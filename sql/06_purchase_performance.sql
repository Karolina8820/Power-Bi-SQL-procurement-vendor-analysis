-- =========================================================
-- 06. PURCHASE PERFORMANCE
-- =========================================================
-- A. Average delivery time by vendor
-- Only vendors with at least 100 purchase records

SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchase_records,
    COUNT(DISTINCT po_number) AS number_of_orders,
    ROUND(
        AVG(receiving_date - po_date),
        2
    ) AS avg_delivery_days
FROM procurement.purchases
WHERE
    po_date IS NOT NULL
    AND receiving_date IS NOT NULL
    AND receiving_date >= po_date
GROUP BY
    vendor_number,
    vendor_name
HAVING COUNT(*) >= 100
ORDER BY
    avg_delivery_days DESC;

	-- B. Average time from receiving to invoice by vendor

SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchase_records,
    COUNT(DISTINCT po_number) AS number_of_orders,
    ROUND(
        AVG(invoice_date - receiving_date),
        2
    ) AS avg_invoice_processing_days
FROM procurement.purchases
WHERE
    receiving_date IS NOT NULL
    AND invoice_date IS NOT NULL
    AND invoice_date >= receiving_date
GROUP BY
    vendor_number,
    vendor_name
HAVING COUNT(*) >= 100
ORDER BY
    avg_invoice_processing_days DESC;
	-- C. Average time from invoice to payment by vendor

SELECT
    vendor_number,
    vendor_name,
    COUNT(*) AS number_of_purchase_records,
    COUNT(DISTINCT po_number) AS number_of_orders,
    ROUND(
        AVG(pay_date - invoice_date),
        2
    ) AS avg_payment_days
FROM procurement.purchases
WHERE
    invoice_date IS NOT NULL
    AND pay_date IS NOT NULL
    AND pay_date >= invoice_date
GROUP BY
    vendor_number,
    vendor_name
HAVING COUNT(*) >= 100
ORDER BY
    avg_payment_days DESC;
	-- D. Data quality check for purchase performance

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE po_date IS NULL) AS missing_po_date,
    COUNT(*) FILTER (WHERE receiving_date IS NULL) AS missing_receiving_date,
    COUNT(*) FILTER (WHERE invoice_date IS NULL) AS missing_invoice_date,
    COUNT(*) FILTER (WHERE pay_date IS NULL) AS missing_pay_date
FROM procurement.purchases;