/**
 * @author Daniel Segal
 * @date 2020-07-30
 */
@IsTest
private class QueryMessageAPITest {

    @TestSetup
    private static void setup() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;
    }

    @IsTest
    static void getRecords_recordsRetrieved_success() {
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/query/account/group/TestAccount';
        QueryMessageAPI.HttpGet();
        Test.stopTest();
        Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(
                RestContext.response.responseBody.toString()
        );

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertNotEquals(RestContext.response, null);
        System.assertEquals(true, (Boolean)results.get('done'));
        System.assertEquals(1, (Integer)results.get('totalSize'));
        System.assertEquals(1, ((List<Object>)results.get('records')).size());
    }

    @IsTest
    static void getRecords_sObjectMissing_throws404() {
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/query/accountt/group/TestAccount';
        QueryMessageAPI.HttpGet();
        Test.stopTest();

        System.assertNotEquals(RestContext.response, null);
        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains('SObject specified does not exists'));
    }

    @IsTest
    static void getRecords_groupNotSpecified_throws404() {
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/query/account/group/';
        QueryMessageAPI.HttpGet();
        Test.stopTest();

        System.assertNotEquals(RestContext.response, null);
        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains('Group was not specified'));
    }

    @IsTest
    static void getRecords_hasNoGroup_throws404() {
        Test.startTest();
        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/query/account/group/example';
        QueryMessageAPI.HttpGet();
        Test.stopTest();

        System.assertNotEquals(RestContext.response, null);
        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(true, RestContext.response.responseBody.toString().contains('Group does not exists'));
    }

}