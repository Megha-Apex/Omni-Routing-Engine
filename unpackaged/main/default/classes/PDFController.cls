public with sharing class PDFController {
    public List<ImageWrapper> images { get; set; }
    public JSR__c jsrRecord { get; set; }
    public String technicianName { get; set; }

    public class ImageWrapper {
        public String imageUrl { get; set; }
        public String imageTitle { get; set; }

        public ImageWrapper(String imageUrl, String imageTitle) {
            this.imageUrl = imageUrl;
            this.imageTitle = imageTitle;
            
        }
    }

    public PDFController(ApexPages.StandardController stdController) {
        Id currentId = stdController.getId();

        // Fetch images
        images = new List<ImageWrapper>();

        List<ContentDocumentLink> cdlList = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :currentId
                AND ContentDocument.FileType IN ('PNG', 'JPEG', 'JPG')
        ];

        for (ContentDocumentLink cdl : cdlList) {
            ContentVersion cv = [SELECT Id, Title FROM ContentVersion
                                 WHERE ContentDocumentId = :cdl.ContentDocumentId AND IsLatest = true];
            images.add(new ImageWrapper(
                '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + cv.Id,
                cv.Title
            ));
        }

        // Dynamically query all fields of the JSR__c object
        String dynamicQuery = 'SELECT ';

        Map<String, Schema.SObjectField> allMap = Schema.getGlobalDescribe().get('JSR__c').getDescribe().fields.getMap();

        // Construct the field list dynamically
        for (String fieldName : allMap.keySet()) {
            dynamicQuery += fieldName + ', ';
        }

        dynamicQuery = dynamicQuery.removeEnd(', '); // Remove the trailing comma and space
        dynamicQuery += ' FROM JSR__c WHERE Id = :currentId';

        List<JSR__c> jsrRecords = Database.query(dynamicQuery);

        if (!jsrRecords.isEmpty()) {
            jsrRecord = jsrRecords[0];
        }

        // Fetch and display values of lookup fields (replace 'Service_Appointment__c' with your actual API name)
        if (jsrRecord.Service_Appointment__c != null) {
            ServiceAppointment serviceAppointment = [SELECT Service_Appointment_ID__c FROM ServiceAppointment WHERE Id = :jsrRecord.Service_Appointment__c];
            jsrRecord.Service_Appointment__c = serviceAppointment.Service_Appointment_ID__c;
        }

      if (jsrRecord.Technician__c != null) {
    ServiceResource tech = [SELECT Name FROM ServiceResource WHERE Id = :jsrRecord.Technician__c LIMIT 1];
    if (tech != null) {
        jsrRecord.Technician__c = tech.Id;
        technicianName = tech.Name; // Assign the Technician's name to the new variable
    }
}
    }

    // Rest of your code

    public void getData() {
        // Do any additional processing here
            System.debug('Service_Appointment__c Value: ' + jsrRecord.Service_Appointment__c);
        
    }
}