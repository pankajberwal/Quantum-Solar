trigger SubscriptionTrigger on Subscription__c (before insert, before update) {
    if(Trigger.isBefore && Trigger.isInsert) {
        SubscriptionTriggerHandler.onBeforeInsert(Trigger.New);
    } else if(Trigger.isBefore && Trigger.isUpdate) {
        SubscriptionTriggerHandler.onBeforeUpdate(Trigger.New, Trigger.oldMap);
    } 
        

}