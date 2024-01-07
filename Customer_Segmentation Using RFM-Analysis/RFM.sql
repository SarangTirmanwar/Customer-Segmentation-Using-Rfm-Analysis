-- Explore the US regional sales data
SELECT TOP 10 * FROM US_Regional_Sales_Data..['Sales Orders Data']

-- Determine the date range for the order data
SELECT
    MAX(OrderDate) AS MAX,
    MIN(OrderDate) AS MIN
FROM US_Regional_Sales_Data..['Sales Orders Data']

-- The data spans from May 2018 to Dec 2020

-- Define today's date for accurate calculations
DECLARE @today_date AS DATE = '2021-01-31';

-- Calculate RFM metrics
SELECT
    _CustomerID AS CustomerID,
    DATEDIFF(day, MAX(OrderDate), @today_date) AS Recency,
    COUNT(OrderNumber) AS Frequency,
    SUM([Unit Price] - ([Unit Price] * [Discount Applied] - [Unit Cost])) AS Monetary_Value
FROM US_Regional_Sales_Data..['Sales Orders Data']
GROUP BY _CustomerID

-- Analyze the distribution of RFM Values using a Five-Number Summary

-- Calculate RFM Values
DECLARE @today_date AS DATE = '2022-03-03';
WITH RFM_CALC AS (
    SELECT
        _CustomerID AS CustomerID,
        DATEDIFF(day, MAX(OrderDate), @today_date) AS Recency,
        COUNT(OrderNumber) AS Frequency,
        CAST(SUM([Unit Price] - ([Unit Price] * [Discount Applied] - [Unit Cost])) AS DECIMAL(16,2)) AS Monetary_Value
    FROM US_Regional_Sales_Data..['Sales Orders Data']
    GROUP BY _CustomerID
),
-- Determine Minimum and Maximum Values
MinMax AS (
    SELECT
        MIN(Recency) AS Rmin,
        MAX(Recency) AS Rmax,
        MIN(Frequency) AS Fmin,
        MAX(Frequency) AS Fmax,
        MIN(Monetary_Value) AS Mmin,
        MAX(Monetary_Value) AS Mmax
    FROM RFM_CALC
)
-- Five-Number Summary for Monetary Value
SELECT DISTINCT
    'Monetary Value' AS RFM,
    M.Mmin AS Min,
    PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Monetary_Value) OVER () AS Q1,
    PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Monetary_Value) OVER () AS Median,
    PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Monetary_Value) OVER () AS Q3,
    M.Mmax AS Max
FROM MinMax M JOIN RFM_CALC ON 1=1
UNION
-- Five-Number Summary for Frequency
SELECT DISTINCT
    'Frequency' AS RFM,
    F.Fmin AS Min,
    PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Frequency) OVER () AS Q1,
    PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Frequency) OVER () AS Median,
    PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Frequency) OVER () AS Q3,
    F.Fmax AS Max
FROM MinMax F JOIN RFM_CALC ON 1=1
UNION
-- Five-Number Summary for Recency
SELECT DISTINCT
    'Recency' AS RFM,
    R.Rmin AS Min,
    PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY Recency) OVER () AS Q1,
    PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY Recency) OVER () AS Median,
    PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY Recency) OVER () AS Q3,
    R.Rmax AS MAX
FROM MinMax R JOIN RFM_CALC ON 1=1

-- Data is right-skewed

-- Partition RFM Values on a scale of 1 to 5 scores due to small ranges

-- Calculate RFM Values
DECLARE @today_date AS DATE = '2021-01-01';
WITH RFM_CALC AS (
    SELECT
        _CustomerID AS CustomerID,
        DATEDIFF(day, MAX(OrderDate), @today_date) AS Recency,
        COUNT(OrderNumber) AS Frequency,
        CAST(SUM([Unit Price] - ([Unit Price] * [Discount Applied] - [Unit Cost])) AS DECIMAL(16,2)) AS Monetary_Value
    FROM US_Regional_Sales_Data..['Sales Orders Data']
    GROUP BY _CustomerID
)
-- Calculate RMF Scores
SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary_Value,
    NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_Score,
    NTILE(5) OVER (ORDER BY Frequency ASC) AS Frequency_Score,
    NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS Monetary_Score
FROM
    RFM_CALC
ORDER BY
    CustomerID

-- Store the above result as a temporary table for further analytics

-- Calculate RFM Values
WITH RFM_CALC AS (
    SELECT
        _CustomerID AS CustomerID,
        DATEDIFF(day, MAX(OrderDate), '2021-01-01') AS Recency,
        COUNT(OrderNumber) AS Frequency,
        CAST(SUM([Unit Price] - ([Unit Price] * [Discount Applied] - [Unit Cost])) AS DECIMAL(16,2)) AS Monetary_Value
    FROM US_Regional_Sales_Data..['Sales Orders Data']
    GROUP BY _CustomerID
)
-- Calculate RMF Scores
SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary_Value,
    NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_Score,
    NTILE(5) OVER (ORDER BY Frequency ASC) AS Frequency_Score,
    NTILE(5) OVER (ORDER BY Monetary_Value ASC) AS Monetary_Score
INTO #RFM_Value_Score
FROM
    RFM_CALC

-- Check the Ranges of RFM by Scores using the temp table created above

WITH Recency_Range AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY Recency_Score) AS I,
        Recency_Score,
        MIN(Recency) AS Rmin,
        MAX(Recency) AS Rmax
    FROM #RFM_Value_Score
    GROUP BY Recency_Score
