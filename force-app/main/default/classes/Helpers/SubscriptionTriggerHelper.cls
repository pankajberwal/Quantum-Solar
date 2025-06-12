public with sharing class SubscriptionTriggerHelper {

    private static Map<String, Integer> subscriptionDurationMap = new Map<String, Integer>{
        'Monthly' => 1,
        'Quarterly' => 3,
        'Semi-Annually' => 6,
        'Yearly' => 12
    };

    
    public static void updateEndDate(List<Subscription__c> newSubscriptions){
        updateEndDate(newSubscriptions, null);
    }

    public static void updateEndDate(List<Subscription__c> newSubscriptions, Map<Id, Subscription__c> oldSubscriptionsMap) {
        for(Subscription__c sub : newSubscriptions) {
            if(oldSubscriptionsMap == null || isUpdateValidForEndDateUpdate(sub, oldSubscriptionsMap)) {
                sub.Subscription_End_Date__c = sub.Start_Date__c.addMonths(subscriptionDurationMap.get(sub.Subscription_Term__c));
                System.debug('Subscription End Date: ' + sub.Subscription_End_Date__c);
            }
        }
    }

    private static Boolean isUpdateValidForEndDateUpdate(Subscription__c newSub, Map<Id, Subscription__c> oldSubscriptionsMap) {
        if(!oldSubscriptionsMap.containsKey(newSub.Id)) {
            return false;
        }

        Subscription__c oldSub = oldSubscriptionsMap.get(newSub.Id);
        return oldSub.Subscription_Term__c != newSub.Subscription_Term__c || oldSub.Start_Date__c != newSub.Start_Date__c;
    }

    public static void validateEffectivity(List<Subscription__c> newSubscriptions){
        validateEffectivity(newSubscriptions, null);
    }


    public static void validateEffectivity(List<Subscription__c> newSubscriptions, Map<Id, Subscription__c> oldSubscriptionsMap) {
        if(newSubscriptions.isEmpty()) return;
        
        // First check for overlaps within the new records
        Map<String, List<Subscription__c>> systemToSubscriptionsMap = checkOverlapsWithinNewRecords(newSubscriptions);
        
        // Collect IDs for existing subscription check
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        Set<Id> customerIds = new Set<Id>();
        Set<Id> subscriptionIds = new Set<Id>();
        
        for(Subscription__c sub : newSubscriptions) {
            if(isUpdateWithDateChange(sub, oldSubscriptionsMap) || sub.Id == null) {
                sharedSolarSystemIds.add(sub.Project__c);
                customerIds.add(sub.Customer__c);
                if(sub.Id != null) {
                    subscriptionIds.add(sub.Id);
                }
            }
        }
        
        if(sharedSolarSystemIds.isEmpty() || customerIds.isEmpty()) return;
        
        // Check for overlaps with existing records
        checkOverlapsWithExistingRecords(systemToSubscriptionsMap, sharedSolarSystemIds, customerIds, subscriptionIds);
    }

    public static void updateStatus(List<Subscription__c> newSubscriptions) {
        updateStatus(newSubscriptions, null);
    }

    public static void updateStatus(List<Subscription__c> newSubscriptions, Map<Id, Subscription__c> oldSubscriptionsMap) {
        for(Subscription__c sub : newSubscriptions) {
            if(oldSubscriptionsMap == null || isUpdateWithDateChange(sub, oldSubscriptionsMap)) {
                if(sub.Start_Date__c <= Date.today() && sub.Subscription_End_Date__c >= Date.today()) {
                    sub.Status__c = 'Active';
                } else {
                    sub.Status__c = 'Inactive';
                }
            }
        }
    }

    private static Map<String, List<Subscription__c>> checkOverlapsWithinNewRecords(List<Subscription__c> newSubscriptions) {
        Map<String, List<Subscription__c>> systemToSubscriptionsMap = new Map<String, List<Subscription__c>>();
        
        for(Subscription__c sub : newSubscriptions) {
            String key = getSubscriptionKey(sub);
            List<Subscription__c> existingSubs = systemToSubscriptionsMap.get(key);
            
            if(existingSubs != null) {
                for(Subscription__c existingSub : existingSubs) {
                    if(isOverlapping(sub, existingSub)) {
                        addOverlapError(sub);
                        break;
                    }
                }
            }
            
            addToSystemMap(systemToSubscriptionsMap, sub);
        }
        
        return systemToSubscriptionsMap;
    }
    
    private static Boolean isUpdateWithDateChange(Subscription__c newSub, Map<Id, Subscription__c> oldSubscriptionsMap) {
        if(oldSubscriptionsMap == null || !oldSubscriptionsMap.containsKey(newSub.Id)) {
            return false;
        }
        
        Subscription__c oldSub = oldSubscriptionsMap.get(newSub.Id);
        return oldSub.Start_Date__c != newSub.Start_Date__c || 
               oldSub.Subscription_End_Date__c != newSub.Subscription_End_Date__c;
    }
    
    private static void checkOverlapsWithExistingRecords(
        Map<String, List<Subscription__c>> systemToSubscriptionsMap,
        Set<Id> sharedSolarSystemIds,
        Set<Id> customerIds,
        Set<Id> subscriptionIds
    ) {
        List<Subscription__c> existingSubscriptions = queryExistingSubscriptions(sharedSolarSystemIds, customerIds, subscriptionIds);
        
        for(Subscription__c existingSub : existingSubscriptions) {
            String key = getSubscriptionKey(existingSub);
            List<Subscription__c> newSubs = systemToSubscriptionsMap.get(key);
            
            if(newSubs != null) {
                for(Subscription__c newSub : newSubs) {
                    if(isOverlapping(newSub, existingSub)) {
                        addOverlapError(newSub);
                    }
                }
            }
        }
    }
    
    private static List<Subscription__c> queryExistingSubscriptions(
        Set<Id> sharedSolarSystemIds,
        Set<Id> customerIds,
        Set<Id> subscriptionIds
    ) {
        String whereClause = 'Project__c IN :sharedSolarSystemIds ' +
                           'AND Customer__c IN :customerIds ' +
                           'AND Status__c = \'Active\' ' +
                           'AND Id NOT IN :subscriptionIds ' +
                           'ORDER BY Start_Date__c';
                           
        Map<String, Object> bindVariables = new Map<String, Object>{
            'sharedSolarSystemIds' => sharedSolarSystemIds,
            'customerIds' => customerIds,
            'subscriptionIds' => subscriptionIds
        };

        return SubscriptionSelector.querySubscriptions(null, whereClause, bindVariables);
    }
    
    private static String getSubscriptionKey(Subscription__c subscription) {
        return subscription.Project__c + '_' + subscription.Customer__c;
    }
    
    private static void addToSystemMap(Map<String, List<Subscription__c>> systemToSubscriptionsMap, Subscription__c subscription) {
        String key = getSubscriptionKey(subscription);
        if(!systemToSubscriptionsMap.containsKey(key)) {
            systemToSubscriptionsMap.put(key, new List<Subscription__c>());
        }
        systemToSubscriptionsMap.get(key).add(subscription);
    }
    
    private static Boolean isOverlapping(Subscription__c sub1, Subscription__c sub2) {
        // Handle null end dates (open-ended subscriptions)
        Date sub1EndDate = sub1.Subscription_End_Date__c != null ? sub1.Subscription_End_Date__c : Date.today().addYears(100);
        Date sub2EndDate = sub2.Subscription_End_Date__c != null ? sub2.Subscription_End_Date__c : Date.today().addYears(100);
        
        return sub1.Start_Date__c <= sub2EndDate && sub2.Start_Date__c <= sub1EndDate;
    }
    
    private static void addOverlapError(Subscription__c subscription) {
        
        subscription.addError(System.Label.Subscription_Overlap_Validation);
    }
}