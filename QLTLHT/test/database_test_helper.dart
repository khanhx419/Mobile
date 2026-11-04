import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qltlht/core/constants/app_constants.dart';
import 'package:qltlht/database/app_database.dart';
import 'package:qltlht/database/initial_data.dart';

class DatabaseTestHelper {
  static Future<Database> createInMemoryDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final db = await openDatabase(
      inMemoryDatabasePath,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
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

        await InitialData.seed(db);
      },
    );

    AppDatabase.setMockDatabase(db);
    return db;
  }
}
