import 'package:flutter/material.dart';

class Habit {
  final int? id;
  final String title;
  final String description;
  final String frequencyType; // 'daily' or 'specific_days'
  final List<int> selectedDays; // 1 = Monday, ..., 7 = Sunday
  final String reminderTime; // "HH:mm"
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;
  final bool isArchived;

  Habit({
    this.id,
    required this.title,
    this.description = '',
    this.frequencyType = 'daily',
    this.selectedDays = const [1, 2, 3, 4, 5, 6, 7],
    this.reminderTime = '08:00',
    this.colorValue = 0xFF2196F3, // Colors.blue
    this.iconCodePoint = 0xe5fe, // Icons.check_circle_outline
    DateTime? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  // Convert Habit to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'frequency_type': frequencyType,
      'selected_days': selectedDays.join(','),
      'reminder_time': reminderTime,
      'color_value': colorValue,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt.toIso8601String(),
      'is_archived': isArchived ? 1 : 0,
    };
  }

  // Create Habit from SQLite Map
  factory Habit.fromMap(Map<String, dynamic> map) {
    List<int> days = [];
    if (map['selected_days'] != null && map['selected_days'].toString().isNotEmpty) {
      days = map['selected_days']
          .toString()
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s) ?? 1)
          .toList();
    }
    if (days.isEmpty) {
      days = [1, 2, 3, 4, 5, 6, 7];
    }

    return Habit(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      frequencyType: map['frequency_type'] as String? ?? 'daily',
      selectedDays: days,
      reminderTime: map['reminder_time'] as String? ?? '08:00',
      colorValue: map['color_value'] as int? ?? 0xFF2196F3,
      iconCodePoint: map['icon_code_point'] as int? ?? 0xe5fe,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    String? frequencyType,
    List<int>? selectedDays,
    String? reminderTime,
    int? colorValue,
    int? iconCodePoint,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      selectedDays: selectedDays ?? this.selectedDays,
      reminderTime: reminderTime ?? this.reminderTime,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // Kiểm tra xem thói quen có áp dụng cho một ngày cụ thể hay không
  bool appliesToWeekday(int weekday) {
    if (frequencyType == 'daily') return true;
    return selectedDays.contains(weekday);
  }
}
