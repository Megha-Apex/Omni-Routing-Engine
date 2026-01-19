public class CandidateFetcherRetryScheduler implements Schedulable {
    private List<Id> serviceAppointmentIds;
    private Boolean withDelay;
    private Integer retryCount;

    public CandidateFetcherRetryScheduler(List<Id> serviceAppointmentIds, Boolean withDelay, Integer retryCount) {
        this.serviceAppointmentIds = serviceAppointmentIds;
        this.withDelay = withDelay;
        this.retryCount = retryCount;
    }

    public void execute(SchedulableContext context) {
        System.debug('CandidateFetcherRetryScheduler executed for SAs: ' + serviceAppointmentIds + ', Retry Count: ' + retryCount);
        System.enqueueJob(new CandidateFetcherQueueable(serviceAppointmentIds, withDelay, retryCount));
    }
}