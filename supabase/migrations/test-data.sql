-- 测试数据脚本
-- 在 Supabase SQL Editor 中执行

-- 创建测试用户
INSERT INTO users (id, email, password_hash, role, name) VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@test.com', 'hashed_password_here', 'super_admin', 'Admin'),
  ('22222222-2222-2222-2222-222222222222', 'sales@test.com', 'hashed_password_here', 'sales_manager', 'Sales Manager'),
  ('33333333-3333-3333-3333-333333333333', 'purchaser@test.com', 'hashed_password_here', 'purchaser', 'Purchaser'),
  ('44444444-4444-4444-4444-444444444444', 'customer@test.com', 'hashed_password_here', 'customer', 'Customer');

-- 创建测试商品分类
INSERT INTO categories (id, name_ja, name_zh, sort_order) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '野菜', '蔬菜', 1),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '精肉', '肉类', 2),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '鮮魚', '鲜鱼', 3),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '果物', '水果', 4);

-- 创建测试商品（需要先获取 purchaser 用户 ID）
-- 使用上面创建的 purchaser ID
DO $$
DECLARE
  purchaser_id UUID := '33333333-3333-3333-3333-333333333333';
  cat_veg UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  cat_meat UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
BEGIN
  -- 插入测试商品
  INSERT INTO products (id, code, name_ja, name_zh, category_id, unit, purchase_price, sale_price_ex_tax, stock, stock_warning, status, submitted_by) VALUES
    (gen_random_uuid(), 'P001', 'ほうれん草', '菠菜', cat_veg, '束', 100, 180, 100, 10, 'approved', purchaser_id),
    (gen_random_uuid(), 'P002', '大根', '白萝卜', cat_veg, '本', 80, 150, 50, 10, 'approved', purchaser_id),
    (gen_random_uuid(), 'P003', '白菜', '白菜', cat_veg, '個', 200, 350, 30, 5, 'approved', purchaser_id),
    (gen_random_uuid(), 'P004', '和牛カルビ', '和牛牛小排', cat_meat, 'g', 1500, 2500, 5000, 500, 'pending', purchaser_id);
END $$;
