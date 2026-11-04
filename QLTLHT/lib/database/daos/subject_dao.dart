import 'package:sqflite/sqflite.dart';
import '../../models/subject.dart';
import '../app_database.dart';

class SubjectDao {
  final AppDatabase _dbManager;

  SubjectDao({AppDatabase? dbManager}) : _dbManager = dbManager ?? AppDatabase.instance;

  Future<Database> get _db => _dbManager.database;

  Future<int> insertSubject(Subject subject) async {
    final db = await _db;
    final rowId = await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _dbManager.notifyTableChanged('subjects');
    return rowId;
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await _db;
    final count = await db.update(
      'subjects',
      subject.toMap(),
      where: 'subjectId = ?',
      whereArgs: [subject.subjectId],
    );
    _dbManager.notifyTableChanged('subjects');
    return count;
  }

  Future<int> deleteSubject(String subjectId) async {
    final db = await _db;
    final count = await db.delete(
      'subjects',
      where: 'subjectId = ?',
      whereArgs: [subjectId],
    );
    _dbManager.notifyTableChanged('subjects');
    return count;
  }

  Future<Subject?> getSubjectById(String subjectId) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT s.*, COUNT(d.documentId) AS documentCount
      FROM subjects s
      LEFT JOIN documents d ON s.subjectId = d.subjectFk
      WHERE s.subjectId = ?
      GROUP BY s.subjectId
    ''', [subjectId]);

    if (results.isEmpty) return null;
    return Subject.fromMap(results.first);
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT s.*, COUNT(d.documentId) AS documentCount
      FROM subjects s
      LEFT JOIN documents d ON s.subjectId = d.subjectFk
      GROUP BY s.subjectId
      ORDER BY s.sortOrder ASC, s.name ASC
    ''');
    return results.map((m) => Subject.fromMap(m)).toList();
  }

  Future<int> countSubjects() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM subjects');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
