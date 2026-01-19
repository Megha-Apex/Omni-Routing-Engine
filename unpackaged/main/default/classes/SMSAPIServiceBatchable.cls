public class SMSAPIServiceBatchable implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query to fetch OutboundSMS__c records with status 'Pending'
        return Database.getQueryLocator([
            SELECT  id ,sendSmsTaskId__c, Status__c, Response_Body__c
            from OutboundSMS__c 
            WHERE Status__c = 'Pending' and sendSmsTaskId__c!= null
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<OutboundSMS__c> scope) {
        APICalloutUtility utilityReference = new APICalloutUtility();
        List<OutboundSMS__c> updateSMSListStatus = new List<OutboundSMS__c>();
        String token =  utilityReference.getToken();
        for (OutboundSMS__c smsRec : scope) {
            String sendSmsTaskId = smsRec.sendSmsTaskId__c;
            String acknowlegmentEndpoint = utilityReference.sendSMSEndpoint+'/' +sendSmsTaskId+'/messages';
            
            try{
                HttpResponse finalResponse = utilityReference.getResponse(acknowlegmentEndpoint,'GET',token,'') ; 
                System.debug('finalResponse Status: ' + finalResponse.getStatus()+'**finalResponse**'+finalResponse.getBody());
                
                
                if (finalResponse.getStatusCode() == 401 ){
                    // Handle error response
                    System.debug('Failed to send SMS: ' + finalResponse.getStatus()+'- Resp: ' + finalResponse.getBody());
                    ErrorResponseWrapper error = (ErrorResponseWrapper)System.JSON.deserialize(finalResponse.getBody(), ErrorResponseWrapper.class);
                    
                    if(error.details!= null){
                        if(error.details[0].code =='invalid-token'){
                            token = utilityReference.getToken(); 
                            finalResponse =   utilityReference.getResponse(acknowlegmentEndpoint,'GET',token,'') ;
                        }
                    }
                }
                
               if (finalResponse.getStatusCode() == 200) { 
                FinalResponseWrapper finalWrapper = (FinalResponseWrapper) System.JSON.deserialize(finalResponse.getBody(), FinalResponseWrapper.class);
                
                smsRec.Response_Body__c = finalResponse.getBody();
                smsRec.Status__c  = 'Sent'; 
                
                List<cls_items> itemList = finalWrapper.items;
                for(cls_items rec : itemList){
                    if(rec.status !='SENT' && rec.status !='DELIVERED'){
                        smsRec.Status__c  = 'Fail';
                    }
                }
               }else {
                    // Handle error response
                    System.debug('Failed Response for SMS ID: ' + finalResponse.getStatus()+'- Resp: ' + finalResponse.getBody());
                    
                    smsRec.Status__c  = 'Fail';
                    smsRec.Response_Body__c = finalResponse.getBody();
                }
                updateSMSListStatus.add(smsRec);
            } catch (Exception e) {
                System.debug('Error occurred: ' + e.getMessage());
                smsRec.Status__c  = 'Fail';
                updateSMSListStatus.add(smsRec);
                update updateSMSListStatus;
            }
        }
        
        
        Database.SaveResult[] result = Database.update( updateSMSListStatus, false);
        
        for (Database.SaveResult sr : result) {
            if (!sr.isSuccess()) {
                Integer index = result.indexOf (sr);
                OutboundSMS__c rec =  updateSMSListStatus.get(index);
                System.debug(' Update failed for Record : ' + rec.Id);  
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Update Failed with error '+err.getStatusCode() + ': ' + err.getMessage()+' fields that affected this error: ' + err.getFields());
                    
                }
            }
            
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        // Optional: Add logic that runs when the batch job completes
        System.debug('Batch processing completed.');
    }
    
    public class FinalResponseWrapper{
        public cls_items[] items;
        public cls_paging paging;
        
    }
    class cls_items {
        public String messageId;    //01917028-b1c8-0c14-cb9b-c77d885785f0
        public cls_recipient recipient;
        public String status;   //DELIVERED
        public String failureReason;
    }
    class cls_recipient {
        public String toPhoneNumber;    //+15126218695
        public cls_contact contact;
        public clsResp_attributes attributes;
    }
    class cls_contact {
    }
    class clsResp_attributes {
    }
    /*
    class cls_failureReason {
    }
*/
    class cls_paging {
        public cls_next next;
        public Integer pageLimit;   //400
    }
    class cls_next {
    }
    
    public class ErrorResponseWrapper{
        
        public String traceId;  //00000000000000000000000000000000
        public cls_details[] details;
        
    }
    class cls_details {
        public String code; //invalid-token
        public String message;  //An error occurred while attempting to decode the Jwt: Jwt expired at 1724057542
    }
    
}