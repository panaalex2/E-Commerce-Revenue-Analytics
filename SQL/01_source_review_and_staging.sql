-- ============================================
-- 1. INITIAL SOURCE REVIEW
-- ============================================

SELECT TOP 10 *
FROM dbo.[online_retail_2009-2010];

SELECT COUNT(*) AS row_count_2009_2010
FROM dbo.[online_retail_2009-2010];

SELECT MIN( InvoiceDate) AS First_Order,
	MAX (InvoiceDate) AS Last_Order
FROM dbo.[online_retail_2009-2010];

SELECT TOP 10 *
FROM dbo.[online_retail_2010-2011];

SELECT COUNT(*) AS row_count_2010_2011
FROM dbo.[online_retail_2010-2011];

SELECT MIN( InvoiceDate) AS First_Order,
	MAX (InvoiceDate) AS MLast_Order
FROM dbo.[online_retail_2010-2011];



-- ============================================
-- 2. REVIEW COLUMN STRUCTURE
-- ============================================

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_2009-2010';

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_2010-2011';

-- ============================================
-- 3. COMBINE BOTH YEARS
-- ============================================

DROP TABLE IF EXISTS dbo.All_sales;

SELECT *
INTO dbo.All_sales
FROM ( 
	SELECT * 
	FROM dbo.[online_retail_2009-2010] 
	UNION ALL
	SELECT * 
	FROM dbo.[online_retail_2010-2011] AS new
	WHERE (
		new.InvoiceDate < '2010-12-01' OR new.InvoiceDate >= '2010-12-10')
	    OR NOT EXISTS (
			SELECT 1
			FROM dbo.[online_retail_2009-2010] AS OLD 
			WHERE (old.Invoice = new.Invoice OR (old.Invoice IS NULL AND new.Invoice IS NULL)) AND   
					(old.StockCode=new.StockCode OR (old.StockCode IS NULL AND new.StockCode IS NULL)) AND 
					(old.Description=new.Description OR (old.Description IS NULL AND new.Description IS NULL)) AND
					(old.Quantity = new.Quantity OR (old.Quantity IS NULL AND new.Quantity IS NULL)) AND
					(old.InvoiceDate=new.InvoiceDate OR (old.InvoiceDate IS NULL AND new.InvoiceDate IS NULL)) AND
					(old.Price=new.Price OR (old.Price IS NULL AND new.Price IS NULL)) AND
					(old.Customer_ID=new.Customer_ID OR (old.Customer_ID IS NULL AND new.Customer_ID IS NULL)) AND
					(old.Country=new.Country OR (old.Country IS NULL AND new.Country IS NULL))
				)
	) AS all_sales;

-- The two source datasets overlap between 1–9 December 2010.
-- During this period, identical rows already present in the first
-- source are excluded to prevent cross-file duplication.

SELECT COUNT (*)
FROM dbo.All_sales;


-- ============================================
-- 4. VALIDATE QUANTITY
-- ============================================

WITH Quantity_Check AS(
	SELECT
		Quantity,
		CASE
			WHEN Quantity IS NULL THEN 'Missing'
			WHEN TRY_CAST(Quantity AS INT) IS NULL THEN 'Invalid Item'
			WHEN TRY_CAST(Quantity AS INT) < 0 THEN 'Negative'
			WHEN TRY_CAST(Quantity AS INT) = 0 THEN 'ZERO'
		END AS Quantity_Issue
	FROM dbo.All_sales)

SELECT *
FROM Quantity_Check
WHERE Quantity_Issue IS NOT NULL;

ALTER TABLE dbo.all_sales
ALTER COLUMN Quantity INT;

-- ============================================
-- 5. VALIDATE PRICE
-- ============================================

WITH Price_Check AS (
	SELECT
		Price,
		CASE
			WHEN Price IS NULL THEN 'Missing'
			WHEN TRY_CAST(Price AS DECIMAL(12,2)) IS NULL THEN 'Invalid Item'
			WHEN TRY_CAST(Price AS DECIMAL(12,2)) < 0 THEN 'Negative'
			WHEN TRY_CAST(Price AS DECIMAL(12,2)) = 0 THEN 'ZERO'	
		END AS Price_Issue
	FROM dbo.All_sales)
SELECT *
FROM Price_Check
WHERE Price_Issue IS NOT NULL;

ALTER TABLE dbo.all_sales
ALTER COLUMN Price DECIMAL(12,2);