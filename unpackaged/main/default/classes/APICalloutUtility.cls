public class APICalloutUtility {
public String sendSMSEndpoint = 'https://api.prod.ca.five9.net/send-sms-svc/v1/domains/600000000000513/send-sms-tasks';

     public String  getToken(){
          Auth_Token__c tokenRec = [Select Token__c, Client_Name__c from Auth_Token__c where Active__c =true and Client_Name__c = 'Five9SMS' ] ;
       return  tokenRec.Token__c;
    }
    
     public  HttpResponse getResponse(String endPoint,String methodType, String token,String body){
             
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
         req.setEndpoint(endPoint);
        req.setMethod(methodType);
        if(methodType =='POST'){
         req.setBody(body);
        }
        req.setHeader('Content-Type', 'application/json');
             req.setHeader('Grant_type', 'client_credentials'); 
        req.setHeader('Authorization', 'Bearer ' +token);
          
            res = http.send(req);
        return  res;
        
    }
}