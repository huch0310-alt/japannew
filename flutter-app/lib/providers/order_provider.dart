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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _supabase.getOrderById(orderId);
      _isLoading = false;
      notifyListeners();
      return _selectedOrder;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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
