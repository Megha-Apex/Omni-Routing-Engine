trigger TargetDate on ServiceAppointment (after insert, after update) {
    // 1. Identify Tentative, Dispatched, or Accepted Appointments
    Set<Id> serviceApptIds = new Set<Id>();
    Set<Id> serviceResourceIds = new Set<Id>();
    
    for (ServiceAppointment appointment : Trigger.new) {
        if (Trigger.isInsert && (appointment.Status == 'Tentative' || 
                                appointment.Status == 'Dispatched' || 
                                appointment.Status == 'Accepted')) {
            serviceApptIds.add(appointment.Id);
        } else if (Trigger.isUpdate && (appointment.Status == 'Tentative' || 
                                       appointment.Status == 'Dispatched' || 
                                       appointment.Status == 'Accepted')) {
            ServiceAppointment oldAppointment = Trigger.oldMap.get(appointment.Id);
            if (oldAppointment.Status != appointment.Status || 
                oldAppointment.Type_of_Appointment__c != appointment.Type_of_Appointment__c) {
                serviceApptIds.add(appointment.Id);
            }
        }
    }
    if (serviceApptIds.isEmpty()) return;

    // 2. Query AssignedResources and related data
    Map<Id, List<ServiceAppointment>> resourceToAppointmentsMap = new Map<Id, List<ServiceAppointment>>();
    Map<Id, AssignedResource> apptToAssignedResourceMap = new Map<Id, AssignedResource>();
    Map<Id, Date> apptToDateMap = new Map<Id, Date>();
    
    for (AssignedResource ar : [
        SELECT Id, ServiceAppointmentId, EstimatedTravelTime, ServiceResourceId,
               ServiceAppointment.Type_of_Appointment__c, ServiceAppointment.ArrivalWindowEndTime,
               ServiceAppointment.ArrivalWindowStartTime, ServiceAppointment.SchedEndTime,
               ServiceAppointment.SchedStartTime, ServiceAppointment.CreatedDate,
               ServiceAppointment.Assigned_Technician__c
        FROM AssignedResource
        WHERE ServiceAppointmentId IN :serviceApptIds
    ]) {
        apptToAssignedResourceMap.put(ar.ServiceAppointmentId, ar);
        serviceResourceIds.add(ar.ServiceResourceId);
        
        Date apptDate = ar.ServiceAppointment.SchedStartTime != null 
            ? ar.ServiceAppointment.SchedStartTime.date() 
            : ar.ServiceAppointment.CreatedDate.date();
        apptToDateMap.put(ar.ServiceAppointmentId, apptDate);
    }

    // Query all appointments for these resources on the same days
    for (AssignedResource ar : [
        SELECT Id, ServiceAppointmentId, ServiceResourceId,
               ServiceAppointment.Type_of_Appointment__c, ServiceAppointment.SchedEndTime,
               ServiceAppointment.SchedStartTime, ServiceAppointment.Assigned_Technician__c
        FROM AssignedResource
        WHERE ServiceResourceId IN :serviceResourceIds
        AND DAY_ONLY(ServiceAppointment.SchedStartTime) IN :apptToDateMap.values()
        ORDER BY ServiceAppointment.SchedStartTime ASC
    ]) {
        if (!resourceToAppointmentsMap.containsKey(ar.ServiceResourceId)) {
            resourceToAppointmentsMap.put(ar.ServiceResourceId, new List<ServiceAppointment>());
        }
        resourceToAppointmentsMap.get(ar.ServiceResourceId).add(ar.ServiceAppointment);
    }

    // Query Shifts
    Map<Id, Shift> resourceToShiftMap = new Map<Id, Shift>();
    for (Shift sh : [
        SELECT Id, ServiceResourceId, StartTime
        FROM Shift
        WHERE ServiceResourceId IN :serviceResourceIds
        AND Status = 'Confirmed'
        AND DAY_ONLY(StartTime) IN :apptToDateMap.values()
    ]) {
        resourceToShiftMap.put(sh.ServiceResourceId, sh);
    }

    // 3. Calculate ETAs
    List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
    
    for (ServiceAppointment appointment : [
        SELECT Id, Type_of_Appointment__c, ArrivalWindowEndTime, ArrivalWindowStartTime,
               SchedEndTime, SchedStartTime, CreatedDate, Assigned_Technician__c
        FROM ServiceAppointment
        WHERE Id IN :serviceApptIds
    ]) {
        AssignedResource currentAR = apptToAssignedResourceMap.get(appointment.Id);
        if (currentAR == null || currentAR.EstimatedTravelTime == null) continue;
        
        ServiceAppointment apptToUpdate = new ServiceAppointment(Id = appointment.Id);
        Integer travelTime = currentAR.EstimatedTravelTime.intValue();
        
        // PMI
        if (appointment.Type_of_Appointment__c == 'PMI') {
            apptToUpdate.ETA_Date_Time__c = appointment.SchedStartTime.addMinutes(travelTime);
            apptToUpdate.ETA__c = travelTime;
        }
        // ARRIVAL WINDOW
        else if (appointment.Type_of_Appointment__c == 'Arrival Window') {
            apptToUpdate.ETA_Date_Time__c = appointment.ArrivalWindowStartTime;
        }
        // HARD START
        else if (appointment.Type_of_Appointment__c == 'Hard Start') {
            apptToUpdate.ETA_Date_Time__c = appointment.ArrivalWindowEndTime;
        }
        // MTTR
        else if (appointment.Type_of_Appointment__c == 'MTTR') {
            apptToUpdate.ETA_Date_Time__c = appointment.CreatedDate.addMinutes(travelTime);
            apptToUpdate.ETA__c = travelTime;
        }
        // ALL DAY
        else if (appointment.Type_of_Appointment__c == 'All Day') {
            List<ServiceAppointment> techAppointments = resourceToAppointmentsMap.get(currentAR.ServiceResourceId);
            
            if (techAppointments != null && !techAppointments.isEmpty()) {
                // Find position of current appointment
                Integer currentIndex = -1;
                for (Integer i = 0; i < techAppointments.size(); i++) {
                    if (techAppointments[i].Id == appointment.Id) {
                        currentIndex = i;
                        break;
                    }
                }
                
                if (currentIndex == 0) {
                    // First appointment - Shift Start + ETT
                    Shift techShift = resourceToShiftMap.get(currentAR.ServiceResourceId);
                    if (techShift != null && techShift.StartTime != null) {
                        apptToUpdate.ETA_Date_Time__c = techShift.StartTime.addMinutes(travelTime);
                        apptToUpdate.ETA__c = travelTime;
                    }
                } else if (currentIndex > 0) {
                    // Subsequent appointment - use first appointment's SchedEnd + ETT
                    if (techAppointments[0].SchedEndTime != null) {
                        apptToUpdate.ETA_Date_Time__c = techAppointments[0].SchedEndTime.addMinutes(travelTime);
                        apptToUpdate.ETA__c = travelTime;
                    }
                }
            }
        }
        
        if (apptToUpdate.ETA_Date_Time__c != null) {
            appointmentsToUpdate.add(apptToUpdate);
        }
    }
    
    // 4. Update Appointments
    if (!appointmentsToUpdate.isEmpty()) {
        update appointmentsToUpdate;
    }
}