public class SMSAPIServiceQueueable implements Queueable, Database.AllowsCallouts{
    private List<OutboundSMS__c> smsRecords ;
    public SMSAPIServiceQueueable(List<OutboundSMS__c> smsList){
        this.smsRecords = smsList;
    }
    
    public void execute(QueueableContext context) {
        List<OutboundSMS__c> updateSMSList = new List<OutboundSMS__c>();
        APICalloutUtility utilityReference = new APICalloutUtility();
        //Get the access token
        String token = utilityReference.getToken();
        for (OutboundSMS__c sms : smsRecords){
            RequestWrapper requestBody = new RequestWrapper();
            List<cls_recipients> recipentList = new  List<cls_recipients>();
            requestBody.campaignName = sms.campaignName__c;
            requestBody.dispositionName = sms.dispositionName__c;
            requestBody.message = sms.message__c;
            
            List<String> phoneNumbers = sms.toPhoneNumber__c.split(',');
            for(String phoneNumber: phoneNumbers){
                cls_recipients recipent = new cls_recipients();
                recipent.toPhoneNumber = '+'+phoneNumber;
                recipentList.add(recipent);
            }
            requestBody.recipients = recipentList;
            cls_attributes att = new cls_attributes();
            att.timestamp = sms.timestamp__c;
            requestBody.attributes = att;
            
            String endpoint = utilityReference.sendSMSEndpoint;
            
            // Set up the request body
            String serializeRequestBody = JSON.serializePretty(requestBody);
            serializeRequestBody = serializeRequestBody.replace('\\\\', '\\');
            
            OutboundSMS__c newSMSRecordInstance = new OutboundSMS__c();
            newSMSRecordInstance.Id = sms.Id;
            
            try {  
                
                HttpResponse res =  utilityReference.getResponse(endpoint,'POST',token,serializeRequestBody) ;
                 
                if (res.getStatusCode() == 401 ){
                    // Handle error response
                    System.debug('Failed to send SMS: ' + res.getStatus()+'- Resp: ' + res.getBody());
                    
                    ErrorResponseWrapper error = (ErrorResponseWrapper)System.JSON.deserialize(res.getBody(), ErrorResponseWrapper.class);
                    
                    if(error.details!= null){
                        if(error.details[0].code =='invalid-token'){
                            token = utilityReference.getToken(); 
                            res =  utilityReference.getResponse(endpoint,'POST',token,serializeRequestBody) ;
                        }
                    }
                }
                
                if (res.getStatusCode() == 202) {
                    // Handle successful response
                    System.debug('SMS sent successfully.** Resp**: ' + res.getBody());
                    
                    SMSTaskIDResponseWrapper taskIDWrapper = (SMSTaskIDResponseWrapper) System.JSON.deserialize(res.getBody(), SMSTaskIDResponseWrapper.class);
                    String  sendSmsTaskId = taskIDWrapper.sendSmsTaskId;
                    newSMSRecordInstance.sendSmsTaskId__c = sendSmsTaskId;
                    newSMSRecordInstance.Status__c  = 'Pending'; 
                    
                } else {
                    // Handle error response
                    System.debug('Failed to send SMS: ' + res.getStatus()+'- Resp: ' + res.getBody());
                    
                    newSMSRecordInstance.Status__c  = 'Fail';
                }
                updateSMSList.add(newSMSRecordInstance);   
            } catch (Exception e) {
                System.debug('Error occurred: ' + e.getMessage());
                newSMSRecordInstance.Status__c  = 'Fail';
                updateSMSList.add(newSMSRecordInstance);
                update updateSMSList;
            }
            
        }
        
        update updateSMSList;
    }
    
    
    //Wrapper Classes
    
    public class RequestWrapper{
        public String campaignName;	//LTS -- Outbound SMS
        public String dispositionName;	//TEST GENERAL
        public String message;	
        public cls_attributes attributes;
        public cls_recipients[] recipients;
        
        
    }
    class cls_attributes {
        public String timestamp;	//&&__TIME__&&
    }
    class cls_recipients {
        public String toPhoneNumber;	//+19023002382
    }
    
    public class SMSTaskIDResponseWrapper{
        public String sendSmsTaskId;	//01913786-3174-d52a-b617-0c917c4163b5
        public String uri;	///send-sms-svc/v1/domains/600000000000513/send-sms-tasks/01913786-3174-d52a-b617-0c917c4163b5
        
    }
    
    public class ErrorResponseWrapper{
        
        public String traceId;	//00000000000000000000000000000000
        public cls_details[] details;
        
    }
    class cls_details {
        public String code;	//invalid-token
        public String message;	//An error occurred while attempting to decode the Jwt: Jwt expired at 1724057542
    }
    
    
}