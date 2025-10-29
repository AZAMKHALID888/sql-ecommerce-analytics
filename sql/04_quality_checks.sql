
-- Row counts
SELECT 'customers' AS table, COUNT(*) AS rows FROM ecommerce.customers
UNION ALL
SELECT 'products', COUNT(*) FROM ecommerce.products
UNION ALL
SELECT 'orders', COUNT(*) FROM ecommerce.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM ecommerce.order_items
UNION ALL
SELECT 'sessions', COUNT(*) FROM ecommerce.sessions;

-- PK uniqueness (should be zero)
SELECT 'dup_customers' AS check, COUNT(*) FROM (
  SELECT customer_id FROM ecommerce.customers GROUP BY 1 HAVING COUNT(*)>1
) x
UNION ALL
SELECT 'dup_products', COUNT(*) FROM (
  SELECT product_id FROM ecommerce.products GROUP BY 1 HAVING COUNT(*)>1
) x
UNION ALL
SELECT 'dup_orders', COUNT(*) FROM (
  SELECT order_id FROM ecommerce.orders GROUP BY 1 HAVING COUNT(*)>1
) x;

-- Referential integrity (should be zero)
SELECT 'dangling_orders_customer' AS check, COUNT(*) FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

SELECT 'dangling_oi_order' AS check, COUNT(*) FROM ecommerce.order_items oi
LEFT JOIN ecommerce.orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

SELECT 'dangling_oi_product' AS check, COUNT(*) FROM ecommerce.order_items oi
LEFT JOIN ecommerce.products p ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;

-- Not-null spot checks
SELECT 'null_prices' AS check, COUNT(*) FROM ecommerce.order_items
WHERE unit_price IS NULL OR unit_cost IS NULL;
