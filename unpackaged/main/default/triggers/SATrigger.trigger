trigger SATrigger on ServiceAppointment (after insert) {
    System.debug('SATrigger fired. Number of SAs: ' + Trigger.new.size());
    
    List<Id> tempSAIds = new List<Id>();
    
    for (ServiceAppointment sa : Trigger.new) {
        // Check if Do_Not_Use_SA__c is true and Work_Order__c is not null
        if (sa.Do_Not_Use_SA__c == true && sa.Work_Order__c != null) {
            tempSAIds.add(sa.Id);
        }
    }
    
    if (!tempSAIds.isEmpty()) {
        System.debug('Enqueueing CandidateFetcherQueueable for SAs: ' + tempSAIds);
        System.enqueueJob(new CandidateFetcherQueueable(tempSAIds, true)); // Added delay flag
    }
}