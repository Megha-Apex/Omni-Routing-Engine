@isTest
private class NewUserPasswordResetActionTest {
    @isTest
    static void testResetNewUserPassword() {
        // Create test data
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];
        User newUser = new User(
            FirstName = 'Test123',
            LastName = 'User',
            Username = 'test123user@example.com',
            Email = 'test123user@example.com',
            Alias = 't123u',
            CommunityNickname = 'test123',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            UserRoleId = userRole.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert newUser;

        // Call the method to be tested
        Test.startTest();
        NewUserPasswordResetAction.resetNewUserPassword(new List<Id>{newUser.Id});
        Test.stopTest();
    }
}