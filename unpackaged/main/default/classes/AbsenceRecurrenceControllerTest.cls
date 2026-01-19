@isTest
private class AbsenceRecurrenceControllerTest {
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
    private static void testOtainAbsenceRecurrence() {
		ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];

        sObject parentAbsence = new ResourceAbsence();
        parentAbsence.put('Start', DateTime.now().addDays(1));
        parentAbsence.put('End', DateTime.now().addDays(1).addMinutes(1));
        parentAbsence.put('Type', 'Lieu - paid');
        parentAbsence.put('ResourceId', serviceResource.Id);
        insert parentAbsence;
        parentAbsence.put('Recurrence_Key__c', parentAbsence.Id);
        update parentAbsence;
        
        List<ResourceAbsence> absenceList = new List<ResourceAbsence>();
        for(Integer absence_i = 1; absence_i <= 3; absence_i++) {
            sObject resourceAbsence = new ResourceAbsence();
            resourceAbsence.put('Start', DateTime.now().addDays(1 + absence_i));
            resourceAbsence.put('End', DateTime.now().addDays(1 + absence_i).addMinutes(1));
            resourceAbsence.put('Type', 'Lieu - paid');
            resourceAbsence.put('Recurrence_Key__c', parentAbsence.get('Id'));
            resourceAbsence.put('ResourceId', serviceResource.Id);
            absenceList.add((ResourceAbsence)resourceAbsence);   
        }
        insert absenceList;
        
        Test.startTest();
        String resultJSON = JSON.serialize(AbsenceRecurrenceController.obtainAbsenceRecurrence(serviceResource.Id));
        Test.stopTest();
        List<Object> resultList = (List<Object>)JSON.deserializeUntyped(resultJSON);
        Map<String, Object> resultMap = (Map<String, Object>)resultList[0];
        String startDateJSON = JSON.serialize((String)resultMap.get('startDate'));
        DateTime startDate = (DateTime)JSON.deserialize(startDateJSON, DateTime.class);
        String endDateJSON = JSON.serialize((String)resultMap.get('endDate'));
        DateTime endDate = (DateTime)JSON.deserialize(endDateJSON, DateTime.class);
        
