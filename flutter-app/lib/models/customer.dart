// flutter-app/lib/models/customer.dart

class Customer {
  final String id;
  final String companyName;
  final String? companyNameZh;
  final String? taxId;
  final String? postalCode;
  final String? address;
  final String? addressZh;
  final String? contactName;
  final String? phone;
  final double discountRate;
  final int paymentTermDays;

  const Customer({
    required this.id,
    required this.companyName,
    this.companyNameZh,
    this.taxId,
    this.postalCode,
    this.address,
    this.addressZh,
    this.contactName,
    this.phone,
    this.discountRate = 0,
    this.paymentTermDays = 30,
  });

  String get displayName => companyName;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      companyNameZh: json['company_name_zh'] as String?,
      taxId: json['tax_id'] as String?,
      postalCode: json['postal_code'] as String?,
      address: json['address'] as String?,
      addressZh: json['address_zh'] as String?,
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      discountRate: (json['discount_rate'] as num?)?.toDouble() ?? 0,
      paymentTermDays: (json['payment_term_days'] as int?) ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'company_name_zh': companyNameZh,
      'tax_id': taxId,
      'postal_code': postalCode,
      'address': address,
      'address_zh': addressZh,
      'contact_name': contactName,
      'phone': phone,
      'discount_rate': discountRate,
      'payment_term_days': paymentTermDays,
    };
  }
}
