import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/core/constants/app_constants.dart';
import 'package:qltlht/models/document.dart';
import 'package:qltlht/repositories/document_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late DocumentRepository repository;

  setUp(() async {
    db = await DatabaseTestHelper.createInMemoryDatabase();
    repository = DocumentRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử DocumentRepository (Tầng Domain / Business Logic)', () {
    test('1. Thêm tài liệu mới qua Repository tự động gắn dateTimeModified', () async {
      final doc = Document(
        documentId: 'doc_repo_01',
        title: 'Tài liệu kiến trúc Clean Architecture',
        description: 'Phân tách logic giữa các tầng',
        subjectFk: 'sub_mob',
        categoryFk: 'cat_reference',
        fileType: AppConstants.fileTypePdf,
        fileName: 'clean_arch.pdf',
        dateCreated: DateTime(2026, 1, 1),
        dateTimeModified: DateTime(2026, 1, 1),
      );

      final rowId = await repository.addDocument(doc);
      expect(rowId, greaterThan(0));

      final retrieved = await repository.getDocumentById('doc_repo_01');
      expect(retrieved, isNotNull);
      expect(retrieved!.dateTimeModified.isAfter(DateTime(2026, 1, 2)), true);
    });

    test('2. Xóa tài liệu qua Repository tự động ghi vào DeleteLogs (Soft Delete)', () async {
      // doc_02 is in seed data
      final beforeDelete = await repository.getDocumentById('doc_02');
      expect(beforeDelete, isNotNull);

      // Thực hiện xóa mềm
      final success = await repository.deleteDocument('doc_02');
      expect(success, true);

      // Đã không còn trong danh sách active
      final afterDelete = await repository.getDocumentById('doc_02');
      expect(afterDelete, isNull);

      // Kiểm tra vết xóa trong Recycle Bin
      final binLogs = await repository.getRecycleBinLogs();
      expect(binLogs.any((l) => l.entryPk == 'doc_02'), true);

      // Khôi phục lại
      final log = binLogs.firstWhere((l) => l.entryPk == 'doc_02');
      final restored = await repository.restoreDocument(log.id!);
      expect(restored, true);

      // Đã có lại trong danh sách active
      final checkRestored = await repository.getDocumentById('doc_02');
      expect(checkRestored, isNotNull);
      expect(checkRestored!.title, contains('Cashew'));
    });

    test('3. Tính toán thống kê dung lượng và số lượng tài liệu', () async {
      final count = await repository.getTotalCount();
      expect(count, greaterThan(0));

      final sizeBytes = await repository.getTotalSizeBytes();
      expect(sizeBytes, greaterThan(0));

      final subjectCounts = await repository.getCountBySubject();
      expect(subjectCounts.containsKey('sub_mob'), true);
    });
  });
}
