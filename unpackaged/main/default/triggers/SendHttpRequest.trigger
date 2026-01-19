/**
 * Created by tal.licht on 8/19/2020.
 */

trigger SendHttpRequest on Outgoing_Message__c (after insert, after update) {
    if(Trigger.isInsert) {
        SendHttpRequest_Handler.afterInsert(Trigger.new);
    }
    else if(Trigger.isUpdate) {
        SendHttpRequest_Handler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}