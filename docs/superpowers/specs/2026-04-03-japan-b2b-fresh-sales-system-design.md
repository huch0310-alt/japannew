# 日本B端生鲜销售系统 - 设计规范

**版本**: 1.0
**日期**: 2026-04-03
**状态**: 已确认

---

## 1. 系统概述

### 1.1 项目背景
面向日本B端客户的生鲜销售系统，基于Supabase全托管后端（东京节点），无需自建服务器。

### 1.2 技术栈

| 层级 | 技术 |
|------|------|
| PC管理后台 | Next.js 15 + ShadCN UI + Tailwind + v0.dev MCP |
| 客户采购APP | Flutter (账号+密码登录) |
| 内部工作人员APP | Flutter (账号+密码登录，采购/销售双角色) |
| 后端 | Supabase 东京节点 (PostgreSQL + RLS + Auth + Storage + Edge Functions) |
| 部署 | Cloudflare Pages |
| 监控 | Sentry |

### 1.3 多语言支持
- 日语 / 简体中文双语
- 默认语言：日语
- 所有界面文本、按钮、提示信息、错误信息全部支持日/中双语

---

## 2. 用户角色与权限体系

| 角色 | 权限范围 |
|------|---------|
| 超级管理员 | 拥有所有权限，管理所有用户、商品、订单、请求书、系统设置 |
| 销售主管 | 审核商品、制定销售价、上下架商品、确认订单、打印分拣单、合并生成请求书、标记收款、查看所有数据 |
| 采购人员 | 仅能上传/编辑自己提交的商品信息、查看自己负责的商品、查看采购相关订单 |
| B端客户 | 仅能查看自己的账号、浏览上架商品、下单、查看自己的订单历史和请求书 |

**核心原则**：无客户自主注册，所有账号由后台管理员统一创建。

---

## 3. 数据库架构

### 3.1 表结构

#### users (用户表 - 统一认证)
```
id: uuid PRIMARY KEY
email: text UNIQUE -- 员工登录用
phone: text UNIQUE -- 客户登录用
password_hash: text
role: enum -- super_admin/sales_manager/purchaser/customer
name: text
is_active: boolean DEFAULT true
created_at: timestamp
```

#### customers (客户档案)
```
id: uuid PK → users.id
company_name: text
company_name_zh: text
tax_id: text
postal_code: text
address: text
address_zh: text
contact_name: text
phone: text
discount_rate: numeric(5,2) -- 折扣率%，默认0
payment_term_days: int -- 付款期限(天)
```

#### products (商品表)
```
id: uuid PK
code: text UNIQUE -- 商品编码
name_ja: text
name_zh: text
category_id: uuid → categories.id
unit: enum -- 個/kg/g/袋/箱/束/本
purchase_price: int -- 采购价(円)
sale_price_ex_tax: int -- 税抜销售价
stock: int DEFAULT 0
stock_warning: int DEFAULT 10 -- 库存预警值
status: enum -- pending/approved/rejected
submitted_by: uuid → users.id -- 提交人
reject_reason: text
images: text[] -- Supabase Storage图片URLs
```

#### categories (商品分类)
```
id: uuid PK
name_ja: text
name_zh: text
parent_id: uuid → categories.id -- 二级分类
sort_order: int
```

#### orders (订单表)
```
id: uuid PK
order_number: text UNIQUE -- 订单号
customer_id: uuid → users.id
status: enum -- pending/confirmed/printed/invoiced/paid/cancelled
total_ex_tax: int -- 税抜合计
tax_amount: int -- 消费税(8%)
total_in_tax: int -- 税込合计
customer_note: text
printed_by: uuid → users.id
printed_at: timestamp
invoice_id: uuid → invoices.id
```

#### order_items (订单明细)
```
id: uuid PK
order_id: uuid → orders.id
product_id: uuid → products.id
quantity: numeric
unit_price_ex_tax: int -- 税抜单价
discounted_price: int -- 折扣后单价
line_total_ex_tax: int
order_date: date -- 日付
note: text
```

#### invoices (请求书表)
```
id: uuid PK
invoice_number: text UNIQUE -- 格式: Q+年月日+3位序号
customer_id: uuid → users.id
total_in_tax: int -- 税込合计
status: enum -- unpaid/paid/overdue
issue_date: date
due_date: date
paid_at: timestamp
pdf_url: text -- Supabase Storage
```

