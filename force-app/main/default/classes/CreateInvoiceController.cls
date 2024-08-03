public class CreateInvoiceController {
    public Invoice__c invoice { get; set; }
    public List<Line_Item__c> lineItems { get; set; }
    public String jsonContent { get; set; }
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
        if (originRecordId != null && !String.isEmpty(originRecordId)) {
            processRecordById(originRecordId);
        }
        return null;
    }
    private void processRecordById(Id recordId) {
        String sObjectType = recordId.getSObjectType().getDescribe().getName();
        String query;
        if (sObjectType == 'Opportunity') {
            query = 'SELECT Id, Name, ' +
                    accountField + ', ' +
                    invoiceDateField + ', ' +
                    dueDateField + ', ' +
                    '(SELECT Id, ' +
                    lineItemDescriptionField + ', ' +
                    lineItemQuantityField + ', ' +
                    lineItemUnitPriceField + ' FROM ' + childRelationshipName + ') ' +
                    'FROM Opportunity WHERE Id = :recordId LIMIT 1';
            Opportunity opp = (Opportunity)Database.query(query);
            if (opp != null && opp.get(accountField) != null && opp.get(invoiceDateField) != null && opp.get(dueDateField) != null) {
                Date dueDate = (opp.get(dueDateField) instanceof Datetime) ? ((Datetime)opp.get(dueDateField)).date() : (Date)opp.get(dueDateField);
                invoice = new Invoice__c(
                    Account__c = (Id)opp.get(accountField),
                    Invoice_Date__c = (Date)opp.get(invoiceDateField),
                    Due_Date__c = dueDate,
                    Invoice_Reference__c = 'Reference-' + opp.Name
                );
                insert invoice;
                lineItems = new List<Line_Item__c>();
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (oli != null && oli.get(lineItemDescriptionField) != null && oli.get(lineItemQuantityField) != null && oli.get(lineItemUnitPriceField) != null) {
                        lineItems.add(new Line_Item__c(
                            Invoice__c = invoice.Id,
                            Name = (String)oli.get(lineItemDescriptionField),
                            Quantity__c = (Decimal)oli.get(lineItemQuantityField),
                            Unit_Price__c = (Decimal)oli.get(lineItemUnitPriceField)
                        ));
                    }
                }
                if (!lineItems.isEmpty()) {
                    insert lineItems;
                }
            // Re-query the invoice to get the updated Total Field value
                invoice = [SELECT Id, Name, Account__c, Account__r.Name, Invoice_Date__c, Due_Date__c, Invoice_Reference__c, Total__c
                           FROM Invoice__c
                           WHERE Id = :invoice.Id];
            // Re-query the line items to get the updated Amount Field value
                lineItems = [SELECT Id, Name, Quantity__c, Unit_Price__c, Amount__c
                             FROM Line_Item__c
                             WHERE Invoice__c = :invoice.Id];
            }
        }
    }
    // Method to create JSON representation of the invoice and line items
    public String createInvoiceJson() {
        Map<String, Object> xeroInvoice = new Map<String, Object>();
        xeroInvoice.put('Type', 'ACCREC'); //value for sales invoice as per XERO doc
        xeroInvoice.put('Contact', new Map<String, String>{ 'ContactID' => '0000000' });
        xeroInvoice.put('Date', invoice.Invoice_Date__c.format());
        xeroInvoice.put('DueDate', invoice.Due_Date__c.format());
        xeroInvoice.put('Status', 'DRAFT');
        xeroInvoice.put('CurrencyCode', UserInfo.getDefaultCurrency());
        xeroInvoice.put('InvoiceNumber', invoice.Name);
        xeroInvoice.put('Reference', invoice.Invoice_Reference__c);
        List<Map<String, Object>> xeroLineItems = new List<Map<String, Object>>();
        for (Line_Item__c item : lineItems) {
            Map<String, Object> lineItem = new Map<String, Object>();
            lineItem.put('Description', item.Name);
            lineItem.put('Quantity', item.Quantity__c);
            lineItem.put('UnitAmount', item.Unit_Price__c);
            lineItem.put('LineAmount', item.Amount__c);
            lineItem.put('AccountCode', '200');
            xeroLineItems.add(lineItem);
        }
        xeroInvoice.put('LineItems', xeroLineItems);
        return JSON.serializePretty(xeroInvoice);
    }
    // Method to handle Show JSON button click
    public PageReference showJson() {
        jsonContent = createInvoiceJson();
        PageReference jsonPage = Page.ShowJsonPage;
        jsonPage.getParameters().put('invoiceId', invoice.Id);
        return jsonPage;
    }
    public PageReference createRecords() {
        return new PageReference('/' + invoice.Id);
    }
    public PageReference discardRecords() {
        try {
            if (invoice != null) {
                delete invoice;
            }
            if (!lineItems.isEmpty()) {
                delete lineItems;
            }
        } catch (DmlException e) {
            ApexPages.addMessages(e);
        }
        return new PageReference('/' + originRecordId);
    }
}