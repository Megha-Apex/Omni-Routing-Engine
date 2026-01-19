trigger ServiceAppointmentTrigger on ServiceAppointment (after insert, after update) {
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            ServiceAppointmentHandler.afterInsert(Trigger.newMap);
        }
        if(Trigger.isUpdate) {
            ServiceAppointmentHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}