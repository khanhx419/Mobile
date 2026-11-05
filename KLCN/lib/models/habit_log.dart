class HabitLog {
  final int? id;
  final int habitId;
  final String dateString; // "YYYY-MM-DD"
  final bool isCompleted;
  final DateTime completedAt;

  HabitLog({
    this.id,
    required this.habitId,
    required this.dateString,
    this.isCompleted = true,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date_string': dateString,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      dateString: map['date_string'] as String,
      isCompleted: (map['is_completed'] as int? ?? 1) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
