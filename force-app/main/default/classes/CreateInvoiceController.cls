public class CreateInvoiceController {  
    public Invoice__c invoice { get; set; }  
    public List<Line_Item__c> lineItems { get; set; }  
    public String jsonContent { get; set; }  
    public String accountName { get; set; }  
    public Decimal totalAmount { get; set; }  
    public Decimal amount { get; set; }
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
        invoice = new Invoice__c();  
        lineItems = new List<Line_Item__c>(); 
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
                // Retrieve account name  
                Account acc = [SELECT Id, Name FROM Account WHERE Id = :invoice.Account__c LIMIT 1];  
                accountName = acc.Name;  
                // Calculate line items and total  
                totalAmount = 0;  
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {  
                    if (oli != null && oli.get(lineItemDescriptionField) != null && oli.get(lineItemQuantityField) != null && oli.get(lineItemUnitPriceField) != null) {  
                        Decimal quantity = (Decimal)oli.get(lineItemQuantityField);  
                        Decimal unitPrice = (Decimal)oli.get(lineItemUnitPriceField);  
                        Decimal amount = quantity * unitPrice;  
                        totalAmount += amount;
                        lineItems.add(new Line_Item__c(  
                            Name = (String)oli.get(lineItemDescriptionField),  
                            Quantity__c = quantity,
                            Unit_Price__c = unitPrice
                        ));  
                    }  
                }  
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
        return jsonPage;  
    }   
    public PageReference createRecords() {  
        try {  
            insert invoice;  
            for (Line_Item__c item : lineItems) {  
                item.Invoice__c = invoice.Id;  
            }  
            insert lineItems;  
        } catch (DmlException e) {  
            ApexPages.addMessages(e);  
        }  
        return new PageReference('/' + invoice.Id);  
    }  
}  