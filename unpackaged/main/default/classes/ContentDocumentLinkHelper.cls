public class ContentDocumentLinkHelper {

    public static void processAfterInsert(Map<Id, ContentDocumentLink> cdlMap) {
        Map<Id, Id> mapContentDocXEmailMessage = new Map<Id, Id>();

        // Collect all ContentDocumentLink records that are linked to EmailMessages
        for (ContentDocumentLink cdl : cdlMap.values()) {
            if (cdl.LinkedEntityId.getSObjectType() == EmailMessage.SObjectType) {
                mapContentDocXEmailMessage.put(cdl.Id, cdl.LinkedEntityId);
            }
        }

        if (!mapContentDocXEmailMessage.isEmpty()) {
            // Query EmailMessages linked to these ContentDocumentLink records
            List<EmailMessage> emList = [
                SELECT Id, ParentId 
                FROM EmailMessage
                WHERE Id IN :mapContentDocXEmailMessage.values()
            ];

            Map<Id, EmailMessage> mapCaseXEmailMessage = new Map<Id, EmailMessage>(emList);
            List<ContentDocumentLink> cdlupd = new List<ContentDocumentLink>();

            // Loop through the ContentDocumentLink records and create new links for the cases
            for (ContentDocumentLink cdl : cdlMap.values()) {
                Id emailMessageId = mapContentDocXEmailMessage.get(cdl.Id);
                if (mapCaseXEmailMessage.containsKey(emailMessageId)) {
                    EmailMessage emailMessage = mapCaseXEmailMessage.get(emailMessageId);
                    ContentDocumentLink newLink = new ContentDocumentLink();
                    newLink.ContentDocumentId = cdl.ContentDocumentId;
                    newLink.LinkedEntityId = emailMessage.ParentId; // Link to the Case
                    newLink.ShareType = 'V'; // Inferred permissions
                    newLink.Visibility = 'AllUsers'; // Set visibility as needed
                    cdlupd.add(newLink);
                }
            }

            // Insert new ContentDocumentLink records
            if (!cdlupd.isEmpty()) {
                try {
                    insert cdlupd;
                } catch (Exception e) {
                    System.debug('Error inserting new ContentDocumentLinks: ' + e.getMessage());
                }
            }
        }
    }
}