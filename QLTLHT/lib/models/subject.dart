class Subject {
  final String subjectId;
  final String code;
  final String name;
  final String lecturer;
  final int color;
  final String icon;
  final int order;
  final DateTime dateCreated;
  final DateTime dateTimeModified;
  final int documentCount;

  Subject({
    required this.subjectId,
    required this.code,
    required this.name,
    this.lecturer = '',
    required this.color,
    this.icon = 'school',
    this.order = 0,
    required this.dateCreated,
    required this.dateTimeModified,
    this.documentCount = 0,
  });

  Subject copyWith({
    String? subjectId,
    String? code,
    String? name,
    String? lecturer,
    int? color,
    String? icon,
    int? order,
    DateTime? dateCreated,
    DateTime? dateTimeModified,
    int? documentCount,
  }) {
    return Subject(
      subjectId: subjectId ?? this.subjectId,
      code: code ?? this.code,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      documentCount: documentCount ?? this.documentCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'code': code,
      'name': name,
      'lecturer': lecturer,
      'color': color,
      'icon': icon,
      'sortOrder': order,
      'dateCreated': dateCreated.toIso8601String(),
      'dateTimeModified': dateTimeModified.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      subjectId: map['subjectId'] as String,
      code: map['code'] as String? ?? '',
      name: map['name'] as String,
      lecturer: map['lecturer'] as String? ?? '',
      color: map['color'] as int? ?? 0xFF2563EB,
      icon: map['icon'] as String? ?? 'school',
      order: map['sortOrder'] as int? ?? 0,
      dateCreated: DateTime.tryParse(map['dateCreated'] as String? ?? '') ?? DateTime.now(),
      dateTimeModified: DateTime.tryParse(map['dateTimeModified'] as String? ?? '') ?? DateTime.now(),
      documentCount: (map['documentCount'] as num?)?.toInt() ?? 0,
    );
  }
}
