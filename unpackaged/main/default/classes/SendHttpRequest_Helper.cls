/**
* @author Tal Licht
* @date 2020-08-19
* @description Helper for sending outgoing messages http requests
*/
public class SendHttpRequest_Helper {

    /**
    * @description Responsible for validating the message before inserting or updating the record
    * @param outgoingMessages the list of new outgoing message objects
    */
    public static void validateMessage(List<Outgoing_Message__c> outgoingMessages){

        for(Outgoing_Message__c outgoingMessage : outgoingMessages) {

            if(outgoingMessage.Message_Type__c == 'Dynamic Message') {
                string className = outgoingMessage.Class_Name__c;
                string sobjectTypeName = outgoingMessage.Object_Type_Name__c;
                Id sobjectId;

                MessageCreatorInterface messageCreatorInstance;
                try {
                    sobjectId = outgoingMessage.Object_Id__c;
                } catch (Exception ex) {
                    string msg = ex.getMessage();
                    if (msg != null && msg.contains('Invalid id')) {
                        outgoingMessage.addError(msg + ', please correct the object Id field.');
                    }
                    return;
                }

                try {
                    DescribeSObjectResult sObjectTypeDescribe = ((SObject)Type.forName(sobjectTypeName).newInstance()).getSObjectType().getDescribe();
                } catch (Exception ex) {
                    outgoingMessage.addError('Error: Incorrect object type name, please correct the object type name field.');
                    return;
                }

                try {
                    Type t = Type.forName(className);
                    messageCreatorInstance = (MessageCreatorInterface) t.newInstance();
                } catch (NullPointerException ex) {
                    outgoingMessage.addError('Error: Massage creator class must implement \'MessageCreatorInterface\', please correct the class name field.');
                    return;
                }

                try {
                    if(outgoingMessage.With_Authentication__c == true) {
                        if(string.isEmpty(outgoingMessage.Named_Credential_Key__c)){
                            outgoingMessage.addError('Error: Invalid named credentials, please correct the named credentials field.');
                            return;
                        }
                        NamedCredential namedCredentials = [SELECT DeveloperName FROM NamedCredential WHERE DeveloperName = :outgoingMessage.Named_Credential_Key__c];
                    }
                } catch (NullPointerException ex) {
                    outgoingMessage.addError('Error: Invalid named credentials, please correct the named credentials field.');
                    return;
                }
            }
        }
    }

    /**
    * @description Responsible for getting the message body
    * @param outgoingMessage the message
    * @param sobj the message as sobject - here for matching the interface when calling it
    * @param childOgms the set of child message ids if it's a master message or the message id if it's a single message
    */
    public static String getBody(Outgoing_Message__c outgoingMessage, SObject sobj, Set<Id> childOgms){
        String messageType = outgoingMessage.Message_Type__c;
        if(messageType == 'Known Message') {
            return outgoingMessage.Body__c;
        }
        else if(messageType == 'Dynamic Message') {
            Id recordId = outgoingMessage.Object_Id__c;
            String className = outgoingMessage.Class_Name__c;
            String sobjectTypeName = outgoingMessage.Object_Type_Name__c;
            String param1 = outgoingMessage.Param1__c;
            String param2 = outgoingMessage.Param2__c;
            Type t = Type.forName(className);
            MessageCreatorInterface messageCreatorInstance = (MessageCreatorInterface)t.newInstance();
            if(messageCreatorInstance != null) {
                if(sobj == null) {
                    return messageCreatorInstance.createMessage(recordId, sobjectTypeName, childOgms, param1, param2);
                }
                else {
                    Outgoing_Message__c ogm = (Outgoing_Message__c)sobj;
                    return messageCreatorInstance.createMessage(ogm, childOgms, param1, param2);
                }
            }
            else {
                System.debug(Logginglevel.ERROR, 'Error: ' + className + '.createMassage(' + recordId + ', ' + sobjectTypeName + ')');
                throw new OgmException('Error: ' + className + '.createMassage(' + recordId + ', ' + sobjectTypeName + ')');
            }
        }
        return null;
    }

