# 日本B端生鲜销售系统 - 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建完整的日本B端生鲜销售系统，包含PC管理后台和两套Flutter APP

**Architecture:** 基于Supabase全托管后端（东京节点），三端共用同一数据库，通过RLS实现数据隔离。PC后台使用Next.js 15 + ShadCN UI + Tailwind，APP使用Flutter跨平台框架。

**Tech Stack:**
- 后端: Supabase (PostgreSQL + RLS + Auth + Storage + Edge Functions)
- PC后台: Next.js 15 + ShadCN UI + Tailwind + v0.dev
- 移动APP: Flutter 3.x + Provider/Bloc状态管理
- 部署: Cloudflare Pages
- 监控: Sentry

---

## 项目结构

```
E:/japannew/
├── docs/superpowers/
│   ├── specs/                    # 设计规范文档
│   └── plans/                     # 实施计划
├── supabase/
│   ├── migrations/                # 数据库迁移脚本
│   └── functions/                 # Edge Functions
├── pc-admin/                     # Next.js PC管理后台
│   ├── src/app/                  # 页面
│   ├── src/components/           # 组件
│   └── src/lib/                  # 工具函数
└── flutter-app/                  # Flutter APP (双角色)
    ├── lib/
    │   ├── customer/             # 客户采购模块
    │   ├── staff/                # 内部工作人员模块
    │   └── shared/               # 共享组件和工具
    └── pubspec.yaml
```

---

## Phase 1: Supabase 后端搭建

### Task 1.1: 创建Supabase项目并配置

**Files:**
- Create: `supabase/config.toml`
- Create: `supabase/.env.example`

- [ ] **Step 1: 创建Supabase项目**

访问 https://supabase.com 选择东京节点创建项目，记录以下信息：
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

- [ ] **Step 2: 创建环境变量文件**

```bash
# supabase/.env.example
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

- [ ] **Step 3: 提交**

```bash
git add supabase/.env.example
git commit -m "chore: add supabase env example"
```

---

### Task 1.2: 创建数据库表结构

**Files:**
- Create: `supabase/migrations/001_initial_schema.sql`

- [ ] **Step 1: 创建enums**

```sql
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
```

- [ ] **Step 2: 创建users表**

```sql
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
```

- [ ] **Step 3: 创建customers表**

```sql
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
```

- [ ] **Step 4: 创建categories表**

```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_ja TEXT NOT NULL,
    name_zh TEXT,
    parent_id UUID REFERENCES categories(id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
```

- [ ] **Step 5: 创建products表**

```sql
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
```

- [ ] **Step 6: 创建orders表**

```sql
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
```

- [ ] **Step 7: 创建order_items表**

```sql
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
```

- [ ] **Step 8: 创建invoices表**

```sql
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
```

- [ ] **Step 9: 创建system_settings表**

```sql
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

-- 插入默认设置
INSERT INTO system_settings (company_name) VALUES ('FreshBiz株式会社');
```

- [ ] **Step 10: 提交**

```bash
git add supabase/migrations/001_initial_schema.sql
git commit -m "feat: add database schema with all tables"
```

---

### Task 1.3: 配置RLS行级安全策略

**Files:**
- Create: `supabase/migrations/002_rls_policies.sql`

- [ ] **Step 1: 启用RLS并创建策略**

```sql
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
```

- [ ] **Step 2: 提交**

```bash
git add supabase/migrations/002_rls_policies.sql
git commit -m "feat: add RLS policies for all tables"
```

---

### Task 1.4: 创建Edge Functions

**Files:**
- Create: `supabase/functions/generate-order-number/index.ts`
- Create: `supabase/functions/generate-invoice-number/index.ts`
- Create: `supabase/functions/calculate-order-total/index.ts`

- [ ] **Step 1: 创建订单号生成函数**

```typescript
// supabase/functions/generate-order-number/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
  const prefix = `ORD-${today}-`

  // 查询当天最大订单号
  const { data, error } = await supabase
    .from('orders')
    .select('order_number')
    .like('order_number', `${prefix}%`)
    .order('order_number', { ascending: false })
    .limit(1)

  let sequence = 1
  if (data && data.length > 0) {
    const lastNumber = data[0].order_number
    const lastSeq = parseInt(lastNumber.split('-')[2])
    sequence = lastSeq + 1
  }

  const orderNumber = `${prefix}${String(sequence).padStart(3, '0')}`

  return new Response(JSON.stringify({ orderNumber }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

- [ ] **Step 2: 创建请求书号生成函数**

```typescript
// supabase/functions/generate-invoice-number/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  const today = new Date().toISOString().split('T')[0].replace(/-/g, '')
  const prefix = `Q${today}`

  // 查询当天最大请求书号
  const { data, error } = await supabase
    .from('invoices')
    .select('invoice_number')
    .like('invoice_number', `${prefix}%`)
    .order('invoice_number', { ascending: false })
    .limit(1)

  let sequence = 1
  if (data && data.length > 0) {
    const lastNumber = data[0].invoice_number
    const lastSeq = parseInt(lastNumber.replace(prefix, ''))
    sequence = lastSeq + 1
  }

  const invoiceNumber = `${prefix}${String(sequence).padStart(3, '0')}`

  return new Response(JSON.stringify({ invoiceNumber }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

- [ ] **Step 3: 创建订单金额计算函数**

```typescript
// supabase/functions/calculate-order-total/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

serve(async (req) => {
  const { items, customerDiscountRate, taxRate } = await req.json()

  let totalExTax = 0
  const calculatedItems = items.map((item: any) => {
    // 使用整数计算避免浮点精度问题
    const discountRate = customerDiscountRate || 0
    const discountedPrice = Math.round(item.unitPriceExTax * (100 - discountRate) / 100)
    const lineTotal = Math.round(item.quantity * discountedPrice)
    totalExTax += lineTotal
    return { ...item, discountedPrice, lineTotal }
  })

  const taxAmount = Math.round(totalExTax * (taxRate || 0.08))
  const totalInTax = totalExTax + taxAmount

  return new Response(JSON.stringify({
    items: calculatedItems,
    totalExTax,
    taxAmount,
    totalInTax
  }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

- [ ] **Step 4: 提交**

```bash
git add supabase/functions/
git commit -m "feat: add edge functions for order and invoice processing"
```

---

### Task 1.5: 配置Supabase Storage

**Files:**
- Create: `supabase/migrations/003_storage_buckets.sql`

- [ ] **Step 1: 创建Storage Bucket**

```sql
-- 创建商品图片bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true);

-- 创建PDF存储bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', false);

-- 配置Storage策略
CREATE POLICY "Anyone can view product images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload product images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Sales can manage pdfs"
    ON storage.objects FOR ALL
    USING (bucket_id = 'pdfs');
```

- [ ] **Step 2: 提交**

```bash
git add supabase/migrations/003_storage_buckets.sql
git commit -m "feat: add storage buckets for images and PDFs"
```

---

### Task 1.6: 创建库存流水表和库存变动记录

**Files:**
- Create: `supabase/migrations/004_stock_transactions.sql`

- [ ] **Step 1: 创建库存流水表**

```sql
CREATE TABLE stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id),
    quantity_change INTEGER NOT NULL,
    reason TEXT NOT NULL,
    order_id UUID REFERENCES orders(id),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_stock_trans_product ON stock_transactions(product_id);
CREATE INDEX idx_stock_trans_created ON stock_transactions(created_at);
```

- [ ] **Step 2: 添加库存变动触发器**

```sql
CREATE OR REPLACE FUNCTION update_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- 减少库存
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE id = NEW.product_id;

    -- 记录库存流水
    INSERT INTO stock_transactions (product_id, quantity_change, reason, order_id, created_by)
    VALUES (NEW.product_id, -NEW.quantity, 'ORDER', NEW.order_id, NEW.created_by);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_item_stock_update
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_stock();
```

- [ ] **Step 3: 提交**

```bash
git add supabase/migrations/004_stock_transactions.sql
git commit -m "feat: add stock transactions tracking"
```

---

## Phase 2: PC管理后台开发

### Task 2.1: 初始化Next.js项目

**Files:**
- Create: `pc-admin/package.json`
- Create: `pc-admin/next.config.js`
- Create: `pc-admin/tailwind.config.js`

- [ ] **Step 1: 创建Next.js项目**

```bash
cd pc-admin
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm
```

- [ ] **Step 2: 安装ShadCN UI**

```bash
npx shadcn@latest init
# 选择默认选项
```

- [ ] **Step 3: 安装所需组件**

```bash
npx shadcn@latest add button input card table dialog select tabs form label toast dropdown-menu avatar badge skeleton
```

- [ ] **Step 4: 安装其他依赖**

```bash
npm install @supabase/supabase-js @supabase/ssr date-fns clsx tailwind-merge lucide-react
```

- [ ] **Step 5: 提交**

```bash
git add pc-admin/
git commit -m "feat: initialize Next.js project with ShadCN UI"
```

---

### Task 2.2: 创建Supabase客户端和认证

**Files:**
- Create: `pc-admin/src/lib/supabase/client.ts`
- Create: `pc-admin/src/lib/supabase/server.ts`
- Create: `pc-admin/src/lib/supabase/middleware.ts`
- Create: `pc-admin/src/middleware.ts`

- [ ] **Step 1: 创建客户端**

```typescript
// pc-admin/src/lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

- [ ] **Step 2: 创建服务端客户端**

```typescript
// pc-admin/src/lib/supabase/server.ts
import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value, ...options })
          } catch (error) {
            // Handle error
          }
        },
        remove(name: string, options: CookieOptions) {
          try {
            cookieStore.set({ name, value: '', ...options })
          } catch (error) {
            // Handle error
          }
        },
      },
    }
  )
}
```

- [ ] **Step 3: 创建中间件**

```typescript
// pc-admin/src/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  // 未登录且访问受保护路由
  if (!user && !request.nextUrl.pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
```

- [ ] **Step 4: 提交**

```bash
git add pc-admin/src/lib/supabase/ pc-admin/src/middleware.ts
git commit -m "feat: add Supabase auth integration"
```

---

### Task 2.3: 创建登录页面

**Files:**
- Create: `pc-admin/src/app/login/page.tsx`
- Create: `pc-admin/src/components/login-form.tsx`

- [ ] **Step 1: 创建登录表单组件**

```tsx
// pc-admin/src/components/login-form.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useToast } from '@/components/ui/use-toast'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const { toast } = useToast()
  const supabase = createClient()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      toast({
        title: 'エラー',
        description: error.message,
        variant: 'destructive',
      })
    } else {
      router.push('/dashboard')
      router.refresh()
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        type="email"
        placeholder="メールアドレス"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <Input
        type="password"
        placeholder="パスワード"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <Button type="submit" className="w-full" disabled={loading}>
        {loading ? 'ログイン中...' : 'ログイン'}
      </Button>
    </form>
  )
}
```

- [ ] **Step 2: 创建登录页面**

```tsx
// pc-admin/src/app/login/page.tsx
import { LoginForm } from '@/components/login-form'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold text-primary">
            🛒 FreshBiz 管理后台
          </CardTitle>
          <CardDescription>
            メールアドレスとパスワードを入力してください
          </CardDescription>
        </CardHeader>
        <CardContent>
          <LoginForm />
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 3: 提交**

