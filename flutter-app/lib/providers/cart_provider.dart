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
