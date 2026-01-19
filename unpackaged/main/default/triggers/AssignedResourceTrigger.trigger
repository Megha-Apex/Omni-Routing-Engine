/**
 * @author daniel.segal
 * @date 2021-01-14
 * @description
 */

trigger AssignedResourceTrigger on AssignedResource (before update, before delete) {
    if(Trigger.isUpdate) {
        AssignedResourceHandler.beforeUpdate(Trigger.old, Trigger.new);
    }

}