# Yuniql Walkthrough: Complete Beginner's Guide

Welcome! This guide will take you from zero knowledge to confidently managing database migrations with Yuniql, PostgreSQL, and GitHub Actions.

---

## Table of Contents

1. [Understanding Database Migrations](#1-understanding-database-migrations)
2. [What is Yuniql?](#2-what-is-yuniql)
3. [How Yuniql Works](#3-how-yuniql-works)
4. [Project Structure Explained](#4-project-structure-explained)
5. [Your First Migration](#5-your-first-migration)
6. [Running Migrations Locally](#6-running-migrations-locally)
7. [Automating with GitHub Actions](#7-automating-with-github-actions)
8. [Adding New Migrations](#8-adding-new-migrations)
9. [Common Scenarios](#9-common-scenarios)
10. [Glossary](#10-glossary)

---

## 1. Understanding Database Migrations

### What is a Database Migration?

A **database migration** is a version-controlled change to your database schema. Think of it like Git commits, but for your database structure.

```
Without Migrations:                    With Migrations:
─────────────────                      ────────────────
Developer A: "I added a column"        v0.01: Add email column
Developer B: "What column?"            v0.02: Add created_at column
DBA: "Production is different!"        v0.03: Add index on email
                                       
❌ Confusion, errors                   ✅ Clear history, reproducible
```

### Why Use Migrations?

| Problem | Migration Solution |
|---------|-------------------|
| "Works on my machine" | Same scripts run everywhere |
| "What changed in production?" | Git history shows every change |
| "How do I set up a new environment?" | Run all migrations from v0.00 |
| "Who made this change?" | Git blame shows author |

---

## 2. What is Yuniql?

**Yuniql** (pronounced "yoo-nickle") is a database migration tool that is:

### SQL-First

You write **native SQL** scripts. No learning a new language or ORM.

```sql
-- This is a Yuniql migration. Just SQL!
CREATE TABLE IF NOT EXISTS app.users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);
```

### Version-Based

Migrations live in numbered folders:

```
db/migrations/
├── v0.00/    ← Version 0.0 (initial)
├── v0.01/    ← Version 0.1 (feature A)
├── v0.02/    ← Version 0.2 (feature B)
```

### Idempotent

**Idempotent** means "safe to run multiple times with the same result."

```
First run:   v0.00 ✅  v0.01 ✅  v0.02 ✅
Second run:  v0.00 ⏭️  v0.01 ⏭️  v0.02 ⏭️  (skipped - already applied)
Third run:   v0.00 ⏭️  v0.01 ⏭️  v0.02 ⏭️  (skipped - already applied)
```

---

## 3. How Yuniql Works

### The Version Tracking Table

When Yuniql runs for the first time, it creates a special table:

```sql
public.__yuniql_schema_version
┌─────────┬─────────────────────┬────────────────────┐
│ version │ applied_on          │ applied_by         │
├─────────┼─────────────────────┼────────────────────┤
│ v0.00   │ 2026-01-27 10:00:00 │ github-actions     │
│ v0.01   │ 2026-01-27 10:00:05 │ github-actions     │
│ v0.02   │ 2026-01-28 14:30:00 │ github-actions     │
└─────────┴─────────────────────┴────────────────────┘
```

This table tracks which versions have been applied. Yuniql checks this before running.

### Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     YUNIQL EXECUTION FLOW                        │
└─────────────────────────────────────────────────────────────────┘

       START
         │
         ▼
   ┌───────────────┐
   │ Connect to DB │
   └───────┬───────┘
           │
           ▼
   ┌───────────────────────────────┐
   │ Check __yuniql_schema_version │
   │ (create if not exists)        │
   └───────────────┬───────────────┘
                   │
                   ▼
   ┌───────────────────────────────┐     ┌─────────────┐
   │ Any unapplied versions?       │─NO─▶│ Done!       │
   └───────────────┬───────────────┘     │ (no work)   │
                   │ YES                  └─────────────┘
                   ▼
   ┌───────────────────────────────┐
   │ For each unapplied version:   │
   │                               │
   │  1. Run _pre/ scripts         │
   │  2. Run version scripts       │
   │     (001_*.sql, 002_*.sql)    │
   │  3. Run _post/ scripts        │
   │  4. Record in version table   │
   │                               │
   └───────────────┬───────────────┘
                   │
                   ▼
   ┌───────────────────────────────┐
   │ All versions applied!         │
   └───────────────────────────────┘
```

---

## 4. Project Structure Explained

Let's examine each part of the project:

```
yuniql-postgres-github-actions-sample/
│
├── .github/workflows/migrate.yml    ← CI/CD automation
│
├── db/migrations/                   ← ALL YOUR MIGRATIONS LIVE HERE
│   │
│   ├── _init/                       ← Runs ONCE, before everything
│   │   └── .gitkeep                    Example: CREATE EXTENSION pgcrypto;
│   │
│   ├── _pre/                        ← Runs BEFORE each version
│   │   └── .gitkeep                    Example: LOCK tables
│   │
│   ├── _post/                       ← Runs AFTER each version
│   │   └── .gitkeep                    Example: NOTIFY applications
│   │
│   ├── _draft/                      ← ALWAYS SKIPPED
│   │   └── .gitkeep                    Use for: work in progress
│   │
│   ├── _erase/                      ← Only with 'yuniql erase'
│   │   └── .gitkeep                    Use for: DROP ALL tables
│   │
│   ├── v0.00/                       ← Version 0.0: Initial Setup
│   │   └── 001_create_schema_and_initial_tables.sql
│   │
│   ├── v0.01/                       ← Version 0.1: Orders Feature
│   │   ├── 001_add_orders_tables.sql
│   │   └── 002_seed_sample_data.sql
│   │
│   └── v0.02/                       ← Version 0.2: Audit & Views
│       └── 001_add_audit_and_views.sql
│
├── scripts/                         ← Helper scripts
│   ├── run-local.sh                    Linux/Mac runner
│   ├── run-local.ps1                   Windows runner
│   └── .env.example                    Template for credentials
│
└── docker/
    └── Dockerfile.yuniql            ← Pre-built Yuniql image
```

### Special Folders Deep Dive

| Folder | Runs When | Common Use Cases |
|--------|-----------|------------------|
| `_init/` | Once ever, before v0.00 | Extensions, roles, initial permissions |
| `_pre/` | Before EACH version | Disable triggers, acquire locks |
| `_post/` | After EACH version | Re-enable triggers, send notifications |
| `_draft/` | Never | Scripts you're still writing |
| `_erase/` | Only with `yuniql erase` | Complete database cleanup |

---

## 5. Your First Migration

Let's create a simple migration step by step.

### Step 1: Create a Version Folder

```bash
mkdir -p db/migrations/v0.03
```

### Step 2: Write Your SQL Script

Create `db/migrations/v0.03/001_add_user_settings.sql`:

```sql
-- =============================================================================
-- Version: v0.03
-- Description: Add user settings table
-- Author: Your Name
-- Date: 2026-01-27
-- =============================================================================

-- Create the settings table
CREATE TABLE IF NOT EXISTS app.user_settings (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    setting_key     VARCHAR(100) NOT NULL,
    setting_value   TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Each user can have each setting only once
    UNIQUE(user_id, setting_key)
);

-- Add helpful comment
COMMENT ON TABLE app.user_settings IS 'User-specific application settings';

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id 
    ON app.user_settings(user_id);

-- Log what we did (optional, for debugging)
DO $$
BEGIN
    RAISE NOTICE 'v0.03: Created user_settings table';
END $$;
```

### Step 3: Key Points to Remember

```
✅ DO:
   • Use IF NOT EXISTS / IF EXISTS
   • Add comments explaining why
   • Use consistent naming (snake_case)
   • Include proper constraints (FK, UNIQUE, CHECK)

❌ DON'T:
   • Modify previously applied migrations
   • Use database-specific features without checking compatibility
   • Forget to add indexes for foreign keys
```

---

## 6. Running Migrations Locally

### Prerequisites

1. **Docker** installed and running
2. **PostgreSQL** database accessible

### Option A: Using the Helper Script

```bash
# 1. Copy environment template
cp scripts/.env.example scripts/.env

# 2. Edit with your credentials
nano scripts/.env  # or use your preferred editor

# 3. Make script executable and run
chmod +x scripts/run-local.sh
./scripts/run-local.sh
```

### Option B: Using Docker Directly

```bash
docker run --rm \
  -v $(pwd)/db/migrations:/db \
  mcr.microsoft.com/dotnet/sdk:8.0 \
  bash -c "
    dotnet tool install -g yuniql.cli --version 1.3.15
    export PATH=\"\$PATH:/root/.dotnet/tools\"
    yuniql run \
      --platform postgresql \
      --connection-string 'Host=localhost;Port=5432;Database=sample_db;Username=postgres;Password=postgres' \
      --path /db \
      --auto-create-db false \
      --debug
  "
```

### Understanding the Output

```
==========================================
Yuniql Local Migration Runner
==========================================
Database: sample_db @ localhost:5432
Migrations: /path/to/db/migrations
Yuniql Version: 1.3.15
------------------------------------------

INF Running migrations from /db
INF Target platform: postgresql
INF Found versions: v0.00, v0.01, v0.02

INF Applying v0.00...
INF   Executed: 001_create_schema_and_initial_tables.sql
INF   Completed v0.00 in 145ms

INF Applying v0.01...
INF   Executed: 001_add_orders_tables.sql
INF   Executed: 002_seed_sample_data.sql
INF   Completed v0.01 in 89ms

INF Applying v0.02...
INF   Executed: 001_add_audit_and_views.sql
INF   Completed v0.02 in 67ms

------------------------------------------
Migrations completed successfully!
```

---

## 7. Automating with GitHub Actions

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS WORKFLOW                       │
└─────────────────────────────────────────────────────────────────┘

  Developer pushes to main branch
           │
           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ GitHub detects changes in db/migrations/**                  │
  │                                                              │
  │ Triggers: .github/workflows/migrate.yml                     │
  └─────────────────────────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ GitHub Runner (ubuntu-latest)                               │
  │                                                              │
  │ Step 1: actions/checkout@v4                                 │
  │         └─▶ Clones your repository                          │
  │                                                              │
  │ Step 2: actions/setup-dotnet@v4                             │
  │         └─▶ Installs .NET 6.0 and 8.0                       │
  │                                                              │
  │ Step 3: dotnet tool install yuniql.cli                      │
  │         └─▶ Installs Yuniql CLI                             │
  │                                                              │
  │ Step 4: yuniql run                                          │
  │         └─▶ Connects to DB using secrets                    │
  │         └─▶ Applies pending migrations                      │
  └─────────────────────────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────────────────────────┐
  │ PostgreSQL Database                                          │
  │                                                              │
  │ ✅ New tables/columns created                                │
  │ ✅ __yuniql_schema_version updated                          │
  └─────────────────────────────────────────────────────────────┘
```

### Setting Up Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:

| Secret Name | Example Value |
|-------------|---------------|
| `DB_HOST` | `mydb.us-east-1.rds.amazonaws.com` |
| `DB_USER` | `app_user` |
| `DB_PASSWORD` | `your-secure-password` |
| `DB_NAME` | `production_db` |

### Manual Trigger

You can also run migrations manually:

1. Go to **Actions** tab
2. Select **Database Migration** workflow
3. Click **Run workflow**
4. Optionally enable debug mode
5. Click **Run workflow** (green button)

---

## 8. Adding New Migrations

### Workflow for New Changes

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ 1. Create    │───▶│ 2. Write     │───▶│ 3. Test      │───▶│ 4. Commit    │
│    folder    │    │    SQL       │    │    locally   │    │    & push    │
│  (v0.XX)     │    │              │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

### Example: Adding a New Feature

```bash
# 1. Create new version folder
mkdir db/migrations/v0.03

# 2. Create your SQL file
cat > db/migrations/v0.03/001_add_reviews.sql << 'EOF'
-- Add product reviews table
CREATE TABLE IF NOT EXISTS app.reviews (
    id          SERIAL PRIMARY KEY,
    product_id  INTEGER NOT NULL REFERENCES app.products(id),
    user_id     INTEGER NOT NULL REFERENCES app.users(id),
    rating      INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_product 
    ON app.reviews(product_id);
EOF

# 3. Test locally
./scripts/run-local.sh

# 4. If successful, commit and push
git add db/migrations/v0.03/
git commit -m "feat(db): add product reviews table"
git push origin main
```

---

## 9. Common Scenarios

### Scenario 1: I need to change an existing column

**Never modify an applied migration.** Create a new version:

```sql
-- db/migrations/v0.04/001_alter_users_email.sql
ALTER TABLE app.users 
    ALTER COLUMN email TYPE VARCHAR(500);
```

### Scenario 2: I need to add data

```sql
-- db/migrations/v0.04/002_add_default_categories.sql
INSERT INTO app.categories (name, description)
VALUES 
    ('Default', 'Default category for uncategorized items')
ON CONFLICT (name) DO NOTHING;
```

### Scenario 3: I need to remove a column

```sql
-- db/migrations/v0.05/001_remove_deprecated_column.sql
ALTER TABLE app.users 
    DROP COLUMN IF EXISTS legacy_field;
```

### Scenario 4: I need to rollback

Yuniql doesn't auto-rollback. Options:

**Option A: Create compensating migration**
```sql
-- db/migrations/v0.06/001_rollback_reviews.sql
DROP TABLE IF EXISTS app.reviews;
```

**Option B: Manual intervention**
```sql
-- Run manually in database
DROP TABLE app.reviews;
DELETE FROM public.__yuniql_schema_version 
WHERE version = 'v0.03';
```

### Scenario 5: I'm working on a migration that's not ready

Use the `_draft` folder:

```
db/migrations/
├── _draft/
│   └── experimental_feature.sql    ← Won't run, safe to commit
└── v0.03/
    └── 001_ready_feature.sql       ← Will run
```

---

## 10. Glossary

| Term | Definition |
|------|------------|
| **Migration** | A version-controlled change to database schema |
| **Idempotent** | Can be run multiple times with same result |
| **Schema** | A namespace in PostgreSQL that groups tables |
| **DDL** | Data Definition Language (CREATE, ALTER, DROP) |
| **DML** | Data Manipulation Language (INSERT, UPDATE, DELETE) |
| **Version Table** | `__yuniql_schema_version` - tracks applied migrations |
| **CI/CD** | Continuous Integration/Continuous Deployment |
| **Rollback** | Reverting a migration (manual in Yuniql) |
| **Seed Data** | Initial data inserted with migrations |

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│                     YUNIQL QUICK REFERENCE                       │
└─────────────────────────────────────────────────────────────────┘

CREATE NEW MIGRATION:
  mkdir db/migrations/v0.XX
  vi db/migrations/v0.XX/001_description.sql

RUN LOCALLY:
  ./scripts/run-local.sh

CHECK VERSION:
  yuniql version

LIST APPLIED VERSIONS:
  SELECT * FROM __yuniql_schema_version ORDER BY version;

COMMON YUNIQL FLAGS:
  --platform postgresql    Target database type
  --path ./db/migrations   Path to migration scripts
  --debug                  Verbose output
  --auto-create-db false   Don't auto-create database

NAMING CONVENTIONS:
  Version folders: v0.00, v0.01, v1.00 (semantic-ish)
  Script files:    001_description.sql (numeric prefix)

GOLDEN RULES:
  ✓ Always use IF NOT EXISTS / IF EXISTS
  ✓ Never modify applied migrations
  ✓ Test locally before pushing
  ✓ One logical change per script
  ✓ Add comments explaining "why"
```

---

<p align="center">
  <strong>Happy Migrating!</strong><br>
  <sub>Questions? Open an issue on GitHub.</sub>
</p>
