--I. Test
USE Capstone_DA_ADV_04;

SELECT COUNT(*) AS total_rows
FROM dbo.sellers;

--II. Kiểm tra số dòng
USE Capstone_DA_ADV_04;

SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM dbo.customers
UNION ALL
SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL
SELECT 'sellers', COUNT(*) FROM dbo.sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM dbo.geolocation
UNION ALL
SELECT 'orders', COUNT(*) FROM dbo.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM dbo.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews;


--III. Kiểm tra khóa chính tiềm năng và duplicate/null
USE Capstone_DA_ADV_04;

-- 1. customers
SELECT 
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS non_null_customer_id,
    COUNT(DISTINCT customer_id) AS unique_customer_id
FROM dbo.customers;

-- 2. products
SELECT 
    COUNT(*) AS total_rows,
    COUNT(product_id) AS non_null_product_id,
    COUNT(DISTINCT product_id) AS unique_product_id
FROM dbo.products;

-- 3. sellers
SELECT 
    COUNT(*) AS total_rows,
    COUNT(seller_id) AS non_null_seller_id,
    COUNT(DISTINCT seller_id) AS unique_seller_id
FROM dbo.sellers;

-- 4. orders
SELECT 
    COUNT(*) AS total_rows,
    COUNT(order_id) AS non_null_order_id,
    COUNT(DISTINCT order_id) AS unique_order_id
FROM dbo.orders;

-- 5. order_reviews
SELECT 
    COUNT(*) AS total_rows,
    COUNT(review_id) AS non_null_review_id,
    COUNT(DISTINCT review_id) AS unique_review_id
FROM dbo.order_reviews;



--IV. Kiểm tra 4 bảng còn lại
USE Capstone_DA_ADV_04;

-- 1. ORDER_ITEMS
-- Kiểm tra cặp (order_id, order_item_id)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', order_item_id)) AS unique_key
FROM dbo.order_items;


-- 2. ORDER_PAYMENTS
-- Kiểm tra cặp (order_id, payment_sequential)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', payment_sequential)) AS unique_key
FROM dbo.order_payments;


-- 3. ORDER_REVIEWS
-- Kiểm tra cặp (order_id, review_id)
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '|', review_id)) AS unique_key
FROM dbo.order_reviews;


-- 4. GEOLOCATION
-- Kiểm tra zip code có unique hay không
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_codes
FROM dbo.geolocation;

--V. Kiểm tra datatype trước khi tạo PK
USE Capstone_DA_ADV_04;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
    (TABLE_NAME = 'customers' AND COLUMN_NAME = 'customer_id')
 OR (TABLE_NAME = 'products' AND COLUMN_NAME = 'product_id')
 OR (TABLE_NAME = 'sellers' AND COLUMN_NAME = 'seller_id')
 OR (TABLE_NAME = 'orders' AND COLUMN_NAME = 'order_id')
 OR (TABLE_NAME = 'order_items' AND COLUMN_NAME IN ('order_id', 'order_item_id'))
 OR (TABLE_NAME = 'order_payments' AND COLUMN_NAME IN ('order_id', 'payment_sequential'))
 OR (TABLE_NAME = 'order_reviews' AND COLUMN_NAME IN ('order_id', 'review_id'))
 OR (TABLE_NAME = 'geolocation' AND COLUMN_NAME = 'geolocation_zip_code_prefix')
ORDER BY TABLE_NAME, COLUMN_NAME;


--VI. Chuẩn hóa datatype và NOT NULL
USE Capstone_DA_ADV_04;
GO

-- CUSTOMERS
ALTER TABLE dbo.customers
ALTER COLUMN customer_id VARCHAR(32) NOT NULL;

-- PRODUCTS
ALTER TABLE dbo.products
ALTER COLUMN product_id VARCHAR(32) NOT NULL;

-- SELLERS
ALTER TABLE dbo.sellers
ALTER COLUMN seller_id VARCHAR(32) NOT NULL;

-- ORDERS
ALTER TABLE dbo.orders
ALTER COLUMN order_id VARCHAR(32) NOT NULL;

-- ORDER ITEMS
ALTER TABLE dbo.order_items
ALTER COLUMN order_id VARCHAR(32) NOT NULL;

ALTER TABLE dbo.order_items
ALTER COLUMN order_item_id BIGINT NOT NULL;

-- ORDER PAYMENTS
ALTER TABLE dbo.order_payments
ALTER COLUMN order_id VARCHAR(32) NOT NULL;

ALTER TABLE dbo.order_payments
ALTER COLUMN payment_sequential BIGINT NOT NULL;