    /**
    * @description Responsible for future message callout
    * @param outgoingMessageId the message id
    * @param endpoint the desired endpoint to send the message to
    * @param method the desired method 'POST'/ 'GET'
    * @param contentType the message content type 'dynamic message'/ 'known message'
    * @param parameters the parameters for the url if there are any
    * @param fileName the file name if the content type isn't json
    * @param additionalHeaders additional headers
    * @param childOgms the set of child message ids if it's a master message or the message id if it's a single message
    */
    @Future(callout=true)
    public static void messageCalloutFuture(Id outgoingMessageId, string endpoint, string method, string contentType, string parameters, string fileName, Map<string,string> additionalHeaders, Set<Id> childOgms) {
        try {
            Outgoing_Message__c outgoingMessage = [SELECT Id, Number_Of_Tries__c, Last_Try__c, Class_Name__c, Object_Type_Name__c, Message_Type__c, Object_Id__c, Param1__c, Param2__c, Response_Body__c, Status__c, Body__c, With_Authentication__c, Named_Credential_Key__c
                                                   FROM Outgoing_Message__c
                                                   WHERE Id =: outgoingMessageId];
            Outgoing_Message__c newOgm = messageCallout(outgoingMessage, endpoint, method, contentType, parameters, fileName, additionalHeaders, childOgms);
            update newOgm;
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,ex.getMessage()+'\n\n'+ex.getStackTraceString());

            Outgoing_Message__c outgoingMessage = new Outgoing_Message__c(Id = outgoingMessageId);
            outgoingMessage.Status__c = 'Fail';
            outgoingMessage.Last_Try__c = Datetime.now();
            outgoingMessage.Response_Body__c = 'Error Message: ' + ex.getMessage() + '\nCause: ' + ex.getCause() + '\nStack Trace: ' + ex.getStackTraceString();
            if(outgoingMessage.Number_Of_Tries__c == null) {
                outgoingMessage.Number_Of_Tries__c = 0;
            }
            outgoingMessage.Number_Of_Tries__c++;

            update outgoingMessage;
        }
    }

    /**
    * @description Responsible for non future message callout
    * @param outgoingMessage the message
    * @param endpoint the desired endpoint to send the message to
    * @param method the desired method 'POST'/ 'GET'
    * @param contentType the message content type 'dynamic message'/ 'known message'
    * @param parameters the parameters for the url if there are any
    * @param fileName the file name if the content type isn't json
    * @param additionalHeaders additional headers
    * @param childOgms the set of child message ids if it's a master message or the message id if it's a single message
    */
    public static Outgoing_Message__c messageCallout(Outgoing_Message__c outgoingMessage, string endpoint, string method, string contentType, string parameters, string fileName, Map<string,string> additionalHeaders, Set<Id> childOgms) {
        // if there is child, the outgoing message is master, and the sobj should be the master
        Set<Id> childOgmsSet = childOgms.clone();

        if(childOgmsSet != null && outgoingMessage.Id != null && childOgmsSet.contains(outgoingMessage.Id)) {
            childOgmsSet.remove(outgoingMessage.Id);
        }

        SObject sobj = null;
        if(childOgmsSet != null && childOgmsSet.size() > 0) {
            sobj = outgoingMessage;
        }

        string body = getBody(outgoingMessage, sobj, childOgmsSet);

        return callout(outgoingMessage, endpoint, method, contentType, parameters, fileName, body, additionalHeaders);
    }

    /**
    * @description Responsible for the message callout itself
    * @param outgoingMessage the message
    * @param endpoint the desired endpoint to send the message to
    * @param method the desired method 'POST'/ 'GET'
    * @param contentType the message content type 'dynamic message'/ 'known message'
    * @param parameters the parameters for the url if there are any
    * @param fileName the file name if the content type isn't json
    * @param body the callout message body
    * @param additionalHeaders additional headers
    * @return Outgoing_Message__c the message which the callout is for
    */
    public static Outgoing_Message__c callout(Outgoing_Message__c outgoingMessage, string endpoint, string method, string contentType, string parameters, string fileName, string body, Map<string,string> additionalHeaders){
        try {
            // Send Request
            HTTPResponse res;
            string reqEndPoint = '';

            if(outgoingMessage.With_Authentication__c == true){
                reqEndPoint = 'callout:' + outgoingMessage.Named_Credential_Key__c + '/' + endpoint;
            } else {
                reqEndPoint = endpoint;
            }

            if(parameters != null && parameters.length() > 0) {
                reqEndPoint += '?' + parameters;
            }

            res = regularRequest(reqEndPoint, method, contentType, additionalHeaders, body);
            system.debug('***callout res '+res);
            outgoingMessage.Last_Try__c = Datetime.now();
            outgoingMessage.Number_Of_Tries__c++;

            // Parse Response
            if(res == null) {
                outgoingMessage.Status__c = 'Fail';
                outgoingMessage.Response_Body__c = 'Error Message: HTTPResponse is null';
            }
            else if(res.getStatusCode() == 200) {
                string responseBody = res.getBody();
                outgoingMessage.Response_Body__c = responseBody;
                outgoingMessage.Status__c = 'Sent';
            }
            else {
                outgoingMessage.Status__c = 'Fail';
                outgoingMessage.Response_Body__c = 'Error Message: ' + res.getBody() + '\nStatus: ' + res.getStatus() + '\nStatus Code: ' + res.getStatusCode();
            }
            return outgoingMessage;
        }
        catch(Exception ex) {
            outgoingMessage.Last_Try__c = Datetime.now();
            outgoingMessage.Response_Body__c = 'Error Message: ' + ex.getMessage() + '\nCause: ' + ex.getCause() + '\nStack Trace: ' + ex.getStackTraceString();
            outgoingMessage.Number_Of_Tries__c++;
            outgoingMessage.Status__c = 'Fail';
            return outgoingMessage;
        }
    }

    /**
    * @description Responsible for the message callout itself
    * @param withAuth should the message be sent with authentication
    * @param endpoint the desired endpoint to send the message to
    * @param method the desired method 'POST'/ 'GET'
    * @param contentType the message content type 'dynamic message'/ 'known message'
    * @param additionalHeaders the parameters for the url if there are any
    * @param body the callout message body
    * @return HTTPResponse
    */
    public static HTTPResponse regularRequest(string endpoint, string method, string contentType, Map<string,string> additionalHeaders, string body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(method);
        if(body != null && method != 'GET') {
            req.setBody(body);
        }
        req.setHeader('Content-Type', contentType);
        for(string key : additionalHeaders.keySet()) {
            req.setHeader(key, additionalHeaders.get(key));
        }
        req.setTimeout(120000);

        // Create a new http object to send the request object
        // A response object is generated as a result of the request
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }

    public class OgmException extends Exception {}
}