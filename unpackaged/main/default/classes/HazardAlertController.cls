public with sharing class HazardAlertController {
    @AuraEnabled(cacheable=true)
    public static List<Hazard_Alert__c> getHazardAlerts(Id recordId, String relationshipField) {
        System.debug('Received relationshipField: ' + relationshipField);
        if (String.isBlank(relationshipField)) {
            throw new AuraHandledException('relationshipField is required');
        }
        
        String query = 'SELECT Id, Description__c, Subject__c ' +
                       'FROM Hazard_Alert__c ' +
                       'WHERE ' + relationshipField + ' = :recordId';
        
        System.debug('Executing query: ' + query);
        return Database.query(query);
    }
}