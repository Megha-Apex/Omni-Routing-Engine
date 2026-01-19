trigger WOTrigger on WorkOrder (after insert, after update) {
    List<ServiceAppointment> saToCreate = new List<ServiceAppointment>();

    for (WorkOrder wo : Trigger.new) {
        // Check if Vendor Status is updated to include "Ticket Acceptance"
        Boolean isVendorStatusValid = false;
        
        if (Trigger.isInsert) {
            // For insert, check if it contains 'Ticket Acceptance'
            isVendorStatusValid = (wo.Vendor_Status__c != null && 
                                   wo.Vendor_Status__c.contains('Ticket Acceptance'));
        } else if (Trigger.isUpdate) {
            WorkOrder oldWO = Trigger.oldMap.get(wo.Id);

            // Check if "Ticket Acceptance" was NOT present before but is now present
            Boolean wasTicketAcceptanceAbsent = (oldWO.Vendor_Status__c == null || 
                                                !oldWO.Vendor_Status__c.contains('Ticket Acceptance'));
            Boolean isTicketAcceptancePresent = (wo.Vendor_Status__c != null && 
                                                 wo.Vendor_Status__c.contains('Ticket Acceptance'));

            // Ensure SAs are only created when "Ticket Acceptance" is added for the first time
            isVendorStatusValid = (wasTicketAcceptanceAbsent && isTicketAcceptancePresent);
        }

        // Proceed if Vendor Status is valid
        if (isVendorStatusValid) {
            saToCreate.addAll(ServiceAppointmentUtility.createServiceAppointments(new List<WorkOrder>{wo}));
        }
    }

    // Handle post-creation logic
    ServiceAppointmentUtility.handlePostCreation(saToCreate);
}