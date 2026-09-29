CREATE SCHEMA procurement;

CREATE TABLE procurement.purchases (
    inventory_id VARCHAR(100),
    store INT,
    brand INT,
    description TEXT,
    size VARCHAR(20),
    vendor_number INT,
    vendor_name TEXT,
    po_number INT,
    po_date DATE,
    receiving_date DATE,
    invoice_date DATE,
    pay_date DATE,
    purchase_price NUMERIC(12,2),
    quantity INT,
    dollars NUMERIC(14,2),
    classification INT
);

ALTER TABLE procurement.purchases
ALTER COLUMN size TYPE VARCHAR(20);