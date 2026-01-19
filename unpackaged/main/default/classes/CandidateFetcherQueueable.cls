public class CandidateFetcherQueueable implements Queueable {
    private List<Id> serviceAppointmentIds;
    private Boolean withDelay;
    private Integer retryCount;
    private static final Integer MAX_RETRIES = 3;
    private static final Integer RETRY_INTERVAL_SECONDS = 30;

    public CandidateFetcherQueueable(List<Id> serviceAppointmentIds, Boolean withDelay) {
        this.serviceAppointmentIds = serviceAppointmentIds;
        this.withDelay = withDelay;
        this.retryCount = 0;
    }

    public CandidateFetcherQueueable(List<Id> serviceAppointmentIds, Boolean withDelay, Integer retryCount) {
        this.serviceAppointmentIds = serviceAppointmentIds;
        this.withDelay = withDelay;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        System.debug('CandidateFetcherQueueable executed for SAs: ' + serviceAppointmentIds + ', Retry Count: ' + retryCount);

        // Removed busy wait from original code
        List<ServiceAppointment> serviceApps = [
            SELECT Id, ServiceTerritoryId, Work_Order__c, Sub_Customer__r.Send_Potential_Tech__c,
                   Active_Technician__c, Active_Technician_Details__c
            FROM ServiceAppointment 
            WHERE Id IN :serviceAppointmentIds 
              AND Do_Not_Use_SA__c = true
        ];
        System.debug('Found ' + serviceApps.size() + ' ServiceAppointments');

        List<Id> sasToRetry = new List<Id>();

        // Fetch scheduling policy once
        FSL__Scheduling_Policy__c schedulingPolicy;
        try {
            schedulingPolicy = [
                SELECT Id, Name 
                FROM FSL__Scheduling_Policy__c 
                WHERE Name = 'Resource Capability' 
                LIMIT 1
            ];
        } catch (QueryException e) {
            System.debug('Scheduling policy "Resource Capability" not found.');
        }

        for (ServiceAppointment sa : serviceApps) {
            if (sa.ServiceTerritoryId == null) {
                System.debug('ServiceTerritoryId not populated for SA: ' + sa.Id);
                if (retryCount < MAX_RETRIES) {
                    sasToRetry.add(sa.Id);
                }
                continue;
            }

            if (schedulingPolicy == null) {
                System.debug('Scheduling policy not available for SA: ' + sa.Id);
                if (retryCount < MAX_RETRIES) {
                    sasToRetry.add(sa.Id);
                }
                continue;
            }

            FSL.GradeSlotsService slotService = new FSL.GradeSlotsService(schedulingPolicy.Id, sa.Id);
            FSL.AdvancedGapMatrix resultMatrix = slotService.getGradedMatrix(true);
            Map<Id, FSL.ResourceScheduleData> resourceData = resultMatrix.ResourceIDToScheduleData;
            System.debug('Found ' + resourceData.size() + ' resources for SA: ' + sa.Id);

            Set<Id> resourceIdsToQuery = new Set<Id>();
            for (Id resourceId : resourceData.keySet()) {
                if (!resourceData.get(resourceId).SchedulingOptions.isEmpty()) {
                    resourceIdsToQuery.add(resourceId);
                }
            }

            Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>([
                SELECT Id, Name, MobilePhone__c, Email__c 
                FROM ServiceResource 
                WHERE Id IN :resourceIdsToQuery
            ]);

            List<String> resourceIds = new List<String>();
            List<String> technicianDetails = new List<String>();
            for (Id resourceId : resourceData.keySet()) {
                if (serviceResources.containsKey(resourceId)) {
                    ServiceResource sr = serviceResources.get(resourceId);
                    resourceIds.add(resourceId);
                    technicianDetails.add(sr.Name + ' , ' + sr.MobilePhone__c + ' , ' + sr.Email__c);
                }
            }

            if (!resourceIds.isEmpty()) {
                sa.Active_Technician__c = String.join(resourceIds, '; ');
                sa.Active_Technician_Details__c = String.join(technicianDetails, '; ');
                update sa;
                System.debug('Updated SA with candidate data: ' + sa.Id);
            } else {
                System.debug('No candidates found for SA: ' + sa.Id);
                if (retryCount < MAX_RETRIES) {
                    sasToRetry.add(sa.Id);
                }
            }
        }

        if (!sasToRetry.isEmpty() && retryCount < MAX_RETRIES) {
            System.debug('Scheduling retry for SAs: ' + sasToRetry);
            scheduleRetry(sasToRetry);
        } else if (!Test.isRunningTest()) {
            System.debug('No retry needed, enqueueing ResourcePreferenceCreatorQueueable for SAs: ' + serviceAppointmentIds);
            System.enqueueJob(new ResourcePreferenceCreatorQueueable(serviceAppointmentIds));
        }
    }

    private void scheduleRetry(List<Id> saIds) {
        if (retryCount >= MAX_RETRIES) {
            System.debug('Max retries reached for ServiceAppointment IDs: ' + saIds);
            return;
        }

        String jobName = 'CandidateFetcherRetry_' + String.join(saIds, '_') + '_' + System.now().getTime();
        String cronExpression = '0 ' + (System.now().second() + RETRY_INTERVAL_SECONDS) + ' * * * ?';

        try {
            System.schedule(jobName, cronExpression, new CandidateFetcherRetryScheduler(saIds, withDelay, retryCount + 1));
            System.debug('Scheduled retry job: ' + jobName + ' for IDs: ' + saIds + ', Retry count: ' + (retryCount + 1));
        } catch (Exception e) {
            System.debug('Failed to schedule retry job: ' + e.getMessage());
        }
    }
}