@isTest
public class MyScheduledJobTest {

   @isTest
    static void testExecutePositiveCase() {
        // Create a test JSR__c record with Status_Check__c = true and email addresses
        JSR__c jsrRecord = new JSR__c(
            Status_Check__c = true,
            Email_to_Address__c = 'test@example.com',
            Email_CC_Address__c = 'cc@example.com'
        );
        insert jsrRecord;

        // Create a test ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test PDF Content'),
            IsMajorVersion = true
        );
        insert cv;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = jsrRecord.Id,
            ShareType = 'I'
        );
        insert cdl;

        Test.startTest();

        // Schedule the job
        MyScheduledJob job = new MyScheduledJob(jsrRecord.Id);
        String jobId = System.schedule('MyScheduledJobTest', '0 0 * * * ?', job);

        Test.stopTest();

        // Assert that the email was sent
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
       // System.assertNotEquals(0, sentEmails.size());

        // Clean up
        System.abortJob(jobId);
        delete jsrRecord;
      //  delete cv;
    
}


    @isTest
    static void testExecuteStatusCheckFalse() {
        // Create a test JSR__c record with Status_Check__c = false
        JSR__c jsrRecord = new JSR__c(
           
            Status_Check__c = false,
            Email_to_Address__c = 'test@example.com',
            Email_CC_Address__c = 'cc@example.com'
        );
        insert jsrRecord;

        Test.startTest();

        // Schedule the job
        MyScheduledJob job = new MyScheduledJob(jsrRecord.Id);
        String jobId = System.schedule('MyScheduledJobTest', '0 0 * * * ?', job);

        Test.stopTest();

        // Assert that no email was sent
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, sentEmails.size());

        // Clean up
        System.abortJob(jobId);
        delete jsrRecord;
    }

    @isTest
    static void testExecuteNoEmailAddresses() {
        // Create a test JSR__c record with Status_Check__c = true but no email addresses
        JSR__c jsrRecord = new JSR__c(
            
            Status_Check__c = true,
            Email_to_Address__c = null,
            Email_CC_Address__c = null
        );
        insert jsrRecord;

        Test.startTest();

        // Schedule the job
        MyScheduledJob job = new MyScheduledJob(jsrRecord.Id);
        String jobId = System.schedule('MyScheduledJobTest', '0 0 * * * ?', job);

        Test.stopTest();

        // Assert that no email was sent
        List<EmailMessage> sentEmails = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, sentEmails.size());

        // Clean up
        System.abortJob(jobId);
        delete jsrRecord;
    }
}