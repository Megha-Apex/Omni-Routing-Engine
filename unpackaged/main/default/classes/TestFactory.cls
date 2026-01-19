public with sharing class TestFactory {
    public static WorkOrder createWorkOrder(Id caseId, Id slaId, Id subCustomerId, Id serviceTypeId, Id siteId, Id billToCustomerId, Id requestTypeId) {
        WorkOrder wo = new WorkOrder();
        wo.CaseId = caseId;
        wo.Sub_Customer__c = subCustomerId;
        wo.SLA__c = slaId;
        wo.Service_Type__c = serviceTypeId;
        wo.SiteID__c = siteId;
        wo.Bill_to_Customer__c = billToCustomerId;
        wo.Request_Type__c = requestTypeId;
        return wo;
    }

    public static Case createCase(String subject, Id requestTypeId, String email) {
        Case cs = new Case();
        cs.Subject = subject;
        cs.Status = 'Open';
        cs.Request_Type__c = requestTypeId;
        cs.Requestor_E_Mail__c = email;

        return cs;
    }

    public static Request_Type__c createRequestType(String name) {
        Request_Type__c requestType = new Request_Type__c();
        requestType.Name = name;
        
        return requestType;
    }
    
    public static Account createSite(String name, String siteIdNumber, Id subCustomerId, String street, String city, String country, String state, String postalCode) {
        Account site = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Site').getRecordTypeId();
        site.RecordTypeId = recordTypeId;
        site.Name = name;
        site.Site_ID_number__c = siteIdNumber;
        site.ParentId = subCustomerId;
        site.BillingStreet = street;
        site.BillingCity = city;
        site.BillingCountry = country;
        site.BillingState = state;
        site.BillingPostalCode = postalCode;
        
        return site;
    }

    public static Account createCustomer(String name) {
        Account customer = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Bill_to_Customer').getRecordTypeId();
        customer.RecordTypeId = recordTypeId;
        customer.Name = name;
        
        return customer;
    }

    public static Account createSubCustomer(String name, Id parentAccountId) {
        Account subCustomer = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Sub_Customer').getRecordTypeId();
        subCustomer.RecordTypeId = recordTypeId;
        subCustomer.ParentId = parentAccountId;
        subCustomer.Name = name;
        
        return subCustomer;
    }

    public static SLA_member__c createSLAMember(String name, Id subCustomerId, Id SLAId) {
        SLA_member__c SLAMember = new SLA_member__c();

        SLAMember.Name = name;
        SLAMember.SLA__c = SLAId;
        SLAMember.Sub_Customer__c = subCustomerId;
        
        return SLAMember;
    }

    public static SLA__c createSLA(String name, Integer priority, String priorityCodeID) {
        SLA__c SLA = new SLA__c();

        SLA.Name = name;
        SLA.Priority__c = priority;
        SLA.Priority_Code_ID__c = priorityCodeID;
        
        return SLA;
    }

    public static Service_Type__c createServiceType(String name, Integer duration, Id jobTypeId, Id contractId) {
        Service_Type__c serviceType = new Service_Type__c();

        Id recordTypeId = Schema.SObjectType.Service_Type__c.getRecordTypeInfosByDeveloperName().get('Service_Type').getRecordTypeId();
        serviceType.Name = name;
        serviceType.RecordTypeId = recordTypeId;
        serviceType.Duration__c = duration;
        serviceType.Duration_in__c = 'Minutes';
        serviceType.Job_Type__c = jobTypeId;
        serviceType.Contract_ID__c = contractId;

        return serviceType;
    }

    public static Service_Type__c createJobType(String name, Id contractId) {
        Service_Type__c jobType = new Service_Type__c();

        Id recordTypeId = Schema.SObjectType.Service_Type__c.getRecordTypeInfosByDeveloperName().get('Job_Type').getRecordTypeId();
        jobType.Name = name;
        jobType.RecordTypeId = recordTypeId;
        jobType.Contract_ID__c = contractId;

        return jobType;
    }

    public static Service_Type__c createContract(String name) {
        Service_Type__c contract = new Service_Type__c();

        Id recordTypeId = Schema.SObjectType.Service_Type__c.getRecordTypeInfosByDeveloperName().get('Contract_ID').getRecordTypeId();
        contract.Name = name;
        contract.RecordTypeId = recordTypeId;
        
        return contract;
    }
}