// flutter-app/lib/models/cart_item.dart

const _taxRate = 1.08;

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
  int get lineTotalInTax => (lineTotalExTax * _taxRate).round();

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
