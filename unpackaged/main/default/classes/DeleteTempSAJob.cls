global class DeleteTempSAJob implements Schedulable {
    private List<Id> serviceAppointmentIds;
    private Integer retryCount = 0;
    private static final Integer MAX_RETRIES = 12; // 1 hour total (12 x 5 minutes)
    private static final Integer RETRY_INTERVAL = 5; // 5 minutes between checks
    
    public DeleteTempSAJob(List<Id> serviceAppointmentIds) {
        this.serviceAppointmentIds = serviceAppointmentIds;
    }
    
    public DeleteTempSAJob(List<Id> serviceAppointmentIds, Integer retryCount) {
        this(serviceAppointmentIds);
        this.retryCount = retryCount;
    }
    
    global void execute(SchedulableContext sc) {
        try {
            List<ServiceAppointment> sasToProcess = [
                SELECT Id, Active_Technician_Details__c, Work_Order__r.Vendor_Status__c, 
                       Active_Technician__c, Work_Order__r.Case.No_Technicians_Found__c 
                FROM ServiceAppointment 
                WHERE Id IN :serviceAppointmentIds 
                AND Do_Not_Use_SA__c = true
            ];
            
            List<ServiceAppointment> sasToDelete = new List<ServiceAppointment>();
            List<Id> sasToRetry = new List<Id>();
            
            for (ServiceAppointment sa : sasToProcess) {
                if (isReadyForDeletion(sa)) {
                    sasToDelete.add(sa);
                } else if (retryCount < MAX_RETRIES) {
                    sasToRetry.add(sa.Id);
                }
            }
            
            if (!sasToDelete.isEmpty()) {
                delete sasToDelete;
                System.debug('Deleted ' + sasToDelete.size() + ' SAs with PotentialTechsProvided or No Technicians Found');
            }
            
            if (!sasToRetry.isEmpty()) {
                scheduleNextCheck(sasToRetry);
            }
        } catch (Exception e) {
            System.debug('Deletion error: ' + e.getMessage());
        }
    }
    
    private Boolean isReadyForDeletion(ServiceAppointment sa) {
        // Existing condition: Delete if Active_Technician_Details__c is not null and Vendor_Status__c contains 'PotentialTechsProvided'
        Boolean existingCondition = sa.Active_Technician_Details__c != null && 
                                   sa.Work_Order__r != null && 
                                   sa.Work_Order__r.Vendor_Status__c != null && 
                                   sa.Work_Order__r.Vendor_Status__c.contains('PotentialTechsProvided');
        
        // New condition: Delete if Active_Technician__c is null and No_Technicians_Found__c is true on related Case
        Boolean newCondition = sa.Active_Technician__c == null && 
                              sa.Work_Order__r != null && 
                              sa.Work_Order__r.Case != null && 
                              sa.Work_Order__r.Case.No_Technicians_Found__c == true;
        
        return existingCondition || newCondition;
    }
    
    private void scheduleNextCheck(List<Id> saIds) {
        Datetime nextCheck = System.now().addMinutes(RETRY_INTERVAL);
        String cronExpression = 
            nextCheck.second() + ' ' + 
            nextCheck.minute() + ' ' + 
            nextCheck.hour() + ' ' + 
            nextCheck.day() + ' ' + 
            nextCheck.month() + ' ? ' + 
            nextCheck.year();
        
        System.schedule(
            'SACheck_Retry_' + retryCount + '_' + System.currentTimeMillis(),
            cronExpression,
            new DeleteTempSAJob(saIds, retryCount + 1)
        );
    }
}