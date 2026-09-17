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