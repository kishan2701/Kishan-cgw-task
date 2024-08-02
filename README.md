# Salesforce Invoice Creation

Currently this repository contains a Visualforce page, an Apex controller, and a custom URL button for creating invoices from Opportunity records in Salesforce.

## Components

### 1. Apex Controller: `CreateInvoiceController`
- Retrieves URL parameters and processes records to create corresponding Invoice and Line Item records.

### 2. Visualforce Page: `CreateInvoice`
- Displays the details of the created Invoice and associated Line Items.
- Uses the controller to process and display data.

### 3. Custom URL Button
- URL to trigger the invoice creation process: 
