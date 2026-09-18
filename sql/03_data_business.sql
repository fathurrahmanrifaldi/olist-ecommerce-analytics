-- 01 SALES ANALYSIS
-- Revenue
SELECT
    SUM(price) AS total_revenue
FROM order_items;

-- Total Orders
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- Monthly Revenue
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
	SUM(oi.price) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;

-- Average Order Value
WITH order_revenue AS (
    SELECT
        order_id,
        SUM(price) AS revenue       
    FROM order_items
    GROUP BY order_id )
SELECT
    AVG(revenue) AS average_order_value
FROM order_revenue;

-- Product Analysis (TOP Category)
SELECT
    t.product_category_name_english AS category,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM order_items oi
	JOIN products p
    	ON oi.product_id = p.product_id
	LEFT JOIN product_category_name_translation t
    	ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY revenue DESC;

-- TOP Sellers
SELECT
    seller_id,
    SUM(price) AS revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM order_items

GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;


-- 02 CUSTOMER ANALYSIS
-- Gabungkan customer dan order
SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id)
        AS total_orders

FROM customers c

JOIN orders o
    ON c.customer_id = o.customer_id

GROUP BY
    c.customer_unique_id;

-- Klasifikasi
CASE

    WHEN COUNT(DISTINCT o.order_id) = 1
        THEN 'One-Time Customer'

    ELSE 'Repeat Customer'

END AS customer_type


-- Repeat Customer Rate
WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id)
            AS total_orders

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    GROUP BY c.customer_unique_id
)

SELECT

    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE total_orders > 1
        )
        / COUNT(*),
        2
    ) AS repeat_customer_rate

FROM customer_orders;

-- Customer Frequency
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
    CASE
        WHEN total_orders = 1 THEN '1 Order'
        WHEN total_orders = 2 THEN '2 Orders'
        WHEN total_orders >= 3 THEN '3+ Orders'
    END AS order_frequency,
    COUNT(*) AS total_customers
FROM customer_orders
GROUP BY
    CASE
        WHEN total_orders = 1 THEN '1 Order'
        WHEN total_orders = 2 THEN '2 Orders'
        WHEN total_orders >= 3 THEN '3+ Orders'
    END
ORDER BY
    CASE
        WHEN
            CASE
                WHEN total_orders = 1 THEN '1 Order'
                WHEN total_orders = 2 THEN '2 Orders'
                WHEN total_orders >= 3 THEN '3+ Orders'
            END = '1 Order'
        THEN 1
        WHEN
            CASE
                WHEN total_orders = 1 THEN '1 Order'
                WHEN total_orders = 2 THEN '2 Orders'
                WHEN total_orders >= 3 THEN '3+ Orders'
            END = '2 Orders'
        THEN 2
        ELSE 3
    END;

-- One Time vs Repeat Customer
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM public.customers c
    JOIN public.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),

customer_type AS (
    SELECT
        customer_unique_id,
        total_orders,
        CASE
            WHEN total_orders = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS customer_type
    FROM customer_orders
),

customer_revenue AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS revenue
    FROM public.customers c
    JOIN public.orders o
        ON c.customer_id = o.customer_id
    JOIN public.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),

combined AS (
    SELECT
        ct.customer_unique_id,
        ct.customer_type,
        ct.total_orders,
        COALESCE(cr.revenue, 0) AS revenue
    FROM customer_type ct
    LEFT JOIN customer_revenue cr
        ON ct.customer_unique_id = cr.customer_unique_id
)

SELECT
    customer_type,
    COUNT(*) AS total_customers,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(revenue)::NUMERIC, 2)  AS total_revenue,
    ROUND(
        COUNT(*)::NUMERIC * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(
        SUM(revenue)::NUMERIC * 100.0 /
        SUM(SUM(revenue)::NUMERIC) OVER (),
        2
    )::NUMERIC AS revenue_percentage,
    ROUND(
        SUM(revenue)::NUMERIC /
        NULLIF(COUNT(*), 0),
        2
    ) AS revenue_per_customer
FROM combined
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- 03 DELIVERY ANALYSIS
-- Average Delivery Time
SELECT
    AVG(delivery_days)
        AS avg_delivery_days

FROM vw_orders_clean

WHERE delivery_status <> 'Not Delivered';

-- Late Delivery Rate
SELECT

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_status IN
        ('Late', 'On Time')
    ) AS delivered_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE delivery_status
                IN ('Late', 'On Time')
            ),
            0
        ),
        2
    ) AS late_rate

FROM vw_orders_clean;

-- Test Delivery Performance
SELECT
    delivery_status,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0 /
        SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS percentage
FROM vw_orders_clean
GROUP BY delivery_status
ORDER BY total_orders DESC;

-- late delivery rate
SELECT
    ROUND(
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        ) * 100.0 /
        NULLIF(
            COUNT(*) FILTER (
                WHERE delivery_status IN ('Late', 'On Time')
            ),
            0
        ),
        2
    ) AS late_delivery_rate
FROM vw_orders_clean;

-- Delivery vs Customer Satisfaction 
WITH order_review AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)

SELECT
    o.delivery_status,
    COUNT(DISTINCT o.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM vw_orders_clean o
JOIN order_review r
    ON o.order_id = r.order_id
WHERE o.delivery_status IN ('On Time', 'Late')
GROUP BY o.delivery_status
ORDER BY o.delivery_status;

-- Hitung selisih review score
WITH order_review AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
),
delivery_review AS (
    SELECT
        o.delivery_status,
        AVG(r.review_score) AS avg_review_score
    FROM vw_orders_clean o
    JOIN order_review r
        ON o.order_id = r.order_id
    WHERE o.delivery_status IN ('On Time', 'Late')
    GROUP BY o.delivery_status
)
SELECT
    ROUND(
        MAX(avg_review_score) - MIN(avg_review_score),
        2
    ) AS review_score_difference
FROM delivery_review;

-- Review Scroe Distribution
WITH order_review AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)

SELECT
    ROUND(review_score, 0) AS review_score,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM order_review
GROUP BY ROUND(review_score, 0)
ORDER BY review_score;

-- Graphic Delivery Performance
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

-- Cari Area dengan volume + Late Rate Tinggi
WITH state_delivery AS (
    SELECT
        c.customer_state,

        COUNT(DISTINCT o.order_id)
            FILTER (
                WHERE o.delivery_status IN ('Late', 'On Time')
            ) AS delivered_orders,

        COUNT(DISTINCT o.order_id)
            FILTER (
                WHERE o.delivery_status = 'Late'
            ) AS late_orders

    FROM vw_orders_clean o
    JOIN customers c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_state
)

SELECT
    customer_state,
    delivered_orders,
    late_orders,
    ROUND(
        late_orders * 100.0 /
        NULLIF(delivered_orders, 0),
        2
    ) AS late_delivery_rate
FROM state_delivery
WHERE delivered_orders >= 1000
ORDER BY late_delivery_rate DESC;

-- 04 CUSTOMER SATISFACTION
-- Customer Satisfaction
SELECT

    o.delivery_status,

    AVG(r.review_score)
        AS average_review_score,

    COUNT(DISTINCT o.order_id)
        AS orders

FROM vw_orders_clean o

JOIN order_reviews r
    ON o.order_id = r.order_id

WHERE
    o.delivery_status
    IN ('Late', 'On Time')

GROUP BY
    o.delivery_status;