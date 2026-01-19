@isTest
public class ServiceAppointmentUtilityTest {

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

        // Create a ServiceTerritory
        OperatingHours oh = new OperatingHours(
            Name = 'US Mountain Shift',
            TimeZone = 'America/Denver'
        );
        insert oh;

        ServiceTerritory st = new ServiceTerritory(
            Name = 'NM',
            IsActive = true,
            OperatingHoursId = oh.Id
        );
        insert st;

        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.Vendor_Status__c = 'Ticket Acceptance'; // Ensure this is set
        wo.ServiceTerritoryId = st.Id; // Associate with the ServiceTerritory
        insert wo;

        // Create a User for the ServiceResource
        Profile p = [SELECT Id FROM Profile WHERE Name = 'FS Mobile TECHNICIANS']; // Use the correct profile name
        User u = new User(
            Alias = 'tstusr',
            Email = 'testuser9878@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser987',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser9878@example.com'
        );
        insert u;

        // Create a ServiceResource linked to the User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = u.Id,
            Alt_Phone__c = '19991234567',
            MobilePhone__c = '18881234567'
        );
        insert sr;

        // Create a ServiceTerritoryMember to associate the ServiceResource with the ServiceTerritory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'P', // Primary territory type
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        // Create a Scheduling Policy
        FSL__Scheduling_Policy__c schedulingPolicy = new FSL__Scheduling_Policy__c(
            Name = 'Resource Capability'
        );
        insert schedulingPolicy;
    }
@isTest
static void testCreateServiceAppointments() {
    // Query the test WorkOrder with all required fields
    WorkOrder wo = [
        SELECT Id, Bill_to_Customer__c, Sub_Customer__c, Vendor_Status__c, SiteID__c, Duration, 
               Service_Type__c, Open_Date__c, ServiceTerritoryId, Reference1__c
        FROM WorkOrder
        LIMIT 1
    ];
    System.debug('WorkOrder queried: ' + wo);

    // Call the method to create ServiceAppointments
    Test.startTest();
    List<ServiceAppointment> serviceAppointments = ServiceAppointmentUtility.createServiceAppointments(new List<WorkOrder>{wo});
    Test.stopTest();

    // Verify that ServiceAppointments were created
    System.debug('Service Appointments created: ' + serviceAppointments);
    System.assert(!serviceAppointments.isEmpty(), 'Service Appointments should be created.');
}
}