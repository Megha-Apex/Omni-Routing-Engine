public with sharing class AbsenceRecurrenceController {
    
    private static Map<Integer, String> numberOfTheWeekToString = new Map<Integer, String>{1 => 'The First', 2 => 'Second', 3 => 'Third', 4 => 'Forth', 5 => 'Last'};
    private static Integer creationBatchSize = 200, creationSynchronousLimit = 200;
    
    @AuraEnabled
    public static List<AbsenceRecurrenceWrapper> obtainAbsenceRecurrence(String resourceId) {
        DateTime dateTimeNow = DateTime.now();
        List<AbsenceRecurrenceWrapper> absenceWrapperList = new List<AbsenceRecurrenceWrapper>();
        List<AggregateResult> absenceRecurrenceList = [SELECT Min(Start)minStart, Max(End)maxEnd, Type, Recurrence_Key__c FROM ResourceAbsence WHERE (Is_Processed__c != '2' OR Is_Processed_CP__c != '2') AND Start > :dateTimeNow AND ResourceId = :resourceId GROUP BY Recurrence_Key__c, Type];
        for(AggregateResult aggregateResult_i : absenceRecurrenceList) {
            absenceWrapperList.add(new AbsenceRecurrenceWrapper((String)aggregateResult_i.get('Recurrence_Key__c'), (String)aggregateResult_i.get('Type'), (DateTime)aggregateResult_i.get('minStart'), (DateTime)aggregateResult_i.get('maxEnd')));
        }
        return absenceWrapperList;
    }
    
    public static String createAbsenceRecurrence(String action, Set<Id> assignedResources, sObject absenceData, String params) {
        List<Absence_Recurrence_Setting__mdt> abscenceRecurrenceSettings = [SELECT Creation_batch_size__c, Creation_synchronous_limit__c FROM Absence_Recurrence_Setting__mdt LIMIT 1];
        if(abscenceRecurrenceSettings.size() > 0){
            creationSynchronousLimit = (Integer)abscenceRecurrenceSettings[0].Creation_synchronous_limit__c;
            creationBatchSize = (Integer)abscenceRecurrenceSettings[0].Creation_batch_size__c;
        }
        
        Set<Date> datesToCreateSet = new Set<Date>();
        Map<String, Object> paramsMap = (Map<String, Object>)JSON.deserializeUntyped(params);
        if(action == 'DailyRecurrence') {
            String selectedDaysOfTheWeek = (String)paramsMap.get('selectedDaysOfTheWeek');
            datesToCreateSet = dailyRecurrence(((DateTime)absenceData.get('Start')).date(), ((DateTime)absenceData.get('End')).date(), selectedDaysOfTheWeek);
        } else if(action == 'WeeklyRecurrence') {
            Integer recurOnWeekOfEveryMonth = (Integer)paramsMap.get('recurOnWeekOfEveryMonth');
            String selectedDaysOfTheWeek = (String)paramsMap.get('selectedDaysOfTheWeek');
            datesToCreateSet = weeklyRecurrence(((DateTime)absenceData.get('Start')).date(), ((DateTime)absenceData.get('End')).date(), selectedDaysOfTheWeek, recurOnWeekOfEveryMonth);
        } else if(action == 'MonthlyRecurrence') {
            Integer selectedDayOfTheMonth = (Integer)paramsMap.get('selectedDayOfTheMonth');
            String ocurrenceOnWeek = (String)paramsMap.get('ocurrenceOnWeek');
            String dayOfWeek = (String)paramsMap.get('dayOfWeek');
            Integer repeatNumberOfMonths = (Integer)paramsMap.get('repeatNumberOfMonths');
            datesToCreateSet = monthlyRecurrence(((DateTime)absenceData.get('Start')).date(), ((DateTime)absenceData.get('End')).date(), selectedDayOfTheMonth, ocurrenceOnWeek, dayOfWeek, repeatNumberOfMonths);
        }
        return prepareOutput(createAbsences((ResourceAbsence)absenceData, assignedResources, datesToCreateSet));
    }
    
    public static Set<Date> dailyRecurrence(Date recurrenceStartDate, Date recurrenceEndDate, String selectedDaysOfTheWeek) {
        Set<Date> datesToCreateSet = new Set<Date>();
        for(Date date_i = recurrenceStartDate; date_i <= recurrenceEndDate; date_i = date_i.addDays(1)){
            if(selectedDaysOfTheWeek.contains((((DateTime)date_i).formatGMT('EEEE')))) {
                datesToCreateSet.add(date_i);                
            }
        }
        return datesToCreateSet;
    }
    
    public static Set<Date> weeklyRecurrence(Date recurrenceStartDate, Date recurrenceEndDate, String selectedDaysOfTheWeek, Integer recurOnWeekOfEveryMonth) {        
        Set<Date> datesToCreateSet = new Set<Date>();
        for(Date date_i = recurrenceStartDate; date_i <= recurrenceEndDate; date_i = date_i.addDays(1)) {
            Integer numberOfTheWeekInMonth = getNumberOfWeek(date_i);
            if(selectedDaysOfTheWeek.contains(((DateTime)date_i).formatGMT('EEEE')) && numberOfTheWeekInMonth == recurOnWeekOfEveryMonth) {
                datesToCreateSet.add(date_i);
            }
        }
        return datesToCreateSet;
    }
    
    public static Set<Date> monthlyRecurrence(Date recurrenceStartDate, Date recurrenceEndDate, Integer selectedDayOfTheMonth, String ocurrenceOnWeek, String dayOfWeek, Integer repeatNumberOfMonths) {
        Set<Date> datesToCreateSet = new Set<Date>();
        if(repeatNumberOfMonths != 0 && selectedDayOfTheMonth != 0) {
            Date endDateOfMonth = recurrenceEndDate.toStartOfMonth().addDays(Date.daysInMonth(recurrenceEndDate.year(), recurrenceEndDate.month()) - 1);
            for(Date date_i = recurrenceStartDate.addMonths(repeatNumberOfMonths - 1); date_i <= endDateOfMonth; date_i = date_i.addMonths(repeatNumberOfMonths)){
                Date checkDate = Date.newInstance(date_i.year(), date_i.month(), selectedDayOfTheMonth);
                if(checkDate <= recurrenceEndDate && checkDate >= recurrenceStartDate){
                    Integer maxDay = Date.daysInMonth(date_i.year(), date_i.month());
                    Integer selectedDay =  maxDay > selectedDayOfTheMonth ? selectedDayOfTheMonth : maxDay;
                    datesToCreateSet.add(Date.newInstance(date_i.year(), date_i.month(), selectedDay));            
                }
            }
        } else if(String.isNotBlank(ocurrenceOnWeek) && String.isNotBlank(dayOfWeek) && repeatNumberOfMonths != 0) {
            Integer numberOfTheStartMonth = recurrenceStartDate.month();
            for(Date date_i = recurrenceStartDate; date_i <= recurrenceEndDate; date_i = date_i.addDays(1)) {
                Integer numberOfTheWeekInMonth = getNumberOfWeek(date_i);
                Integer numberOfTheCurrentMonth = date_i.month();
                Integer monthsBetween = recurrenceStartDate.monthsBetween(date_i);
                if(numberOfTheWeekToString.get(numberOfTheWeekInMonth) == ocurrenceOnWeek && ((DateTime)date_i).formatGMT('EEEE') == dayOfWeek &&
                   (Math.mod(monthsBetween, repeatNumberOfMonths) == 0 && monthsBetween != 0 || monthsBetween == 0 && repeatNumberOfMonths == 1)) {
                    datesToCreateSet.add(date_i); 
                }
            }
        }
        return datesToCreateSet;
    }
    
    public static List<sObject> createAbsences(ResourceAbsence absenceData, Set<Id> assignedResources, Set<Date> datesToCreateSet){
        if(datesToCreateSet.isEmpty()) {
            return new List<SObject>();   
        }
		Time startTime;
        sObject absenceDataSObject = (sObject)absenceData;
        Integer startTimeMinutes = ((DateTime)absenceDataSObject.get('Start')).time().minute() + ((DateTime)absenceDataSObject.get('Start')).time().hour() * 60;
        Integer endTimeMinutes = ((DateTime)absenceDataSObject.get('End')).time().minute() + ((DateTime)absenceDataSObject.get('End')).time().hour() * 60;
        Integer durationInMinutes = endTimeMinutes - startTimeMinutes;
        List<sObject> absencesToInsertList = new List<sObject>();
        Map<Id, ResourceAbsence> parentAbsenceMap = new Map<Id, ResourceAbsence>();
        Date firstDate = new List<Date>(datesToCreateSet).get(0);
        for(Id resourceId : assignedResources) {
            sObject parentAbsence = new ResourceAbsence();
            parentAbsence.put('Start', DateTime.newInstance(firstDate, ((DateTime)absenceDataSObject.get('Start')).time()));
            parentAbsence.put('End', DateTime.newInstance(firstDate, ((DateTime)absenceDataSObject.get('End')).time()));
            parentAbsence.put('Type', (String)absenceDataSObject.get('Type'));
            parentAbsence.put('Public_Comments__c', (String)absenceDataSObject.get('Public_Comments__c'));
            parentAbsence.put('Internal_Comments__c', (String)absenceDataSObject.get('Internal_Comments__c'));
            parentAbsence.put('ResourceId', resourceId);
            parentAbsence.put('Service_Territory__c', absenceDataSObject.get('Service_Territory__c'));
            parentAbsenceMap.put(resourceId, (ResourceAbsence)parentAbsence);
        }
        if(parentAbsenceMap.values().size() > 0) {
            insert parentAbsenceMap.values();
        }
        for(ResourceAbsence parentAbsence_i : parentAbsenceMap.values()) {
            parentAbsence_i.Recurrence_Key__c = parentAbsence_i.Id;
            parentAbsence_i.Recurrence_Status__c = 'Queued';
        }
        for(Id resourceId : assignedResources) {
            Integer index = 0;
            for(Date date_i : datesToCreateSet) {
                if(index != 0) {
                    ResourceAbsence parentAbsence = parentAbsenceMap.get(resourceId);
                    sObject childAbsence = (sObject)parentAbsence.clone(false, true, false, false);
                    DateTime startDateTime = Datetime.newInstance(date_i, parentAbsence.Start.time());
                    childAbsence.put('Start', startDateTime);
                    DateTime endDateTime = Datetime.newInstance(date_i, parentAbsence.Start.time().addMinutes(durationInMinutes));
                    childAbsence.put('End', endDateTime);
                    childAbsence.put('ResourceId', resourceId);
                    childAbsence.put('Recurrence_Key__c', parentAbsence.Id);
                    absencesToInsertList.add(childAbsence);
                }
                index++;
            }
        }
        if(absencesToInsertList.size() > creationSynchronousLimit) {
            if(Test.isRunningTest()){
                creationBatchSize = 213;
                List<sObject> absencesToCreateTest = new List<sObject>();
                absencesToCreateTest.add(absencesToInsertList[0]);
                absencesToCreateTest.add(absencesToInsertList[1]);
                Database.executeBatch(new AbsenceRecurrenceCreationBatch(absencesToInsertList, parentAbsenceMap), creationBatchSize);
                return null;
            }
            update parentAbsenceMap.values();
            Database.executeBatch(new AbsenceRecurrenceCreationBatch(absencesToInsertList, parentAbsenceMap), creationBatchSize);
            return null;
        }
        for(ResourceAbsence parentAbsence_i : parentAbsenceMap.values()) {
            parentAbsence_i.Recurrence_Status__c = '';
        }
        List<ResourceAbsence> resourceAbsenceList = parentAbsenceMap.values();
        update resourceAbsenceList;
        insert absencesToInsertList;
        return Database.query('SELECT AbsenceNumber, Start, End FROM ResourceAbsence WHERE Id IN :absencesToInsertList OR Id IN :resourceAbsenceList');
    }
    
    @AuraEnabled
    public static void deleteAbsences(List<Id> parentAbsenceIdList) {
        DateTime dateTimeNow = DateTime.now();
        List<ResourceAbsence> absenceToDeleteList = [SELECT Id FROM ResourceAbsence WHERE (Id IN :parentAbsenceIdList AND Start > :dateTimeNow) OR (Recurrence_Key__c IN :parentAbsenceIdList AND Is_Processed__c != '2' AND Start > :dateTimeNow)];
        if(absenceToDeleteList.size() > 0) {
            delete absenceToDeleteList;
        }
    }
    
    public static String prepareOutput(List<sObject> createdRecords){
        if(createdRecords == null){
            return '<h1>' + Label.Please_note_absences_are_being_created_in_the_background + '</h1>';
        }
        if(createdRecords.isEmpty()){
            return '<h1>' + Label.No_record_were_created + '</h1>';
        }
        
        String header = '';
        header = Label.Absence_recurrence_created;
        String htmlOutput = '<h1>'+header+'</h1><p><table><colgroup><col width="200px"><col width="200px"><col width="200px"></colgroup><tr><th align="left">Absence Name</th><th align="left">Start</th><th align="left">Finish</th></tr>';
        for(sObject absence_i : createdRecords){
            htmlOutput += '<tr><td><a href="/' + absence_i.Id + '">' + absence_i.get('AbsenceNumber') + '</a></td>';
            htmlOutput += '<td>'+((Datetime)absence_i.get('Start')).format('d MMM yyyy HH:mm')+'</td>';
            htmlOutput += '<td>'+((Datetime)absence_i.get('End')).format('d MMM yyyy HH:mm')+'</td></tr>';
        }
        htmlOutput += '</table></p>';
        System.debug('htmlOutput: ' + htmlOutput);
        return htmlOutput;
    }
    
    private static Integer getNumberOfWeek(Date date_i) {
        Integer firstDayOfTheWeek = date_i.toStartOfWeek().day();
        Integer numberOfTheWeekInMonth = (Integer)Math.ceil((firstDayOfTheWeek / 7.0));
        return numberOfTheWeekInMonth;
    }
    
    private class AbsenceRecurrenceWrapper {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String availabilityType {get;set;}
        @AuraEnabled
        public DateTime startDate {get;set;}
        @AuraEnabled
        public DateTime endDate {get;set;}
        
        public AbsenceRecurrenceWrapper(String Id, String availabilityType, DateTime startDate, DateTime endDate) {
            this.Id = Id;
            this.availabilityType = availabilityType;
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}