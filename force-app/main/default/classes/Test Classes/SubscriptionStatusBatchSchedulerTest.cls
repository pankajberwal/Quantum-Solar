@isTest
public with sharing class SubscriptionStatusBatchSchedulerTest {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2')
        };
        insert accounts;
        
        // Create test projects
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'Test Project 1', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 2', Project_Type__c = 'Community')
        };
        insert projects;
        
        // Create test subscriptions
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Expired subscription
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[0].Id,
            Project__c = projects[0].Id,
            Start_Date__c = Date.today().addMonths(-2),
            Subscription_End_Date__c = Date.today().addDays(-1),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        ));
        
        // Active subscription
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[1].Id,
            Project__c = projects[1].Id,
            Start_Date__c = Date.today(),
            Subscription_End_Date__c = Date.today().addMonths(1),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        ));
        
        insert subscriptions;
    }
    
    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        
        // Schedule the job
        String jobId = SubscriptionStatusBatchScheduler.scheduleJob();
        
        // Verify the job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
        System.assertEquals('0 0 0 * * ?', jobs[0].CronExpression, 
            'Job should be scheduled to run at 12 AM daily');
        
        // Execute the scheduler
        SubscriptionStatusBatchScheduler scheduler = new SubscriptionStatusBatchScheduler();
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify the batch job processed the records
        List<Subscription__c> updatedSubscriptions = [
            SELECT Id, Status__c
            FROM Subscription__c
            ORDER BY Subscription_End_Date__c
        ];
        
        // Verify expired subscription was marked as inactive
        System.assertEquals('Inactive', updatedSubscriptions[0].Status__c,
            'Expired subscription should be marked as Inactive');
        
        // Verify active subscription remained active
        System.assertEquals('Active', updatedSubscriptions[1].Status__c,
            'Active subscription should remain Active');
    }
    
    @isTest
    static void testRescheduleJob() {
        Test.startTest();
        
        // Schedule the job first time
        String jobId1 = SubscriptionStatusBatchScheduler.scheduleJob();
        
        // Schedule the job again (should reschedule)
        String jobId2 = SubscriptionStatusBatchScheduler.scheduleJob();
        
        // Verify only one job exists
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Subscription Status Batch - Daily'
        ];
        
        System.assertEquals(1, jobs.size(), 
            'Only one job should be scheduled after rescheduling');
        
        Test.stopTest();
    }
}