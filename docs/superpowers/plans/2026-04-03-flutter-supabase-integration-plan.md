# Flutter APP Supabase集成实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将Flutter APP的所有页面从mock数据改造为通过Supabase获取真实数据

**Architecture:** 使用Provider模式进行状态管理，数据模型与Supabase数据库表结构一一对应，通过Service层封装所有数据库操作

**Tech Stack:** Flutter + Provider + Supabase Flutter SDK + shared_preferences

---

## 文件结构

```
flutter-app/lib/
├── models/
│   ├── product.dart          # 商品模型
│   ├── category.dart         # 分类模型
│   ├── cart_item.dart       # 购物车项模型
│   ├── order.dart            # 订单模型
│   └── order_item.dart       # 订单明细模型
├── providers/
│   ├── auth_provider.dart     # 认证状态管理
│   ├── product_provider.dart  # 商品数据管理
│   ├── cart_provider.dart     # 购物车状态管理
│   └── order_provider.dart    # 订单状态管理
├── services/
│   └── supabase_service.dart  # Supabase操作封装
└── (existing screens will be modified)
```

---

## Task 1: 创建数据模型

**Files:**
- Create: `flutter-app/lib/models/product.dart`
- Create: `flutter-app/lib/models/category.dart`
- Create: `flutter-app/lib/models/cart_item.dart`
- Create: `flutter-app/lib/models/order.dart`
- Create: `flutter-app/lib/models/order_item.dart`

- [ ] **Step 1: 创建product.dart**

```dart
// flutter-app/lib/models/product.dart

class Product {
  final String id;
  final String code;
  final String nameJa;
  final String? nameZh;
  final String? categoryId;
  final String unit;
  final int purchasePrice;
  final int salePriceExTax;
  final int stock;
  final String status;
  final String? rejectReason;
  final List<String>? images;

  const Product({
    required this.id,
    required this.code,
    required this.nameJa,
    this.nameZh,
    this.categoryId,
    required this.unit,
    required this.purchasePrice,
    required this.salePriceExTax,
    required this.stock,
    required this.status,
    this.rejectReason,
    this.images,
  });

  int get salePriceInTax => (salePriceExTax * 1.08).round();

  String get displayName => nameJa;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      code: json['code'] as String,
      nameJa: json['name_ja'] as String,
      nameZh: json['name_zh'] as String?,
      categoryId: json['category_id'] as String?,
      unit: json['unit'] as String,
      purchasePrice: json['purchase_price'] as int,
      salePriceExTax: json['sale_price_ex_tax'] as int,
      stock: json['stock'] as int,
      status: json['status'] as String,
      rejectReason: json['reject_reason'] as String?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ja': nameJa,
      'name_zh': nameZh,
      'category_id': categoryId,
      'unit': unit,
      'purchase_price': purchasePrice,
      'sale_price_ex_tax': salePriceExTax,
      'stock': stock,
      'status': status,
      'reject_reason': rejectReason,
      'images': images,
    };
  }
}
```

- [ ] **Step 2: 创建category.dart**

```dart
// flutter-app/lib/models/category.dart

class Category {
  final String id;
  final String nameJa;
  final String? nameZh;
  final String? parentId;
  final int sortOrder;

  const Category({
    required this.id,
    required this.nameJa,
    this.nameZh,
    this.parentId,
    required this.sortOrder,
  });

  String get displayName => nameJa;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nameJa: json['name_ja'] as String,
      nameZh: json['name_zh'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
```

- [ ] **Step 3: 创建cart_item.dart**

```dart
// flutter-app/lib/models/cart_item.dart

class CartItem {
  final String productId;
  final String productName;
  final String unit;
  final int quantity;
  final int unitPriceExTax;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPriceExTax,
    this.imageUrl,
  });

  int get lineTotalExTax => quantity * unitPriceExTax;
  int get lineTotalInTax => (lineTotalExTax * 1.08).round();

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity ?? this.quantity,
      unitPriceExTax: unitPriceExTax,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit': unit,
      'quantity': quantity,
      'unit_price_ex_tax': unitPriceExTax,
      'image_url': imageUrl,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as int,
      unitPriceExTax: json['unit_price_ex_tax'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}
```

