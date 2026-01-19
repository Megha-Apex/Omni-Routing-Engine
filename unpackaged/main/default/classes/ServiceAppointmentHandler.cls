public with sharing class ServiceAppointmentHandler {
    public static void afterInsert(Map<Id, ServiceAppointment> saMap) {
        System.debug('ServiceAppointmentHandler afterInsert');
        Set<Id> woIdSet = new Set<Id>();
        for(ServiceAppointment sa : saMap.values()) {
            woIdSet.add(sa.ParentRecordId);
        }

        if(!woIdSet.isEmpty() && !saMap.keySet().isEmpty()) {
            List<ServiceAppointment> saToUpdateList = setSAArrivalWindowTimes(woIdSet, saMap.keySet());
            
            if(!saToUpdateList.isEmpty()) {
                update saToUpdateList;
            }
        }
    }

    public static void handleTimeBlocksValidations(Map<Id, ServiceAppointment> saOldMap, Map<Id, ServiceAppointment> saNewMap)  {
        List<Status_Based_Locks__mdt> statusBasedLocks = [SELECT Id, Roles__c, Statuses_for_time_locks__c FROM Status_Based_Locks__mdt];
        List<String> statusesToExclude = new List<String>();
        List<String> roles = new List<String>();
        Boolean isAdmin = false;

        if(statusBasedLocks.isEmpty()) {
            return;
        }
        statusesToExclude = statusBasedLocks.get(0).Statuses_for_time_locks__c != null ? statusBasedLocks.get(0).Statuses_for_time_locks__c.split(',') : new List<String>{'On-Site', 'Off-Site', 'Field Complete', 'Field Incompleted', 'Completed', 'Incompleted'};
        roles = statusBasedLocks.get(0).Roles__c != null ? statusBasedLocks.get(0).Roles__c.split(',') : new List<String>{'Admin'};
        Map<Id, UserRole> idToUserRoleMap = new Map<Id, UserRole>([SELECT Id FROM UserRole WHERE Name IN :roles]);
        isAdmin = idToUserRoleMap.containsKey(UserInfo.getUserRoleId()) ? true : false;

        for(ServiceAppointment serviceAppointment : saNewMap.values()) {
            ServiceAppointment oldServiceAppointment = saOldMap.get(serviceAppointment.Id);
            if(serviceAppointment.Time_Change_Flag__c == false) {
                if(!isAdmin && statusesToExclude.contains(serviceAppointment.Status) && (serviceAppointment.SchedStartTime != oldServiceAppointment.SchedStartTime || serviceAppointment.SchedEndTime != oldServiceAppointment.SchedEndTime)) {
                    if(serviceAppointment.Status == oldServiceAppointment.Status) {
                        serviceAppointment.addError('“It is not allowed to change the Scheduled Time for Service Appointment with status ' + serviceAppointment.Status);
                    }
                }
            }
        }

    }

    public static void beforeUpdate(Map<Id, ServiceAppointment> saOldMap, Map<Id, ServiceAppointment> saNewMap) {
        System.debug('ServiceAppointmentHandler beforeUpdate');
        handleTimeBlocksValidations(saOldMap, saNewMap);
        Set<Id> saIdSet = new Set<Id>();
        Set<Id> woIdSet = new Set<Id>();
        for(Id saId : saOldMap.keySet()) {
            System.debug('saOldMap.get(saId).ServiceTerritoryId: ' + saOldMap.get(saId).ServiceTerritoryId);
            System.debug('saNewMap.get(saId).ServiceTerritoryId: ' + saNewMap.get(saId).ServiceTerritoryId);
            if(saOldMap.get(saId).ServiceTerritoryId == null && saNewMap.get(saId).ServiceTerritoryId != null) {
                saIdSet.add(saId);
                woIdSet.add(saNewMap.get(saId).ParentRecordId);
            }
        }

        System.debug('woIdSet: ' + woIdSet);
        System.debug('saIdSet: ' + saIdSet);
        
        if(!woIdSet.isEmpty() && !saIdSet.isEmpty()) {
            List<ServiceAppointment> saToUpdateList = setSAArrivalWindowTimes(woIdSet, saIdSet);            
            
            if(!saToUpdateList.isEmpty()) {
                update saToUpdateList;
            }
        }
    }

    private static List<ServiceAppointment> setSAArrivalWindowTimes(Set<Id> woIdSet, Set<Id> saIdSet) {
        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder> ([SELECT Id, MaintenancePlan.CreatedBy.TimeZoneSidKey, MaintenancePlan.Desired_Arrival_Window_Start_Time__c, MaintenancePlan.Desired_Arrival_Window_End_Time__c, SuggestedMaintenanceDate FROM WorkOrder WHERE ID IN: woIdSet AND MaintenancePlanId != null]);
        System.debug('*** woMap' + woMap);

        List<ServiceAppointment> serviceAppointmentList = [SELECT ServiceTerritory.OperatingHours.TimeZone, ServiceAppointment.ParentRecordId, ArrivalWindowStartTime, ArrivalWindowEndTime
                                                           FROM ServiceAppointment 
                                                           WHERE Id IN :saIdSet AND ParentRecordId IN: woMap.keySet()];
        System.debug('*** serviceAppointmentList' + serviceAppointmentList);

        List<ServiceAppointment> saToUpdateList = new List<ServiceAppointment>();
        for(ServiceAppointment sa : serviceAppointmentList) {
            Boolean isChanged = false;

            // Convert ArrivalWindowStart & ArrivalWindowEnd to MaintenancePlan created user TZ
            if(sa.ArrivalWindowStartTime == null || sa.ArrivalWindowEndTime == null) {
                WorkOrder wo = woMap.get(sa.ParentRecordId);
                String timeZoneName = wo.MaintenancePlan.CreatedBy.TimeZoneSidKey;
                
                Datetime startDt = convertGMTtoTZ(Datetime.newInstanceGmt(wo.SuggestedMaintenanceDate, wo.MaintenancePlan.Desired_Arrival_Window_Start_Time__c), timeZoneName);
                
                if(wo.MaintenancePlan.Desired_Arrival_Window_End_Time__c != null) {
                    Datetime endDt = convertGMTtoTZ(Datetime.newInstanceGmt(wo.SuggestedMaintenanceDate, wo.MaintenancePlan.Desired_Arrival_Window_End_Time__c), timeZoneName);
                    if(endDt < startDt) {
                        endDt = endDt.addDays(1);
                    }
                    sa.ArrivalWindowEndTime = endDt;
                }
                sa.ArrivalWindowStartTime = startDt;

                isChanged = true;
            }

            // Convert Earliest start & Due date to territory TZ
            if(String.isNotBlank(sa.ServiceTerritory.OperatingHours.TimeZone)) {
                WorkOrder wo = woMap.get(sa.ParentRecordId);
                String timeZoneName = sa.ServiceTerritory.OperatingHours.TimeZone;
                
                Datetime startDt = convertGMTtoTZ(Datetime.newInstanceGmt(wo.SuggestedMaintenanceDate, Time.newInstance(0, 0, 0, 0)), timeZoneName);
                Datetime endDt = convertGMTtoTZ(Datetime.newInstanceGmt(wo.SuggestedMaintenanceDate, Time.newInstance(23, 59, 59, 59)), timeZoneName);

                sa.EarliestStartTime = startDt;
                sa.DueDate = endDt;

                isChanged = true;
            }

            if(isChanged) {
                saToUpdateList.add(sa);
            }
        }
        
        System.debug('*** saToUpdateList' + saToUpdateList);
        return saToUpdateList;
    }

    private static Datetime convertGMTtoTZ(Datetime dt, String tzName) {
        return doConversion(dt, tzName, false);
    }

    private static Datetime convertTZtoGMT(Datetime dt, String tzName) {
        return doConversion(dt, tzName, true);
    }

    private static Datetime doConversion(Datetime dt, String tzName, Boolean addOrRemove) {
        Integer multiplier = (addOrRemove ? 1 : - 1);
        TimeZone storeTimeZone = TimeZone.getTimeZone(tzName);
        Integer offsetInMinute = storeTimeZone.getOffset(dt) / (60 * 1000);
        dt = dt.addMinutes(multiplier * offsetInMinute);
        return dt;
    }
}