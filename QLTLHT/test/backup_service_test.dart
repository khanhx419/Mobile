import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/core/constants/app_constants.dart';
import 'package:qltlht/services/backup_service.dart';
import 'package:sqflite/sqflite.dart';
import 'database_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late BackupService backupService;

  setUp(() async {
    db = await DatabaseTestHelper.createInMemoryDatabase();
    backupService = BackupService();
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử BackupService (Sao lưu & Phục hồi Cashew Snapshot)', () {
    test('1. Xuất dữ liệu snapshot dạng JSON chứa đầy đủ cấu trúc thực thể', () async {
      final jsonSnapshot = await backupService.exportToJson();
      expect(jsonSnapshot.isNotEmpty, true);

      final Map<String, dynamic> parsed = jsonDecode(jsonSnapshot);
      expect(parsed['app'], AppConstants.appName);
      expect(parsed['schemaVersion'], AppConstants.dbVersion);
      expect(parsed['subjects'], isA<List>());
      expect(parsed['categories'], isA<List>());
      expect(parsed['documents'], isA<List>());

      final List docs = parsed['documents'];
      expect(docs.isNotEmpty, true);
    });

    test('2. Nhập dữ liệu snapshot từ JSON và hợp nhất vào SQLite', () async {
      final customBackup = jsonEncode({
        'app': AppConstants.appName,
        'version': '1.0.0',
        'schemaVersion': 1,
        'subjects': [
          {
            'subjectId': 'sub_cloud',
            'code': 'INT3500',
            'name': 'Điện toán Đám mây',
            'lecturer': 'TS. Hoàng Văn B',
            'color': 0xFF2563EB,
            'icon': 'cloud',
            'sortOrder': 9,
            'dateCreated': DateTime.now().toIso8601String(),
            'dateTimeModified': DateTime.now().toIso8601String(),
          }
        ],
        'categories': [],
        'documents': [
          {
            'documentId': 'doc_cloud_01',
            'title': 'Ebook AWS Solutions Architect',
            'description': 'Tài liệu ôn thi chứng chỉ AWS Cloud',
            'subjectFk': 'sub_cloud',
            'categoryFk': 'cat_reference',
            'fileType': 'PDF',
            'fileName': 'AWS_Architect.pdf',
            'fileSizeBytes': 10485760,
            'tags': 'AWS, Cloud',
            'isFavorite': 1,
            'isCompleted': 0,
            'dateCreated': DateTime.now().toIso8601String(),
            'dateTimeModified': DateTime.now().toIso8601String(),
          }
        ]
      });

      final result = await backupService.importFromJson(customBackup);
      expect(result['subjects'], equals(1));
      expect(result['documents'], equals(1));

      // Kiểm tra trong database đã tồn tại môn và tài liệu mới
      final checkDoc = await db.query('documents', where: 'documentId = ?', whereArgs: ['doc_cloud_01']);
      expect(checkDoc.isNotEmpty, true);
      expect(checkDoc.first['title'], 'Ebook AWS Solutions Architect');
    });
  });
}
