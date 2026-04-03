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
