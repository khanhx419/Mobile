import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../database/app_database.dart';
import '../../models/subject.dart';
import '../../repositories/subject_repository.dart';

class SubjectProvider extends ChangeNotifier {
  final SubjectRepository _repository;
  StreamSubscription? _dbSubscription;

  List<Subject> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  SubjectProvider({SubjectRepository? repository})
      : _repository = repository ?? SubjectRepository() {
    _listenToDatabaseChanges();
    loadSubjects();
  }

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _listenToDatabaseChanges() {
    _dbSubscription = AppDatabase.instance.tableUpdatesStream.listen((tableName) {
      if (tableName == 'subjects' || tableName == 'documents') {
        loadSubjects();
      }
    });
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await _repository.getAllSubjects();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Lỗi khi tải môn học: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSubject(Subject subject) async {
    try {
      final res = await _repository.addSubject(subject);
      await loadSubjects();
      return res > 0;
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm môn học: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubject(Subject subject) async {
    try {
      final res = await _repository.updateSubject(subject);
      await loadSubjects();
      return res > 0;
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật môn học: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      final success = await _repository.deleteSubject(id);
      await loadSubjects();
      return success;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa môn học: $e';
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
