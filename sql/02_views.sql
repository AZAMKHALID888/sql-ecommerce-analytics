-- Date helpers
CREATE OR REPLACE VIEW ecommerce.v_dates AS
SELECT
  d::date AS d,
  date_trunc('month', d)::date AS m
FROM generate_series(
  (SELECT min(signup_ts)::date FROM ecommerce.customers),
  (SELECT greatest(
            (SELECT max(order_ts)::date FROM ecommerce.orders),
            (SELECT max(session_ts)::date FROM ecommerce.sessions)
          )),
  interval '1 day'
) AS g(d);

-- Revenue & margin per order item
CREATE OR REPLACE VIEW ecommerce.v_order_items_enriched AS
SELECT
  oi.order_id,
  o.customer_id,
  o.order_ts::date AS order_date,
  date_trunc('month', o.order_ts)::date AS order_month,
  oi.product_id,
  p.category,
  oi.qty,
  oi.unit_price,
  oi.unit_cost,
  (oi.qty * oi.unit_price) AS revenue,
  (oi.qty * (oi.unit_price - oi.unit_cost)) AS margin
FROM ecommerce.order_items oi
JOIN ecommerce.orders o  USING (order_id)
JOIN ecommerce.products p USING (product_id)
WHERE o.status = 'paid';

-- Customer first order month (for cohorts)
CREATE OR REPLACE VIEW ecommerce.v_customer_firsts AS
SELECT
  c.customer_id,
  date_trunc('month', min(o.order_ts))::date AS first_order_month
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o ON o.customer_id = c.customer_id AND o.status='paid'
GROUP BY 1;

-- Monthly active customers (MAC)
CREATE OR REPLACE VIEW ecommerce.v_mac AS
SELECT
  date_trunc('month', o.order_ts)::date AS month,
  COUNT(DISTINCT o.customer_id) AS mac
FROM ecommerce.orders o
WHERE o.status = 'paid'
GROUP BY 1;

-- Monthly sessions & crude conversion (orders/sessions)
CREATE OR REPLACE VIEW ecommerce.v_sessions_orders AS
WITH s AS (
  SELECT date_trunc('month', session_ts)::date AS month, COUNT(*) AS sessions
  FROM ecommerce.sessions GROUP BY 1
),
o AS (
  SELECT date_trunc('month', order_ts)::date AS month, COUNT(*) AS orders
  FROM ecommerce.orders WHERE status='paid' GROUP BY 1
)
SELECT
  COALESCE(s.month, o.month) AS month,
  s.sessions,
  o.orders,
  CASE WHEN s.sessions > 0 THEN ROUND(o.orders::numeric/s.sessions, 4) ELSE NULL END AS conversion_rate
FROM s FULL OUTER JOIN o ON s.month = o.month;

-- Cohort retention by first_purchase_month vs activity month
CREATE OR REPLACE VIEW ecommerce.v_cohorts AS
WITH firsts AS (
  SELECT customer_id, first_order_month FROM ecommerce.v_customer_firsts
),
active AS (
  SELECT DISTINCT customer_id, date_trunc('month', order_ts)::date AS month_active
  FROM ecommerce.orders WHERE status='paid'
)
SELECT
  f.first_order_month AS cohort_month,
  a.month_active,
  COUNT(DISTINCT a.customer_id) AS active_customers
FROM firsts f
JOIN active a ON a.customer_id = f.customer_id
GROUP BY 1,2;

-- Revenue & margin monthly
CREATE OR REPLACE VIEW ecommerce.v_revenue_monthly AS
SELECT
  order_month AS month,
  SUM(revenue) AS revenue,
  SUM(margin)  AS margin
FROM ecommerce.v_order_items_enriched
GROUP BY 1;

-- Top products & categories monthly (rolling 3m)
CREATE OR REPLACE VIEW ecommerce.v_top_products AS
WITH per_product_month AS (
  SELECT
    date_trunc('month', o.order_ts)::date AS order_month,
    oi.product_id,
    p.category,
    SUM(oi.qty * oi.unit_price) AS revenue,
    SUM(oi.qty * (oi.unit_price - oi.unit_cost)) AS margin
  FROM ecommerce.order_items oi
  JOIN ecommerce.orders o  USING (order_id)
  JOIN ecommerce.products p USING (product_id)
  WHERE o.status = 'paid'
  GROUP BY 1,2,3
)
SELECT
  order_month,
  product_id,
  category,
  revenue,
  margin,
  AVG(revenue) OVER (
    PARTITION BY product_id
    ORDER BY order_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rev_rolling_3m
FROM per_product_month;

-- Simple anomaly score (Z-score on monthly revenue)
CREATE OR REPLACE VIEW ecommerce.v_anomaly AS
WITH x AS (
  SELECT month, revenue,
         AVG(revenue) OVER () AS mu,
         STDDEV_POP(revenue) OVER () AS sigma
  FROM ecommerce.v_revenue_monthly
)
SELECT
  month, revenue,
  CASE WHEN sigma = 0 OR sigma IS NULL THEN 0 ELSE (revenue - mu)/sigma END AS z_score
FROM x;
