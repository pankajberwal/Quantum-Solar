@isTest
public class SubscriptionTriggerTest {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2'),
            new Account(Name = 'Test Account 3'),
            new Account(Name = 'Test Account 4'),
            new Account(Name = 'Test Account 5')
        };
        insert accounts;
        
        // Create test projects
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'Test Project 1', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 2', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 3', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 4', Project_Type__c = 'Community'),
            new Project__c(Name = 'Test Project 5', Project_Type__c = 'Community')
        };
        insert projects;
    }
    
    // Test End Date Calculation
    @isTest
    static void testEndDateCalculation() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Project__c proj1 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        Project__c proj2 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 2' LIMIT 1];
        
        Test.startTest();
        // Test Monthly subscription for Account 1 and Project 1
        Subscription__c monthlySub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert monthlySub;
        
        // Test Quarterly subscription for Account 2 and Project 1
        Subscription__c quarterlySub = new Subscription__c(
            Customer__c = acc2.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Quarterly'
        );
        insert quarterlySub;
        
        // Test Semi-Annually subscription for Account 1 and Project 2
        Subscription__c semiAnnualSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj2.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Semi-Annually'
        );
        insert semiAnnualSub;
        
        // Test Yearly subscription for Account 2 and Project 2
        Subscription__c annualSub = new Subscription__c(
            Customer__c = acc2.Id,
            Project__c = proj2.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Yearly'
        );
        insert annualSub;
        Test.stopTest();
        
        // Verify end dates
        List<Subscription__c> subs = [SELECT Id, Subscription_Term__c, Start_Date__c, Subscription_End_Date__c 
                                    FROM Subscription__c WHERE Id IN :new List<Id>{monthlySub.Id, quarterlySub.Id, 
                                    semiAnnualSub.Id, annualSub.Id}];
        
        for(Subscription__c sub : subs) {
            if(sub.Subscription_Term__c == 'Monthly') {
                System.assertEquals(sub.Start_Date__c.addMonths(1), sub.Subscription_End_Date__c, 
                    'Monthly subscription end date should be 1 month after start date');
            } else if(sub.Subscription_Term__c == 'Quarterly') {
                System.assertEquals(sub.Start_Date__c.addMonths(3), sub.Subscription_End_Date__c, 
                    'Quarterly subscription end date should be 3 months after start date');
            } else if(sub.Subscription_Term__c == 'Semi-Annually') {
                System.assertEquals(sub.Start_Date__c.addMonths(6), sub.Subscription_End_Date__c, 
                    'Semi-Annual subscription end date should be 6 months after start date');
            } else if(sub.Subscription_Term__c == 'Yearly') {
                System.assertEquals(sub.Start_Date__c.addMonths(12), sub.Subscription_End_Date__c, 
                    'Annual subscription end date should be 12 months after start date');
            }
        }
    }
    
    // Test Status Updates
    @isTest
    static void testStatusUpdates() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Project__c proj1 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        
        Test.startTest();
        // Test Active status for Account 1
        Subscription__c activeSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert activeSub;
        
        // Test Inactive status for Account 2
        Subscription__c inactiveSub = new Subscription__c(
            Customer__c = acc2.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addMonths(-2),
            Subscription_Term__c = 'Monthly'
        );
        insert inactiveSub;
        Test.stopTest();
        
        // Verify statuses
        List<Subscription__c> subs = [SELECT Id, Status__c FROM Subscription__c 
                                    WHERE Id IN :new List<Id>{activeSub.Id, inactiveSub.Id}];
        
        for(Subscription__c sub : subs) {
            if(sub.Id == activeSub.Id) {
                System.assertEquals('Active', sub.Status__c, 'Current subscription should be Active');
            } else {
                System.assertEquals('Inactive', sub.Status__c, 'Past subscription should be Inactive');
            }
        }
    }
    
    // Test Overlap Validation
    @isTest
    static void testOverlapValidation() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Project__c proj1 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        
        // Create initial subscription
        Subscription__c existingSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly',
            Status__c = 'Active'
        );
        insert existingSub;
        
        Test.startTest();
        // Test overlapping subscription for same customer and project
        Subscription__c overlappingSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addDays(15),
            Subscription_Term__c = 'Monthly'
        );
        
        try {
            insert overlappingSub;
            System.assert(false, 'Should have thrown an error for overlapping subscription');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('overlaps with an existing active subscription'), 
                'Error message should mention overlap');
        }
        
        // Test non-overlapping subscription for same customer but different project
        Subscription__c nonOverlappingSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = [SELECT Id FROM Project__c WHERE Name = 'Test Project 2' LIMIT 1].Id,
            Start_Date__c = Date.today().addDays(15),
            Subscription_Term__c = 'Monthly'
        );
        insert nonOverlappingSub;
        
        // Test non-overlapping subscription for same project but different customer
        Subscription__c nonOverlappingSub2 = new Subscription__c(
            Customer__c = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1].Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addDays(15),
            Subscription_Term__c = 'Monthly'
        );
        insert nonOverlappingSub2;
        Test.stopTest();
        
        // Verify non-overlapping subscriptions were created
        List<Subscription__c> subs = [SELECT Id FROM Subscription__c 
                                    WHERE Id IN :new List<Id>{nonOverlappingSub.Id, nonOverlappingSub2.Id}];
        System.assertEquals(2, subs.size(), 'Both non-overlapping subscriptions should have been created');
    }
    
    // Test Bulk Operations
    @isTest
    static void testBulkOperations() {
        List<Account> accList= [SELECT Id FROM Account ];
        List<Project__c> projList = [SELECT Id FROM Project__c];
        
        List<Subscription__c> subsToInsert = new List<Subscription__c>();
        // Create subscriptions for Account 1 and Project 1
        for(Integer i = 0; i < 100; i++) {
            subsToInsert.add(new Subscription__c(
                Customer__c = accList.get(Math.mod(i, 5)).Id,
                Project__c = projList.get(Math.mod(i, 5)).Id,
                Start_Date__c = Date.today().addMonths(i),
                Subscription_Term__c = 'Monthly'
            ));
        }
        Date startDate = Date.today().addMonths(-100);
        // Create subscriptions for Account 2 and Project 2
        for(Integer i = 0; i < 100; i++) {
            subsToInsert.add(new Subscription__c(
                Customer__c = accList.get(Math.mod(i, 5)).Id,   
                Project__c = projList.get(Math.mod(i, 5)).Id,
                Start_Date__c = startDate.addMonths(i),
                Subscription_Term__c = 'Monthly'
            ));
        }
        
        Test.startTest();
        insert subsToInsert;
        
        // Update all subscriptions
        for(Subscription__c sub : subsToInsert) {
            sub.Subscription_Term__c = 'Quarterly';
        }
        update subsToInsert;
        Test.stopTest();
        
        // Verify updates
        List<Subscription__c> updatedSubs = [SELECT Id, Subscription_Term__c, Subscription_End_Date__c, Start_Date__c
                                           FROM Subscription__c WHERE Id IN :subsToInsert];
        
        for(Subscription__c sub : updatedSubs) {
            System.assertEquals('Quarterly', sub.Subscription_Term__c, 
                'Subscription term should be updated to Quarterly');
            System.assertEquals(sub.Start_Date__c.addMonths(3), sub.Subscription_End_Date__c, 
                'End date should be updated to 3 months after start date');
        }
    }
    
    // Test Update Scenarios
    @isTest
    static void testUpdateScenarios() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Project__c proj1 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        
        // Create initial subscription
        Subscription__c sub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert sub;
        
        Test.startTest();
        // Test term update
        sub.Subscription_Term__c = 'Quarterly';
        update sub;
        
        // Test start date update
        sub.Start_Date__c = Date.today().addMonths(1);
        update sub;
        
        // Test status update
        sub.Status__c = 'Inactive';
        update sub;
        
        // Try to create overlapping subscription after making current one inactive
        Subscription__c newSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert newSub;
        Test.stopTest();
        
        // Verify final state
        Subscription__c updatedSub = [SELECT Id, Subscription_Term__c, Start_Date__c, 
                                    Subscription_End_Date__c, Status__c 
                                    FROM Subscription__c WHERE Id = :sub.Id];
        
        System.assertEquals('Quarterly', updatedSub.Subscription_Term__c, 
            'Subscription term should be updated to Quarterly');
        System.assertEquals(Date.today().addMonths(1), updatedSub.Start_Date__c, 
            'Start date should be updated');
        System.assertEquals(Date.today().addMonths(4), updatedSub.Subscription_End_Date__c, 
            'End date should be updated to 3 months after new start date');
        System.assertEquals('Inactive', updatedSub.Status__c, 
            'Status should be updated to Inactive');
            
        // Verify new subscription was created after making old one inactive
        List<Subscription__c> newSubs = [SELECT Id FROM Subscription__c WHERE Id = :newSub.Id];
        System.assertEquals(1, newSubs.size(), 'New subscription should be created after making old one inactive');
    }
    
    @isTest
    static void testSubscriptionOverlapValidation() {
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Project__c proj1 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 1' LIMIT 1];
        
        Test.startTest();
        
        // Create initial active subscription
        Subscription__c initialSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert initialSub;
        
        // Test Case 1: Exact same dates - should fail
        Subscription__c overlapSub1 = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        
        try {
            insert overlapSub1;
            System.assert(false, 'Should have thrown an error for exact date overlap');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('overlap'), 
                'Error message should mention overlap');
        }
        
        // Test Case 2: Start date within existing subscription period - should fail
        Subscription__c overlapSub2 = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addDays(15),
            Subscription_Term__c = 'Monthly'
        );
        
        try {
            insert overlapSub2;
            System.assert(false, 'Should have thrown an error for start date within existing period');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('overlap'), 
                'Error message should mention overlap');
        }
        
        // Test Case 3: End date within existing subscription period - should fail
        Subscription__c overlapSub3 = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addDays(-15),
            Subscription_Term__c = 'Monthly'
        );
        
        try {
            insert overlapSub3;
            System.assert(false, 'Should have thrown an error for end date within existing period');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('overlap'), 
                'Error message should mention overlap');
        }
        
        // Test Case 4: Completely encompasses existing subscription - should fail
        Subscription__c overlapSub4 = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today().addDays(-15),
            Subscription_Term__c = 'Quarterly'
        );
        
        try {
            insert overlapSub4;
            System.assert(false, 'Should have thrown an error for encompassing period');
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('overlap'), 
                'Error message should mention overlap');
        }
        
        // Test Case 5: Different customer, same project - should succeed
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        Subscription__c diffCustomerSub = new Subscription__c(
            Customer__c = acc2.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert diffCustomerSub;
        
        // Test Case 6: Same customer, different project - should succeed
        Project__c proj2 = [SELECT Id FROM Project__c WHERE Name = 'Test Project 2' LIMIT 1];
        Subscription__c diffProjectSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj2.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert diffProjectSub;
        
        // Test Case 7: After making initial subscription inactive, should be able to create new one
        initialSub.Status__c = 'Inactive';
        update initialSub;
        
        Subscription__c newSub = new Subscription__c(
            Customer__c = acc1.Id,
            Project__c = proj1.Id,
            Start_Date__c = Date.today(),
            Subscription_Term__c = 'Monthly'
        );
        insert newSub;
        
        Test.stopTest();
        
        // Verify final state
        List<Subscription__c> finalSubs = [
            SELECT Id, Customer__c, Project__c, Start_Date__c, Status__c 
            FROM Subscription__c 
            WHERE Customer__c = :acc1.Id AND Project__c = :proj1.Id
        ];
        
        System.assertEquals(2, finalSubs.size(), 
            'Should have two subscriptions (one inactive, one active)');
        
        // Verify that only one subscription is active
        Integer activeCount = 0;
        for(Subscription__c sub : finalSubs) {
            if(sub.Status__c == 'Active') {
                activeCount++;
            }
        }
        System.assertEquals(1, activeCount, 
            'Should have exactly one active subscription');
    }
} 