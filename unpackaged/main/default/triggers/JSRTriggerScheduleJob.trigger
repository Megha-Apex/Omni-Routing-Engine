trigger JSRTriggerScheduleJob on JSR__c (after update) {
    for (JSR__c jsr : Trigger.new) {
        JSR__c oldJSR = Trigger.oldMap.get(jsr.Id);

        // Check if Status Check changed from false to true
        if (!oldJSR.Status_Check__c && jsr.Status_Check__c) {
            // Schedule the job to run one minute in the future, but only once
            Datetime scheduleTime = System.now().addMinutes(1);
            
            String jobName = 'MyScheduledJob_' + jsr.Id;
            
            // Check if a job with the same name already exists, and delete it if found
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
                System.abortJob(ct.Id);
            }

            // Construct the cron expression for one-time execution
            String cronExpression = scheduleTime.second() + ' ' + scheduleTime.minute() + ' ' + scheduleTime.hour() + ' ' + scheduleTime.day() + ' ' + scheduleTime.month() + ' ? ' + scheduleTime.year();

            String jobId = System.schedule(jobName, cronExpression, new MyScheduledJob(jsr.Id));
        }
    }
}