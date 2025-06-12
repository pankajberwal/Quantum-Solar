public with sharing class SubscriptionTriggerHandler {
    

    
    public static void onBeforeInsert(List<Subscription__c> newSubscriptions) {
        SubscriptionTriggerHelper.updateEndDate(newSubscriptions);
        SubscriptionTriggerHelper.validateEffectivity(newSubscriptions);
        SubscriptionTriggerHelper.updateStatus(newSubscriptions);
    }

    public static void onBeforeUpdate(List<Subscription__c> updatedSubscriptions, Map<Id, Subscription__c> oldSubscriptionsMap) {
        SubscriptionTriggerHelper.updateEndDate(updatedSubscriptions);
        SubscriptionTriggerHelper.validateEffectivity(updatedSubscriptions, oldSubscriptionsMap);
        SubscriptionTriggerHelper.updateStatus(updatedSubscriptions, oldSubscriptionsMap);
    }

}