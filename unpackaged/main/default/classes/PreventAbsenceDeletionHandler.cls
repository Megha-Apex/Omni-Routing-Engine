public class PreventAbsenceDeletionHandler {
    public static void handleDeletion(List<ResourceAbsence> absencesToDelete, Boolean isExecuting) {
        Set<String> allowedProfiles = new Set<String>{'System Administrator', 'FSL System Admin', 'FSL Dispatch Team Lead Coordinator', 'FSL Dispatcher', 'FSL Dispatch Manager', 'FSL Resource Planner', 'E2C Dispatcher'};
        
        // Retrieve the profiles of the current user
        Set<String> currentUserProfiles = new Set<String>();
        for(User user : [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()]){
            currentUserProfiles.add(user.Profile.Name);
        }
        
        // Check if any of the current user profiles are allowed to delete absences
        Boolean isDeletionAllowed = false;
        for (String profile : currentUserProfiles) {
            if (allowedProfiles.contains(profile)) {
                isDeletionAllowed = true;
                break;
            }
        }
        
        // If deletion is not allowed, throw an exception and prevent the deletion
        if (!isDeletionAllowed && isExecuting) {
            for (ResourceAbsence absence : absencesToDelete) {
                absence.addError('You are not allowed to delete resource absences.');
            }
        }
    }
}