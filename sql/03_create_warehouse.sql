/* ======================================================================
   03_create_warehouse.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Creates the Olist_DW database, the four schemas
             (stg, dw, mart, etl), the 7 dimension tables with their
             Unknown members (key -1) and the 2 fact tables
             (fact constellation). The tables are filled by the SSIS ETL.
   HOW TO RUN: open in SSMS, click Execute (F5).
   ====================================================================== */

IF DB_ID('Olist_DW') IS NULL
    CREATE DATABASE Olist_DW;
GO

USE Olist_DW;
GO

IF SCHEMA_ID('stg')  IS NULL EXEC('CREATE SCHEMA stg');   -- staging area
IF SCHEMA_ID('dw')   IS NULL EXEC('CREATE SCHEMA dw');    -- enterprise data warehouse
IF SCHEMA_ID('mart') IS NULL EXEC('CREATE SCHEMA mart');  -- data marts
IF SCHEMA_ID('etl')  IS NULL EXEC('CREATE SCHEMA etl');   -- ETL control and log tables


----Dim Date-----
CREATE TABLE dw.Dim_Date (
    date_key        INT           NOT NULL,            -- e.g. 20171124 ; -1 = Unknown
    full_date       DATE          NULL,
    day_of_month    TINYINT       NULL,
    day_name        VARCHAR(10)   NOT NULL,
    day_of_week     TINYINT       NULL,                -- 1 = Monday ... 7 = Sunday
    week_of_year    TINYINT       NULL,
    month_number    TINYINT       NULL,
    month_name      VARCHAR(10)   NOT NULL,
    quarter_number  TINYINT       NULL,
    quarter_name    VARCHAR(10)   NOT NULL,            -- Q1 ... Q4
    calendar_year   SMALLINT      NULL,
    year_month      VARCHAR(10)   NOT NULL,            -- e.g. 2017-11
    is_weekend      BIT           NOT NULL DEFAULT 0,
    is_holiday      BIT           NOT NULL DEFAULT 0,  -- filled from the holiday API
    holiday_name    NVARCHAR(100) NULL,
    CONSTRAINT PK_Dim_Date PRIMARY KEY (date_key)
);


/* ---- Dim_Customer : one row per real person (customer_unique_id) ---- */
CREATE TABLE dw.Dim_Customer (
    customer_key        INT       IDENTITY(1,1) NOT NULL,
    customer_unique_id  CHAR(32)  NOT NULL,            -- business key
    first_order_date    DATE      NULL,
    CONSTRAINT PK_Dim_Customer PRIMARY KEY (customer_key),
    CONSTRAINT UQ_Dim_Customer_unique_id UNIQUE (customer_unique_id)
);


/* ---- Dim_Product ---- */
CREATE TABLE dw.Dim_Product (
    product_key             INT           IDENTITY(1,1) NOT NULL,
    product_id              CHAR(32)      NOT NULL,    -- business key
    category_name_pt        NVARCHAR(100) NULL,
    category_name_en        NVARCHAR(100) NOT NULL,
    product_name_length     INT           NULL,
    product_description_length INT        NULL,
    product_photos_qty      INT           NULL,
    weight_g                INT           NULL,
    length_cm               INT           NULL,
    height_cm               INT           NULL,
    width_cm                INT           NULL,
    volume_cm3              INT           NULL,        -- derived: length x height x width
    CONSTRAINT PK_Dim_Product PRIMARY KEY (product_key),
    CONSTRAINT UQ_Dim_Product_id UNIQUE (product_id)
);

/* ---- Dim_Seller ---- */
CREATE TABLE dw.Dim_Seller (
    seller_key   INT      IDENTITY(1,1) NOT NULL,
    seller_id    CHAR(32) NOT NULL,                    -- business key
    CONSTRAINT PK_Dim_Seller PRIMARY KEY (seller_key),
    CONSTRAINT UQ_Dim_Seller_id UNIQUE (seller_id)
);
 


/* ---- Dim_Location : one row per zip code prefix ---- */
CREATE TABLE dw.Dim_Location (
    location_key     INT           IDENTITY(1,1) NOT NULL,
    zip_code_prefix  VARCHAR(5)    NOT NULL,           -- business key
    city             NVARCHAR(100) NULL,
    state_code       CHAR(2)       NULL,
    state_name       NVARCHAR(50)  NULL,
    region           NVARCHAR(20)  NOT NULL,           -- derived from state
    latitude         DECIMAL(9,6)  NULL,
    longitude        DECIMAL(9,6)  NULL,
    CONSTRAINT PK_Dim_Location PRIMARY KEY (location_key),
    CONSTRAINT UQ_Dim_Location_zip UNIQUE (zip_code_prefix)
);
 


