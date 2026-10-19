/* ======================================================================
   06_data_marts.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Creates two department-specific data marts (schema mart).
             Each mart is a flattened, easy-to-use view of the warehouse,
             with the business rules of one department already applied.

             1. mart.Sales_Mart
                - For   : Sales and Marketing managers
                - Grain : one row per order item
                - Rule  : only real sales (canceled and unavailable orders removed)

             2. mart.Delivery_Satisfaction_Mart
                - For   : Operations and Customer Service managers
                - Grain : one row per order
                - Rule  : only delivered orders (orders that have a delivery date)

   The marts are views, so they always show the current warehouse data and
   need no extra ETL step. Safe to re-run.
   HOW TO RUN: open in SSMS, click Execute (F5).
   ====================================================================== */

USE Olist_DW;
GO

/* ---------- 1. Sales mart ---------- */
CREATE OR ALTER VIEW mart.Sales_Mart
AS
SELECT f.order_id,
       f.order_item_id,
       d.full_date          AS order_date,
       d.calendar_year,
       d.quarter_name,
       d.month_number,
       d.month_name,
       d.year_month,
       d.day_name,
       d.is_weekend,
       d.is_holiday,
       d.holiday_name,
       p.product_id,
       p.category_name_en   AS product_category,
       s.seller_id,
       sl.state_code        AS seller_state,
       sl.region            AS seller_region,
       c.customer_unique_id,
       cl.city              AS customer_city,
       cl.state_code        AS customer_state,
       cl.region            AS customer_region,
       os.order_status,
       f.quantity,
       f.price,
       f.freight_value,
       f.item_total_value
FROM dw.Fact_Sales f
JOIN dw.Dim_Date        d  ON d.date_key         = f.order_date_key
JOIN dw.Dim_Product     p  ON p.product_key      = f.product_key
JOIN dw.Dim_Seller      s  ON s.seller_key       = f.seller_key
JOIN dw.Dim_Location    sl ON sl.location_key    = f.seller_location_key
JOIN dw.Dim_Customer    c  ON c.customer_key     = f.customer_key
JOIN dw.Dim_Location    cl ON cl.location_key    = f.customer_location_key
JOIN dw.Dim_OrderStatus os ON os.order_status_key = f.order_status_key
WHERE os.counts_as_sale = 1;
GO

/* ---------- 2. Delivery and satisfaction mart ---------- */
CREATE OR ALTER VIEW mart.Delivery_Satisfaction_Mart
AS
SELECT f.order_id,
       pd.full_date         AS purchase_date,
       pd.calendar_year     AS purchase_year,
       pd.quarter_name      AS purchase_quarter,
       pd.month_number      AS purchase_month_number,
       pd.month_name        AS purchase_month,
       pd.year_month        AS purchase_year_month,
       dd.full_date         AS delivered_date,
       ed.full_date         AS estimated_delivery_date,
       cl.city              AS customer_city,
       cl.state_code        AS customer_state,
       cl.region            AS customer_region,
       os.order_status,
       os.status_group,
       pt.payment_type,
       pt.payment_group,
       f.item_count,
       f.payment_total,
       f.payment_installments,
       f.delivery_days,
       f.delivery_delay_days,
       f.is_late_delivery,
       f.review_score
FROM dw.Fact_OrderFulfilment f
JOIN dw.Dim_Date        pd ON pd.date_key          = f.purchase_date_key
JOIN dw.Dim_Date        dd ON dd.date_key          = f.delivered_date_key
JOIN dw.Dim_Date        ed ON ed.date_key          = f.estimated_delivery_date_key
JOIN dw.Dim_Location    cl ON cl.location_key      = f.customer_location_key
JOIN dw.Dim_OrderStatus os ON os.order_status_key  = f.order_status_key
JOIN dw.Dim_PaymentType pt ON pt.payment_type_key  = f.payment_type_key
WHERE f.delivered_date_key <> -1;
GO

/* ---------- 3. Check: rows in each mart must equal the expected count ---------- */
SELECT 'Sales_Mart' AS mart,
       (SELECT COUNT(*) FROM mart.Sales_Mart) AS rows_in_mart,
       (SELECT COUNT(*)
          FROM dw.Fact_Sales f
          JOIN dw.Dim_OrderStatus s ON s.order_status_key = f.order_status_key
         WHERE s.counts_as_sale = 1) AS expected_rows
UNION ALL
SELECT 'Delivery_Satisfaction_Mart',
       (SELECT COUNT(*) FROM mart.Delivery_Satisfaction_Mart),
       (SELECT COUNT(*) FROM dw.Fact_OrderFulfilment WHERE delivered_date_key <> -1);
GO
