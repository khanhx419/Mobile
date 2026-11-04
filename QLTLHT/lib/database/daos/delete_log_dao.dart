import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/delete_log.dart';
import '../../models/document.dart';
import '../app_database.dart';

class DeleteLogDao {
  final AppDatabase _dbManager;

  DeleteLogDao({AppDatabase? dbManager}) : _dbManager = dbManager ?? AppDatabase.instance;

  Future<Database> get _db => _dbManager.database;

  Future<int> insertDeleteLog(DeleteLog log) async {
    final db = await _db;
    final rowId = await db.insert('delete_logs', log.toMap());
    _dbManager.notifyTableChanged('delete_logs');
    return rowId;
  }

  Future<List<DeleteLog>> getAllDeleteLogs() async {
    final db = await _db;
    final results = await db.query(
      'delete_logs',
      orderBy: 'dateTimeModified DESC',
    );
    return results.map((m) => DeleteLog.fromMap(m)).toList();
  }

  Future<DeleteLog?> getDeleteLogById(int id) async {
    final db = await _db;
    final results = await db.query(
      'delete_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return DeleteLog.fromMap(results.first);
  }

  Future<int> deleteLogPermanently(int id) async {
    final db = await _db;
    final count = await db.delete(
      'delete_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    _dbManager.notifyTableChanged('delete_logs');
    return count;
  }

  Future<int> clearAllLogs() async {
    final db = await _db;
    final count = await db.delete('delete_logs');
    _dbManager.notifyTableChanged('delete_logs');
    return count;
  }

  /// Restore deleted document back to documents table using its payloadJson
  Future<bool> restoreDocument(int logId) async {
    final db = await _db;
    final log = await getDeleteLogById(logId);
    if (log == null || log.type != 'document') return false;

    try {
      final map = jsonDecode(log.payloadJson) as Map<String, dynamic>;
      final doc = Document.fromMap(map);
      await db.insert('documents', doc.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await deleteLogPermanently(logId);
      _dbManager.notifyTableChanged('documents');
      _dbManager.notifyTableChanged('delete_logs');
      return true;
    } catch (e) {
      return false;
    }
  }
}
