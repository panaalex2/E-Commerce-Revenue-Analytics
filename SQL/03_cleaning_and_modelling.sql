-- ============================================
-- 1. CREATE MODELLED TRANSACTION TABLE
-- ============================================
-- Classify transactions based on the data quality findings.

DROP TABLE IF EXISTS dbo.Transactions;

SELECT *,
	CASE
		WHEN LEFT (Invoice,1)='A' THEN 'Accounting Adjustment'
		WHEN LEFT (Invoice,1)='C' THEN 
			CASE
				WHEN StockCode = 'M' OR StockCode = 'ADJUST' THEN 'Manual Adjustment'
				WHEN StockCode = 'POST' OR 
					StockCode = 'DOT' OR 
					StockCode = 'C2' THEN 'Postage / Carriage'
				WHEN StockCode = 'D' THEN 'Discount'
				WHEN StockCode = 'CRUK' OR 
					StockCode = 'BANK CHARGES' OR
					StockCode = 'AMAZONFEE' THEN 'Fee / Commission'
				WHEN StockCode = 'S' THEN 'Sample'
				WHEN StockCode = 'TEST001' OR 
					StockCode = 'PADS' OR
					StockCode = 'gift_0001_80' THEN 'Other'
				ELSE 'Cancellation'
				END
		WHEN LEFT (Invoice,1) <> 'A' AND LEFT (Invoice,1) <> 'C' THEN 
			CASE
				WHEN Price = 0 AND Quantity <> 0 THEN 'Stock / Operational Adjustment'
				WHEN Price >0 AND Quantity > 0 THEN 'Product Sale'
				ELSE 'Review'
				END
    END AS Transaction_Type,
	Quantity * Price AS Transaction_Value,
	CAST(InvoiceDate AS DATE) AS Transaction_date
INTO dbo.Transactions
FROM dbo.All_sales;

-- ============================================
-- 2. VALIDATE TRANSACTION CLASSIFICATION
-- ============================================
-- Verify transaction distribution, quantities, and monetary

SELECT Transaction_Type,
	COUNT (*) AS Total_Rows,
	SUM (Quantity) AS Total_Quantity,
	SUM (Transaction_Value) AS Total_Value
FROM dbo.Transactions
GROUP BY Transaction_Type
ORDER BY Total_Rows DESC;

SELECT
    Transaction_Type,
    COUNT(*) AS Missing_Customer_ID
FROM dbo.Transactions
WHERE Customer_ID IS NULL
GROUP BY Transaction_Type
ORDER BY Missing_Customer_ID DESC;

-- Identify missing customer references by transaction type.
-- These records are preserved for non-customer-level analysis.

SELECT COUNT (*) AS All_sales_row,
	(SELECT COUNT (*) FROM dbo.Transactions) AS Transactions_row,
	SUM (Quantity*Price) AS All_sales_Value,
	(SELECT SUM (Transaction_Value) FROM dbo.Transactions) AS Transactions_Value
FROM dbo.All_sales;

-- Confirm that transaction modelling preserves the original


-- ============================================
-- 3. VALIDATE DIMENSION KEYS
-- ============================================

SELECT Invoice,
	COUNT(DISTINCT Customer_ID) AS Unique_Customer,
	COUNT(DISTINCT Transaction_Type) AS Unique_TransactionType,
	COUNT(DISTINCT Country) AS Unique_Country,
	COUNT(DISTINCT InvoiceDate) AS Unique_Date
FROM dbo.Transactions
GROUP BY Invoice
HAVING COUNT(DISTINCT Customer_ID) > 1 OR 
		COUNT(DISTINCT Country) > 1 OR 
		COUNT(DISTINCT InvoiceDate) >1 OR 
		COUNT(DISTINCT Transaction_Type) > 1;


Select * 
FROM dbo.Transactions
WHERE Invoice IN  ( 
					SELECT Invoice 
					FROM dbo.Transactions 
					GROUP BY Invoice 
					HAVING COUNT(DISTINCT InvoiceDate) >1
					)
ORDER BY Invoice ,InvoiceDate;

