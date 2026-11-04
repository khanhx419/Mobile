import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../../database/app_database.dart';
import '../../models/category.dart';
import '../../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;
  StreamSubscription? _dbSubscription;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository() {
    _listenToDatabaseChanges();
    loadCategories();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _listenToDatabaseChanges() {
    _dbSubscription = AppDatabase.instance.tableUpdatesStream.listen((tableName) {
      if (tableName == 'categories') {
        loadCategories();
      }
    });
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _repository.getAllCategories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Lỗi khi tải danh mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      final res = await _repository.addCategory(category);
      await loadCategories();
      return res > 0;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm danh mục: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }
}
