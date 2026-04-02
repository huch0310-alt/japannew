-- 启用RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transactions ENABLE ROW LEVEL SECURITY;

-- Users表策略
CREATE POLICY "Users can view their own data"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Super admin can manage all users"
    ON users FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

CREATE POLICY "Sales manager can view all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- Customers表策略
CREATE POLICY "Customers can view own profile"
    ON customers FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Sales can view all customers"
    ON customers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

CREATE POLICY "Super admin can manage customers"
    ON customers FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Categories表策略（公开读取）
CREATE POLICY "Anyone can view categories"
    ON categories FOR SELECT
    USING (true);

CREATE POLICY "Sales can manage categories"
    ON categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- Products表策略
CREATE POLICY "Approved products visible to all authenticated"
    ON products FOR SELECT
    USING (
        status = 'approved'
        OR submitted_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager', 'purchaser')
        )
    );

CREATE POLICY "Purchaser can insert own products"
    ON products FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'purchaser'
        )
        AND submitted_by = auth.uid()
    );

CREATE POLICY "Purchaser can update own pending products"
    ON products FOR UPDATE
    USING (
        submitted_by = auth.uid()
        AND status = 'pending'
    );

CREATE POLICY "Sales can approve/reject products"
    ON products FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- Orders表策略
CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_id = auth.uid());

CREATE POLICY "Sales can view all orders"
    ON orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

CREATE POLICY "Customers can create orders"
    ON orders FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'customer'
        )
        AND customer_id = auth.uid()
    );

CREATE POLICY "Sales can update orders"
    ON orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- Order Items策略
CREATE POLICY "Customers can create order items with their order"
    ON order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_id
            AND o.customer_id = auth.uid()
        )
    );

CREATE POLICY "Users can view order items"
    ON order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_id
            AND (
                o.customer_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM users
                    WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
                )
            )
        )
    );

-- Invoices策略
CREATE POLICY "Customers can view own invoices"
    ON invoices FOR SELECT
    USING (customer_id = auth.uid());

CREATE POLICY "Sales can manage invoices"
    ON invoices FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- System Settings策略（仅管理员可读写）
CREATE POLICY "Only super admin can access system settings"
    ON system_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Stock Transactions策略
CREATE POLICY "Sales can view stock transactions"
    ON stock_transactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

CREATE POLICY "System can insert stock transactions"
    ON stock_transactions FOR INSERT
    WITH CHECK (true);
