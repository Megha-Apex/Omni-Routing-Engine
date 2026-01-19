trigger OutboundSMSTrigger on OutboundSMS__c (after insert, after update) {

OutboundSMSHandler handler = new OutboundSMSHandler();
handler.run();
}