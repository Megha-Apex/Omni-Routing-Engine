@isTest
private class AbsenceRecurrenceInvocableTest {
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
    private static void testDailyAbsenceRecurrence() { 
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<AbsenceRecurrenceInvocable.Request> requestList = new List<AbsenceRecurrenceInvocable.Request>();
        AbsenceRecurrenceInvocable.Request request = new AbsenceRecurrenceInvocable.Request();
        request.startDate = Date.newInstance(2120, 1, 1);
        request.startTime = '12:00';
        request.endDate = Date.newInstance(2120, 1, 8);
        request.endTime = '14:00';
        request.isDaily = true;
        request.selectedDaysOfTheWeek = 'Monday; Tuesday';
        request.publicComments = '';
        request.internalComments = '';
        request.activityType = 'Lieu - Paid';
        request.assignedResources = new List<Id>{serviceResource.Id};
        requestList.add(request);
        
        Test.startTest();
        List<String> resultList = AbsenceRecurrenceInvocable.main(requestList);
        Test.stopTest();
        
        System.assertEquals(true, resultList.size() > 0);
    }
    
    @isTest
    private static void testWeeklyAbsenceRecurrence() { 
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<AbsenceRecurrenceInvocable.Request> requestList = new List<AbsenceRecurrenceInvocable.Request>();
        AbsenceRecurrenceInvocable.Request request = new AbsenceRecurrenceInvocable.Request();
        request.startDate = Date.newInstance(2120, 1, 1);
        request.startTime = '12:00';
        request.endDate = Date.newInstance(2120, 1, 8);
        request.endTime = '14:00';
        request.isWeekly = true;
        request.selectedDaysOfTheWeek = 'Monday; Tuesday';
        request.recurOnWeekOfEveryMonth = 1;
        request.publicComments = '';
        request.internalComments = '';
        request.activityType = 'Lieu - Paid';
        request.assignedResources = new List<Id>{serviceResource.Id};
        requestList.add(request);
        
        Test.startTest();
        List<String> resultList = AbsenceRecurrenceInvocable.main(requestList);
        Test.stopTest();
        
        System.assertEquals(true, resultList.size() > 0);
    }
    
    @isTest
    private static void testMonthlyAbsenceRecurrence() { 
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        List<AbsenceRecurrenceInvocable.Request> requestList = new List<AbsenceRecurrenceInvocable.Request>();
        AbsenceRecurrenceInvocable.Request request = new AbsenceRecurrenceInvocable.Request();
        request.startDate = Date.newInstance(2120, 1, 1);
        request.startTime = '12:00';
        request.endDate = Date.newInstance(2120, 3, 1);
        request.endTime = '14:00';
        request.isMonthly = true;
        request.selectedDayOfTheMonth = 3;
        request.ocurrenceOnWeek = 'The First';
        request.repeatNumberOfMonths = 1;
        request.publicComments = '';
        request.internalComments = '';
        request.activityType = 'Lieu - Paid';
        request.assignedResources = new List<Id>{serviceResource.Id};
        requestList.add(request);
        
        Test.startTest();
        List<String> resultList = AbsenceRecurrenceInvocable.main(requestList);
        Test.stopTest();
        
        System.assertEquals(true, resultList.size() > 0);
    }
}