@isTest
private class SubscriptionStatusBatchTest {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2'),
            new Account(Name = 'Test Account 3'),
            new Account(Name = 'Test Account 4'),
            new Account(Name = 'Test Account 5'),
            new Account(Name = 'Test Account 6'),
            new Account(Name = 'Test Account 7'),
            new Account(Name = 'Test Account 8'),
            new Account(Name = 'Test Account 9'),
            new Account(Name = 'Test Account 10')
        };
        insert accounts;
        
        // Create test projects
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'Test Project 1', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 2', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 3', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 4', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 5', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 6', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 7', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 8', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 9', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 10', Project_Type__c = 'Community')
        };
        insert projects;
        
        // Create test subscriptions with different end dates
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Expired subscription (end date in the past)
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[0].Id,
            Project__c = projects[0].Id,
            Start_Date__c = Date.today().addMonths(-2),
            Subscription_End_Date__c = Date.today().addDays(-1),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        ));
        
        // Expiring today subscription
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[0].Id,
            Project__c = projects[1].Id,
            Start_Date__c = Date.today().addMonths(-1).addDays(-1),
            Subscription_End_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        ));
        
        // Future subscription
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[1].Id,
            Project__c = projects[0].Id,
            Start_Date__c = Date.today(),
            Subscription_End_Date__c = Date.today().addMonths(1),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        ));
        
        // Already inactive subscription
        subscriptions.add(new Subscription__c(
            Customer__c = accounts[1].Id,
            Project__c = projects[1].Id,
            Start_Date__c = Date.today().addMonths(-2),
            Subscription_End_Date__c = Date.today().addDays(-1),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Inactive'
        ));
        
        insert subscriptions;
    }
    
    @isTest
    static void testBatchProcessing() {
        Test.startTest();
        
        // Execute the batch
        Database.executeBatch(new SubscriptionStatusBatch());
        
        Test.stopTest();
        
        // Verify results
        List<Subscription__c> updatedSubscriptions = [
            SELECT Id, Status__c, Subscription_End_Date__c, 
            Start_Date__c, Subscription_Term__c
            FROM Subscription__c
        ];
        // Verify expired subscription
        Subscription__c expiredSub = updatedSubscriptions[0];
        System.assertEquals('Inactive', expiredSub.Status__c,
            'Subscription with past end date should be marked as Inactive');
        
        // Verify expiring today subscription
        Subscription__c expiringTodaySub = updatedSubscriptions[1];
        System.assertEquals('Inactive', expiringTodaySub.Status__c,
            'Subscription ending today should be marked as Inactive');
        
        // Verify future subscription
        Subscription__c futureSub = updatedSubscriptions[2];
        System.assertEquals('Active', futureSub.Status__c,
            'Subscription with future end date should remain Active');
        
        // Verify already inactive subscription
        Subscription__c inactiveSub = updatedSubscriptions[3];
        System.assertEquals('Inactive', inactiveSub.Status__c,
            'Already inactive subscription should remain Inactive');
    }
    
    @isTest
    static void testBatchWithBulkData() {
        // Create 200 subscriptions with various end dates
        List<Account> accList = [SELECT Id FROM Account ];
        List<Project__c> projList = [SELECT Id FROM Project__c ];
        
        List<Subscription__c> bulkSubs = new List<Subscription__c>();
        for(Integer i = 0; i < 200; i++) {
            bulkSubs.add(new Subscription__c(
                Customer__c = accList.get(Math.mod(i, 10)).Id,
                Project__c = projList.get(Math.mod(i/10, 10)).Id,
                Start_Date__c = Date.today().addMonths(-(200-i)).addDays(-1),
                Subscription_Term__c = 'Monthly'
            ));
        }
        insert bulkSubs;
        
        Test.startTest();
        
        // Execute the batch
        Database.executeBatch(new SubscriptionStatusBatch());
        
        Test.stopTest();
        
        // Verify that all expired subscriptions were processed
        List<Subscription__c> updatedSubs = [
            SELECT Id, Status__c, Subscription_End_Date__c, Start_Date__c
            FROM Subscription__c
            WHERE Id IN :bulkSubs
        ];
        
        System.assertEquals(200, updatedSubs.size(),
            'All bulk subscriptions should have been processed');
        
        // Verify status updates
        for(Subscription__c sub : updatedSubs) {
            System.debug('Subscription: ' + sub);
            if(sub.Subscription_End_Date__c < Date.today()) {
                System.assertEquals('Inactive', sub.Status__c,
                    'Expired subscription should be marked as Inactive');
            } else {
                System.assertEquals('Active', sub.Status__c,
                    'Active subscription should remain Active');
            }
        }
    }
} 