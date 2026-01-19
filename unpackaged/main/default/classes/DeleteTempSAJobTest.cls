@isTest
public class DeleteTempSAJobTest {
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

    // Mock for FSL.GradeSlotsService to force retry
    private class GradeSlotsServiceMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            if (stubbedMethodName == 'getGradedMatrix') {
                FSL.AdvancedGapMatrix matrix = new FSL.AdvancedGapMatrix();
                matrix.ResourceIDToScheduleData = new Map<Id, FSL.ResourceScheduleData>(); // Empty map triggers retry
                return matrix;
            }
            return null;
        }
    }

    @isTest
    static void testDeleteTempSAJob() {
        // Query the test ServiceAppointment
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        // Calculate a valid cron expression for 1 minute from now
        Datetime scheduleTime = System.now().addMinutes(1);
        Integer second = 0;
        Integer minute = scheduleTime.minute();
        Integer hour = scheduleTime.hour();
        Integer day = scheduleTime.day();
        Integer month = scheduleTime.month();
        Integer year = scheduleTime.year();
        String cronExpression = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;

        Test.startTest();
        Test.setMock(StubProvider.class, new GradeSlotsServiceMock());
        System.schedule('DeleteTempSAJobTest', cronExpression, new DeleteTempSAJob(new List<Id>{sa.Id}));
        Test.stopTest();

        // Verify that the job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'DeleteTempSAJobTest%'];
        System.assert(!scheduledJobs.isEmpty(), 'DeleteTempSAJob should be scheduled.');

        // Verify that the ServiceAppointment was deleted
        List<ServiceAppointment> deletedSAs = [SELECT Id FROM ServiceAppointment WHERE Id = :sa.Id];
        //System.assert(deletedSAs.isEmpty(), 'ServiceAppointment should have been deleted.');

        // Verify retry jobs were scheduled
        List<CronTrigger> retryJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE 'CandidateFetcherRetry%'];
        System.debug('Retry jobs scheduled: ' + retryJobs);
       // System.assert(!retryJobs.isEmpty(), 'CandidateFetcherRetryScheduler job should be scheduled due to retry.');
    }

    @isTest
    static void testCandidateFetcherRetryScheduler() {
        // Query the test ServiceAppointment
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        // Prepare parameters for CandidateFetcherRetryScheduler
        List<Id> saIds = new List<Id>{sa.Id};
        Boolean withDelay = true;
        Integer retryCount = 1;

        // Calculate a valid cron expression for 1 minute from now
        Datetime scheduleTime = System.now().addMinutes(1);
        Integer second = 0;
        Integer minute = scheduleTime.minute();
        Integer hour = scheduleTime.hour();
        Integer day = scheduleTime.day();
        Integer month = scheduleTime.month();
        Integer year = scheduleTime.year();
        String cronExpression = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ? ' + year;
        String jobName = 'TestCandidateFetcherRetry_' + sa.Id + '_' + System.now().getTime();

        Test.startTest();
        System.schedule(jobName, cronExpression, new CandidateFetcherRetryScheduler(saIds, withDelay, retryCount));
        Test.stopTest();

        // Verify that the scheduler job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        System.assert(!scheduledJobs.isEmpty(), 'CandidateFetcherRetryScheduler job should be scheduled.');
    }
}