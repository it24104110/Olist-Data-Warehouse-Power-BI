/* ======================================================================
   01_create_oltp_db.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Creates the operational source database Olist_OLTP_DB (S1)
             with the 7 transactional tables, primary keys and foreign keys.
             The reviews table has no primary key because review_id repeats.
   HOW TO RUN: open in SSMS, click Execute (F5). Then run 02_load_oltp.sql.
   ====================================================================== */

IF DB_ID('Olist_OLTP_DB') IS NULL
    CREATE DATABASE Olist_OLTP_DB;
GO

USE Olist_OLTP_DB;
GO

CREATE TABLE dbo.customers (
    customer_id               CHAR(32)      NOT NULL,
    customer_unique_id        CHAR(32)      NOT NULL,
    customer_zip_code_prefix  VARCHAR(5)    NULL,
    customer_city             NVARCHAR(100) NULL,   -- Unicode, same type as staging
    customer_state            CHAR(2)       NULL,
    CONSTRAINT PK_customers PRIMARY KEY (customer_id)
);

CREATE TABLE dbo.sellers (
    seller_id                 CHAR(32)      NOT NULL,
    seller_zip_code_prefix    VARCHAR(5)    NULL,
    seller_city               NVARCHAR(100) NULL,
    seller_state              CHAR(2)       NULL,
    CONSTRAINT PK_sellers PRIMARY KEY (seller_id)
);

CREATE TABLE dbo.products (
    product_id                 CHAR(32)      NOT NULL,
    product_category_name      NVARCHAR(100) NULL,
    product_name_lenght        INT           NULL,   -- spelling kept as in the source
    product_description_lenght INT           NULL,   -- spelling kept as in the source
    product_photos_qty         INT           NULL,
    product_weight_g           INT           NULL,
    product_length_cm          INT           NULL,
    product_height_cm          INT           NULL,
    product_width_cm           INT           NULL,
    CONSTRAINT PK_products PRIMARY KEY (product_id)
);

CREATE TABLE dbo.orders (
    order_id                       CHAR(32)     NOT NULL,
    customer_id                    CHAR(32)     NOT NULL,
    order_status                   VARCHAR(20)  NULL,
    order_purchase_timestamp       DATETIME2(0) NOT NULL,
    order_approved_at              DATETIME2(0) NULL,
    order_delivered_carrier_date   DATETIME2(0) NULL,
    order_delivered_customer_date  DATETIME2(0) NULL,
    order_estimated_delivery_date  DATETIME2(0) NULL,
    CONSTRAINT PK_orders PRIMARY KEY (order_id),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
        REFERENCES dbo.customers (customer_id)
);

CREATE TABLE dbo.order_items (
    order_id             CHAR(32)      NOT NULL,
    order_item_id        INT           NOT NULL,
    product_id           CHAR(32)      NOT NULL,
    seller_id            CHAR(32)      NOT NULL,
    shipping_limit_date  DATETIME2(0)  NULL,
    price                DECIMAL(10,2) NOT NULL,
    freight_value        DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_order_items PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT FK_items_orders   FOREIGN KEY (order_id)   REFERENCES dbo.orders (order_id),
    CONSTRAINT FK_items_products FOREIGN KEY (product_id) REFERENCES dbo.products (product_id),
    CONSTRAINT FK_items_sellers  FOREIGN KEY (seller_id)  REFERENCES dbo.sellers (seller_id)
);

CREATE TABLE dbo.order_payments (
    order_id              CHAR(32)      NOT NULL,
    payment_sequential    INT           NOT NULL,
    payment_type          VARCHAR(20)   NULL,
    payment_installments  INT           NULL,
    payment_value         DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_order_payments PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES dbo.orders (order_id)
);

CREATE TABLE dbo.order_reviews (
    review_id                CHAR(32)       NOT NULL,
    order_id                 CHAR(32)       NOT NULL,
    review_score             TINYINT        NULL,
    review_comment_title     NVARCHAR(200)  NULL,
    review_comment_message   NVARCHAR(MAX)  NULL,
    review_creation_date     DATETIME2(0)   NULL,
    review_answer_timestamp  DATETIME2(0)   NULL,
    CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES dbo.orders (order_id)
);
GO
