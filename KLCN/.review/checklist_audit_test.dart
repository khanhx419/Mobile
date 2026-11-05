// Review-only regression probes. Uses a temporary DB, never the user's database.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:intl/intl.dart';
import 'package:klcn/models/habit.dart';
import 'package:klcn/providers/habit_provider.dart';
import 'package:klcn/services/database_service.dart';

class ReviewPaths extends PathProviderPlatform {
  ReviewPaths(this.directory);
  final String directory;
  @override
  Future<String?> getApplicationDocumentsPath() async => directory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HabitProvider provider;
  final now = DateTime.now();
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('klcn_audit_');
    PathProviderPlatform.instance = ReviewPaths(directory.path);
    provider = HabitProvider();
    await provider.init();
    final database = await DatabaseService.instance.database;
    final rows = await database.rawQuery('SELECT COUNT(*) AS n FROM habit_logs');
    // ignore: avoid_print
    print('Fresh database contains ${rows.single['n']} seeded completion records');
    for (final habit in provider.habits.toList()) {
      await provider.deleteHabit(habit.id!);
    }
    await provider.addHabit(Habit(title: 'Created today', createdAt: now));
  });
  tearDownAll(() async {
    await (await DatabaseService.instance.database).close();
    provider.dispose();
  });

  test('habit created today must not appear yesterday', () async {
    await provider.setSelectedDate(DateTime(now.year, now.month, now.day - 1));
    expect(provider.habitsForSelectedDate, isEmpty);
  });
  test('week must not charge goals before habit creation', () async {
    final stats = await provider.getWeeklyStats(anchorDate: now);
    expect(stats.take(6).map((s) => s.totalCount).toList(), everyElement(0));
  });
  test('month must only charge today for a newly created daily habit', () async {
    final stats = await provider.getMonthlyStats(monthDate: now);
    expect(stats['totalExpected'], 1);
  });
  test('30-day performance must count only days since creation', () async {
    final result = await provider.getHabitPerformances();
    expect(result.single.targetDays, 1);
  });
  test('a Monday-Wednesday-Friday habit should retain streak across rest days', () async {
    final db = await DatabaseService.instance.database;
    final schedule = <int>[1, 3, 5];
    await provider.addHabit(Habit(title: 'Three scheduled sessions', frequencyType: 'specific_days',
        selectedDays: schedule, createdAt: now.subtract(const Duration(days: 30))));
    final habit = provider.habits.first;
    var cursor = DateTime(now.year, now.month, now.day);
    var inserted = 0;
    while (inserted < 3) {
      if (schedule.contains(cursor.weekday)) {
        await db.insert('habit_logs', {'habit_id': habit.id, 'date_string': DateFormat('yyyy-MM-dd').format(cursor),
          'is_completed': 1, 'completed_at': cursor.toIso8601String()});
        inserted++;
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    expect(await DatabaseService.instance.getStreakForHabit(habit.id!), 3);
  });
}
