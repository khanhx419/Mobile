enum PermissionLevel {
  view,
  edit,
  admin;

  static PermissionLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'edit':
        return PermissionLevel.edit;
      case 'admin':
        return PermissionLevel.admin;
      case 'view':
      default:
        return PermissionLevel.view;
    }
  }

  String toDbString() {
    switch (this) {
      case PermissionLevel.edit:
        return 'edit';
      case PermissionLevel.admin:
        return 'admin';
      case PermissionLevel.view:
        return 'view';
    }
  }

  String get displayName {
    switch (this) {
      case PermissionLevel.edit:
        return 'Người chỉnh sửa (Editor)';
      case PermissionLevel.admin:
        return 'Quản trị viên (Admin)';
      case PermissionLevel.view:
        return 'Người xem (Viewer)';
    }
  }
}

class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String? userName;
  final PermissionLevel permissionLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    this.userName,
    this.permissionLevel = PermissionLevel.view,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'user_email': userEmail,
      'permission_level': permissionLevel.toDbString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory DocumentPermission.fromMap(Map<String, dynamic> map) {
    return DocumentPermission(
      id: (map['id'] ?? '').toString(),
      documentId: (map['document_id'] ?? map['documentId'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      userEmail: (map['user_email'] ?? map['userEmail'] ?? '').toString(),
      userName: map['user_name']?.toString() ?? map['userName']?.toString(),
      permissionLevel: PermissionLevel.fromString(map['permission_level']?.toString() ?? map['permissionLevel']?.toString()),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  DocumentPermission copyWith({
    String? id,
    String? documentId,
    String? userId,
    String? userEmail,
    String? userName,
    PermissionLevel? permissionLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentPermission(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
