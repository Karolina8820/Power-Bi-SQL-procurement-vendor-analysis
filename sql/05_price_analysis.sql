-- =========================================================
-- 05. PRICE ANALYSIS
-- =========================================================


-- A. Purchase price differences for the same product across vendors

SELECT
    brand,
    description,
    COUNT(DISTINCT vendor_number) AS number_of_vendors,
    MIN(purchase_price) AS min_purchase_price,
    MAX(purchase_price) AS max_purchase_price,
    ROUND(
        MAX(purchase_price) - MIN(purchase_price),
        2
    ) AS price_difference
FROM procurement.purchases
WHERE purchase_price IS NOT NULL
GROUP BY
    brand,
    description
HAVING
    COUNT(DISTINCT vendor_number) > 1
    AND MAX(purchase_price) > MIN(purchase_price)
ORDER BY
    price_difference DESC
LIMIT 20;


-- B. Number of different purchase prices for the same product

SELECT
    brand,
    description,
    COUNT(DISTINCT purchase_price) AS number_of_prices,
    MIN(purchase_price) AS min_purchase_price,
    MAX(purchase_price) AS max_purchase_price
FROM procurement.purchases
WHERE purchase_price IS NOT NULL
GROUP BY
    brand,
    description
HAVING COUNT(DISTINCT purchase_price) > 1
ORDER BY
    number_of_prices DESC
LIMIT 20;


-- C. Compare selling price and purchase price

SELECT
    brand,
    description,
    price,
    purchase_price,
    ROUND(
        price - purchase_price,
        2
    ) AS gross_margin,
    ROUND(
        ((price - purchase_price) / NULLIF(price, 0)) * 100,
        2
    ) AS margin_pct,
    vendor_number,
    vendor_name
FROM procurement.purchase_prices
WHERE
    price IS NOT NULL
    AND purchase_price IS NOT NULL
    AND price > 0
ORDER BY margin_pct DESC
LIMIT 20;

-- D. Products with the lowest margin

SELECT
    brand,
    description,
    price,
    purchase_price,
    ROUND(
        price - purchase_price,
        2
    ) AS gross_margin,
    ROUND(
        ((price - purchase_price) / NULLIF(price, 0)) * 100,
        2
    ) AS margin_pct,
    vendor_number,
    vendor_name
FROM procurement.purchase_prices
WHERE
    price IS NOT NULL
    AND purchase_price IS NOT NULL
    AND price > 0
ORDER BY margin_pct ASC
LIMIT 20;

-- E. Most common selling price values

SELECT
    price,
    COUNT(*) AS number_of_products
FROM procurement.purchase_prices
WHERE price IS NOT NULL
GROUP BY price
ORDER BY number_of_products DESC
LIMIT 20;

--- F. Data validation - final purchase prices table

SELECT
    COUNT(*) AS number_of_rows
FROM procurement.purchase_prices;