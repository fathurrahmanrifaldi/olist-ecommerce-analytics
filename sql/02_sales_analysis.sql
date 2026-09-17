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
