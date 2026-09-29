SELECT COUNT(*) AS number_of_rows
FROM procurement.sales;
SELECT *
FROM procurement.sales
LIMIT 10;

-- I. Weekly sales quantity by product and store

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
ORDER BY
    sales_week,
    weekly_sales DESC;

-- J. Average weekly sales including weeks with zero sales

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
        AND a.sales_week = w.sales_week
)

SELECT
    inventory_id,
    store,
    brand,
    description,
    COUNT(*) AS number_of_weeks,
    ROUND(AVG(weekly_sales), 2) AS avg_weekly_sales,
    MIN(weekly_sales) AS min_weekly_sales,
    MAX(weekly_sales) AS max_weekly_sales
FROM complete_weekly_sales
GROUP BY
    inventory_id,
    store,
    brand,
    description
HAVING COUNT(*) >= 4
ORDER BY avg_weekly_sales DESC
LIMIT 20;

-- K. Inventory coverage based on average weekly sales

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
        e.on_hand::NUMERIC /
        NULLIF(a.avg_weekly_sales, 0),
        2
    ) AS weeks_of_stock
FROM procurement.end_inventory e
INNER JOIN avg_sales a
    ON e.inventory_id = a.inventory_id
    AND e.store = a.store
ORDER BY weeks_of_stock ASC
LIMIT 20;
-- L. Recommended order quantity based on 4 weeks of demand

WITH avg_sales AS (
    SELECT
        inventory_id,
        store,
        brand,
        description,
        ROUND(AVG(weekly_sales), 2) AS avg_weekly_sales
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
    ) AS recommended_order_qty

FROM procurement.end_inventory e

INNER JOIN avg_sales a
    ON e.inventory_id = a.inventory_id
    AND e.store = a.store

WHERE a.avg_weekly_sales > 0

ORDER BY recommended_order_qty DESC

LIMIT 20;