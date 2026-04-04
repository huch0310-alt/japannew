-- =====================================================
-- FreshBiz 日本B2B生鲜销售系统 - Supabase 数据库结构
-- =====================================================

-- 启用 UUID 生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. 用户表 (统一认证)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    password_hash TEXT,
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'sales_manager', 'purchaser', 'customer')),
    name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 策略
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己的信息
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- 管理员可以查看所有用户
CREATE POLICY "Admins can view all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- 管理员可以创建用户
CREATE POLICY "Admins can create users"
    ON users FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- 管理员可以更新用户
CREATE POLICY "Admins can update users"
    ON users FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 2. 客户档案表
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    company_name_zh TEXT,
    tax_id TEXT,
    postal_code TEXT,
    address TEXT,
    address_zh TEXT,
    contact_name TEXT,
    phone TEXT,
    discount_rate NUMERIC(5, 2) DEFAULT 0,
    payment_term_days INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- 客户可以查看自己的信息
CREATE POLICY "Customers can view own profile"
    ON customers FOR SELECT
    USING (id = auth.uid());

-- 管理员可以管理所有客户
CREATE POLICY "Admins can manage customers"
    ON customers FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 3. 商品分类表
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ja TEXT NOT NULL,
    name_zh TEXT,
    parent_id UUID REFERENCES categories(id),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- 所有人可以查看分类
CREATE POLICY "Anyone can view categories"
    ON categories FOR SELECT
    TO authenticated
    USING (true);

-- 管理员可以管理分类
CREATE POLICY "Admins can manage categories"
    ON categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 4. 商品表
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    name_ja TEXT NOT NULL,
    name_zh TEXT,
    category_id UUID REFERENCES categories(id),
    unit TEXT NOT NULL DEFAULT '個',
    purchase_price INTEGER NOT NULL DEFAULT 0,
    sale_price_ex_tax INTEGER NOT NULL DEFAULT 0,
    stock INTEGER DEFAULT 0,
    stock_warning INTEGER DEFAULT 10,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    submitted_by UUID REFERENCES users(id),
    reject_reason TEXT,
    images TEXT[],
    description_ja TEXT,
    description_zh TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 所有人可以查看已批准的商品
CREATE POLICY "Anyone can view approved products"
    ON products FOR SELECT
    TO authenticated
    USING (status = 'approved');

-- 采购人员可以查看自己提交的商品
CREATE POLICY "Purchasers can view own products"
    ON products FOR SELECT
    USING (submitted_by = auth.uid());

-- 管理员可以管理所有商品
CREATE POLICY "Admins can manage products"
    ON products FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- 采购人员可以提交商品
CREATE POLICY "Purchasers can submit products"
    ON products FOR INSERT
    WITH CHECK (
        submitted_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 5. 订单表
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number TEXT UNIQUE NOT NULL,
    customer_id UUID REFERENCES users(id) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'printed', 'invoiced', 'paid', 'cancelled')),
    total_ex_tax INTEGER DEFAULT 0,
    tax_amount INTEGER DEFAULT 0,
    total_in_tax INTEGER DEFAULT 0,
    customer_note TEXT,
    printed_by UUID REFERENCES users(id),
    printed_at TIMESTAMPTZ,
    invoice_id UUID REFERENCES invoices(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 客户可以查看自己的订单
CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_id = auth.uid());

-- 员工可以查看所有订单
CREATE POLICY "Staff can view all orders"
    ON orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager', 'purchaser')
        )
    );

-- 客户可以创建订单
CREATE POLICY "Customers can create orders"
    ON orders FOR INSERT
    WITH CHECK (customer_id = auth.uid());

-- 管理员可以更新订单
CREATE POLICY "Admins can update orders"
    ON orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 6. 订单明细表
-- =====================================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES products(id) NOT NULL,
    product_name TEXT,
    quantity NUMERIC NOT NULL DEFAULT 1,
    unit_price_ex_tax INTEGER DEFAULT 0,
    discounted_price INTEGER DEFAULT 0,
    line_total_ex_tax INTEGER DEFAULT 0,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- 订单相关人员可以查看订单明细
CREATE POLICY "Related users can view order items"
    ON order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM orders o
            WHERE o.id = order_id AND (
                o.customer_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM users
                    WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
                )
            )
        )
    );

-- =====================================================
-- 7. 请求书表
-- =====================================================
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number TEXT UNIQUE NOT NULL,
    customer_id UUID REFERENCES users(id) NOT NULL,
    total_in_tax INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid', 'overdue')),
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    paid_at TIMESTAMPTZ,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- 客户可以查看自己的请求书
CREATE POLICY "Customers can view own invoices"
    ON invoices FOR SELECT
    USING (customer_id = auth.uid());

-- 员工可以查看所有请求书
CREATE POLICY "Staff can view all invoices"
    ON invoices FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- 管理员可以创建请求书
CREATE POLICY "Admins can create invoices"
    ON invoices FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- 管理员可以更新请求书
CREATE POLICY "Admins can update invoices"
    ON invoices FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('super_admin', 'sales_manager')
        )
    );

-- =====================================================
-- 8. 系统设置表
-- =====================================================
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name TEXT DEFAULT 'FreshBiz株式会社',
    company_address TEXT,
    company_phone TEXT,
    tax_id TEXT,
    bank_name TEXT,
    bank_branch TEXT,
    bank_account_type TEXT DEFAULT '普通',
    bank_account_number TEXT,
    tax_rate NUMERIC(3, 2) DEFAULT 0.08,
    default_payment_term_days INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- 管理员可以查看和修改系统设置
CREATE POLICY "Admins can manage system settings"
    ON system_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- =====================================================
-- 初始化数据
-- =====================================================

-- 插入默认系统设置（只有一行）
INSERT INTO system_settings (company_name, company_address, company_phone, tax_rate)
VALUES ('FreshBiz株式会社', '大阪府大阪市北区梅田1-1-1', '06-1234-5678', 0.08)
ON CONFLICT DO NOTHING;

-- 插入默认分类
INSERT INTO categories (name_ja, name_zh, sort_order) VALUES
    ('野菜', '蔬菜', 1),
    ('精肉', '精肉', 2),
    ('鮮魚', '鲜鱼', 3),
    ('果物', '水果', 4)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 辅助函数
-- =====================================================

-- 自动生成订单号
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.order_number := 'ORD' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || RIGHT(NEW.id::TEXT, 6);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 自动生成请求书号
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
    seq_num INTEGER;
    prefix TEXT;
BEGIN
    prefix := 'Q' || TO_CHAR(NEW.issue_date, 'YYYYMMDD');
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(invoice_number FROM LENGTH(prefix) + 2) AS INTEGER)
    ), 0) + 1 INTO seq_num
    FROM invoices
    WHERE invoice_number LIKE prefix || '%';

    NEW.invoice_number := prefix || '-' || LPAD(seq_num::TEXT, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 更新时间戳
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要自动更新 updated_at 的表创建触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 订单创建时生成订单号
CREATE TRIGGER generate_order_number_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- 请求书创建时生成请求书号
CREATE TRIGGER generate_invoice_number_trigger
    BEFORE INSERT ON invoices
    FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();
