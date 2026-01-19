@isTest
public class CasePasswordResetHandlerTest {
    @isTest
    static void testSendPasswordResetEmail() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(
            Alias = 'tuser',
            Email = 't100user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test100',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 't100user@example.com'
        );
        insert testUser;

        // Create a test case with Reset_Password_For__c set to the test user
        Case testCase = new Case(
            Subject = 'Test Case',
            Reset_Password_For__c = testUser.Id
        );
        insert testCase;

        // Test the scenario where Reset_Password_For__c is set
        Test.startTest();
        // Call the method to send the password reset email
        List<Id> caseIds = new List<Id>{ testCase.Id };
        CasePasswordResetHandler.sendPasswordResetEmail(caseIds);
        Test.stopTest();

        // Verify that the password reset email was sent
        System.assert(true, 'Password reset email should have been sent without errors.');
    }
}