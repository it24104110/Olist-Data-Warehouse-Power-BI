/* Optional: quality checks on staging and the warehouse after an ETL run. */
USE Olist_DW;
GO
SELECT 'stg_customers' AS table_name, COUNT(*) AS row_count FROM stg.stg_customers
UNION ALL SELECT 'stg_sellers', COUNT(*) FROM stg.stg_sellers
UNION ALL SELECT 'stg_products', COUNT(*) FROM stg.stg_products
UNION ALL SELECT 'stg_orders', COUNT(*) FROM stg.stg_orders
UNION ALL SELECT 'stg_order_items', COUNT(*) FROM stg.stg_order_items
UNION ALL SELECT 'stg_order_payments', COUNT(*) FROM stg.stg_order_payments
UNION ALL SELECT 'stg_order_reviews', COUNT(*) FROM stg.stg_order_reviews
UNION ALL SELECT 'stg_geolocation', COUNT(*) FROM stg.stg_geolocation
UNION ALL SELECT 'stg_product_category_translation', COUNT(*) FROM stg.stg_product_category_translation
UNION ALL SELECT 'stg_public_holidays', COUNT(*) FROM stg.stg_public_holidays;


--dw row counts
USE Olist_DW;
SELECT 'Dim_OrderStatus' AS table_name, COUNT(*) AS row_count FROM dw.Dim_OrderStatus
UNION ALL SELECT 'Dim_PaymentType', COUNT(*) FROM dw.Dim_PaymentType
UNION ALL SELECT 'Dim_seller', COUNT(*) FROM dw.Dim_Seller
UNION ALL SELECT 'Dim_Customer', COUNT(*) FROM dw.Dim_Customer
UNION ALL SELECT 'Dim_Product', COUNT(*) FROM dw.Dim_Product

SELECT COUNT(*) AS location_rows,
       SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS no_coordinates,
       SUM(CASE WHEN region = 'Unknown' THEN 1 ELSE 0 END) AS unknown_region
FROM dw.Dim_Location
WHERE location_key <> -1;

SELECT COUNT(*) AS holidays, SUM(CAST(is_global AS INT)) AS nationwide FROM stg.stg_public_holidays;
SELECT TOP 3 local_name FROM stg.stg_public_holidays;
SELECT holiday_date, english_name, counties FROM stg.stg_public_holidays WHERE is_global = 0;


SELECT COUNT(*) AS date_rows, SUM(CAST(is_holiday AS INT)) AS holidays, MIN(full_date) AS first_day, MAX(full_date) AS last_day
FROM dw.Dim_Date WHERE date_key <> -1;







SELECT 'Fact_Sales' AS fact_table, COUNT(*) AS rows_loaded FROM dw.Fact_Sales
UNION ALL SELECT 'Fact_OrderFulfilment', COUNT(*) FROM dw.Fact_OrderFulfilment;

SELECT SUM(CASE WHEN order_date_key = -1 THEN 1 ELSE 0 END)        AS unknown_date,
       SUM(CASE WHEN customer_key = -1 THEN 1 ELSE 0 END)          AS unknown_customer,
       SUM(CASE WHEN product_key = -1 THEN 1 ELSE 0 END)           AS unknown_product,
       SUM(CASE WHEN seller_key = -1 THEN 1 ELSE 0 END)            AS unknown_seller,
       SUM(CASE WHEN customer_location_key = -1 THEN 1 ELSE 0 END) AS unknown_cust_location,
       SUM(CASE WHEN seller_location_key = -1 THEN 1 ELSE 0 END)   AS unknown_seller_location
FROM dw.Fact_Sales;

SELECT SUM(CASE WHEN delivered_date_key = -1 THEN 1 ELSE 0 END) AS not_delivered,
       SUM(CASE WHEN payment_type_key = -1 THEN 1 ELSE 0 END)   AS no_payment,
       SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END)    AS no_review
FROM dw.Fact_OrderFulfilment;

SELECT (SELECT SUM(price) FROM dw.Fact_Sales) AS dw_price_total,
       (SELECT SUM(price) FROM Olist_OLTP_DB.dbo.order_items) AS source_price_total;


-- 1. Translation: expect 71 rows and 71 distinct categories
use Olist_DW
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_category_name) AS distinct_categories
FROM stg.stg_product_category_translation;

-- 2. Product categories with no English translation
SELECT DISTINCT p.product_category_name
FROM stg.stg_products p
LEFT JOIN stg.stg_product_category_translation t ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL AND t.product_category_name IS NULL;

-- 3. Geolocation quality
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) AS zip_prefixes,
       SUM(CASE WHEN geolocation_lat IS NULL OR geolocation_lng IS NULL THEN 1 ELSE 0 END) AS missing_coords,
       SUM(CASE WHEN LEN(geolocation_zip_code_prefix) <> 5 THEN 1 ELSE 0 END) AS bad_zip_length,
       SUM(CASE WHEN TRY_CAST(geolocation_lat AS FLOAT) NOT BETWEEN -34 AND 6
                  OR TRY_CAST(geolocation_lng AS FLOAT) NOT BETWEEN -75 AND -33 THEN 1 ELSE 0 END) AS outside_brazil
FROM stg.stg_geolocation;

-- 4. Customer and seller zip prefixes with no geolocation row
SELECT 'customers' AS source, COUNT(DISTINCT c.customer_zip_code_prefix) AS zips_without_geolocation
FROM stg.stg_customers c
WHERE c.customer_zip_code_prefix NOT IN (SELECT DISTINCT geolocation_zip_code_prefix FROM stg.stg_geolocation)
UNION ALL
SELECT 'sellers', COUNT(DISTINCT s.seller_zip_code_prefix)
FROM stg.stg_sellers s
WHERE s.seller_zip_code_prefix NOT IN (SELECT DISTINCT geolocation_zip_code_prefix FROM stg.stg_geolocation);
