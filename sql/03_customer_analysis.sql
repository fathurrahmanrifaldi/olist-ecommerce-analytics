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