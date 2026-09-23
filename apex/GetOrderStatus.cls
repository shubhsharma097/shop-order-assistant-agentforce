/**
 * Invocable Apex action used by the Shop Order Assistant Agentforce agent.
 * Looks up a Shop_Order__c by order number and returns details ONLY if the
 * supplied email matches the email on the order.
 */
public with sharing class GetOrderStatus {

    public class Request {
        @InvocableVariable(label='Order Number' description='The order number the customer provides, e.g. ORD-1001' required=true)
        public String orderNumber;
        @InvocableVariable(label='Customer Email' description='The email address the customer used when placing the order' required=true)
        public String customerEmail;
    }

    public class Result {
        @InvocableVariable(label='Found' description='True only if the order exists AND the email matches')
        public Boolean found;
        @InvocableVariable(label='Status') public String status;
        @InvocableVariable(label='Estimated Delivery') public Date estimatedDelivery;
        @InvocableVariable(label='Tracking Number') public String trackingNumber;
        @InvocableVariable(label='Message' description='Explanation to relay to the customer')
        public String message;
    }

    @InvocableMethod(label='Get Order Status'
        description='Looks up an order by order number and verifies it belongs to the given email. Use when a customer asks about the status, location, or delivery date of an order.')
    public static List<Result> getStatus(List<Request> requests) {
        // Bulkified: one query for all requests
        Set<String> numbers = new Set<String>();
        for (Request r : requests) numbers.add(r.orderNumber);

        Map<String, Shop_Order__c> byNumber = new Map<String, Shop_Order__c>();
        for (Shop_Order__c o : [SELECT Order_Number__c, Customer_Email__c, Status__c,
                                       Estimated_Delivery__c, Tracking_Number__c
                                FROM Shop_Order__c WHERE Order_Number__c IN :numbers
                                WITH USER_MODE]) {
            byNumber.put(o.Order_Number__c, o);
        }

        List<Result> results = new List<Result>();
        for (Request r : requests) {
            Result res = new Result();
            Shop_Order__c o = byNumber.get(r.orderNumber);
            if (o == null || o.Customer_Email__c == null
                    || !o.Customer_Email__c.equalsIgnoreCase(r.customerEmail)) {
                // Same message either way, so the agent never confirms an order exists to the wrong person
                res.found = false;
                res.message = 'No order matches that order number and email combination.';
            } else {
                res.found = true;
                res.status = o.Status__c;
                res.estimatedDelivery = o.Estimated_Delivery__c;
                res.trackingNumber = o.Tracking_Number__c;
                res.message = 'Order found.';
            }
            results.add(res);
        }
        return results;
    }
}
