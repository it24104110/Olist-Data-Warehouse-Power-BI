# Data

## S1 + S2: Olist dataset (CSV, not included)

This project uses the **Brazilian E-Commerce Public Dataset by Olist** (about 100k orders, 2016–2018).
The CSV files are not included in this repository.

1. Download the dataset from Kaggle:
   https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Put all 9 CSV files in `C:\DWBI_Project\Source_CSV\`. The files are used in two places:
   - `sql/02_load_oltp.sql` loads the 7 transactional files into `Olist_OLTP_DB`.
   - The SSIS package `01_Staging_Load` reads the geolocation and category translation files directly.

| File | Contents | Used as |
|---|---|---|
| `olist_orders_dataset.csv` | Orders and their status / timestamps | S1 table |
| `olist_order_items_dataset.csv` | Items in each order (price, freight, seller) | S1 table |
| `olist_order_payments_dataset.csv` | Payment type, instalments and value | S1 table |
| `olist_order_reviews_dataset.csv` | Customer review scores and comments | S1 table |
| `olist_customers_dataset.csv` | Customers and their location | S1 table |
| `olist_sellers_dataset.csv` | Sellers and their location | S1 table |
| `olist_products_dataset.csv` | Product attributes and category | S1 table |
| `olist_geolocation_dataset.csv` | Zip code prefix → latitude / longitude | S2 CSV |
| `product_category_name_translation.csv` | Portuguese → English category names | S2 CSV |

## S3: Public holidays (JSON, included)

`holidays/` holds Brazilian public holidays for 2016–2018 (42 holidays), saved from the
[Nager.Date API](https://date.nager.at/) (`/api/v3/PublicHolidays/{year}/BR`).

The SSIS Script Task calls the API on every run and saves the responses to `C:\DWBI_Project\Holiday_JSON\`.
If the API can't be reached, it reads the saved files from that folder instead. Copy these files there so the ETL also works offline.

Dataset © Olist, released on Kaggle under CC BY-NC-SA 4.0.
