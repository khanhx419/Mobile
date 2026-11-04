import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../core/constants/app_constants.dart';
import 'initial_data.dart';

/// AppDatabase manages the local SQLite database lifecycle, schema migrations,
/// and connection pooling according to Cashew's Local-First Architecture.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  /// Reactive stream broadcast when any table is modified.
  /// Mimics Drift's TableUpdates Stream from Cashew.
  final _tableUpdatesController = StreamController<String>.broadcast();
  Stream<String> get tableUpdatesStream => _tableUpdatesController.stream;

  void notifyTableChanged(String tableName) {
    _tableUpdatesController.add(tableName);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Optional custom database for Unit Testing (in-memory or custom path)
  static void setMockDatabase(Database db) {
    _database = db;
  }

  Future<Database> _initDatabase({String? customPath}) async {
    // Enable FFI on Web or Windows/Linux/macOS
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (customPath != null) {
      path = customPath;
    } else {
      if (kIsWeb) {
        path = AppConstants.dbName;
      } else {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, AppConstants.dbName);
      }
    }

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable SQLite foreign keys (ACID integrity like Cashew)
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Table Subjects (Equivalent to Wallets in Cashew)
    await db.execute('''
      CREATE TABLE subjects (
        subjectId TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        lecturer TEXT DEFAULT '',
        color INTEGER NOT NULL,
        icon TEXT DEFAULT 'school',
        sortOrder INTEGER DEFAULT 0,
        dateCreated TEXT NOT NULL,
        dateTimeModified TEXT NOT NULL
      )
    ''');

    // 2. Table Categories (Equivalent to Categories in Cashew)
    await db.execute('''
      CREATE TABLE categories (
        categoryId TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        color INTEGER NOT NULL,
        icon TEXT DEFAULT 'folder',
        sortOrder INTEGER DEFAULT 0,
        dateTimeModified TEXT NOT NULL
      )
    ''');

    // 3. Table Documents (Equivalent to Transactions in Cashew)
    await db.execute('''
      CREATE TABLE documents (
        documentId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        subjectFk TEXT NOT NULL,
        categoryFk TEXT NOT NULL,
        fileType TEXT NOT NULL,
        fileName TEXT DEFAULT '',
        fileUri TEXT DEFAULT '',
        fileSizeBytes INTEGER DEFAULT 0,
        tags TEXT DEFAULT '',
        isFavorite INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        dateCreated TEXT NOT NULL,
        dateTimeModified TEXT NOT NULL,
        FOREIGN KEY (subjectFk) REFERENCES subjects(subjectId) ON DELETE CASCADE,
        FOREIGN KEY (categoryFk) REFERENCES categories(categoryId) ON DELETE RESTRICT
      )
    ''');

    // 4. Table DeleteLogs (Tombstone table for distributed sync & soft delete like Cashew)
    await db.execute('''
      CREATE TABLE delete_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entryPk TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        payloadJson TEXT NOT NULL,
        dateTimeModified TEXT NOT NULL
      )
    ''');

    // 5. Indexes for query optimization
    await db.execute('CREATE INDEX idx_doc_subject ON documents(subjectFk)');
    await db.execute('CREATE INDEX idx_doc_category ON documents(categoryFk)');
    await db.execute('CREATE INDEX idx_doc_modified ON documents(dateTimeModified)');
    await db.execute('CREATE INDEX idx_doc_created ON documents(dateCreated)');
    await db.execute('CREATE INDEX idx_doc_favorite ON documents(isFavorite)');
    await db.execute('CREATE INDEX idx_delete_logs_pk ON delete_logs(entryPk)');

    // Populate initial default data
    await InitialData.seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema migration handling
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
