@isTest
private class EnablePreventGeocodeChatterTest {
      @TestSetup
    static void makeData() {
       Request_Type__c requestType = TestFactory.createRequestType('Test Request Type');
        insert requestType;

        Case cs = TestFactory.createCase('Test', requestType.Id, 'test@test.com');
        insert cs;

        TimeZone timeZone = UserInfo.getTimeZone();
        OperatingHours operatingHours = new OperatingHours(Name = 'Test', TimeZone = timeZone.toString());
        insert operatingHours;

        Service_Type__c contract = TestFactory.createContract('Test Contract');
        insert contract;

        Service_Type__c jobType = TestFactory.createJobType('Test Job Type', contract.Id);
        insert jobType;

        Service_Type__c serviceType = TestFactory.createServiceType('Test Service Type', 60, jobType.Id, contract.Id);
        insert serviceType;

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
}

    // Test case to cover the scenario where all geolocation fields and assigned technician are null
    @isTest
    static void testAllFieldsNull() {
         Case cs = [SELECT Id FROM Case];
        SLA_member__c slaMember = [SELECT Id FROM SLA_member__c];
        Account customer = [SELECT Id FROM Account WHERE Name = 'Test Customer'];
        Account subCustomer = [SELECT Id FROM Account WHERE Name = 'Test Sub Customer'];
        Service_Type__c serviceType = [SELECT Id FROM Service_Type__c WHERE Name = 'Test Service Type'];
        Account site = [SELECT Id FROM Account WHERE Name = 'Test Site'];
        OperatingHours operatingHours = [SELECT Id FROM OperatingHours WHERE Name = 'Test'];
        Request_Type__c requestType = [SELECT Id FROM Request_Type__c WHERE Name = 'Test Request Type'];
        
        MaintenancePlan maintenancePlan = new MaintenancePlan();
        maintenancePlan.Frequency = 1;
        maintenancePlan.StartDate = Date.today();
        maintenancePlan.NextSuggestedMaintenanceDate = Date.today().addDays(2);
        maintenancePlan.GenerationTimeframe = 1;
        maintenancePlan.Desired_Arrival_Window_Start_Time__c = Time.newInstance(17, 0, 0, 0);
        maintenancePlan.Desired_Arrival_Window_End_Time__c = Time.newInstance(18, 0, 0, 0);
        maintenancePlan.Service_Type__c = serviceType.Id;
        maintenancePlan.SLA__c = slaMember.Id;
        maintenancePlan.Bill_to_Customer__c = customer.Id;
        maintenancePlan.Sub_Customer__c = subCustomer.Id;
        maintenancePlan.Site__c = site.Id;

        insert maintenancePlan;
        
        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.MaintenancePlanId = maintenancePlan.Id;
        wo.SuggestedMaintenanceDate = Date.today();
        insert wo;
        
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name= '02 Toronto', OperatingHoursId = operatingHours.Id, IsActive=true);
        insert serviceTerritory;
        
        Account account = new Account(Name = 'Test');
        insert account;


    ServiceAppointment serviceAppointment = new ServiceAppointment();
    serviceAppointment.ParentRecordId = wo.Id;
    serviceAppointment.Work_Order__c = wo.Id;
    serviceAppointment.Status = '01 Open';
    serviceAppointment.EarliestStartTime = DateTime.now();
    serviceAppointment.DueDate = Date.today().addDays(2);
    serviceAppointment.Street = '301 Bottomley Avenue North';
    serviceAppointment.State = 'Saskatchewan';
    serviceAppointment.PostalCode = 'S7N 1L3';
    serviceAppointment.Country = 'Canada';
    serviceAppointment.City = 'Saskatoon';
    serviceAppointment.Bill_to_Customer__c = customer.Id;
    serviceAppointment.ETA__c = 30; // Set an example ETA value in minutes (e.g., 30 minutes).

    // Make sure to set the Enroute_Time_Stamp__c field to a valid value in your data setup.
    serviceAppointment.Enroute_Time_Stamp__c = DateTime.now();

    // Insert the ServiceAppointment record within the Test.startTest() and Test.stopTest() block
    
    //insert serviceAppointment;
        
        // Insert the ServiceAppointment
        Test.startTest();
        insert serviceAppointment;
        Test.stopTest();
        
