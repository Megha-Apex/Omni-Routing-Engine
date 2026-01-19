trigger JSRTriggerSendEmail on JSR__c (after update) {
    List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
    Set<Id> jsrIdsToProcess = new Set<Id>();

    for (JSR__c jsr : Trigger.new) {
        JSR__c oldJSR = Trigger.oldMap.get(jsr.Id);

        // Check if Status Check changed to true in this update
        if (jsr.Status_Check__c && (oldJSR == null || !oldJSR.Status_Check__c)) {
            jsrIdsToProcess.add(jsr.Id);
        }
    }

    // Query for JSR__c records with the specified criteria
    Map<Id, JSR__c> jsrMap = new Map<Id, JSR__c>([SELECT Id, Email_to_Address__c, Email_CC_Address__c FROM JSR__c WHERE Id IN :jsrIdsToProcess]);

    // Create email messages
    for (Id jsrId : jsrIdsToProcess) {
        JSR__c jsrRecord = jsrMap.get(jsrId);

       
    }
}