- [ ] **Step 4: 创建order_item.dart**

```dart
// flutter-app/lib/models/order_item.dart

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPriceExTax;
  final int discountedPrice;
  final int lineTotalExTax;
  final String? note;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceExTax,
    required this.discountedPrice,
    required this.lineTotalExTax,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
      unitPriceExTax: json['unit_price_ex_tax'] as int,
      discountedPrice: json['discounted_price'] as int,
      lineTotalExTax: json['line_total_ex_tax'] as int,
      note: json['note'] as String?,
    );
  }
}
```

- [ ] **Step 5: 创建order.dart**

```dart
// flutter-app/lib/models/order.dart

import 'order_item.dart';

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

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.status,
    required this.totalExTax,
    required this.taxAmount,
    required this.totalInTax,
    this.customerNote,
    required this.createdAt,
    this.items = const [],
  });

  static const Map<String, String> statusLabels = {
    'pending': '未確認',
    'confirmed': '確認済',
    'printed': '印刷済',
    'invoiced': '請求書済',
    'paid': '支払済',
    'cancelled': 'キャンセル',
  };

  String get statusLabel => statusLabels[status] ?? status;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      status: json['status'] as String,
      totalExTax: json['total_ex_tax'] as int,
      taxAmount: json['tax_amount'] as int,
      totalInTax: json['total_in_tax'] as int,
      customerNote: json['customer_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
```

- [ ] **Step 6: 提交**

```bash
git add flutter-app/lib/models/
git commit -m "feat(flutter): add data models for Supabase integration

- Product model with price calculation
- Category model
- CartItem model for shopping cart
- Order and OrderItem models

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: 创建Supabase服务层

**Files:**
- Create: `flutter-app/lib/services/supabase_service.dart`

- [ ] **Step 1: 创建supabase_service.dart**

```dart
// flutter-app/lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // ============ 认证 ============

  Future<User?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get onAuthStateChanged => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  // ============ 商品 ============

  Future<List<Product>> getApprovedProducts() async {
    final response = await _client
        .from('products')
        .select()
        .eq('status', 'approved')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('status', 'approved')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await _client
        .from('products')
        .select()
        .eq('status', 'approved')
        .or('name_ja.ilike.%$query%,name_zh.ilike.%$query%,code.ilike.%$query%')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final response = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }

  Future<void> uploadProduct({
    required String code,
    required String nameJa,
    String? nameZh,
    String? categoryId,
    required String unit,
    required int purchasePrice,
    required int stock,
    String? descriptionJa,
    String? descriptionZh,
    List<String>? images,
  }) async {
    await _client.from('products').insert({
      'code': code,
      'name_ja': nameJa,
      'name_zh': nameZh,
      'category_id': categoryId,
      'unit': unit,
      'purchase_price': purchasePrice,
      'sale_price_ex_tax': purchasePrice,
      'stock': stock,
      'status': 'pending',
      'submitted_by': currentUser?.id,
      'description_ja': descriptionJa,
      'description_zh': descriptionZh,
      'images': images,
    });
  }

  Future<List<Product>> getMyProducts(String userId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('submitted_by', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  // ============ 分类 ============

  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  // ============ 订单 ============

  Future<Order> createOrder({
    required String customerId,
    required List<CartItem> items,
    String? customerNote,
  }) async {
    // 计算价格
    int totalExTax = 0;
    for (final item in items) {
      totalExTax += item.lineTotalExTax;
    }
    int taxAmount = (totalExTax * AppConfig.defaultTaxRate).round();
    int totalInTax = totalExTax + taxAmount;

    // 创建订单
    final orderResponse = await _client.from('orders').insert({
      'customer_id': customerId,
      'status': 'pending',
      'total_ex_tax': totalExTax,
      'tax_amount': taxAmount,
      'total_in_tax': totalInTax,
      'customer_note': customerNote,
    }).select().single();

    // 创建订单明细
    final orderId = orderResponse['id'] as String;
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'product_id': item.productId,
      'quantity': item.quantity,
      'unit_price_ex_tax': item.unitPriceExTax,
      'discounted_price': item.unitPriceExTax,
      'line_total_ex_tax': item.lineTotalExTax,
    }).toList();

    await _client.from('order_items').insert(orderItems);

    return getOrderById(orderId) ?? Order.fromJson(orderResponse);
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }

  // ============ 订单管理（员工） ============

  Future<List<Order>> getAllOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/services/
