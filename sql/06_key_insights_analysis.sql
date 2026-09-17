-- 01. Overall Business Performance
SELECT
    SUM(oi.price)::numeric AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price)::NUMERIC / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
JOIN public.customers c
    ON o.customer_id = c.customer_id;


-- 02. Revenue Trend
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC / NULLIF(COUNT(DISTINCT o.order_id), 0), 2 ) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;


-- 02B. Revenue per Bulan
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price)::NUMERIC / NULLIF(COUNT(DISTINCT o.order_id), 0),                            2    ) AS average_order_value
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;


-- 02C. Top 5 bulan
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
    SUM(oi.price) AS revenue
FROM public.orders o
JOIN public.order_items oi
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY revenue DESC
LIMIT 5;


-- 03. Product Category Performance
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    SUM(oi.price) AS revenue,

    COUNT(DISTINCT oi.order_id) AS total_orders,

    COUNT(*) AS total_items,

    ROUND(
        SUM(oi.price):: NUMERIC /
        NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS average_order_value

FROM public.order_items oi

JOIN public.products p
    ON oi.product_id = p.product_id
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name =
       t.product_category_name
GROUP BY 1
ORDER BY revenue DESC;

-- 03B.Revenue contribution category
WITH category_revenue AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS category,
        SUM(oi.price) AS revenue
    FROM public.order_items oi
    JOIN public.products p
        ON oi.product_id = p.product_id
    LEFT JOIN public.product_category_name_translation t
        ON p.product_category_name =
           t.product_category_name
    GROUP BY 1
)
SELECT
    category,
    revenue,
    ROUND(
        100.0 * revenue::NUMERIC/
        SUM(revenue) OVER ()::NUMERIC,
        2
    ) AS revenue_share_percent
FROM category_revenue
ORDER BY revenue DESC;

-- 04. Customer Type
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
        WHEN total_orders = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_share_percent

FROM customer_orders
GROUP BY 1
ORDER BY customers DESC;

-- 05. Customer Revenue Contribution
WITH customer_summary AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        SUM(oi.price) AS revenue

    FROM public.customers c

    JOIN public.orders o
        ON c.customer_id = o.customer_id

    JOIN public.order_items oi
        ON o.order_id = oi.order_id

    GROUP BY c.customer_unique_id
),

customer_type_revenue AS (
    SELECT
        CASE
            WHEN total_orders = 1
                THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type,

        COUNT(*) AS customers,

        SUM(revenue) AS revenue

    FROM customer_summary
    GROUP BY 1
)

SELECT
    customer_type,

    customers,

    ROUND(
        (
            100.0 * customers /
            SUM(customers) OVER ()
        )::numeric,
        2
    ) AS customer_share_percent,

    revenue,

    ROUND(
        (
            100.0 * revenue /
            SUM(revenue) OVER ()
        )::numeric,
        2
    ) AS revenue_share_percent,

    ROUND(
        (
            revenue /
            NULLIF(customers, 0)
        )::numeric,
        2
    ) AS revenue_per_customer

FROM customer_type_revenue
ORDER BY revenue DESC;


-- 06 Overall Delivery Performance
SELECT
    delivery_status,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(
        100.0 * COUNT(DISTINCT order_id)
        /
        SUM(COUNT(DISTINCT order_id)) OVER (),
        2
    ) AS order_share_percent

FROM public.vw_orders_clean

GROUP BY delivery_status

ORDER BY total_orders DESC;

-- 06B. Late Delivery Rate
SELECT
    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_status IN ('Late', 'On Time')
    ) AS delivered_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE delivery_status IN ('Late', 'On Time')
            ),
            0
        ),
        2
    ) AS late_delivery_rate_percent

FROM public.vw_orders_clean;


-- 07. Delivery vs Customer Satisfaction
SELECT
    o.delivery_status,

    COUNT(DISTINCT r.order_id) AS total_orders,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score

FROM public.vw_orders_clean o

JOIN public.order_reviews r
    ON o.order_id = r.order_id

WHERE o.delivery_status IN ('Late', 'On Time')

GROUP BY o.delivery_status

ORDER BY average_review_score DESC;

-- 07B. Review Score Difference
WITH delivery_review AS (
    SELECT
        o.delivery_status,
        AVG(r.review_score) AS average_review_score
    FROM public.vw_orders_clean o
    JOIN public.order_reviews r
        ON o.order_id = r.order_id
    WHERE o.delivery_status IN ('Late', 'On Time')
    GROUP BY o.delivery_status
)

