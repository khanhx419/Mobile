import 'package:flutter_test/flutter_test.dart';
import 'package:klcn/models/habit.dart';

void main() {
  test('Habit model serialization test', () {
    final habit = Habit(
      id: 1,
      title: 'Đọc sách 20 phút',
      description: 'Đọc sách phát triển bản thân',
      frequencyType: 'daily',
      selectedDays: [1, 2, 3, 4, 5, 6, 7],
      reminderTime: '21:00',
      colorValue: 0xFF2196F3,
      iconCodePoint: 0xe3e0,
    );

    final map = habit.toMap();
    expect(map['title'], 'Đọc sách 20 phút');
    expect(map['frequency_type'], 'daily');
    expect(map['reminder_time'], '21:00');

    final reconstructed = Habit.fromMap(map);
    expect(reconstructed.title, habit.title);
    expect(reconstructed.frequencyType, habit.frequencyType);
    expect(reconstructed.selectedDays.length, 7);
  });

  test('Habit weekday application test', () {
    final habit = Habit(
      id: 2,
      title: 'Tập gym',
      frequencyType: 'specific_days',
      selectedDays: [1, 3, 5], // T2, T4, T6
    );

    expect(habit.appliesToWeekday(1), true);
    expect(habit.appliesToWeekday(2), false);
    expect(habit.appliesToWeekday(3), true);
    expect(habit.appliesToWeekday(4), false);
    expect(habit.appliesToWeekday(5), true);
    expect(habit.appliesToWeekday(7), false);
  });
}
