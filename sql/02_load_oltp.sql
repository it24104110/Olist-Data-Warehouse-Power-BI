/* ======================================================================
   02_load_oltp.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Loads the 7 transactional CSV files into Olist_OLTP_DB with
             BULK INSERT (parent tables first so the foreign keys pass).
             This builds the source system; it is not part of the ETL.
   BEFORE RUNNING: put the Olist CSV files in C:\DWBI_Project\Source_CSV\
             (or find/replace that folder below).
   ====================================================================== */

USE Olist_OLTP_DB;
GO

BULK INSERT dbo.customers
FROM 'C:\DWBI_Project\Source_CSV\olist_customers_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

BULK INSERT dbo.sellers
FROM 'C:\DWBI_Project\Source_CSV\olist_sellers_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

BULK INSERT dbo.products
FROM 'C:\DWBI_Project\Source_CSV\olist_products_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

BULK INSERT dbo.orders
FROM 'C:\DWBI_Project\Source_CSV\olist_orders_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

BULK INSERT dbo.order_items
FROM 'C:\DWBI_Project\Source_CSV\olist_order_items_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

BULK INSERT dbo.order_payments
FROM 'C:\DWBI_Project\Source_CSV\olist_order_payments_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', KEEPNULLS, TABLOCK);

-- No ROWTERMINATOR here: the fixed line ending failed on this file,
-- so SQL Server detects the line endings itself (report section 2.6).
BULK INSERT dbo.order_reviews
FROM 'C:\DWBI_Project\Source_CSV\olist_order_reviews_dataset.csv'
WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, FIELDTERMINATOR=',', CODEPAGE='65001', KEEPNULLS, TABLOCK);
GO

-- Check: customers 99,441 / sellers 3,095 / products 32,951 / orders 99,441
--        order_items 112,650 / order_payments 103,886 / order_reviews 99,224
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM dbo.customers
UNION ALL SELECT 'sellers',        COUNT(*) FROM dbo.sellers
UNION ALL SELECT 'products',       COUNT(*) FROM dbo.products
UNION ALL SELECT 'orders',         COUNT(*) FROM dbo.orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM dbo.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM dbo.order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM dbo.order_reviews;
