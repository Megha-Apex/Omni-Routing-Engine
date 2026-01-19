trigger CaseTrigger on Case (after insert, after update) {
    
    // Recursion Guard: Check the flag from the Handler
    if (!CaseRoutingHandler.isFirstRun) {
        return;
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            CaseRoutingHandler.processAndRoute(Trigger.new, Trigger.oldMap);
        }
    }
}