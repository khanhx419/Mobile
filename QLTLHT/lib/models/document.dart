import 'document_permission.dart';

class Document {
  final String documentId;
  final String title;
  final String description;
  final String subjectFk;
  final String categoryFk;
  final String fileType;
  final String fileName;
  final String fileUri; // Local path or fallback URI
  final int fileSizeBytes;
  final String tags;
  final bool isFavorite;
  final bool isCompleted;
  final DateTime dateCreated;
  final DateTime dateTimeModified;

  // Cloud & Sharing integration fields
  final String? ownerId;
  final String? ownerEmail;
  final String? ownerName;
  final String? fileUrl; // Firebase Storage Download URL
  final String? storagePath; // Firebase Storage Object Path (e.g. documents/user123/doc456/sample.pdf)
  final PermissionLevel? userPermission; // Current user's permission level

  // Joined presentation fields
  final String? subjectName;
  final String? subjectCode;
  final int? subjectColor;
  final String? categoryName;
  final int? categoryColor;

  Document({
    required this.documentId,
    required this.title,
    this.description = '',
    required this.subjectFk,
    required this.categoryFk,
    required this.fileType,
    this.fileName = '',
    this.fileUri = '',
    this.fileSizeBytes = 0,
    this.tags = '',
    this.isFavorite = false,
    this.isCompleted = false,
    required this.dateCreated,
    required this.dateTimeModified,
    this.ownerId,
    this.ownerEmail,
    this.ownerName,
    this.fileUrl,
    this.storagePath,
    this.userPermission,
    this.subjectName,
    this.subjectCode,
    this.subjectColor,
    this.categoryName,
    this.categoryColor,
  });

  bool get isOwner => userPermission == null || userPermission == PermissionLevel.admin || ownerId == null;
  bool get canEdit => isOwner || userPermission == PermissionLevel.edit || userPermission == PermissionLevel.admin;
  bool get isSharedWithMe => ownerId != null && userPermission != null && userPermission != PermissionLevel.admin;

  List<String> get tagsList => tags.isEmpty
      ? []
      : tags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Document copyWith({
    String? documentId,
    String? title,
    String? description,
    String? subjectFk,
    String? categoryFk,
    String? fileType,
    String? fileName,
    String? fileUri,
    int? fileSizeBytes,
    String? tags,
    bool? isFavorite,
    bool? isCompleted,
    DateTime? dateCreated,
    DateTime? dateTimeModified,
    String? ownerId,
    String? ownerEmail,
    String? ownerName,
    String? fileUrl,
    String? storagePath,
    PermissionLevel? userPermission,
    String? subjectName,
    String? subjectCode,
    int? subjectColor,
    String? categoryName,
    int? categoryColor,
  }) {
    return Document(
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectFk: subjectFk ?? this.subjectFk,
      categoryFk: categoryFk ?? this.categoryFk,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileUri: fileUri ?? this.fileUri,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      dateCreated: dateCreated ?? this.dateCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      userPermission: userPermission ?? this.userPermission,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectColor: subjectColor ?? this.subjectColor,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  /// SQLite & JSON snapshot compatibility
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'title': title,
      'description': description,
      'subjectFk': subjectFk,
      'categoryFk': categoryFk,
      'fileType': fileType,
      'fileName': fileName,
      'fileUri': fileUri,
      'fileSizeBytes': fileSizeBytes,
      'tags': tags,
      'isFavorite': isFavorite ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'dateCreated': dateCreated.toIso8601String(),
      'dateTimeModified': dateTimeModified.toIso8601String(),
      if (ownerId != null) 'ownerId': ownerId,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (storagePath != null) 'storagePath': storagePath,
    };
  }

  /// Supabase database row mapping
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': documentId,
      'title': title,
      'description': description,
      'subject_id': subjectFk,
      'category_id': categoryFk,
      'file_type': fileType,
      'file_name': fileName,
      'file_url': fileUrl ?? fileUri,
      'storage_path': storagePath,
      'file_size': fileSizeBytes,
      'tags': tags,
      'is_favorite': isFavorite,
      'is_completed': isCompleted,
      'owner_id': ownerId,
      'created_at': dateCreated.toIso8601String(),
      'updated_at': dateTimeModified.toIso8601String(),
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      documentId: (map['documentId'] ?? map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description'] as String? ?? '',
      subjectFk: (map['subjectFk'] ?? map['subject_id'] ?? '').toString(),
      categoryFk: (map['categoryFk'] ?? map['category_id'] ?? '').toString(),
      fileType: map['fileType'] as String? ?? map['file_type'] as String? ?? 'PDF',
      fileName: map['fileName'] as String? ?? map['file_name'] as String? ?? '',
      fileUri: map['fileUri'] as String? ?? map['file_url'] as String? ?? '',
      fileSizeBytes: (map['fileSizeBytes'] ?? map['file_size'] as num?)?.toInt() ?? 0,
      tags: map['tags'] as String? ?? '',
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true || map['is_favorite'] == true),
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true || map['is_completed'] == true),
      dateCreated: DateTime.tryParse(map['dateCreated'] as String? ?? map['created_at'] as String? ?? '') ?? DateTime.now(),
      dateTimeModified: DateTime.tryParse(map['dateTimeModified'] as String? ?? map['updated_at'] as String? ?? '') ?? DateTime.now(),
      ownerId: map['ownerId'] as String? ?? map['owner_id'] as String?,
      ownerEmail: map['ownerEmail'] as String? ?? map['owner_email'] as String?,
      ownerName: map['ownerName'] as String? ?? map['owner_name'] as String?,
      fileUrl: map['fileUrl'] as String? ?? map['file_url'] as String?,
      storagePath: map['storagePath'] as String? ?? map['storage_path'] as String?,
      userPermission: map['userPermission'] != null
          ? PermissionLevel.fromString(map['userPermission']?.toString())
          : (map['permission_level'] != null ? PermissionLevel.fromString(map['permission_level']?.toString()) : null),
      subjectName: map['subjectName'] as String?,
      subjectCode: map['subjectCode'] as String?,
      subjectColor: map['subjectColor'] as int?,
      categoryName: map['categoryName'] as String?,
      categoryColor: map['categoryColor'] as int?,
    );
  }
}
