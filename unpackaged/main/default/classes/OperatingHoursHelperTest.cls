@isTest
public class OperatingHoursHelperTest {

    @testSetup
    static void setupTestData() {
        // Create an Operating Hours record
        OperatingHours oh = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'America/New_York' // EST timezone
        );
        insert oh;

        // Create TimeSlot records for the Operating Hours
        List<TimeSlot> timeSlots = new List<TimeSlot>{
            new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = 'Monday',
                StartTime = Time.newInstance(8, 0, 0, 0), // 8:00 AM
                EndTime = Time.newInstance(17, 0, 0, 0)   // 5:00 PM
            ),
            new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = 'Tuesday',
                StartTime = Time.newInstance(8, 0, 0, 0), // 8:00 AM
                EndTime = Time.newInstance(17, 0, 0, 0)   // 5:00 PM
            ),
            new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = 'Wednesday',
                StartTime = Time.newInstance(8, 0, 0, 0), // 8:00 AM
                EndTime = Time.newInstance(17, 0, 0, 0)   // 5:00 PM
            ),
            new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = 'Thursday',
                StartTime = Time.newInstance(8, 0, 0, 0), // 8:00 AM
                EndTime = Time.newInstance(17, 0, 0, 0)   // 5:00 PM
            ),
            new TimeSlot(
                OperatingHoursId = oh.Id,
                DayOfWeek = 'Friday',
                StartTime = Time.newInstance(8, 0, 0, 0), // 8:00 AM
                EndTime = Time.newInstance(17, 0, 0, 0)   // 5:00 PM
            )
        };
        insert timeSlots;
    }

    @isTest
    static void testIsOutsideOperatingHours_WithinOperatingHours() {
        // Get the Operating Hours record
        OperatingHours oh = [SELECT Id FROM OperatingHours WHERE Name = 'Test Operating Hours' LIMIT 1];

        // Create a test request with a datetime within operating hours
        OperatingHoursHelper.Request req = new OperatingHoursHelper.Request();
        req.operatingHoursId = oh.Id;
        req.inputDatetime = Datetime.newInstanceGmt(2025, 3, 13, 20, 0, 0); // 8:00 PM GMT (3:00 PM EST)

        // Call the method
        List<OperatingHoursHelper.Result> results = OperatingHoursHelper.isOutsideOperatingHours(new List<OperatingHoursHelper.Request>{req});

        // Verify the result
        System.assertEquals(false, results[0].isOutside, 'The datetime should be within operating hours.');
    }

    @isTest
    static void testIsOutsideOperatingHours_OutsideOperatingHours() {
        // Get the Operating Hours record
        OperatingHours oh = [SELECT Id FROM OperatingHours WHERE Name = 'Test Operating Hours' LIMIT 1];

        // Create a test request with a datetime outside operating hours
        OperatingHoursHelper.Request req = new OperatingHoursHelper.Request();
        req.operatingHoursId = oh.Id;
        req.inputDatetime = Datetime.newInstanceGmt(2025, 3, 13, 22, 0, 0); // 10:00 PM GMT (5:00 PM EST)

        // Call the method
        List<OperatingHoursHelper.Result> results = OperatingHoursHelper.isOutsideOperatingHours(new List<OperatingHoursHelper.Request>{req});

        // Verify the result
        System.assertEquals(true, results[0].isOutside, 'The datetime should be outside operating hours.');
    }

    @isTest
    static void testIsOutsideOperatingHours_EdgeCase_StartOfOperatingHours() {
        // Get the Operating Hours record
        OperatingHours oh = [SELECT Id FROM OperatingHours WHERE Name = 'Test Operating Hours' LIMIT 1];

        // Create a test request with a datetime at the start of operating hours
        OperatingHoursHelper.Request req = new OperatingHoursHelper.Request();
        req.operatingHoursId = oh.Id;
        req.inputDatetime = Datetime.newInstanceGmt(2025, 3, 13, 13, 0, 0); // 1:00 PM GMT (8:00 AM EST)

        // Call the method
        List<OperatingHoursHelper.Result> results = OperatingHoursHelper.isOutsideOperatingHours(new List<OperatingHoursHelper.Request>{req});

        // Verify the result
        System.assertEquals(false, results[0].isOutside, 'The datetime should be within operating hours.');
    }

    @isTest
    static void testIsOutsideOperatingHours_EdgeCase_EndOfOperatingHours() {
        // Get the Operating Hours record
        OperatingHours oh = [SELECT Id FROM OperatingHours WHERE Name = 'Test Operating Hours' LIMIT 1];

        // Create a test request with a datetime at the end of operating hours
        OperatingHoursHelper.Request req = new OperatingHoursHelper.Request();
        req.operatingHoursId = oh.Id;
        req.inputDatetime = Datetime.newInstanceGmt(2025, 3, 13, 22, 0, 0); // 10:00 PM GMT (5:00 PM EST)

        // Call the method
        List<OperatingHoursHelper.Result> results = OperatingHoursHelper.isOutsideOperatingHours(new List<OperatingHoursHelper.Request>{req});

        // Verify the result
        System.assertEquals(true, results[0].isOutside, 'The datetime should be outside operating hours.');
    }
}