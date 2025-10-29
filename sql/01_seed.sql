-- sqlfluff: disable=all
-- Reason: uses psql meta-commands (\copy) which SQLFluff cannot parse.
-- sqlfluff: disable=all
-- Reason: uses psql meta-commands (\copy) which SQLFluff cannot parse.

-- Load CSVs (expects /data mounted by docker-compose)
\copy ecommerce.customers    FROM '/data/customers.csv'    CSV HEADER;
\copy ecommerce.products     FROM '/data/products.csv'     CSV HEADER;
\copy ecommerce.orders       FROM '/data/orders.csv'       CSV HEADER;
\copy ecommerce.order_items  FROM '/data/order_items.csv'  CSV HEADER;
\copy ecommerce.sessions     FROM '/data/sessions.csv'     CSV HEADER;


