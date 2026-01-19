public class ProjectHelper {
    private static Boolean isProcessing = false; // Prevent recursion

    public static void updateParentWorkedHours(Set<Id> parentProjectIds) {
        if (isProcessing) return; // Prevent recursion
        isProcessing = true;

        try {
            // Step 1: Aggregate child hours
            Map<Id, Decimal> childWorkedHoursMap = new Map<Id, Decimal>();
            List<AggregateResult> aggregateResults = [
                SELECT Parent_Project__c, SUM(Hours_Worked__c) totalWorkedHours
                FROM Project__c
                WHERE Parent_Project__c IN :parentProjectIds
                GROUP BY Parent_Project__c
            ];

            for (AggregateResult result : aggregateResults) {
                Id parentId = (Id) result.get('Parent_Project__c');
                Decimal childHours = (Decimal) result.get('totalWorkedHours');
                childWorkedHoursMap.put(parentId, childHours);
            }

            // Step 2: Query parent projects
            List<Project__c> parentProjects = [
                SELECT Id, Hours_Worked__c, Total_Worked_Hours__c, Is_Parent__c
                FROM Project__c
                WHERE Id IN :parentProjectIds
            ];

            // Step 3: Update parent projects
            List<Project__c> projectsToUpdate = new List<Project__c>();

            for (Project__c parentProject : parentProjects) {
                if (parentProject.Is_Parent__c) {
                    Decimal childHours = childWorkedHoursMap.containsKey(parentProject.Id)
                        ? childWorkedHoursMap.get(parentProject.Id)
                        : 0; // No children, set childHours to 0

                    Decimal parentHours = parentProject.Hours_Worked__c != null
                        ? parentProject.Hours_Worked__c
                        : 0;

                    // If no child projects, copy parent Hours_Worked__c to Total_Worked_Hours__c
                    if (childHours == 0) {
                        parentProject.Total_Worked_Hours__c = parentHours;
                    } else {
                        parentProject.Total_Worked_Hours__c = parentHours + childHours;
                    }

                    projectsToUpdate.add(parentProject);
                }
            }

            if (!projectsToUpdate.isEmpty()) {
                update projectsToUpdate;
                System.debug('Updated Parent Projects: ' + projectsToUpdate);
            } else {
                System.debug('No updates required for Parent Projects.');
            }
        } catch (Exception e) {
            System.debug('Error during parent hours update: ' + e.getMessage());
        } finally {
            isProcessing = false; // Reset static variable
        }
    }
}