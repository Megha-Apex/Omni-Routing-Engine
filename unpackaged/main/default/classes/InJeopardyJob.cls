/**
* @author Daniel Segal
* @date 2020-07-08
* @description Scheduled Job For Running In_Joepardy Flow
*/

public with sharing class InJeopardyJob implements Schedulable{


    public void execute(SchedulableContext SC) {
        // Call the Flow
        Map<String, Object> params = new Map<String, Object>();
        Flow.Interview.In_Joepardy dispatchFlow = new Flow.Interview.In_Joepardy(params);
        dispatchFlow.start();
    }

}