-- Finding: Some invoices contain timestamps approximately one minute apart.
-- Each invoice has one customer, country, and transaction type.
-- MIN(InvoiceDate) will be used to assign one timestamp per invoice.

SELECT StockCode,
	COUNT(DISTINCT Description) AS Unique_Description
FROM dbo.Transactions
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1 
ORDER By Unique_Description DESC;

SELECT StockCode,
	Description,
	SUM (Quantity) AS Total_Q
FROM dbo.Transactions
WHERE StockCode IN (
					SELECT StockCode 
					FROM dbo.Transactions
					GROUP BY StockCode
					HAVING COUNT(DISTINCT Description) > 1 
					)
GROUP BY StockCode,Description
ORDER BY Stockcode, Total_Q DESC;

-- Finding: Some StockCodes have multiple descriptions due to
-- corrections, transaction notes, or minor naming differences.

-- ============================================
-- 4. CREATE AND VALIDATE DIMCUSTOMER
-- ============================================

DROP TABLE IF EXISTS dbo.DimCustomer;

SELECT DISTINCT Customer_ID AS Customer_ID
INTO dbo.DimCustomer
FROM dbo.Transactions
WHERE Customer_ID IS NOT NULL;

SELECT COUNT (*) AS Dim_count,
	(SELECT COUNT (DISTINCT Customer_ID) FROM dbo.Transactions) AS Transaction_Count
FROM dbo.DimCustomer;

SELECT
    Customer_ID,
    COUNT(*) AS Occurrences
FROM dbo.DimCustomer
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS Missing_Customer_ID
FROM dbo.DimCustomer
WHERE Customer_ID IS NULL;

-- ============================================
-- 5. CREATE AND VALIDATE DIMINVOICE
-- ============================================

DROP TABLE IF EXISTS dbo.DimInvoice;

SELECT Invoice AS Invoice,
	MIN(InvoiceDate) AS InvoiceDate,
	MAX (Customer_ID) AS Customer_ID,
	MIN (Country) AS Country,
	MIN (Transaction_Type) AS Invoice_Type
INTO dbo.DimInvoice
FROM dbo.Transactions
GROUP BY Invoice;

SELECT COUNT (DISTINCT Invoice) AS Dim_Invoice,
	(SELECT COUNT (DISTINCT Invoice) FROM dbo.Transactions) AS Transaction_Invoice
FROM dbo.DimInvoice

SELECT
    Invoice,
    COUNT(*) AS Occurrences
FROM dbo.DimInvoice
GROUP BY Invoice
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS Missing_Invoice
FROM dbo.DimInvoice
WHERE Invoice IS NULL;

-- ============================================
-- 6. CREATE AND VALIDATE DIMPRODUCT
-- ============================================
-- Select one description per StockCode, prioritizing non-NULL
-- descriptions and excluding operational adjustments from
-- quantity-based ranking.

DROP TABLE IF EXISTS dbo.DimProduct;

WITH Stock_Desc_count AS (
	SELECT  StockCode,
			Description,
			SUM (CASE 
					WHEN Transaction_Type <> 'Stock / Operational Adjustment' THEN Quantity
					ELSE 0
				END
			) AS Total_Q,
			COUNT (*) AS Occurrences
	FROM dbo.Transactions
	GROUP BY StockCode,Description
	),
	Rank_Description AS (
		SELECT ROW_NUMBER() OVER (
			PARTITION BY StockCode
			ORDER BY 
				CASE 
					WHEN Description IS NULL OR 
						TRIM(Description) = '' 
						THEN 1
					ELSE 0
				END ASC ,
				Total_Q DESC,Occurrences DESC,
					Description ASC
			) AS Ranking,
			*
		FROM Stock_Desc_count
)

SELECT StockCode,
Description
INTO dbo.DimProduct
FROM Rank_Description
WHERE Ranking = 1;


SELECT COUNT (DISTINCT StockCode) AS Dim_Stock,
	(SELECT COUNT (DISTINCT StockCode) FROM dbo.Transactions) AS Tran_Stock
FROM dbo.DimProduct;

