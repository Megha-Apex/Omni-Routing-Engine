@IsTest
public class CustomTokenAuthMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        // Simulate a successful token retrieval
        if (Test.isRunningTest() && req.getEndpoint().contains('https://login.microsoftonline.com/e4ab1aeb-19aa-4473-ad4a-981c6d9ca982/oauth2/v2.0/token')) {
            res.setStatusCode(200);
            res.setBody('{"access_token":"fakeAccessToken","expires_in":3600}');
        }
        // Simulate an error response
        else {
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('{"error": "Mocked error response"}');
        }
        return res;
    }
}