# 数据库设置指南

## 前提条件

1. Supabase 项目已创建 (https://supabase.com/dashboard)
2. 已获取 Supabase Access Token

## 步骤 1: 获取 Supabase Access Token

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 点击右上角头像 → **Account Settings**
3. 进入 **Access Tokens** 页面
4. 点击 **New access token** 生成令牌
5. 复制令牌并添加到 GitHub Secrets:
   - 进入 GitHub 仓库 → **Settings** → **Secrets and variables** → **Actions**
   - 添加 `SUPABASE_ACCESS_TOKEN` = 你的访问令牌

## 步骤 2: 在本地应用数据库迁移 (可选)

如果你想在本地开发，需要:

```bash
# 安装 Supabase CLI
# Windows (使用管理员权限):
scoop install supabase

# 或者下载二进制:
# https://github.com/supabase/cli/releases

# 链接项目
supabase link --project-ref mfasmbmddjwzmtwgdgyf

# 推送迁移
supabase db push
```

## 步骤 3: 验证设置

运行以下命令验证数据库连接:

```bash
# 检查表是否存在
curl "https://mfasmbmddjwzmtwgdgyf.supabase.co/rest/v1/users?select=id&limit=1" \
  -H "apikey: sb_publishable_Ozx1fOoj4aoGewQntYSj4A_Vw5Po8cU" \
  -H "Authorization: Bearer sb_publishable_Ozx1fOoj4aoGewQntYSj4A_Vw5Po8cU"
```

如果返回空数组或错误，说明需要先执行 schema。

## 数据库 Schema 说明

Schema 文件位于: `docs/supabase-schema.sql`

包含以下表:
- `users` - 用户表
- `customers` - 客户档案表
- `categories` - 商品分类表
- `products` - 商品表
- `orders` - 订单表
- `order_items` - 订单明细表
- `invoices` - 请求书表
- `system_settings` - 系统设置表

## 故障排除

### 问题: "Could not find the table"
**解决**: 数据库 schema 未应用。请执行 `docs/supabase-schema.sql` 中的 SQL。

### 问题: RLS 策略阻止访问
**解决**: 检查 `users` 表是否有管理员角色的用户，然后通过管理员账户进行操作。
