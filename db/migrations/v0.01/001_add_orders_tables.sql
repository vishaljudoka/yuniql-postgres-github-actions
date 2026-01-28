-- =============================================================================
-- Version: v0.01
-- Description: Add orders and order items tables
-- =============================================================================

-- =============================================================================
-- Orders table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.orders (
    id              SERIAL PRIMARY KEY,
    order_number    VARCHAR(50) NOT NULL UNIQUE,
    user_id         INTEGER NOT NULL REFERENCES app.users(id),
    status          VARCHAR(20) DEFAULT 'pending' 
                    CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
    total_amount    DECIMAL(12, 2) NOT NULL DEFAULT 0,
    shipping_address TEXT,
    notes           TEXT,
    ordered_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.orders IS 'Customer orders';

-- =============================================================================
-- Order items table
-- =============================================================================
CREATE TABLE IF NOT EXISTS app.order_items (
    id              SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES app.orders(id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES app.products(id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      DECIMAL(10, 2) NOT NULL,
    subtotal        DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE app.order_items IS 'Individual items within an order';

-- =============================================================================
-- Add indexes for common queries
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_orders_user_id 
    ON app.orders(user_id);

CREATE INDEX IF NOT EXISTS idx_orders_status 
    ON app.orders(status);

CREATE INDEX IF NOT EXISTS idx_orders_ordered_at 
    ON app.orders(ordered_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
    ON app.order_items(order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id 
    ON app.order_items(product_id);

-- =============================================================================
-- Version tracking (informational)
-- =============================================================================
DO $$
BEGIN
    RAISE NOTICE 'v0.01: Created tables: orders, order_items with indexes';
END $$;
