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

The original dataset was provided across two yearly files:

- 2009–2010
- 2010–2011

## Tools

- SQL Server
- SQL Server Management Studio (SSMS)
- Power BI
- Git / GitHub

## Project Workflow

The project follows a structured analytics pipeline:

Raw source data  
→ Source validation  
→ Combined staging table  
→ Data quality investigation  
→ Cleaning and transaction classification  
→ Analytical data model  
→ Revenue and customer analysis  
→ Power BI dashboard

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

## Current Status

The project is currently in the **data quality investigation and cleaning stage**.

Next steps include:

- Define transaction categories
- Establish cleaning rules
- Separate commercial sales from accounting and operational adjustments
- Create analytical tables
- Calculate revenue KPIs
- Perform customer, product, country, and time-based analysis
- Build the Power BI data model
- Develop the final Power BI dashboard

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
