/**
 * Created by oreny on 29/10/2020.
 */

trigger WorkOrderTrigger on WorkOrder (before insert, before update) {
    if(Trigger.isBefore) {
        if (Trigger.isInsert) {
            WorkOrderHandler.beforeInsert(Trigger.new);
        }
        else if(Trigger.isUpdate) {
            WorkOrderHandler.beforeUpdate(Trigger.old, Trigger.newMap);
        }
    }
}