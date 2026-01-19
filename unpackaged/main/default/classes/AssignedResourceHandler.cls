/**
 * @author daniel.segal
 * @date 2021-01-14
 * @description
 */

public with sharing class AssignedResourceHandler {

    public static void beforeUpdate(List<AssignedResource> arOldList, List<AssignedResource> arNewList) {
        Map<Id, AssignedResource> assignedResourceServiceAppointmentOldMap = new Map<Id, AssignedResource>();
        Map<Id, AssignedResource> assignedResourceServiceAppointmentNewMap = new Map<Id, AssignedResource>();
        List<Status_Based_Locks__mdt> statusBasedLocks = [SELECT Id, Roles__c, Statuses_for_tech_locks__c FROM Status_Based_Locks__mdt];
        List<String> statusesToExclude = new List<String>();
        List<String> roles = new List<String>();
        Boolean isAdmin = false;
        if(statusBasedLocks.isEmpty()) {
            return;
        }
        for(Integer i =0 ; i < arOldList.size() ; i++) {
            assignedResourceServiceAppointmentOldMap.put(arOldList[i].ServiceAppointmentId, arOldList[i]);
            assignedResourceServiceAppointmentNewMap.put(arNewList[i].ServiceAppointmentId, arNewList[i]);
        }
        List<ServiceAppointment> serviceAppointments = [SELECT Id, Status FROM ServiceAppointment WHERE Id IN :assignedResourceServiceAppointmentOldMap.keySet()];

        statusesToExclude = statusBasedLocks.get(0).Statuses_for_tech_locks__c != null ? statusBasedLocks.get(0).Statuses_for_tech_locks__c.split(',') : new List<String>{'Dispatched', 'Accepted', 'Enroute', 'On-Site', 'Off-Site', 'Field Complete', 'Field Incompleted', 'Completed', 'Incompleted'};
        roles = statusBasedLocks.get(0).Roles__c != null ? statusBasedLocks.get(0).Roles__c.split(',') : new List<String>{'Admin'};
        Map<Id, UserRole> idToUserRoleMap = new Map<Id, UserRole>([SELECT Id FROM UserRole WHERE Name IN :roles]);
        isAdmin = idToUserRoleMap.containsKey(UserInfo.getUserRoleId()) ? true : false;

        for(ServiceAppointment serviceAppointment : serviceAppointments) {
            if(!isAdmin && statusesToExclude.contains(serviceAppointment.Status) && assignedResourceServiceAppointmentOldMap.get(serviceAppointment.Id).ServiceResourceId != assignedResourceServiceAppointmentNewMap.get(serviceAppointment.Id).ServiceResourceId) {
                assignedResourceServiceAppointmentNewMap.get(serviceAppointment.Id).addError('It is not allowed to change the Assigned Technician for Service Appointment with status ' + serviceAppointment.Status +  '. The Service Appointment must be rejected.');
            }
        }
    }

}