-- =========================================================
-- REBUILD PURCHASE_PRICES TABLE
-- =========================================================

-- 1. Delete the incorrectly structured table
DROP TABLE IF EXISTS procurement.purchase_prices;


-- 2. Create the table with the correct column meanings
CREATE TABLE procurement.purchase_prices (
    brand INT,
    description TEXT,
    price NUMERIC(12,2),
    size VARCHAR(20),
    volume NUMERIC(12,2),
    classification INT,
    purchase_price NUMERIC(12,2),
    vendor_number INT,
    vendor_name TEXT
);


-- 3. Insert data from the raw table
INSERT INTO procurement.purchase_prices (
    brand,
    description,
    price,
    size,
    volume,
    classification,
    purchase_price,
    vendor_number,
    vendor_name
)
SELECT
    NULLIF(brand, '')::INT,
    description,
    NULLIF(NULLIF(size, 'Unknown'), '')::NUMERIC(12,2),
    volume,
    NULLIF(NULLIF(price, 'Unknown'), '')::NUMERIC(12,2),
    NULLIF(classification, '')::INT,
    NULLIF(purchase_price, '')::NUMERIC(12,2),
    NULLIF(vendor_number, '')::INT,
    vendor_name
FROM procurement.purchase_prices_raw;


-- 4. Check number of rows
SELECT COUNT(*) AS number_of_rows
FROM procurement.purchase_prices;

-- 5. Check the corrected data
SELECT
    brand,
    description,
    price,
    size,
    volume,
    purchase_price
FROM procurement.purchase_prices
LIMIT 10;