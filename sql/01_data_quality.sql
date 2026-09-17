-- Mengubah tipe data pada beberapa kolom di tabel orders menjadi Timestamp
ALTER TABLE orders
    ALTER COLUMN order_purchase_timestamp
        TYPE TIMESTAMP
        USING NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP,
    ALTER COLUMN order_approved_at
        TYPE TIMESTAMP
        USING NULLIF(TRIM(order_approved_at), '')::TIMESTAMP,
    ALTER COLUMN order_delivered_carrier_date
        TYPE TIMESTAMP
        USING NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP,
    ALTER COLUMN order_delivered_customer_date
        TYPE TIMESTAMP
        USING NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP,
    ALTER COLUMN order_estimated_delivery_date
        TYPE TIMESTAMP
        USING NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP;

-- Check duplicate order
SELECT
    order_id,
    COUNT(*) AS total
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check NULL
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_delivered_customer_date) AS delivered_orders
FROM orders

-- Data Cleaning Order
CREATE VIEW vw_orders_clean AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN 'Not Delivered'
        WHEN order_delivered_customer_date
             <= order_estimated_delivery_date
            THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN EXTRACT(
            EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)
        	) / 86400
    END AS delivery_days
FROM orders;

-- check view orders clean
SELECT * FROM vw_orders_clean;


-- Data Cleaning Product Category
CREATE VIEW vw_products_clean AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name
       = t.product_category_name;

-- Check view product clean
SELECT * FROM vw_products_clean;

-- Testing total customer

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers c
    JOIN public.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,
    ROUND(
        COUNT(*) FILTER (WHERE total_orders > 1) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM customer_orders;