// flutter-app/lib/models/category.dart

class Category {
  final String id;
  final String nameJa;
  final String? nameZh;
  final String? parentId;
  final int sortOrder;

  const Category({
    required this.id,
    required this.nameJa,
    this.nameZh,
    this.parentId,
    required this.sortOrder,
  });

  String get displayName => nameJa;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nameJa: json['name_ja'] as String,
      nameZh: json['name_zh'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ja': nameJa,
      'name_zh': nameZh,
      'parent_id': parentId,
      'sort_order': sortOrder,
    };
  }
}
