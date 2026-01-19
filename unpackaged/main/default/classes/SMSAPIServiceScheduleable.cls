public class SMSAPIServiceScheduleable implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        
        Database.executeBatch(new SMSAPIServiceBatchable(), 10);
        
    }
}