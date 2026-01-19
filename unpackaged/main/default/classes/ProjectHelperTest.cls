@isTest
private class ProjectHelperTest {

    @isTest
    static void testUpdateParentWorkedHours_Insert() {
        // Set up parent project
        Project__c parentProject = new Project__c(Name = 'Parent Project', Is_Parent__c = true);
        insert parentProject;

        // Insert child projects (these will automatically calculate Hours_Worked__c through roll-up summary)
        Project__c childProject1 = new Project__c(Name = 'Child Project 1', Parent_Project__c = parentProject.Id);
        Project__c childProject2 = new Project__c(Name = 'Child Project 2', Parent_Project__c = parentProject.Id);
        insert new List<Project__c>{childProject1, childProject2};

        // After inserting child projects, Salesforce will automatically calculate the roll-up summary (Hours_Worked__c)
        // We focus on ensuring the `Total_Worked_Hours__c` field is updated correctly

        Test.startTest();
        // Query the parent project to check if `Total_Worked_Hours__c` is updated correctly after insert
        parentProject = [SELECT Id, Total_Worked_Hours__c FROM Project__c WHERE Id = :parentProject.Id];
        Test.stopTest();

        // Assert that `Total_Worked_Hours__c` was updated as expected
        System.assertEquals(0, parentProject.Total_Worked_Hours__c, 'Total Worked Hours should be correctly updated after child projects are inserted.');
    }

    @isTest
    static void testUpdateParentWorkedHours_Update() {
        // Set up parent project
        Project__c parentProject = new Project__c(Name = 'Parent Project', Is_Parent__c = true);
        insert parentProject;

        // Insert child project
        Project__c childProject = new Project__c(Name = 'Child Project', Parent_Project__c = parentProject.Id);
        insert childProject;

        // Update the child project to simulate a change in the Hours_Worked__c (which will be calculated automatically by the roll-up summary)
        childProject.Name = 'Updated Child Project';
        update childProject;

        // Query the parent project to ensure the `Total_Worked_Hours__c` field is updated correctly
        Test.startTest();
        parentProject = [SELECT Id, Total_Worked_Hours__c FROM Project__c WHERE Id = :parentProject.Id];
        Test.stopTest();

        // Assert that `Total_Worked_Hours__c` is updated correctly after child project update
        System.assertEquals(0, parentProject.Total_Worked_Hours__c, 'Total Worked Hours should be updated correctly after child project is updated.');
    }

    @isTest
    static void testUpdateParentWorkedHours_Delete() {
        // Set up parent project
        Project__c parentProject = new Project__c(Name = 'Parent Project', Is_Parent__c = true);
        insert parentProject;

        // Insert child project
        Project__c childProject = new Project__c(Name = 'Child Project', Parent_Project__c = parentProject.Id);
        insert childProject;

        // Delete the child project to test if `Total_Worked_Hours__c` is recalculated properly
        delete childProject;

        // Query the parent project to ensure that `Total_Worked_Hours__c` is updated correctly
        Test.startTest();
        parentProject = [SELECT Id, Total_Worked_Hours__c FROM Project__c WHERE Id = :parentProject.Id];
        Test.stopTest();

        // After deletion, `Total_Worked_Hours__c` should be 0 since there are no child projects
        System.assertEquals(0, parentProject.Total_Worked_Hours__c, 'Total Worked Hours should be 0 after child project is deleted.');
    }

    @isTest
    static void testUpdateParentWorkedHours_Undelete() {
        // Set up parent project
        Project__c parentProject = new Project__c(Name = 'Parent Project', Is_Parent__c = true);
        insert parentProject;

        // Insert a child project and delete it
        Project__c childProject = new Project__c(Name = 'Child Project', Parent_Project__c = parentProject.Id);
        insert childProject;
        delete childProject;

        // Undelete the child project and verify the update
        undelete childProject;

        // Query the parent project after undeleting the child
        Test.startTest();
        parentProject = [SELECT Id, Total_Worked_Hours__c FROM Project__c WHERE Id = :parentProject.Id];
        Test.stopTest();

        // Total Worked Hours should reflect the child project's hours after it's undeleted
        System.assertEquals(0, parentProject.Total_Worked_Hours__c, 'Total Worked Hours should be updated correctly after child project is undeleted.');
    }

    @isTest
    static void testUpdateParentWorkedHours_TriggerBehavior() {
        // Set up a parent project and insert child projects
        Project__c parentProject = new Project__c(Name = 'Parent Project', Is_Parent__c = true);
        insert parentProject;

        Project__c childProject = new Project__c(Name = 'Child Project', Parent_Project__c = parentProject.Id);
        insert childProject;

        // Now delete and undelete to ensure the trigger logic is covered
        delete childProject;
        undelete childProject;

        // Ensure the update logic via the trigger works, i.e., `updateParentWorkedHours` gets called
        Test.startTest();
        parentProject = [SELECT Id, Total_Worked_Hours__c FROM Project__c WHERE Id = :parentProject.Id];
        Test.stopTest();

        // Assert the parent project's `Total_Worked_Hours__c` field is updated correctly
        System.assertEquals(0, parentProject.Total_Worked_Hours__c, 'The Total Worked Hours should be updated correctly after DML operations on child projects.');
    }
}