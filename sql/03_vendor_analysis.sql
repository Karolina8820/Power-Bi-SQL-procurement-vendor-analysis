-- =========================================================
-- 03. VENDOR ANALYSIS
-- =========================================================


-- A. Top 10 vendors by number of purchase records

SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchases
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name
ORDER BY number_of_purchases DESC
LIMIT 10;


-- B. Top 10 vendors by total procurement spend

SELECT
    vendor_number,
    vendor_name,
    SUM(dollars) AS total_spend
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name
ORDER BY total_spend DESC
LIMIT 10;


-- C. Top 10 vendors by average purchase value

SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchases,
    SUM(dollars) AS total_spend,
    ROUND(AVG(dollars), 2) AS avg_purchase_value
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name
ORDER BY avg_purchase_value DESC
LIMIT 10;