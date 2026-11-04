import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../database/daos/delete_log_dao.dart';
import '../../database/daos/document_dao.dart';
import '../../models/app_user.dart';
import '../../models/delete_log.dart';
import '../../models/document.dart';
import '../../models/document_permission.dart';
import '../services/firebase_storage_service.dart';
import '../services/supabase_service.dart';

class DocumentRepository {
  final DocumentDao _documentDao;
  final DeleteLogDao _deleteLogDao;
  final SupabaseService _supabaseService;
  final FirebaseStorageService _storageService;

  DocumentRepository({
    DocumentDao? documentDao,
    DeleteLogDao? deleteLogDao,
    SupabaseService? supabaseService,
    FirebaseStorageService? storageService,
  })  : _documentDao = documentDao ?? DocumentDao(),
        _deleteLogDao = deleteLogDao ?? DeleteLogDao(),
        _supabaseService = supabaseService ?? SupabaseService(),
        _storageService = storageService ?? FirebaseStorageService();

  // ===========================================================================
  // LOCAL SQLITE PERSISTENCE (Cashew Local-First Engine)
  // ===========================================================================

  Future<List<Document>> getAllDocuments() => _documentDao.getAllDocuments();

  Future<Document?> getDocumentById(String id) => _documentDao.getDocumentById(id);

  Future<int> addDocument(Document document) async {
    final now = DateTime.now();
    final enriched = document.copyWith(
      dateCreated: document.dateCreated,
      dateTimeModified: now,
    );
    return await _documentDao.insertDocument(enriched);
  }

  Future<int> updateDocument(Document document) async {
    final enriched = document.copyWith(
      dateTimeModified: DateTime.now(),
    );
    return await _documentDao.updateDocument(enriched);
  }

  /// Soft-delete document: Removes from documents table and logs to DeleteLogs
  /// adhering to Cashew Tombstone synchronization pattern.
  Future<bool> deleteDocument(String documentId) async {
    final doc = await _documentDao.getDocumentById(documentId);
    if (doc == null) return false;

    // 1. Insert into DeleteLogs
    final log = DeleteLog(
      entryPk: doc.documentId,
      type: 'document',
      title: doc.title,
      payloadJson: jsonEncode(doc.toMap()),
      dateTimeModified: DateTime.now(),
    );
    await _deleteLogDao.insertDeleteLog(log);

    // 2. Remove from active documents table
    final deletedCount = await _documentDao.deleteDocument(documentId);
    return deletedCount > 0;
  }

  Future<bool> restoreDocument(int logId) async {
    return await _deleteLogDao.restoreDocument(logId);
  }

  Future<List<DeleteLog>> getRecycleBinLogs() async {
    return await _deleteLogDao.getAllDeleteLogs();
  }

  Future<int> deletePermanently(int logId) async {
    return await _deleteLogDao.deleteLogPermanently(logId);
  }

  Future<int> clearRecycleBin() async {
    return await _deleteLogDao.clearAllLogs();
  }

  Future<List<Document>> searchAndFilter({
    String? query,
    String? subjectFk,
    String? categoryFk,
    bool? isFavorite,
    bool? isCompleted,
    String? fileType,
    String sortBy = AppConstants.sortDateDesc,
  }) {
    return _documentDao.searchAndFilterDocuments(
      query: query,
      subjectFk: subjectFk,
      categoryFk: categoryFk,
      isFavorite: isFavorite,
      isCompleted: isCompleted,
      fileType: fileType,
      sortBy: sortBy,
    );
  }

  Future<int> toggleFavorite(String documentId, bool currentFavorite) {
    return _documentDao.toggleFavorite(documentId, !currentFavorite);
  }

  Future<int> toggleCompleted(String documentId, bool currentCompleted) {
    return _documentDao.toggleCompleted(documentId, !currentCompleted);
  }

  Future<int> getTotalCount() => _documentDao.countDocuments();

  Future<int> getTotalSizeBytes() => _documentDao.sumTotalFileSizeBytes();

