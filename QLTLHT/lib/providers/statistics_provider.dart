import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../database/app_database.dart';
import '../../repositories/document_repository.dart';
import '../../repositories/subject_repository.dart';

class LearningStatistics {
  final int totalDocuments;
  final int totalSubjects;
  final int totalSizeBytes;
  final int completedDocuments;
  final int favoriteDocuments;
  final Map<String, int> countBySubject;
  final Map<String, int> countByCategory;

  LearningStatistics({
    required this.totalDocuments,
    required this.totalSubjects,
    required this.totalSizeBytes,
    required this.completedDocuments,
    required this.favoriteDocuments,
    required this.countBySubject,
    required this.countByCategory,
  });

  double get completionRate => totalDocuments == 0 ? 0.0 : (completedDocuments / totalDocuments);
}

class StatisticsProvider extends ChangeNotifier {
  final DocumentRepository _docRepo;
  final SubjectRepository _subRepo;
  StreamSubscription? _dbSubscription;

  LearningStatistics? _stats;
  bool _isLoading = false;

  StatisticsProvider({
    DocumentRepository? docRepo,
    SubjectRepository? subRepo,
  })  : _docRepo = docRepo ?? DocumentRepository(),
        _subRepo = subRepo ?? SubjectRepository() {
    _listenToDatabaseChanges();
    loadStatistics();
  }

  LearningStatistics? get stats => _stats;
  bool get isLoading => _isLoading;

  void _listenToDatabaseChanges() {
    _dbSubscription = AppDatabase.instance.tableUpdatesStream.listen((_) {
      loadStatistics();
    });
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final docs = await _docRepo.getAllDocuments();
      final totalSubjects = await _subRepo.getTotalCount();
      final totalSizeBytes = await _docRepo.getTotalSizeBytes();
      final countBySubject = await _docRepo.getCountBySubject();
      final countByCategory = await _docRepo.getCountByCategory();

      int completed = 0;
      int favorites = 0;
      for (final doc in docs) {
        if (doc.isCompleted) completed++;
        if (doc.isFavorite) favorites++;
      }

      _stats = LearningStatistics(
        totalDocuments: docs.length,
        totalSubjects: totalSubjects,
        totalSizeBytes: totalSizeBytes,
        completedDocuments: completed,
        favoriteDocuments: favorites,
        countBySubject: countBySubject,
        countByCategory: countByCategory,
      );
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }
}
