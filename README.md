# Yuniql PostgreSQL + GitHub Actions Sample

[![Database Migration](https://img.shields.io/badge/Database-Migration-blue)](https://yuniql.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

A production-ready example of automated database migrations using **Yuniql** with **PostgreSQL** and **GitHub Actions**.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [What is Yuniql?](#what-is-yuniql)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Writing Migrations](#writing-migrations)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │  Developer   │────▶│    Git       │────▶│   GitHub     │
  │  writes SQL  │     │    Commit    │     │   Push       │
  └──────────────┘     └──────────────┘     └──────────────┘
         │                                         │
         │                                         ▼
         │                          ┌──────────────────────────┐
         │                          │   GitHub Actions         │
         │                          │   ┌──────────────────┐   │
         │                          │   │ 1. Checkout repo │   │
         │                          │   │ 2. Setup .NET    │   │
         │                          │   │ 3. Install Yuniql│   │
         │                          │   │ 4. Run migrations│   │
         │                          │   └──────────────────┘   │
         │                          └────────────┬─────────────┘
         │                                       │
         ▼                                       ▼
  ┌──────────────┐                    ┌──────────────────────────┐
  │  Local Dev   │                    │      PostgreSQL DB       │
  │  (Docker)    │───────────────────▶│  ┌──────────────────┐   │
  │              │                    │  │ __yuniql_schema_ │   │
  └──────────────┘                    │  │    _version      │   │
                                      │  │ (tracks applied  │   │
                                      │  │  migrations)     │   │
                                      │  └──────────────────┘   │
                                      │                         │
                                      │  ┌──────────────────┐   │
                                      │  │   app schema     │   │
                                      │  │  ├── users       │   │
                                      │  │  ├── products    │   │
                                      │  │  ├── orders      │   │
                                      │  │  └── ...         │   │
                                      │  └──────────────────┘   │
                                      └──────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            MIGRATION EXECUTION FLOW                          │
└─────────────────────────────────────────────────────────────────────────────┘

    db/migrations/
    │
    ├── _init/          ──────▶  Runs ONCE (first time only)
    │
    ├── _pre/           ──────▶  Runs BEFORE each version
    │
    ├── v0.00/          ──────┐
    │   └── 001_*.sql         │
    │                         │  Applied in version order
    ├── v0.01/          ──────┤  (only NEW versions)
    │   ├── 001_*.sql         │
    │   └── 002_*.sql         │
    │                         │
    ├── v0.02/          ──────┘
    │   └── 001_*.sql
    │
    ├── _post/          ──────▶  Runs AFTER each version
    │
    ├── _draft/         ──────▶  SKIPPED (work in progress)
    │
    └── _erase/         ──────▶  Only with 'yuniql erase'


┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATABASE SCHEMA                                 │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────┐
    │                    PostgreSQL Database                       │
    │  ┌────────────────────────────────────────────────────────┐ │
    │  │                     app schema                          │ │
    │  │                                                         │ │
    │  │  ┌──────────┐    ┌────────────┐    ┌──────────────┐    │ │
    │  │  │  users   │    │ categories │    │   products   │    │ │
    │  │  ├──────────┤    ├────────────┤    ├──────────────┤    │ │
    │  │  │ id       │    │ id         │    │ id           │    │ │
    │  │  │ email    │    │ name       │◀───│ category_id  │    │ │
    │  │  │ username │    │ parent_id  │    │ sku          │    │ │
    │  │  │ ...      │    │ ...        │    │ price        │    │ │
    │  │  └──────────┘    └────────────┘    └──────────────┘    │ │
    │  │        │                                   │            │ │
    │  │        │         ┌────────────┐            │            │ │
    │  │        │         │   orders   │            │            │ │
    │  │        │         ├────────────┤            │            │ │
    │  │        └────────▶│ user_id    │            │            │ │
    │  │                  │ status     │            │            │ │
    │  │                  │ total      │            │            │ │
    │  │                  └────────────┘            │            │ │
    │  │                        │                   │            │ │
    │  │                        ▼                   │            │ │
    │  │                ┌──────────────┐            │            │ │
    │  │                │ order_items  │◀───────────┘            │ │
    │  │                ├──────────────┤                         │ │
    │  │                │ order_id     │                         │ │
    │  │                │ product_id   │                         │ │
    │  │                │ quantity     │                         │ │
    │  │                └──────────────┘                         │ │
    │  │                                                         │ │
    │  │  ┌──────────────┐    ┌───────────────────────────────┐ │ │
    │  │  │  audit_log   │    │           VIEWS               │ │ │
    │  │  ├──────────────┤    │  • v_product_inventory        │ │ │
    │  │  │ table_name   │    │  • v_order_summary            │ │ │
    │  │  │ old_values   │    │  • v_dashboard_stats          │ │ │
    │  │  │ new_values   │    └───────────────────────────────┘ │ │
    │  │  └──────────────┘                                      │ │
    │  └────────────────────────────────────────────────────────┘ │
    └─────────────────────────────────────────────────────────────┘
```

---

## What is Yuniql?

**Yuniql** is a SQL-first database migration tool. Unlike ORM-based migrations, you write plain SQL scripts that are versioned and executed in order.

| Feature | Description |
|---------|-------------|
| **SQL-First** | Write native SQL - no ORM, no code generation |
| **Version Controlled** | Track migrations in Git alongside your code |
| **Idempotent** | Safe to re-run - only applies new versions |
| **Multi-Platform** | PostgreSQL, SQL Server, MySQL, and more |
| **CI/CD Ready** | Works with Docker, GitHub Actions, Azure DevOps |

---

## Project Structure

```
yuniql-postgres-github-actions-sample/
│
├── .github/
│   └── workflows/
│       └── migrate.yml              # GitHub Actions workflow
│
├── db/
│   └── migrations/
│       ├── _init/                   # One-time setup scripts
│       ├── _pre/                    # Pre-version hooks
│       ├── _post/                   # Post-version hooks
│       ├── _draft/                  # Work-in-progress (skipped)
│       ├── _erase/                  # Cleanup scripts
│       ├── v0.00/                   # Initial schema
│       │   └── 001_create_schema_and_initial_tables.sql
│       ├── v0.01/                   # Orders feature
│       │   ├── 001_add_orders_tables.sql
│       │   └── 002_seed_sample_data.sql
│       └── v0.02/                   # Audit & reporting
│           └── 001_add_audit_and_views.sql
│
├── scripts/
│   ├── run-local.sh                 # Local runner (Linux/Mac)
│   ├── run-local.ps1                # Local runner (Windows)
│   └── .env.example                 # Environment template
│
├── docker/
│   └── Dockerfile.yuniql            # Pre-built Yuniql image
│
├── .gitignore
├── CHANGELOG.md                     # Version history
├── CONTRIBUTING.md                  # Contribution guide
├── LICENSE                          # MIT License
├── README.md                        # This file
└── WALKTHROUGH.md                   # Step-by-step tutorial
```

---

## Quick Start

### Prerequisites

| Requirement | Purpose |
|-------------|---------|
| Docker | Run migrations locally |
| PostgreSQL | Target database (local or cloud) |
| Git | Version control |
| GitHub Account | CI/CD (optional) |

### Option 1: Run Locally

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/yuniql-postgres-github-actions-sample.git
cd yuniql-postgres-github-actions-sample

# 2. Start a local PostgreSQL (if needed)
docker run -d --name postgres-local \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sample_db \
  -p 5432:5432 \
  postgres:15

# 3. Configure environment
cp scripts/.env.example scripts/.env
# Edit scripts/.env with your credentials

# 4. Run migrations
chmod +x scripts/run-local.sh
./scripts/run-local.sh
```

### Option 2: GitHub Actions

1. **Add repository secrets:**

   | Secret | Value |
   |--------|-------|
   | `DB_HOST` | Your PostgreSQL host |
   | `DB_USER` | Database username |
   | `DB_PASSWORD` | Database password |
   | `DB_NAME` | Database name |

2. **Push to trigger:**
   ```bash
   git push origin main
   ```

3. **Or manually trigger** from the Actions tab

---

## GitHub Actions Workflow

The workflow (`.github/workflows/migrate.yml`) provides:

```yaml
Triggers:
  - Push to main (when db/migrations/** changes)
  - Manual dispatch (workflow_dispatch)

Steps:
  1. Checkout repository
  2. Setup .NET SDK (6.0 + 8.0)
  3. Install Yuniql CLI
  4. Run migrations with debug option
```

### Required Secrets

| Secret | Example | Description |
|--------|---------|-------------|
| `DB_HOST` | `db.example.com` | Database hostname |
| `DB_USER` | `app_user` | Database username |
| `DB_PASSWORD` | `********` | Database password |
| `DB_NAME` | `production_db` | Database name |

---

## Writing Migrations

### Naming Convention

```
v{MAJOR}.{MINOR}/
└── {ORDER}_{description}.sql

Examples:
├── v0.00/001_create_users.sql       # First ever migration
├── v0.01/001_add_orders.sql         # Feature: orders
├── v0.01/002_seed_data.sql          # Same version, runs after 001
└── v0.02/001_add_indexes.sql        # Performance improvements
```

### Idempotent Scripts

Always use `IF NOT EXISTS` / `IF EXISTS`:

```sql
-- Good: Safe to re-run
CREATE TABLE IF NOT EXISTS app.users (...);
CREATE INDEX IF NOT EXISTS idx_users_email ON app.users(email);

-- Bad: Will fail on re-run
CREATE TABLE app.users (...);
```

### Special Folders

| Folder | When it Runs | Use Case |
|--------|--------------|----------|
| `_init/` | Once, before first version | Database setup, extensions |
| `_pre/` | Before each version | Disable triggers, locks |
| `_post/` | After each version | Re-enable triggers, notifications |
| `_draft/` | Never (skipped) | Work in progress |
| `_erase/` | Only with `yuniql erase` | Complete cleanup |

---

## Best Practices

| Practice | Reason |
|----------|--------|
| Use `IF NOT EXISTS` | Makes scripts idempotent |
| One change per script | Easier debugging and rollback |
| Never modify applied migrations | Create new versions instead |
| Use dedicated schema | Isolate from public schema |
| Test locally first | Catch errors before CI/CD |
| Add comments | Document purpose and decisions |

---

## Troubleshooting

<details>
<summary><strong>"Migrations already applied"</strong></summary>

This is expected behavior. Yuniql tracks applied versions in `__yuniql_schema_version` table and only runs new versions.

```sql
-- Check applied versions
SELECT * FROM public.__yuniql_schema_version ORDER BY version;
```
</details>

<details>
<summary><strong>"Connection refused"</strong></summary>

- Verify host and port in connection string
- Check firewall/security group rules
- For AWS RDS: ensure inbound rules allow your IP
- For SSL: add `SSL Mode=Require;Trust Server Certificate=true`
</details>

<details>
<summary><strong>"Permission denied"</strong></summary>

Database user needs sufficient privileges:
```sql
GRANT CREATE, USAGE ON SCHEMA app TO your_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app TO your_user;
```
</details>

<details>
<summary><strong>".NET 6.0 required"</strong></summary>

Yuniql CLI v1.3.15 requires .NET 6.0 runtime. The workflow installs both 6.0 and 8.0.
</details>

---

## Resources

| Resource | Link |
|----------|------|
| Yuniql Documentation | [yuniql.io/docs](https://yuniql.io/docs/) |
| Yuniql GitHub | [github.com/rdagumern/yuniql](https://github.com/rdagumern/yuniql) |
| PostgreSQL Docs | [postgresql.org/docs](https://www.postgresql.org/docs/) |
| GitHub Actions | [docs.github.com/actions](https://docs.github.com/en/actions) |

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

<p align="center">
  <sub>Built with SQL and automated with GitHub Actions</sub>
</p>
