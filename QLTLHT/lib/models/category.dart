class Category {
  final String categoryId;
  final String name;
  final String description;
  final int color;
  final String icon;
  final int order;
  final DateTime dateTimeModified;

  Category({
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.color,
    this.icon = 'folder',
    this.order = 0,
    required this.dateTimeModified,
  });

  Category copyWith({
    String? categoryId,
    String? name,
    String? description,
    int? color,
    String? icon,
    int? order,
    DateTime? dateTimeModified,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'sortOrder': order,
      'dateTimeModified': dateTimeModified.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      color: map['color'] as int? ?? 0xFF3B82F6,
      icon: map['icon'] as String? ?? 'folder',
      order: map['sortOrder'] as int? ?? 0,
      dateTimeModified: DateTime.tryParse(map['dateTimeModified'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
