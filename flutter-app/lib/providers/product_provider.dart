// flutter-app/lib/providers/product_provider.dart

import 'package:flutter/foundation.dart' hide Category;
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
