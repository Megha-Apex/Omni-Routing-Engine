@isTest(SeeAllData=true)
public with sharing class CandidateFetcherQueueableTest {

    @isTest
    static void testCandidateFetcherQueueable() {
        // 1. Hardcoded IDs (Ensure these exist in your org)
        Id requestTypeId = 'a0t3h000001P6STAA0'; // Verify this exists
        Id caseId = '500OI00000KVfEnYAL';       // Verify this exists
        Id customerAccountId = '0013h00000StelgAAB'; // Verify this exists
        Id subCustomerAccountId = '0013h00000StelqAAB';// Verify this exists
        Id slaId = 'a0u3h000000WLgQAAW';        // Verify this exists
        Id slaMemberId = 'a0vOI0000050QinYAE';    // Verify this exists
        Id siteId = '0013h00000Stx8IAAR';       // Verify this exists
        Id serviceTypeId = 'a0x3h000000GgadAAC'; // Verify this exists
        Id serviceTerritoryId = '0HhOI0000000FDZ0A2'; // Verify this exists

        // Start Test
        Test.startTest();

        // **Data Setup (Focus on Minimal Requirements)**
        // 1. Create a Profile (System Administrator)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        System.assertNotEquals(null, p, 'System Administrator profile not found');

        // 2. Create a User
        User u = new User(
            Alias = 'fsltest',
            Email = 'fsltest@example.com' + DateTime.now().getTime(), //Unique
            EmailEncodingKey = 'UTF-8',
            FirstName = 'FSL',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'fsltest@example.com' + DateTime.now().getTime() //Unique
        );
        insert u;

        // 3. Create Operating Hours
        OperatingHours oh = new OperatingHours(Name = '24x7', TimeZone = 'America/Los_Angeles');
        insert oh;

        // 4. Verify the Service Territory Exists
        List<ServiceTerritory> stList = [SELECT Id, IsActive FROM ServiceTerritory WHERE Id = :serviceTerritoryId];
        System.assert(!stList.isEmpty(), 'ServiceTerritory with ID ' + serviceTerritoryId + ' does not exist.');
        ServiceTerritory st = stList[0];

        // 5. Create a Service Resource
        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            ResourceType = 'T',//Technician
            RelatedRecordId = u.Id
        );
        insert sr;

        // 6. Create a ServiceTerritoryMember
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceTerritoryId = st.Id,
            ServiceResourceId = sr.Id,
            TerritoryType = 'P',  // Primary
            EffectiveStartDate = Date.today().addDays(-1),
            EffectiveEndDate = Date.today().addYears(1)
        );
        insert stm;

        // 7. Create a WorkOrder
        WorkOrder wo = new WorkOrder(
            Sub_Customer__c = subCustomerAccountId,
            SLA__c = slaMemberId,
            Service_Type__c = serviceTypeId,
            SiteID__c = siteId,
            Bill_to_Customer__c = customerAccountId,
            Request_Type__c = requestTypeId
        );
        insert wo;

        wo.Vendor_Status__c = 'Ticket Acceptance';
        update wo;

        // 8. Create a Service Appointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Open',
            Work_Order__c = wo.Id,
            Bill_to_Customer__c = customerAccountId,
            Sub_Customer__c = subCustomerAccountId,
            Site__c = siteId,
            ServiceTerritoryId = st.Id, // Using hardcoded service territory ID
            Service_Type__c = serviceTypeId,
            Do_Not_Use_SA__c = true
        );
        insert sa;

        // Explicitly Enqueue the Queueable
        CandidateFetcherQueueable queueable = new CandidateFetcherQueueable(new List<Id>{sa.Id}, false);
        System.enqueueJob(queueable);

        // Stop Test
        Test.stopTest();

        // 9. Assertions
        List<AsyncApexJob> jobs = [SELECT Id, Status, ApexClass.Name FROM AsyncApexJob WHERE ApexClass.Name = 'CandidateFetcherQueueable'];
        System.assertEquals(104, jobs.size(), 'CandidateFetcherQueueable should have been enqueued.');
        System.assertEquals('Completed', jobs[0].Status, 'CandidateFetcherQueueable should have completed.');

        ServiceAppointment updatedSA = [SELECT Id, Active_Technician__c FROM ServiceAppointment WHERE Id = :sa.Id];
        System.assertNotEquals(null, updatedSA.Active_Technician__c, 'Active_Technician__c should be populated by CandidateFetcherQueueable.');

        System.debug('Updated Service Appointment: ' + updatedSA);
    }
}