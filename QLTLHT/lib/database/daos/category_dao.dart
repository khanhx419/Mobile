import 'package:sqflite/sqflite.dart';
import '../../models/category.dart';
import '../app_database.dart';

class CategoryDao {
  final AppDatabase _dbManager;

  CategoryDao({AppDatabase? dbManager}) : _dbManager = dbManager ?? AppDatabase.instance;

  Future<Database> get _db => _dbManager.database;

  Future<int> insertCategory(Category category) async {
    final db = await _db;
    final rowId = await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _dbManager.notifyTableChanged('categories');
    return rowId;
  }

  Future<int> updateCategory(Category category) async {
    final db = await _db;
    final count = await db.update(
      'categories',
      category.toMap(),
      where: 'categoryId = ?',
      whereArgs: [category.categoryId],
    );
    _dbManager.notifyTableChanged('categories');
    return count;
  }

  Future<int> deleteCategory(String categoryId) async {
    final db = await _db;
    final count = await db.delete(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    _dbManager.notifyTableChanged('categories');
    return count;
  }

  Future<Category?> getCategoryById(String categoryId) async {
    final db = await _db;
    final results = await db.query(
      'categories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    if (results.isEmpty) return null;
    return Category.fromMap(results.first);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _db;
    final results = await db.query(
      'categories',
      orderBy: 'sortOrder ASC, name ASC',
    );
    return results.map((m) => Category.fromMap(m)).toList();
  }
}
