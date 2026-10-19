/* ======================================================================
   04_create_staging.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Creates the staging tables (schema stg) for the three sources:
             S1 database tables, S2 CSV files and S3 holiday API (raw JSON
             and parsed holidays). Run AFTER 03_create_warehouse.sql.
             Staging tables have no keys; SSIS clears them on every run.
   HOW TO RUN: open in SSMS, click Execute (F5).
   ====================================================================== */

USE Olist_DW;
GO

/* ---------- 2. Source S1: copies of the Olist_OLTP tables ---------- */
CREATE TABLE stg.stg_customers (
    customer_id               CHAR(32)      NULL,
    customer_unique_id        CHAR(32)      NULL,
    customer_zip_code_prefix  VARCHAR(5)    NULL,
    customer_city             NVARCHAR(100) NULL,
    customer_state            CHAR(2)       NULL
);
 
CREATE TABLE stg.stg_sellers (
    seller_id                 CHAR(32)      NULL,
    seller_zip_code_prefix    VARCHAR(5)    NULL,
    seller_city               NVARCHAR(100) NULL,
    seller_state              CHAR(2)       NULL
);
 
CREATE TABLE stg.stg_products (
    product_id                 CHAR(32)      NULL,
    product_category_name      NVARCHAR(100) NULL,
    product_name_lenght        INT           NULL,   -- spelling kept as in the source
    product_description_lenght INT           NULL,   -- spelling kept as in the source
    product_photos_qty         INT           NULL,
    product_weight_g           INT           NULL,
    product_length_cm          INT           NULL,
    product_height_cm          INT           NULL,
    product_width_cm           INT           NULL
);
 
CREATE TABLE stg.stg_orders (
    order_id                       CHAR(32)     NULL,
    customer_id                    CHAR(32)     NULL,
    order_status                   VARCHAR(20)  NULL,
    order_purchase_timestamp       DATETIME2(0) NULL,
    order_approved_at              DATETIME2(0) NULL,
    order_delivered_carrier_date   DATETIME2(0) NULL,
    order_delivered_customer_date  DATETIME2(0) NULL,
    order_estimated_delivery_date  DATETIME2(0) NULL
);
 
CREATE TABLE stg.stg_order_items (
    order_id             CHAR(32)      NULL,
    order_item_id        INT           NULL,
    product_id           CHAR(32)      NULL,
    seller_id            CHAR(32)      NULL,
    shipping_limit_date  DATETIME2(0)  NULL,
    price                DECIMAL(10,2) NULL,
    freight_value        DECIMAL(10,2) NULL
);
 
CREATE TABLE stg.stg_order_payments (
    order_id              CHAR(32)      NULL,
    payment_sequential    INT           NULL,
    payment_type          VARCHAR(20)   NULL,
    payment_installments  INT           NULL,
    payment_value         DECIMAL(10,2) NULL
);
 
CREATE TABLE stg.stg_order_reviews (
    review_id                CHAR(32)     NULL,
    order_id                 CHAR(32)     NULL,
    review_score             TINYINT      NULL,
    review_creation_date     DATETIME2(0) NULL,
    review_answer_timestamp  DATETIME2(0) NULL
);
 
/* ---------- 3. Source S2: CSV reference files (raw text) ---------- */
CREATE TABLE stg.stg_geolocation (
    geolocation_zip_code_prefix  NVARCHAR(10)  NULL,
    geolocation_lat              NVARCHAR(50)  NULL,
    geolocation_lng              NVARCHAR(50)  NULL,
    geolocation_city             NVARCHAR(100) NULL,
    geolocation_state            NVARCHAR(10)  NULL
);
 
CREATE TABLE stg.stg_product_category_translation (
    product_category_name          NVARCHAR(100) NULL,
    product_category_name_english  NVARCHAR(100) NULL
);
 
/* ---------- 4. Source S3: holiday API (JSON) ---------- */
CREATE TABLE stg.stg_public_holidays (
    holiday_date    DATE           NULL,
    local_name      NVARCHAR(200)  NULL,   -- name in Portuguese
    english_name    NVARCHAR(200)  NULL,
    country_code    CHAR(2)        NULL,
    is_fixed        BIT            NULL,
    is_global       BIT            NULL,   -- 1 = nationwide, 0 = only some states
    launch_year     INT            NULL,
    holiday_types   NVARCHAR(200)  NULL,
    counties        NVARCHAR(500)  NULL    -- states where it applies (when not nationwide)
);
 
/* Raw JSON responses from the holiday API (filled by the SSIS Script Task) */
CREATE TABLE stg.stg_holidays_raw (
    holiday_year INT NULL,
    raw_json     NVARCHAR(MAX) NULL,
    loaded_at    DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
 
/* ---------- 5. Check: all 11 staging tables should exist with 0 rows ---------- */
SELECT s.name AS schema_name,
       t.name AS table_name,
       (SELECT SUM(p.rows) FROM sys.partitions p
         WHERE p.object_id = t.object_id AND p.index_id IN (0, 1)) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'stg'
ORDER BY t.name;

SELECT 'OLTP source' AS side, DATA_TYPE
FROM Olist_OLTP_DB.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers' AND COLUMN_NAME = 'customer_city'
UNION ALL
SELECT 'DW staging', DATA_TYPE
FROM Olist_DW.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg' AND TABLE_NAME = 'stg_customers' AND COLUMN_NAME = 'customer_city';
GO
