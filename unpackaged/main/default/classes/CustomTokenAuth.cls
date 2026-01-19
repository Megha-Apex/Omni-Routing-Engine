public class CustomTokenAuth {
    public class TokenResponse {
        public String access_token;
        public Integer expires_in;
    }

    @future(callout=true)
    public static void retrieveToken() {
        // Log initial governor limits
        logGovernorLimits('Start of retrieveToken');

        List<Token_Metadata__mdt> metadataList = [SELECT Client_Id__c, Client_Secret__c, Scope__c, Token_Endpoint_URL__c, MasterLabel FROM Token_Metadata__mdt];
        List<TokenResponseWrapper> tokenResponses = new List<TokenResponseWrapper>();

        for (Token_Metadata__mdt metadata : metadataList) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(metadata.Token_Endpoint_URL__c);
            System.debug('Endpoint URL: ' + metadata.Token_Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            String clientCredentials = metadata.Client_Id__c + ':' + metadata.Client_Secret__c;
            String encodedCredentials = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(clientCredentials));
            req.setHeader('Authorization', encodedCredentials);

            String scopeParam = '';
            if (metadata.Scope__c != null) {
                scopeParam = '&scope=' + EncodingUtil.urlEncode(metadata.Scope__c, 'UTF-8');
            }

            req.setBody('grant_type=client_credentials' + scopeParam);

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                if (res.getStatusCode() == 200) {
                    TokenResponse tokenResponse = (TokenResponse) JSON.deserialize(res.getBody(), TokenResponse.class);
                    tokenResponses.add(new TokenResponseWrapper(tokenResponse, metadata.MasterLabel));
                } else {
                    System.debug('Error in token retrieval: StatusCode=' + res.getStatusCode() + ', Body=' + res.getBody());
                }
            } catch(Exception e) {
                System.debug('Exception in retrieveToken: ' + e.getMessage());
            }
        }

        // Log governor limits before calling storeTokens
        logGovernorLimits('Before calling storeTokens');

        if (!tokenResponses.isEmpty()) {
            storeTokens(tokenResponses);
        }

        // Log final governor limits
        logGovernorLimits('End of retrieveToken');
    }

    private static void storeTokens(List<TokenResponseWrapper> tokenResponses) {
        // Log governor limits at the start of storeTokens
        logGovernorLimits('Start of storeTokens');

        List<Auth_Token__c> tokensToInsert = new List<Auth_Token__c>();

        for (TokenResponseWrapper tokenResponseWrapper : tokenResponses) {
            deactivateExistingTokens(tokenResponseWrapper.clientName);
            Datetime expirationTime = Datetime.now().addSeconds(tokenResponseWrapper.tokenResponse.expires_in);
            Auth_Token__c newToken = new Auth_Token__c(
                Token__c = tokenResponseWrapper.tokenResponse.access_token,
                Expiration_Time__c = expirationTime,
                Active__c = true,
                Client_Name__c = tokenResponseWrapper.clientName
            );
            tokensToInsert.add(newToken);
        }

        // Log governor limits before inserting tokens
        logGovernorLimits('Before inserting tokens');

        if (!tokensToInsert.isEmpty()) {
            try {
                insert tokensToInsert;
            } catch (DmlException e) {
                System.debug('DmlException: ' + e.getMessage());
            }
        }

        // Log governor limits after inserting tokens
        logGovernorLimits('End of storeTokens');
    }

    private static void deactivateExistingTokens(String clientName) {
        // Log governor limits at the start of deactivateExistingTokens
        logGovernorLimits('Start of deactivateExistingTokens');

        List<Auth_Token__c> tokens = [SELECT Id FROM Auth_Token__c WHERE Active__c = true AND Client_Name__c = :clientName];
        for (Auth_Token__c token : tokens) {
            token.Active__c = false;
        }

        // Log governor limits before updating tokens
        logGovernorLimits('Before updating tokens');

        update tokens;

        // Log governor limits after updating tokens
        logGovernorLimits('End of deactivateExistingTokens');
    }

    private static void logGovernorLimits(String context) {
        System.debug('--- Governor Limits (' + context + ') ---');
        System.debug('  - CPU time (ms): ' + Limits.getCpuTime());
        System.debug('  - Heap size (bytes): ' + Limits.getHeapSize());
        System.debug('  - SOQL queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
        System.debug('  - DML rows: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows());
        System.debug('  - DML statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
        System.debug('  - Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());
        System.debug('  - Future calls: ' + Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls());
        System.debug('  - Query rows: ' + Limits.getQueryRows() + '/' + Limits.getLimitQueryRows());
        System.debug('  - Email invocations: ' + Limits.getEmailInvocations() + '/' + Limits.getLimitEmailInvocations());
       
    }

    private class TokenResponseWrapper {
        public TokenResponse tokenResponse;
        public String clientName;

        public TokenResponseWrapper(TokenResponse tokenResponse, String clientName) {
            this.tokenResponse = tokenResponse;
            this.clientName = clientName;
        }
    }
}