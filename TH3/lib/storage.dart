import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'learning.dart';

class Store {
  final Database db;
  Store(this.db);
  static Future<Store> open({String? path}) async {
    final db = await openDatabase(
      path ?? p.join(await getDatabasesPath(), 'english_th3.db'),
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          goal_minutes INTEGER NOT NULL DEFAULT 5 CHECK(goal_minutes BETWEEN 1 AND 120),
          reminder_hour INTEGER NOT NULL DEFAULT 20, reminder_minute INTEGER NOT NULL DEFAULT 0,
          reminder_enabled INTEGER NOT NULL DEFAULT 0)''');
        await db.execute('''CREATE TABLE sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
          lesson_index INTEGER NOT NULL, practiced_at TEXT NOT NULL, local_day TEXT NOT NULL,
          seconds INTEGER NOT NULL CHECK(seconds > 0), transcript TEXT NOT NULL,
          confidence REAL, reference TEXT NOT NULL, score INTEGER,
          analysis_json TEXT NOT NULL, engine TEXT NOT NULL)''');
        await db.execute(
          'CREATE INDEX sessions_user_day ON sessions(user_id, local_day)',
        );
        await db.execute(
          'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.insert('users', {'name': 'Người học 1'});
      },
    );
    return Store(db);
  }

  Future<List<Map<String, Object?>>> users() =>
      db.query('users', orderBy: 'id');
  Future<int> activeId() async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['active_user'],
    );
    return rows.isEmpty
        ? (await users()).first['id'] as int
        : int.parse(rows.first['value'] as String);
  }

  Future<void> activate(int id) async => db.insert('settings', {
    'key': 'active_user',
    'value': '$id',
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> updateUser(int id, Map<String, Object?> values) async =>
      db.update('users', values, where: 'id = ?', whereArgs: [id]);
  Future<void> addUser(String name) async {
    final id = await db.insert('users', {'name': name.trim()});
    await activate(id);
  }

  Future<List<Map<String, Object?>>> history(int id) => db.query(
    'sessions',
    where: 'user_id = ?',
    whereArgs: [id],
    orderBy: 'id DESC',
  );
  Future<void> save({
    required int userId,
    required int lessonIndex,
    required String transcript,
    required int seconds,
    required Assessment result,
    double? confidence,
    DateTime? now,
  }) async {
    final time = now ?? DateTime.now();
    await db.insert('sessions', {
      'user_id': userId,
      'lesson_index': lessonIndex,
      'practiced_at': time.toIso8601String(),
      'local_day': dayKey(time),
      'seconds': seconds,
      'transcript': transcript,
      'confidence': confidence,
      'reference': lessons[lessonIndex].text,
      'score': result.score,
      'analysis_json': jsonEncode({
        'pairs': result.pairs.map((p) => p.toJson()).toList(),
        'tips': result.tips,
        'unknown': result.unknown,
      }),
      'engine':
          'Android SpeechRecognizer + IPA edit-distance v1 (transcript proxy)',
    });
  }
}
