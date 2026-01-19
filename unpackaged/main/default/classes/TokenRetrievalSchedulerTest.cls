@IsTest
private class TokenRetrievalSchedulerTest {
    @IsTest
    static void testScheduler() {
        Test.startTest();
        String jobId = System.schedule('TokenRetrieval', '0 0 * * * ?', new TokenRetrievalScheduler());
        Test.stopTest();
        
        // Verify that the job was scheduled
        System.assertNotEquals(null, jobId);
    }
}