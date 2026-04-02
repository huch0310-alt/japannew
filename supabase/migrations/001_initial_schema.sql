-- Japan B2B Fresh Sales System - Initial Schema
-- Migration: 001_initial_schema.sql

-- Step 1: Create enums
-- 用户角色枚举
CREATE TYPE user_role AS ENUM ('super_admin', 'sales_manager', 'purchaser', 'customer');

-- 商品状态枚举
CREATE TYPE product_status AS ENUM ('pending', 'approved', 'rejected');

-- 订单状态枚举
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'printed', 'invoiced', 'paid', 'cancelled');

-- 请求书状态枚举
CREATE TYPE invoice_status AS ENUM ('unpaid', 'paid', 'overdue');

-- 商品单位枚举
CREATE TYPE product_unit AS ENUM ('個', 'kg', 'g', '袋', '箱', '束', '本');

-- Step 2: Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'customer',
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);

-- Step 3: Create customers table
CREATE TABLE customers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    company_name_zh TEXT,
    tax_id TEXT,
    postal_code TEXT,
    address TEXT,
    address_zh TEXT,
    contact_name TEXT,
    discount_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
    payment_term_days INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Step 4: Create categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ja TEXT NOT NULL,
    name_zh TEXT,
    parent_id UUID REFERENCES categories(id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);

-- Step 5: Create products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name_ja TEXT NOT NULL,
    name_zh TEXT,
    category_id UUID REFERENCES categories(id),
    unit product_unit NOT NULL DEFAULT '個',
    purchase_price INTEGER NOT NULL DEFAULT 0,
    sale_price_ex_tax INTEGER NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    stock_warning INTEGER NOT NULL DEFAULT 10,
    status product_status NOT NULL DEFAULT 'pending',
    submitted_by UUID REFERENCES users(id),
    reject_reason TEXT,
    images TEXT[],
    description_ja TEXT,
    description_zh TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_submitted_by ON products(submitted_by);

-- Step 6: Create orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES users(id),
    status order_status NOT NULL DEFAULT 'pending',
    total_ex_tax INTEGER NOT NULL DEFAULT 0,
    tax_amount INTEGER NOT NULL DEFAULT 0,
    total_in_tax INTEGER NOT NULL DEFAULT 0,
    customer_note TEXT,
    printed_by UUID REFERENCES users(id),
    printed_at TIMESTAMPTZ,
    invoice_id UUID REFERENCES invoices(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at);

-- Step 7: Create order_items table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity NUMERIC NOT NULL DEFAULT 1,
    unit_price_ex_tax INTEGER NOT NULL,
    discounted_price INTEGER NOT NULL,
    line_total_ex_tax INTEGER NOT NULL,
    order_date DATE NOT NULL DEFAULT current_date,
    note TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Step 8: Create invoices table
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT UNIQUE NOT NULL,
    customer_id UUID NOT NULL REFERENCES users(id),
    total_ex_tax INTEGER NOT NULL DEFAULT 0,
    tax_amount INTEGER NOT NULL DEFAULT 0,
    total_in_tax INTEGER NOT NULL DEFAULT 0,
    status invoice_status NOT NULL DEFAULT 'unpaid',
    issue_date DATE NOT NULL DEFAULT current_date,
    due_date DATE NOT NULL,
    paid_at TIMESTAMPTZ,
    pdf_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_customer ON invoices(customer_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Step 9: Create system_settings table
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    company_address TEXT,
    company_phone TEXT,
    tax_id TEXT,
    bank_name TEXT,
    bank_branch TEXT,
    bank_account_type TEXT,
    bank_account_number TEXT,
    tax_rate NUMERIC(3,2) NOT NULL DEFAULT 0.08,
    default_payment_term_days INTEGER NOT NULL DEFAULT 30,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Insert default settings
INSERT INTO system_settings (company_name) VALUES ('FreshBiz株式会社');
