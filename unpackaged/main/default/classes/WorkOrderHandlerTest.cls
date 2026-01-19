@IsTest
public with sharing class WorkOrderHandlerTest {

    @TestSetup
    static void makeData(){
        Request_Type__c requestType = TestFactory.createRequestType('Test Request Type');
        insert requestType;

        Case cs = TestFactory.createCase('Test', requestType.Id, 'test@test.com');
        insert cs;

        Account customer = TestFactory.createCustomer('Test Customer');
        insert customer;

        Account subCustomer = TestFactory.createSubCustomer('Test Sub Customer', customer.Id);
        insert subCustomer;

        SLA__c sla = TestFactory.createSLA('Test SLA', 1, '4');
        insert sla;

        SLA_member__c slaMember = TestFactory.createSLAMember('Test SLA Member', subCustomer.Id, sla.Id);
        insert slaMember;

        Service_Type__c contract = TestFactory.createContract('Test Contract');
        insert contract;

        Service_Type__c jobType = TestFactory.createJobType('Test Job Type', contract.Id);
        insert jobType;

        Service_Type__c serviceType = TestFactory.createServiceType('Test Service Type', 60, jobType.Id, contract.Id);
        insert serviceType;

        Account site = TestFactory.createSite('Test Site', '4', subCustomer.Id, '2800 East 1st Avenue', 'Vancouver', 'Canada', 'BC', 'V5M 4N9');
        insert site;

        WorkOrderHandler handler = new WorkOrderHandler();
    }

    @IsTest
    static void workOrderCreationTest() {
        Case cs = [SELECT Id FROM Case];
        SLA_member__c slaMember = [SELECT Id FROM SLA_member__c];
        Account customer = [SELECT Id FROM Account WHERE Name = 'Test Customer'];
        Account subCustomer = [SELECT Id FROM Account WHERE Name = 'Test Sub Customer'];
        Service_Type__c serviceType = [SELECT Id FROM Service_Type__c WHERE Name = 'Test Service Type'];
        Account site = [SELECT Id FROM Account WHERE Name = 'Test Site'];
        Request_Type__c requestType = [SELECT Id FROM Request_Type__c WHERE Name = 'Test Request Type'];

        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        
        Test.startTest();
        insert wo;
        Test.stopTest();

        wo = [SELECT Id, Work_Order_Identity__c FROM WorkOrder WHERE Id =: wo.Id];
        List<String> identity = wo.Work_Order_Identity__c.split('-');
        System.assertNotEquals(null, wo.Work_Order_Identity__c, 'We should have the work order identity');
        System.assertEquals(2, identity.size(), 'identity should be in the format of {CaseIdentity}-{WO Number}');
        System.assertEquals('1', identity[1], 'WorkOrder identity should be 1');
    }

    @IsTest
    static void workOrderBulkCreationTest() {
        Case cs = [SELECT Id FROM Case];
        SLA_member__c slaMember = [SELECT Id FROM SLA_member__c];
        Account customer = [SELECT Id FROM Account WHERE Name = 'Test Customer'];
        Account subCustomer = [SELECT Id FROM Account WHERE Name = 'Test Sub Customer'];
        Service_Type__c serviceType = [SELECT Id FROM Service_Type__c WHERE Name = 'Test Service Type'];
        Account site = [SELECT Id FROM Account WHERE Name = 'Test Site'];
        Request_Type__c requestType = [SELECT Id FROM Request_Type__c WHERE Name = 'Test Request Type'];

        WorkOrder wo = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        WorkOrder wo3 = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);
        WorkOrder wo2 = TestFactory.createWorkOrder(cs.Id, slaMember.Id, subCustomer.Id, serviceType.Id, site.Id, customer.Id, requestType.Id);

        List<WorkOrder> woList = new List<WorkOrder>{wo,wo2,wo3};
        
        Test.startTest();
        insert woList;
        Test.stopTest();

        Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>([SELECT Id, Work_Order_Identity__c FROM WorkOrder WHERE Id IN: woList]);
        for(Integer i=0; i<woList.size() ; i++) {
            WorkOrder woIdentity = woMap.get(woList[i].Id);
            List<String> identity = woIdentity.Work_Order_Identity__c.split('-');
            System.assertNotEquals(null, woIdentity.Work_Order_Identity__c, 'We should have the work order identity');
            System.assertEquals(2, identity.size(), 'identity should be in the format of {CaseIdentity}-{WO Number}');
            System.assertEquals((i+1) + '', identity[1], 'WorkOrder identity should be 1');
        }

    }
}