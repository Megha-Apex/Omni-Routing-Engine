public class AbsenceRecurrenceInvocable {
    @InvocableMethod(label='Absence Recurrence')
    public static List<String> main(List<Request> requestList){
        Request request = requestList[0];
        Set<Id> assignedResources = new Set<Id>();
        for(Id assignedResource_i : request.assignedResources) {
            assignedResources.add(assignedResource_i);
        }
        sObject absenceData = new ResourceAbsence();
        absenceData.put('Start', DateTime.newInstance(request.startDate, convertStringToTime(request.startTime)));
        absenceData.put('End', DateTime.newInstance(request.endDate, convertStringToTime(request.endTime)));
        absenceData.put('Type', request.activityType);
        absenceData.put('Public_Comments__c', request.publicComments);
        absenceData.put('Internal_Comments__c', request.internalComments);
        absenceData.put('Service_Territory__c', request.serviceTerritoryId);

        String action = '';
        String params = '';
        if(request.isDaily != null && request.isDaily) {
            action = 'DailyRecurrence';
            params = JSON.serialize(new AbsenceParams(request.selectedDaysOfTheWeek));
        } else if(request.isWeekly != null && request.isWeekly) {
            action = 'WeeklyRecurrence';
            params = JSON.serialize(new AbsenceParams(request.recurOnWeekOfEveryMonth, request.selectedDaysOfTheWeek));
        } else if(request.isMonthly != null && request.isMonthly) {
            action = 'MonthlyRecurrence';
            params = JSON.serialize(new AbsenceParams(request.selectedDayOfTheMonth, request.ocurrenceOnWeek, request.dayOfWeek, request.repeatNumberOfMonths));
        }
        return new List<String>{AbsenceRecurrenceController.createAbsenceRecurrence(action, assignedResources, absenceData, params)};
    }
    
    private static Time convertStringToTime(String timeString) {
        String[] timeStringSplit = timeString.split(':');
        Time convertedTime = Time.newInstance(Integer.valueOf(timeStringSplit[0]), Integer.valueOf(timeStringSplit[1]), 0, 0);    
        return convertedTime;
    }
    
    public class Request {
        @InvocableVariable(label = 'Start')
        public String startTime;
        
        @InvocableVariable(label = 'End')
        public String endTime;
        
        @InvocableVariable(label = 'Activity Type')
        public String activityType;
        
        @InvocableVariable(label = 'Public Comments')
        public String publicComments;
        
        @InvocableVariable(label = 'Internal Comments')
        public String internalComments;
        
        @InvocableVariable(label = 'Start Date')
        public Date startDate;
        
        @InvocableVariable(label = 'End Date')
        public Date endDate;
        
        @InvocableVariable(label = 'Daily')
        public Boolean isDaily;
        
        @InvocableVariable(label = 'Weekly')
        public Boolean isWeekly;
        
        @InvocableVariable(label = 'Monthly')
        public Boolean isMonthly;
        
        @InvocableVariable(label = 'Selected Days Of The Week')
        public String selectedDaysOfTheWeek;
        
        @InvocableVariable(label = 'Recur On Week Of Every Month')
        public Integer recurOnWeekOfEveryMonth;
        
        @InvocableVariable(label = 'Selected Day Of The Month')
        public Integer selectedDayOfTheMonth;
        
        @InvocableVariable(label = 'Ocurrence On Week')
        public String ocurrenceOnWeek;
        
        @InvocableVariable(label = 'Day Of Week')
        public String dayOfWeek;
        
        @InvocableVariable(label = 'Repeat Number Of Months')
        public Integer repeatNumberOfMonths;
        
        @InvocableVariable(label = 'Assigned Engineers')
        public List<Id> assignedResources;

        @InvocableVariable(label = 'Service Territory')
        public Id serviceTerritoryId;

        public Request() {
           	
        }
    }
    
    private class AbsenceParams {
        public String selectedDaysOfTheWeek;
        public Integer recurOnWeekOfEveryMonth;
        public Integer selectedDayOfTheMonth;
        public String ocurrenceOnWeek;
        public String dayOfWeek;
        public Integer repeatNumberOfMonths;
        
        public AbsenceParams(String selectedDaysOfTheWeek) {
            this.selectedDaysOfTheWeek = selectedDaysOfTheWeek;
        }
        
        public AbsenceParams(Integer recurOnWeekOfEveryMonth, String selectedDaysOfTheWeek) {
        	this.recurOnWeekOfEveryMonth = recurOnWeekOfEveryMonth;
            this.selectedDaysOfTheWeek = selectedDaysOfTheWeek;
        }
        
        public AbsenceParams(Integer selectedDayOfTheMonth, String ocurrenceOnWeek, String dayOfWeek, Integer repeatNumberOfMonths) {
            this.selectedDayOfTheMonth = selectedDayOfTheMonth;
            this.ocurrenceOnWeek = ocurrenceOnWeek;
            this.dayOfWeek = dayOfWeek;
            this.repeatNumberOfMonths = repeatNumberOfMonths;
        }
    }
}