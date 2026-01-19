/**
* @author Chris Rushton
* @date 2022-11-08
* @description Test For Running SLANotificationsJob Flow
*/

@IsTest
public with sharing class SLANotificationsJobTest {

    @IsTest
    static void executeJob_success() {
        Test.startTest();
        SLANotificationsJob SLANotificationsJob = new SLANotificationsJob();
        SLANotificationsJob.execute(null);
        Test.stopTest();
    }
}