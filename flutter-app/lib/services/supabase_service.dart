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
