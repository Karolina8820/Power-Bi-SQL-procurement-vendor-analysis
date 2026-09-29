-- =========================================================
-- 08. VIEWS FOR POWER BI
-- =========================================================


-- A. Vendor Performance
-- Procurement spend and purchasing activity by vendor

CREATE OR REPLACE VIEW procurement.vw_vendor_performance AS
SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchase_records,
    COUNT(DISTINCT po_number) AS number_of_orders,
    SUM(quantity) AS total_quantity,
    SUM(dollars) AS total_spend,
    ROUND(AVG(dollars), 2) AS avg_purchase_value
FROM procurement.purchases
GROUP BY
    vendor_number,
    vendor_name;


-- B. Inventory & Replenishment
-- Current inventory, weekly demand and recommended order quantity

CREATE OR REPLACE VIEW procurement.vw_inventory_replenishment AS

WITH weekly_sales AS (
    SELECT
        DATE_TRUNC('week', sales_date) AS sales_week,
        inventory_id,
        store,
        brand,
        description,
        SUM(sales_quantity) AS weekly_sales
    FROM procurement.sales
    WHERE sales_date IS NOT NULL
    GROUP BY
        DATE_TRUNC('week', sales_date),
        inventory_id,
        store,
        brand,
        description
),

product_period AS (
    SELECT
        inventory_id,
        store,
        brand,
        description,
        MIN(sales_week) AS first_week,
        MAX(sales_week) AS last_week
    FROM weekly_sales
    GROUP BY
        inventory_id,
        store,
        brand,
        description
),

all_weeks AS (
    SELECT
        p.inventory_id,
        p.store,
        p.brand,
        p.description,
        generate_series(
            p.first_week,
            p.last_week,
            INTERVAL '1 week'
        ) AS sales_week
    FROM product_period p
),

complete_weekly_sales AS (
    SELECT
        a.inventory_id,
        a.store,
        a.brand,
        a.description,
        a.sales_week,
        COALESCE(w.weekly_sales, 0) AS weekly_sales
    FROM all_weeks a
    LEFT JOIN weekly_sales w
        ON a.inventory_id = w.inventory_id
        AND a.store = w.store
        AND a.sales_week = w.sales_week
),

avg_sales AS (
    SELECT
        inventory_id,
        store,
        brand,
        description,
        ROUND(AVG(weekly_sales), 2) AS avg_weekly_sales
    FROM complete_weekly_sales
    GROUP BY
        inventory_id,
        store,
        brand,
        description
)

SELECT
    e.inventory_id,
    e.store,
    e.brand,
    e.description,
    e.on_hand AS current_inventory,
    a.avg_weekly_sales,

    ROUND(
        a.avg_weekly_sales * 4,
        0
    ) AS target_stock_4_weeks,

    GREATEST(
        ROUND(
            a.avg_weekly_sales * 4 - e.on_hand,
            0
        ),
        0
    ) AS recommended_order_qty,

    ROUND(
        e.on_hand::NUMERIC /
        NULLIF(a.avg_weekly_sales, 0),
        2
    ) AS weeks_of_stock

FROM procurement.end_inventory e

INNER JOIN avg_sales a
    ON e.inventory_id = a.inventory_id
    AND e.store = a.store

WHERE a.avg_weekly_sales > 0;


-- C. Monthly Spend
-- Monthly procurement spend and quantity
DROP VIEW IF EXISTS procurement.vw_monthly_spend;

CREATE OR REPLACE VIEW procurement.vw_monthly_spend AS
SELECT
    DATE_TRUNC('month', po_date) AS purchase_month,
    SUM(quantity) AS purchased_quantity,
    SUM(dollars) AS total_spend,
    COUNT(DISTINCT po_number) AS number_of_orders,
    COUNT(DISTINCT vendor_number) AS number_of_vendors
FROM procurement.purchases
WHERE po_date IS NOT NULL
GROUP BY
    DATE_TRUNC('month', po_date)
ORDER BY
    purchase_month;

	-- =========================================================
-- D. Vendor Performance
-- =========================================================


CREATE OR REPLACE VIEW procurement.vw_vendor_performance AS
SELECT
    vendor_number,
    vendor_name,

    COUNT(*) AS number_of_purchase_records,

    COUNT(DISTINCT po_number) AS number_of_orders,

    ROUND(SUM(dollars), 2) AS total_spend,

    ROUND(AVG(dollars), 2) AS avg_purchase_value,

    ROUND(
        AVG(receiving_date - po_date),
        2
    ) AS avg_receiving_days,

    ROUND(
        AVG(invoice_date - receiving_date),
        2
    ) AS avg_invoice_processing_days,

    ROUND(
        AVG(pay_date - invoice_date),
        2
    ) AS avg_payment_days

FROM procurement.purchases

WHERE
    po_date IS NOT NULL
    AND receiving_date IS NOT NULL
    AND invoice_date IS NOT NULL
    AND pay_date IS NOT NULL

GROUP BY
    vendor_number,
    vendor_name;

	-- =========================================================
-- E. Replenishment / Recommended Order Quantity
-- =========================================================
-- Target stock = 4 weeks of average sales
-- Recommended order quantity = target stock - current inventory

CREATE OR REPLACE VIEW procurement.vw_replenishment AS

WITH avg_sales AS (

    SELECT
        inventory_id,
        store,
        brand,
        description,
        AVG(weekly_sales) AS avg_weekly_sales

    FROM (

        SELECT
            DATE_TRUNC('week', sales_date) AS sales_week,
            inventory_id,
            store,
            brand,
            description,
            SUM(sales_quantity) AS weekly_sales

        FROM procurement.sales

        WHERE sales_date IS NOT NULL

        GROUP BY
            DATE_TRUNC('week', sales_date),
            inventory_id,
            store,
            brand,
            description

    ) weekly_sales

    GROUP BY
        inventory_id,
        store,
        brand,
        description
)

SELECT
    e.inventory_id,
    e.store,
    e.brand,
    e.description,

    e.on_hand AS current_inventory,

    ROUND(
        a.avg_weekly_sales,
        2
    ) AS avg_weekly_sales,

    ROUND(
        a.avg_weekly_sales * 4,
        0
    ) AS target_stock_4_weeks,

    GREATEST(
        ROUND(a.avg_weekly_sales * 4, 0) - e.on_hand,
        0
    ) AS recommended_order_qty,

    ROUND(
        e.on_hand::NUMERIC /
        NULLIF(a.avg_weekly_sales, 0),
        2
    ) AS weeks_of_stock

FROM procurement.end_inventory e

INNER JOIN avg_sales a
    ON e.inventory_id = a.inventory_id
    AND e.store = a.store

WHERE a.avg_weekly_sales > 0;