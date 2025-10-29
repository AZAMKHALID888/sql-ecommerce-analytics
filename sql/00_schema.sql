
-- Create schema
DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;

-- Customers
CREATE TABLE ecommerce.customers (
  customer_id   INT PRIMARY KEY,
  country       TEXT NOT NULL,
  signup_channel TEXT NOT NULL,
  signup_ts     TIMESTAMP NOT NULL
);

-- Products
CREATE TABLE ecommerce.products (
  product_id INT PRIMARY KEY,
  category   TEXT NOT NULL
);

-- Orders
CREATE TABLE ecommerce.orders (
  order_id    INT PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES ecommerce.customers(customer_id),
  order_ts    TIMESTAMP NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('paid','cancelled','refunded'))
);

-- Order Items
CREATE TABLE ecommerce.order_items (
  order_id   INT NOT NULL REFERENCES ecommerce.orders(order_id),
  product_id INT NOT NULL REFERENCES ecommerce.products(product_id),
  qty        INT NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  unit_cost  NUMERIC(12,2) NOT NULL CHECK (unit_cost >= 0),
  PRIMARY KEY (order_id, product_id)
);

-- Sessions (web/app visits)
CREATE TABLE ecommerce.sessions (
  session_id   INT PRIMARY KEY,
  customer_id  INT NOT NULL REFERENCES ecommerce.customers(customer_id),
  session_ts   TIMESTAMP NOT NULL,
  source       TEXT NOT NULL
);

-- Helpful indexes
CREATE INDEX ON ecommerce.orders (customer_id, order_ts);
CREATE INDEX ON ecommerce.order_items (product_id);
CREATE INDEX ON ecommerce.sessions (customer_id, session_ts);
