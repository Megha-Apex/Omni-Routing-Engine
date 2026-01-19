@isTest
private class HazardAlertControllerTest {
    
    public static void createTestData() {
        Request_Type__c requestType = TestFactory.createRequestType('Test Request Type');
        insert requestType;

        Case cs = TestFactory.createCase('Test', requestType.Id, 'test@test.com');
        insert cs;

        Account customer = TestFactory.createCustomer('Test Customer');
        insert customer;

        Account subCustomer = TestFactory.createSubCustomer('Test Sub Customer', customer.Id);
        insert subCustomer;

        SLA__c sla = TestFactory.createSLA('Test SLA', 1, '4');
        insert sla;

        SLA_member__c slaMember = TestFactory.createSLAMember('Test SLA Member', subCustomer.Id, sla.Id);
        insert slaMember;

        Service_Type__c contract = TestFactory.createContract('Test Contract');
        insert contract;

        Service_Type__c jobType = TestFactory.createJobType('Test Job Type', contract.Id);
        insert jobType;

        Service_Type__c serviceType = TestFactory.createServiceType('Test Service Type', 60, jobType.Id, contract.Id);
        insert serviceType;

        Account site = TestFactory.createSite('Test Site', '4', subCustomer.Id, '2800 East 1st Avenue', 'Vancouver', 'Canada', 'BC', 'V5M 4N9');
        insert site;

        // Create test Hazard Alert records related to the Site Account
        List<Hazard_Alert__c> hazardAlerts = new List<Hazard_Alert__c>();
        hazardAlerts.add(new Hazard_Alert__c(
            Subject__c = 'Test Hazard 1',
            Description__c = 'Test Description 1',
            Account__c = site.Id
        ));
        hazardAlerts.add(new Hazard_Alert__c(
            Subject__c = 'Test Hazard 2',
            Description__c = 'Test Description 2',
            Account__c = site.Id
        ));
        insert hazardAlerts;
    }

    @TestSetup
    static void makeData() {
        createTestData();
    }
    
    // Test method for successful retrieval of Hazard Alerts
    @isTest
    static void testGetHazardAlerts_Success() {
        // Retrieve the test Site Account
        Account testSite = [SELECT Id FROM Account WHERE Name = 'Test Site' LIMIT 1];
        
        // Start test
        Test.startTest();
        List<Hazard_Alert__c> result = HazardAlertController.getHazardAlerts(testSite.Id, 'Account__c');
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, result.size(), 'Expected 2 Hazard Alerts to be returned');
        System.assertEquals('Test Hazard 1', result[0].Subject__c, 'First Hazard Alert subject is incorrect');
        System.assertEquals('Test Description 1', result[0].Description__c, 'First Hazard Alert description is incorrect');
        System.assertEquals('Test Hazard 2', result[1].Subject__c, 'Second Hazard Alert subject is incorrect');
        System.assertEquals('Test Description 2', result[1].Description__c, 'Second Hazard Alert description is incorrect');
    }
    
    // Test method for blank relationshipField
    @isTest
    static void testGetHazardAlerts_BlankRelationshipField() {
        // Retrieve the test Site Account
        Account testSite = [SELECT Id FROM Account WHERE Name = 'Test Site' LIMIT 1];
        
        // Start test and expect an exception
        Test.startTest();
        try {
            HazardAlertController.getHazardAlerts(testSite.Id, '');
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
           // System.assertEquals('relationshipField is required', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
    }
    
    // Test method for null relationshipField
    @isTest
    static void testGetHazardAlerts_NullRelationshipField() {
        // Retrieve the test Site Account
        Account testSite = [SELECT Id FROM Account WHERE Name = 'Test Site' LIMIT 1];
        
        // Start test and expect an exception
        Test.startTest();
        try {
            HazardAlertController.getHazardAlerts(testSite.Id, null);
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
           // System.assertEquals('relationshipField is required', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
    }
    
  
}