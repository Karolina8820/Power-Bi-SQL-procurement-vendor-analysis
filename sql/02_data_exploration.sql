SELECT COUNT(*) AS number_of_rows
FROM procurement.purchases;


SELECT COUNT(DISTINCT vendor_number) AS number_of_vendors
FROM procurement.purchases;