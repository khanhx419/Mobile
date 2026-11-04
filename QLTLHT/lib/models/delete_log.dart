class DeleteLog {
  final int? id;
  final String entryPk;
  final String type; // 'document', 'subject', 'category'
  final String title;
  final String payloadJson;
  final DateTime dateTimeModified;

  DeleteLog({
    this.id,
    required this.entryPk,
    required this.type,
    required this.title,
    required this.payloadJson,
    required this.dateTimeModified,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'entryPk': entryPk,
      'type': type,
      'title': title,
      'payloadJson': payloadJson,
      'dateTimeModified': dateTimeModified.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory DeleteLog.fromMap(Map<String, dynamic> map) {
    return DeleteLog(
      id: map['id'] as int?,
      entryPk: map['entryPk'] as String,
      type: map['type'] as String,
      title: map['title'] as String? ?? 'Không có tiêu đề',
      payloadJson: map['payloadJson'] as String? ?? '{}',
      dateTimeModified: DateTime.tryParse(map['dateTimeModified'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