  Future<Map<String, int>> getCountBySubject() => _documentDao.countDocumentsBySubject();

  Future<Map<String, int>> getCountByCategory() => _documentDao.countDocumentsByCategory();

  // ===========================================================================
  // CLOUD INTEGRATION (Firebase Storage & Supabase Database with RLS)
  // ===========================================================================

  /// Tải tệp lên Firebase Storage theo cấu trúc documents/{userId}/{documentId}/{fileName}
  Future<StorageUploadResult> uploadToFirebaseStorage({
    required String userId,
    required String documentId,
    required String fileName,
    Uint8List? fileBytes,
    String? localFilePath,
  }) {
    return _storageService.uploadDocumentFile(
      userId: userId,
      documentId: documentId,
      fileName: fileName,
      fileBytes: fileBytes,
      localFilePath: localFilePath,
    );
  }

  /// Lấy danh sách tài liệu từ Supabase đã áp dụng RLS phân quyền theo user
  Future<List<Document>> getCloudDocumentsForUser(String userId) async {
    return await _supabaseService.getDocumentsForUser(userId);
  }

  /// Thêm tài liệu mới lên Cloud (Supabase & Firebase Storage) và lưu bản sao Local SQLite
  Future<Document> addCloudDocument(Document document, String currentUserId) async {
    final cloudDoc = await _supabaseService.insertDocument(document, currentUserId);
    // Lưu song song vào SQLite để truy cập nhanh ngoại tuyến (Local-First)
    await _documentDao.insertDocument(cloudDoc);
    return cloudDoc;
  }

  /// Cập nhật tài liệu trên Cloud (Kiểm tra RLS: Chỉ Owner hoặc Editor mới được sửa)
  Future<Document> updateCloudDocument(Document document, String requesterId) async {
    final updated = await _supabaseService.updateDocument(document, requesterId);
    await _documentDao.updateDocument(updated);
    return updated;
  }

  /// Xóa tài liệu trên Cloud (Kiểm tra RLS: Chỉ Chủ sở hữu mới được xóa)
  Future<bool> deleteCloudDocument(String documentId, String requesterId) async {
    final doc = await _documentDao.getDocumentById(documentId);
    final hasCloud = _supabaseService.hasDocument(documentId);
    if (hasCloud) {
      final success = await _supabaseService.deleteDocument(documentId, requesterId);
      if (!success) return false;
      if (doc?.storagePath != null && doc!.storagePath!.isNotEmpty) {
        await _storageService.deleteDocumentFile(doc.storagePath!);
      }
    }
    return await deleteDocument(documentId);
  }

  /// Chia sẻ tài liệu cho người khác theo Email (Checklist Mục 4)
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permission,
    required String requesterId,
  }) {
    return _supabaseService.shareDocument(
      documentId: documentId,
      targetEmail: targetEmail,
      permission: permission,
      requesterId: requesterId,
    );
  }

  /// Thu hồi quyền chia sẻ tài liệu
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
    required String requesterId,
  }) {
    return _supabaseService.revokePermission(
      documentId: documentId,
      targetUserId: targetUserId,
      requesterId: requesterId,
    );
  }

  /// Thay đổi cấp độ quyền chia sẻ (Viewer <-> Editor)
  Future<bool> updatePermissionLevel({
    required String documentId,
    required String targetUserId,
    required PermissionLevel newLevel,
    required String requesterId,
  }) {
    return _supabaseService.updatePermissionLevel(
      documentId: documentId,
      targetUserId: targetUserId,
      newLevel: newLevel,
      requesterId: requesterId,
    );
  }

  /// Lấy danh sách các quyền truy cập của một tài liệu
  Future<List<DocumentPermission>> getDocumentPermissions(
    String documentId,
    String requesterId,
  ) {
    return _supabaseService.getDocumentPermissions(documentId, requesterId);
  }

  /// Lấy danh sách tất cả người dùng trong hệ thống để gợi ý chia sẻ
  Future<List<AppUser>> getAllUsers() => _supabaseService.getAllUsers();
}
