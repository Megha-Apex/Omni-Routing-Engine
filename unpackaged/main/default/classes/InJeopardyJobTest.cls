/**
* @author Daniel Segal
* @date 2020-07-08
* @description Test For Running InJeopardyJob Flow
*/

@IsTest
public with sharing class InJeopardyJobTest {

    @IsTest
    static void executeJob_success() {
        Test.startTest();
        InJeopardyJob inJeopardyJob = new InJeopardyJob();
        inJeopardyJob.execute(null);
        Test.stopTest();
    }
}