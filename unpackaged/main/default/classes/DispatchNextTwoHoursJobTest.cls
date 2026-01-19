/**
* @author Daniel Segal
* @date 2020-07-08
* @description Test For Running Dispatch_Next_two_hours_SA Flow
*/

@IsTest
public with sharing class DispatchNextTwoHoursJobTest {

    @IsTest
    static void executeJob_success() {
        Test.startTest();
        DispatchNextTwoHoursJob dispatchNextTwoHoursJob = new DispatchNextTwoHoursJob();
        dispatchNextTwoHoursJob.execute(null);
        Test.stopTest();
    }
}