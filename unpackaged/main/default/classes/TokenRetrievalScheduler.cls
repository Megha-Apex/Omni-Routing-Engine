global class TokenRetrievalScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        CustomTokenAuth.retrieveToken();
    }
}