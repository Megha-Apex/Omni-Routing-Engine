trigger WOUpdateTrigger on WO_Update__c (after insert, after update) {
    Set<Id> workOrderIds = new Set<Id>();

    // Collect Work Order IDs and check conditions
    for (WO_Update__c woUpdate : Trigger.new) {
        // Check if the record meets the conditions
        if (woUpdate.Update_Action__c == 'Reschedule' && 
            woUpdate.Approval_Status__c == 'Approved' && 
            woUpdate.Work_Order_Number__c != null) {

            // For update, ensure the Approval Status was not already "Approved"
            if (Trigger.isUpdate) {
                WO_Update__c oldWoUpdate = Trigger.oldMap.get(woUpdate.Id);
                if (oldWoUpdate.Approval_Status__c != 'Approved') {
                    workOrderIds.add(woUpdate.Work_Order_Number__c);
                }
            } else if (Trigger.isInsert) {
                workOrderIds.add(woUpdate.Work_Order_Number__c);
            }
        }
    }

    if (!workOrderIds.isEmpty()) {
        // Retrigger the Service Appointment creation process
        List<WorkOrder> workOrdersToCreateSAs = [
            SELECT Id, Bill_to_Customer__c, Sub_Customer__c, Vendor_Status__c, 
                   Duration, ServiceTerritoryId, Service_Type__c, Open_Date__c, SiteID__c, Reference1__c
            FROM WorkOrder 
            WHERE Id IN :workOrderIds
        ];

        // Create new Service Appointments
        List<ServiceAppointment> saToCreate = ServiceAppointmentUtility.createServiceAppointments(workOrdersToCreateSAs);

        // Handle post-creation logic
        ServiceAppointmentUtility.handlePostCreation(saToCreate);
    }
}