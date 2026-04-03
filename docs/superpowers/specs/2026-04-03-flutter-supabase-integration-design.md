# Flutter APP Supabase集成设计规范

**版本**: 1.0
**日期**: 2026-04-03
**状态**: 已确认

---

## 1. 架构概览

采用 **Provider模式** 进行状态管理，符合Flutter官方推荐。

```
lib/
├── models/                     # 数据模型
│   ├── product.dart           # 商品模型
│   ├── category.dart           # 分类模型
│   ├── cart_item.dart         # 购物车项模型
│   ├── order.dart              # 订单模型
│   └── order_item.dart        # 订单明细模型
├── providers/                  # Provider状态管理
│   ├── auth_provider.dart     # 认证状态
│   ├── product_provider.dart  # 商品列表
│   ├── cart_provider.dart     # 购物车
│   └── order_provider.dart     # 订单
├── services/                   # 服务层
│   └── supabase_service.dart  # Supabase客户端封装
├── customer/screens/           # 客户APP页面
│   ├── home_screen.dart
│   ├── cart_screen.dart
│   └── order_history_screen.dart
└── staff/screens/              # 员工APP页面
    ├── product_upload_screen.dart
    ├── my_products_screen.dart
    └── order_management_screen.dart
```

---

## 2. 数据模型

### 2.1 Product (商品)

```dart
class Product {
  final String id;
  final String code;           // 商品编码
  final String nameJa;         // 日语名称
  final String? nameZh;       // 中文名称
  final String? categoryId;    // 分类ID
  final String unit;           // 单位
  final int purchasePrice;     // 采购价
  final int salePriceExTax;    // 税抜销售价
  final int stock;             // 库存
  final String status;         // pending/approved/rejected
  final String? rejectReason;   // 驳回原因
  final List<String>? images;   // 图片URLs

  // 计算属性
  int get salePriceInTax => (salePriceExTax * 1.08).round();
}
```

### 2.2 Category (分类)

```dart
class Category {
  final String id;
  final String nameJa;
  final String? nameZh;
  final String? parentId;
  final int sortOrder;
}
```

### 2.3 CartItem (购物车项)

```dart
class CartItem {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final int unitPriceExTax;
  final String? imageUrl;

  int get lineTotalExTax => quantity * unitPriceExTax;
  int get lineTotalInTax => (lineTotalExTax * 1.08).round();
}
```

### 2.4 Order (订单)

```dart
class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String status;
  final int totalExTax;
  final int taxAmount;
  final int totalInTax;
  final String? customerNote;
  final DateTime createdAt;
  final List<OrderItem> items;
}
```

---

## 3. Provider职责

| Provider | 职责 | 核心方法 |
|----------|------|---------|
| `AuthProvider` | 用户认证状态、登录/登出 | `signIn()`, `signOut()`, `currentUser` |
| `ProductProvider` | 商品列表、分类、搜索 | `getProducts()`, `getCategories()`, `getProductById()` |
| `CartProvider` | 购物车增删改、订单提交 | `addItem()`, `removeItem()`, `updateQuantity()`, `submitOrder()` |
| `OrderProvider` | 订单历史、订单状态 | `getOrders()`, `getOrderById()`, `updateStatus()` |

---

## 4. Supabase服务接口

### 4.1 认证服务

```dart
class SupabaseService {
  // 登录
  Future<User?> signIn(String email, String password);

  // 登出
  Future<void> signOut();

  // 获取当前用户
  User? get currentUser;

  // 监听认证状态变化
  Stream<User?> get onAuthStateChanged;
}
```

### 4.2 商品服务

```dart
  // 获取已审核商品列表
  Future<List<Product>> getApprovedProducts();

  // 获取商品分类
  Future<List<Category>> getCategories();

  // 按分类获取商品
  Future<List<Product>> getProductsByCategory(String categoryId);

  // 搜索商品
  Future<List<Product>> searchProducts(String query);
```

### 4.3 订单服务

```dart
  // 提交订单
  Future<Order> createOrder({
    required String customerId,
    required List<CartItem> items,
    String? customerNote,
  });

  // 获取客户订单历史
  Future<List<Order>> getCustomerOrders(String customerId);

  // 获取订单明细
  Future<Order?> getOrderWithItems(String orderId);
```

### 4.4 购物车服务

```dart
  // 购物车数据本地持久化（使用shared_preferences）
  // 服务器端不存储购物车，购物车属于客户端状态
```

---

## 5. 页面改造清单

### 5.1 客户APP

| 页面 | 改造内容 |
|------|---------|
| `home_screen.dart` | 从`ProductProvider`获取热销/新品数据 |
| `cart_screen.dart` | 使用`CartProvider`，提交订单调用`createOrder()` |
| `order_history_screen.dart` | 从`OrderProvider`获取订单列表 |
| `main_screen.dart` | 初始化Providers，底部导航 |

### 5.2 员工APP

| 页面 | 改造内容 |
|------|---------|
| `product_upload_screen.dart` | 调用Supabase插入商品 |
| `my_products_screen.dart` | 从Supabase获取采购人员自己上传的商品 |
| `order_management_screen.dart` | 从Supabase获取所有订单，支持状态更新 |

---

## 6. 错误处理

| 错误类型 | 处理方式 |
|----------|---------|
| 网络错误 | SnackBar提示"ネットワークエラー。もう一度お試しください。" |
| 认证失效 | 跳转登录页 |
| 数据为空 | 显示空状态占位 |
| 提交失败 | SnackBar提示失败原因 |

---

## 7. 本地化价格显示

- 所有价格默认显示**税込**价格
- 金额使用`int`存储，以日元为单位
- 格式化：`¥{NumberFormat('#,###').format(amount)}`

---

**备注**：本设计为Flutter APP Supabase集成专项设计，补充主设计文档。
