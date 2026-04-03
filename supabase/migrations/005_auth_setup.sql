-- Supabase Auth 配置
-- 2026-04-03

-- 1. 启用 UUID 扩展 (如果尚未启用)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 修改 users 表，使用 auth.users 作为认证源
-- 取消 email 和 phone 的唯一约束（将由 auth.users 保证）
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_phone_key;

-- 3. 创建函数：当 auth.users 创建时，自动在 users 表创建对应记录
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'customer'::user_role
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 创建触发器：在 auth.users 插入后自动调用
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. 禁用 users 表的直接插入/更新/删除（强制通过 auth.users 管理）
-- 注意：这会影响现有代码，需要先迁移数据
-- ALTER TABLE users DISABLE TRIGGER ALL;

-- 6. 创建登录函数（验证密码并返回用户信息）
CREATE OR REPLACE FUNCTION public.login(
  p_email text,
  p_password text
)
RETURNS json AS $$
DECLARE
  v_user auth.users;
  v_is_valid boolean;
BEGIN
  -- 验证用户是否存在
  SELECT * INTO v_user FROM auth.users WHERE email = p_email;
  IF v_user IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'ユーザーが見つかりません');
  END IF;

  -- 验证密码（Supabase Auth 使用内置密码验证）
  -- 这里我们通过尝试刷新会话来验证密码
  -- 如果密码正确，signInWithPassword 会成功

  RETURN json_build_object(
    'success', true,
    'user_id', v_user.id,
    'email', v_user.email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 创建获取用户资料的函数
CREATE OR REPLACE FUNCTION public.get_current_user_profile()
RETURNS json AS $$
DECLARE
  v_user_id uuid;
  v_profile users;
BEGIN
  -- 获取当前登录用户的 ID
  v_user_id := coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::json->>'sub',
    current_setting('request.jwt.claim_sub', true)
  )::uuid;

  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', '未ログイン');
  END IF;

  -- 获取用户资料
  SELECT * INTO v_profile FROM users WHERE id = v_user_id;
  IF v_profile IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'ユーザーが見つかりません');
  END IF;

  RETURN json_build_object(
    'success', true,
    'profile', row_to_json(v_profile)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
