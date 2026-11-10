# E-Commerce Revenue Analytics | SQL & Power BI

## Project Overview

This project analyzes two years of transactional data from a UK-based online retailer using SQL Server and Power BI.

The objective is to build a complete analytics workflow, starting from raw transaction data and progressing through data validation, cleaning, modelling, business analysis, and dashboard development.

The project focuses particularly on revenue performance, cancellations, customer activity, product performance, and international sales.

## Dataset

The project uses the **Online Retail II** dataset from the UCI Machine Learning Repository.

The dataset contains more than 1 million transactions recorded between December 2009 and December 2011 for a UK-based non-store online retailer.

The main fields include:

- Invoice
- StockCode
- Description
- Quantity
- InvoiceDate
- Price
- Customer_ID
- Country

The original dataset was provided as a single Excel workbook containing two worksheets:

- 2009–2010
- 2010–2011

Each worksheet was exported to a separate CSV file and imported into SQL Server for analysis.

## Tools

- SQL Server
- SQL Server Management Studio (SSMS)
- Power BI
- Git / GitHub

## Project Workflow

The project follows a structured analytics pipeline:

Raw source data  
→ CSV Export & SQL Server Import
→ Source Validation & Staging
→ Data Quality Investigation
→ Transaction Classification
→ Relational Data Modelling 
→ SQL Business KPIs & Analysis
→ Power BI Dashboard

## SQL Development

### 00 — Database Creation

Creates the SQL Server database used for the project.

`00_create_database.sql`

### 01 — Source Review & Staging

Performs the initial validation of both source datasets, including:

- Row counts
- Date range validation
- Column and datatype review
- Source dataset combination
- Handling of the overlapping period between the two yearly datasets
- Quantity validation
- Price validation
- Creation of the `dbo.All_sales` staging table

The two source datasets overlap between **1 December 2010 and 9 December 2010**. Identical cross-file records within this period are excluded when building the staging table, while potential duplicates within each individual source are preserved for further investigation.

`01_source_review_and_staging.sql`

### 02 — Data Quality Investigation

Investigates unusual transaction patterns before applying cleaning rules.

Current analysis includes:

- Negative and zero quantities
- Missing Customer IDs
- Zero-value transactions
- Invoice prefix patterns
- Cancellation transactions
- Accounting adjustments
- Special StockCodes
- Stock corrections
- Duplicate transaction records

Several unusual records were found to represent legitimate business processes rather than simple data errors.

For example:

- `C` invoice prefixes are associated primarily with cancellation/reversal transactions.
- `A` invoice prefixes are associated with accounting adjustments.
- Special StockCodes include postage, discounts, commissions, fees, samples, manual entries, and other non-standard transactions.
- Missing Customer IDs do not necessarily indicate invalid transactions and may still be useful for revenue, product, country, and time-based analysis.

`02_data_quality_investigation.sql`

### 03 — Transaction Cleaning & Data Modelling

Creates a structured analytical data model using the findings from the data quality investigation.

Key activities include:
- Classifying transactions into commercial sales, cancellations, adjustments, and other transaction categories.
- Calculating transaction values and preparing date fields for reporting.
- Creating a central transaction table (dbo.Transactions).
- Building four dimension tables: DimCustomer, DimProduct, DimInvoice, and DimDate.
- Standardizing product descriptions using CTEs, conditional aggregation, and ROW_NUMBER().
- Validating dimension keys, relationships, and data consistency.
- Confirming that JOINs preserve transaction counts and monetary values.
The model preserves transaction records, including those with missing Customer IDs, while separating different business activities through transaction classification.

`03_cleaning_and_modelling.sql`

## Current Status

The SQL data preparation and modelling phase is complete.

Completed:
- Database setup and data import
- Source validation and consolidation
- Data quality investigation
- Transaction classification
- Creation of the central transaction table and four dimension tables
- Data model validation

Next steps:
- Define and calculate business KPIs using SQL
- Analyze revenue, customers, products, and international sales
- Build reusable SQL reporting views
- Develop the Power BI data model and dashboard
- Document key business insights and recommendations

## Planned Business Analysis

The final analysis will explore areas such as:

- Gross Sales
- Cancelled Sales Value
- Net Revenue
- Number of Orders
- Average Order Value
- Units Sold
- Customer Activity
- Product Performance
- Country Performance
- Monthly and Quarterly Revenue Trends
- Cancellation Patterns

## Project Goal

The goal of this project is to demonstrate practical SQL and Power BI skills through a realistic end-to-end business analytics workflow.

Rather than immediately removing unusual records, the project first investigates their business meaning and documents the reasoning behind each cleaning and modelling decision.
