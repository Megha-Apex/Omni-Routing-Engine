public class OperatingHoursHelper {

    public class Request {
        @InvocableVariable(required=true)
        public String operatingHoursId;

        @InvocableVariable(required=true)
        public Datetime inputDatetime;
    }

    public class Result {
        @InvocableVariable(required=true)
        public Boolean isOutside;
    }

    @InvocableMethod(label='Check if Datetime is Outside Operating Hours' description='Returns true if the datetime is outside the specified operating hours.')
    public static List<Result> isOutsideOperatingHours(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            // Debug: Input Datetime
            System.debug('Input Datetime (GMT): ' + req.inputDatetime);

            // Get Operating Hours Timezone
            OperatingHours oh = [SELECT Id, TimeZone FROM OperatingHours WHERE Id = :req.operatingHoursId LIMIT 1];
            TimeZone tz = TimeZone.getTimeZone(oh.TimeZone);

            // Convert inputDatetime (GMT) to Operating Hours Timezone
            String localDateTimeString = req.inputDatetime.format('yyyy-MM-dd HH:mm:ss', oh.TimeZone);
            Datetime localDateTime = Datetime.valueOf(localDateTimeString);
            System.debug('Local DateTime (' + oh.TimeZone + '): ' + localDateTime);

            // Extract the time portion (localTimeOnly)
            Time localTimeOnly = Time.newInstance(localDateTime.hour(), localDateTime.minute(), localDateTime.second(), 0);
            System.debug('Local Time Only: ' + localTimeOnly);

            // Convert localTimeOnly to milliseconds since midnight
            Integer localTimeMillis = localTimeOnly.hour() * 3600000 + localTimeOnly.minute() * 60000 + localTimeOnly.second() * 1000;
            System.debug('Local Time in Milliseconds: ' + localTimeMillis);

            // Get TimeSlots for the Operating Hours
            List<TimeSlot> timeSlots = [SELECT StartTime, EndTime, DayOfWeek FROM TimeSlot WHERE OperatingHoursId = :req.operatingHoursId];

            // Evaluate if the localDateTime is outside operating hours
            Boolean isOutside = true;
            for (TimeSlot slot : timeSlots) {
                System.debug('Time Slot: ' + slot.DayOfWeek + ' ' + slot.StartTime + ' - ' + slot.EndTime);
                if (slot.DayOfWeek == localDateTime.format('EEEE')) {
                    // Convert slot.StartTime and slot.EndTime to milliseconds since midnight
                    Integer startTimeMillis = slot.StartTime.hour() * 3600000 + slot.StartTime.minute() * 60000 + slot.StartTime.second() * 1000;
                    Integer endTimeMillis = slot.EndTime.hour() * 3600000 + slot.EndTime.minute() * 60000 + slot.EndTime.second() * 1000;

                    // Compare with StartTime and EndTime
                    if (localTimeMillis >= startTimeMillis && localTimeMillis <= endTimeMillis) {
                        isOutside = false;
                        break;
                    }
                }
            }

            // Debug: Result
            System.debug('Is Outside Operating Hours? ' + isOutside);

            // Add the result for this request
            Result res = new Result();
            res.isOutside = isOutside;
            results.add(res);
        }
        return results;
    }
}