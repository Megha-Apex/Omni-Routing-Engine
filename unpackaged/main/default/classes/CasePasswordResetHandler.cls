public class CasePasswordResetHandler {
    // Method to send the standard Salesforce password reset email
    @InvocableMethod(label='Send Password Reset Email' description='Sends the standard Salesforce password reset email to the user specified in the Reset_Password_For__c field.')
    public static void sendPasswordResetEmail(List<Id> caseIds) {
        // Query the Case records and include the Reset_Password_For__c field
        List<Case> cases = [SELECT Id, Reset_Password_For__c FROM Case WHERE Id IN :caseIds];
        List<User> usersToReset = new List<User>();
        
        // Collect User IDs from the Reset_Password_For__c field
        for (Case c : cases) {
            if (c.Reset_Password_For__c != null) {
                usersToReset.add(new User(Id = c.Reset_Password_For__c));
            }
        }
        
        // Send the standard password reset email
        if (!usersToReset.isEmpty()) {
            System.resetPassword(usersToReset[0].Id, true);
        }
    }
}