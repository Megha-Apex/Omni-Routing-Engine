/**
* @author Daniel Segal
* @date 2020-07-08
* @description Scheduled Job For Running Dispatch_Next_two_hours_SA Flow
*/

public with sharing class DispatchNextTwoHoursJob implements Schedulable{


    public void execute(SchedulableContext SC) {
        // Call the Flow
        Map<String, Object> params = new Map<String, Object>();
        Flow.Interview.Dispatch_Next_two_hours_SA dispatchFlow = new Flow.Interview.Dispatch_Next_two_hours_SA(params);
        dispatchFlow.start();
    }
}