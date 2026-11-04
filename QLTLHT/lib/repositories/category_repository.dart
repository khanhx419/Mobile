import '../../database/daos/category_dao.dart';
import '../../models/category.dart';

class CategoryRepository {
  final CategoryDao _categoryDao;

  CategoryRepository({CategoryDao? categoryDao}) : _categoryDao = categoryDao ?? CategoryDao();

  Future<List<Category>> getAllCategories() => _categoryDao.getAllCategories();

  Future<Category?> getCategoryById(String id) => _categoryDao.getCategoryById(id);

  Future<int> addCategory(Category category) async {
    final enriched = category.copyWith(dateTimeModified: DateTime.now());
    return await _categoryDao.insertCategory(enriched);
  }

  Future<int> updateCategory(Category category) async {
    final enriched = category.copyWith(dateTimeModified: DateTime.now());
    return await _categoryDao.updateCategory(enriched);
  }

  Future<int> deleteCategory(String categoryId) => _categoryDao.deleteCategory(categoryId);
}
