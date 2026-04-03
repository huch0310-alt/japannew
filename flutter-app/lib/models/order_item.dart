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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price_ex_tax': unitPriceExTax,
      'discounted_price': discountedPrice,
      'line_total_ex_tax': lineTotalExTax,
      'note': note,
    };
  }
}
