public class ServiceAppointmentUtility {
    // Method to create Service Appointments
    public static List<ServiceAppointment> createServiceAppointments(List<WorkOrder> workOrders) {
        List<ServiceAppointment> saToCreate = new List<ServiceAppointment>();
        Set<Id> accountIds = new Set<Id>();

        // Collect Account IDs for validation
        for (WorkOrder wo : workOrders) {
            if (wo.Bill_to_Customer__c != null) accountIds.add(wo.Bill_to_Customer__c);
            if (wo.Sub_Customer__c != null) accountIds.add(wo.Sub_Customer__c);
        }

        // Query Accounts
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, Send_Potential_Tech__c 
            FROM Account 
            WHERE Id IN :accountIds
        ]);

        // Create Service Appointments
        for (WorkOrder wo : workOrders) {
            Account subCustomerAccount = accountMap.get(wo.Sub_Customer__c);

            // Check if Vendor Status contains 'Ticket Acceptance'
            Boolean isVendorStatusValid = (wo.Vendor_Status__c != null && 
                                         wo.Vendor_Status__c.contains('Ticket Acceptance'));

            if (subCustomerAccount != null && 
                subCustomerAccount.Send_Potential_Tech__c == TRUE && 
                isVendorStatusValid) {

                ServiceAppointment sa = new ServiceAppointment();
                sa.ParentRecordId = wo.Id;
                sa.EarliestStartTime = System.now().addHours(2);
                sa.DueDate = System.today().addDays(14);
                sa.Status = 'Open';
                sa.Work_Order__c = wo.Id;
                sa.Bill_to_Customer__c = wo.Bill_to_Customer__c;
                sa.Sub_Customer__c = wo.Sub_Customer__c;
                sa.Site__c = wo.SiteID__c;
                sa.Duration = wo.Duration;
                sa.ServiceTerritoryId = wo.ServiceTerritoryId;
                sa.Service_Type__c = wo.Service_Type__c;
                sa.Open_Date__c = wo.Open_Date__c;
                sa.Schedule_Automatically__c = false;    
                sa.Reference1__c = wo.Reference1__c;
                sa.Do_Not_Use_SA__c = true;

                saToCreate.add(sa);
            }
        }
        return saToCreate;
    }

    // Handle post-creation logic
    public static void handlePostCreation(List<ServiceAppointment> saToCreate) {
        if (!saToCreate.isEmpty()) {
            try {
                insert saToCreate;
                List<Id> createdSAIds = new List<Id>();
                for (ServiceAppointment sa : saToCreate) {
                    createdSAIds.add(sa.Id);
                }
                System.debug('Created ' + saToCreate.size() + ' Service Appointments');

                // Schedule initial check after 10 minutes
                scheduleDeletionCheck(createdSAIds);

                // Enqueue CandidateFetcherQueueable
                System.enqueueJob(new CandidateFetcherQueueable(createdSAIds, true));
            } catch (DmlException e) {
                System.debug('SA creation error: ' + e.getMessage());
            }
        }
    }

    // Schedule initial deletion check
    private static void scheduleDeletionCheck(List<Id> saIds) {
        Datetime scheduleTime = System.now().addMinutes(10);
        String cronExpression = 
            scheduleTime.second() + ' ' + 
            scheduleTime.minute() + ' ' + 
            scheduleTime.hour() + ' ' + 
            scheduleTime.day() + ' ' + 
            scheduleTime.month() + ' ? ' + 
            scheduleTime.year();

        System.schedule(
            'SACheck_' + System.currentTimeMillis(),
            cronExpression,
            new DeleteTempSAJob(saIds)
        );
    }
}