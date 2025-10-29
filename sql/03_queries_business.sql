
-- 1) Monthly Active Customers (MAC) & growth rate
WITH mac AS (
  SELECT month, mac,
         LAG(mac) OVER (ORDER BY month) AS mac_prev
  FROM ecommerce.v_mac
)
SELECT
  month,
  mac,
  ROUND(100.0*(mac - mac_prev)/NULLIF(mac_prev,0), 2) AS mac_growth_pct
FROM mac
ORDER BY month;

-- 2) Revenue & margin by month
SELECT month, revenue, margin
FROM ecommerce.v_revenue_monthly
ORDER BY month;

-- 3) Top 10 products by revenue overall
SELECT product_id, category, SUM(revenue) AS revenue, SUM(margin) AS margin
FROM ecommerce.v_order_items_enriched
GROUP BY 1,2
ORDER BY revenue DESC
LIMIT 10;

-- 4) Category performance with rolling 3m revenue
WITH cat AS (
  SELECT order_month, category, SUM(revenue) AS revenue
  FROM ecommerce.v_order_items_enriched
  GROUP BY 1,2
),
roll AS (
  SELECT
    category, order_month,
    revenue,
    AVG(revenue) OVER (PARTITION BY category ORDER BY order_month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rev_roll_3m
  FROM cat
)
SELECT * FROM roll ORDER BY order_month, category;

-- 5) Cohort retention table (cohort x month_index)
WITH grid AS (
  SELECT cohort_month, month_active,
         (DATE_PART('year', month_active) - DATE_PART('year', cohort_month))*12
         + (DATE_PART('month', month_active) - DATE_PART('month', cohort_month)) AS month_index,
         active_customers
  FROM ecommerce.v_cohorts
),
sizes AS (
  SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
  FROM ecommerce.v_customer_firsts
  GROUP BY 1
)
SELECT
  g.cohort_month,
  g.month_index,
  g.active_customers,
  s.cohort_size,
  ROUND(100.0 * g.active_customers / NULLIF(s.cohort_size,0), 2) AS retention_pct
FROM grid g
JOIN sizes s USING (cohort_month)
ORDER BY cohort_month, month_index;

-- 6) Sessions vs Orders conversion
SELECT * FROM ecommerce.v_sessions_orders ORDER BY month;

-- 7) Anomaly flags (|z| >= 2)
SELECT month, revenue, z_score,
       CASE WHEN ABS(z_score) >= 2 THEN 'anomaly' ELSE 'normal' END AS flag
FROM ecommerce.v_anomaly
ORDER BY month;
