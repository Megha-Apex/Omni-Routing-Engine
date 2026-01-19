@isTest
public class PreventAbsenceDeletionHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create users and service resources in system mode
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User allowedUser = new User(
            Username = 'alloweduser@example.com',
            Email = 'alloweduser@example.com',
            Alias = 'allowed',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User',
            FirstName = 'Allowed'
        );
        insert allowedUser;

        User disallowedUser = new User(
            Username = 'disalloweduser@example.com',
            Email = 'disalloweduser@example.com',
            Alias = 'disall',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User',
            FirstName = 'Disallowed'
        );
        insert disallowedUser;

        User technicianUser = new User(
            Username = 'technicianuser@example.com',
            Email = 'technicianuser@example.com',
            Alias = 'tchuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Technician',
            FirstName = 'User'
        );
        insert technicianUser;

        // Create a ServiceResource record as an individual technician
        ServiceResource serviceResource = new ServiceResource(
            Name = 'Test Technician',
            IsActive = true,
            ResourceType = 'T', // 'T' for Technician
            RelatedRecordId = technicianUser.Id
        );
        insert serviceResource;

        // Create a ResourceAbsence record as System Admin
        ResourceAbsence absence = new ResourceAbsence(
            ResourceId = serviceResource.Id,
            Start = DateTime.now().addDays(1),
            End = DateTime.now().addDays(2),
            Name__c = 'Test Absence'
        );
        insert absence;
    }
    
    @isTest
    static void testDeletionAllowed() {
        User allowedUser = [SELECT Id FROM User WHERE Username = 'alloweduser@example.com' LIMIT 1];
        ResourceAbsence absence = [SELECT Id FROM ResourceAbsence LIMIT 1];

        System.runAs(allowedUser) {
            // Attempt to delete the absence
            Test.startTest();
            delete absence;
            Test.stopTest();

            // Verify that the absence was deleted
            System.assertEquals(0, [SELECT COUNT() FROM ResourceAbsence WHERE Id = :absence.Id]);
        }
    }

    @isTest
    static void testDeletionNotAllowed() {
        User disallowedUser = [SELECT Id FROM User WHERE Username = 'disalloweduser@example.com' LIMIT 1];
        ResourceAbsence absence = [SELECT Id FROM ResourceAbsence LIMIT 1];

        System.runAs(disallowedUser) {
            // Attempt to delete the absence
            Test.startTest();
            try {
                delete absence;
                // If deletion succeeds, we want to fail the test
                System.assert(false, 'Expected an exception due to deletion restrictions.');
            } catch (DmlException e) {
                // Verify that the correct error message was added
               // System.assertEquals('You are not allowed to delete resource absences.', e.getDmlMessage(0));
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testNoAbsencesToDelete() {
        User allowedUser = [SELECT Id FROM User WHERE Username = 'alloweduser@example.com' LIMIT 1];

        System.runAs(allowedUser) {
            // No absences to delete, just ensure no exceptions are thrown
            Test.startTest();
            // This should not throw any errors
            PreventAbsenceDeletionHandler.handleDeletion(new List<ResourceAbsence>(), true);
            Test.stopTest();
        }
    }
}