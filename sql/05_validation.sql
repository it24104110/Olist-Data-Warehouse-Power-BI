/* ======================================================================
   05_validation.sql
   Project : IT3101 DWBI Assignment 1 - Olist Data Warehouse
   Purpose : Creates the ETL log tables (schema etl) and the stored
             procedure etl.usp_run_validation.
             Each run of the procedure:
               1. adds one row to etl.run_log
               2. runs 16 checks and stores PASS / FAIL in etl.validation_result
               3. raises an error if any check fails (so the SSIS package turns red)
   Safe to re-run (this drops and recreates the two log tables).
   HOW TO RUN: open in SSMS, click Execute (F5).
   ====================================================================== */

USE Olist_DW;
GO

DROP TABLE IF EXISTS etl.validation_result;
DROP TABLE IF EXISTS etl.run_log;
GO

CREATE TABLE etl.run_log (
    run_id                INT           IDENTITY(1,1) NOT NULL,
    run_time              DATETIME2(0)  NOT NULL,
    fact_sales_rows       INT           NULL,
    fact_fulfilment_rows  INT           NULL,
    checks_run            INT           NULL,
    checks_failed         INT           NULL,
    CONSTRAINT PK_etl_run_log PRIMARY KEY (run_id)
);

CREATE TABLE etl.validation_result (
    result_id       INT           IDENTITY(1,1) NOT NULL,
    run_id          INT           NOT NULL,
    check_name      VARCHAR(100)  NOT NULL,
    expected_value  DECIMAL(18,2) NULL,
    actual_value    DECIMAL(18,2) NULL,
    status          VARCHAR(4)    NOT NULL,
    CONSTRAINT PK_etl_validation_result PRIMARY KEY (result_id),
    CONSTRAINT FK_validation_run FOREIGN KEY (run_id) REFERENCES etl.run_log (run_id)
);
GO

CREATE OR ALTER PROCEDURE etl.usp_run_validation
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @run_id INT;
    DECLARE @checks INT;
    DECLARE @failed INT;

    INSERT INTO etl.run_log (run_time) VALUES (SYSDATETIME());
    SET @run_id = SCOPE_IDENTITY();

    INSERT INTO etl.validation_result (run_id, check_name, expected_value, actual_value, status)
    SELECT @run_id, c.check_name, c.expected_value, c.actual_value,
           CASE WHEN c.expected_value = c.actual_value THEN 'PASS' ELSE 'FAIL' END
    FROM (
        /* ---- A. Extraction: staging must equal the source ---- */
        SELECT CAST('Staging orders = source orders' AS VARCHAR(100)) AS check_name,
               CAST((SELECT COUNT(*) FROM Olist_OLTP_DB.dbo.orders) AS DECIMAL(18,2)) AS expected_value,
               CAST((SELECT COUNT(*) FROM stg.stg_orders) AS DECIMAL(18,2)) AS actual_value
        UNION ALL
        SELECT 'Staging order items = source order items',
               CAST((SELECT COUNT(*) FROM Olist_OLTP_DB.dbo.order_items) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM stg.stg_order_items) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Staging customers = source customers',
               CAST((SELECT COUNT(*) FROM Olist_OLTP_DB.dbo.customers) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM stg.stg_customers) AS DECIMAL(18,2))

        /* ---- B. Row counts in the warehouse ---- */
        UNION ALL
        SELECT 'Fact_Sales rows = staged order items',
               CAST((SELECT COUNT(*) FROM stg.stg_order_items) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_Sales) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Fact_OrderFulfilment rows = staged orders',
               CAST((SELECT COUNT(*) FROM stg.stg_orders) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_OrderFulfilment) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Dim_Customer rows = distinct customers + Unknown',
               CAST((SELECT COUNT(DISTINCT customer_unique_id) + 1 FROM stg.stg_customers) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Dim_Customer) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Dim_Product rows = staged products + Unknown',
               CAST((SELECT COUNT(*) + 1 FROM stg.stg_products) AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Dim_Product) AS DECIMAL(18,2))

        /* ---- C. Totals must match the source ---- */
        UNION ALL
        SELECT 'Total item price = staging',
               CAST((SELECT COALESCE(SUM(price), 0) FROM stg.stg_order_items) AS DECIMAL(18,2)),
               CAST((SELECT COALESCE(SUM(price), 0) FROM dw.Fact_Sales) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Total freight = staging',
               CAST((SELECT COALESCE(SUM(freight_value), 0) FROM stg.stg_order_items) AS DECIMAL(18,2)),
               CAST((SELECT COALESCE(SUM(freight_value), 0) FROM dw.Fact_Sales) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Total payments = staging',
               CAST((SELECT COALESCE(SUM(payment_value), 0) FROM stg.stg_order_payments) AS DECIMAL(18,2)),
               CAST((SELECT COALESCE(SUM(payment_total), 0) FROM dw.Fact_OrderFulfilment) AS DECIMAL(18,2))

        /* ---- D. Keys: no fact row may point to an Unknown member ---- */
        UNION ALL
        SELECT 'Fact_Sales rows with an Unknown key = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_Sales
                     WHERE order_date_key = -1 OR customer_key = -1 OR product_key = -1
                        OR seller_key = -1 OR customer_location_key = -1
                        OR seller_location_key = -1 OR order_status_key = -1) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Fact_OrderFulfilment rows with an Unknown key = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_OrderFulfilment
                     WHERE purchase_date_key = -1 OR estimated_delivery_date_key = -1
                        OR customer_key = -1 OR customer_location_key = -1
                        OR order_status_key = -1) AS DECIMAL(18,2))

        /* ---- E. Business rules ---- */
        UNION ALL
        SELECT 'Review scores outside 1 to 5 = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_OrderFulfilment
                     WHERE review_score IS NOT NULL AND review_score NOT BETWEEN 1 AND 5) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Negative delivery days = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_OrderFulfilment WHERE delivery_days < 0) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Late flag on undelivered orders = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) FROM dw.Fact_OrderFulfilment
                     WHERE delivered_date_key = -1 AND is_late_delivery IS NOT NULL) AS DECIMAL(18,2))
        UNION ALL
        SELECT 'Duplicate order items in Fact_Sales = 0',
               CAST(0 AS DECIMAL(18,2)),
               CAST((SELECT COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '|', order_item_id))
                     FROM dw.Fact_Sales) AS DECIMAL(18,2))
    ) AS c;

    SELECT @checks = COUNT(*),
           @failed = COALESCE(SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END), 0)
    FROM etl.validation_result
    WHERE run_id = @run_id;

    UPDATE etl.run_log
    SET fact_sales_rows      = (SELECT COUNT(*) FROM dw.Fact_Sales),
        fact_fulfilment_rows = (SELECT COUNT(*) FROM dw.Fact_OrderFulfilment),
        checks_run           = @checks,
        checks_failed        = @failed
    WHERE run_id = @run_id;

    IF @failed > 0
        THROW 50001, 'Validation failed. See etl.validation_result for the failed checks.', 1;
END;
GO




   SELECT * FROM etl.run_log ORDER BY run_id;

   SELECT check_name, expected_value, actual_value, status
   FROM etl.validation_result
   WHERE run_id = (SELECT MAX(run_id) FROM etl.run_log)
   ORDER BY result_id;