#### system_settings (系统设置)
```
id: uuid PK
company_name: text
company_address: text
company_phone: text
tax_id: text
bank_name: text
bank_branch: text
bank_account_type: text -- 普通口座
bank_account_number: text
tax_rate: numeric(3,2) -- 默认0.08
default_payment_term_days: int
```

### 3.2 关键设计点
- 价格/金额全部用 `int` 存储（日元，0位小数）
- RLS 按 role 隔离数据访问
- 商品/分类支持日/中双语存储
- 订单状态机：pending → confirmed → printed → invoiced → paid → cancelled

---

## 4. 价格计算逻辑

### 4.1 订单价格计算
```
折扣后单价 = 税抜单价 × (1 - 客户折扣率 / 100)
商品税抜金额 = 数量 × 折扣后单价
订单税抜合计 = Σ(所有商品税抜金额)
消费税额 = 订单税抜合计 × 消费税率 (8%)
订单税込合计 = 订单税抜合计 + 消费税额
```

### 4.2 日本标准消费税
- 默认税率：8%
- 支持按客户设置专属折扣率（默认0%）

---

## 5. PC后台管理端

### 5.1 技术栈
- Next.js 15
- ShadCN UI
- Tailwind CSS
- v0.dev MCP（UI生成）

### 5.2 全局基础
- 登录页：仅支持账号密码登录，无注册入口
- 顶部导航：语言切换（日/中）、个人信息、退出登录
- 侧边栏：根据用户角色动态显示菜单
- 全局通知：新订单提交、商品待审核实时提醒
- 所有列表支持导出Excel、打印功能

### 5.3 核心功能模块

#### 5.3.1 仪表盘
- 今日/本周/本月销售额、订单数、客户数统计卡片
- 销售额趋势图（按日）、商品销量排行TOP20
- 待审核商品数、待打印订单数、待生成请求书订单数、待收款请求书数
- 最近10条订单列表

#### 5.3.2 用户管理
- 客户账号管理：新增/编辑/禁用客户账号
- 内部人员管理：新增/编辑/禁用采购/销售人员账号，分配角色
- 支持批量导入客户账号Excel表格

#### 5.3.3 商品管理
- 商品列表：显示商品编码、名称、分类、采购价、税抜销售价、库存、状态
- 商品分类管理：支持两级分类
- 商品审核：审核通过/驳回，上下架
- 库存管理：手动调整库存、查看库存流水、设置库存预警阈值
- 支持批量上下架、批量修改价格

#### 5.3.4 订单管理
- 订单列表：显示订单号、客户名称、税込总金额、下单时间、订单状态
- 订单详情：显示完整商品明细、客户备注、价格计算
- 订单操作：确认订单、取消订单、打印分拣单
- 支持按时间、客户、状态筛选订单

#### 5.3.5 请求书管理
- 请求书列表：显示请求书编号、客户名称、税込总金额、生成日期、付款期限、状态
- 多订单合并生成功能
- 操作：查看详情、重新生成PDF、打印、下载PDF、标记已收款
- 支持按客户、生成日期、状态筛选请求书

#### 5.3.6 系统设置
- 公司信息：公司名称、地址、电话、税号、银行账户信息
- 全局设置：默认消费税率（默认8%）、默认付款期限
- 打印设置：请求书模板微调、分拣单模板微调
- 多语言设置：管理系统文本翻译

---

## 6. 客户采购APP

### 6.1 技术栈
- Flutter 跨平台 (iOS + Android)
- 与内部工作人员APP共用代码库

### 6.2 全局基础
- 登录页：仅支持账号+密码登录，无注册入口
- 底部导航：首页、分类、购物车、我的
- 语言切换：个人中心内切换日/中，偏好自动保存
- 所有价格默认显示税込价格，可切换查看税抜价格

### 6.3 核心功能模块

#### 6.3.1 首页
- 顶部搜索栏
- 快捷分类入口：4列网格布局
- 热销商品、新品上架专区
- 商品卡片：图片比例1:1，显示商品名称、规格、税込单价、库存

#### 6.3.2 分类页
- 左侧分类导航，右侧2列商品列表
- 排序按钮：默认排序、价格升序、价格降序

#### 6.3.3 购物车
- 商品列表：修改数量、删除商品
- 自动计算税込总价
- 提交订单：添加备注

#### 6.3.4 我的
- 个人信息：公司名称、联系人、地址、电话
- 我的订单：全部/待确认/已确认/已完成
- 我的请求书：查看所有已生成的请求书，支持下载PDF
- 修改密码
- 联系客服

---

## 7. 内部工作人员APP

