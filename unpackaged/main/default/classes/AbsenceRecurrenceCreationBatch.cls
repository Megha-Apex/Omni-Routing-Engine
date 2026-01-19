global class AbsenceRecurrenceCreationBatch implements Database.Batchable<sObject>{

    private static String recurrenceStatus='Recurrence_Status__c';

    private List<ResourceAbsence> absenceToCreateList;
    private Map<Id, ResourceAbsence> parentAbsenceMap;


    global AbsenceRecurrenceCreationBatch(List<ResourceAbsence> absenceToCreateList, Map<Id, ResourceAbsence> parentAbsenceMap) {
        this.absenceToCreateList = absenceToCreateList;
        this.parentAbsenceMap = parentAbsenceMap;
	}
    
    global Iterable<sObject> start(Database.BatchableContext BC) {
        for(ResourceAbsence parentAbsence_i : parentAbsenceMap.values()) {
            parentAbsence_i.Recurrence_Status__c = 'In Progress';
        }
        System.debug(parentAbsenceMap);
        update parentAbsenceMap.values();
        return this.absenceToCreateList;
	}
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try {
            insert scope;
        } catch (Exception ex) {
            for(ResourceAbsence parentAbsence_i : parentAbsenceMap.values()) {
                parentAbsence_i.Recurrence_Status__c = 'Failed';
            }
            update parentAbsenceMap.values();
            System.debug('Exception - ' + ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        List<ResourceAbsence> parentAbsenceList = [SELECT Recurrence_Status__c FROM ResourceAbsence WHERE Id IN :parentAbsenceMap.keySet()];
        for(ResourceAbsence parentAbsence_i : parentAbsenceList) {
            if(parentAbsence_i.Recurrence_Status__c != 'Failed') {
            	parentAbsence_i.Recurrence_Status__c = 'Completed';
            }
        }
        update parentAbsenceList;
    }
}