-- QUERY 01: KPI TONG QUAN KINH DOANH

USE Capstone_DA_ADV_04;
GO

WITH order_revenue AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM dbo.order_payments
    GROUP BY order_id
)

SELECT
    SUM(orv.order_value) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    CAST(
        SUM(orv.order_value) / NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(18,2)
    ) AS avg_order_value
FROM dbo.orders o
LEFT JOIN order_revenue orv
    ON o.order_id = orv.order_id;



-- QUERY 02: DOANH THU VA DON HANG THEO THANG

WITH monthly_sales AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
        MONTH(o.order_purchase_timestamp) AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(p.payment_value) AS total_revenue
    FROM dbo.orders o
    JOIN dbo.order_payments p
        ON o.order_id = p.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)

SELECT
    year,
    month,
    total_orders,
    CAST(total_revenue AS DECIMAL(18,2)) AS total_revenue
FROM monthly_sales
ORDER BY year, month;



-- QUERY 03: TOP 10 DANH MUC SAN PHAM THEO DOANH THU

SELECT TOP 10
    p.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.order_item_id * 0 + 1) AS total_items,
    CAST(SUM(oi.price) AS DECIMAL(18,2)) AS product_revenue
FROM dbo.order_items oi
JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english
ORDER BY product_revenue DESC;



-- QUERY 04: TOP 10 SELLERS THEO DOANH THU
SELECT TOP 10
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items,
    CAST(SUM(oi.price) AS DECIMAL(18,2)) AS product_revenue
FROM dbo.order_items oi
JOIN dbo.sellers s
    ON oi.seller_id = s.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY product_revenue DESC;


-- QUERY 05: PHAN TICH PHUONG THUC THANH TOAN
SELECT
    payment_type,
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT order_id) AS total_orders,
    CAST(SUM(payment_value) AS DECIMAL(18,2)) AS total_payment_value,
    CAST(AVG(payment_value) AS DECIMAL(18,2)) AS avg_payment_value
FROM dbo.order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- QUERY 06: PHAN TICH DANH GIA KHACH HANG
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage
FROM dbo.order_reviews
GROUP BY review_score
ORDER BY review_score;




-- QUERY 07: PHAN TICH THOI GIAN GIAO HANG
SELECT
    COUNT(*) AS delivered_orders,

    CAST(AVG(
        CAST(DATEDIFF(DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) AS FLOAT)
    ) AS DECIMAL(10,2)) AS avg_delivery_days,

    SUM(
        CASE
            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    CAST(
        SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(5,2)
    ) AS late_delivery_percentage

FROM dbo.orders

WHERE
    order_status = 'delivered'
    AND order_purchase_timestamp IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL;





-- QUERY 08: ANH HUONG GIAO HANG TRE DEN DANH GIA
SELECT
    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,

    COUNT(*) AS total_reviews,

    CAST(AVG(CAST(r.review_score AS FLOAT))
         AS DECIMAL(4,2)) AS avg_review_score

FROM dbo.orders o

JOIN dbo.order_reviews r
    ON o.order_id = r.order_id

WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND r.review_score IS NOT NULL

GROUP BY
    CASE
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 'Late'
        ELSE 'On Time'
    END

ORDER BY avg_review_score;



-- QUERY 09: PHAN TICH DOANH THU THEO BANG
SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS total_orders,

    COUNT(DISTINCT c.customer_unique_id) AS total_customers,

    CAST(
        SUM(p.payment_value)
        AS DECIMAL(18,2)
    ) AS total_revenue,

    CAST(
        SUM(p.payment_value) / COUNT(DISTINCT o.order_id)
        AS DECIMAL(18,2)
    ) AS avg_order_value

FROM dbo.customers c

JOIN dbo.orders o
    ON c.customer_id = o.customer_id

JOIN dbo.order_payments p
    ON o.order_id = p.order_id

GROUP BY
    c.customer_state

ORDER BY
    total_revenue DESC;






-- QUERY 10: PHAN TICH KHACH HANG QUAY LAI
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM dbo.customers c
    JOIN dbo.orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS total_customers,

    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS customer_percentage,

    SUM(total_orders) AS total_orders

FROM customer_orders

GROUP BY
    CASE
        WHEN total_orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END

ORDER BY total_customers DESC;