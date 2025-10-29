
# SQL Ecommerce Analytics (PostgreSQL)

Analyze a realistic **synthetic ecommerce** dataset with SQL: monthly actives, revenue, top products, retention cohorts, and simple anomaly flags. Everything runs locally with Postgres or Docker.

## Dataset
Small, synthetic data generated for analytics practice (MIT-licensed). Files in `/data`: `customers`, `products`, `orders`, `order_items`, `sessions`.

## ERD (Mermaid)
```mermaid
erDiagram
  customers ||--o{ orders : places
  orders ||--o{ order_items : contains
  products ||--o{ order_items : sold_as
  customers ||--o{ sessions : browses
  customers {
    int customer_id PK
    text country
    text signup_channel
    timestamp signup_ts
  }
  orders {
    int order_id PK
    int customer_id FK
    timestamp order_ts
    text status
  }
  order_items {
    int order_id FK
    int product_id FK
    int qty
    numeric unit_price
    numeric unit_cost
  }
  products {
    int product_id PK
    text category
  }
  sessions {
    int session_id PK
    int customer_id FK
    timestamp session_ts
    text source
  }
```
## Run locally (Docker recommended)

```bash
# 1) Start Postgres
docker compose up -d

# 2) Create schema + load data + build views + run business queries
psql postgresql://postgres:postgres@localhost:5432/postgres -f sql/00_schema.sql
psql postgresql://postgres:postgres@localhost:5432/postgres -f sql/01_seed.sql
psql postgresql://postgres:postgres@localhost:5432/postgres -f sql/02_views.sql
psql postgresql://postgres:postgres@localhost:5432/postgres -f sql/03_queries_business.sql

# 3) Optional checks
psql postgresql://postgres:postgres@localhost:5432/postgres -f sql/04_quality_checks.sql
```

Without Docker, use a local Postgres and run the same commands (update the connection string if needed).

## What’s included
- Clean schema + seed from CSV
- Semantic views for metrics
- Cohort retention, rolling metrics, and anomaly flags
- sqlfluff config + CI workflow

## Git commands to publish
```bash
git init
git add .
git commit -m "Initial commit: SQL ecommerce analytics"
git branch -M main
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## License
MIT (see `LICENSE`)
