@isTest
public class SATriggerTest {

    @TestSetup
    static void setupTestData() {
        // Create test data using TestFactory
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

        Account site = TestFactory.createSite('Test Site', '4', subCustomer.Id, '2800 East 1st Avenue', 'Vancouver', 'Canada', 'BC', 'V5M 4N9');
        insert site;

        Service_Type__c serviceType = TestFactory.createServiceType('Test Service Type', 60, null, null);
        insert serviceType;

        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.Vendor_Status__c = 'Ticket Acceptance';
        insert wo;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            EarliestStartTime = System.now().addHours(2),
            DueDate = System.today().addDays(14),
            Status = 'Open',
            Work_Order__c = wo.Id,
            Bill_to_Customer__c = wo.Bill_to_Customer__c,
            Sub_Customer__c = wo.Sub_Customer__c,
            Site__c = wo.SiteID__c,
            Duration = wo.Duration,
            ServiceTerritoryId = wo.ServiceTerritoryId,
            Service_Type__c = wo.Service_Type__c,
            Open_Date__c = wo.Open_Date__c,
            Schedule_Automatically__c = false,
            Do_Not_Use_SA__c = true
        );
        insert sa;
    }

    @isTest
    static void testSATriggerInsert() {
        // Query the test ServiceAppointment
        ServiceAppointment sa = [SELECT Id, Do_Not_Use_SA__c, Work_Order__c FROM ServiceAppointment LIMIT 1];

        // Update Do_Not_Use_SA__c to trigger the SATrigger
        sa.Do_Not_Use_SA__c = true;
        Test.startTest();
        update sa;
        Test.stopTest();

        // Verify that the queueable job was enqueued
        System.assertEquals(1, Limits.getQueueableJobs(), 'Queueable job should be enqueued');
    }
}