/* Optional: profiling queries on the source database (report section 2.7). */
USE Olist_OLTP_DB;

--confirms that nothing was lost during the load.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM dbo.customers
UNION ALL SELECT 'sellers', COUNT(*) FROM dbo.sellers
UNION ALL SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL SELECT 'orders', COUNT(*) FROM dbo.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM dbo.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM dbo.order_reviews;


--gives date range, and it shows the nearly empty early months that affect the monthly loading design.
SELECT FORMAT(order_purchase_timestamp, 'yyyy-MM') AS order_month,
       COUNT(*) AS orders
FROM dbo.orders
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month;

--Order status
SELECT order_status, COUNT(*) AS orders
FROM dbo.orders
GROUP BY order_status
ORDER BY orders DESC;


--Missing dates in orders
SELECT COUNT(*) AS total_orders,
       SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS no_approved_date,
       SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS no_carrier_date,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS no_delivery_date
FROM dbo.orders;


--Odd dates
SELECT SUM(CASE WHEN order_status = 'delivered' AND order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS delivered_but_no_date,
       SUM(CASE WHEN order_delivered_customer_date < order_purchase_timestamp THEN 1 ELSE 0 END) AS delivered_before_purchase
FROM dbo.orders;


--Missing product information
SELECT COUNT(*) AS total_products,
       SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS no_category,
       SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS no_weight
FROM dbo.products;


--Customers (proof for the customer_id discussion)
SELECT COUNT(*) AS total_customer_rows,
       COUNT(DISTINCT customer_unique_id) AS real_customers
FROM dbo.customers;


---Reviews
SELECT COUNT(*) AS review_rows,
       COUNT(DISTINCT review_id) AS distinct_review_ids,
       COUNT(DISTINCT order_id) AS orders_with_reviews
FROM dbo.order_reviews;


--Payments
SELECT payment_type, COUNT(*) AS payments, SUM(payment_value) AS total_value
FROM dbo.order_payments
GROUP BY payment_type
ORDER BY payments DESC;


--Price and freight range
SELECT MIN(price) AS min_price, MAX(price) AS max_price,
       MIN(freight_value) AS min_freight, MAX(freight_value) AS max_freight
FROM dbo.order_items;


--Accent test
SELECT TOP 3 review_comment_message
FROM dbo.order_reviews
WHERE review_comment_message LIKE N'%ã%';
