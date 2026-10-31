-- ============================================
-- 1. NEGATIVE / ZERO QUANTITIES
-- ============================================

SELECT *
FROM dbo.All_sales
WHERE Quantity <= 0 
    AND Description IS NULL
ORDER BY Quantity DESC;

SELECT COUNT(*)
FROM dbo.All_sales
WHERE Quantity <= 0 
    AND Description IS NULL

-- ============================================
-- 2. MISSING CUSTOMER IDS
-- ============================================

SELECT *
FROM dbo.All_sales
WHERE Customer_ID IS NULL 
    AND Description IS NOT NULL
ORDER BY Quantity DESC;

-- ============================================
-- 3. NEGATIVE QUANTITY BY DESCRIPTION
-- ============================================

SELECT
    Description,
    COUNT(*) AS Number_of_Rows,
    SUM(Quantity) AS Total_Quantity,
    AVG(Price) AS Avg_Price
FROM dbo.All_sales
WHERE Quantity < 0
GROUP BY Description
ORDER BY Number_of_Rows DESC;

-- ============================================
-- 4. NEGATIVE / ZERO-VALUE UNIDENTIFIED RECORDS
-- ============================================

SELECT
    COUNT(*) AS Rows,
    SUM(Quantity) AS Quantity
FROM dbo.All_sales
WHERE Quantity <= 0
  AND Description IS NULL
  AND Customer_ID IS NULL
  AND Price = 0;

/*
These rows appear to be non-commercial adjustment records.
Further investigation of invoice patterns will be performed
before excluding them from analytical datasets.
*/

-- ============================================
-- 5. POSITIVE QUANTITY / ZERO-VALUE RECORDS
-- ============================================

SELECT
    COUNT(*) AS Rows,
    SUM(Quantity) AS Quantity
FROM dbo.All_sales
WHERE Quantity > 0
  AND Description IS NULL
  AND Customer_ID IS NULL
  AND Price = 0;

  -- ============================================
-- 6. Invoice code partern
-- ============================================

SELECT 
    LEFT (Invoice , 1)AS Invoice_Prefix,
    Count(DISTINCT Invoice) AS Total_Invoice,
    SUM (Quantity) As Total_Quantity,
    SUM(Price * Quantity) AS Total_Value
FROM dbo.All_sales
GROUP BY LEFT (Invoice , 1)
ORDER BY Total_Quantity ASC;

SELECT *
FROM dbo.All_sales
WHERE LEFT (Invoice , 1) = 'A';
 -- invoices starting with A are accounting adjustments, not normal product sales. 
  
-- ============================================
-- 7. StockCode Investigation
-- ============================================

SELECT StockCode,
    Description,
    Count(StockCode) AS Total_Rows,
    SUM (Quantity) As Total_Quantity,
    SUM(Price * Quantity) AS Total_Value
FROM dbo.All_sales
WHERE LEFT (Invoice , 1) = 'C' AND
    StockCode LIKE '[A-Za-z]%'
GROUP BY StockCode , Description
ORDER BY StockCode DESC;

/*C invoices with standard product StockCodes are consistent with cancellation/reversal transactions. 
Letter-based StockCodes frequently represent non-product items such as fees, postage, discounts, commissions, and manual adjustments.*/

-- ============================================
-- 8. Negative Non-Cancellation Transactions
-- ============================================

SELECT 
    SUM( CASE 
        WHEN LEFT (Invoice , 1) <> 'C'  AND Quantity < 0 AND Price = 0 THEN 1
        ELSE 0
        END) AS Rows_NegQ_NoPr,
    SUM( CASE 
        WHEN LEFT (Invoice , 1) <> 'C' AND Quantity < 0 AND Price <> 0 THEN 1
        ELSE 0
        END) AS Rows_NegQ_WithPr,
    SUM( CASE 
        WHEN LEFT (Invoice , 1) <> 'C' AND Quantity = 0 AND Price = 0 THEN 1
        ELSE 0
        END) AS Rows_0Q_NoPr,
    SUM( CASE 
        WHEN LEFT (Invoice , 1) <> 'C' AND Quantity = 0 AND Price <> 0 THEN 1
        ELSE 0
        END) AS Rows_0Q_WithPr
FROM dbo.All_sales;

SELECT *
FROM dbo.All_sales
WHERE LEFT (Invoice , 1) <> 'C'  AND Quantity < 0 AND Price = 0
ORDER BY Description DESC;

-- Based on descriptions seems like negative quantity 0 price is for stock correction,stock damaged,correct invoice, miss match invoice

-- ============================================
-- 9. Cancellation Investigation
-- ============================================

SELECT cancellations.Invoice,
    SUBSTRING(cancellations.Invoice,2,7) AS Potential_Original_Invoice,
    adjustments.Invoice,
    adjustments.Description,
    adjustments.Customer_ID,
    adjustments.StockCode
FROM dbo.All_sales AS cancellations
LEFT JOIN dbo.All_sales AS adjustments ON SUBSTRING(cancellations.Invoice,2,7) = adjustments.Invoice
WHERE LEFT (cancellations.Invoice , 1) = 'C' AND adjustments.Invoice IS NOT NULL

/* C invoices are primarily associated with cancellation/reversal transactions. 
Some C records also contain special StockCodes representing fees, adjustments, postage, or other non-product activity.*/

-- ============================================
-- 10. Duplicate Investigation
-- ============================================

SELECT cancellations.Invoice,
    cancellations.Quantity,
    cancellations.Customer_ID,
    cancellations.StockCode,
    adjustments.Invoice,
    adjustments.Quantity,
    adjustments.Description,
    adjustments.Customer_ID,
    adjustments.StockCode
FROM dbo.All_sales AS cancellations
LEFT JOIN dbo.All_sales AS adjustments ON cancellations.Customer_ID = adjustments.Customer_ID AND cancellations.StockCode = adjustments.StockCode
WHERE LEFT (cancellations.Invoice , 1) = 'C' AND adjustments.Invoice IS NOT NULL AND LEFT (adjustments.Invoice , 1) <> 'C';

-- Invoices with C are reflected to cancelations, damages or expences

SELECT Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    COUNT(*) AS Occurrences,
    CASE 
        WHEN InvoiceDate >= '2010-12-01' AND InvoiceDate < '2010-12-10' THEN 'Overlap Period'
        ELSE 'Outside Overlap'
        END AS Overlap_Statues
FROM dbo.All_sales
GROUP BY Invoice, StockCode, Description,Quantity,InvoiceDate,Price,Customer_ID,Country
HAVING COUNT(*) > 1
ORDER By Occurrences DESC
