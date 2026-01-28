-- =============================================================================
-- Version: v0.02
-- Description: Add audit logging and reporting views
-- =============================================================================

-- =============================================================================
-- Audit log table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.audit_log (
    id              SERIAL PRIMARY KEY,
    table_name      VARCHAR(100) NOT NULL,
    record_id       INTEGER NOT NULL,
    action          VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values      JSONB,
    new_values      JSONB,
    changed_by      VARCHAR(100),
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.audit_log IS 'Audit trail for important table changes';

CREATE INDEX IF NOT EXISTS idx_audit_log_table_record 
    ON app.audit_log(table_name, record_id);

CREATE INDEX IF NOT EXISTS idx_audit_log_changed_at 
    ON app.audit_log(changed_at DESC);

-- =============================================================================
-- Product inventory view
-- =============================================================================
CREATE OR REPLACE VIEW app.v_product_inventory AS
SELECT 
    p.id,
    p.sku,
    p.name,
    p.price,
    p.quantity,
    p.quantity * p.price AS inventory_value,
    c.name AS category_name,
    CASE 
        WHEN p.quantity = 0 THEN 'Out of Stock'
        WHEN p.quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    p.is_active
FROM app.products p
LEFT JOIN app.categories c ON p.category_id = c.id;

COMMENT ON VIEW app.v_product_inventory IS 'Product inventory with stock status';

-- =============================================================================
-- Order summary view
-- =============================================================================
CREATE OR REPLACE VIEW app.v_order_summary AS
SELECT 
    o.id AS order_id,
    o.order_number,
    u.email AS customer_email,
    u.first_name || ' ' || u.last_name AS customer_name,
    o.status,
    COUNT(oi.id) AS item_count,
    SUM(oi.subtotal) AS calculated_total,
    o.total_amount,
    o.ordered_at,
    o.updated_at
FROM app.orders o
JOIN app.users u ON o.user_id = u.id
LEFT JOIN app.order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_number, u.email, u.first_name, u.last_name, 
         o.status, o.total_amount, o.ordered_at, o.updated_at;

COMMENT ON VIEW app.v_order_summary IS 'Order summary with customer info';

-- =============================================================================
-- Dashboard statistics view
-- =============================================================================
CREATE OR REPLACE VIEW app.v_dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM app.users WHERE is_active = true) AS active_users,
    (SELECT COUNT(*) FROM app.products WHERE is_active = true) AS active_products,
    (SELECT COUNT(*) FROM app.orders WHERE status != 'cancelled') AS total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM app.orders WHERE status = 'delivered') AS total_revenue,
    (SELECT COUNT(*) FROM app.products WHERE quantity = 0) AS out_of_stock_products,
    (SELECT COUNT(*) FROM app.orders WHERE status = 'pending') AS pending_orders;

COMMENT ON VIEW app.v_dashboard_stats IS 'Quick statistics for dashboard';

-- =============================================================================
-- Additional indexes for performance
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_users_email 
    ON app.users(email);

CREATE INDEX IF NOT EXISTS idx_users_username 
    ON app.users(username);

CREATE INDEX IF NOT EXISTS idx_products_sku 
    ON app.products(sku);

CREATE INDEX IF NOT EXISTS idx_products_category 
    ON app.products(category_id);

CREATE INDEX IF NOT EXISTS idx_products_active 
    ON app.products(is_active) WHERE is_active = true;

-- =============================================================================
-- Version tracking (informational)
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE 'v0.02: Created audit_log table and reporting views';
END $$;