/* ---- Dim_OrderStatus ---- */
CREATE TABLE dw.Dim_OrderStatus (
    order_status_key  INT         IDENTITY(1,1) NOT NULL,
    order_status      VARCHAR(20) NOT NULL,            -- business key
    status_group      VARCHAR(20) NOT NULL,            -- Delivered / In progress / Not fulfilled
    counts_as_sale    BIT         NOT NULL,            -- 0 for canceled and unavailable
    CONSTRAINT PK_Dim_OrderStatus PRIMARY KEY (order_status_key),
    CONSTRAINT UQ_Dim_OrderStatus UNIQUE (order_status)
);


 
/* ---- Dim_PaymentType ---- */
CREATE TABLE dw.Dim_PaymentType (
    payment_type_key  INT         IDENTITY(1,1) NOT NULL,
    payment_type      VARCHAR(20) NOT NULL,            -- business key
    payment_group     VARCHAR(20) NOT NULL,            -- Card / Bank slip / Voucher / Not defined
    CONSTRAINT PK_Dim_PaymentType PRIMARY KEY (payment_type_key),
    CONSTRAINT UQ_Dim_PaymentType UNIQUE (payment_type)
);


/* ---------- Unknown members (key = -1) so fact rows never need a NULL key ---------- */
INSERT INTO dw.Dim_Date (date_key, full_date, day_name, month_name, quarter_name, year_month)
VALUES (-1, NULL, 'Unknown', 'Unknown', 'Unknown', 'Unknown');
 
SET IDENTITY_INSERT dw.Dim_Customer ON;
INSERT INTO dw.Dim_Customer (customer_key, customer_unique_id, first_order_date)
VALUES (-1, 'UNKNOWN', NULL);
SET IDENTITY_INSERT dw.Dim_Customer OFF;
 
SET IDENTITY_INSERT dw.Dim_Product ON;
INSERT INTO dw.Dim_Product (product_key, product_id, category_name_pt, category_name_en)
VALUES (-1, 'UNKNOWN', NULL, 'Unknown');
SET IDENTITY_INSERT dw.Dim_Product OFF;
 
SET IDENTITY_INSERT dw.Dim_Seller ON;
INSERT INTO dw.Dim_Seller (seller_key, seller_id)
VALUES (-1, 'UNKNOWN');
SET IDENTITY_INSERT dw.Dim_Seller OFF;
 
SET IDENTITY_INSERT dw.Dim_Location ON;
INSERT INTO dw.Dim_Location (location_key, zip_code_prefix, city, state_code, state_name, region)
VALUES (-1, '-1', 'Unknown', NULL, 'Unknown', 'Unknown');
SET IDENTITY_INSERT dw.Dim_Location OFF;
 
SET IDENTITY_INSERT dw.Dim_OrderStatus ON;
INSERT INTO dw.Dim_OrderStatus (order_status_key, order_status, status_group, counts_as_sale)
VALUES (-1, 'unknown', 'Unknown', 0);
SET IDENTITY_INSERT dw.Dim_OrderStatus OFF;
 
SET IDENTITY_INSERT dw.Dim_PaymentType ON;
INSERT INTO dw.Dim_PaymentType (payment_type_key, payment_type, payment_group)
VALUES (-1, 'unknown', 'Unknown');
SET IDENTITY_INSERT dw.Dim_PaymentType OFF;
GO
 
/* ======================================================================
   4. FACT TABLES
   ====================================================================== */
 
/* ---- Fact_Sales : grain = one row per order item ---- */
CREATE TABLE dw.Fact_Sales (
    sales_key              BIGINT        IDENTITY(1,1) NOT NULL,
    -- foreign keys to dimensions
    order_date_key         INT           NOT NULL,
    customer_key           INT           NOT NULL,
    product_key            INT           NOT NULL,
    seller_key             INT           NOT NULL,
    customer_location_key  INT           NOT NULL,
    seller_location_key    INT           NOT NULL,
    order_status_key       INT           NOT NULL,
    -- degenerate dimensions (together they define the grain)
    order_id               CHAR(32)      NOT NULL,
    order_item_id          INT           NOT NULL,
    -- measures
    quantity               INT           NOT NULL DEFAULT 1,
    price                  DECIMAL(10,2) NOT NULL,
    freight_value          DECIMAL(10,2) NOT NULL,
    item_total_value       DECIMAL(10,2) NOT NULL,     -- price + freight_value
    -- audit
    etl_load_date          DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Fact_Sales PRIMARY KEY (sales_key),
    CONSTRAINT UQ_Fact_Sales_grain UNIQUE (order_id, order_item_id),
    CONSTRAINT FK_FactSales_DimDate        FOREIGN KEY (order_date_key)        REFERENCES dw.Dim_Date (date_key),
    CONSTRAINT FK_FactSales_DimCustomer    FOREIGN KEY (customer_key)          REFERENCES dw.Dim_Customer (customer_key),
    CONSTRAINT FK_FactSales_DimProduct     FOREIGN KEY (product_key)           REFERENCES dw.Dim_Product (product_key),
    CONSTRAINT FK_FactSales_DimSeller      FOREIGN KEY (seller_key)            REFERENCES dw.Dim_Seller (seller_key),
    CONSTRAINT FK_FactSales_CustLocation   FOREIGN KEY (customer_location_key) REFERENCES dw.Dim_Location (location_key),
    CONSTRAINT FK_FactSales_SellerLocation FOREIGN KEY (seller_location_key)   REFERENCES dw.Dim_Location (location_key),
    CONSTRAINT FK_FactSales_DimOrderStatus FOREIGN KEY (order_status_key)      REFERENCES dw.Dim_OrderStatus (order_status_key)
);
 
