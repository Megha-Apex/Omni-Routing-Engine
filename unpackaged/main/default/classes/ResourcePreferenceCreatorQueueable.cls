public class ResourcePreferenceCreatorQueueable implements Queueable {
    private List<Id> serviceAppointmentIds;

    public ResourcePreferenceCreatorQueueable(List<Id> serviceAppointmentIds) {
        this.serviceAppointmentIds = serviceAppointmentIds;
    }

    public void execute(QueueableContext context) {
        // Fetch SAs and create Resource Preferences
        List<ServiceAppointment> serviceApps = [
            SELECT Id, Work_Order__c, Active_Technician__c 
            FROM ServiceAppointment 
            WHERE Id IN :serviceAppointmentIds 
              AND Do_Not_Use_SA__c = true
        ];

        // Collect Work Order IDs and Active Technician IDs
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (ServiceAppointment sa : serviceApps) {
            if (sa.Active_Technician__c != null && sa.Work_Order__c != null) {
                workOrderIds.add(sa.Work_Order__c);

                // Convert the List<String> from split() to a Set<Id>
                List<String> resourceIdStrings = sa.Active_Technician__c.split(';');
                for (String resourceIdStr : resourceIdStrings) {
                    resourceIdStr = resourceIdStr.trim();
                    if (String.isNotBlank(resourceIdStr)) {
                        resourceIds.add((Id) resourceIdStr); // Cast to Id
                    }
                }
            }
        }

        // Query existing Resource Preferences to avoid duplicates
        Map<String, ResourcePreference> existingPrefsMap = new Map<String, ResourcePreference>();
        for (ResourcePreference rp : [
            SELECT Id, RelatedRecordId, ServiceResourceId 
            FROM ResourcePreference 
            WHERE RelatedRecordId IN :workOrderIds 
              AND ServiceResourceId IN :resourceIds
        ]) {
            // Use a composite key to identify duplicates
            String compositeKey = rp.RelatedRecordId + '-' + rp.ServiceResourceId;
            existingPrefsMap.put(compositeKey, rp);
        }

        // Create new Resource Preferences, avoiding duplicates
        List<ResourcePreference> resourcePrefs = new List<ResourcePreference>();
        for (ServiceAppointment sa : serviceApps) {
            if (sa.Active_Technician__c != null && sa.Work_Order__c != null) {
                for (String resourceId : sa.Active_Technician__c.split(';')) {
                    resourceId = resourceId.trim();
                    if (String.isNotBlank(resourceId)) {
                        // Check if a ResourcePreference already exists for this combination
                        String compositeKey = sa.Work_Order__c + '-' + resourceId;
                        if (!existingPrefsMap.containsKey(compositeKey)) {
                            resourcePrefs.add(new ResourcePreference(
                                RelatedRecordId = sa.Work_Order__c,
                                ServiceResourceId = (Id) resourceId, // Cast to Id
                                PreferenceType = 'Required'
                            ));
                        }
                    }
                }
            }
        }

        // Insert new Resource Preferences
        if (!resourcePrefs.isEmpty()) {
            insert resourcePrefs;
            System.debug('Created ' + resourcePrefs.size() + ' Resource Preferences.');
        }
    }
}