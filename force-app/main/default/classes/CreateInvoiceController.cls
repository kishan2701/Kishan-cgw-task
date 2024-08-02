public class CreateInvoiceController {
    public Invoice__c invoice { get; set; }
    public List<Line_Item__c> lineItems { get; set; }
    private String originRecordId;
    private String accountField;
    private String invoiceDateField;
    private String dueDateField;
    private String childRelationshipName;
    private String lineItemDescriptionField;
    private String lineItemQuantityField;
    private String lineItemUnitPriceField;

    public CreateInvoiceController() {
        // Retrieve URL parameters
        originRecordId = ApexPages.currentPage().getParameters().get('origin_record');
        accountField = ApexPages.currentPage().getParameters().get('account');
        invoiceDateField = ApexPages.currentPage().getParameters().get('invoice_date');
        dueDateField = ApexPages.currentPage().getParameters().get('invoice_due_date');
        childRelationshipName = ApexPages.currentPage().getParameters().get('child_relationship_name');
        lineItemDescriptionField = ApexPages.currentPage().getParameters().get('line_item_description');
        lineItemQuantityField = ApexPages.currentPage().getParameters().get('line_item_quantity');
        lineItemUnitPriceField = ApexPages.currentPage().getParameters().get('line_item_unit_price');
    }
    
    public PageReference processRecord() {
        if (originRecordId != null) {
            processRecordById(originRecordId);
        }
        return null;
    }
    
    private void processRecordById(Id recordId) {
        // Determine the object type
        SObjectType sObjectType = recordId.getSObjectType();
        String objectType = sObjectType.getDescribe().getName();

        if (objectType == 'Opportunity') {
            handleOpportunity(recordId);
        } else if (objectType == 'Order') {
            // handleOrder(recordId);
        }
    }
    
    private void handleOpportunity(Id opportunityId) {
        Opportunity opp = [SELECT Id, AccountId, CloseDate, Follow_up_Date__c,
                           (SELECT Id, Name, Quantity, UnitPrice FROM OpportunityLineItems)
                           FROM Opportunity
                           WHERE Id = :opportunityId
                           LIMIT 1];
        invoice = new Invoice__c(
            Account__c = opp.AccountId,
            Invoice_Date__c = opp.CloseDate,
            Due_Date__c = opp.Follow_up_Date__c.date(),
            Invoice_Reference__c = 'Reference-' + opp.Id
        );
        insert invoice;

        lineItems = new List<Line_Item__c>();
        for (OpportunityLineItem oli : opp.OpportunityLineItems) {
            lineItems.add(new Line_Item__c(
                Invoice__c = invoice.Id,
                Name = (String)oli.get(lineItemDescriptionField),
                Quantity__c = (Decimal)oli.get(lineItemQuantityField),
                Unit_Price__c = (Decimal)oli.get(lineItemUnitPriceField)
            ));
        }
        if (!lineItems.isEmpty()) {
            insert lineItems;
        }

        // Re-query the invoice to get the updated fields including the roll-up summary field
        invoice = [SELECT Id, Name, Account__c, Invoice_Date__c, Due_Date__c, Invoice_Reference__c, Total__c
                   FROM Invoice__c
                   WHERE Id = :invoice.Id];

        // Re-query the line items to get the updated formula fields
        lineItems = [SELECT Id, Name, Quantity__c, Unit_Price__c, Amount__c
                     FROM Line_Item__c
                     WHERE Invoice__c = :invoice.Id];
    }
}