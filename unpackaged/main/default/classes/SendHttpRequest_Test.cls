/**
* @author Tal Licht
* @date 2020-08-19
* @description Test class for SendHttpRequest_Handler
 */
@IsTest
private class SendHttpRequest_Test {

    @IsTest static void testDynamicMessageCalloutWithoutAuth() {
        Id taskId = createAccount('Test Task');

        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = taskId;
        String objectTypeName = 'Account';
        String groupType = 'TestBulkAccounts';
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testFailDynamicMessageCalloutWithAuth() {
        Id taskId = createAccount('Test Task');

        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = taskId;
        String objectTypeName = 'Account';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        try {
            Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
            mission.With_Authentication__c = true;
            mission.Named_Credential_Key__c = '';
            insert mission;
        }
        catch (Exception ex){
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
    }

    @IsTest static void testMasterDynamicMessageCallout() {
        Id taskId = createAccount('Test Task');

        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = taskId;
        String objectTypeName = 'Account';
        String groupType = 'TestBulkAccounts';
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testFailIdDynamicMessageCallout() {
        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = '1234';
        String objectTypeName = 'Account';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        try {
            Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
            insert mission;
        }
        catch (Exception ex){
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
    }

    @IsTest static void testFailObjectTypeNameDynamicMessageCallout() {
        Id taskId = createAccount('Test Task');

        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = taskId;
        String objectTypeName = 'Test';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        try {
            Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
            insert mission;
        }
        catch (Exception ex){
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
    }

//    @IsTest static void testFailClassDynamicMessageCallout() {
//        Id taskId = createAccount('Test Task');
//
//        String recordTypeName = 'Dynamic Message';
//        String url = 'http://api.salesforce.com/foo/bar';
//        String urlParameters = '';
//        String contentType = 'application/json';
//        String method = 'POST';
//        String className = 'XmlMessageCreator';
//        String objectId = taskId;
//        String objectTypeName = 'Account';
//        String groupType = null;
//        String status = 'Queued';
//
//        // Set mock callout class
//        try {
//            Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
//            insert mission;
//        }
//        catch (Exception ex){
//            System.debug('The following exception has occurred: ' + ex.getMessage());
//        }
//    }

    @IsTest static void testUploadMessageCallout() {

        String recordTypeName = 'Known Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String body = '<Test>testKnownMessageCallout</Test>';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, null, null, null, body, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testKnownMessageCallout() {
        String recordTypeName = 'Known Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String body = '<Test>testKnownMessageCallout</Test>';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, null, null, null, body, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testFailKnownMessageCallout() {
        String recordTypeName = 'Known Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String body = '<Test>testKnownMessageCallout</Test>';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(500));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, null, null, null, body, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testRecreateCallout() {
        String recordTypeName = 'Known Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String body = '<Test>testKnownMessageCallout</Test>';
        String groupType = null;
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, null, null, null, body, groupType, groupType, status);
        Test.startTest();
        insert mission;
        Test.stopTest();
    }

    @IsTest static void testUpdateMission() {
        String recordTypeName = 'Known Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String body = '<Test>testKnownMessageCallout</Test>';
        String groupType = null;
        String status = 'Fail';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, null, null, null, body, groupType, groupType, status);
        Test.startTest();
        insert mission;
        mission.Status__c = 'Queued';
        update mission;
        Test.stopTest();
    }

    @IsTest static void testBulkDynamicOgms(){

        Integer groupSize = 10;
        List<Outgoing_Message__c> messages = new List<Outgoing_Message__c>();
        List<Account> accList = new List<Account>();
        Group__mdt groupSettings = [SELECT Group_Size__c, DeveloperName FROM Group__mdt WHERE DeveloperName = 'TestBulkAccounts' LIMIT 1];

        for (Integer i = 0; i < groupSize ; i++){
            String name = 'name'+String.valueOf(i);
            Account acc = createAccountsBulk(name);
            accList.add(acc);
        }

        insert accList;

        for (Integer j = 0; j < groupSize ; j++){
            String recordTypeName = 'Dynamic Message';
            String url = 'http://api.salesforce.com/foo/bar';
            String urlParameters = '';
            String contentType = 'application/json';
            String method = 'POST';
            String className = 'JsonMessageCreator';
            String objectId = accList[j].Id;
            String objectTypeName = 'Account';
            String groupType = 'TestBulkAccounts';
            String status = 'Queued';

            Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
            mission.Param1__c = groupSettings.DeveloperName;
            messages.add(mission);
        }
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Test.startTest();
        insert messages;
        Test.stopTest();
    }

    @IsTest static void testOutgoingMessageBatch(){
        Id taskId = createAccount('Test Task');

        String recordTypeName = 'Dynamic Message';
        String url = 'http://api.salesforce.com/foo/bar';
        String urlParameters = '';
        String contentType = 'application/json';
        String method = 'POST';
        String className = 'JsonMessageCreator';
        String objectId = taskId;
        String objectTypeName = 'Account';
        String groupType = 'TestBulkAccounts';
        String status = 'Queued';

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new SendHttpRequest_Mock(200));
        Outgoing_Message__c mission = createOutgoingMessage(recordTypeName, url, urlParameters, contentType, method, className, objectId, objectTypeName, null, groupType, groupType, status);
        
        System.Test.startTest();
        Database.executeBatch(new Outgoing_Message_Batch(new List<Outgoing_Message__c>{mission}));
        System.Test.stopTest();
    }

    public static Outgoing_Message__c createOutgoingMessage(String recordTypeName, String url, String parameters, String contentType, String method, String className, String objectId, String objectTypeName, String body, String groupType, String param1, String status) {
        Id recordTypeId = Schema.SObjectType.Outgoing_Message__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        Outgoing_Message__c outgoingMessage = new Outgoing_Message__c();
        outgoingMessage.RecordTypeId = recordTypeId;
        outgoingMessage.Message_Type__c = recordTypeName;
        outgoingMessage.URL__c = url;
        outgoingMessage.URL_Parameters__c = parameters;
        outgoingMessage.Content_Type__c = contentType;
        outgoingMessage.Method__c = method;
        outgoingMessage.Class_Name__c = className;
        outgoingMessage.Object_Id__c = objectId;
        outgoingMessage.Object_Type_Name__c = objectTypeName;
        outgoingMessage.Body__c = body;
        outgoingMessage.Group__c = groupType;
        outgoingMessage.Param1__c = param1;
        outgoingMessage.Status__c = status;

        return outgoingMessage;
    }


    public static Id createAccount(String name) {
        Account acc = new Account();

        acc.Name = name;

        insert acc;
        return acc.Id;
    }

    static Account createAccountsBulk(String name){
        Account account = new Account();
        account.Name = name;

        return account;
    }
}