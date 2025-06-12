public with sharing class SubscriptionStatusBatch implements Database.Batchable<sObject>, Database.Stateful {
  private List<string> errorLogs = new List<String>();
  

  public Database.QueryLocator start(Database.BatchableContext bc) {
    // Query all active subscriptions or those needing update
    return Database.getQueryLocator(
      'SELECT Id, Start_Date__c, Subscription_End_Date__c, Project__c, Customer__c, Status__c FROM Subscription__c WHERE (Start_Date__c <= TODAY AND Subscription_End_Date__c > TODAY AND Status__c != \'Active\') OR (Subscription_End_Date__c < TODAY AND Status__c != \'Inactive\') '
    );
  }

  public void execute(
    Database.BatchableContext bc,
    List<Subscription__c> scope
  ) {
    System.debug('SubscriptionStatusBatch execute');
    List<Subscription__c> subsToUpdate = new List<Subscription__c>();

    for (Subscription__c sub : scope) {
      if (sub.Start_Date__c == Date.today() && sub.Status__c != 'Active') {
        sub.Status__c = 'Active';
        subsToUpdate.add(sub);
      } else if (
        sub.Subscription_End_Date__c < Date.today() &&
        sub.Status__c != 'Inactive'
      ) {
        sub.Status__c = 'Inactive';
        subsToUpdate.add(sub);
      }
    }

    if (!subsToUpdate.isEmpty()) {
      Database.SaveResult[] results = Database.update(subsToUpdate, false);

      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          String errorMsg = 'Error updating subscription ' + result.getId() + ': ' + result.getErrors()[0].getMessage();
          errorLogs.add(errorMsg);
        }
      }
    }
  }

  public void finish(Database.BatchableContext bc) {
    if (!errorLogs.isEmpty()) {
      /*
      //Either send email or log the errors
      1 : Send Email
      2: Create a Error Report Object and log the records it can also help in retry mechanism
      */
    } 
  }
}
