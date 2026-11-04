import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/core/constants/app_constants.dart';
import 'package:qltlht/database/daos/delete_log_dao.dart';
import 'package:qltlht/database/daos/document_dao.dart';
import 'package:qltlht/database/daos/subject_dao.dart';
import 'package:qltlht/models/document.dart';
import 'package:sqflite/sqflite.dart';
import 'database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late DocumentDao documentDao;
  late SubjectDao subjectDao;
  late DeleteLogDao deleteLogDao;

  setUp(() async {
    db = await DatabaseTestHelper.createInMemoryDatabase();
    documentDao = DocumentDao();
    subjectDao = SubjectDao();
    deleteLogDao = DeleteLogDao();
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử DocumentDao & Tầng Persistence SQLite', () {
    test('1. Đọc danh sách tài liệu mẫu đã được seed ban đầu', () async {
      final docs = await documentDao.getAllDocuments();
      expect(docs.isNotEmpty, true);
      expect(docs.length, greaterThanOrEqualTo(6));
    });

    test('2. Thêm mới tài liệu học tập vào SQLite', () async {
      final newDoc = Document(
        documentId: 'doc_test_101',
        title: 'Tài liệu kiểm thử Unit Test',
        description: 'Mô tả kiểm thử đơn vị cho kiến trúc Cashew',
        subjectFk: 'sub_mob',
        categoryFk: 'cat_lecture',
        fileType: AppConstants.fileTypePdf,
        fileName: 'unit_test.pdf',
        fileSizeBytes: 2048,
        tags: 'Test, Unit, Cashew',
        isFavorite: true,
        isCompleted: false,
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      final rowId = await documentDao.insertDocument(newDoc);
      expect(rowId, greaterThan(0));

      final retrieved = await documentDao.getDocumentById('doc_test_101');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Tài liệu kiểm thử Unit Test');
      expect(retrieved.subjectName, contains('Di động'));
      expect(retrieved.categoryName, 'Bài giảng');
      expect(retrieved.isFavorite, true);
    });

    test('3. Cập nhật tài liệu học tập (Update Document)', () async {
      final original = await documentDao.getDocumentById('doc_01');
      expect(original, isNotNull);

      final updated = original!.copyWith(
        title: 'Tiêu đề sau khi cập nhật',
        isCompleted: true,
      );

      final count = await documentDao.updateDocument(updated);
      expect(count, equals(1));

      final verified = await documentDao.getDocumentById('doc_01');
      expect(verified!.title, 'Tiêu đề sau khi cập nhật');
      expect(verified.isCompleted, true);
    });

    test('4. Tìm kiếm tài liệu theo từ khóa (Search Keyword)', () async {
      final results = await documentDao.searchAndFilterDocuments(query: 'Dijkstra');
      expect(results.length, equals(1));
      expect(results.first.title, contains('Dijkstra'));

      final noResults = await documentDao.searchAndFilterDocuments(query: 'NonExistentKeywordXYZ');
      expect(noResults.isEmpty, true);
    });

    test('5. Lọc tài liệu đa tiêu chí (Môn học và Thể loại)', () async {
      // Lọc môn Lập trình Di động (sub_mob)
      final mobDocs = await documentDao.searchAndFilterDocuments(subjectFk: 'sub_mob');
      expect(mobDocs.every((d) => d.subjectFk == 'sub_mob'), true);

      // Lọc chỉ tài liệu yêu thích
      final favDocs = await documentDao.searchAndFilterDocuments(isFavorite: true);
      expect(favDocs.every((d) => d.isFavorite), true);
    });

    test('6. Xóa tài liệu khỏi bảng documents', () async {
      final count = await documentDao.deleteDocument('doc_05');
      expect(count, equals(1));

      final deleted = await documentDao.getDocumentById('doc_05');
      expect(deleted, isNull);
    });
  });

  group('Kiểm thử SubjectDao & DeleteLogDao (Tombstones)', () {
    test('1. Lấy danh sách môn học và tính số lượng tài liệu kèm theo', () async {
      final subjects = await subjectDao.getAllSubjects();
      expect(subjects.isNotEmpty, true);

      final mobSub = subjects.firstWhere((s) => s.subjectId == 'sub_mob');
      expect(mobSub.documentCount, greaterThan(0));
    });

    test('2. Xóa và khôi phục tài liệu qua DeleteLog (Cashew Tombstone Pattern)', () async {
      // Giả lập xóa doc_06 và ghi nhận log
      final docToDelete = await documentDao.getDocumentById('doc_06');
      expect(docToDelete, isNotNull);

      // Ghi log
      await db.insert('delete_logs', {
        'entryPk': docToDelete!.documentId,
        'type': 'document',
        'title': docToDelete.title,
        'payloadJson': '{"documentId":"doc_06","title":"${docToDelete.title}","subjectFk":"sub_net","categoryFk":"cat_lecture","fileType":"PowerPoint (PPTX)","dateCreated":"2026-10-03T00:00:00.000","dateTimeModified":"2026-10-03T00:00:00.000"}',
        'dateTimeModified': DateTime.now().toIso8601String(),
      });

      // Xóa khỏi bảng chính
      await documentDao.deleteDocument('doc_06');
      expect(await documentDao.getDocumentById('doc_06'), isNull);

      // Kiểm tra trong Recycle Bin
      final logs = await deleteLogDao.getAllDeleteLogs();
      expect(logs.any((l) => l.entryPk == 'doc_06'), true);

      // Khôi phục lại từ log
      final logEntry = logs.firstWhere((l) => l.entryPk == 'doc_06');
      final restored = await deleteLogDao.restoreDocument(logEntry.id!);
      expect(restored, true);

      // Xác minh tài liệu đã quay lại bảng chính
      final checkDoc = await documentDao.getDocumentById('doc_06');
      expect(checkDoc, isNotNull);
      expect(checkDoc!.title, contains('TCP & UDP'));
    });
  });
}
