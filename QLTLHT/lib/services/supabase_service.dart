import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../models/app_user.dart';
import '../models/document.dart';
import '../models/document_permission.dart';
import 'auth_service.dart';

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() {
    _initSampleData();
  }

  SupabaseClient? _supabaseClient;
  bool _isLiveConnected = false;

  // In-Memory Cloud Store (Mô phỏng chính xác RLS của Supabase)
  final Map<String, AppUser> _usersStore = {};
  final Map<String, Document> _documentsStore = {};
  final List<DocumentPermission> _permissionsStore = [];

  bool get isLiveConnected => _isLiveConnected;

  /// Khởi tạo kết nối Supabase Cloud nếu có cấu hình
  Future<void> initialize() async {
    try {
      if (SupabaseConfig.supabaseUrl.isNotEmpty &&
          !SupabaseConfig.supabaseUrl.contains('example') &&
          SupabaseConfig.supabaseAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
        _supabaseClient = Supabase.instance.client;
        _isLiveConnected = true;
        debugPrint('Đã kết nối thành công với Supabase Cloud.');
      }
    } catch (e) {
      debugPrint('Thông báo Supabase init: $e. Sử dụng Secure Simulated Cloud Engine.');
      _isLiveConnected = false;
    }
  }

  void _initSampleData() {
    // Nạp sẵn 3 tài khoản người dùng mẫu
    for (final user in AuthService.testAccounts) {
      _usersStore[user.id] = user;
    }

    // Nạp sẵn một tài liệu mẫu do Alice sở hữu
    final sampleDocId = 'doc_sample_cloud_01';
    final sampleDoc = Document(
      documentId: sampleDocId,
      title: 'Giáo trình Kiến trúc Phần mềm và Điện toán Đám mây',
      description: 'Tài liệu môn Kiến trúc phần mềm nâng cao, hướng dẫn tích hợp Flutter, Firebase và Supabase.',
      subjectFk: 'sub_1',
      categoryFk: 'cat_1',
      fileType: 'PDF',
      fileName: 'kien_truc_phan_mem_cloud.pdf',
      fileUri: 'https://firebasestorage.googleapis.com/v0/b/qltlht-flutter-firebase.appspot.com/o/documents%2Fusr_alice_owner_101%2Fdoc_sample_cloud_01%2Fkien_truc_phan_mem_cloud.pdf?alt=media',
      fileUrl: 'https://firebasestorage.googleapis.com/v0/b/qltlht-flutter-firebase.appspot.com/o/documents%2Fusr_alice_owner_101%2Fdoc_sample_cloud_01%2Fkien_truc_phan_mem_cloud.pdf?alt=media',
      storagePath: 'documents/usr_alice_owner_101/doc_sample_cloud_01/kien_truc_phan_mem_cloud.pdf',
      fileSizeBytes: 3500000, // 3.5 MB
      tags: 'Kiến trúc, Cloud, Flutter, Firebase, Supabase',
      isFavorite: true,
      isCompleted: false,
      ownerId: 'usr_alice_owner_101',
      ownerEmail: 'alice.owner@student.edu.vn',
      ownerName: 'Alice (Chủ sở hữu)',
      dateCreated: DateTime(2026, 2, 10, 9, 30),
      dateTimeModified: DateTime(2026, 2, 10, 9, 30),
    );
    _documentsStore[sampleDocId] = sampleDoc;

    // Alice chia sẻ tài liệu cho Bob (Viewer)
    _permissionsStore.add(
      DocumentPermission(
        id: 'perm_01_bob',
        documentId: sampleDocId,
        userId: 'usr_bob_viewer_202',
        userEmail: 'bob.viewer@student.edu.vn',
        userName: 'Bob (Người xem - Viewer)',
        permissionLevel: PermissionLevel.view,
        createdAt: DateTime(2026, 2, 11, 10, 0),
      ),
    );

    // Alice chia sẻ tài liệu cho Charlie (Editor)
    _permissionsStore.add(
      DocumentPermission(
        id: 'perm_02_charlie',
        documentId: sampleDocId,
        userId: 'usr_charlie_editor_303',
        userEmail: 'charlie.editor@student.edu.vn',
        userName: 'Charlie (Chỉnh sửa - Editor)',
        permissionLevel: PermissionLevel.edit,
        createdAt: DateTime(2026, 2, 11, 10, 30),
      ),
    );
  }

  // ===========================================================================
  // QUẢN LÝ NGƯỜI DÙNG (USERS TABLE)
  // ===========================================================================

  Future<void> upsertUser(AppUser user) async {
    _usersStore[user.id] = user;
    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!.from('users').upsert(user.toMap());
      } catch (e) {
        debugPrint('Supabase upsertUser cloud error: $e');
      }
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    return _usersStore.values.toList();
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    try {
      return _usersStore.values.firstWhere(
        (u) => u.email.trim().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // ROW LEVEL SECURITY (RLS) CHECK LOGIC
  // ===========================================================================

  bool hasDocument(String documentId) {
    return _documentsStore.containsKey(documentId);
  }

  /// Xác định quyền hạn của người dùng đối với một tài liệu
  PermissionLevel? checkUserPermissionLevel(String documentId, String userId) {
    final doc = _documentsStore[documentId];
    if (doc == null) return null;

    // Nếu là chủ sở hữu -> quyền Admin
    if (doc.ownerId == userId) {
      return PermissionLevel.admin;
    }

    // Tra cứu trong bảng document_permissions
    for (final perm in _permissionsStore) {
      if (perm.documentId == documentId && perm.userId == userId) {
        return perm.permissionLevel;
      }
    }

    return null; // Không có quyền
  }

  bool canUserView(String documentId, String userId) {
    return checkUserPermissionLevel(documentId, userId) != null;
  }

  bool canUserEdit(String documentId, String userId) {
    final perm = checkUserPermissionLevel(documentId, userId);
    return perm == PermissionLevel.admin || perm == PermissionLevel.edit;
  }

  bool isUserOwner(String documentId, String userId) {
    final doc = _documentsStore[documentId];
    return doc != null && doc.ownerId == userId;
  }

  // ===========================================================================
  // TÀI LIỆU (DOCUMENTS TABLE - RLS ENFORCED)
  // ===========================================================================

  /// Lấy danh sách tài liệu mà người dùng được phép xem (Cá nhân + Được chia sẻ)
  Future<List<Document>> getDocumentsForUser(String userId) async {
    final List<Document> accessibleDocs = [];

    for (final doc in _documentsStore.values) {
      final perm = checkUserPermissionLevel(doc.documentId, userId);
      if (perm != null) {
        accessibleDocs.add(
          doc.copyWith(
            userPermission: perm,
          ),
        );
      }
    }

    // Sắp xếp theo ngày cập nhật mới nhất
    accessibleDocs.sort((a, b) => b.dateTimeModified.compareTo(a.dateTimeModified));
    return accessibleDocs;
  }

  /// Lấy tài liệu theo ID có kiểm tra RLS
  Future<Document?> getDocumentById(String documentId, String currentUserId) async {
    final doc = _documentsStore[documentId];
    if (doc == null) return null;

    final perm = checkUserPermissionLevel(documentId, currentUserId);
    if (perm == null) {
      throw PermissionDeniedException(
        'Bạn không có quyền truy cập vào tài liệu này (RLS Violation).',
      );
    }

    return doc.copyWith(userPermission: perm);
  }

  /// Thêm mới tài liệu (Chỉ tạo với quyền sở hữu cá nhân - RLS INSERT)
  Future<Document> insertDocument(Document doc, String currentUserId) async {
    final user = _usersStore[currentUserId];
    final enrichedDoc = doc.copyWith(
      ownerId: currentUserId,
      ownerEmail: user?.email ?? '',
      ownerName: user?.displayName ?? '',
      userPermission: PermissionLevel.admin,
      dateCreated: DateTime.now(),
      dateTimeModified: DateTime.now(),
    );

    _documentsStore[enrichedDoc.documentId] = enrichedDoc;

    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!.from('documents').insert(enrichedDoc.toSupabaseMap());
      } catch (e) {
        debugPrint('Supabase insertDocument cloud error: $e');
      }
    }

    return enrichedDoc;
  }

  /// Cập nhật thông tin tài liệu (Kiểm tra RLS UPDATE: Owner hoặc Editor)
  Future<Document> updateDocument(Document doc, String requesterId) async {
    final existing = _documentsStore[doc.documentId];
    if (existing == null) {
      throw Exception('Tài liệu không tồn tại');
    }

    if (!canUserEdit(doc.documentId, requesterId)) {
      throw PermissionDeniedException(
        'Từ chối quyền cập nhật: Bạn chỉ có quyền Xem (Viewer) hoặc không có quyền đối với tài liệu này.',
      );
    }

    final updatedDoc = doc.copyWith(
      ownerId: existing.ownerId,
      ownerEmail: existing.ownerEmail,
      ownerName: existing.ownerName,
      userPermission: checkUserPermissionLevel(doc.documentId, requesterId),
      dateTimeModified: DateTime.now(),
    );

    _documentsStore[doc.documentId] = updatedDoc;

    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!
            .from('documents')
            .update(updatedDoc.toSupabaseMap())
            .eq('id', doc.documentId);
      } catch (e) {
        debugPrint('Supabase updateDocument cloud error: $e');
      }
    }

    return updatedDoc;
  }

  /// Xóa tài liệu (Kiểm tra RLS DELETE: CHỈ DUY NHẤT Owner mới có quyền xóa)
  Future<bool> deleteDocument(String documentId, String requesterId) async {
    final existing = _documentsStore[documentId];
    if (existing == null) return false;

    if (!isUserOwner(documentId, requesterId)) {
      throw PermissionDeniedException(
        'Từ chối quyền xóa: Chỉ Chủ sở hữu (Owner) của tài liệu mới có quyền xóa tài liệu này.',
      );
    }

    _documentsStore.remove(documentId);
    // Xóa các quyền liên quan trong bảng permissions
    _permissionsStore.removeWhere((p) => p.documentId == documentId);

    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!.from('documents').delete().eq('id', documentId);
      } catch (e) {
        debugPrint('Supabase deleteDocument cloud error: $e');
      }
    }

    return true;
  }

  /// Tìm kiếm và lọc tài liệu trên Cloud
  Future<List<Document>> searchDocuments({
    required String userId,
    String? query,
    String? fileType,
    String? subjectId,
    String? categoryId,
    bool? onlySharedWithMe,
    bool? onlyMyDocuments,
  }) async {
    final allAccessible = await getDocumentsForUser(userId);

    return allAccessible.where((doc) {
      if (onlyMyDocuments == true && doc.ownerId != userId) {
        return false;
      }
      if (onlySharedWithMe == true && (doc.ownerId == userId || doc.userPermission == PermissionLevel.admin)) {
        return false;
      }
      if (fileType != null && fileType.isNotEmpty && doc.fileType != fileType) {
        return false;
      }
      if (subjectId != null && subjectId.isNotEmpty && doc.subjectFk != subjectId) {
        return false;
      }
      if (categoryId != null && categoryId.isNotEmpty && doc.categoryFk != categoryId) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(q);
        final matchDesc = doc.description.toLowerCase().contains(q);
        final matchTags = doc.tags.toLowerCase().contains(q);
        final matchFileName = doc.fileName.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchTags && !matchFileName) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ===========================================================================
  // QUYỀN CHIA SẺ (DOCUMENT_PERMISSIONS TABLE - RLS ENFORCED)
  // ===========================================================================

  /// Lấy danh sách các quyền được cấp cho một tài liệu (Chỉ Owner mới được xem)
  Future<List<DocumentPermission>> getDocumentPermissions(String documentId, String requesterId) async {
    if (!isUserOwner(documentId, requesterId)) {
      throw PermissionDeniedException(
        'Chỉ Chủ sở hữu của tài liệu mới có quyền xem danh sách người dùng được chia sẻ.',
      );
    }

    return _permissionsStore.where((p) => p.documentId == documentId).toList();
  }

  /// Chia sẻ tài liệu cho người dùng khác theo Email (RLS INSERT: Chỉ Owner mới chia sẻ được)
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permission,
    required String requesterId,
  }) async {
    if (!isUserOwner(documentId, requesterId)) {
      throw PermissionDeniedException(
        'Từ chối: Chỉ Chủ sở hữu của tài liệu mới có quyền chia sẻ cho người khác.',
      );
    }

    // Tra cứu user theo email
    AppUser? targetUser = await getUserByEmail(targetEmail);
    if (targetUser == null) {
      // Nếu user chưa có trong cache, tạo user mới
      final newUid = 'usr_${targetEmail.split('@').first}_${DateTime.now().millisecondsSinceEpoch % 1000}';
      targetUser = AppUser(
        id: newUid,
        email: targetEmail.trim(),
        displayName: targetEmail.split('@').first,
        createdAt: DateTime.now(),
      );
      _usersStore[newUid] = targetUser;
    }

    if (targetUser.id == requesterId) {
      throw Exception('Không thể tự chia sẻ tài liệu cho chính mình.');
    }

    // Kiểm tra xem đã tồn tại quyền chia sẻ chưa
    final existingIndex = _permissionsStore.indexWhere(
      (p) => p.documentId == documentId && p.userId == targetUser!.id,
    );

    final now = DateTime.now();
    DocumentPermission resultPerm;

    if (existingIndex >= 0) {
      // Đã có -> Cập nhật quyền
      resultPerm = _permissionsStore[existingIndex].copyWith(
        permissionLevel: permission,
        updatedAt: now,
      );
      _permissionsStore[existingIndex] = resultPerm;
    } else {
      // Tạo mới
      resultPerm = DocumentPermission(
        id: const Uuid().v4(),
        documentId: documentId,
        userId: targetUser.id,
        userEmail: targetUser.email,
        userName: targetUser.displayName,
        permissionLevel: permission,
        createdAt: now,
        updatedAt: now,
      );
      _permissionsStore.add(resultPerm);
    }

    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!.from('document_permissions').upsert(resultPerm.toMap());
      } catch (e) {
        debugPrint('Supabase shareDocument cloud error: $e');
      }
    }

    return resultPerm;
  }

  /// Thu hồi quyền chia sẻ của một người dùng (RLS DELETE: Chỉ Owner mới thu hồi được)
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
    required String requesterId,
  }) async {
    if (!isUserOwner(documentId, requesterId)) {
      throw PermissionDeniedException(
        'Từ chối: Chỉ Chủ sở hữu của tài liệu mới có quyền thu hồi quyền chia sẻ.',
      );
    }

    _permissionsStore.removeWhere(
      (p) => p.documentId == documentId && p.userId == targetUserId,
    );

    if (_isLiveConnected && _supabaseClient != null) {
      try {
        await _supabaseClient!
            .from('document_permissions')
            .delete()
            .match({'document_id': documentId, 'user_id': targetUserId});
      } catch (e) {
        debugPrint('Supabase revokePermission cloud error: $e');
      }
    }

    return true;
  }

  /// Cập nhật cấp độ quyền (từ View sang Edit hoặc ngược lại)
  Future<bool> updatePermissionLevel({
    required String documentId,
    required String targetUserId,
    required PermissionLevel newLevel,
    required String requesterId,
  }) async {
    if (!isUserOwner(documentId, requesterId)) {
      throw PermissionDeniedException(
        'Từ chối: Chỉ Chủ sở hữu mới có quyền thay đổi cấp độ quyền chia sẻ.',
      );
    }

    final index = _permissionsStore.indexWhere(
      (p) => p.documentId == documentId && p.userId == targetUserId,
    );

    if (index >= 0) {
      final updated = _permissionsStore[index].copyWith(
        permissionLevel: newLevel,
        updatedAt: DateTime.now(),
      );
      _permissionsStore[index] = updated;

      if (_isLiveConnected && _supabaseClient != null) {
        try {
          await _supabaseClient!
              .from('document_permissions')
              .update({'permission_level': newLevel.toDbString(), 'updated_at': DateTime.now().toIso8601String()})
              .match({'document_id': documentId, 'user_id': targetUserId});
        } catch (e) {
          debugPrint('Supabase updatePermission cloud error: $e');
        }
      }
      return true;
    }
    return false;
  }
}
