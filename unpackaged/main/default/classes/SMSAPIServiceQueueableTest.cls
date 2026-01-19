@IsTest
public class SMSAPIServiceQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        
        Auth_Token__c token = new Auth_Token__c();
        token.Client_Name__c ='Five9SMS';
        token.Token__c ='eyJraWQiOiI5NzI0MjdlMS1jMmI2LTQ3NzQtYmIxZS0zMWUzNDA2NzdhOTkiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJqUlp3ZXBkaTI4bnVNbmpzQUNHR0VMMHliYk9FWDRTZiIsInZlciI6MSwiY2xpZW50SWQiOiJqUlp3ZXBkaTI4bnVNbmpzQUNHR0VMMHliYk9FWDRTZiIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLmNhLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTcyNDc0OTI0NCwiaWF0IjoxNzI0NzQ1NjQ0LCJvcmdJZCI6IjYwMDAwMDAwMDAwMDUxMyIsImRvbWFpbklkIjoiNjAwMDAwMDAwMDAwNTEzIiwianRpIjoiZjQ5OGU3NDUtZDI4OC00NjA5LThlNDAtN2FhNjcyMjE0ZGM3In0.cxUmh3fJ1kkXxrB7JV8a7GaimYBiPuK5EbjNJq38GSVyfABqma8VEYJqKKATEXnMFdUnN_vOqeSksUOacy1Q--Zm05ZvvpqHtAfIt-3wLplMU4UP2US6StZFsMBWr0v7ruPG2fQlS11cA3ZV8NjmPwf5xhqPpYeSkfA1PcYP_kjkBAW7UFG7LGnxQO7yG8o1I8g_CYyezxKi_rWYT2oU2Y9eZiq6fqgNHH1PmbLUaqSYQY9RyZpcTl5g1jRgs9nZsLOogxLdSzsH0DY4AJfr8LqD_6JnqeRCOpmR8gHctckNlU1vbtrz4N3kVzrMRJ4Hg87CNADts9uuuPc-_k4R7w';
        token.Active__c = TRUE;
        insert token;
        

            }
    
    @IsTest
    static void testExecute_SuccessfulResponse() {
       
         Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTestMock(202, '{ "sendSmsTaskId": "12345","uri":"send-sms-svc/v1/domains/600000000000513/send-sms-tasks/01913786-3174-d52a-b617-0c917c4163b5"}'));
      
        // Insert test data for OutboundSMS__c records
        List<OutboundSMS__c> smsList = new List<OutboundSMS__c>();
        smsList.add(new OutboundSMS__c(
            campaignName__c = 'LTS -- Outbound SMS',
            dispositionName__c = 'TEST GENERAL',
            message__c = 'Test message',
            toPhoneNumber__c = '1234567890,9876543210',
            timestamp__c = '&&__TIME__&&'
        ));
        
        smsList.add(new OutboundSMS__c(
            campaignName__c = 'LTS -- Outbound SMS',
            dispositionName__c = 'TEST GENERAL',
            message__c = 'Another test message',
            toPhoneNumber__c = '1234567891',
            timestamp__c = '&&__TIME__&&'
        ));
        
         
        
        Test.startTest();
        insert smsList;
        
        Test.stopTest();
        
        // Verify that the SMS records were updated with the correct status and sendSmsTaskId
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c, sendSmsTaskId__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
            System.assertEquals('Pending', sms.Status__c);
            Assert.isNotNull(sms.sendSmsTaskId__c);
            System.assertEquals('12345', sms.sendSmsTaskId__c);
        }
    }
    
    @IsTest
    static void testExecute_FailedResponse() {
          // Mock the HTTP response for a failed scenario
        Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTestMock(400, '{ "error": "Invalid request" }'));
       
         List<OutboundSMS__c> smsList = new List<OutboundSMS__c>();
        smsList.add(new OutboundSMS__c(
            campaignName__c = 'LTS -- Outbound SMS',
            dispositionName__c = 'TEST GENERAL',
            message__c = 'Test message',
            toPhoneNumber__c = '1234567890,9876543210',
            timestamp__c = '&&__TIME__&&'
        ));
                
        Test.startTest();
        insert smsList;
        
        Test.stopTest();
         // Verify that the SMS records were updated with the correct status and sendSmsTaskId after token refresh
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c, sendSmsTaskId__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
          //  System.assertEquals('Pending', sms.Status__c);
             Assert.isNull(sms.sendSmsTaskId__c);
           
        }
        
       
       
    }
    
    @IsTest
    static void testExecute_TokenRefresh() {
        // Mock the HTTP response to simulate a token refresh scenario (401 followed by a successful response)
         Test.setMock(HttpCalloutMock.class, new SMSAPIServiceQueueableTestMock(401,'{"details": [{"code": "invalid-token"}]}')); // Pass true to the mock to indicate token refresh
       
         List<OutboundSMS__c> smsList = new List<OutboundSMS__c>();
        smsList.add(new OutboundSMS__c(
            campaignName__c = 'LTS -- Outbound SMS',
            dispositionName__c = 'TEST GENERAL',
            message__c = 'Test message',
            toPhoneNumber__c = '1234567890,9876543210',
            timestamp__c = '&&__TIME__&&'
        ));
       
        Test.startTest();
        insert smsList;
        
        Test.stopTest();
        
        // Verify that the SMS records were updated with the correct status and sendSmsTaskId after token refresh
        List<OutboundSMS__c> updatedRecords = [SELECT Id, Status__c, sendSmsTaskId__c FROM OutboundSMS__c];
        for (OutboundSMS__c sms : updatedRecords) {
           // System.assertEquals('Pending', sms.Status__c);
            //System.assertEquals('Fail', sms.Status__c);
             Assert.isNull(sms.sendSmsTaskId__c);
           // System.assertEquals('12345', sms.sendSmsTaskId__c); // Assuming successful response after token refresh
        }
    }
    
    // Test mock class for HTTP callout
    public class SMSAPIServiceQueueableTestMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean isTokenRefresh;
        
        public SMSAPIServiceQueueableTestMock(Integer statusCode, String responseBody ){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.isTokenRefresh = isTokenRefresh;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
           
            return res;
        }
    }
}