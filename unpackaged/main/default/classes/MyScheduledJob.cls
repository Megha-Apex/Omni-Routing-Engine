public class MyScheduledJob implements Schedulable {
    private Id jsrRecordId;

    public MyScheduledJob(Id jsrRecordId) {
        this.jsrRecordId = jsrRecordId;
    }

    public void execute(SchedulableContext context) {
        try {
            // Retrieve the JSR__c record using this.jsrRecordId
            JSR__c jsrRecord = [SELECT Id, Name, Status_Check__c, Email_to_Address__c, Email_CC_Address__c FROM JSR__c WHERE Id = :jsrRecordId LIMIT 1];

            // Check if Status_Check__c is still true (to prevent sending if it changed again)
            if (jsrRecord.Status_Check__c) {
                // Split the email addresses by comma and trim any spaces
                List<String> toEmailAddresses = new List<String>();
                List<String> ccEmailAddresses = new List<String>();

                if (!String.isBlank(jsrRecord.Email_to_Address__c)) {
                    toEmailAddresses = jsrRecord.Email_to_Address__c.split(',');
                }

                if (!String.isBlank(jsrRecord.Email_CC_Address__c)) {
                    ccEmailAddresses = jsrRecord.Email_CC_Address__c.split(',');
                }

                for (Integer i = 0; i < toEmailAddresses.size(); i++) {
                    toEmailAddresses[i] = toEmailAddresses[i].trim();
                }

                for (Integer i = 0; i < ccEmailAddresses.size(); i++) {
                    ccEmailAddresses[i] = ccEmailAddresses[i].trim();
                }

                // Create a list of email messages
                List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

                // Query for and attach the PDF from the related list (similar logic as in your original code)
                List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId
                                                           FROM ContentDocumentLink
                                                           WHERE LinkedEntityId = :jsrRecord.Id
                                                           AND ContentDocument.FileType = 'PDF'
                                                           LIMIT 1];

                if (!documentLinks.isEmpty()) {
                    ContentDocumentLink pdfLink = documentLinks[0];
                    ContentDocument pdfDocument = [SELECT Id, Title, FileType, LatestPublishedVersionId
                                                   FROM ContentDocument
                                                   WHERE Id = :pdfLink.ContentDocumentId];

                    for (String emailAddress : toEmailAddresses) {
                        if (!String.isBlank(emailAddress)) {
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            email.setToAddresses(new String[] { emailAddress });
                            email.setSubject('Ledcor Job Summary Report'); // Replace with your email subject
                            email.setPlainTextBody('Please see the attached Job Summary Report. Do not reply to this email.'); // Replace with your email message

                            // Attach the PDF
                            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                            emailAttachment.setFileName(pdfDocument.Title + '.pdf');
                            emailAttachment.setBody([SELECT VersionData
                                                    FROM ContentVersion
                                                    WHERE Id = :pdfDocument.LatestPublishedVersionId][0].VersionData);

                            email.setFileAttachments(new Messaging.EmailFileAttachment[] { emailAttachment });

                            emailMessages.add(email);
                        }
                    }

                    // Add CC addresses to the email
                    if (!ccEmailAddresses.isEmpty()) {
                        emailMessages[0].setCcAddresses(ccEmailAddresses);
                    }

                    // Send the email messages
                    if (!emailMessages.isEmpty()) {
                        Messaging.SendEmailResult[] sendEmailResults = Messaging.sendEmail(emailMessages);
                        // Handle any email sending errors if needed
                    }
                }
            }
        } catch (Exception e) {
            // Handle exceptions here (e.g., log error messages)
            System.debug('Error in MyScheduledJob: ' + e.getMessage());
        }
    }
}