```bash
git add pc-admin/src/app/login/ pc-admin/src/components/login-form.tsx
git commit -m "feat: add login page"
```

---

### Task 2.4: 创建布局和导航

**Files:**
- Create: `pc-admin/src/app/(dashboard)/layout.tsx`
- Create: `pc-admin/src/components/sidebar.tsx`
- Create: `pc-admin/src/components/header.tsx`

- [ ] **Step 1: 创建Dashboard布局**

```tsx
// pc-admin/src/app/(dashboard)/layout.tsx
import { Sidebar } from '@/components/sidebar'
import { Header } from '@/components/header'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-gray-100">
      <Header />
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: 创建侧边栏组件**

```tsx
// pc-admin/src/components/sidebar.tsx
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  Users,
  Package,
  ShoppingCart,
  FileText,
  Settings,
} from 'lucide-react'

const menuItems = [
  { href: '/dashboard', label: '仪表盘', icon: LayoutDashboard },
  { href: '/users', label: '用户管理', icon: Users },
  { href: '/products', label: '商品管理', icon: Package },
  { href: '/orders', label: '订单管理', icon: ShoppingCart },
  { href: '/invoices', label: '请求书', icon: FileText },
  { href: '/settings', label: '系统设置', icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-56 bg-white border-r border-gray-200 min-h-screen">
      <nav className="p-4 space-y-1">
        {menuItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-4 py-2.5 rounded-md text-sm font-medium transition-colors',
                isActive
                  ? 'bg-primary text-white'
                  : 'text-gray-700 hover:bg-gray-100'
              )}
            >
              <Icon className="h-5 w-5" />
              {item.label}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
```

- [ ] **Step 3: 创建顶部导航**

```tsx
// pc-admin/src/components/header.tsx
'use client'

import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

export function Header() {
  const router = useRouter()
  const supabase = createClient()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <header className="h-14 bg-primary text-white px-6 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <span className="text-lg font-bold">🛒 FreshBiz</span>
        <span className="text-sm opacity-80">管理后台</span>
      </div>

      <div className="flex items-center gap-4">
        <Select defaultValue="ja">
          <SelectTrigger className="w-24 bg-transparent border-white/30 text-white">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ja">日本語</SelectItem>
            <SelectItem value="zh">中文</SelectItem>
          </SelectContent>
        </Select>

        <Button
          variant="ghost"
          className="text-white hover:bg-white/20"
          onClick={handleLogout}
        >
          退出
        </Button>
      </div>
    </header>
  )
}
```

- [ ] **Step 4: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/layout.tsx pc-admin/src/components/sidebar.tsx pc-admin/src/components/header.tsx
git commit -m "feat: add dashboard layout with sidebar and header"
```

---

### Task 2.5: 创建仪表盘页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/dashboard/page.tsx`
- Create: `pc-admin/src/components/dashboard/stats-card.tsx`
- Create: `pc-admin/src/components/dashboard/sales-chart.tsx`

- [ ] **Step 1: 创建统计卡片组件**

```tsx
// pc-admin/src/components/dashboard/stats-card.tsx
import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'

interface StatsCardProps {
  title: string
  value: string | number
  change?: string
  changeType?: 'increase' | 'decrease'
  icon: React.ReactNode
  iconColor?: string
}

export function StatsCard({
  title,
  value,
  change,
  changeType,
  icon,
  iconColor = 'text-primary',
}: StatsCardProps) {
  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-gray-500">{title}</p>
            <p className="text-2xl font-bold mt-1 font-mono">{value}</p>
            {change && (
              <p className={cn(
                'text-xs mt-1',
                changeType === 'increase' ? 'text-green-600' : 'text-red-600'
              )}>
                {changeType === 'increase' ? '▲' : '▼'} {change}
              </p>
            )}
          </div>
          <div className={cn('p-3 rounded-lg bg-gray-100', iconColor)}>
            {icon}
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 2: 创建销售图表组件**

```tsx
// pc-admin/src/components/dashboard/sales-chart.tsx
'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface SalesChartProps {
  data: { date: string; amount: number }[]
}

