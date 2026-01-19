/**
* @author Tal Licht
* @date 2020-08-19
* @description class for handling outgoing messages batch
*/
global class Outgoing_Message_Batch implements Database.Batchable < Outgoing_Message__c >, Database.AllowsCallouts{
    List<Outgoing_Message__c> newObjs;
    global Outgoing_Message_Batch(List<Outgoing_Message__c> newObjs) {
        this.newObjs = newObjs;
    }

    global Iterable < Outgoing_Message__c > start(Database.BatchableContext BC) {
        return newObjs;
    }

    global void execute(Database.BatchableContext BC, List < Outgoing_Message__c > scope) {
        SendHttpRequest_Handler.createBulkCallouts(scope, false);
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('[BatchExecutor] finished phase ');
    }
}