git commit -m "feat(flutter): add SupabaseService for database operations

- Authentication methods (signIn, signOut)
- Product CRUD operations
- Category queries
- Order creation and queries
- Employee order management

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: 创建Providers

**Files:**
- Create: `flutter-app/lib/providers/auth_provider.dart`
- Create: `flutter-app/lib/providers/product_provider.dart`
- Create: `flutter-app/lib/providers/cart_provider.dart`
- Create: `flutter-app/lib/providers/order_provider.dart`

- [ ] **Step 1: 创建auth_provider.dart**

```dart
// flutter-app/lib/providers/auth_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Stream<User?> get authStateChanges => _supabase.onAuthStateChanged;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _supabase.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
    _user = null;
    notifyListeners();
  }

  void checkAuth() {
    _user = _supabase.currentUser;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

- [ ] **Step 2: 创建product_provider.dart**

```dart
// flutter-app/lib/providers/product_provider.dart

import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<Product> _products = [];
  List<Category> _categories = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 热销商品（取前6个）
  List<Product> get hotProducts => _products.take(6).toList();

  // 新品（按创建时间排序取前6个）
  List<Product> get newProducts {
    final sorted = List<Product>.from(_products)
      ..sort((a, b) => b.code.compareTo(a.code));
    return sorted.take(6).toList();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _supabase.getApprovedProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _supabase.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadProductsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _supabase.getProductsByCategory(categoryId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _supabase.searchProducts(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> getProductById(String id) async {
    try {
      _selectedProduct = await _supabase.getProductById(id);
      notifyListeners();
      return _selectedProduct;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> uploadProduct({
    required String code,
    required String nameJa,
    String? nameZh,
    String? categoryId,
    required String unit,
    required int purchasePrice,
    required int stock,
    String? descriptionJa,
    String? descriptionZh,
    List<String>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.uploadProduct(
        code: code,
        nameJa: nameJa,
        nameZh: nameZh,
        categoryId: categoryId,
        unit: unit,
        purchasePrice: purchasePrice,
        stock: stock,
        descriptionJa: descriptionJa,
        descriptionZh: descriptionZh,
        images: images,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Product>> getMyProducts(String userId) async {
    try {
      return await _supabase.getMyProducts(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

- [ ] **Step 3: 创建cart_provider.dart**

```dart
// flutter-app/lib/providers/cart_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class CartProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  final List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  int get totalExTax => _items.fold(0, (sum, item) => sum + item.lineTotalExTax);
  int get taxAmount => (totalExTax * 0.08).round();
  int get totalInTax => totalExTax + taxAmount;

  static const String _cartKey = 'cart_items';

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items.clear();
        _items.addAll(decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (e) {
      // 忽略加载错误
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      // 忽略保存错误
    }
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        productId: product.id,
        productName: product.nameJa,
        unit: product.unit,
        quantity: quantity,
        unitPriceExTax: product.salePriceExTax,
        imageUrl: product.images?.isNotEmpty == true ? product.images!.first : null,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  Future<bool> submitOrder(String customerId, {String? customerNote}) async {
    if (_items.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.createOrder(
        customerId: customerId,
        items: _items,
        customerNote: customerNote,
      );
      clearCart();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

- [ ] **Step 4: 创建order_provider.dart**

```dart
// flutter-app/lib/providers/order_provider.dart

import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 按状态筛选订单
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((o) => o.status == status).toList();
  }

  List<Order> get pendingOrders => getOrdersByStatus('pending');
  List<Order> get confirmedOrders => getOrdersByStatus('confirmed');
  List<Order> get printedOrders => getOrdersByStatus('printed');
  List<Order> get invoicedOrders => getOrdersByStatus('invoiced');

  Future<void> loadCustomerOrders(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _supabase.getCustomerOrders(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _supabase.getAllOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      _selectedOrder = await _supabase.getOrderById(orderId);
      notifyListeners();
      return _selectedOrder;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.updateOrderStatus(orderId, status);
      // 更新本地数据
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = Order(
          id: _orders[index].id,
          orderNumber: _orders[index].orderNumber,
          customerId: _orders[index].customerId,
          status: status,
          totalExTax: _orders[index].totalExTax,
          taxAmount: _orders[index].taxAmount,
          totalInTax: _orders[index].totalInTax,
          customerNote: _orders[index].customerNote,
          createdAt: _orders[index].createdAt,
          items: _orders[index].items,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

- [ ] **Step 5: 提交**

```bash
git add flutter-app/lib/providers/
git commit -m "feat(flutter): add Provider state management

- AuthProvider for authentication state
- ProductProvider for product/category data
- CartProvider with local persistence
- OrderProvider for order management

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: 修改main.dart集成Providers

**Files:**
- Modify: `flutter-app/lib/main.dart`

- [ ] **Step 1: 修改main.dart**

```dart
// flutter-app/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'services/supabase_service.dart';
import 'customer/screens/login_screen.dart';
import 'customer/screens/main_screen.dart';
import 'staff/screens/product_upload_screen.dart';
import 'staff/screens/my_products_screen.dart';
import 'staff/screens/order_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Supabase
  final supabase = SupabaseService();
  await supabase.initialize();

  runApp(const FreshBizApp());
}

class FreshBizApp extends StatelessWidget {
  const FreshBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'FreshBiz',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ja'),
        supportedLocales: const [
          Locale('ja'),
          Locale('zh'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F4C81),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Noto Sans JP',
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/customer': (context) => const MainScreen(),
          '/staff/upload': (context) => const ProductUploadScreen(),
          '/staff/products': (context) => const MyProductsScreen(),
          '/staff/orders': (context) => const OrderManagementScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 检查当前认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    // 根据角色路由
    final role = authProvider.user!.userMetadata?['role'] as String? ?? 'customer';
    if (role == 'purchaser' || role == 'sales_manager') {
      return const StaffHome();
    }
    return const MainScreen();
  }
}

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _currentIndex = 0;

  final _screens = const [
    ProductUploadScreen(),
    MyProductsScreen(),
    OrderManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_outlined),
            selectedIcon: Icon(Icons.upload),
            label: '上传',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '商品',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/main.dart
git commit -m "feat(flutter): integrate Providers in main.dart

- MultiProvider with all providers
- AuthProvider for auth state management
- ProductProvider, CartProvider, OrderProvider

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: 修改登录页面使用AuthProvider

**Files:**
- Modify: `flutter-app/lib/customer/screens/login_screen.dart`

- [ ] **Step 1: 修改login_screen.dart**

```dart
// flutter-app/lib/customer/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signIn(
      _accountController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'ログインに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  prefixText: '🔒 ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: authProvider.isLoading
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

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/customer/screens/login_screen.dart
git commit -m "feat(flutter): update LoginScreen to use AuthProvider

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: 修改首页使用ProductProvider

**Files:**
- Modify: `flutter-app/lib/customer/screens/home_screen.dart`

- [ ] **Step 1: 修改home_screen.dart**

```dart
// flutter-app/lib/customer/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ProductProvider>().searchProducts(query);
  }

  void _addToCart(Product product) {
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.nameJa}をカートに追加しました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FreshBiz'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(
                  onSearch: _onSearch,
                  controller: _searchController,
                ),
              );
            },
          ),
        ],
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.error != null
              ? Center(child: Text('エラー: ${productProvider.error}'))
              : RefreshIndicator(
                  onRefresh: () => productProvider.loadProducts(),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 搜索栏
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '商品を検索...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            onSubmitted: _onSearch,
                          ),
                        ),

                        // 分类网格
                        if (productProvider.categories.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: productProvider.categories.take(4).map((cat) {
                                return _buildCategoryItem(
                                  cat.nameJa,
                                  _getCategoryIcon(cat.nameJa),
                                  _getCategoryColor(cat.nameJa),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 热销商品
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('人気商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () {},
                                child: const Text('もっと見る'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: productProvider.hotProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.hotProducts[index];
                              return _buildProductCard(product, _addToCart);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 新商品
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('新商品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () {},
                                child: const Text('もっと見る'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: productProvider.newProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.newProducts[index];
                              return _buildProductCard(product, _addToCart);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildProductCard(Product product, Function(Product) onAddToCart) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: product.images?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      product.images!.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                    ),
                  )
                : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nameJa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text('¥${NumberFormat('#,###').format(product.salePriceInTax)}', style: const TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onAddToCart(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('追加', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case '野菜':
        return Icons.eco;
      case '精肉':
        return Icons.restaurant;
      case '鮮魚':
        return Icons.set_meal;
      case '果物':
        return Icons.apple;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case '野菜':
        return Colors.green;
      case '精肉':
        return Colors.red;
      case '鮮魚':
        return Colors.blue;
      case '果物':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  final TextEditingController controller;

  ProductSearchDelegate({required this.onSearch, required this.controller});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('検索어를 입력하세요'));
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/customer/screens/home_screen.dart
git commit -m "feat(flutter): update HomeScreen to use ProductProvider

- Load products and categories from Supabase
- Add to cart functionality
- Search delegate

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: 修改购物车页面使用CartProvider

**Files:**
- Modify: `flutter-app/lib/customer/screens/cart_screen.dart`

- [ ] **Step 1: 修改cart_screen.dart**

```dart
// flutter-app/lib/customer/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    return Column(
      children: [
        Expanded(
          child: cartProvider.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('カートは空です', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return _CartItem(
                      item: item,
                      onQuantityChanged: (qty) {
                        cartProvider.updateQuantity(item.productId, qty);
                      },
                      onRemove: () {
                        cartProvider.removeItem(item.productId);
                      },
                    );
                  },
                ),
        ),
        if (!cartProvider.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).round()),
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
                    Text('${cartProvider.itemCount}点'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('税抜合計', style: TextStyle(color: Colors.grey)),
                    Text('¥${NumberFormat('#,###').format(cartProvider.totalExTax)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('消費税(8%)', style: TextStyle(color: Colors.grey)),
                    Text('¥${NumberFormat('#,###').format(cartProvider.taxAmount)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('合計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '¥${NumberFormat('#,###').format(cartProvider.totalInTax)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C81)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartProvider.isLoading
                        ? null
                        : () => _submitOrder(context, cartProvider, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: cartProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('注文を確定する', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _submitOrder(BuildContext context, CartProvider cartProvider, AuthProvider authProvider) async {
    final user = authProvider.user;
    if (user == null) return;

    final success = await cartProvider.submitOrder(user.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注文を確定しました'),
          backgroundColor: Colors.green,
        ),
      );
      // 刷新订单列表
      context.read<OrderProvider>().loadCustomerOrders(user.id);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.error ?? '注文の確定に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CartItem extends StatelessWidget {
  final dynamic item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItem({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item.unit} • ¥${NumberFormat('#,###').format(item.unitPriceExTax)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                child: GestureDetector(
                  onTap: () => onQuantityChanged(item.quantity - 1),
                  child: const Center(child: Text('-', style: TextStyle(fontSize: 16))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () => onQuantityChanged(item.quantity + 1),
                  child: const Center(child: Text('+', style: TextStyle(fontSize: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            '¥${NumberFormat('#,###').format(item.lineTotalInTax)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/customer/screens/cart_screen.dart
git commit -m "feat(flutter): update CartScreen to use CartProvider

- Real cart item display
- Quantity update and remove
- Order submission with price calculation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: 修改订单历史页面使用OrderProvider

**Files:**
- Modify: `flutter-app/lib/customer/screens/order_history_screen.dart`

- [ ] **Step 1: 修改order_history_screen.dart**

```dart
// flutter-app/lib/customer/screens/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<OrderProvider>().loadCustomerOrders(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文履歴'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.orders.isEmpty
              ? const Center(child: Text('注文履歴がありません'))
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = context.read<AuthProvider>().user;
                    if (user != null) {
                      await orderProvider.loadCustomerOrders(user.id);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.orders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      return _OrderCard(order: order);
                    },
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColors = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'printed': Colors.green,
      'invoiced': Colors.purple,
      'paid': Colors.teal,
      'cancelled': Colors.red,
    };
    final statusColor = statusColors[order.status] ?? Colors.grey;

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
                Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (statusColor as Color).withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '注文日: ${DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(),
            ...order.items.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text('¥${NumberFormat('#,###').format(item.lineTotalExTax)}'),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('合計', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '¥${NumberFormat('#,###').format(order.totalInTax)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/customer/screens/order_history_screen.dart
git commit -m "feat(flutter): update OrderHistoryScreen to use OrderProvider

- Load customer orders from Supabase
- Display order list with status

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: 修改员工商品页面使用ProductProvider

**Files:**
- Modify: `flutter-app/lib/staff/screens/my_products_screen.dart`

- [ ] **Step 1: 修改my_products_screen.dart**

```dart
// flutter-app/lib/staff/screens/my_products_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _pendingProducts = [];
  List<Product> _approvedProducts = [];
  List<Product> _rejectedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final products = await context.read<ProductProvider>().getMyProducts(user.id);

    setState(() {
      _pendingProducts = products.where((p) => p.status == 'pending').toList();
      _approvedProducts = products.where((p) => p.status == 'approved').toList();
      _rejectedProducts = products.where((p) => p.status == 'rejected').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('私の商品'),
        backgroundColor: const Color(0xFF3ECF8E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: '審査中(${_pendingProducts.length})'),
            Tab(text: '通過(${_approvedProducts.length})'),
            Tab(text: '拒否(${_rejectedProducts.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ProductList(products: _pendingProducts, status: 'pending', onRefresh: _loadProducts),
                _ProductList(products: _approvedProducts, status: 'approved', onRefresh: _loadProducts),
                _ProductList(products: _rejectedProducts, status: 'rejected', onRefresh: _loadProducts),
              ],
            ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String status;
  final Future<void> Function() onRefresh;

  const _ProductList({
    required this.products,
    required this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('商品がありません'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
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
                child: const Center(child: Icon(Icons.eco, color: Color(0xFF3ECF8E), size: 28)),
              ),
              title: Text(product.nameJa),
              subtitle: Text('¥${NumberFormat('#,###').format(product.purchasePrice)}'),
              trailing: status == 'rejected'
                  ? Text(product.rejectReason ?? '拒否理由', style: const TextStyle(color: Colors.red, fontSize: 12))
                  : status == 'pending'
                      ? const Icon(Icons.edit)
                      : null,
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/staff/screens/my_products_screen.dart
git commit -m "feat(flutter): update MyProductsScreen to use ProductProvider

- Load purchaser's products from Supabase
- Filter by status (pending/approved/rejected)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 10: 修改员工订单管理页面使用OrderProvider

**Files:**
- Modify: `flutter-app/lib/staff/screens/order_management_screen.dart`

- [ ] **Step 1: 修改order_management_screen.dart**

```dart
// flutter-app/lib/staff/screens/order_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await context.read<OrderProvider>().loadAllOrders();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文管理'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: '未確認(${orderProvider.pendingOrders.length})'),
            Tab(text: '確認済(${orderProvider.confirmedOrders.length})'),
            Tab(text: '印刷済(${orderProvider.printedOrders.length})'),
            Tab(text: '請求書済(${orderProvider.invoicedOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: orderProvider.pendingOrders, status: 'pending', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.confirmedOrders, status: 'confirmed', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.printedOrders, status: 'printed', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.invoicedOrders, status: 'invoiced', onRefresh: _loadOrders),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List orders;
  final String status;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.status,
    required this.onRefresh,
  });

  static const Map<String, String> _statusLabels = {
    'pending': '未確認',
    'confirmed': '確認済',
    'printed': '印刷済',
    'invoiced': '請求書済',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'printed': Colors.green,
    'invoiced': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('注文がありません'));
    }

    final statusLabel = _statusLabels[status] ?? '不明';
    final statusColor = _statusColors[status] ?? Colors.grey;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
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
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (statusColor as Color).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('注文日: ${DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${order.items.length}点', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('¥${NumberFormat('#,###').format(order.totalInTax)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (status == 'pending')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, order.id, 'confirmed'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 4),
                                Text('確認'),
                              ],
                            ),
                          ),
                        ),
                      if (status == 'pending') const SizedBox(width: 8),
                      if (status == 'confirmed')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, order.id, 'printed'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F4C81),
                              side: const BorderSide(color: Color(0xFF0F4C81)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print, size: 16),
                                SizedBox(width: 4),
                                Text('印刷'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String newStatus) async {
    final success = await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '更新しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/staff/screens/order_management_screen.dart
git commit -m "feat(flutter): update OrderManagementScreen to use OrderProvider

- Load all orders from Supabase
- Update order status (confirm, print)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 11: 修改商品上传页面使用ProductProvider

**Files:**
- Modify: `flutter-app/lib/staff/screens/product_upload_screen.dart`

- [ ] **Step 1: 修改product_upload_screen.dart**

```dart
// flutter-app/lib/staff/screens/product_upload_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameJaController = TextEditingController();
  final _nameZhController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '野菜';
  String _selectedUnit = '個';
  final List<String> _images = [];

  final categories = ['野菜', '精肉', '鮮魚', '果物'];
  final units = ['個', 'kg', 'g', '袋', '箱', '束', '本'];

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最大5枚まで選択できます')),
      );
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final productProvider = context.read<ProductProvider>();

    try {
      await productProvider.uploadProduct(
        code: _codeController.text,
        nameJa: _nameJaController.text,
        nameZh: _nameZhController.text.isEmpty ? null : _nameZhController.text,
        categoryId: _getCategoryId(_selectedCategory),
        unit: _selectedUnit,
        purchasePrice: int.parse(_purchasePriceController.text),
        stock: int.parse(_stockController.text),
        descriptionJa: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        images: _images.isEmpty ? null : _images,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('提出しました'),
            backgroundColor: Colors.green,
          ),
        );
        // 清空表单
        _formKey.currentState?.reset();
        _codeController.clear();
        _nameJaController.clear();
        _nameZhController.clear();
        _purchasePriceController.clear();
        _stockController.clear();
        _descriptionController.clear();
        setState(() {
          _images.clear();
          _selectedCategory = '野菜';
          _selectedUnit = '個';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提出に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getCategoryId(String categoryName) {
    // TODO: 根据分类名称获取分类ID，需要先加载分类列表
    return null;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameJaController.dispose();
    _nameZhController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品アップロード'),
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

            // Product Code
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '商品コード *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) => value?.isEmpty ?? true ? '必須' : null,
            ),
            const SizedBox(height: 16),

            // Product Name (Japanese)
            TextFormField(
              controller: _nameJaController,
              decoration: InputDecoration(
                labelText: '商品名(日) *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) => value?.isEmpty ?? true ? '必須' : null,
            ),
            const SizedBox(height: 16),

            // Product Name (Chinese)
            TextFormField(
              controller: _nameZhController,
              decoration: InputDecoration(
                labelText: '商品名(中)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                    validator: (value) {
                      if (value?.isEmpty ?? true) return '必須';
                      if (int.tryParse(value!) == null) return '数値を入力';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(labelText: '在庫 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return '必須';
                      if (int.tryParse(value!) == null) return '数値を入力';
                      return null;
                    },
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
              onPressed: productProvider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECF8E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: productProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('提出する', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/lib/staff/screens/product_upload_screen.dart
git commit -m "feat(flutter): update ProductUploadScreen to use ProductProvider

- Upload product to Supabase
- Form validation
- Loading state

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 12: 创建分类页面

**Files:**
- Create: `flutter-app/lib/customer/screens/category_screen.dart`
- Modify: `flutter-app/lib/customer/screens/main_screen.dart`

- [ ] **Step 1: 创建category_screen.dart**

```dart
// flutter-app/lib/customer/screens/category_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    if (categoryId != null) {
      context.read<ProductProvider>().loadProductsByCategory(categoryId);
    } else {
      context.read<ProductProvider>().loadProducts();
    }
  }

  void _addToCart(Product product) {
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.nameJa}をカートに追加しました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分類'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // 左侧分类导航
          Container(
            width: 100,
            color: Colors.grey[100],
            child: ListView(
              children: [
                ListTile(
                  title: const Text('すべて'),
                  selected: _selectedCategoryId == null,
                  selectedColor: const Color(0xFF0F4C81),
                  onTap: () => _onCategorySelected(null),
                ),
                ...categories.map((cat) {
                  return ListTile(
                    title: Text(cat.nameJa, style: const TextStyle(fontSize: 14)),
                    selected: _selectedCategoryId == cat.id,
                    selectedColor: const Color(0xFF0F4C81),
                    onTap: () => _onCategorySelected(cat.id),
                  );
                }),
              ],
            ),
          ),
          // 右侧商品列表
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? const Center(child: Text('商品がありません'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return _ProductGridItem(product: product, onAddToCart: _addToCart);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final Product product;
  final Function(Product) onAddToCart;

  const _ProductGridItem({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: product.images?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        product.images!.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    )
                  : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nameJa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(product.unit, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¥${NumberFormat('#,###').format(product.salePriceInTax)}',
                      style: const TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => onAddToCart(product),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 修改main_screen.dart添加分类页面**

```dart
// flutter-app/lib/customer/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'order_history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    OrderHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add flutter-app/lib/customer/screens/category_screen.dart
git add flutter-app/lib/customer/screens/main_screen.dart
git commit -m "feat(flutter): add CategoryScreen and update MainScreen

- CategoryScreen with category filter and product grid
- Updated bottom navigation with 4 tabs

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 13: 创建assets目录

**Files:**
- Create: `flutter-app/assets/images/.gitkeep`

- [ ] **Step 1: 创建目录和占位文件**

```bash
mkdir -p flutter-app/assets/images
touch flutter-app/assets/images/.gitkeep
```

- [ ] **Step 2: 提交**

```bash
git add flutter-app/assets/
git commit -m "chore(flutter): add assets directory for images

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## 验证清单

实施完成后，请验证以下功能：

- [ ] 登录页面可以成功登录
- [ ] 首页显示商品列表
- [ ] 分类页面可以按分类筛选
- [ ] 购物车添加/删除/修改数量
- [ ] 提交订单成功
- [ ] 订单历史显示订单列表
- [ ] 员工上传商品功能
- [ ] 员工查看我的商品
- [ ] 员工订单管理（确认/打印）
