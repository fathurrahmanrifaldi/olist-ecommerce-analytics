-- Timestamp Cleaning
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

-- Delivery Status
SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id)
        FILTER (
            WHERE o.delivery_status IN ('Late', 'On Time')
        ) AS delivered_orders,

    COUNT(DISTINCT o.order_id)
        FILTER (
            WHERE o.delivery_status = 'Late'
        ) AS late_orders,

    ROUND(
        COUNT(DISTINCT o.order_id)
            FILTER (WHERE o.delivery_status = 'Late')
        * 100.0 /
        NULLIF(
            COUNT(DISTINCT o.order_id)
                FILTER (
                    WHERE o.delivery_status IN ('Late', 'On Time')
                ),
            0
        ),
        2
    ) AS late_delivery_rate

FROM vw_orders_clean o
JOIN customers c
    ON o.customer_id = c.customer_id

GROUP BY c.customer_state
ORDER BY late_delivery_rate DESC;

-- Category name validation
SELECT
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS null_category,

    COUNT(*) FILTER (
        WHERE product_category_name = ''
    ) AS empty_category,

    COUNT(*) FILTER (
        WHERE TRIM(product_category_name) = ''
    ) AS blank_after_trim,

    COUNT(*) FILTER (
        WHERE product_category_name IS NOT NULL
          AND TRIM(product_category_name) <> ''
    ) AS valid_category
FROM products;