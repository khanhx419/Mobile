import 'dart:convert';
import '../../database/daos/delete_log_dao.dart';
import '../../database/daos/subject_dao.dart';
import '../../models/delete_log.dart';
import '../../models/subject.dart';

class SubjectRepository {
  final SubjectDao _subjectDao;
  final DeleteLogDao _deleteLogDao;

  SubjectRepository({
    SubjectDao? subjectDao,
    DeleteLogDao? deleteLogDao,
  })  : _subjectDao = subjectDao ?? SubjectDao(),
        _deleteLogDao = deleteLogDao ?? DeleteLogDao();

  Future<List<Subject>> getAllSubjects() => _subjectDao.getAllSubjects();

  Future<Subject?> getSubjectById(String id) => _subjectDao.getSubjectById(id);

  Future<int> addSubject(Subject subject) async {
    final now = DateTime.now();
    final enriched = subject.copyWith(
      dateCreated: subject.dateCreated,
      dateTimeModified: now,
    );
    return await _subjectDao.insertSubject(enriched);
  }

  Future<int> updateSubject(Subject subject) async {
    final enriched = subject.copyWith(
      dateTimeModified: DateTime.now(),
    );
    return await _subjectDao.updateSubject(enriched);
  }

  Future<bool> deleteSubject(String subjectId) async {
    final sub = await _subjectDao.getSubjectById(subjectId);
    if (sub == null) return false;

    // Log deletion into DeleteLogs
    final log = DeleteLog(
      entryPk: sub.subjectId,
      type: 'subject',
      title: sub.name,
      payloadJson: jsonEncode(sub.toMap()),
      dateTimeModified: DateTime.now(),
    );
    await _deleteLogDao.insertDeleteLog(log);

    final deletedCount = await _subjectDao.deleteSubject(subjectId);
    return deletedCount > 0;
  }

  Future<int> getTotalCount() => _subjectDao.countSubjects();
}
