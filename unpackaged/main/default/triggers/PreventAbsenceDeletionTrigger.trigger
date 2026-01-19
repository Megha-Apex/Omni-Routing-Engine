trigger PreventAbsenceDeletionTrigger on ResourceAbsence (before delete) {
    PreventAbsenceDeletionHandler.handleDeletion(Trigger.old, Trigger.isExecuting);
}