public with sharing class SubscriptionStatusBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Execute the batch job
        Database.executeBatch(new SubscriptionStatusBatch());
    }
    
    // Method to schedule the job
    public static String scheduleJob() {
        // Schedule the job to run daily at 12 AM
        String jobName = 'Subscription Status Batch - Daily';
        String cronExp = '0 0 0 * * ?'; // Run at 12 AM every day
        
        // Check if the job is already scheduled
        List<CronTrigger> existingJobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        
        if (!existingJobs.isEmpty()) {
            // If job exists, abort it first
            System.abortJob(existingJobs[0].Id);
        }
        
        // Schedule the new job
        return System.schedule(jobName, cronExp, new SubscriptionStatusBatchScheduler());
    }
}