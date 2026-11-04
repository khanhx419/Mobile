import 'dart:convert';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../database/app_database.dart';
import '../../models/category.dart';
import '../../models/delete_log.dart';
import '../../models/document.dart';
import '../../models/subject.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/subject_repository.dart';

class BackupService {
  final DocumentRepository _docRepo;
  final SubjectRepository _subRepo;
  final CategoryRepository _catRepo;

  BackupService({
    DocumentRepository? docRepo,
    SubjectRepository? subRepo,
    CategoryRepository? catRepo,
  })  : _docRepo = docRepo ?? DocumentRepository(),
        _subRepo = subRepo ?? SubjectRepository(),
        _catRepo = catRepo ?? CategoryRepository();

  /// Export complete application state to JSON snapshot string
  /// Equivalent to Cashew's snapshot export mechanism
  Future<String> exportToJson() async {
    final documents = await _docRepo.getAllDocuments();
    final subjects = await _subRepo.getAllSubjects();
    final categories = await _catRepo.getAllCategories();
    final deleteLogs = await _docRepo.getRecycleBinLogs();

    final data = {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'schemaVersion': AppConstants.dbVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'subjects': subjects.map((s) => s.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'documents': documents.map((d) => d.toMap()).toList(),
      'deleteLogs': deleteLogs.map((l) => l.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import application state from JSON snapshot
  Future<Map<String, int>> importFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    int subjectsCount = 0;
    int categoriesCount = 0;
    int documentsCount = 0;

    // 1. Import Categories first (for foreign key integrity)
    if (data.containsKey('categories') && data['categories'] is List) {
      for (final item in data['categories']) {
        final cat = Category.fromMap(Map<String, dynamic>.from(item));
        await _catRepo.addCategory(cat);
        categoriesCount++;
      }
    }

    // 2. Import Subjects
    if (data.containsKey('subjects') && data['subjects'] is List) {
      for (final item in data['subjects']) {
        final sub = Subject.fromMap(Map<String, dynamic>.from(item));
        await _subRepo.addSubject(sub);
        subjectsCount++;
      }
    }

    // 3. Import Documents
    if (data.containsKey('documents') && data['documents'] is List) {
      for (final item in data['documents']) {
        final doc = Document.fromMap(Map<String, dynamic>.from(item));
        await _docRepo.addDocument(doc);
        documentsCount++;
      }
    }

    AppDatabase.instance.notifyTableChanged('documents');
    AppDatabase.instance.notifyTableChanged('subjects');
    AppDatabase.instance.notifyTableChanged('categories');

    return {
      'subjects': subjectsCount,
      'categories': categoriesCount,
      'documents': documentsCount,
    };
  }

  /// Save backup JSON to local file
  Future<File> exportToFile(String targetFilePath) async {
    final jsonContent = await exportToJson();
    final file = File(targetFilePath);
    return await file.writeAsString(jsonContent);
  }

  /// Load backup from local file
  Future<Map<String, int>> importFromFile(String sourceFilePath) async {
    final file = File(sourceFilePath);
    if (!await file.exists()) {
      throw FileSystemException('Tệp sao lưu không tồn tại', sourceFilePath);
    }
    final content = await file.readAsString();
    return await importFromJson(content);
  }
}
