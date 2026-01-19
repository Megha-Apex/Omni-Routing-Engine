@isTest
public class ContentDocumentLinkHelperTest {

    @isTest
    static void testProcessAfterInsert() {
        // Create a test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Stage__c = 'New'
        );
        insert testCase;

        // Create a test email message
        EmailMessage testEmail = new EmailMessage(
            Subject = 'Test Email',
            FromName = 'Test Sender',
            ToAddress = 'test@example.com',
            ParentId = testCase.Id
            //Status = 'New'
        );
        insert testEmail;

        // Create a test content version
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is a test file.')
        );
        insert contentVersion;

        // Query the ContentDocumentId from ContentVersion
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        System.debug('ContentVersion: ' + contentVersion);

        // Create a ContentDocumentLink for the email message
        ContentDocumentLink cdlEmail = new ContentDocumentLink(
            ContentDocumentId = contentVersion.ContentDocumentId,
            LinkedEntityId = testEmail.Id,
            ShareType = 'V', // Inferred permissions
            Visibility = 'AllUsers' // Set visibility as needed
        );
        insert cdlEmail;

        // Simulate the trigger after insert
        Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>([SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE Id = :cdlEmail.Id]);
        System.debug('cdlMap: ' + cdlMap);

        Test.startTest();
        ContentDocumentLinkHelper.processAfterInsert(cdlMap);
        Test.stopTest();

        // Verify that a new ContentDocumentLink has been created for the case
        List<ContentDocumentLink> caseLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testCase.Id];
        System.debug('caseLinks: ' + caseLinks);
        System.assertEquals(1, caseLinks.size(), 'A ContentDocumentLink should be created for the case.');
        System.assertEquals(contentVersion.ContentDocumentId, caseLinks[0].ContentDocumentId, 'The ContentDocumentId should match the original document.');
    }
}