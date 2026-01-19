@isTest
public class TestFileUploadTriggerclone {
    @isTest
    static void testTriggerLogic() {
        // Create a test Case
        Case testCase = new Case(Status = 'New');
        insert testCase;
        
        // Create a test WorkOrder related to the Case
        WorkOrder testWorkOrder = new WorkOrder(CaseId = testCase.Id);
        insert testWorkOrder;
        
        // Create a test ContentVersion
        ContentVersion testVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestPath',
            VersionData = Blob.valueOf('Test Content')
        );
        insert testVersion;
        
        // Create a test ContentDocument
        ContentDocumentLink testLink = new ContentDocumentLink(
            LinkedEntityId = testCase.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testVersion.Id].ContentDocumentId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        
        Test.startTest();
        // Insert the test ContentDocumentLink
        insert testLink;
        Test.stopTest();
        
        // Verify that the ContentDocumentLink is cloned to the related WorkOrder
        List<ContentDocumentLink> clonedLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testWorkOrder.Id];
        System.assertEquals(1, clonedLinks.size(), 'The ContentDocumentLink was not cloned to the related WorkOrder.');
    }
}