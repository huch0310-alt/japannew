// flutter-app/lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class ServiceException implements Exception {
  final String message;
  final dynamic originalError;
  ServiceException(this.message, [this.originalError]);
  @override
  String toString() => 'ServiceException: $message';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;
  bool _initialized = false;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _initialized = true;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw ServiceException('SupabaseService has not been initialized. Call initialize() first.');
    }
  }

  SupabaseClient get client => _client;

  // ============ 认证 ============

  Future<User?> signIn(String email, String password) async {
    _checkInitialized();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw ServiceException('Failed to sign in', e);
    }
  }

  Future<void> signOut() async {
    _checkInitialized();
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServiceException('Failed to sign out', e);
    }
  }

  User? get currentUser {
    _checkInitialized();
    return _client.auth.currentUser;
  }

  Stream<User?> get onAuthStateChanged {
    _checkInitialized();
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  // ============ 商品 ============

  Future<List<Product>> getApprovedProducts() async {
    _checkInitialized();
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch approved products', e);
    }
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('status', 'approved')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch products by category', e);
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('status', 'approved')
          .or('name_ja.ilike.%$query%,name_zh.ilike.%$query%,code.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to search products', e);
    }
  }

  Future<Product?> getProductById(String id) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response);
    } catch (e) {
      throw ServiceException('Failed to fetch product by id', e);
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
    _checkInitialized();
    try {
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
    } catch (e) {
      throw ServiceException('Failed to upload product', e);
    }
  }

  Future<List<Product>> getMyProducts(String userId) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('submitted_by', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch my products', e);
    }
  }

  // ============ 分类 ============

  Future<List<Category>> getCategories() async {
    _checkInitialized();
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      return (response as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch categories', e);
    }
  }

  // ============ 订单 ============

  Future<Order> createOrder({
    required String customerId,
    required List<CartItem> items,
    String? customerNote,
  }) async {
    _checkInitialized();
    try {
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

      try {
        await _client.from('order_items').insert(orderItems);
      } catch (e) {
        // Rollback: delete the order we just created
        await _client.from('orders').delete().eq('id', orderId);
        throw ServiceException('Failed to create order items, order rolled back', e);
      }

      return getOrderById(orderId) ?? Order.fromJson(orderResponse);
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Failed to create order', e);
    }
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch customer orders', e);
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    _checkInitialized();
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) return null;
      return Order.fromJson(response);
    } catch (e) {
      throw ServiceException('Failed to fetch order by id', e);
    }
  }

  // ============ 订单管理（员工） ============

  Future<List<Order>> getAllOrders() async {
    _checkInitialized();
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      return (response as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      throw ServiceException('Failed to fetch all orders', e);
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    _checkInitialized();
    try {
      await _client
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      throw ServiceException('Failed to update order status', e);
    }
  }
}