### 7.1 技术栈
- Flutter 跨平台 (iOS + Android)
- 与客户采购APP共用代码库

### 7.2 采购人员端

#### 底部导航
首页 → 商品上传 → 我的

#### 核心功能
- 商品上传：支持拍照上传多张图片（最多5张），填写商品信息
- 我的商品：标签页切换待审核/已通过/已驳回
- 待审核商品可编辑，驳回原因红色显示

### 7.3 销售人员端

#### 底部导航
首页 → 商品管理 → 订单管理 → 我的

#### 核心功能
- 待审核商品：列表显示，支持滑动审核通过/驳回、批量审核、修改销售价
- 商品管理：搜索商品，一键上下架，长按修改销售价
- 订单管理：标签页切换不同状态订单，支持确认订单、打印分拣单
- 库存查询：查看所有商品库存，设置预警

---

## 8. 请求书PDF样式

### 8.1 布局结构
- A4纵向打印
- 顶部居中「請求書」大字标题
- 右上角问候语「毎度ありがとうございます。下記のとおりご請求申し上げます。」
- 左侧客户信息（公司名称+御中、邮编、地址）
- 右侧发行信息（请求日、发票号、我方公司信息）
- 银行汇款信息框
- **請求金額居中大框**（深蓝色边框，浅蓝色背景，位于商品明细表格上方）
- 商品明细表格：日付、商品名称、数量、单位、単価、金額、備考
- 表格右下角汇总：税抜合計、消費税額、税込合計

### 8.2 自动生成规则
- 请求书编号格式：Q+年月日+3位序号（如 Q20260403001）
- 所有我方信息从系统设置自动读取
- 所有客户信息从客户档案自动读取
- 消费税率从全局设置自动读取
- 自动应用客户专属折扣率

---

## 9. 分拣单样式

### 9.1 布局结构
- A4纸纵向打印
- 包含字段：订单号、客户名称、配送地址、联系人、联系电话、下单时间、备注
- 商品明细表格：数量、单位、商品名称、税抜单价、折扣后单价、税抜金額、備考
- 价格汇总：客户折扣率、税抜合計、消費税(8%)、税込合計
- 合计商品数、打印时间、打印人

---

## 10. UI设计规范

### 10.1 配色
- 主色调：#0F4C81
- 辅助色：#00B42A（成功）、#FF7D00（警告）、#F53F3F（危险）
- 中性色：严格灰度阶梯，避免纯黑纯白

### 10.2 排版
- 全局字体：'Noto Sans JP', 'Inter', sans-serif
- 数字和金额：等宽字体
- 建立清晰的字体层级，标题加粗，正文易读

### 10.3 组件
- 圆角：PC端6px，移动端8px
- 阴影：仅使用轻微阴影
- 间距：8px基准网格
- 按钮：主按钮深蓝色背景，白色文字

### 10.4 页面优化
- 表格：隔行变色，表头固定，重要数据加粗，状态用颜色标签区分
- 表单：左对齐标签，输入框圆角6px，提交按钮右对齐
- 所有加载状态使用骨架屏
- 所有操作添加成功/失败提示

---

## 11. 计价与单位规范

### 11.1 计价
- 货币：日元（JPY）
- 金额：保留0位小数

### 11.2 规格单位
- 日本常用单位：個、kg、g、袋、箱、束、本

---

## 12. 部署与交付

### 12.1 PC后台部署
- Cloudflare Pages
- 绑定自定义域名

### 12.2 Flutter APP打包
- APK：Android打包详细分步指令
- IPA：iOS打包详细分步指令

### 12.3 文档
- 图文版系统使用手册（分角色编写，面向非技术人员）

### 12.4 监控
- 配置Sentry错误监控
- 自动捕获系统异常并发送邮件通知

---

## 13. 多语言与本地化

### 13.1 界面文本
- 所有界面文本、按钮、提示信息、错误信息全部支持日/中双语

### 13.2 格式适配
- 日期格式：日本标准
- 数字格式：日本标准
- 货币格式：日本标准

### 13.3 商品多语言
- 商品名称、分类、说明支持多语言存储
- 根据用户语言自动显示

### 13.4 文档双语
- 请求书和分拣单默认生成日语版本
- 支持切换生成中文版本

---

## 14. 待确认事项

### 14.1 请求书样式
- 用户将提供日本商务请求书样式模板
- 实现时需严格1:1还原

### 14.2 UI细节调整
- 设计细节可在开发过程中根据实际效果调整

---

**备注**：本设计文档为初始版本，具体实现时可根据实际情况进行调整。