SELECT
    MAX(
        CASE
            WHEN delivery_status = 'On Time'
            THEN average_review_score
        END
    ) AS on_time_review_score,

    MAX(
        CASE
            WHEN delivery_status = 'Late'
            THEN average_review_score
        END
    ) AS late_review_score,

    ROUND(
        MAX(
            CASE
                WHEN delivery_status = 'On Time'
                THEN average_review_score
            END
        )
        -
        MAX(
            CASE
                WHEN delivery_status = 'Late'
                THEN average_review_score
            END
        ),
        2
    ) AS review_score_difference

FROM delivery_review;
    
    
-- 08. Geographic Performance
    SELECT
    c.customer_state AS state,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    COUNT(DISTINCT o.order_id)
        FILTER (
            WHERE v.delivery_status = 'Late'
        ) AS late_orders,

    ROUND(
        100.0 *
        COUNT(DISTINCT o.order_id)
            FILTER (
                WHERE v.delivery_status = 'Late'
            )
        /
        NULLIF(
            COUNT(DISTINCT o.order_id),
            0
        ),
        2
    ) AS late_delivery_rate_percent

FROM public.orders o

JOIN public.customers c
    ON o.customer_id = c.customer_id

JOIN public.vw_orders_clean v
    ON o.order_id = v.order_id

WHERE v.delivery_status IN ('Late', 'On Time')

GROUP BY c.customer_state

ORDER BY late_delivery_rate_percent DESC;

-- 09. Cari "High Volume + High Late Rate"
WITH state_delivery AS (
    SELECT
        c.customer_state AS state,

        COUNT(DISTINCT o.order_id) AS delivered_orders,

        COUNT(DISTINCT o.order_id)
            FILTER (
                WHERE v.delivery_status = 'Late'
            ) AS late_orders

    FROM public.orders o

    JOIN public.customers c
        ON o.customer_id = c.customer_id

    JOIN public.vw_orders_clean v
        ON o.order_id = v.order_id

    WHERE v.delivery_status IN ('Late', 'On Time')

    GROUP BY c.customer_state
)

SELECT
    state,

    delivered_orders,

    late_orders,

    ROUND(
        100.0 * late_orders /
        NULLIF(delivered_orders, 0),
        2
    ) AS late_delivery_rate_percent

FROM state_delivery

ORDER BY
    late_orders DESC;

-- 10. Product Category: Revenue vs Volume
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    SUM(oi.price) AS revenue,

    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(
        SUM(oi.price)::NUMERIC /
        NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS revenue_per_order

FROM public.order_items oi

JOIN public.products p
    ON oi.product_id = p.product_id
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name =
       t.product_category_name

GROUP BY 1

ORDER BY revenue DESC;

-- 11. Customer Revenue per Customer Type
WITH customer_revenue AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS total_orders,

        SUM(oi.price) AS revenue

    FROM public.customers c

    JOIN public.orders o
        ON c.customer_id = o.customer_id

    JOIN public.order_items oi
        ON o.order_id = oi.order_id

    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(
        AVG(revenue)::NUMERIC,
        2
    ) AS average_revenue_per_customer,

    ROUND(
        SUM(revenue)::NUMERIC,
        2
    ) AS total_revenue

FROM customer_revenue

GROUP BY 1;

-- 12. Top Revenue Category
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS category,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS revenue,

    COUNT(DISTINCT oi.order_id) AS orders

FROM public.order_items oi

JOIN public.products p
    ON oi.product_id = p.product_id
LEFT JOIN public.product_category_name_translation t
    ON p.product_category_name =
       t.product_category_name

GROUP BY 1

ORDER BY revenue DESC

LIMIT 5;

-- 13. Top 5 States by Revenue
SELECT
    c.customer_state AS state,

    ROUND(
        SUM(oi.price)::NUMERIC,
        2
    ) AS revenue,

    COUNT(DISTINCT o.order_id) AS orders

FROM public.orders o

JOIN public.customers c
    ON o.customer_id = c.customer_id
JOIN public.order_items oi
    ON o.order_id = oi.order_id

GROUP BY c.customer_state

ORDER BY revenue DESC

LIMIT 5;

-- 14. Revenue Growth Month-over-Month
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS month,

        SUM(oi.price)::numeric AS revenue

    FROM public.orders o

    JOIN public.order_items oi
        ON o.order_id = oi.order_id

    GROUP BY 1
),

monthly_growth AS (
    SELECT
        month,
        revenue,

        LAG(revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue

    FROM monthly_revenue
)

SELECT
    month,

    ROUND(revenue, 2) AS revenue,

    ROUND(previous_month_revenue, 2)
        AS previous_month_revenue,

    ROUND(
        (
            100.0 *
            (revenue - previous_month_revenue)
            /
            NULLIF(previous_month_revenue, 0)
        )::numeric,
        2
    ) AS mom_growth_percent

FROM monthly_growth

ORDER BY month;