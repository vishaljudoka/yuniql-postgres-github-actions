-- =============================================================================
-- Version: v0.01
-- Description: Seed sample data for development/testing
-- =============================================================================

-- =============================================================================
-- Sample Categories
-- =============================================================================
INSERT INTO app.categories (name, description)
VALUES 
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Apparel and fashion items'),
    ('Books', 'Physical and digital books'),
    ('Home & Garden', 'Home improvement and garden supplies')
ON CONFLICT (name) DO NOTHING;

-- Add subcategories
INSERT INTO app.categories (name, description, parent_id)
SELECT 'Smartphones', 'Mobile phones and accessories', id 
FROM app.categories WHERE name = 'Electronics'
ON CONFLICT (name) DO NOTHING;

INSERT INTO app.categories (name, description, parent_id)
SELECT 'Laptops', 'Notebook computers', id 
FROM app.categories WHERE name = 'Electronics'
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- Sample Products
-- =============================================================================
INSERT INTO app.products (sku, name, description, price, quantity, category_id)
SELECT 
    'PHONE-001',
    'Smartphone Pro X',
    'Latest flagship smartphone with advanced features',
    999.99,
    50,
    id
FROM app.categories WHERE name = 'Smartphones'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO app.products (sku, name, description, price, quantity, category_id)
SELECT 
    'LAPTOP-001',
    'Developer Laptop 15"',
    'High-performance laptop for developers',
    1499.99,
    25,
    id
FROM app.categories WHERE name = 'Laptops'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO app.products (sku, name, description, price, quantity, category_id)
SELECT 
    'BOOK-001',
    'Database Design Fundamentals',
    'Comprehensive guide to database design',
    49.99,
    100,
    id
FROM app.categories WHERE name = 'Books'
ON CONFLICT (sku) DO NOTHING;

-- =============================================================================
-- Sample User (password: 'sample123' - DO NOT use in production!)
-- =============================================================================
INSERT INTO app.users (email, username, password_hash, first_name, last_name)
VALUES (
    'demo@example.com',
    'demo_user',
    '$2a$10$sample.hash.for.demo.purposes.only',
    'Demo',
    'User'
)
ON CONFLICT (email) DO NOTHING;

-- =============================================================================
-- Version tracking (informational)
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE 'v0.01: Seeded sample categories, products, and demo user';
END $$;
