trigger ProjectTrigger on Project__c (after insert, after update, after delete, after undelete) {
    Set<Id> parentProjectIds = new Set<Id>();

    // Collect Parent Project IDs from newly inserted or updated projects
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (Project__c project : Trigger.new) {
            if (project.Parent_Project__c != null) {
                parentProjectIds.add(project.Parent_Project__c);
            }

            if (project.Is_Parent__c == true) {
                parentProjectIds.add(project.Id);
            }
        }
    }

    // Collect Parent Project IDs from deleted projects
    if (Trigger.isDelete) {
        for (Project__c project : Trigger.old) {
            if (project.Parent_Project__c != null) {
                parentProjectIds.add(project.Parent_Project__c);
            }

            if (project.Is_Parent__c == true) {
                parentProjectIds.add(project.Id);
            }
        }
    }

    // If there are Parent Project IDs to process, call the helper method
    if (!parentProjectIds.isEmpty()) {
        ProjectHelper.updateParentWorkedHours(parentProjectIds);
    }
}