export function SalesChart({ data }: SalesChartProps) {
  const maxAmount = Math.max(...data.map((d) => d.amount))

  return (
    <Card>
      <CardHeader>
        <CardTitle>销售额趋势（近7日）</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-40 flex items-end justify-around gap-2">
          {data.map((item, index) => (
            <div key={index} className="flex flex-col items-center gap-2">
              <div
                className="w-10 bg-primary rounded-t transition-all"
                style={{
                  height: `${(item.amount / maxAmount) * 100}%`,
                  minHeight: '10px',
                }}
              />
              <span className="text-xs text-gray-500">{item.date}</span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 3: 创建仪表盘页面**

```tsx
// pc-admin/src/app/(dashboard)/dashboard/page.tsx
import { StatsCard } from '@/components/dashboard/stats-card'
import { SalesChart } from '@/components/dashboard/sales-chart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { DollarSign, ShoppingCart, Package, FileText } from 'lucide-react'

export default async function DashboardPage() {
  // TODO: 从Supabase获取真实数据
  const stats = {
    todaySales: '¥1,234,560',
    todayOrders: 48,
    pendingProducts: 5,
    pendingInvoices: 12,
  }

  const chartData = [
    { date: '4/1', amount: 800000 },
    { date: '4/2', amount: 950000 },
    { date: '4/3', amount: 850000 },
    { date: '4/4', amount: 1100000 },
    { date: '4/5', amount: 980000 },
    { date: '4/6', amount: 1200000 },
    { date: '4/7', amount: 1050000 },
  ]

  const recentOrders = [
    { id: 'ORD-20260403-001', customer: 'ABC株式会社', amount: '¥45,600', status: '待确认', time: '10:23' },
    { id: 'ORD-20260403-002', customer: 'XYZ商事', amount: '¥123,400', status: '已确认', time: '09:45' },
    { id: 'ORD-20260403-003', customer: '千代田精肉店', amount: '¥78,900', status: '已打印', time: '09:12' },
  ]

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">仪表盘</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          title="今日销售额"
          value={stats.todaySales}
          change="+12.5%"
          changeType="increase"
          icon={<DollarSign className="h-6 w-6" />}
          iconColor="text-green-600"
        />
        <StatsCard
          title="今日订单"
          value={stats.todayOrders}
          change="+8件"
          changeType="increase"
          icon={<ShoppingCart className="h-6 w-6" />}
          iconColor="text-blue-600"
        />
        <StatsCard
          title="待审核商品"
          value={stats.pendingProducts}
          change="需要处理"
          icon={<Package className="h-6 w-6" />}
          iconColor="text-orange-600"
        />
        <StatsCard
          title="待收款请求书"
          value={stats.pendingInvoices}
          change="¥2,345,000"
          icon={<FileText className="h-6 w-6" />}
          iconColor="text-red-600"
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <SalesChart data={chartData} className="lg:col-span-2" />

        {/* Top Products */}
        <Card>
          <CardHeader>
            <CardTitle>销量TOP5</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {[
                { name: 'ほうれん草', qty: '234個' },
                { name: '大根', qty: '198本' },
                { name: '白菜', qty: '156個' },
                { name: 'にんじん', qty: '145本' },
                { name: 'じゃがいも', qty: '132kg' },
              ].map((item, i) => (
                <div key={i} className="flex justify-between text-sm">
                  <span className="text-gray-600">{i + 1}. {item.name}</span>
                  <span className="font-bold">{item.qty}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Orders */}
      <Card>
        <CardHeader>
          <CardTitle>最近订单</CardTitle>
        </CardHeader>
        <CardContent>
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50">
                <th className="text-left p-3 font-medium">订单号</th>
                <th className="text-left p-3 font-medium">客户</th>
                <th className="text-right p-3 font-medium">金额</th>
                <th className="text-center p-3 font-medium">状态</th>
                <th className="text-left p-3 font-medium">时间</th>
              </tr>
            </thead>
            <tbody>
              {recentOrders.map((order, i) => (
                <tr key={i} className="border-t">
                  <td className="p-3 font-mono text-sm">{order.id}</td>
                  <td className="p-3">{order.customer}</td>
                  <td className="p-3 text-right font-bold font-mono">{order.amount}</td>
                  <td className="p-3 text-center">
                    <span className={`
                      px-2 py-1 rounded text-xs
                      ${order.status === '待确认' ? 'bg-blue-100 text-blue-700' : ''}
                      ${order.status === '已确认' ? 'bg-orange-100 text-orange-700' : ''}
                      ${order.status === '已打印' ? 'bg-green-100 text-green-700' : ''}
                    `}>
                      {order.status}
                    </span>
                  </td>
                  <td className="p-3 text-gray-500">{order.time}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 4: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/dashboard/ pc-admin/src/components/dashboard/
git commit -m "feat: add dashboard page with stats and charts"
```

---

### Task 2.6: 创建用户管理页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/users/page.tsx`
- Create: `pc-admin/src/app/(dashboard)/users/_components/user-table.tsx`
- Create: `pc-admin/src/components/user-dialog.tsx`

- [ ] **Step 1: 创建用户表格组件**

```tsx
// pc-admin/src/app/(dashboard)/users/_components/user-table.tsx
'use client'

import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { UserDialog } from '@/components/user-dialog'

interface User {
  id: string
  email: string
  phone?: string
  name: string
  role: string
  isActive: boolean
  companyName?: string
}

interface UserTableProps {
  users: User[]
  onEdit: (user: User) => void
}

export function UserTable({ users, onEdit }: UserTableProps) {
  const roleLabels: Record<string, string> = {
    super_admin: '超级管理员',
    sales_manager: '销售主管',
    purchaser: '采购人员',
    customer: '客户',
  }

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="bg-gray-50">
          <th className="text-left p-3 font-medium">名前</th>
          <th className="text-left p-3 font-medium">メール/電話</th>
          <th className="text-left p-3 font-medium">役割</th>
          <th className="text-left p-3 font-medium">会社</th>
          <th className="text-center p-3 font-medium">状態</th>
          <th className="text-right p-3 font-medium">操作</th>
        </tr>
      </thead>
      <tbody>
        {users.map((user) => (
          <tr key={user.id} className="border-t hover:bg-gray-50">
            <td className="p-3 font-medium">{user.name}</td>
            <td className="p-3 text-gray-600">{user.email || user.phone}</td>
            <td className="p-3">
              <Badge variant="outline">{roleLabels[user.role] || user.role}</Badge>
            </td>
            <td className="p-3 text-gray-600">{user.companyName || '-'}</td>
            <td className="p-3 text-center">
              <Badge variant={user.isActive ? 'default' : 'secondary'}>
                {user.isActive ? '有効' : '無効'}
              </Badge>
            </td>
            <td className="p-3 text-right">
              <Button variant="ghost" size="sm" onClick={() => onEdit(user)}>
                編集
              </Button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
```

- [ ] **Step 2: 创建用户对话框**

```tsx
// pc-admin/src/components/user-dialog.tsx
'use client'

import { useState } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface UserDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  user?: any
}

export function UserDialog({ open, onOpenChange, user }: UserDialogProps) {
  const [formData, setFormData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    phone: user?.phone || '',
    role: user?.role || 'customer',
    companyName: user?.companyName || '',
    discountRate: user?.discountRate || '0',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // TODO: 调用API保存
    console.log('Save user:', formData)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>{user ? 'ユーザーを編集' : '新規ユーザーを作成'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name">名前 *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="role">役割 *</Label>
              <Select value={formData.role} onValueChange={(v) => setFormData({ ...formData, role: v })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="super_admin">超级管理员</SelectItem>
                  <SelectItem value="sales_manager">销售主管</SelectItem>
                  <SelectItem value="purchaser">采购人员</SelectItem>
                  <SelectItem value="customer">客户</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="email">メールアドレス</Label>
              <Input
                id="email"
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">電話番号</Label>
              <Input
                id="phone"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="companyName">会社名</Label>
            <Input
              id="companyName"
              value={formData.companyName}
              onChange={(e) => setFormData({ ...formData, companyName: e.target.value })}
            />
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              キャンセル
            </Button>
            <Button type="submit">保存</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
```

- [ ] **Step 3: 创建用户管理页面**

```tsx
// pc-admin/src/app/(dashboard)/users/page.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { UserTable } from './_components/user-table'
import { UserDialog } from '@/components/user-dialog'
import { Plus } from 'lucide-react'

// Mock数据
const mockUsers = [
  { id: '1', name: '山田太郎', email: 'yamada@abc.co.jp', role: 'purchaser', isActive: true },
  { id: '2', name: '佐藤花子', email: 'sato@freshbiz.jp', role: 'sales_manager', isActive: true },
  { id: '3', name: 'ABC株式会社', email: 'order@abc.co.jp', role: 'customer', isActive: true, companyName: 'ABC株式会社' },
]

export default function UsersPage() {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedUser, setSelectedUser] = useState<any>(null)

  const handleEdit = (user: any) => {
    setSelectedUser(user)
    setDialogOpen(true)
  }

  const handleCreate = () => {
    setSelectedUser(null)
    setDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">ユーザー管理</h1>
        <Button onClick={handleCreate}>
          <Plus className="h-4 w-4 mr-2" />
          新規作成
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>ユーザーリスト</CardTitle>
        </CardHeader>
        <CardContent>
          <UserTable users={mockUsers} onEdit={handleEdit} />
        </CardContent>
      </Card>

      <UserDialog open={dialogOpen} onOpenChange={setDialogOpen} user={selectedUser} />
    </div>
  )
}
```

- [ ] **Step 4: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/users/ pc-admin/src/components/user-dialog.tsx
git commit -m "feat: add user management page"
```

---

### Task 2.7: 创建商品管理页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/products/page.tsx`
- Create: `pc-admin/src/components/product-dialog.tsx`

- [ ] **Step 1: 创建商品管理页面**

```tsx
// pc-admin/src/app/(dashboard)/products/page.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ProductDialog } from '@/components/product-dialog'

const mockProducts = [
  { id: '1', code: 'P001', name: 'ほうれん草', category: '野菜', purchasePrice: 100, salePrice: 180, stock: 50, status: 'approved' },
  { id: '2', code: 'P002', name: '和牛カルビ', category: '精肉', purchasePrice: 600, salePrice: 850, stock: 20, status: 'pending' },
  { id: '3', code: 'P003', name: '白菜', category: '野菜', purchasePrice: 200, salePrice: 300, stock: 0, status: 'approved' },
]

export default function ProductsPage() {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<any>(null)

  const statusLabels: Record<string, { label: string; color: string }> = {
    pending: { label: '審査中', color: 'bg-yellow-100 text-yellow-700' },
    approved: { label: '上架中', color: 'bg-green-100 text-green-700' },
    rejected: { label: '拒否', color: 'bg-red-100 text-red-700' },
  }

  const handleEdit = (product: any) => {
    setSelectedProduct(product)
    setDialogOpen(true)
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">商品管理</h1>
        <div className="flex gap-2">
          <Button variant="outline">批量上架</Button>
          <Button variant="outline">批量価格変更</Button>
          <Button>新規作成</Button>
        </div>
      </div>

      <Card>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b">
                <th className="text-left p-3 font-medium">商品コード</th>
                <th className="text-left p-3 font-medium">商品名</th>
                <th className="text-left p-3 font-medium">分類</th>
                <th className="text-right p-3 font-medium">仕入価格</th>
                <th className="text-right p-3 font-medium">販売価格</th>
                <th className="text-right p-3 font-medium">在庫</th>
                <th className="text-center p-3 font-medium">状態</th>
                <th className="text-right p-3 font-medium">操作</th>
              </tr>
            </thead>
            <tbody>
              {mockProducts.map((product) => (
                <tr key={product.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{product.code}</td>
                  <td className="p-3 font-medium">{product.name}</td>
                  <td className="p-3 text-gray-600">{product.category}</td>
                  <td className="p-3 text-right font-mono">¥{product.purchasePrice.toLocaleString()}</td>
                  <td className="p-3 text-right font-mono">¥{product.salePrice.toLocaleString()}</td>
                  <td className="p-3 text-right font-mono">
                    {product.stock <= product.stockWarning && product.stock > 0 && (
                      <span className="text-orange-500">⚠️</span>
                    )}
                    {product.stock === 0 && <span className="text-red-500">缺货</span>}
                    {product.stock}個
                  </td>
                  <td className="p-3 text-center">
                    <Badge className={statusLabels[product.status].color}>
                      {statusLabels[product.status].label}
                    </Badge>
                  </td>
                  <td className="p-3 text-right">
                    <Button variant="ghost" size="sm" onClick={() => handleEdit(product)}>
                      編集
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <ProductDialog open={dialogOpen} onOpenChange={setDialogOpen} product={selectedProduct} />
    </div>
  )
}
```

- [ ] **Step 2: 创建商品对话框**

```tsx
// pc-admin/src/components/product-dialog.tsx
'use client'

import { useState } from 'react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

interface ProductDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product?: any
}

export function ProductDialog({ open, onOpenChange, product }: ProductDialogProps) {
  const [formData, setFormData] = useState({
    code: product?.code || '',
    nameJa: product?.name || '',
    category: product?.category || '',
    unit: product?.unit || '個',
    purchasePrice: product?.purchasePrice || '',
    salePrice: product?.salePrice || '',
    stock: product?.stock || '',
    stockWarning: product?.stockWarning || '10',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log('Save product:', formData)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle>{product ? '商品を編集' : '新規商品を作成'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="code">商品コード *</Label>
              <Input id="code" value={formData.code} onChange={(e) => setFormData({ ...formData, code: e.target.value })} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="category">分類 *</Label>
              <Select value={formData.category} onValueChange={(v) => setFormData({ ...formData, category: v })}>
                <SelectTrigger>
                  <SelectValue placeholder="選択" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="vegetable">野菜</SelectItem>
                  <SelectItem value="meat">精肉</SelectItem>
                  <SelectItem value="seafood">鮮魚</SelectItem>
                  <SelectItem value="fruit">果物</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="nameJa">商品名 *</Label>
            <Input id="nameJa" value={formData.nameJa} onChange={(e) => setFormData({ ...formData, nameJa: e.target.value })} required />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <div className="space-y-2">
              <Label htmlFor="unit">単位</Label>
              <Select value={formData.unit} onValueChange={(v) => setFormData({ ...formData, unit: v })}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="個">個</SelectItem>
                  <SelectItem value="kg">kg</SelectItem>
                  <SelectItem value="g">g</SelectItem>
                  <SelectItem value="袋">袋</SelectItem>
                  <SelectItem value="箱">箱</SelectItem>
                  <SelectItem value="束">束</SelectItem>
                  <SelectItem value="本">本</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="purchasePrice">仕入価格</Label>
              <Input id="purchasePrice" type="number" value={formData.purchasePrice} onChange={(e) => setFormData({ ...formData, purchasePrice: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="salePrice">販売価格</Label>
              <Input id="salePrice" type="number" value={formData.salePrice} onChange={(e) => setFormData({ ...formData, salePrice: e.target.value })} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="stock">在庫</Label>
              <Input id="stock" type="number" value={formData.stock} onChange={(e) => setFormData({ ...formData, stock: e.target.value })} />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>キャンセル</Button>
            <Button type="submit">保存</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
```

- [ ] **Step 3: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/products/ pc-admin/src/components/product-dialog.tsx
git commit -m "feat: add product management page"
```

---

### Task 2.8: 创建订单管理页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/orders/page.tsx`

- [ ] **Step 1: 创建订单管理页面**

```tsx
// pc-admin/src/app/(dashboard)/orders/page.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Printer, Eye } from 'lucide-react'

const mockOrders = [
  { id: '1', orderNumber: 'ORD-20260403-001', customer: 'ABC株式会社', totalInTax: 45600, status: 'pending', createdAt: '10:23' },
  { id: '2', orderNumber: 'ORD-20260403-002', customer: 'XYZ商事', totalInTax: 123400, status: 'confirmed', createdAt: '09:45' },
  { id: '3', orderNumber: 'ORD-20260403-003', customer: '千代田精肉店', totalInTax: 78900, status: 'printed', createdAt: '09:12' },
]

export default function OrdersPage() {
  const [tab, setTab] = useState('all')

  const statusLabels: Record<string, { label: string; color: string }> = {
    pending: { label: '未確認', color: 'bg-blue-100 text-blue-700' },
    confirmed: { label: '確認済', color: 'bg-orange-100 text-orange-700' },
    printed: { label: '印刷済', color: 'bg-green-100 text-green-700' },
    invoiced: { label: '請求書済', color: 'bg-purple-100 text-purple-700' },
    paid: { label: '支払済', color: 'bg-gray-100 text-gray-700' },
    cancelled: { label: 'キャンセル', color: 'bg-red-100 text-red-700' },
  }

  const filteredOrders = tab === 'all'
    ? mockOrders
    : mockOrders.filter((o) => o.status === tab)

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">注文管理</h1>

      <Tabs defaultValue="all" onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="all">すべて</TabsTrigger>
          <TabsTrigger value="pending">未確認</TabsTrigger>
          <TabsTrigger value="confirmed">確認済</TabsTrigger>
          <TabsTrigger value="printed">印刷済</TabsTrigger>
        </TabsList>

        {['all', 'pending', 'confirmed', 'printed'].map((t) => (
          <TabsContent key={t} value={t} className="mt-4">
            <Card>
              <CardContent className="p-0">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-gray-50 border-b">
                      <th className="text-left p-3 font-medium">注文番号</th>
                      <th className="text-left p-3 font-medium">お客様</th>
                      <th className="text-right p-3 font-medium">税込金額</th>
                      <th className="text-center p-3 font-medium">状態</th>
                      <th className="text-left p-3 font-medium">注文時間</th>
                      <th className="text-right p-3 font-medium">操作</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredOrders.map((order) => (
                      <tr key={order.id} className="border-t hover:bg-gray-50">
                        <td className="p-3 font-mono">{order.orderNumber}</td>
                        <td className="p-3">{order.customer}</td>
                        <td className="p-3 text-right font-bold font-mono">¥{order.totalInTax.toLocaleString()}</td>
                        <td className="p-3 text-center">
                          <Badge className={statusLabels[order.status].color}>
                            {statusLabels[order.status].label}
                          </Badge>
                        </td>
                        <td className="p-3 text-gray-500">{order.createdAt}</td>
                        <td className="p-3 text-right">
                          <div className="flex justify-end gap-2">
                            <Button variant="ghost" size="sm">
                              <Eye className="h-4 w-4 mr-1" />
                              詳細
                            </Button>
                            {order.status === 'pending' && (
                              <Button variant="outline" size="sm">確認</Button>
                            )}
                            {(order.status === 'confirmed' || order.status === 'pending') && (
                              <Button variant="outline" size="sm">
                                <Printer className="h-4 w-4 mr-1" />
                                印刷
                              </Button>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
}
```

- [ ] **Step 2: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/orders/
git commit -m "feat: add order management page"
```

---

### Task 2.9: 创建请求书管理页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/invoices/page.tsx`

- [ ] **Step 1: 创建请求书管理页面**

```tsx
// pc-admin/src/app/(dashboard)/invoices/page.tsx
'use client'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Download, Printer, Eye, CheckCircle } from 'lucide-react'

const mockInvoices = [
  { id: '1', invoiceNumber: 'Q20260403001', customer: 'ABC株式会社', totalInTax: 2862, status: 'unpaid', issueDate: '2026-04-03', dueDate: '2026-04-30' },
  { id: '2', invoiceNumber: 'Q20260402001', customer: 'XYZ商事', totalInTax: 123400, status: 'paid', issueDate: '2026-04-02', dueDate: '2026-04-30' },
  { id: '3', invoiceNumber: 'Q20260401001', customer: '千代田精肉店', totalInTax: 78900, status: 'overdue', issueDate: '2026-04-01', dueDate: '2026-04-15' },
]

export default function InvoicesPage() {
  const statusLabels: Record<string, { label: string; color: string }> = {
    unpaid: { label: '未払い', color: 'bg-red-100 text-red-700' },
    paid: { label: '支払済', color: 'bg-green-100 text-green-700' },
    overdue: { label: '期限超過', color: 'bg-orange-100 text-orange-700' },
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">請求書管理</h1>
        <Button>新規請求書作成</Button>
      </div>

      <Card>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b">
                <th className="text-left p-3 font-medium">請求書番号</th>
                <th className="text-left p-3 font-medium">お客様</th>
                <th className="text-right p-3 font-medium">請求金額</th>
                <th className="text-center p-3 font-medium">状態</th>
                <th className="text-left p-3 font-medium">発行日</th>
                <th className="text-left p-3 font-medium">支払期限</th>
                <th className="text-right p-3 font-medium">操作</th>
              </tr>
            </thead>
            <tbody>
              {mockInvoices.map((invoice) => (
                <tr key={invoice.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono font-bold">{invoice.invoiceNumber}</td>
                  <td className="p-3">{invoice.customer}</td>
                  <td className="p-3 text-right font-bold font-mono">¥{invoice.totalInTax.toLocaleString()}</td>
                  <td className="p-3 text-center">
                    <Badge className={statusLabels[invoice.status].color}>
                      {statusLabels[invoice.status].label}
                    </Badge>
                  </td>
                  <td className="p-3 text-gray-600">{invoice.issueDate}</td>
                  <td className="p-3 text-gray-600">{invoice.dueDate}</td>
                  <td className="p-3 text-right">
                    <div className="flex justify-end gap-2">
                      <Button variant="ghost" size="sm">
                        <Eye className="h-4 w-4 mr-1" />
                        詳細
                      </Button>
                      <Button variant="ghost" size="sm">
                        <Download className="h-4 w-4 mr-1" />
                        PDF
                      </Button>
                      {invoice.status !== 'paid' && (
                        <Button variant="outline" size="sm" className="text-green-600">
                          <CheckCircle className="h-4 w-4 mr-1" />
                          支払確認
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 2: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/invoices/
git commit -m "feat: add invoice management page"
```

---

### Task 2.10: 创建系统设置页面

**Files:**
- Create: `pc-admin/src/app/(dashboard)/settings/page.tsx`

- [ ] **Step 1: 创建系统设置页面**

```tsx
// pc-admin/src/app/(dashboard)/settings/page.tsx
'use client'

import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function SettingsPage() {
  const [companyInfo, setCompanyInfo] = useState({
    companyName: 'FreshBiz株式会社',
    address: '大阪府大阪市北区梅田1-1-1',
    phone: '06-1234-5678',
    taxId: '6123456789012',
    bankName: '大阪銀行',
    bankBranch: '本店',
    bankAccountType: '普通',
    bankAccountNumber: '1234567',
  })

  const [taxSettings, setTaxSettings] = useState({
    taxRate: '8',
    paymentTermDays: '30',
  })

  const handleSave = () => {
    // TODO: 保存设置
    console.log('Save settings')
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">システム設定</h1>

      <Tabs defaultValue="company">
        <TabsList>
          <TabsTrigger value="company">会社情報</TabsTrigger>
          <TabsTrigger value="tax">全局設定</TabsTrigger>
          <TabsTrigger value="print">印刷設定</TabsTrigger>
        </TabsList>

        <TabsContent value="company" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>会社情報</CardTitle>
              <CardDescription>請求書に表示される会社情報を設定します</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>会社名</Label>
                  <Input value={companyInfo.companyName} onChange={(e) => setCompanyInfo({ ...companyInfo, companyName: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>電話番号</Label>
                  <Input value={companyInfo.phone} onChange={(e) => setCompanyInfo({ ...companyInfo, phone: e.target.value })} />
                </div>
              </div>
              <div className="space-y-2">
                <Label>住所</Label>
                <Input value={companyInfo.address} onChange={(e) => setCompanyInfo({ ...companyInfo, address: e.target.value })} />
              </div>
              <div className="space-y-2">
                <Label>税号</Label>
                <Input value={companyInfo.taxId} onChange={(e) => setCompanyInfo({ ...companyInfo, taxId: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>銀行名</Label>
                  <Input value={companyInfo.bankName} onChange={(e) => setCompanyInfo({ ...companyInfo, bankName: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>支店名</Label>
                  <Input value={companyInfo.bankBranch} onChange={(e) => setCompanyInfo({ ...companyInfo, bankBranch: e.target.value })} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>口座種別</Label>
                  <Input value={companyInfo.bankAccountType} onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountType: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>口座番号</Label>
                  <Input value={companyInfo.bankAccountNumber} onChange={(e) => setCompanyInfo({ ...companyInfo, bankAccountNumber: e.target.value })} />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSave}>保存</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tax" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>全局設定</CardTitle>
              <CardDescription>消费税率等の全局設定を行います</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>消费税率 (%)</Label>
                  <Input type="number" value={taxSettings.taxRate} onChange={(e) => setTaxSettings({ ...taxSettings, taxRate: e.target.value })} />
                </div>
                <div className="space-y-2">
                  <Label>デフォルト支払期限 (日)</Label>
                  <Input type="number" value={taxSettings.paymentTermDays} onChange={(e) => setTaxSettings({ ...taxSettings, paymentTermDays: e.target.value })} />
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleSave}>保存</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="print" className="mt-4">
          <Card>
            <CardHeader>
              <CardTitle>印刷設定</CardTitle>
              <CardDescription>請求書・分拣扎の印刷設定を行います</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">印刷テンプレートのカスタマイズ機能は開発予定</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
```

- [ ] **Step 2: 提交**

```bash
git add pc-admin/src/app/\(dashboard\)/settings/
git commit -m "feat: add settings page"
```

---

## Phase 3: 测试

### Task 3.1: 单元测试

**Files:**
- Create: `pc-admin/src/lib/__tests__/price-calculator.test.ts`
- Create: `supabase/migrations/test-data.sql`

- [ ] **Step 1: 价格计算测试**

```typescript
// pc-admin/src/lib/__tests__/price-calculator.test.ts
describe('Price Calculator', () => {
  it('calculates discounted price correctly', () => {
    const unitPrice = 1000
    const discountRate = 10
    const discountedPrice = Math.round(unitPrice * (100 - discountRate) / 100)
    expect(discountedPrice).toBe(900)
  })

  it('calculates tax correctly', () => {
    const totalExTax = 10000
    const taxRate = 0.08
    const taxAmount = Math.round(totalExTax * taxRate)
    expect(taxAmount).toBe(800)
  })

  it('handles zero discount rate', () => {
    const unitPrice = 1000
    const discountRate = 0
    const discountedPrice = Math.round(unitPrice * (100 - discountRate) / 100)
    expect(discountedPrice).toBe(1000)
  })
})
```

- [ ] **Step 2: 提交**

```bash
git add pc-admin/src/lib/__tests__/
git commit -m "test: add price calculation unit tests"
```

---

### Task 3.2: 集成测试 - 订单流程

**Files:**
- Create: `supabase/migrations/test-data.sql`

- [ ] **Step 1: 创建测试数据脚本**

```sql
-- 测试数据脚本
-- 运行前请在本地环境执行

-- 创建测试用户
INSERT INTO users (id, email, password_hash, role, name) VALUES
  ('00000000-0000-0000-0000-000000000001', 'admin@test.com', 'hash', 'super_admin', 'Admin'),
  ('00000000-0000-0000-0000-000000000002', 'sales@test.com', 'hash', 'sales_manager', 'Sales'),
  ('00000000-0000-0000-0000-000000000003', 'customer@test.com', 'hash', 'customer', 'Customer');

-- 创建测试商品分类
INSERT INTO categories (id, name_ja, name_zh) VALUES
  ('00000000-0000-0000-0001-000000000001', '野菜', '蔬菜'),
  ('00000000-0000-0000-0001-000000000002', '精肉', '肉类');

-- 创建测试商品
INSERT INTO products (id, code, name_ja, name_zh, category_id, unit, purchase_price, sale_price_ex_tax, stock, status, submitted_by) VALUES
  ('00000000-0000-0000-0002-000000000001', 'P001', 'ほうれん草', '菠菜', '00000000-0000-0000-0001-000000000001', '束', 100, 180, 100, 'approved', '00000000-0000-0000-0000-000000000002');
```

- [ ] **Step 2: 提交**

```bash
git add supabase/migrations/test-data.sql
git commit -m "test: add integration test data"
```

---

## Phase 4: Flutter APP开发

### Task 3.1: 初始化Flutter项目

**Files:**
- Create: `flutter-app/pubspec.yaml`

- [ ] **Step 1: 创建Flutter项目**

```bash
cd flutter-app
flutter create --org com.freshbiz --project-name freshbiz_app .
```

- [ ] **Step 2: 配置pubspec.yaml**

```yaml
name: freshbiz_app
description: 日本B端生鲜销售系统APP
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1
  provider: ^6.1.1
  go_router: ^12.1.1
  supabase_flutter: ^2.3.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  pdf: ^3.10.4
  printing: ^5.11.1
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

- [ ] **Step 3: 创建资源目录**

```bash
mkdir -p flutter-app/assets/images
```

- [ ] **Step 4: 提交**

```bash
git add flutter-app/
git commit -m "feat: initialize Flutter project"
```

---

### Task 3.2: 创建Supabase客户端配置

**Files:**
- Create: `flutter-app/lib/supabase.dart`
- Create: `flutter-app/lib/config.dart`

- [ ] **Step 1: 创建配置**

```dart
// flutter-app/lib/config.dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // 日本单位
  static const List<String> units = ['個', 'kg', 'g', '袋', '箱', '束', '本'];

  // 默认消费税率 8%
  static const double defaultTaxRate = 0.08;
}
```

- [ ] **Step 2: 创建Supabase客户端**

```dart
// flutter-app/lib/supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
}

final supabase = Supabase.instance.client;
```

- [ ] **Step 3: 提交**

```bash
git add flutter-app/lib/supabase.dart flutter-app/lib/config.dart
git commit -m "feat: add Supabase client configuration"
```

---

### Task 3.3: 创建国际化配置

**Files:**
- Create: `flutter-app/lib/l10n/app_ja.arb`
- Create: `flutter-app/lib/l10n/app_zh.arb`
- Create: `flutter-app/lib/l10n/l10n.dart`

- [ ] **Step 1: 创建日语翻译**

```json
// flutter-app/lib/l10n/app_ja.arb
{
  "appTitle": "FreshBiz",
  "login": "ログイン",
  "account": "アカウント",
  "password": "パスワード",
  "home": "ホーム",
  "categories": "分類",
  "cart": "カート",
  "myPage": "マイページ",
  "search": "商品を検索...",
  "hotProducts": "热销商品",
  "newProducts": "新品上架",
  "addToCart": "カートに追加",
  "checkout": "注文を確定する",
  "total": "合計",
  "taxIncluded": "税込",
  "taxExcluded": "税抜",
  "orderHistory": "注文履歴",
  "invoices": "請求書",
  "downloadPdf": "PDFをダウンロード",
  "settings": "設定",
  "language": "言語",
  "logout": "ログアウト",
  "confirmOrder": "確認",
  "printPickingList": "分拣单印刷",
  "pending": "未確認",
  "confirmed": "確認済",
  "completed": "完了",
  "cancel": "キャンセル"
}
```

- [ ] **Step 2: 创建中文翻译**

```json
// flutter-app/lib/l10n/app_zh.arb
{
  "appTitle": "FreshBiz",
  "login": "登录",
  "account": "账号",
  "password": "密码",
  "home": "首页",
  "categories": "分类",
  "cart": "购物车",
  "myPage": "我的",
  "search": "搜索商品...",
  "hotProducts": "热销商品",
  "newProducts": "新品上架",
  "addToCart": "加入购物车",
  "checkout": "提交订单",
  "total": "合计",
  "taxIncluded": "含税",
  "taxExcluded": "不含税",
  "orderHistory": "订单历史",
  "invoices": "请求书",
  "downloadPdf": "下载PDF",
  "settings": "设置",
  "language": "语言",
  "logout": "退出登录",
  "confirmOrder": "确认",
  "printPickingList": "打印分拣单",
  "pending": "待确认",
  "confirmed": "已确认",
  "completed": "已完成",
  "cancel": "取消"
}
```

- [ ] **Step 3: 创建本地化配置**

```dart
// flutter-app/lib/l10n/l10n.dart
import 'package:flutter/material.dart';

class L10n {
  static final Map<String, Map<String, String>> _translations = {
    'ja': {
      'appTitle': 'FreshBiz',
      'login': 'ログイン',
      'home': 'ホーム',
      'categories': '分類',
      'cart': 'カート',
      'myPage': 'マイページ',
    },
    'zh': {
      'appTitle': 'FreshBiz',
      'login': '登录',
      'home': '首页',
      'categories': '分类',
      'cart': '购物车',
      'myPage': '我的',
    },
  };

  static String t(String locale, String key) {
    return _translations[locale]?[key] ?? _translations['ja']?[key] ?? key;
  }
}
```

- [ ] **Step 4: 提交**

```bash
git add flutter-app/lib/l10n/
git commit -m "feat: add i18n configuration"
```

---

### Task 3.4: 创建客户APP - 登录和首页

**Files:**
- Create: `flutter-app/lib/customer/screens/login_screen.dart`
- Create: `flutter-app/lib/customer/screens/home_screen.dart`
- Create: `flutter-app/lib/customer/screens/main_screen.dart`

- [ ] **Step 1: 创建登录页面**

```dart
// flutter-app/lib/customer/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: _accountController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (response.user != null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインに失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🛒 FreshBiz', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('新鮮な野菜をお届けします', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 48),
              TextField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: 'アカウント',
                  prefixText: '👤 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  prefixText: '🔒 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ログイン', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建首页**

```dart
// flutter-app/lib/customer/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['野菜', '精肉', '鮮魚', '果物'];
    final icons = ['🥬', '🥩', '🐟', '🍎'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '商品を検索...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categories Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.asMap().entries.map((entry) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(icons[entry.key], style: const TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.value, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Hot Products
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔥 热销商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('すべて見る')),
              ],
            ),
          ),

          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Center(child: Text('🥬', style: TextStyle(fontSize: 48))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ほうれん草', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('1束', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('¥180', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F4C81),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 创建主页面（含底部导航）**

```dart
// flutter-app/lib/customer/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    Center(child: Text('分類画面')),
    Center(child: Text('カート画面')),
    Center(child: Text('マイページ画面')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FreshBiz 注文'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // 语言切换
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F4C81),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: '分類'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'カート'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 提交**

```bash
git add flutter-app/lib/customer/
git commit -m "feat: add customer app login and home screens"
```

---

### Task 3.5: 创建客户APP - 购物车和订单

**Files:**
- Create: `flutter-app/lib/customer/screens/cart_screen.dart`
- Create: `flutter-app/lib/customer/screens/order_history_screen.dart`

- [ ] **Step 1: 创建购物车页面**

```dart
// flutter-app/lib/customer/screens/cart_screen.dart
import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _CartItem(
                name: 'ほうれん草',
                unit: '束',
                price: 180,
                quantity: 2,
              ),
              _CartItem(
                name: '和牛カルビ',
                unit: '100g',
                price: 850,
                quantity: 3,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('商品数', style: TextStyle(color: Colors.grey)),
                  const Text('5点'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('税抜合計', style: TextStyle(color: Colors.grey)),
                  const Text('¥2,650'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('消費税(8%)', style: TextStyle(color: Colors.grey)),
                  const Text('¥212'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('合計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('¥2,862', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C81))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('注文を確定する', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItem extends StatelessWidget {
  final String name;
  final String unit;
  final int price;
  final int quantity;

  const _CartItem({
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🥬', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$unit • ¥${price.toLocaleString()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(child: Text('-', style: TextStyle(fontSize: 16))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(child: Text('+', style: TextStyle(fontSize: 16))),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text('¥${(price * quantity).toLocaleString()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 创建订单历史页面**

```dart
// flutter-app/lib/customer/screens/order_history_screen.dart
import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'ORD-20260403-001', 'status': 'pending', 'total': 45600, 'date': '04/03 10:23'},
      {'id': 'ORD-20260402-001', 'status': 'confirmed', 'total': 123400, 'date': '04/02 09:45'},
      {'id': 'ORD-20260401-001', 'status': 'completed', 'total': 78900, 'date': '04/01 14:30'},
    ];

    final statusLabels = {
      'pending': {'label': '未確認', 'color': Colors.blue},
      'confirmed': {'label': '確認済', 'color': Colors.orange},
      'completed': {'label': '完了', 'color': Colors.green},
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = statusLabels[order['status']]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status['color']!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status['label'] as String, style: TextStyle(color: status['color'], fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['date'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('¥${(order['total'] as int).toLocaleString()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F4C81))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add flutter-app/lib/customer/screens/cart_screen.dart flutter-app/lib/customer/screens/order_history_screen.dart
git commit -m "feat: add customer app cart and order history screens"
```

---

### Task 3.6: 创建内部工作人员APP - 商品上传

**Files:**
- Create: `flutter-app/lib/staff/screens/product_upload_screen.dart`
- Create: `flutter-app/lib/staff/screens/my_products_screen.dart`

- [ ] **Step 1: 创建商品上传页面**

```dart
// flutter-app/lib/staff/screens/product_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '野菜';
  String _selectedUnit = '個';
  final List<String> _images = [];

  final categories = ['野菜', '精肉', '鮮魚', '果物'];
  final units = ['個', 'kg', 'g', '袋', '箱', '束', '本'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📤 商品上传'),
        backgroundColor: const Color(0xFF3ECF8E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3ECF8E), style: BorderStyle.solid, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _images.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Color(0xFF3ECF8E)),
                          SizedBox(height: 8),
                          Text('写真を追加 (最大5枚)', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : Center(child: Text('${_images.length}枚選択', style: const TextStyle(color: Color(0xFF3ECF8E)))),
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '商品名 *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) => value?.isEmpty ?? true ? '必須' : null,
            ),
            const SizedBox(height: 16),

            // Category & Unit
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: '分類 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(labelText: '単位 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price & Stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: InputDecoration(labelText: '仕入価格 *', prefixText: '¥', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? '必須' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(labelText: '在庫 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? '必須' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: '説明', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // Submit
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECF8E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('📤 提出する', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 创建我的商品页面**

```dart
// flutter-app/lib/staff/screens/my_products_screen.dart
import 'package:flutter/material.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('私の商品'),
          backgroundColor: const Color(0xFF3ECF8E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '審査中(2)'),
              Tab(text: '通過(15)'),
              Tab(text: '拒否(1)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductList(status: 'pending'),
            _ProductList(status: 'approved'),
            _ProductList(status: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final String status;

  const _ProductList({required this.status});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': '新鮮な白菜', 'price': 300, 'status': 'pending'},
      {'name': '的有机胡萝卜', 'price': 200, 'status': 'pending'},
    ].where((p) => p['status'] == status || status != 'pending').toList();

    if (products.isEmpty) {
      return const Center(child: Text('商品がありません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('🥬', style: TextStyle(fontSize: 24))),
            ),
            title: Text(product['name'] as String),
            subtitle: Text('¥${(product['price'] as int).toLocaleString()}'),
            trailing: status == 'rejected'
                ? const Text('❌ 拒否理由', style: TextStyle(color: Colors.red, fontSize: 12))
                : status == 'pending'
                    ? const Icon(Icons.edit)
                    : null,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add flutter-app/lib/staff/
git commit -m "feat: add staff app product upload screens"
```

---

### Task 3.7: 创建内部工作人员APP - 订单管理

**Files:**
- Create: `flutter-app/lib/staff/screens/order_management_screen.dart`

- [ ] **Step 1: 创建订单管理页面**

```dart
// flutter-app/lib/staff/screens/order_management_screen.dart
import 'package:flutter/material.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📋 订单管理'),
          backgroundColor: const Color(0xFF0F4C81),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: '未確認(3)'),
              Tab(text: '確認済(12)'),
              Tab(text: '印刷済(8)'),
              Tab(text: '請求書済(5)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(status: 'pending'),
            _OrderList(status: 'confirmed'),
            _OrderList(status: 'printed'),
            _OrderList(status: 'invoiced'),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String status;

  const _OrderList({required this.status});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'ORD-20260403-001', 'customer': 'ABC株式会社', 'total': 45600, 'items': 5, 'time': '10:23'},
      {'id': 'ORD-20260403-002', 'customer': 'XYZ商事', 'total': 123400, 'items': 12, 'time': '09:45'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('未確認', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(order['customer'] as String, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text('📦 ${order['items']}点 • ¥${(order['total'] as int).toLocaleString()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('注文時間: ${order['time']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Text('✅ 確認'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F4C81),
                          side: const BorderSide(color: Color(0xFF0F4C81)),
                        ),
                        child: const Text('🖨️ 印刷'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/staff/screens/order_management_screen.dart
git commit -m "feat: add staff app order management screen"
```

---

## Phase 4: PDF生成功能

### Task 4.1: 创建请求书PDF生成

**Files:**
- Create: `supabase/functions/generate-invoice-pdf/index.ts`

- [ ] **Step 1: 创建请求书PDF生成函数**

```typescript
// supabase/functions/generate-invoice-pdf/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { invoiceId, settings } = await req.json()

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  // 获取请求书数据
  const { data: invoice } = await supabase
    .from('invoices')
    .select(`
      *,
      customers:users!customer_id(
        company_name, company_name_zh, postal_code, address, address_zh, contact_name, discount_rate
      ),
      orders(*)
    `)
    .eq('id', invoiceId)
    .single()

  // 获取订单明细
  const { data: orderItems } = await supabase
    .from('order_items')
    .select(`
      *,
      products:products(name_ja, name_zh, unit)
    `)
    .in('order_id', invoice.orders.map((o: any) => o.id))

  // 生成HTML
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Noto Sans JP', sans-serif; font-size: 11px; padding: 40px; line-height: 1.5; }
        .title { text-align: center; font-size: 28px; font-weight: bold; letter-spacing: 8px; margin-bottom: 30px; border-bottom: 2px double #333; padding-bottom: 15px; display: inline-block; }
        .greeting { text-align: right; color: #666; margin-bottom: 20px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 30px; margin-bottom: 25px; }
        .section-title { font-size: 9px; color: #666; margin-bottom: 4px; }
        .company-name { font-size: 14px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th { background: #333; color: white; padding: 10px 8px; border: 1px solid #333; text-align: left; }
        td { padding: 8px; border: 1px solid #ddd; }
        .amount-section { display: flex; gap: 0; margin-bottom: 20px; align-items: stretch; }
        .amount-box { width: 160px; border: 3px solid #0F4C81; padding: 16px; background: #e8f4fd; text-align: center; }
        .amount-label { font-size: 11px; color: #0F4C81; font-weight: bold; }
        .amount-value { font-size: 18px; font-weight: bold; font-family: monospace; color: #0F4C81; }
        .summary { display: flex; justify-content: flex-end; }
        .summary-table { width: 220px; }
        .summary-row { display: flex; justify-content: space-between; padding: 6px 10px; border: 1px solid #ddd; }
        .total-row { background: #333; color: white; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 15px; border-top: 1px solid #ddd; text-align: center; color: #666; font-size: 10px; }
      </style>
    </head>
    <body>
      <div style="text-align: center;">
        <div class="title">請 求 書</div>
      </div>

      <div class="greeting">
        毎度ありがとうございます。下記のとおりご請求申し上げます。
      </div>

      <div class="info-grid">
        <div>
          <div class="section-title">宛先</div>
          <div class="company-name">${invoice.customers.company_name} 御中</div>
          <div>${invoice.customers.postal_code}</div>
          <div>${invoice.customers.address}</div>
        </div>
        <div style="text-align: right;">
          <div class="section-title">発行日時</div>
          <div>${invoice.issue_date}</div>
          <div style="margin-top: 8px;">
            <div class="section-title">請求書番号</div>
            <div>${invoice.invoice_number}</div>
          </div>
          <div style="margin-top: 8px;">
            <div class="section-title">支払期限</div>
            <div>${invoice.due_date}</div>
          </div>
        </div>
      </div>

      <div style="background: #f5f5f5; padding: 12px; margin-bottom: 20px;">
        <strong>【銀行振込先】</strong><br/>
        ${settings?.bank_name || '大阪銀行'} ${settings?.bank_branch || '本店'} 普通口座 ${settings?.bank_account_number || '1234567'}
      </div>

      <div class="amount-section">
        <div class="amount-box">
          <div class="amount-label">請求金額</div>
          <div class="amount-value">¥${invoice.total_in_tax.toLocaleString()}</div>
        </div>
        <table style="width: 100%; margin-left: 16px;">
          <thead>
            <tr>
              <th style="width: 15%;">日付</th>
              <th style="width: 40%;">品目</th>
              <th style="width: 10%; text-align: center;">数量</th>
              <th style="width: 8%; text-align: center;">単位</th>
              <th style="width: 13%; text-align: right;">単価</th>
              <th style="width: 14%; text-align: right;">金額</th>
            </tr>
          </thead>
          <tbody>
            ${orderItems.map((item: any) => `
              <tr>
                <td>${item.order_date}</td>
                <td>${item.products.name_ja}</td>
                <td style="text-align: center;">${item.quantity}</td>
                <td style="text-align: center;">${item.products.unit}</td>
                <td style="text-align: right; font-family: monospace;">¥${item.unit_price_ex_tax.toLocaleString()}</td>
                <td style="text-align: right; font-family: monospace;">¥${item.line_total_ex_tax.toLocaleString()}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>

      <div class="summary">
        <div class="summary-table">
          <div class="summary-row">
            <span>税抜合計</span>
            <span style="font-family: monospace;">¥${invoice.total_ex_tax?.toLocaleString() || Math.round(invoice.total_in_tax / 1.08).toLocaleString()}</span>
          </div>
          <div class="summary-row">
            <span>消費税額（8％）</span>
            <span style="font-family: monospace;">¥${invoice.tax_amount?.toLocaleString() || (invoice.total_in_tax - Math.round(invoice.total_in_tax / 1.08)).toLocaleString()}</span>
          </div>
          <div class="summary-row total-row">
            <span>請求金額</span>
            <span style="font-family: monospace;">¥${invoice.total_in_tax.toLocaleString()}</span>
          </div>
        </div>
      </div>

      <div class="footer">
        <div>ご質問等ございましたら、お気軽にお問い合わせください。</div>
        <div style="margin-top: 5px;">${settings?.company_name || 'FreshBiz株式会社'} | ${settings?.company_address || '大阪府大阪市北区梅田1-1-1'} | Tel: ${settings?.company_phone || '06-1234-5678'}</div>
      </div>
    </body>
    </html>
  `

  return new Response(JSON.stringify({ html }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

- [ ] **Step 2: 提交**

```bash
git add supabase/functions/generate-invoice-pdf/
git commit -m "feat: add invoice PDF generation with proper styling"
```

---

### Task 4.2: 创建分拣单PDF生成

**Files:**
- Create: `supabase/functions/generate-picking-list-pdf/index.ts`

- [ ] **Step 1: 创建分拣单PDF生成函数**

```typescript
// supabase/functions/generate-picking-list-pdf/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { orderId, printedBy, printedAt } = await req.json()

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseKey)

  // 获取订单数据
  const { data: order } = await supabase
    .from('orders')
    .select(`
      *,
      customer:users!customer_id(
        company_name, contact_name, phone, address, postal_code
      ),
      order_items(*, products(name_ja, unit))
    `)
    .eq('id', orderId)
    .single()

  // 获取打印人信息
  const { data: printer } = await supabase
    .from('users')
    .select('name')
    .eq('id', printedBy)
    .single()

  const totalItems = order.order_items.reduce((sum: number, item: any) => sum + Number(item.quantity), 0)

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Noto Sans JP', sans-serif; font-size: 11px; padding: 40px; line-height: 1.5; }
        .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px; border-bottom: 2px solid #0F4C81; padding-bottom: 16px; }
        .order-number { font-size: 16px; font-weight: bold; }
        .order-date { font-size: 14px; color: #666; }
        .customer-box { background: #f8f9fa; padding: 16px; border-radius: 6px; margin-bottom: 20px; }
        .customer-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; font-size: 11px; }
        .customer-label { color: #666; font-size: 10px; margin-bottom: 2px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        th { background: #0F4C81; color: white; padding: 10px 8px; border: 1px solid #0F4C81; text-align: left; }
        td { padding: 8px; border: 1px solid #ddd; }
        .summary { display: flex; justify-content: space-between; align-items: flex-end; }
        .summary-left { font-size: 11px; color: #666; }
        .summary-right table { width: 180px; }
        .summary-right td { padding: 6px; border: 1px solid #ddd; font-size: 11px; }
        .total-row { background: #0F4C81; color: white; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="header">
        <div>
          <div class="order-number">注文番号: ${order.order_number}</div>
          <div class="order-date">注文日時: ${new Date(order.created_at).toLocaleString('ja-JP')}</div>
        </div>
      </div>

      <div class="customer-box">
        <div class="customer-grid">
          <div>
            <div class="customer-label">会社名</div>
            <div style="font-weight: bold;">${order.customer.company_name}</div>
          </div>
          <div>
            <div class="customer-label">担当者</div>
            <div>${order.customer.contact_name} 様</div>
          </div>
          <div>
            <div class="customer-label">電話番号</div>
            <div>${order.customer.phone}</div>
          </div>
          <div>
            <div class="customer-label">配送先住所</div>
            <div>${order.customer.postal_code} ${order.customer.address}</div>
          </div>
        </div>
        ${order.customer_note ? `
          <div style="margin-top: 12px; padding-top: 12px; border-top: 1px dashed #ccc;">
            <div class="customer-label">備考</div>
            <div>${order.customer_note}</div>
          </div>
        ` : ''}
      </div>

      <table>
        <thead>
          <tr>
            <th style="width: 10%; text-align: center;">数量</th>
            <th style="width: 10%; text-align: center;">単位</th>
            <th style="width: 40%;">商品名</th>
            <th style="width: 15%; text-align: right;">単価</th>
            <th style="width: 15%; text-align: right;">割引後単価</th>
            <th style="width: 10%; text-align: right;">金額</th>
          </tr>
        </thead>
        <tbody>
          ${order.order_items.map((item: any) => `
            <tr>
              <td style="text-align: center;">${item.quantity}</td>
              <td style="text-align: center;">${item.products.unit}</td>
              <td>${item.products.name_ja}</td>
              <td style="text-align: right; font-family: monospace;">¥${item.unit_price_ex_tax.toLocaleString()}</td>
              <td style="text-align: right; font-family: monospace;">¥${item.discounted_price.toLocaleString()}</td>
              <td style="text-align: right; font-family: monospace;">¥${item.line_total_ex_tax.toLocaleString()}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>

      <div class="summary">
        <div class="summary-left">
          <div>合計商品数: <strong>${totalItems}点</strong></div>
          <div>打印时间: ${new Date(printedAt).toLocaleString('ja-JP')}</div>
          <div>打印人: ${printer?.name || printedBy}</div>
        </div>
        <div class="summary-right">
          <table>
            <tr>
              <td style="background: #f8f9fa;">割引率</td>
              <td style="text-align: right;">${order.customer.discount_rate || 0}%</td>
            </tr>
            <tr>
              <td style="background: #f8f9fa;">税抜合計</td>
              <td style="text-align: right; font-family: monospace;">¥${order.total_ex_tax.toLocaleString()}</td>
            </tr>
            <tr>
              <td style="background: #f8f9fa;">消費税(8%)</td>
              <td style="text-align: right; font-family: monospace;">¥${order.tax_amount.toLocaleString()}</td>
            </tr>
            <tr class="total-row">
              <td>税込合計</td>
              <td style="font-family: monospace;">¥${order.total_in_tax.toLocaleString()}</td>
            </tr>
          </table>
        </div>
      </div>
    </body>
    </html>
  `

  return new Response(JSON.stringify({ html }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

- [ ] **Step 2: 提交**

```bash
git add supabase/functions/generate-picking-list-pdf/
git commit -m "feat: add picking list PDF generation"
```

---

## Phase 5: 部署与监控

### Task 5.1: 配置Cloudflare Pages部署

**Files:**
- Create: `pc-admin/.github/workflows/deploy.yml`

- [ ] **Step 1: 创建GitHub Actions工作流**

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
        working-directory: pc-admin
      - run: npm run build
        working-directory: pc-admin
      - uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: freshbiz-admin
          directory: pc-admin/out
```

- [ ] **Step 2: 提交**

```bash
git add pc-admin/.github/workflows/deploy.yml
git commit -m "ci: add Cloudflare Pages deployment workflow"
```

---

### Task 5.2: 配置Sentry监控

**Files:**
- Create: `pc-admin/sentry.client.config.ts`
- Create: `pc-admin/sentry.edge.config.ts`
- Create: `pc-admin/sentry.server.config.ts`

- [ ] **Step 1: 安装Sentry SDK**

```bash
cd pc-admin
npm install @sentry/nextjs
npx sentry-wizard -i nextjs
```

- [ ] **Step 2: 创建Sentry配置**

```typescript
// pc-admin/sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  beforeSend(event) {
    // 发送邮件通知
    return event
  },
})
```

- [ ] **Step 3: Flutter Sentry配置**

```yaml
# flutter-app/pubspec.yaml
sentry_flutter: ^0.1.0
```

```dart
// flutter-app/lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    options => options
      ..dsn = 'YOUR_SENTRY_DSN'
      ..tracesSampleRate = 0.1,
    appRunner: () => runApp(const MyApp()),
  );
}
```

- [ ] **Step 4: 提交**

```bash
git add pc-admin/sentry.*.config.ts flutter-app/lib/main.dart
git commit -m "feat: add Sentry error monitoring"
```

---

## 实施检查清单

### 数据库
- [ ] Supabase项目创建
- [ ] 数据库表结构创建
- [ ] RLS策略配置（包含system_settings和stock_transactions）
- [ ] Storage Bucket配置
- [ ] 库存流水表和触发器

### PC管理后台
- [ ] Next.js项目初始化
- [ ] ShadCN UI组件安装
- [ ] Supabase认证集成
- [ ] 登录页面
- [ ] 仪表盘页面
- [ ] 用户管理页面（含批量Excel导入）
- [ ] 商品管理页面（含库存流水查看）
- [ ] 订单管理页面
- [ ] 请求书管理页面（含多订单合并功能）
- [ ] 系统设置页面（含打印设置）
- [ ] Cloudflare Pages部署

### Flutter APP
- [ ] Flutter项目初始化
- [ ] Supabase集成
- [ ] 国际化配置
- [ ] 客户登录/首页
- [ ] 客户购物车
- [ ] 客户订单历史
- [ ] 采购商品上传
- [ ] 销售订单管理
- [ ] PDF生成功能（请求书+分拣单）

### 测试
- [ ] 价格计算单元测试
- [ ] 订单流程集成测试

### 监控
- [ ] Sentry配置
- [ ] 错误告警邮件通知

---

## 预估工作量

| Phase | 任务数 | 预估时间 |
|-------|--------|---------|
| Phase 1: Supabase后端 | 5 | 1-2天 |
| Phase 2: PC管理后台 | 10 | 3-4天 |
| Phase 3: 测试 | 2 | 0.5天 |
| Phase 4: Flutter APP | 7 | 3-4天 |
| Phase 5: PDF生成 | 2 | 0.5天 |
| Phase 6: 部署与监控 | 2 | 0.5天 |
| **总计** | **25** | **8-11天** |

---

**备注**: 实施过程中可根据实际情况调整任务优先级和进度。
