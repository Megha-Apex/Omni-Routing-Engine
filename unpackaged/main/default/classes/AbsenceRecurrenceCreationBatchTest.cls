@isTest
private class AbsenceRecurrenceCreationBatchTest {
    
	@testSetup
    private static void testSetup() {
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        ServiceResource serviceResource = new ServiceResource();
        serviceResource.AccountId = account.Id;
        serviceResource.RelatedRecordId = UserInfo.getUserId();
        serviceResource.Name = 'Test Service';
        serviceResource.IsActive = true;
        insert serviceResource;
    }
    
    @isTest
    private static void testBatch() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        sObject parentAbsence = new ResourceAbsence();
        parentAbsence.put('Start', DateTime.now().addDays(1));
        parentAbsence.put('End', DateTime.now().addDays(1).addHours(6));
        parentAbsence.put('Type', 'Lieu - paid');
        parentAbsence.put('ResourceId', serviceResource.Id);
        insert parentAbsence;
        
        sObject resourceAbsence = new ResourceAbsence();
        resourceAbsence.put('Start', DateTime.now().addDays(2));
        resourceAbsence.put('End', DateTime.now().addDays(2).addHours(6));
        resourceAbsence.put('Type', 'Lieu - paid');
        resourceAbsence.put('Recurrence_Key__c', parentAbsence.get('Id'));
        resourceAbsence.put('ResourceId', serviceResource.Id);
        List<ResourceAbsence> absenceList = new List<ResourceAbsence>();
        absenceList.add((ResourceAbsence)resourceAbsence);
        
        Map<Id, ResourceAbsence> parentAbsenceMap = new Map<Id, ResourceAbsence>();
        parentAbsenceMap.put(parentAbsence.Id, (ResourceAbsence)parentAbsence);
        
        Test.startTest();
		Id batchId = Database.executeBatch(new AbsenceRecurrenceCreationBatch(absenceList, parentAbsenceMap));
        Test.stopTest();
        ResourceAbsence newParentAbsence = [SELECT Recurrence_Status__c FROM ResourceAbsence WHERE Id = :parentAbsence.Id LIMIT 1];
        System.assertEquals('Completed', newParentAbsence.Recurrence_Status__c);
        System.assertEquals(1, [SELECT Id FROM ResourceAbsence WHERE Id != :newParentAbsence.Id].size());
    }
    
    @isTest
    private static void testBatchFailed() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        sObject parentAbsence = new ResourceAbsence();
        parentAbsence.put('Start', DateTime.now().addDays(1));
        parentAbsence.put('End', DateTime.now().addDays(1).addHours(6));
        parentAbsence.put('Type', 'Lieu - paid');
        parentAbsence.put('ResourceId', serviceResource.Id);
        insert parentAbsence;
        
        sObject resourceAbsence = new ResourceAbsence();
        resourceAbsence.put('Start', DateTime.now().addDays(2));
        resourceAbsence.put('End', DateTime.now().addDays(2).addHours(6));
        resourceAbsence.put('Recurrence_Key__c', parentAbsence.get('Id'));
        List<ResourceAbsence> absenceList = new List<ResourceAbsence>();
        absenceList.add((ResourceAbsence)resourceAbsence);
        
        Map<Id, ResourceAbsence> parentAbsenceMap = new Map<Id, ResourceAbsence>();
        parentAbsenceMap.put(parentAbsence.Id, (ResourceAbsence)parentAbsence);
        
        Test.startTest();
		Id batchId = Database.executeBatch(new AbsenceRecurrenceCreationBatch(absenceList, parentAbsenceMap));
        Test.stopTest();
        ResourceAbsence newParentAbsence = [SELECT Recurrence_Status__c FROM ResourceAbsence WHERE Id = :parentAbsence.Id LIMIT 1];
        System.assertEquals('Failed', newParentAbsence.Recurrence_Status__c);
        System.assertEquals(0, [SELECT Id FROM ResourceAbsence WHERE Id != :newParentAbsence.Id].size());
    }
}