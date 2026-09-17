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

-- TEST Delivery Performance
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