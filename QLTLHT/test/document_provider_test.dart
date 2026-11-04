import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/core/constants/app_constants.dart';
import 'package:qltlht/models/document.dart';
import 'package:qltlht/models/subject.dart';
import 'package:qltlht/providers/document_provider.dart';
import 'package:qltlht/providers/settings_provider.dart';
import 'package:qltlht/providers/subject_provider.dart';
import 'package:qltlht/repositories/document_repository.dart';
import 'package:qltlht/repositories/subject_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late DocumentRepository docRepo;
  late SubjectRepository subRepo;

  setUp(() async {
    db = await DatabaseTestHelper.createInMemoryDatabase();
    docRepo = DocumentRepository();
    subRepo = SubjectRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử Tầng State Management (Providers)', () {
    test('1. DocumentProvider nạp dữ liệu và phản ứng với bộ lọc tìm kiếm', () async {
      final provider = DocumentProvider(repository: docRepo);
      await provider.loadDocuments();

      expect(provider.documents.isNotEmpty, true);
      final initialCount = provider.totalCount;

      // Tìm kiếm từ khóa 'Flutter'
      provider.setSearchQuery('Flutter');
      await provider.loadDocuments();
      expect(provider.documents.every((d) => d.title.contains('Flutter') || d.tags.contains('Flutter')), true);

      // Reset bộ lọc
      provider.resetFilters();
      await provider.loadDocuments();
      expect(provider.totalCount, equals(initialCount));
    });

    test('2. DocumentProvider thêm, toggle favorite và xóa tài liệu', () async {
      final provider = DocumentProvider(repository: docRepo);
      await provider.loadDocuments();

      final newDoc = Document(
        documentId: 'doc_prov_1',
        title: 'Tài liệu State Provider Test',
        subjectFk: 'sub_mob',
        categoryFk: 'cat_lecture',
        fileType: AppConstants.fileTypePdf,
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      final added = await provider.addDocument(newDoc);
      expect(added, true);

      // Toggle favorite
      await provider.toggleFavorite('doc_prov_1', false);
      final checkDoc = provider.documents.firstWhere((d) => d.documentId == 'doc_prov_1');
      expect(checkDoc.isFavorite, true);

      // Xóa tài liệu -> vào thùng rác
      final deleted = await provider.deleteDocument('doc_prov_1');
      expect(deleted, true);
      expect(provider.recycleBinLogs.any((l) => l.entryPk == 'doc_prov_1'), true);

      // Khôi phục lại
      final log = provider.recycleBinLogs.firstWhere((l) => l.entryPk == 'doc_prov_1');
      final restored = await provider.restoreDocument(log.id!);
      expect(restored, true);
    });

    test('3. SubjectProvider quản lý thêm và cập nhật môn học', () async {
      final subProvider = SubjectProvider(repository: subRepo);
      await subProvider.loadSubjects();

      final newSub = Subject(
        subjectId: 'sub_prov_test',
        code: 'INT9999',
        name: 'Môn học kiểm thử State',
        lecturer: 'Giảng viên Test',
        color: 0xFF2563EB,
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      final added = await subProvider.addSubject(newSub);
      expect(added, true);
      expect(subProvider.subjects.any((s) => s.subjectId == 'sub_prov_test'), true);
    });

    test('4. SettingsProvider thay đổi chủ đề và màu sắc chủ đạo', () async {
      final settingsProvider = SettingsProvider();

      await settingsProvider.setThemeMode(ThemeMode.dark);
      expect(settingsProvider.themeMode, ThemeMode.dark);

      await settingsProvider.setAccentColor(const Color(0xFFE11D48));
      expect(settingsProvider.accentColor, const Color(0xFFE11D48));
    });
  });
}