        System.assertEquals(DateTime.now().addDays(1).date(), startDate.date());
        System.assertEquals(DateTime.now().addDays(4).date(), endDate.date());
    }
    
    @isTest
    private static void testDailyRecurrence() {
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 1, 7);
        String selectedDaysOfTheWeek = 'Monday; Friday';
        
        Test.startTest();
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.dailyRecurrence(startDate, endDate, selectedDaysOfTheWeek);
        Test.stopTest();
        System.assertEquals(2, datesToCreateSet.size());
    }
    
    @isTest
    private static void testWeeklyRecurrence() {
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 2, 1);
        Integer recurOnWeekOfEveryMonth = 3;
        String selectedDaysOfTheWeek = 'Monday; Friday';
        
        Test.startTest();
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.weeklyRecurrence(startDate, endDate, selectedDaysOfTheWeek, recurOnWeekOfEveryMonth);
        Test.stopTest();
        
        System.assertEquals(2, datesToCreateSet.size());
    }
    
    @isTest
    private static void testDayOfEveryMonthRecurrence() {
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 12, 31);
        
        Test.startTest();
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.monthlyRecurrence(startDate, endDate, 13, '', '', 1);
        Test.stopTest();

        System.assertEquals(12, datesToCreateSet.size());
    }
    
    @isTest
    private static void testWeekDayOfEveryMonthRecurrence() {
        Date startDate = Date.newInstance(2019, 12, 31);
        Date endDate = Date.newInstance(2021, 1, 1);
        
        Test.startTest();
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.monthlyRecurrence(startDate, endDate, 0, 'The First', 'Monday', 1);
        Test.stopTest();

        System.assertEquals(12, datesToCreateSet.size());
    }
    
    @isTest
    private static void testCreateAbsences() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 1, 31);
        String selectedDaysOfTheWeek = 'Monday; Friday';
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.dailyRecurrence(startDate, endDate, selectedDaysOfTheWeek);
        sObject resourceAbsence = new ResourceAbsence();
        resourceAbsence.put('Start', DateTime.newInstance(2020, 1, 1, 8, 0, 0));
        resourceAbsence.put('End', DateTime.newInstance(2020, 1, 31, 11, 0, 0));
        resourceAbsence.put('Type', 'Lieu - paid');
        Set<Id> assignedResources = new Set<Id>();
        assignedResources.add(serviceResource.Id);
        
        Test.startTest();
        List<sObject> resourceAbsenceList = AbsenceRecurrenceController.createAbsences((ResourceAbsence)resourceAbsence, assignedResources, datesToCreateSet);
        Test.stopTest();
        
        System.assertEquals(datesToCreateSet.size(), resourceAbsenceList.size());
    }
    
    @isTest
    private static void testCreateAbsencesBatch() {
    ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 7, 31);
        String selectedDaysOfTheWeek = 'Monday; Tuesday; Wednesday; Thursday; Friday; Saturday; Sunday';
        Set<Date> datesToCreateSet = AbsenceRecurrenceController.dailyRecurrence(startDate, endDate, selectedDaysOfTheWeek);
        sObject resourceAbsence = new ResourceAbsence();
        resourceAbsence.put('Start', DateTime.newInstance(2020, 1, 1, 8, 0, 0));
        resourceAbsence.put('End', DateTime.newInstance(2020, 7, 31, 11, 0, 0));
        resourceAbsence.put('Type', 'Lieu - paid');
        Set<Id> assignedResources = new Set<Id>();
        assignedResources.add(serviceResource.Id);
        
        Test.startTest();
        AbsenceRecurrenceController.createAbsences((ResourceAbsence)resourceAbsence, assignedResources, datesToCreateSet);
        Test.stopTest();
        List<sObject> resourceAbsenceList = [SELECT Id FROM ResourceAbsence WHERE ResourceId = :serviceResource.Id];
        System.assertEquals(datesToCreateSet.size(), resourceAbsenceList.size());
    }
    
    @isTest
    private static void testDeleteAbsences() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];

        sObject parentAbsence = new ResourceAbsence();
        parentAbsence.put('Start', DateTime.newInstance(2021, 1, 1, 8, 0, 0));
        parentAbsence.put('End', DateTime.newInstance(2021, 1, 1, 11, 0, 0));
        parentAbsence.put('Type', 'Lieu - paid');
        parentAbsence.put('ResourceId', serviceResource.Id);
        insert parentAbsence;
        parentAbsence.put('Recurrence_Key__c', parentAbsence.Id);
        update parentAbsence;
        
        sObject resourceAbsence = new ResourceAbsence();
        resourceAbsence.put('Start', DateTime.newInstance(2021, 1, 2, 8, 0, 0));
        resourceAbsence.put('End', DateTime.newInstance(2021, 1, 2, 11, 0, 0));
        resourceAbsence.put('Type', 'Lieu - paid');
        resourceAbsence.put('ResourceId', serviceResource.Id);
        resourceAbsence.put('Recurrence_Key__c', parentAbsence.Id);
        insert resourceAbsence;
        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
        resourceAbsenceList.add((ResourceAbsence)parentAbsence);
        resourceAbsenceList.add((ResourceAbsence)resourceAbsence);
        
        Test.startTest();
        AbsenceRecurrenceController.deleteAbsences(new List<Id>{parentAbsence.Id});
        Test.stopTest();
		
        System.assertEquals(0, [SELECT Id FROM ResourceAbsence WHERE Id IN :resourceAbsenceList].size());
    }
    
    @isTest
    private static void testPrepartOutput() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];

        sObject parentAbsence = new ResourceAbsence();
        parentAbsence.put('Start', DateTime.newInstance(2021, 1, 1, 8, 0, 0));
        parentAbsence.put('End', DateTime.newInstance(2021, 1, 1, 11, 0, 0));
        parentAbsence.put('Type', 'Lieu - paid');
        parentAbsence.put('ResourceId', serviceResource.Id);
        insert parentAbsence;
        List<ResourceAbsence> resourceAbsenceList = new List<ResourceAbsence>();
        resourceAbsenceList.add((ResourceAbsence)parentAbsence);
        
        Test.startTest();
        String result = AbsenceRecurrenceController.prepareOutput(resourceAbsenceList);
        Test.stopTest();
        
        System.assertEquals(true, String.isNotBlank(result));
    }
    
    @isTest
    private static void testCreateAbsenceRecurrence() {
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        String action = 'DailyRecurrence';
        Set<Id> assignedResources = new Set<Id>();
        assignedResources.add(serviceResource.Id);
        sObject absenceData = new ResourceAbsence();
        absenceData.put('Start', DateTime.newInstance(Date.newInstance(2120, 1, 1), Time.newInstance(12, 0, 0, 0)));
        absenceData.put('End', DateTime.newInstance(Date.newInstance(2120, 2, 1), Time.newInstance(14, 0, 0, 0)));
        absenceData.put('Type', 'Lieu - Paid');
        absenceData.put('Public_Comments__c', 'test');
        absenceData.put('Internal_Comments__c', 'test');
        String selectedDaysOfTheWeek = 'Monday; Tuesday';
       	String params = JSON.serialize(new AbsenceParams(selectedDaysOfTheWeek));
        
        Test.startTest();
        String result = AbsenceRecurrenceController.createAbsenceRecurrence(action, assignedResources, absenceData, params);
        Test.stopTest();
        
        System.assertEquals(true, String.isNotBlank(result));
    }
    
    private class AbsenceParams {
        public String selectedDaysOfTheWeek;
        
        public AbsenceParams(String selectedDaysOfTheWeek) {
            this.selectedDaysOfTheWeek = selectedDaysOfTheWeek;
        }
    }
}