// flutter-app/lib/models/product.dart

const _taxRate = 1.08;

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

  int get salePriceInTax => (salePriceExTax * _taxRate).round();

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
