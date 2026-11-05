import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/database_service.dart';

enum HabitFilter { all, completed, pending }

class DailyStat {
  final DateTime date;
  final String dateString;
  final String dayName;
  final int completedCount;
  final int totalCount;
  final double rate; // 0.0 to 1.0

  DailyStat({
    required this.date,
    required this.dateString,
    required this.dayName,
    required this.completedCount,
    required this.totalCount,
    required this.rate,
  });
}

class HabitPerformance {
  final Habit habit;
  final int completedDays;
  final int targetDays;
  final double completionRate;
  final int streak;

  HabitPerformance({
    required this.habit,
    required this.completedDays,
    required this.targetDays,
    required this.completionRate,
    required this.streak,
  });
}

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  List<Habit> _habits = [];
  DateTime _selectedDate = DateTime.now();
  Set<int> _completedHabitIds = {};
  Map<int, int> _streaks = {};
  bool _isLoading = true;
  HabitFilter _filter = HabitFilter.all;

  // Getters
  List<Habit> get habits => _habits;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateString => _dateFormat.format(_selectedDate);
  bool get isLoading => _isLoading;
  HabitFilter get filter => _filter;
  Map<int, int> get streaks => _streaks;

  // Lọc các thói quen áp dụng cho ngày đang chọn
  List<Habit> get habitsForSelectedDate {
    final weekday = _selectedDate.weekday; // 1 = Monday, 7 = Sunday
    final applicableHabits = _habits.where((h) => h.appliesToWeekday(weekday)).toList();

    switch (_filter) {
      case HabitFilter.completed:
        return applicableHabits.where((h) => _completedHabitIds.contains(h.id)).toList();
      case HabitFilter.pending:
        return applicableHabits.where((h) => !_completedHabitIds.contains(h.id)).toList();
      case HabitFilter.all:
      default:
        return applicableHabits;
    }
  }

  // Tổng số thói quen của ngày đang chọn
  int get totalHabitsForSelectedDate {
    final weekday = _selectedDate.weekday;
    return _habits.where((h) => h.appliesToWeekday(weekday)).length;
  }

  // Số thói quen đã hoàn thành của ngày đang chọn
  int get completedHabitsCountForSelectedDate {
    final weekday = _selectedDate.weekday;
    return _habits
        .where((h) => h.appliesToWeekday(weekday) && _completedHabitIds.contains(h.id))
        .length;
  }

  // Tỷ lệ hoàn thành ngày đang chọn (0.0 đến 1.0)
  double get completionRateForSelectedDate {
    final total = totalHabitsForSelectedDate;
    if (total == 0) return 0.0;
    return completedHabitsCountForSelectedDate / total;
  }

  // Kiểm tra một habit đã hoàn thành trong ngày đang chọn chưa
  bool isCompleted(int? habitId) {
    if (habitId == null) return false;
    return _completedHabitIds.contains(habitId);
  }

  int getStreak(int? habitId) {
    if (habitId == null) return 0;
    return _streaks[habitId] ?? 0;
  }

  void setFilter(HabitFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await _loadLogsForSelectedDate();
    notifyListeners();
  }

  // Khởi tạo tải dữ liệu
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadHabits();
    await _loadLogsForSelectedDate();
    await _loadStreaks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHabits() async {
    _habits = await _db.getAllHabits();
    notifyListeners();
  }

  Future<void> _loadLogsForSelectedDate() async {
    _completedHabitIds = await _db.getCompletedHabitIdsForDate(selectedDateString);
  }

  Future<void> _loadStreaks() async {
    final Map<int, int> newStreaks = {};
    for (var habit in _habits) {
      if (habit.id != null) {
        newStreaks[habit.id!] = await _db.getStreakForHabit(habit.id!);
      }
    }
    _streaks = newStreaks;
  }

  // Thêm thói quen mới
  Future<void> addHabit(Habit habit) async {
    final id = await _db.insertHabit(habit);
    final newHabit = habit.copyWith(id: id);
    _habits.insert(0, newHabit);
    _streaks[id] = 0;
    notifyListeners();
  }

  // Cập nhật thói quen
  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      notifyListeners();
    }
  }

  // Xóa thói quen
  Future<void> deleteHabit(int habitId) async {
    await _db.deleteHabit(habitId);
    _habits.removeWhere((h) => h.id == habitId);
    _completedHabitIds.remove(habitId);
    _streaks.remove(habitId);
    notifyListeners();
  }

  // Toggle hoàn thành thói quen
  Future<void> toggleHabitCompletion(int habitId) async {
    final isDone = await _db.toggleHabitCompletion(habitId, selectedDateString);
    if (isDone) {
      _completedHabitIds.add(habitId);
    } else {
      _completedHabitIds.remove(habitId);
    }

    // Cập nhật lại streak của habit này
    _streaks[habitId] = await _db.getStreakForHabit(habitId);

    notifyListeners();
  }

  // Reset dữ liệu về ban đầu (Seed data)
  Future<void> resetAll() async {
    _isLoading = true;
    notifyListeners();

    await _db.resetAllData();
    await init();
  }

  // ================= THỐNG KÊ (STATISTICS) =================

  // 1. Thống kê theo tuần (7 ngày gần nhất tính đến selectedDate hoặc hôm nay)
  Future<List<DailyStat>> getWeeklyStats({DateTime? anchorDate}) async {
    final anchor = anchorDate ?? DateTime.now();
    final List<DailyStat> stats = [];

    // Lấy 7 ngày: từ 6 ngày trước đến ngày anchor
    final startDate = anchor.subtract(const Duration(days: 6));
    final startDateStr = _dateFormat.format(startDate);
    final endDateStr = _dateFormat.format(anchor);

    final counts = await _db.getCompletedCountsByDate(startDateStr, endDateStr);

    for (int i = 6; i >= 0; i--) {
      final date = anchor.subtract(Duration(days: i));
      final dateStr = _dateFormat.format(date);
      final weekday = date.weekday;

      // Tính tổng số habit áp dụng cho thứ đó
      final total = _habits.where((h) => h.appliesToWeekday(weekday)).length;
      final completed = counts[dateStr] ?? 0;
      final rate = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

      // Tên thứ rút gọn (T2, T3, T4, T5, T6, T7, CN)
      final dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      final dayName = weekday == 7 ? 'CN' : 'T${weekday + 1}';

      stats.add(DailyStat(
        date: date,
        dateString: dateStr,
        dayName: dayName,
        completedCount: completed,
        totalCount: total,
        rate: rate,
      ));
    }

    return stats;
  }

  // 2. Thống kê theo tháng (30 ngày gần nhất hoặc cả tháng)
  Future<Map<String, dynamic>> getMonthlyStats({DateTime? monthDate}) async {
    final target = monthDate ?? DateTime.now();
    final firstDayOfMonth = DateTime(target.year, target.month, 1);
    final lastDayOfMonth = DateTime(target.year, target.month + 1, 0);

    final startStr = _dateFormat.format(firstDayOfMonth);
    final endStr = _dateFormat.format(lastDayOfMonth);

    final counts = await _db.getCompletedCountsByDate(startStr, endStr);

    int totalExpected = 0;
    int totalCompleted = 0;
    final now = DateTime.now();
    // Chỉ tính đến ngày hiện tại nếu xem tháng hiện tại
    final limitDay = (target.year == now.year && target.month == now.month)
        ? now.day
        : lastDayOfMonth.day;

    for (int day = 1; day <= limitDay; day++) {
      final date = DateTime(target.year, target.month, day);
      final dateStr = _dateFormat.format(date);
      final weekday = date.weekday;

      final expectedOnDay = _habits.where((h) => h.appliesToWeekday(weekday)).length;
      totalExpected += expectedOnDay;
      totalCompleted += (counts[dateStr] ?? 0);
    }

    final double monthlyRate =
        totalExpected > 0 ? (totalCompleted / totalExpected).clamp(0.0, 1.0) : 0.0;

    return {
      'month': target.month,
      'year': target.year,
      'totalDaysCalculated': limitDay,
      'totalExpected': totalExpected,
      'totalCompleted': totalCompleted,
      'monthlyRate': monthlyRate,
      'dailyLogs': counts,
    };
  }

  // 3. Hiệu suất chi tiết từng thói quen trong 30 ngày qua
  Future<List<HabitPerformance>> getHabitPerformances({int daysCount = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: daysCount - 1));
    final startStr = _dateFormat.format(startDate);
    final endStr = _dateFormat.format(now);

    final List<HabitPerformance> performances = [];

    for (var habit in _habits) {
      if (habit.id == null) continue;

      // Đếm số ngày target trong 30 ngày qua
      int targetDays = 0;
      for (int i = 0; i < daysCount; i++) {
        final d = startDate.add(Duration(days: i));
        if (habit.appliesToWeekday(d.weekday)) {
          targetDays++;
        }
      }

      final completedDays = await _db.getTotalCompletionsForHabit(
        habit.id!,
        startDate: startStr,
        endDate: endStr,
      );

      final rate = targetDays > 0 ? (completedDays / targetDays).clamp(0.0, 1.0) : 0.0;
      final streak = _streaks[habit.id!] ?? 0;

      performances.add(HabitPerformance(
        habit: habit,
        completedDays: completedDays,
        targetDays: targetDays,
        completionRate: rate,
        streak: streak,
      ));
    }

    // Sắp xếp theo tỷ lệ hoàn thành giảm dần
    performances.sort((a, b) => b.completionRate.compareTo(a.completionRate));
    return performances;
  }
}
