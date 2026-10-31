# Data Source & Preparation

## Dataset

This project uses the **Online Retail II** dataset from the **UCI Machine Learning Repository**.

**Dataset:** Online Retail II  
**Source:** https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii?utm_source=chatgpt.com
**License:**https://creativecommons.org/licenses/by/4.0/legalcode

The dataset contains transactional data from a UK-based online retailer covering the period from **December 2009 to December 2011**.

The original dataset contains more than **1 million transaction records**.

### Main Fields

- Invoice
- StockCode
- Description
- Quantity
- InvoiceDate
- Price
- Customer_ID
- Country

## Original File Structure

The dataset was downloaded as a single Excel workbook containing two worksheets:

- `Year 2009-2010`
- `Year 2010-2011`

## Data Preparation

To prepare the data for SQL Server, I followed these steps:

1. Downloaded the original Online Retail II Excel workbook from the UCI Machine Learning Repository.
2. Reviewed the two yearly worksheets contained in the workbook.
3. Exported each worksheet as a separate CSV file:
   - `online_retail_2009-2010.csv`
   - `online_retail_2010-2011.csv`
4. Imported both CSV files into Microsoft SQL Server.
5. Created the following source tables:
   - `dbo.online_retail_2009-2010`
   - `dbo.online_retail_2010-2011`
6. Used SQL to review the source tables, validate their structure and date ranges, and combine them into a staging table for further analysis.

During the source review, the two yearly datasets were found to overlap between **1 December 2010 and 9 December 2010**. Cross-file duplicate records within this shared period are handled during the staging process.

## Raw Data Availability

The original raw dataset is **not stored in this GitHub repository**.

Anyone wishing to reproduce the analysis can download the complete **Online Retail II** dataset directly from the UCI Machine Learning Repository.

The SQL scripts in the `/sql` folder document the transformation and analysis steps performed after the source data was imported into SQL Server.