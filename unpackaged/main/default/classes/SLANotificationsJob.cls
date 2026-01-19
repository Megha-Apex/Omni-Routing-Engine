/**
* @author Chris Rushton
* @date 2022-11-08
* @description Scheduled Job For Running SLANotifications Flow
*/

public with sharing class SLANotificationsJob implements Schedulable{


    public void execute(SchedulableContext SC) {
        // Call the Flow
        Map<String, Object> params = new Map<String, Object>();
        Flow.Interview.SLANotifications dispatchFlow = new Flow.Interview.SLANotifications(params);
        dispatchFlow.start();
    }

}