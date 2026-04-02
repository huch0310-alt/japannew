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
