@isTest
public class ResourcePreferenceCreatorQueueableTest {

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

        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.Vendor_Status__c = 'Ticket Acceptance'; // Ensure this is set
        insert wo;

        // Create a User for the ServiceResource
        Profile p;
        try {
            p = [SELECT Id FROM Profile WHERE Name = 'FS Mobile TECHNICIANS']; // Use the correct profile name
            System.debug('Profile found: ' + p);
        } catch (QueryException e) {
            System.debug('Profile not found. Please check the profile name.');
            return;
        }

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
        System.debug('User created: ' + u);

        // Create a ServiceResource linked to the User
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = u.Id,
            Alt_Phone__c = '19991234567',
            MobilePhone__c = '18881234567'
        );
        insert sr;
        System.debug('ServiceResource created: ' + sr);

        // Create a ServiceTerritory
        OperatingHours oh = new OperatingHours(
            Name = 'US Mountain Shift',
            TimeZone = 'America/Denver'
        );
        insert oh;
        System.debug('OperatingHours created: ' + oh);

        ServiceTerritory st = new ServiceTerritory(
            Name = 'NM',
            IsActive = true,
            OperatingHoursId = oh.Id
        );
        insert st;
        System.debug('ServiceTerritory created: ' + st);

        // Create a ServiceTerritoryMember to associate the ServiceResource with the ServiceTerritory
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'P', // Primary territory type
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;
        System.debug('ServiceTerritoryMember created: ' + stm);

        // Create a Scheduling Policy
        FSL__Scheduling_Policy__c schedulingPolicy = new FSL__Scheduling_Policy__c(
            Name = 'Resource Capability'
        );
        insert schedulingPolicy;
        System.debug('Scheduling Policy created: ' + schedulingPolicy);

        // Create a ServiceAppointment
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
            ServiceTerritoryId = st.Id, // Associate with the ServiceTerritory
            Service_Type__c = wo.Service_Type__c,
            Open_Date__c = wo.Open_Date__c,
            Schedule_Automatically__c = false,
            Do_Not_Use_SA__c = true
        );
        insert sa;
        System.debug('ServiceAppointment created: ' + sa);

        // Set Active_Technician__c to the ServiceResource ID
        sa.Active_Technician__c = sr.Id;
        update sa;
        System.debug('ServiceAppointment updated with Active_Technician__c: ' + sa);
    }

    @isTest
    static void testResourcePreferenceCreatorQueueable() {
        // Query the test ServiceAppointment
        ServiceAppointment sa = [SELECT Id, Active_Technician__c, Work_Order__c FROM ServiceAppointment LIMIT 1];
        System.debug('ServiceAppointment queried: ' + sa);

        // Enqueue the ResourcePreferenceCreatorQueueable job
        Test.startTest();
        System.enqueueJob(new ResourcePreferenceCreatorQueueable(new List<Id>{sa.Id}));
        Test.stopTest();

        // Verify that Resource Preferences were created
        List<ResourcePreference> resourcePrefs = [
            SELECT Id 
            FROM ResourcePreference 
            WHERE RelatedRecordId = :sa.Work_Order__c
        ];
        System.debug('Resource Preferences created: ' + resourcePrefs);
        System.assert(!resourcePrefs.isEmpty(), 'Resource Preferences should be created.');
    }
}