-- ORDER REVIEWS
ALTER TABLE dbo.order_reviews
ALTER COLUMN order_id VARCHAR(32) NOT NULL;

ALTER TABLE dbo.order_reviews
ALTER COLUMN review_id VARCHAR(32) NOT NULL;

-- GEOLOCATION
ALTER TABLE dbo.geolocation
ALTER COLUMN geolocation_zip_code_prefix BIGINT NOT NULL;


--VII. Tạo Primary Keys
USE Capstone_DA_ADV_04;
GO

ALTER TABLE dbo.customers
ADD CONSTRAINT PK_customers
PRIMARY KEY (customer_id);

ALTER TABLE dbo.products
ADD CONSTRAINT PK_products
PRIMARY KEY (product_id);

ALTER TABLE dbo.sellers
ADD CONSTRAINT PK_sellers
PRIMARY KEY (seller_id);

ALTER TABLE dbo.orders
ADD CONSTRAINT PK_orders
PRIMARY KEY (order_id);

ALTER TABLE dbo.order_items
ADD CONSTRAINT PK_order_items
PRIMARY KEY (order_id, order_item_id);

ALTER TABLE dbo.order_payments
ADD CONSTRAINT PK_order_payments
PRIMARY KEY (order_id, payment_sequential);

ALTER TABLE dbo.order_reviews
ADD CONSTRAINT PK_order_reviews
PRIMARY KEY (order_id, review_id);

ALTER TABLE dbo.geolocation
ADD CONSTRAINT PK_geolocation
PRIMARY KEY (geolocation_zip_code_prefix);


--VIII. Kiểm tra PK
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY TABLE_NAME;


--IX. Chuẩn hóa các cột Foreign Key và kiểm tra orphan records trước khi tạo quan hệ
-- Đổi datatype FK về VARCHAR(32)
USE Capstone_DA_ADV_04;
GO

ALTER TABLE dbo.orders
ALTER COLUMN customer_id VARCHAR(32) NOT NULL;

ALTER TABLE dbo.order_items
ALTER COLUMN product_id VARCHAR(32) NOT NULL;

ALTER TABLE dbo.order_items
ALTER COLUMN seller_id VARCHAR(32) NOT NULL;

-- Kiểm tra orphan records
-- orders có customer_id không tồn tại trong customers?
SELECT COUNT(*) AS orphan_orders
FROM dbo.orders o
LEFT JOIN dbo.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- order_items có order_id không tồn tại trong orders?
SELECT COUNT(*) AS orphan_order_items_order
FROM dbo.order_items oi
LEFT JOIN dbo.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- order_items có product_id không tồn tại trong products?
SELECT COUNT(*) AS orphan_order_items_product
FROM dbo.order_items oi
LEFT JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- order_items có seller_id không tồn tại trong sellers?
SELECT COUNT(*) AS orphan_order_items_seller
FROM dbo.order_items oi
LEFT JOIN dbo.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- payments có order_id không tồn tại trong orders?
SELECT COUNT(*) AS orphan_payments
FROM dbo.order_payments op
LEFT JOIN dbo.orders o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- reviews có order_id không tồn tại trong orders?
SELECT COUNT(*) AS orphan_reviews
FROM dbo.order_reviews r
LEFT JOIN dbo.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;



--Foreign Key constraints.
USE Capstone_DA_ADV_04;
GO

ALTER TABLE dbo.orders
ADD CONSTRAINT FK_orders_customers
FOREIGN KEY (customer_id)
REFERENCES dbo.customers(customer_id);

ALTER TABLE dbo.order_items
ADD CONSTRAINT FK_order_items_orders
FOREIGN KEY (order_id)
REFERENCES dbo.orders(order_id);

ALTER TABLE dbo.order_items
ADD CONSTRAINT FK_order_items_products
FOREIGN KEY (product_id)
REFERENCES dbo.products(product_id);

ALTER TABLE dbo.order_items
ADD CONSTRAINT FK_order_items_sellers
FOREIGN KEY (seller_id)
REFERENCES dbo.sellers(seller_id);

ALTER TABLE dbo.order_payments
ADD CONSTRAINT FK_order_payments_orders
FOREIGN KEY (order_id)
REFERENCES dbo.orders(order_id);

ALTER TABLE dbo.order_reviews
ADD CONSTRAINT FK_order_reviews_orders
FOREIGN KEY (order_id)
REFERENCES dbo.orders(order_id);

--Kiểm tra
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE CONSTRAINT_TYPE IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;