SELECT
    StockCode,
    COUNT(*) AS Occurrences
FROM dbo.DimProduct
GROUP BY StockCode
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS Missing_StockCode
FROM dbo.DimProduct
WHERE StockCode IS NULL;

-- ============================================
-- 7. CREATE AND VALIDATE DIMDATE
-- ============================================

DROP TABLE IF EXISTS dbo.DimDate;

WITH DateSequence AS (
    SELECT CAST('2009-12-01' AS DATE) AS CalendarDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CalendarDate)
    FROM DateSequence
    WHERE CalendarDate < '2011-12-31'
)

SELECT *,
	YEAR (CalendarDate) AS Year_Count,
	DATEPART (QUARTER, CalendarDate) AS Quarter_Count,
	MONTH (CalendarDate) AS Month_Count,
	DATENAME (MONTH, CalendarDate) AS Month_Name,
	DATEPART(ISO_WEEK, CalendarDate) AS Week_Count,
	DATENAME (WEEKDAY, CalendarDate) AS Day_Name,
	DAY (CalendarDate) AS Day_Count,
	(YEAR (CalendarDate)*100 + MONTH (CalendarDate)) AS YearMonth
INTO  dbo.DimDate
FROM DateSequence
OPTION (MAXRECURSION 0);


SELECT
    MIN(CalendarDate) AS First_Date,
    MAX(CalendarDate) AS Last_Date,
    COUNT(*) AS Total_Days,
    DATEDIFF(DAY, MIN(CalendarDate), MAX(CalendarDate)) + 1 AS Expected_Days
FROM dbo.DimDate;

SELECT
    CalendarDate,
    COUNT(*) AS Occurrences
FROM dbo.DimDate
GROUP BY CalendarDate
HAVING COUNT(*) > 1;

-- ============================================
-- 8. FINAL DATA MODEL VALIDATION
-- ============================================

SELECT SUM ( CASE
			WHEN t.Customer_ID IS NOT NULL
				AND c.Customer_ID IS NULL 
				THEN 1
			ELSE 0
			END ) AS Unmatched_Customers,
		SUM ( CASE
			WHEN t.StockCode IS NOT NULL
				AND p.StockCode IS NULL 
				THEN 1
			ELSE 0
			END ) AS Unmatched_Product,
		SUM ( CASE
			WHEN t.Invoice IS NOT NULL
				AND i.Invoice IS NULL 
				THEN 1
			ELSE 0
			END ) AS Unmatched_Invoice,
		SUM ( CASE
			WHEN t.Transaction_date IS NOT NULL
				AND d.CalendarDate IS NULL 
				THEN 1
			ELSE 0
			END ) AS Unmatched_Date
FROM dbo.Transactions AS t
LEFT JOIN dbo.DimCustomer AS c
    ON t.Customer_ID = c.Customer_ID
LEFT JOIN dbo.DimProduct AS p
    ON t.StockCode = p.StockCode
LEFT JOIN dbo.DimInvoice AS i
    ON t.Invoice = i.Invoice
LEFT JOIN dbo.DimDate AS d
    ON t.Transaction_date = d.CalendarDate


SELECT
    COUNT(*) AS Total_Rows_After,
	(SELECT COUNT (*) FROM dbo.Transactions) AS Total_Rows_Before,
    SUM(t.Transaction_Value) AS Total_Value_After_Joins,
	(SELECT SUM (Transaction_Value) FROM dbo.Transactions) AS Total_Value_Before
FROM dbo.Transactions AS t
LEFT JOIN dbo.DimCustomer AS c
    ON t.Customer_ID = c.Customer_ID
LEFT JOIN dbo.DimProduct AS p
    ON t.StockCode = p.StockCode
LEFT JOIN dbo.DimInvoice AS i
    ON t.Invoice = i.Invoice
LEFT JOIN dbo.DimDate AS d
    ON t.Transaction_date = d.CalendarDate;


-- Final validation: All dimension keys are unique,
-- non-NULL transaction keys match their dimensions,
-- and JOINs preserve transaction counts and total values.
-- The analytical model is ready for KPI development.