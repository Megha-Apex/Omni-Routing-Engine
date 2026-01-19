/**
 * Created by oreny on 29/10/2020.
 */

public with sharing class WorkOrderHandler {

    public static void beforeInsert(List<WorkOrder> woList) {
        updateWOIdentity(woList);
    }

    public static void beforeUpdate(List<WorkOrder> oldList, Map<Id,WorkOrder> newMap) {
        List<WorkOrder> woToUpdate = new List<WorkOrder>();
        for(WorkOrder oldWO : oldList) {
            WorkOrder newWO = newMap.get(oldWO.Id);
            if (oldWO.CaseId == null && newWO.CaseId != null) {
                woToUpdate.add(newWO);
            }
        }

        if(!woToUpdate.isEmpty()) {
            updateWOIdentity(woToUpdate);
        }
    }

    private static void updateWOIdentity(List<WorkOrder> woList) {
        // Get caseId
        Set<Id> caseIdSet = new Set<Id>();
        for (WorkOrder wo : woList) {
            if (!String.isEmpty(wo.CaseId)) {
                caseIdSet.add(wo.CaseId);
            }
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Case_Identity__c, (SELECT Id FROM WorkOrders) FROM Case WHERE Id IN:caseIdSet]);

        // Get the cs size
        Map<Id, Integer> caseWoSize = new Map<Id, Integer>();
        for (Id caseId : caseMap.keySet()) {
            Case cs = caseMap.get(caseId);
            Integer woSize = cs.WorkOrders.size();
            caseWoSize.put(caseId, woSize);
        }

        // Set WorkOrder identity
        for (WorkOrder wo : woList) {
            Id caseId = wo.CaseId;
            if(String.isEmpty(wo.Work_Order_Identity__c) && !String.isEmpty(caseId)) {
                Case cs = caseMap.get(caseId);
                String identity = cs.Case_Identity__c;

                Integer woSize = caseWoSize.get(caseId);
                ++woSize;
                caseWoSize.put(caseId, woSize);

                wo.Work_Order_Identity__c = identity + '-' + woSize;
            }
        }
    }


}