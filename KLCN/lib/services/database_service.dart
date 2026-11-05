import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('personal_discipline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Khởi tạo ffi cho Windows/Linux/macOS desktop nếu cần
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = filePath;
    } else if (Platform.isWindows || Platform.isLinux) {
      final appDocDir = await getApplicationDocumentsDirectory();
      path = join(appDocDir.path, 'KLCN', filePath);
      final dir = Directory(dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Bảng thói quen
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        frequency_type TEXT NOT NULL,
        selected_days TEXT,
        reminder_time TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Bảng nhật ký hoàn thành thói quen
    await db.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date_string TEXT NOT NULL,
        is_completed INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
        UNIQUE (habit_id, date_string)
      )
    ''');

    // Thêm các thói quen mẫu khởi đầu
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    final sampleHabits = [
      {
        'title': 'Uống 2L nước mỗi ngày',
        'description': 'Bổ sung nước đều đặn để thanh lọc cơ thể và tăng năng lượng',
        'frequency_type': 'daily',
        'selected_days': '1,2,3,4,5,6,7',
        'reminder_time': '07:00',
        'color_value': 0xFF0288D1, // Light Blue
        'icon_code_point': 0xe798, // local_drink
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'Đọc sách 20 phút',
        'description': 'Đọc ít nhất 10-15 trang sách phát triển bản thân',
        'frequency_type': 'daily',
        'selected_days': '1,2,3,4,5,6,7',
        'reminder_time': '21:30',
        'color_value': 0xFF7B1FA2, // Purple
        'icon_code_point': 0xe3e0, // menu_book
        'created_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'Tập thể dục / Chạy bộ',
        'description': 'Vận động thể thao 30 phút rèn luyện sức bền',
        'frequency_type': 'specific_days',
        'selected_days': '1,3,5,6', // T2, T4, T6, T7
        'reminder_time': '06:00',
        'color_value': 0xFFE64A19, // Deep Orange
        'icon_code_point': 0xe28d, // fitness_center
        'created_at': now.subtract(const Duration(days: 14)).toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'Học từ vựng tiếng Anh',
        'description': 'Ôn tập 10 từ vựng và ngữ pháp mới',
        'frequency_type': 'daily',
        'selected_days': '1,2,3,4,5,6,7',
        'reminder_time': '20:00',
        'color_value': 0xFF388E3C, // Green
        'icon_code_point': 0xe59c, // school
        'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
        'is_archived': 0,
      },
      {
        'title': 'Dậy sớm trước 6:00 AM',
        'description': 'Khởi đầu ngày mới tràn đầy năng lượng và tích cực',
        'frequency_type': 'specific_days',
        'selected_days': '1,2,3,4,5', // T2 đến T6
        'reminder_time': '06:00',
        'color_value': 0xFFF57C00, // Amber / Orange
        'icon_code_point': 0xe053, // alarm
        'created_at': now.subtract(const Duration(days: 20)).toIso8601String(),
        'is_archived': 0,
      },
    ];

    for (var h in sampleHabits) {
      final habitId = await db.insert('habits', h);

      // Thêm vài log hoàn thành cho những ngày trước để có sẵn dữ liệu thống kê trực quan
      for (int i = 1; i <= 6; i++) {
        final pastDate = now.subtract(Duration(days: i));
        final dateStr = dateFormat.format(pastDate);

        // Giả lập hoàn thành ngẫu nhiên 70-80% để biểu đồ có dữ liệu thật đẹp
        if ((habitId + i) % 3 != 0) {
          await db.insert('habit_logs', {
            'habit_id': habitId,
            'date_string': dateStr,
            'is_completed': 1,
            'completed_at': pastDate.toIso8601String(),
          });
        }
      }
    }
  }

  // ================= HABITS CRUD =================

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (includeArchived) {
      maps = await db.query('habits', orderBy: 'id DESC');
    } else {
      maps = await db.query('habits',
          where: 'is_archived = ?', whereArgs: [0], orderBy: 'id DESC');
    }
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<Habit?> getHabitById(int id) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Habit.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(int id) async {
    final db = await database;
    // Xóa cả logs liên quan
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ================= HABIT LOGS & COMPLETION =================

  // Đánh dấu hoặc hủy đánh dấu hoàn thành một thói quen trong ngày
  Future<bool> toggleHabitCompletion(int habitId, String dateString) async {
    final db = await database;
    final existing = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date_string = ?',
      whereArgs: [habitId, dateString],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final currentCompleted = (existing.first['is_completed'] as int? ?? 1) == 1;
      final newCompleted = !currentCompleted;
      await db.update(
        'habit_logs',
        {
          'is_completed': newCompleted ? 1 : 0,
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return newCompleted;
    } else {
      await db.insert('habit_logs', {
        'habit_id': habitId,
        'date_string': dateString,
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  // Lấy danh sách ID các habit đã hoàn thành trong ngày
  Future<Set<int>> getCompletedHabitIdsForDate(String dateString) async {
    final db = await database;
    final maps = await db.query(
      'habit_logs',
      columns: ['habit_id'],
      where: 'date_string = ? AND is_completed = 1',
      whereArgs: [dateString],
    );
    return maps.map((m) => m['habit_id'] as int).toSet();
  }

  // Tính Streak (chuỗi ngày liên tục hoàn thành thói quen tính đến hôm nay)
  Future<int> getStreakForHabit(int habitId) async {
    final db = await database;
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // Lấy tất cả các ngày hoàn thành theo thứ tự giảm dần
    final maps = await db.query(
      'habit_logs',
      columns: ['date_string'],
      where: 'habit_id = ? AND is_completed = 1',
      whereArgs: [habitId],
      orderBy: 'date_string DESC',
    );

    if (maps.isEmpty) return 0;

    final completedDates = maps.map((m) => m['date_string'] as String).toSet();

    int streak = 0;
    DateTime checkDate = now;

    // Nếu hôm nay chưa check, kiểm tra từ hôm qua xem streak có còn giữ không
    final todayStr = dateFormat.format(checkDate);
    if (!completedDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = dateFormat.format(checkDate);
      if (completedDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Lấy số lượng log hoàn thành trong một khoảng ngày
  Future<Map<String, int>> getCompletedCountsByDate(
      String startDate, String endDate) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT date_string, COUNT(*) as count
      FROM habit_logs
      WHERE date_string >= ? AND date_string <= ? AND is_completed = 1
      GROUP BY date_string
    ''', [startDate, endDate]);

    final Map<String, int> counts = {};
    for (var row in results) {
      counts[row['date_string'] as String] = row['count'] as int;
    }
    return counts;
  }

  // Lấy chi tiết lịch sử hoàn thành của một thói quen
  Future<int> getTotalCompletionsForHabit(int habitId,
      {String? startDate, String? endDate}) async {
    final db = await database;
    String where = 'habit_id = ? AND is_completed = 1';
    List<dynamic> args = [habitId];

    if (startDate != null && endDate != null) {
      where += ' AND date_string >= ? AND date_string <= ?';
      args.addAll([startDate, endDate]);
    }

    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM habit_logs WHERE $where',
      args,
    );
    return results.first['count'] as int? ?? 0;
  }

  // Xóa toàn bộ dữ liệu (reset)
  Future<void> resetAllData() async {
    final db = await database;
    await db.delete('habit_logs');
    await db.delete('habits');
    await _insertSampleData(db);
  }
}
