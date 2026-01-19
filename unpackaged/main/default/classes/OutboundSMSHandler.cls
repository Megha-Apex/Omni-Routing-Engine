public class OutboundSMSHandler {
    
    public void run(){
        NFTriggerSettings__c triggerSetting =   NFTriggerSettings__c.getInstance();
        
        if(triggerSetting !=null && !triggerSetting.OutboundSMS_Disable__c ){
            if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    handleAfterInsert(Trigger.new);
                    
                } else if (Trigger.isUpdate) {
                    handleAfterUpdate(Trigger.new,Trigger.oldMap);
                }
            }
        }else{
            System.debug('Trigger is disabled by custom setting.'); 
        }
    }
    
    public void handleAfterInsert(List<OutboundSMS__c> newRecords){
        List<OutboundSMS__c> recordsToProcess = new List<OutboundSMS__c>();
        OutboundSMSService service = new OutboundSMSService();
        
        for (OutboundSMS__c sms : newRecords) {
            if(sms.Status__c == 'Queued'){
                recordsToProcess.add(sms);
            }
        }
        
        if (!recordsToProcess.isEmpty()) {
            service.processSMS(recordsToProcess);
        }
    }
    
    public void handleAfterUpdate(List<OutboundSMS__c> newRecords , Map<Id,Object > oldRecordsMap){
        Map<Id,OutboundSMS__c> oldMap = ( Map<Id,OutboundSMS__c>)oldRecordsMap;
        List<OutboundSMS__c> recordsToProcess = new List<OutboundSMS__c>();
        OutboundSMSService service = new OutboundSMSService();
        
        for (OutboundSMS__c sms : newRecords) {
            OutboundSMS__c oldSms = oldMap.get(sms.Id);
            if (oldSms.Status__c != 'Queued' && sms.Status__c == 'Queued') {
                recordsToProcess.add(sms);
            }
        }
        if (!recordsToProcess.isEmpty()) {
            service.processSMS(recordsToProcess);
        }
    }
}