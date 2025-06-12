public with sharing class SubscriptionSelector {

    private static final String SUBSCRIPTION_FIELDS = 'Id, Project__c, Start_Date__c, Subscription_End_Date__c, Customer__c';

    
   

    public  static List<Subscription__c> querySubscriptions(
        String queryFields,
        String whereClause,
        Map<String, Object> bindVariables
    ) {
        queryFields = queryFields == null ? SUBSCRIPTION_FIELDS : queryFields;
        String query = 'SELECT ' + queryFields + ' FROM Subscription__c';
        if(whereClause != null) {
            query += ' WHERE ' + whereClause;
        }
        return Database.queryWithBinds(query, bindVariables, AccessLevel.SYSTEM_MODE);
    }
}