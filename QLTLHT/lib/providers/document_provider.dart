import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../database/app_database.dart';
import '../../models/app_user.dart';
import '../../models/delete_log.dart';
import '../../models/document.dart';
import '../../models/document_permission.dart';
import '../../repositories/document_repository.dart';
import '../services/supabase_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _repository;
  StreamSubscription? _dbSubscription;

  List<Document> _documents = [];
  List<DeleteLog> _recycleBinLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Current active user ID for Cloud RBAC
  String _currentUserId = 'usr_alice_owner_101';

  // Filter States
  String _searchQuery = '';
  String _selectedSubjectId = 'all';
  String _selectedCategoryId = 'all';
  bool _isFavoriteOnly = false;
  bool? _isCompletedFilter;
  String _selectedFileType = 'all';
  String _sortBy = AppConstants.sortDateDesc;
  int _sharingTabIndex = 0; // 0: Tất cả, 1: Của tôi, 2: Được chia sẻ

  DocumentProvider({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository() {
    _listenToDatabaseChanges();
    loadDocuments();
    loadRecycleBin();
  }

  // Getters
  List<Document> get documents => _documents;
  List<DeleteLog> get recycleBinLogs => _recycleBinLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get currentUserId => _currentUserId;
  String get searchQuery => _searchQuery;
  String get selectedSubjectId => _selectedSubjectId;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isFavoriteOnly => _isFavoriteOnly;
  bool? get isCompletedFilter => _isCompletedFilter;
  String get selectedFileType => _selectedFileType;
  String get sortBy => _sortBy;
  int get sharingTabIndex => _sharingTabIndex;

  int get totalCount => _documents.length;
  int get recycleBinCount => _recycleBinLogs.length;

  /// Danh sách tài liệu của tôi (My Documents)
  List<Document> get myDocuments =>
      _documents.where((d) => d.ownerId == null || d.ownerId == _currentUserId).toList();

  /// Danh sách tài liệu được chia sẻ với tôi (Shared with Me)
  List<Document> get sharedWithMeDocuments =>
      _documents.where((d) => d.ownerId != null && d.ownerId != _currentUserId).toList();

  void setCurrentUserId(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    loadDocuments();
  }

  void setSharingTab(int index) {
    if (_sharingTabIndex == index) return;
    _sharingTabIndex = index;
    notifyListeners();
  }

  void _listenToDatabaseChanges() {
    _dbSubscription = AppDatabase.instance.tableUpdatesStream.listen((tableName) {
      if (tableName == 'documents' || tableName == 'subjects' || tableName == 'categories') {
        loadDocuments();
      }
      if (tableName == 'delete_logs') {
        loadRecycleBin();
      }
    });
  }

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Tải tài liệu Cloud từ Supabase (đã qua cơ chế RLS lọc theo _currentUserId)
      final cloudDocs = await _repository.getCloudDocumentsForUser(_currentUserId);

      // 2. Tải tài liệu Local SQLite
      final localDocs = await _repository.searchAndFilter(
        query: _searchQuery,
        subjectFk: _selectedSubjectId,
        categoryFk: _selectedCategoryId,
        isFavorite: _isFavoriteOnly ? true : null,
        isCompleted: _isCompletedFilter,
        fileType: _selectedFileType,
        sortBy: _sortBy,
      );

      // 3. Kết hợp và loại trùng (Ưu tiên bản ghi Cloud)
      final Map<String, Document> mergedMap = {};
      for (final doc in localDocs) {
        mergedMap[doc.documentId] = doc;
      }
      for (final doc in cloudDocs) {
        mergedMap[doc.documentId] = doc;
      }

      var mergedList = mergedMap.values.toList();

      // Áp dụng bộ lọc tìm kiếm & loại tệp
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        mergedList = mergedList.where((d) {
          return d.title.toLowerCase().contains(q) ||
              d.description.toLowerCase().contains(q) ||
              d.tags.toLowerCase().contains(q) ||
              d.fileName.toLowerCase().contains(q);
        }).toList();
      }

      if (_selectedSubjectId != 'all') {
        mergedList = mergedList.where((d) => d.subjectFk == _selectedSubjectId).toList();
      }

      if (_selectedCategoryId != 'all') {
        mergedList = mergedList.where((d) => d.categoryFk == _selectedCategoryId).toList();
      }

      if (_selectedFileType != 'all') {
        mergedList = mergedList.where((d) => d.fileType == _selectedFileType).toList();
      }

      if (_isFavoriteOnly) {
        mergedList = mergedList.where((d) => d.isFavorite).toList();
      }

      if (_isCompletedFilter != null) {
        mergedList = mergedList.where((d) => d.isCompleted == _isCompletedFilter).toList();
      }

      _documents = mergedList;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Lỗi khi tải danh sách tài liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecycleBin() async {
    try {
      _recycleBinLogs = await _repository.getRecycleBinLogs();
      notifyListeners();
    } catch (_) {}
  }

  // Filter setters
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadDocuments();
  }

  void setSelectedSubject(String subjectId) {
    if (_selectedSubjectId == subjectId) return;
    _selectedSubjectId = subjectId;
    loadDocuments();
  }

  void setSelectedCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    loadDocuments();
  }

  void toggleFavoriteOnly() {
    _isFavoriteOnly = !_isFavoriteOnly;
    loadDocuments();
  }

  void setCompletedFilter(bool? isCompleted) {
    _isCompletedFilter = isCompleted;
    loadDocuments();
  }

  void setSelectedFileType(String fileType) {
    _selectedFileType = fileType;
    loadDocuments();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    loadDocuments();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedSubjectId = 'all';
    _selectedCategoryId = 'all';
    _isFavoriteOnly = false;
    _isCompletedFilter = null;
    _selectedFileType = 'all';
    _sortBy = AppConstants.sortDateDesc;
    _sharingTabIndex = 0;
    loadDocuments();
  }

  // ===========================================================================
  // CRUD & CLOUD FILE OPERATIONS
  // ===========================================================================

  /// Thêm tài liệu mới kèm upload tệp lên Firebase Storage
  Future<bool> addDocumentWithCloudFile({
    required Document doc,
    Uint8List? fileBytes,
    String? localFilePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Document finalDoc = doc;

      // 1. Upload file lên Firebase Storage nếu có tệp đính kèm
      if (fileBytes != null || (localFilePath != null && localFilePath.isNotEmpty)) {
        final uploadResult = await _repository.uploadToFirebaseStorage(
          userId: _currentUserId,
          documentId: doc.documentId,
          fileName: doc.fileName.isNotEmpty ? doc.fileName : 'document.pdf',
          fileBytes: fileBytes,
          localFilePath: localFilePath,
        );

        finalDoc = doc.copyWith(
          fileUrl: uploadResult.downloadUrl,
          fileUri: uploadResult.downloadUrl,
          storagePath: uploadResult.storagePath,
          fileSizeBytes: uploadResult.fileSizeBytes,
        );
      }

      // 2. Lưu vào Supabase và Local SQLite
      await _repository.addCloudDocument(finalDoc, _currentUserId);
      await loadDocuments();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi thêm tài liệu: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDocument(Document doc) async {
    try {
      final res = await _repository.addDocument(doc);
      await loadDocuments();
      return res > 0;
    } catch (e) {
      _errorMessage = 'Không thể thêm tài liệu: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật tài liệu (Kiểm tra RLS: Owner hoặc Editor)
  Future<bool> updateDocument(Document doc) async {
    try {
      await _repository.updateCloudDocument(doc, _currentUserId);
      await loadDocuments();
      return true;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật tài liệu: $e';
      notifyListeners();
      return false;
    }
  }

  /// Xóa tài liệu (Kiểm tra RLS: Chỉ Chủ sở hữu mới được xóa)
  Future<bool> deleteDocument(String id) async {
    try {
      final success = await _repository.deleteCloudDocument(id, _currentUserId);
      await loadDocuments();
      await loadRecycleBin();
      return success;
    } on PermissionDeniedException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể xóa tài liệu: $e';
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // CHIA SẺ VÀ PHÂN QUYỀN TÀI LIỆU (SHARING & RBAC)
  // ===========================================================================

  /// Chia sẻ tài liệu cho người khác theo Email
  Future<bool> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permission,
  }) async {
    try {
      await _repository.shareDocument(
        documentId: documentId,
        targetEmail: targetEmail,
        permission: permission,
        requesterId: _currentUserId,
      );
      await loadDocuments();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi chia sẻ: $e';
      notifyListeners();
      return false;
    }
  }

  /// Thu hồi quyền chia sẻ
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
  }) async {
    try {
      final success = await _repository.revokePermission(
        documentId: documentId,
        targetUserId: targetUserId,
        requesterId: _currentUserId,
      );
      await loadDocuments();
      return success;
    } catch (e) {
      _errorMessage = 'Lỗi thu hồi quyền: $e';
      notifyListeners();
      return false;
    }
  }

  /// Đổi cấp độ quyền chia sẻ
  Future<bool> updatePermissionLevel({
    required String documentId,
    required String targetUserId,
    required PermissionLevel newLevel,
  }) async {
    try {
      final success = await _repository.updatePermissionLevel(
        documentId: documentId,
        targetUserId: targetUserId,
        newLevel: newLevel,
        requesterId: _currentUserId,
      );
      await loadDocuments();
      return success;
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật quyền: $e';
      notifyListeners();
      return false;
    }
  }

  /// Lấy danh sách các quyền đã cấp của tài liệu
  Future<List<DocumentPermission>> getDocumentPermissions(String documentId) {
    return _repository.getDocumentPermissions(documentId, _currentUserId);
  }

  /// Danh sách người dùng hệ thống để gợi ý chia sẻ
  Future<List<AppUser>> getAllUsers() => _repository.getAllUsers();

  Future<void> toggleFavorite(String id, bool currentVal) async {
    await _repository.toggleFavorite(id, currentVal);
    await loadDocuments();
  }

  Future<void> toggleCompleted(String id, bool currentVal) async {
    await _repository.toggleCompleted(id, currentVal);
    await loadDocuments();
  }

  Future<bool> restoreDocument(int logId) async {
    final success = await _repository.restoreDocument(logId);
    if (success) {
      await loadDocuments();
      await loadRecycleBin();
    }
    return success;
  }

  Future<void> permanentDelete(int logId) async {
    await _repository.deletePermanently(logId);
    await loadRecycleBin();
  }

  Future<void> clearRecycleBin() async {
    await _repository.clearRecycleBin();
    await loadRecycleBin();
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }
}
