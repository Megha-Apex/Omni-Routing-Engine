@isTest
public class CopyFileClassTest {

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

    @isTest
private static void testInsertServiceAppointmentWithTerritory_success() {
    
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
//        maintenancePlan.Street__c = '301 Bottomley Avenue North';
//        maintenancePlan.State_Territory__c = 'Saskatchewan';
//        maintenancePlan.Zip_Code__c = 'S7N 1L3';
//        maintenancePlan.Country__c = 'Canada';
//        maintenancePlan.City__c = 'Saskatoon';
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
    
    insert serviceAppointment;
 
        // Create test data for JSR__c records
        JSR__c testJSR = new JSR__c(
            Status_check__c = true,
            Service_Appointment__c = '08p8Y000002lDSnQAM'
        );
        insert testJSR;

        // Create test data for ContentVersion
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test PDF File',
            VersionData = Blob.valueOf('Test PDF Content'),
            PathOnClient = 'test.pdf'
        );
        insert testContentVersion;

        // Query the ContentDocumentId associated with the ContentVersion
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id LIMIT 1];

        // Create test data for ContentDocumentLink with a valid ContentDocumentId
        ContentDocumentLink testCdLink = new ContentDocumentLink(
            ContentDocumentId = testContentVersion.ContentDocumentId,
            LinkedEntityId = testJSR.Id,
            ShareType = 'I'
        );
        insert testCdLink;

    /*    // Create a related ServiceAppointment record
        ServiceAppointment testServiceAppointment = new ServiceAppointment(
            Work_Order__c = 'WO-001',
            // Add other required fields as needed
        );
        insert testServiceAppointment;*/

        // Link the ServiceAppointment to the JSR
        testJSR.Service_Appointment__c = serviceAppointment.Id;
        update testJSR;

        // Call the method to be tested
        Test.startTest();
        CopyFileClass.copyFiles(new List<Id>{ testJSR.Id });
        Test.stopTest();

        // Verify that the ContentDocumentLink was created for the Service Appointment record
        List<ContentDocumentLink> saCdLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testJSR.Service_Appointment__c
        ];
        System.assertEquals(1, saCdLinks.size(), 'ContentDocumentLink not created for Service Appointment');

        // Verify that the ContentDocumentLink was created for the Work Order record
        List<ContentDocumentLink> woCdLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN (SELECT Work_Order__c FROM ServiceAppointment WHERE Id = :testJSR.Service_Appointment__c)
        ];
        System.assertEquals(1, woCdLinks.size(), 'ContentDocumentLink not created for Work Order');
    }
}