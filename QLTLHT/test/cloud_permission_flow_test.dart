import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/models/document.dart';
import 'package:qltlht/models/document_permission.dart';
import 'package:qltlht/repositories/document_repository.dart';
import 'package:qltlht/services/auth_service.dart';
import 'package:qltlht/services/firebase_storage_service.dart';
import 'package:qltlht/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;
  late FirebaseStorageService storageService;
  late SupabaseService supabaseService;
  late DocumentRepository repository;

  // 3 Tài khoản kiểm thử chính + 1 tài khoản Unauthorized
  final aliceOwner = AuthService.testAccounts[0]; // usr_alice_owner_101
  final bobViewer = AuthService.testAccounts[1]; // usr_bob_viewer_202
  final charlieEditor = AuthService.testAccounts[2]; // usr_charlie_editor_303
  final daveStranger = AuthService.testAccounts[3]; // usr_dave_stranger_404

  setUp(() {
    authService = AuthService();
    storageService = FirebaseStorageService();
    supabaseService = SupabaseService();
    repository = DocumentRepository(
      supabaseService: supabaseService,
      storageService: storageService,
    );
  });

  group('CHECKLIST 1: XÁC THỰC GOOGLE VÀ QUẢN LÝ NGƯỜI DÙNG FIREBASE AUTH', () {
    test('1.1. AuthService có sẵn danh sách 3 tài khoản người dùng mẫu chuẩn', () {
      expect(AuthService.testAccounts.length, greaterThanOrEqualTo(3));
      expect(aliceOwner.email, contains('alice.owner'));
      expect(bobViewer.email, contains('bob.viewer'));
      expect(charlieEditor.email, contains('charlie.editor'));
    });

    test('1.2. Chuyển đổi trạng thái đăng nhập giữa các tài khoản kiểm thử', () async {
      // Bắt đầu với Alice
      authService.switchTestAccount(aliceOwner);
      expect(authService.currentUser?.id, equals(aliceOwner.id));

      // Chuyển sang Bob
      authService.switchTestAccount(bobViewer);
      expect(authService.currentUser?.id, equals(bobViewer.id));

      // Chuyển sang Charlie
      authService.switchTestAccount(charlieEditor);
      expect(authService.currentUser?.id, equals(charlieEditor.id));
    });

    test('1.3. Đồng bộ thông tin người dùng vào bảng users trên Supabase', () async {
      await supabaseService.upsertUser(aliceOwner);
      await supabaseService.upsertUser(bobViewer);
      await supabaseService.upsertUser(charlieEditor);

      final users = await supabaseService.getAllUsers();
      expect(users.any((u) => u.id == aliceOwner.id), isTrue);
      expect(users.any((u) => u.id == bobViewer.id), isTrue);
      expect(users.any((u) => u.id == charlieEditor.id), isTrue);
    });
  });

  group('CHECKLIST 2 & 3: CẤU TRÚC LƯU TRỮ FIREBASE STORAGE VÀ THIẾT KẾ CSDL SUPABASE', () {
    test('2.1. Cấu trúc đường dẫn file Firebase Storage chuẩn documents/{userId}/{documentId}/{fileName}', () {
      final path = storageService.buildStoragePath(
        userId: aliceOwner.id,
        documentId: 'doc_123',
        fileName: 'bai giang chuong 1.pdf',
      );

      expect(path, equals('documents/usr_alice_owner_101/doc_123/bai_giang_chuong_1.pdf'));
    });

    test('2.2. Upload tệp tin lên Firebase Storage và trả về URL tải về', () async {
      final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final uploadResult = await storageService.uploadDocumentFile(
        userId: aliceOwner.id,
        documentId: 'doc_test_upload',
        fileName: 'Slide_KienTruc_Cloud.pdf',
        fileBytes: fakeBytes,
      );

      expect(uploadResult.storagePath, equals('documents/usr_alice_owner_101/doc_test_upload/Slide_KienTruc_Cloud.pdf'));
      expect(uploadResult.downloadUrl, contains('firebasestorage.googleapis.com'));
      expect(uploadResult.fileSizeBytes, equals(8));
    });

    test('3.1. Tạo tài liệu mới trên Supabase liên kết với URL từ Firebase Storage', () async {
      final newDoc = Document(
        documentId: 'doc_alice_001',
        title: 'Báo cáo Chuyên đề Cloud Computing',
        description: 'Tài liệu hướng dẫn kết nối Firebase và Supabase trên Flutter',
        subjectFk: 'sub_1',
        categoryFk: 'cat_1',
        fileType: 'PDF',
        fileName: 'bao_cao_cloud.pdf',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/app/o/documents/usr_alice_owner_101/doc_alice_001/bao_cao_cloud.pdf',
        storagePath: 'documents/usr_alice_owner_101/doc_alice_001/bao_cao_cloud.pdf',
        fileSizeBytes: 2048576,
        tags: 'Cloud, Supabase, Firebase',
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      final createdDoc = await supabaseService.insertDocument(newDoc, aliceOwner.id);
      expect(createdDoc.ownerId, equals(aliceOwner.id));
      expect(createdDoc.storagePath, contains('documents/usr_alice_owner_101'));
      expect(createdDoc.userPermission, equals(PermissionLevel.admin));
    });
  });

  group('CHECKLIST 4, 5 & 6: PHÂN QUYỀN TRUY CẬP (RLS) & KIỂM THỬ TRÊN 3 TÀI KHOẢN NGƯỜI DÙNG', () {
    const testDocId = 'doc_shared_rbac_test';

    setUp(() async {
      // Alice tạo tài liệu kiểm thử
      final doc = Document(
        documentId: testDocId,
        title: 'Tài liệu Thực hành Phân quyền RBAC',
        description: 'Bản thảo thực hành kiểm thử quyền Viewer và Editor',
        subjectFk: 'sub_1',
        categoryFk: 'cat_2',
        fileType: 'DOCX',
        fileName: 'rbac_lab.docx',
        fileUrl: 'https://firebasestorage.googleapis.com/file_url_test',
        storagePath: 'documents/${aliceOwner.id}/$testDocId/rbac_lab.docx',
        ownerId: aliceOwner.id,
        ownerEmail: aliceOwner.email,
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );
      await supabaseService.insertDocument(doc, aliceOwner.id);
    });

    test('6.1. [Alice - Owner]: Cấp quyền View cho Bob và quyền Edit cho Charlie', () async {
      // Alice chia sẻ cho Bob với quyền 'view'
      final permBob = await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: bobViewer.email,
        permission: PermissionLevel.view,
        requesterId: aliceOwner.id,
      );
      expect(permBob.userId, equals(bobViewer.id));
      expect(permBob.permissionLevel, equals(PermissionLevel.view));

      // Alice chia sẻ cho Charlie với quyền 'edit'
      final permCharlie = await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: charlieEditor.email,
        permission: PermissionLevel.edit,
        requesterId: aliceOwner.id,
      );
      expect(permCharlie.userId, equals(charlieEditor.id));
      expect(permCharlie.permissionLevel, equals(PermissionLevel.edit));

      // Kiểm tra danh sách quyền (chỉ Owner mới có thể xem)
      final permissions = await supabaseService.getDocumentPermissions(testDocId, aliceOwner.id);
      expect(permissions.length, equals(2));
    });

    test('6.2. [Bob - Viewer]: Được phép xem tài liệu nhưng BỊ TỪ CHỐI khi sửa hoặc xóa', () async {
      // Cấp quyền View cho Bob
      await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: bobViewer.email,
        permission: PermissionLevel.view,
        requesterId: aliceOwner.id,
      );

      // 1. Bob đọc tài liệu -> Thành công
      final docForBob = await supabaseService.getDocumentById(testDocId, bobViewer.id);
      expect(docForBob, isNotNull);
      expect(docForBob!.userPermission, equals(PermissionLevel.view));

      // 2. Bob cố gắng cập nhật thông tin tài liệu -> Phải bị từ chối bằng Exception RLS
      final modifiedDoc = docForBob.copyWith(
        title: 'Bob đã hack tiêu đề này!',
      );
      expect(
        () async => await supabaseService.updateDocument(modifiedDoc, bobViewer.id),
        throwsA(isA<PermissionDeniedException>()),
      );

      // 3. Bob cố gắng xóa tài liệu -> Phải bị từ chối
      expect(
        () async => await supabaseService.deleteDocument(testDocId, bobViewer.id),
        throwsA(isA<PermissionDeniedException>()),
      );

      // 4. Bob cố gắng chia sẻ tài liệu cho Dave -> Phải bị từ chối (Chỉ owner mới share được)
      expect(
        () async => await supabaseService.shareDocument(
          documentId: testDocId,
          targetEmail: daveStranger.email,
          permission: PermissionLevel.view,
          requesterId: bobViewer.id,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('6.3. [Charlie - Editor]: Được phép xem và sửa thông tin tài liệu nhưng BỊ TỪ CHỐI khi xóa', () async {
      // Cấp quyền Edit cho Charlie
      await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: charlieEditor.email,
        permission: PermissionLevel.edit,
        requesterId: aliceOwner.id,
      );

      // 1. Charlie đọc tài liệu -> Thành công
      final docForCharlie = await supabaseService.getDocumentById(testDocId, charlieEditor.id);
      expect(docForCharlie, isNotNull);
      expect(docForCharlie!.userPermission, equals(PermissionLevel.edit));

      // 2. Charlie cập nhật mô tả tài liệu -> THÀNH CÔNG!
      final updatedDoc = docForCharlie.copyWith(
        description: 'Mô tả này đã được Charlie (Editor) bổ sung thêm nội dung chuẩn xác.',
      );
      final result = await supabaseService.updateDocument(updatedDoc, charlieEditor.id);
      expect(result.description, contains('Charlie (Editor) bổ sung'));

      // 3. Kiểm tra tính toàn vẹn của dữ liệu sau khi sửa
      final verifiedDoc = await supabaseService.getDocumentById(testDocId, aliceOwner.id);
      expect(verifiedDoc!.description, contains('Charlie (Editor) bổ sung'));

      // 4. Charlie cố gắng xóa tài liệu -> BỊ TỪ CHỐI (Chỉ Owner mới có quyền xóa)
      expect(
        () async => await supabaseService.deleteDocument(testDocId, charlieEditor.id),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('6.4. [Dave - Unauthorized]: Bị từ chối truy cập hoàn toàn vào tài liệu riêng tư', () async {
      // Dave không được chia sẻ tài liệu testDocId
      final daveDocs = await supabaseService.getDocumentsForUser(daveStranger.id);
      expect(daveDocs.any((d) => d.documentId == testDocId), isFalse);

      // Dave cố tình đọc trực tiếp bằng ID -> Ném ngoại lệ vi phạm quyền riêng tư
      expect(
        () async => await supabaseService.getDocumentById(testDocId, daveStranger.id),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('6.5. [Alice - Owner]: Thu hồi quyền (Revoke) của Bob và kiểm tra tính toàn vẹn', () async {
      // Cấp quyền cho Bob
      await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: bobViewer.email,
        permission: PermissionLevel.view,
        requesterId: aliceOwner.id,
      );

      // Bob xem được
      expect(supabaseService.canUserView(testDocId, bobViewer.id), isTrue);

      // Alice thu hồi quyền của Bob
      final revokeSuccess = await supabaseService.revokePermission(
        documentId: testDocId,
        targetUserId: bobViewer.id,
        requesterId: aliceOwner.id,
      );
      expect(revokeSuccess, isTrue);

      // Bob không còn quyền xem
      expect(supabaseService.canUserView(testDocId, bobViewer.id), isFalse);
    });

    test('6.6. Tìm kiếm tài liệu lọc theo quyền: Tài liệu của tôi vs Tài liệu được chia sẻ', () async {
      // Alice chia sẻ tài liệu cho Charlie
      await supabaseService.shareDocument(
        documentId: testDocId,
        targetEmail: charlieEditor.email,
        permission: PermissionLevel.edit,
        requesterId: aliceOwner.id,
      );

      // Charlie tìm kiếm tài liệu được chia sẻ
      final sharedDocs = await supabaseService.searchDocuments(
        userId: charlieEditor.id,
        onlySharedWithMe: true,
      );
      expect(sharedDocs.length, greaterThanOrEqualTo(1));
      expect(sharedDocs.any((d) => d.documentId == testDocId), isTrue);

      // Charlie tìm kiếm tài liệu cá nhân tự tạo (Charlie chưa tạo tài liệu nào)
      final myDocs = await supabaseService.searchDocuments(
        userId: charlieEditor.id,
        onlyMyDocuments: true,
      );
      expect(myDocs.any((d) => d.documentId == testDocId), isFalse);
    });
  });
}
