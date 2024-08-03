# Salesforce Invoice Creation

This repository contains a couple of Visualforce page, an Apex controller, and a custom URL button for creating invoices from records in Salesforce and the ability to view JSON request body in a format accepted by XERO.

## Components

### 1. Apex Controller: `CreateInvoiceController`
- Retrieves URL parameters.
- Processes Opportunity records to create corresponding Invoice and Line Item records.
- Re-queries to get updated fields including roll-up summary and formula fields.
- Includes null checks for robustness.
- Generates JSON representation of the Invoice and Line Items.

### 2. Visualforce Page: `CreateInvoice`
- Displays the details of the created Invoice and associated Line Items.
- Uses the controller to process and display data.
- Includes a `Show JSON` button to generate and display JSON data.

### 3. Visualforce Page: `ShowJsonPage`
- Displays the JSON representation of the Invoice and Line Items.

### 4. Custom URL Button
- URL to trigger the invoice creation process: 
