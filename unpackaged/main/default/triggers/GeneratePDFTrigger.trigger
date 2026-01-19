trigger GeneratePDFTrigger on JSR__c (after update) {
    List<JSR__c> jsrRecordsToUpdate = new List<JSR__c>();

    // Collect JSR records that need to be updated
    for (JSR__c newJSR : [SELECT Id, Status_Check__c, Name, SA_Identity_Number__c, Technician__r.Name, CreatedDate,Client__c, Client_Reference__c FROM JSR__c WHERE Id IN :Trigger.new]) {
        JSR__c oldJSR = Trigger.oldMap.get(newJSR.Id);

        // Check if Status Check changed from false to true
        if (!oldJSR.Status_Check__c && newJSR.Status_Check__c == true) {
            jsrRecordsToUpdate.add(newJSR);
        }
    }

    if (!jsrRecordsToUpdate.isEmpty()) {
        for (JSR__c jsrRecord : jsrRecordsToUpdate) {
            // Retrieve the Technician Name from the related Technician record
            String technicianName = jsrRecord.Technician__r.Name;
            
            // Construct the PDF title using Technician Name, Client, and Client Reference
            String pdfTitle = technicianName + ' - ' + jsrRecord.Client__c + ' - ' + jsrRecord.Client_Reference__c+' - ' + jsrRecord.SA_Identity_Number__c + ' - ' + jsrRecord.Name+ ' - ' +jsrRecord.CreatedDate;
            
            PDFGenerator.generateAndAttachPDF(jsrRecord.Id, pdfTitle); // Generate and attach the PDF with the custom title
        }
    }
}