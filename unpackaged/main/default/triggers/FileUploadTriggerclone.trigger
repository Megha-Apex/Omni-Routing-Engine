trigger FileUploadTriggerclone on ContentDocumentLink (after insert) {
   // Define the user IDs for which the trigger should not run
    Set<Id> excludedUserIds = new Set<Id>{
        '005OI000003ThXhYAK', // Replace with Jerome's User ID
        '0053h000005MEfOAAW'  // Replace with BI user's User ID
    };

    // Check if the current user's ID is in the excluded list
    if (excludedUserIds.contains(UserInfo.getUserId())) {
        System.debug('Trigger skipped as the running user is excluded. UserId: ' + UserInfo.getUserId());
        return;
    }

    List<ContentDocumentLink> newLinks = new List<ContentDocumentLink>();

    // Collecting the Case Ids from the inserted ContentDocumentLinks
    Set<Id> caseIds = new Set<Id>();
    for (ContentDocumentLink link : Trigger.new) {
        if (link.LinkedEntityId.getSObjectType() == Case.SObjectType) {
            caseIds.add(link.LinkedEntityId);
        }
    }

    // Logging case IDs for debugging purposes
    System.debug('Case IDs: ' + caseIds);

    if (!caseIds.isEmpty()) {
        // Querying the related Work Orders
        List<WorkOrder> relatedWorkOrders = [SELECT Id, CaseId FROM WorkOrder WHERE CaseId IN :caseIds];
        
        // Logging related Work Orders for debugging purposes
        System.debug('Related Work Orders: ' + relatedWorkOrders);

        // Cloning the ContentDocumentLink to the related Work Orders
        for (ContentDocumentLink link : Trigger.new) {
            if (link.LinkedEntityId.getSObjectType() == Case.SObjectType) {
                for (WorkOrder wo : relatedWorkOrders) {
                    ContentDocumentLink newLink = new ContentDocumentLink(
                        LinkedEntityId = wo.Id,
                        ContentDocumentId = link.ContentDocumentId,
                        ShareType = link.ShareType,
                        Visibility = link.Visibility
                    );
                    newLinks.add(newLink);
                }
            }
        }
    }

    // Logging new links for debugging purposes
    System.debug('New ContentDocumentLinks: ' + newLinks);

    // Inserting the new ContentDocumentLinks
    if (!newLinks.isEmpty()) {
        try {
            insert newLinks;
        } catch (Exception e) {
            System.debug('Error inserting new ContentDocumentLinks: ' + e.getMessage());
        }
    }
}