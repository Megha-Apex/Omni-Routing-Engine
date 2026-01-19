public class OutboundSMSService {

    public  void processSMS(List<OutboundSMS__c> smsList) {
        // Call the API callout class here
        System.enqueueJob(new SMSAPIServiceQueueable(smsList));
    }
}