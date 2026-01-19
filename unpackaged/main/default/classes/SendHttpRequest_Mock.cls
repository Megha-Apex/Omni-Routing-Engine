/**
* @author Tal Licht
* @date 2020-08-19
* @description mock API for testing the send of outgoing messages
 */
@isTest
public with sharing class SendHttpRequest_Mock implements HttpCalloutMock {
    private Integer statusCode;

    public SendHttpRequest_Mock(Integer statusCode) {
        this.statusCode = statusCode;
    }

    public HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals('http://api.salesforce.com/foo/bar', req.getEndpoint());

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');
        res.setBody('<SUCCESS><QUOTEID>1033203</QUOTEID></SUCCESS>');
        res.setStatusCode(statusCode);
        return res;
    }
}