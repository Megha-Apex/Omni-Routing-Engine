@isTest
private class TargetDateTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Profile for User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'FS Mobile TECHNICIANS' LIMIT 1];

        // Create User (Taylor, Chase)
        User u = new User(
            Alias = 'taycha',
            Email = 'taylor.chase@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Taylor',
            FirstName = 'Chase',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Denver',
            Username = 'taylor.chase.3005729@example.com.testuser'
        );
        insert u;

        // Create ServiceResource (Taylor, Chase)
        ServiceResource sr = new ServiceResource(
            Name = 'Taylor, Chase',
            IsActive = true,
            RelatedRecordId = u.Id,
            ResourceType = 'T'
        );
        insert sr;

        // Create OperatingHours
        OperatingHours oh = new OperatingHours(
            Name = 'US Mountain Shift',
            TimeZone = 'America/Denver'
        );
        insert oh;

        // Create ServiceTerritory
        ServiceTerritory st = new ServiceTerritory(
            Name = 'NM',
            IsActive = true,
            OperatingHoursId = oh.Id
        );
        insert st;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New'
        );
        insert wo;

        // Create ServiceTerritoryMember
        ServiceTerritoryMember stm = new ServiceTerritoryMember(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = st.Id,
            TerritoryType = 'P',
            EffectiveStartDate = DateTime.newInstance(2025, 6, 10),
            EffectiveEndDate = DateTime.newInstance(2026, 6, 10)
        );
        insert stm;

        // Create Shift
        Shift sh = new Shift(
            ServiceTerritoryId = st.Id,
            StartTime = Datetime.newInstance(2025, 6, 10, 11, 0, 0), // 8:00 AM MDT
            EndTime = Datetime.newInstance(2025, 6, 10, 23, 0, 0), // 5:00 PM MDT
            Status = 'Confirmed',
            ServiceResourceId = sr.Id
        );
        insert sh;

        // Create Service Appointments with initial type
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        for (Integer i = 0; i < 5; i++) {
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'Dispatched', // Start with Dispatched
                SchedStartTime = Datetime.newInstance(2025, 6, 10, 10, 0, 0), // 2:17 PM MDT
                SchedEndTime = Datetime.newInstance(2025, 6, 10, 11, 0, 0),
                ArrivalWindowStartTime = Datetime.newInstance(2025, 6, 10, 8, 0, 0),
                ArrivalWindowEndTime = Datetime.newInstance(2025, 6, 10, 16, 0, 0),
                ServiceTerritoryId = st.Id,
                Duration = 60,
                DurationType = 'Minutes',
                Description = 'Test Appointment',
                EarliestStartTime = Datetime.newInstance(2025, 6, 10, 9, 0, 0), // 1:17 PM MDT
                DueDate = Datetime.newInstance(2025, 6, 10, 12, 0, 0) // 4:17 PM MDT
            );
            appointments.add(sa);
        }
        insert appointments;

        // Create AssignedResources
        List<AssignedResource> assignedResources = new List<AssignedResource>();
        for (ServiceAppointment sa : appointments) {
            AssignedResource ar = new AssignedResource(
                ServiceAppointmentId = sa.Id,
                ServiceResourceId = sr.Id,
                EstimatedTravelTime = 15
            );
            assignedResources.add(ar);
        }
        insert assignedResources;
    }
    
    @isTest
    static void testNoAssignedResource() {
        Test.startTest();
        
        // Retrieve the ServiceAppointment
        ServiceAppointment sa = [SELECT Id, ETA_Date_Time__c, SchedStartTime, Status FROM ServiceAppointment LIMIT 1];
        
        // Update to Tentative without AssignedResource
        sa.Status = 'Dispatched';
        update sa;

        Test.stopTest();

        // Retrieve the updated record
        ServiceAppointment updatedSa = [SELECT Id, ETA_Date_Time__c, SchedStartTime, Status FROM ServiceAppointment WHERE Id = :sa.Id];
        
        // Assertion: Check if ETA_Date_Time__c is null when no AssignedResource is present
        System.assertEquals(null, updatedSa.ETA_Date_Time__c, 'ETA_Date_Time__c should be null when no AssignedResource is present');
    }
    
    @isTest
    static void testWithAssignedResource() {
        Test.startTest();
        
        // Retrieve ServiceAppointments, AssignedResources, and Shift
        List<ServiceAppointment> appointments = [SELECT Id, ETA_Date_Time__c, SchedStartTime, SchedEndTime, ArrivalWindowStartTime, ArrivalWindowEndTime, 
                                                CreatedDate, Type_of_Appointment__c, Status, EarliestStartTime 
                                                FROM ServiceAppointment];
        List<AssignedResource> assignedResources = [SELECT Id, ServiceAppointmentId, ServiceResourceId, EstimatedTravelTime 
                                                  FROM AssignedResource];
        Shift sh = [SELECT Id, StartTime, EndTime FROM Shift LIMIT 1];

        // Step 1: Move from 'Open' to 'Dispatched' with type update
        List<String> appointmentTypes = new List<String>{'PMI', 'Arrival Window', 'Hard Start', 'MTTR', 'All Day'};
        for (Integer i = 0; i < appointments.size(); i++) {
            appointments[i].Status = 'Dispatched';
            appointments[i].Type_of_Appointment__c = appointmentTypes[i];
            System.debug('Before update - SA: ' + JSON.serializePretty(appointments[i]));
        }
        update appointments;

        Test.stopTest();

        // Verify updates
        List<ServiceAppointment> updatedAppointments = [SELECT Id, ETA_Date_Time__c, ETA__c, Type_of_Appointment__c, SchedStartTime, 
                                                       ArrivalWindowStartTime, ArrivalWindowEndTime, CreatedDate, SchedEndTime, EarliestStartTime 
                                                       FROM ServiceAppointment];
        for (ServiceAppointment sa : updatedAppointments) {
            System.debug('Updated Appointment: ' + JSON.serializePretty(sa));
            if (sa.Type_of_Appointment__c == 'PMI') {
                System.assertNotEquals(null, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should be set for PMI');
                System.assertEquals(sa.SchedStartTime, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should match SchedStartTime');
            } else if (sa.Type_of_Appointment__c == 'Arrival Window') {
                System.assertNotEquals(null, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should be set for Arrival Window');
                System.assertEquals(sa.ArrivalWindowStartTime, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should match ArrivalWindowStartTime');
            } else if (sa.Type_of_Appointment__c == 'Hard Start') {
                System.assertNotEquals(null, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should be set for Hard Start');
                System.assertEquals(sa.ArrivalWindowEndTime, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should match ArrivalWindowEndTime');
            } else if (sa.Type_of_Appointment__c == 'MTTR') {
                System.assertNotEquals(null, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should be set for MTTR');
                System.assertEquals(sa.CreatedDate, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should match CreatedDate');
            } else if (sa.Type_of_Appointment__c == 'All Day') {
                System.assertNotEquals(null, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should be set for All Day');
               System.assertEquals(sa.SchedEndTime, sa.ETA_Date_Time__c, 'ETA_Date_Time__c should match SchedEndTime');
            }
        }
    }
}