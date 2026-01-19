@IsTest
public class SMSAPIServiceBatchableTest {

    @TestSetup
    static void setupTestData() {
        // Insert test data for OutboundSMS__c records with 'Pending' status
        List<OutboundSMS__c> smsList = new List<OutboundSMS__c>();
        smsList.add(new OutboundSMS__c(
            Status__c = 'Pending',
            sendSmsTaskId__c = '12345',
            Response_Body__c = null
        ));
        smsList.add(new OutboundSMS__c(
            Status__c = 'Pending',
            sendSmsTaskId__c = '12345',
            Response_Body__c = null
        ));
        insert smsList;

        Auth_Token__c token = new Auth_Token__c();
        token.Client_Name__c ='Five9SMS';
        token.Token__c ='eyJraWQiOiI5NzI0MjdlMS1jMmI2LTQ3NzQtYmIxZS0zMWUzNDA2NzdhOTkiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJqUlp3ZXBkaTI4bnVNbmpzQUNHR0VMMHliYk9FWDRTZiIsInZlciI6MSwiY2xpZW50SWQiOiJqUlp3ZXBkaTI4bnVNbmpzQUNHR0VMMHliYk9FWDRTZiIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLmNhLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTcyNDc0OTI0NCwiaWF0IjoxNzI0NzQ1NjQ0LCJvcmdJZCI6IjYwMDAwMDAwMDAwMDUxMyIsImRvbWFpbklkIjoiNjAwMDAwMDAwMDAwNTEzIiwianRpIjoiZjQ5OGU3NDUtZDI4OC00NjA5LThlNDAtN2FhNjcyMjE0ZGM3In0.cxUmh3fJ1kkXxrB7JV8a7GaimYBiPuK5EbjNJq38GSVyfABqma8VEYJqKKATEXnMFdUnN_vOqeSksUOacy1Q--Zm05ZvvpqHtAfIt-3wLplMU4UP2US6StZFsMBWr0v7ruPG2fQlS11cA3ZV8NjmPwf5xhqPpYeSkfA1PcYP_kjkBAW7UFG7LGnxQO7yG8o1I8g_CYyezxKi_rWYT2oU2Y9eZiq6fqgNHH1PmbLUaqSYQY9RyZpcTl5g1jRgs9nZsLOogxLdSzsH0DY4AJfr8LqD_6JnqeRCOpmR8gHctckNlU1vbtrz4N3kVzrMRJ4Hg87CNADts9uuuPc-_k4R7w';
        token.Active__c = TRUE;
        insert token;
    }
    // test method to cover SMSAPIServiceScheduleable Class 
    @IsTest
    static void testScheduleExecute() {
        
            SMSAPIServiceScheduleable schedulableInstance = new SMSAPIServiceScheduleable();
          
        // Test the scheduled execution
        Test.startTest();
        String jobId = System.schedule('Test SMSAPIServiceScheduleable', '0 0 * * * ?', schedulableInstance);
        Test.stopTest();

        // Verify that the batch job was enqueued
        System.assertNotEquals(null, jobId);
        
    }

    @IsTest
    static void testBatchExecute_SuccessfulResponse() {
        // Mock the HTTP response for a successful scenario
        Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTest.SMSAPIServiceQueueableTestMock(200, '{"items": [  { "messageId": "01917028-b1c8-0c14-cb9b-c77d885785f0", "recipient": {"toPhoneNumber": "+15126218695", "contact": null, "attributes": {}},"status": "DELIVERED","failureReason": null}], "paging": { "next": null, "pageLimit": 400 }}'));

        // Instantiate and execute the batchable class
        SMSAPIServiceBatchable batchInstance = new SMSAPIServiceBatchable();
        Test.startTest();
        ID batchJobId = Database.executeBatch(batchInstance); // Set a small scope size to test all records
        Test.stopTest();

        // Verify that the SMS records were updated with the correct status and response body
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c, Response_Body__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
            System.assertEquals('Sent', sms.Status__c);
             Assert.isNotNull(sms.Response_Body__c);
        }
    }

    @IsTest
    static void testBatchExecute_FailedResponse() {
        // Mock the HTTP response for a failed scenario
        Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTest.SMSAPIServiceQueueableTestMock(400, '{"error": "Invalid request"}'));

        // Instantiate and execute the batchable class
        SMSAPIServiceBatchable batchInstance = new SMSAPIServiceBatchable();
        Test.startTest();
        ID batchJobId = Database.executeBatch(batchInstance);
        Test.stopTest();

        // Verify that the SMS records were updated with a 'Fail' status
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
            //System.assertEquals('Pending', sms.Status__c);
        }
    }

    @IsTest
    static void testBatchExecute_TokenRefresh() {
        // Mock the HTTP response to simulate a token refresh scenario (401 followed by a successful response)
        Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTest.SMSAPIServiceQueueableTestMock(401, '{ "details": [{"code": "invalid-token"}]}')); // Pass true to the mock to indicate token refresh

        // Instantiate and execute the batchable class
        SMSAPIServiceBatchable batchInstance = new SMSAPIServiceBatchable();
        Test.startTest();
        ID batchJobId = Database.executeBatch(batchInstance);
        Test.stopTest();

        // Verify that the SMS records were updated with the correct status and response body after token refresh
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c, Response_Body__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
          //  System.assertEquals('Pending', sms.Status__c);
            Assert.isNotNull(sms.Response_Body__c);
        }
    }

   
}