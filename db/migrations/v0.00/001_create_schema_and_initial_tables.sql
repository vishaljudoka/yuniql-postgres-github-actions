-- =============================================================================
-- Version: v0.00
-- Description: Initial schema and tables setup
-- =============================================================================

-- Create application schema (isolates our tables from public schema)
CREATE SCHEMA IF NOT EXISTS app;

-- =============================================================================
-- Users table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL UNIQUE,
    username        VARCHAR(50) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.users IS 'Application users';
COMMENT ON COLUMN app.users.password_hash IS 'Bcrypt hashed password';

-- =============================================================================
-- Categories table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.categories (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    parent_id       INTEGER REFERENCES app.categories(id),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.categories IS 'Product categories with hierarchical support';

-- =============================================================================
-- Products table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.products (
    id              SERIAL PRIMARY KEY,
    sku             VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    price           DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    quantity        INTEGER DEFAULT 0 CHECK (quantity >= 0),
    category_id     INTEGER REFERENCES app.categories(id),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.products IS 'Product catalog';

-- =============================================================================
-- Version tracking (informational)
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE 'v0.00: Created schema "app" with tables: users, categories, products';
END $$;