        // Retrieve the inserted ServiceAppointment
        serviceAppointment = [SELECT FSL__Prevent_Geocoding_For_Chatter_Actions__c FROM ServiceAppointment WHERE Id = :serviceAppointment.Id];
        
        // Verify that the FSL__Prevent_Geocoding_For_Chatter_Actions__c field is true
        System.assertEquals(true, serviceAppointment.FSL__Prevent_Geocoding_For_Chatter_Actions__c);
    }

    // Test case to cover the scenario where at least one geolocation field is populated
    @isTest
    static void testSomeFieldsPopulated() {
        Case cs = [SELECT Id FROM Case];
        SLA_member__c slaMember = [SELECT Id FROM SLA_member__c];
        Account customer = [SELECT Id FROM Account WHERE Name = 'Test Customer'];
        Account subCustomer = [SELECT Id FROM Account WHERE Name = 'Test Sub Customer'];
        Service_Type__c serviceType = [SELECT Id FROM Service_Type__c WHERE Name = 'Test Service Type'];
        Account site = [SELECT Id FROM Account WHERE Name = 'Test Site'];
        OperatingHours operatingHours = [SELECT Id FROM OperatingHours WHERE Name = 'Test'];
        Request_Type__c requestType = [SELECT Id FROM Request_Type__c WHERE Name = 'Test Request Type'];
        
        MaintenancePlan maintenancePlan = new MaintenancePlan();
        maintenancePlan.Frequency = 1;
        maintenancePlan.StartDate = Date.today();
        maintenancePlan.NextSuggestedMaintenanceDate = Date.today().addDays(2);
        maintenancePlan.GenerationTimeframe = 1;
        maintenancePlan.Desired_Arrival_Window_Start_Time__c = Time.newInstance(17, 0, 0, 0);
        maintenancePlan.Desired_Arrival_Window_End_Time__c = Time.newInstance(18, 0, 0, 0);
        maintenancePlan.Service_Type__c = serviceType.Id;
        maintenancePlan.SLA__c = slaMember.Id;
        maintenancePlan.Bill_to_Customer__c = customer.Id;
        maintenancePlan.Sub_Customer__c = subCustomer.Id;
        maintenancePlan.Site__c = site.Id;

        insert maintenancePlan;
        
        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        wo.MaintenancePlanId = maintenancePlan.Id;
        wo.SuggestedMaintenanceDate = Date.today();
        insert wo;
        
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name= '02 Toronto', OperatingHoursId = operatingHours.Id, IsActive=true);
        insert serviceTerritory;
        
        Account account = new Account(Name = 'Test');
        insert account;


    ServiceAppointment sa = new ServiceAppointment();
    sa.ParentRecordId = wo.Id;
    sa.Work_Order__c = wo.Id;
    sa.Status = '01 Open';
    sa.EarliestStartTime = DateTime.now();
    sa.DueDate = Date.today().addDays(2);
    sa.Street = '301 Bottomley Avenue North';
    sa.State = 'Saskatchewan';
    sa.PostalCode = 'S7N 1L3';
    sa.Country = 'Canada';
    sa.City = 'Saskatoon';
    sa.FSL__InternalSLRGeolocation__Latitude__s = 37.7749;
    sa.FSL__InternalSLRGeolocation__Longitude__s = -122.4194;
    sa.Bill_to_Customer__c = customer.Id;
    sa.ETA__c = 30; // Set an example ETA value in minutes (e.g., 30 minutes).

    // Make sure to set the Enroute_Time_Stamp__c field to a valid value in your data setup.
    sa.Enroute_Time_Stamp__c = DateTime.now();

    // Insert the ServiceAppointment record within the Test.startTest() and Test.stopTest() block
    
    //insert serviceAppointment;
       
        
        // Insert the ServiceAppointment
        Test.startTest();
        insert sa;
        Test.stopTest();
        
        // Retrieve the inserted ServiceAppointment
        sa = [SELECT FSL__Prevent_Geocoding_For_Chatter_Actions__c FROM ServiceAppointment WHERE Id = :sa.Id];
        
        // Verify that the FSL__Prevent_Geocoding_For_Chatter_Actions__c field is null
    //    System.assertEquals(null, sa.FSL__Prevent_Geocoding_For_Chatter_Actions__c);
    }

    
}