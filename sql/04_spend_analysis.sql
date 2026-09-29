-- =========================================================
-- 04. SPEND ANALYSIS
-- =========================================================

-- Total procurement spend by year

SELECT
    EXTRACT(YEAR FROM po_date) AS year,
    SUM(dollars) AS total_spend
FROM procurement.purchases
GROUP BY
    EXTRACT(YEAR FROM po_date)
ORDER BY year;

-- B. Total procurement spend by month

SELECT
    DATE_TRUNC('month', po_date) AS purchase_month,
    SUM(dollars) AS total_spend
FROM procurement.purchases
GROUP BY
    DATE_TRUNC('month', po_date)
ORDER BY purchase_month;

-- C. Procurement spend by vendor

SELECT
    vendor_number,
    vendor_name,
    SUM(dollars) AS total_spend
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name
ORDER BY total_spend DESC;

-- D. Vendor share of total procurement spend

SELECT
    vendor_number,
    vendor_name,
    SUM(dollars) AS total_spend,
    ROUND(
        SUM(dollars) / (SELECT SUM(dollars) FROM procurement.purchases) * 100,
        2
    ) AS spend_share_pct
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name
ORDER BY total_spend DESC;

-- E. Check for vendors with multiple names

SELECT
    vendor_number,
    COUNT(DISTINCT vendor_name) AS number_of_vendor_names
FROM procurement.purchases
GROUP BY vendor_number
HAVING COUNT(DISTINCT vendor_name) > 1
ORDER BY number_of_vendor_names DESC;
-- F. Vendor names with duplicated vendor numbers

SELECT DISTINCT
    vendor_number,
    vendor_name
FROM procurement.purchases
WHERE vendor_number IN (1587, 2000, 4425)
ORDER BY
    vendor_number,
    vendor_name;
	-- G. Spend concentration - Top 5 vendors

SELECT
    SUM(total_spend) AS top_5_spend,
    ROUND(
        SUM(total_spend) /
        (SELECT SUM(dollars) FROM procurement.purchases) * 100,
        2
    ) AS top_5_share_pct
FROM (
    SELECT
        vendor_number,
        SUM(dollars) AS total_spend
    FROM procurement.purchases
    GROUP BY vendor_number
    ORDER BY total_spend DESC
    LIMIT 5
) AS top_vendors;

-- H. Spend concentration - Top 10 vendors

SELECT
    SUM(total_spend) AS top_10_spend,
    ROUND(
        SUM(total_spend) /
        (SELECT SUM(dollars) FROM procurement.purchases) * 100,
        2
    ) AS top_10_share_pct
FROM (
    SELECT
        vendor_number,
        SUM(dollars) AS total_spend
    FROM procurement.purchases
    GROUP BY vendor_number
    ORDER BY total_spend DESC
    LIMIT 10
) AS top_vendors;

