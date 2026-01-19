public class CopyFileClass {
    @InvocableMethod(label='Copy Files from JSR to Work Order' description='Copies PDF files from JSR to Work Order')
    public static void copyFiles(List<Id> jsrRecordIds) {
        List<ContentDocumentLink> contentDocumentLinksToCopy = new List<ContentDocumentLink>();

        for (Id jsrId : jsrRecordIds) {
            JSR__c jsr;
            try {
                jsr = [SELECT Id, Status_check__c, Service_Appointment__c FROM JSR__c WHERE Id = :jsrId LIMIT 1];
            } catch (QueryException e) {
                System.debug('No JSR record found with Id: ' + jsrId);
                continue; // Skip to the next iteration if JSR record not found
            }

            if (jsr.Status_check__c && jsr.Service_Appointment__c != null) {
                // Query ContentDocumentLinks related to the JSR record
                List<ContentDocumentLink> jsrContentDocuments = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :jsr.Id
                ];

                for (ContentDocumentLink cdLink : jsrContentDocuments) {
                    // Check if the file has a .pdf extension
                    List<ContentVersion> pdfFiles = [
                        SELECT Id, Title, VersionData, ContentDocumentId
                        FROM ContentVersion
                        WHERE ContentDocumentId = :cdLink.ContentDocumentId
                          AND FileExtension = 'pdf'
                        LIMIT 1
                    ];

                    if (!pdfFiles.isEmpty()) {
                        ContentVersion contentVersion = pdfFiles[0];

                        System.debug('PDF File found: ' + contentVersion.Title);

                        // Create a new ContentDocumentLink for the Service Appointment record
                        Id workOrderId;
                        ServiceAppointment saRecord;
                        try {
                            saRecord = [SELECT Work_Order__c FROM ServiceAppointment WHERE Id = :jsr.Service_Appointment__c LIMIT 1];
                            if (saRecord != null && saRecord.Work_Order__c != null) {
                                workOrderId = saRecord.Work_Order__c;
                            } else {
                                System.debug('No Work Order found for Service Appointment: ' + jsr.Service_Appointment__c);
                                continue; // Skip to the next iteration if Work Order not found
                            }
                        } catch (QueryException e) {
                            System.debug('Error querying Service Appointment: ' + e.getMessage());
                            continue; // Skip to the next iteration if there is an error querying Service Appointment
                        }

                        ContentDocumentLink saCdLink = new ContentDocumentLink(
                            ContentDocumentId = contentVersion.ContentDocumentId,
                            LinkedEntityId = jsr.Service_Appointment__c,
                            ShareType = 'V'
                        );
                        contentDocumentLinksToCopy.add(saCdLink);

                        // Create a new ContentDocumentLink for the Work Order record
                        if (workOrderId != null) {
                            ContentDocumentLink woCdLink = new ContentDocumentLink(
                                ContentDocumentId = contentVersion.ContentDocumentId,
                                LinkedEntityId = workOrderId,
                                ShareType = 'V'
                            );
                            contentDocumentLinksToCopy.add(woCdLink);
                        } else {
                            System.debug('No Work Order found for Service Appointment: ' + jsr.Service_Appointment__c);
                        }
                    } else {
                        System.debug('No PDF file found for ContentDocumentId: ' + cdLink.ContentDocumentId);
                    }
                }
            }
        }

        // Insert the new ContentDocumentLinks
        if (!contentDocumentLinksToCopy.isEmpty()) {
            System.debug('Inserting ContentDocumentLinks: ' + contentDocumentLinksToCopy);
            insert contentDocumentLinksToCopy;
        }
    }
}