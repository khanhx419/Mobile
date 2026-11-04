import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../models/document.dart';
import '../app_database.dart';

class DocumentDao {
  final AppDatabase _dbManager;

  DocumentDao({AppDatabase? dbManager}) : _dbManager = dbManager ?? AppDatabase.instance;

  Future<Database> get _db => _dbManager.database;

  // Base query with JOINs for rich metadata display
  static const String _baseSelectQuery = '''
    SELECT 
      d.*,
      s.name AS subjectName,
      s.code AS subjectCode,
      s.color AS subjectColor,
      c.name AS categoryName,
      c.color AS categoryColor
    FROM documents d
    LEFT JOIN subjects s ON d.subjectFk = s.subjectId
    LEFT JOIN categories c ON d.categoryFk = c.categoryId
  ''';

  Future<int> insertDocument(Document doc) async {
    final db = await _db;
    final rowId = await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _dbManager.notifyTableChanged('documents');
    return rowId;
  }

  Future<int> updateDocument(Document doc) async {
    final db = await _db;
    final count = await db.update(
      'documents',
      doc.toMap(),
      where: 'documentId = ?',
      whereArgs: [doc.documentId],
    );
    _dbManager.notifyTableChanged('documents');
    return count;
  }

  Future<int> deleteDocument(String documentId) async {
    final db = await _db;
    final count = await db.delete(
      'documents',
      where: 'documentId = ?',
      whereArgs: [documentId],
    );
    _dbManager.notifyTableChanged('documents');
    return count;
  }

  Future<Document?> getDocumentById(String documentId) async {
    final db = await _db;
    final results = await db.rawQuery(
      '$_baseSelectQuery WHERE d.documentId = ?',
      [documentId],
    );
    if (results.isEmpty) return null;
    return Document.fromMap(results.first);
  }

  Future<List<Document>> getAllDocuments() async {
    final db = await _db;
    final results = await db.rawQuery('$_baseSelectQuery ORDER BY d.dateTimeModified DESC');
    return results.map((m) => Document.fromMap(m)).toList();
  }

  Future<List<Document>> searchAndFilterDocuments({
    String? query,
    String? subjectFk,
    String? categoryFk,
    bool? isFavorite,
    bool? isCompleted,
    String? fileType,
    String sortBy = AppConstants.sortDateDesc,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      final term = '%${query.trim()}%';
      whereClauses.add('(d.title LIKE ? OR d.description LIKE ? OR d.tags LIKE ? OR d.fileName LIKE ?)');
      whereArgs.addAll([term, term, term, term]);
    }

    if (subjectFk != null && subjectFk.isNotEmpty && subjectFk != 'all') {
      whereClauses.add('d.subjectFk = ?');
      whereArgs.add(subjectFk);
    }

    if (categoryFk != null && categoryFk.isNotEmpty && categoryFk != 'all') {
      whereClauses.add('d.categoryFk = ?');
      whereArgs.add(categoryFk);
    }

    if (isFavorite == true) {
      whereClauses.add('d.isFavorite = 1');
    }

    if (isCompleted != null) {
      whereClauses.add('d.isCompleted = ?');
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (fileType != null && fileType.isNotEmpty && fileType != 'all') {
      whereClauses.add('d.fileType = ?');
      whereArgs.add(fileType);
    }

    String orderBy;
    switch (sortBy) {
      case AppConstants.sortDateAsc:
        orderBy = 'd.dateCreated ASC';
        break;
      case AppConstants.sortTitleAsc:
        orderBy = 'd.title COLLATE NOCASE ASC';
        break;
      case AppConstants.sortTitleDesc:
        orderBy = 'd.title COLLATE NOCASE DESC';
        break;
      case AppConstants.sortSizeDesc:
        orderBy = 'd.fileSizeBytes DESC';
        break;
      case AppConstants.sortDateDesc:
      default:
        orderBy = 'd.dateTimeModified DESC';
        break;
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final sql = '$_baseSelectQuery $whereSql ORDER BY $orderBy';

    final results = await db.rawQuery(sql, whereArgs);
    return results.map((m) => Document.fromMap(m)).toList();
  }

  Future<int> toggleFavorite(String documentId, bool isFavorite) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      'documents',
      {
        'isFavorite': isFavorite ? 1 : 0,
        'dateTimeModified': now,
      },
      where: 'documentId = ?',
      whereArgs: [documentId],
    );
    _dbManager.notifyTableChanged('documents');
    return count;
  }

  Future<int> toggleCompleted(String documentId, bool isCompleted) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final count = await db.update(
      'documents',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'dateTimeModified': now,
      },
      where: 'documentId = ?',
      whereArgs: [documentId],
    );
    _dbManager.notifyTableChanged('documents');
    return count;
  }

  Future<int> countDocuments() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM documents');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> sumTotalFileSizeBytes() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(fileSizeBytes) as total FROM documents');
    if (result.isEmpty || result.first['total'] == null) return 0;
    return (result.first['total'] as num).toInt();
  }

  Future<Map<String, int>> countDocumentsBySubject() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT subjectFk, COUNT(*) as count
      FROM documents
      GROUP BY subjectFk
    ''');
    final map = <String, int>{};
    for (final row in results) {
      final key = row['subjectFk'] as String;
      final val = (row['count'] as num).toInt();
      map[key] = val;
    }
    return map;
  }

  Future<Map<String, int>> countDocumentsByCategory() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT categoryFk, COUNT(*) as count
      FROM documents
      GROUP BY categoryFk
    ''');
    final map = <String, int>{};
    for (final row in results) {
      final key = row['categoryFk'] as String;
      final val = (row['count'] as num).toInt();
      map[key] = val;
    }
    return map;
  }
}
