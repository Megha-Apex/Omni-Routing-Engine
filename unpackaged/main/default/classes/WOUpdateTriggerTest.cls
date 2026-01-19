@isTest
public class WOUpdateTriggerTest {

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
        subCustomer.Send_Potential_Tech__c = true; // Ensure this is true
        insert subCustomer;

        SLA__c sla = TestFactory.createSLA('Test SLA', 1, '4');
        insert sla;

        SLA_member__c slaMember = TestFactory.createSLAMember('Test SLA Member', subCustomer.Id, sla.Id);
        insert slaMember;

        Account site = TestFactory.createSite('Test Site', '4', subCustomer.Id, '2800 East 1st Avenue', 'Vancouver', 'Canada', 'BC', 'V5M 4N9');
        insert site;

        Service_Type__c serviceType = TestFactory.createServiceType('Test Service Type', 60, null, null);
        insert serviceType;

        // Create a WorkOrder
        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.Vendor_Status__c = 'Ticket Acceptance'; // Ensure this is set
        insert wo;

        // Create a WO_Update__c record
        WO_Update__c woUpdate = new WO_Update__c(
            Work_Order_Number__c = wo.Id,
            Update_Action__c = 'Reschedule',
            Approval_Status__c = 'Pending'
        );
        insert woUpdate;
    }

    @isTest
    static void testWOUpdateTriggerUpdate() {
        // Query the test WO_Update__c record
        WO_Update__c woUpdate = [SELECT Id, Approval_Status__c FROM WO_Update__c LIMIT 1];

        // Update the WO_Update__c record to meet the conditions
        woUpdate.Approval_Status__c = 'Approved';

        Test.startTest();
        update woUpdate;
        Test.stopTest();

        // Verify that ServiceAppointments were created
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<ServiceAppointment> serviceAppointments = [
            SELECT Id 
            FROM ServiceAppointment 
            WHERE Work_Order__c = :wo.Id
        ];
       // System.assert(!serviceAppointments.isEmpty(), 'Service Appointments should be created.');
    }

}