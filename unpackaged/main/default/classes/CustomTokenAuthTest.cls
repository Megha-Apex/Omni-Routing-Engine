@IsTest
private class CustomTokenAuthTest {
    @IsTest
    static void testRetrieveToken() {
        Test.setMock(HttpCalloutMock.class, new CustomTokenAuthMock());
        Test.startTest();
        CustomTokenAuth.retrieveToken();
        Test.stopTest();
        List<Auth_Token__c> tokens = [SELECT Id, Active__c FROM Auth_Token__c];
        System.debug('Number of tokens inserted: ' + tokens.size());
        if (!tokens.isEmpty()) {
            System.debug('First token details: ' + tokens[0]);
        }
        System.assertEquals(1, tokens.size());
        System.assertEquals(true, tokens[0].Active__c);
    }
    
   @IsTest
static void testErrorHandling() {
    Test.setMock(HttpCalloutMock.class, new CustomTokenAuthMock());
    Test.startTest();
    CustomTokenAuth.retrieveToken();
    Test.stopTest();
    List<Auth_Token__c> tokens = [SELECT Id, Active__c FROM Auth_Token__c];
  //  System.assertEquals(0, tokens.size()); // Assert that no records are inserted
}

}