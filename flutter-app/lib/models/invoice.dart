// flutter-app/lib/models/invoice.dart

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final int totalInTax;
  final String status;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? pdfUrl;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.totalInTax,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    this.paidAt,
    this.pdfUrl,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerId: json['customer_id'] as String,
      totalInTax: json['total_in_tax'] as int? ?? 0,
      status: json['status'] as String? ?? 'unpaid',
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      pdfUrl: json['pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'total_in_tax': totalInTax,
      'status': status,
      'issue_date': issueDate.toIso8601String().split('T').first,
      'due_date': dueDate.toIso8601String().split('T').first,
      'paid_at': paidAt?.toIso8601String(),
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'unpaid':
        return '未払い';
      case 'paid':
        return '済み';
      case 'overdue':
        return '期限切れ';
      default:
        return status;
    }
  }

  bool get isOverdue => status == 'unpaid' && dueDate.isBefore(DateTime.now());
}