/* ---- Fact_OrderFulfilment : grain = one row per order ---- */
CREATE TABLE dw.Fact_OrderFulfilment (
    fulfilment_key                BIGINT        IDENTITY(1,1) NOT NULL,
    -- foreign keys to dimensions (Dim_Date is used in three roles)
    purchase_date_key             INT           NOT NULL,
    delivered_date_key            INT           NOT NULL,   -- -1 when not delivered
    estimated_delivery_date_key   INT           NOT NULL,
    customer_key                  INT           NOT NULL,
    customer_location_key         INT           NOT NULL,
    order_status_key              INT           NOT NULL,
    payment_type_key              INT           NOT NULL,   -- main payment type (largest value)
    -- degenerate dimension (defines the grain)
    order_id                      CHAR(32)      NOT NULL,
    -- measures
    item_count                    INT           NOT NULL,
    payment_total                 DECIMAL(12,2) NULL,
    payment_installments          INT           NULL,       -- of the main payment
    delivery_days                 INT           NULL,       -- purchase to delivery
    delivery_delay_days           INT           NULL,       -- delivery minus estimate (+ late, - early)
    is_late_delivery              BIT           NULL,       -- NULL when not delivered
    review_score                  TINYINT       NULL,       -- latest review, 1 to 5
    -- audit
    etl_load_date                 DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Fact_OrderFulfilment PRIMARY KEY (fulfilment_key),
    CONSTRAINT UQ_Fact_OrderFulfilment_grain UNIQUE (order_id),
    CONSTRAINT FK_FactFul_PurchaseDate  FOREIGN KEY (purchase_date_key)           REFERENCES dw.Dim_Date (date_key),
    CONSTRAINT FK_FactFul_DeliveredDate FOREIGN KEY (delivered_date_key)          REFERENCES dw.Dim_Date (date_key),
    CONSTRAINT FK_FactFul_EstimatedDate FOREIGN KEY (estimated_delivery_date_key) REFERENCES dw.Dim_Date (date_key),
    CONSTRAINT FK_FactFul_DimCustomer   FOREIGN KEY (customer_key)                REFERENCES dw.Dim_Customer (customer_key),
    CONSTRAINT FK_FactFul_CustLocation  FOREIGN KEY (customer_location_key)       REFERENCES dw.Dim_Location (location_key),
    CONSTRAINT FK_FactFul_DimStatus     FOREIGN KEY (order_status_key)            REFERENCES dw.Dim_OrderStatus (order_status_key),
    CONSTRAINT FK_FactFul_DimPayment    FOREIGN KEY (payment_type_key)            REFERENCES dw.Dim_PaymentType (payment_type_key)
);
GO
 
/* ======================================================================
   5. CHECK THE RESULT  (copy these two result grids for your report)
   ====================================================================== */
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;
 
SELECT 'Dim_Date' AS dimension, COUNT(*) AS unknown_rows FROM dw.Dim_Date WHERE date_key = -1
UNION ALL SELECT 'Dim_Customer',    COUNT(*) FROM dw.Dim_Customer    WHERE customer_key = -1
UNION ALL SELECT 'Dim_Product',     COUNT(*) FROM dw.Dim_Product     WHERE product_key = -1
UNION ALL SELECT 'Dim_Seller',      COUNT(*) FROM dw.Dim_Seller      WHERE seller_key = -1
UNION ALL SELECT 'Dim_Location',    COUNT(*) FROM dw.Dim_Location    WHERE location_key = -1
UNION ALL SELECT 'Dim_OrderStatus', COUNT(*) FROM dw.Dim_OrderStatus WHERE order_status_key = -1
UNION ALL SELECT 'Dim_PaymentType', COUNT(*) FROM dw.Dim_PaymentType WHERE payment_type_key = -1;
