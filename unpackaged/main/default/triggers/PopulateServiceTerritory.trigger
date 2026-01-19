trigger PopulateServiceTerritory on ResourceAbsence (before insert, before update) {
    Set<Id> resourceIds = new Set<Id>();
    
    // Collect Resource Ids from the new ResourceAbsence records
    for (ResourceAbsence ra : Trigger.new) {
        if (ra.ResourceId != null) {
            resourceIds.add(ra.ResourceId);
        }
    }

    if (resourceIds.isEmpty()) return;

    // Query ServiceTerritoryMember to find active territories for these resources and log TerritoryType
    Map<Id, Id> resourceToTerritoryMap = new Map<Id, Id>();
    for (ServiceTerritoryMember stm : [
        SELECT ServiceResourceId, ServiceTerritoryId, TerritoryType
        FROM ServiceTerritoryMember
        WHERE ServiceResourceId IN :resourceIds
          AND (EffectiveStartDate <= :System.now() OR EffectiveStartDate = NULL)
          AND (EffectiveEndDate >= :System.now() OR EffectiveEndDate = NULL)
    ]) {
        // Log the TerritoryType values
        System.debug('TerritoryType for ServiceResourceId ' + stm.ServiceResourceId + ' is: ' + stm.TerritoryType);
        
        // Check for primary territory
        if (stm.TerritoryType == 'P') {
            resourceToTerritoryMap.put(stm.ServiceResourceId, stm.ServiceTerritoryId);
        }
    }

    // Loop through ResourceAbsence records and assign the correct Service Territory
    for (ResourceAbsence ra : Trigger.new) {
        if (ra.ResourceId != null && resourceToTerritoryMap.containsKey(ra.ResourceId)) {
            ra.Service_Territory__c = resourceToTerritoryMap.get(ra.ResourceId);
        }
    }
}