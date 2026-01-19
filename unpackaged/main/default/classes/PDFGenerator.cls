public class PDFGenerator {
    @future(callout=true)
    public static void generateAndAttachPDF(Id jsrRecordId, String pdfTitle) {
        try {
            // Create a Visualforce PageReference
            PageReference pageRef = Page.Generate_JSR; // Replace with your actual Visualforce Page name
            pageRef.getParameters().put('id', jsrRecordId);
			 System.debug('Line 8');
            // Generate the PDF content
            Blob pdfBlob;
          //  pdfBlob = pageRef.getContentAsPDF();// commented from sfdc

// Added from SFDC
     if(Test.isRunningTest()){
            pdfBlob = blob.valueOf('Unit.Test');
         System.debug('pdfblobtestclass='+pdfBlob);
        }else{
            pdfBlob = pageRef.getContentAsPDF();
                 System.debug('pdfblobmainclass='+pdfBlob);
        }
            
            // Ends


            // Create a ContentVersion record
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = pdfTitle; // Set the title to the JSR name
            contentVersion.PathOnClient = pdfTitle + '.pdf'; // Specify the file name
            contentVersion.VersionData = pdfBlob;
            contentVersion.FirstPublishLocationId = jsrRecordId; // Attach to your object
            contentVersion.ContentLocation = 'S'; // 'S' for Salesforce

            insert contentVersion;
        } catch (Exception e) {
            // Handle exceptions here (e.g., log error messages)
            System.debug('Error in PDF generation: ' + e.getMessage());
        }
    }
}