public class NewUserPasswordResetAction {
    @InvocableMethod(label='Reset New User Password' description='Resets the password for a new user.')
    public static void resetNewUserPassword(List<Id> userIds) {
        for(Id id : userIds) {
            User u = [SELECT Id FROM User WHERE Id = :id LIMIT 1];
            System.resetPassword(u.Id, true);
        }
    }
}