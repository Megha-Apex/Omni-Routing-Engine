@isTest
public class TestPDFController {
    @isTest
    static void testPDFControllerConstructor() {
        // Create a test JSR__c record
        JSR__c testJSR = new JSR__c(/* Initialize test data */);
        insert testJSR;

        // Create a test ContentVersion
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Image',
            VersionData = Blob.valueOf('Test Data'),
            PathOnClient = 'testimage.jpg'
        );
        insert testContentVersion;

        // Create a test ContentDocument and link it to the JSR__c record
        ContentDocumentLink testCdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId,
            LinkedEntityId = testJSR.Id,
            ShareType = 'V'
        );
        insert testCdl;

        // Instantiate PDFController with a mocked StandardController
        ApexPages.StandardController stdController = new ApexPages.StandardController(testJSR);
        PDFController controller = new PDFController(stdController);

        // Call the constructor
        Test.startTest();
        // The constructor's queries will be executed now
        Test.stopTest();

        // Verify the results
        // Check values in controller.images and controller.jsrRecord
        System.assertEquals(1, controller.images.size(), 'Number of images should match');
        System.assertEquals(testJSR.Id, controller.jsrRecord.Id, 'JSR__c record Id should match');
    }

    @isTest
    static void testGetDataMethod() {
        // Create test data and set up the test environment
        JSR__c testJSR = new JSR__c(/* Initialize test data */);
        insert testJSR;

        // Create a test ContentVersion
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Image',
            VersionData = Blob.valueOf('Test Data'),
            PathOnClient = 'testimage.jpg'
        );
        insert testContentVersion;

        // Create a test ContentDocument and link it to the JSR__c record
        ContentDocumentLink testCdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId,
            LinkedEntityId = testJSR.Id,
            ShareType = 'V'
        );
        insert testCdl;

        // Instantiate PDFController with a mocked StandardController
        ApexPages.StandardController stdController = new ApexPages.StandardController(testJSR);
        PDFController controller = new PDFController(stdController);

        // Call the getData method
        Test.startTest();
        controller.getData();
        Test.stopTest();

        // Verify the expected behavior after calling getData
        // Add assertions here based on the expected behavior of your getData method
    }
}