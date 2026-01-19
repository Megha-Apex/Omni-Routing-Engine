@isTest 
public class PDFGeneratorTest {
    @isTest
    static void testGenerateAndAttachPDF() {
        // Create a test JSR record
        JSR__c testJSR = new JSR__c();
        insert testJSR;

        // Create a test ContentVersion associated with the testJSR
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test PDF';
        cv.PathOnClient = 'Test PDF.pdf';
        cv.VersionData = Blob.valueOf('Test PDF Content');
        cv.FirstPublishLocationId = testJSR.Id;
        cv.ContentLocation = 'S'; // 'S' for Salesforce
        insert cv;

        // Call the generateAndAttachPDF method
        Test.startTest();
        PDFGenerator.generateAndAttachPDF(testJSR.Id, 'Test PDF');
        Test.stopTest();

        // Query for the ContentVersion
        ContentVersion queriedCV = [SELECT Id, Title, PathOnClient, ContentLocation FROM ContentVersion WHERE FirstPublishLocationId = :testJSR.Id LIMIT 1];
		System.debug(queriedCV);
        // Verify that a ContentVersion was created
        System.assertNotEquals(null, queriedCV, 'ContentVersion should be created');

        // Add more assertions as needed to validate the ContentVersion and its attributes
        System.assertEquals('Test PDF', queriedCV.Title, 'ContentVersion Title should match');
        System.assertEquals('Test PDF.pdf', queriedCV.PathOnClient, 'ContentVersion PathOnClient should match');
        System.assertEquals('S', queriedCV.ContentLocation, 'ContentVersion ContentLocation should be Salesforce');
    }
}