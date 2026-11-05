# Báo cáo ứng dụng kỷ luật cá nhân với Flutter

Ngày tổng hợp 05/11/2026. Báo cáo phân tích mã nguồn KLCN theo năm tiêu chí của đề bài. Ứng dụng có bộ khung giao diện và SQLite, nhưng công thức thống kê và một số luồng ghi dữ liệu cần hoàn thiện. Không tuyên bố đã nghiệm thu trên thiết bị.

## Công nghệ và kiến trúc

Flutter và Dart xây dựng giao diện. Provider cung cấp trạng thái cho các màn hình. HabitProvider gọi DatabaseService để thực hiện thao tác SQLite. Model Habit lưu cấu hình và HabitLog lưu nhật ký theo ngày. Các widget như HabitCard, DateStripPicker và ProgressCard tái sử dụng thành phần giao diện. SQLite là nơi lưu chính, không suy ra chức năng lưu trữ chỉ từ dependency SharedPreferences.

## Phân tích theo slide và mã nguồn

### 2 Cấu trúc và luồng dữ liệu

- screens và widgets: giao diện, thao tác người dùng
- HabitProvider: trạng thái, lọc ngày, thống kê
- DatabaseService: truy vấn SQLite
- models: Habit và HabitLog

Nguồn `lib/main.dart`, dòng 29–36. Trích đoạn hiện trạng.

```dart
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => HabitProvider()..init(),
    child: MaterialApp(
      title: 'Kỷ Luật Cá Nhân',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
```

### 3 Checklist 1  Các màn hình chính

- Có danh sách thói quen, form thêm sửa và màn hình thống kê
- IndexedStack giữ các tab tồn tại khi chuyển màn hình
- Cần cập nhật số liệu cache khi dữ liệu thay đổi

Nguồn `lib/screens/home_screen.dart`, dòng 23–35. Trích đoạn hiện trạng.

```dart
final List<Widget> _screens = const [
  _HabitListTab(),
  StatisticsScreen(),
  SettingsScreen(),
];

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: IndexedStack(
      index: _currentNavigationIndex,
      children: _screens,
    ),
```

### 4 Checklist 2  Thuộc tính thói quen

- Tên, mô tả, tần suất và các ngày thực hiện
- Giờ nhắc, màu sắc, biểu tượng và ngày tạo
- Giờ nhắc hiện mới được lưu và hiển thị

Nguồn `lib/models/habit.dart`, dòng 4–13. Trích đoạn hiện trạng.

```dart
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
```

### 5 CRUD và phản hồi khi lưu

- Form gọi addHabit hoặc updateHabit
- Thiếu await và xử lý lỗi trước khi báo thành công
- Cần khóa nút trong lúc lưu để tránh thao tác trùng

Nguồn `lib/screens/habit_form_screen.dart`, dòng 137–149. Trích đoạn hiện trạng.

```dart
if (widget.habit == null) {
  provider.addHabit(habitData);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã thêm thói quen mới thành công!')),
  );
} else {
  provider.updateHabit(habitData);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã cập nhật thói quen thành công!')),
  );
}

Navigator.pop(context);
```

### 6 Checklist 3  Hoàn thành theo ngày

- Log nhận mã thói quen và ngày đang chọn
- UI đổi trạng thái sau kết quả từ SQLite
- Cần kiểm tra ngày tạo và chặn hoàn thành tương lai

Nguồn `lib/providers/habit_provider.dart`, dòng 181–191. Trích đoạn hiện trạng.

```dart
Future<void> toggleHabitCompletion(int habitId) async {
  final isDone = await _db.toggleHabitCompletion(habitId, selectedDateString);
  if (isDone) {
    _completedHabitIds.add(habitId);
  } else {
    _completedHabitIds.remove(habitId);
  }

  // Cập nhật lại streak của habit này
  _streaks[habitId] = await _db.getStreakForHabit(habitId);

```

### 7 Streak với lịch tùy chỉnh

- Hàm hiện đi lùi từng ngày lịch
- Ngày nghỉ làm đứt chuỗi dù không có buổi đến hạn
- Ca thứ 2, 4, 6: kỳ vọng 3 buổi, thực tế trả về 1

Nguồn `lib/services/database_service.dart`, dòng 295–305. Trích đoạn hiện trạng.

```dart
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
```

### 8 Checklist 4  Lưu bằng SQLite

- habits lưu cấu hình thói quen
- habit_logs lưu trạng thái hoàn thành từng ngày
- UNIQUE hạn chế trùng cặp thói quen và ngày

Nguồn `lib/services/database_service.dart`, dòng 71–81. Trích đoạn hiện trạng.

```dart
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

```

### 9 Dữ liệu mẫu và lịch sử thực tế

- Database mới tự tạo 20 log hoàn thành
- Lịch sử giả đi vào cùng bảng với dữ liệu người dùng
- Nên tách chế độ demo và khởi đầu lịch sử thật rỗng

Nguồn `lib/services/database_service.dart`, dòng 152–163. Trích đoạn hiện trạng.

```dart
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
```

### 10 Checklist 5  Mẫu số thống kê

- Ngày, tuần, tháng và hiệu suất đều có giao diện
- Công thức chỉ xét thứ, chưa xét createdAt
- Thói quen mới bị tính cả những ngày trước khi bắt đầu

Nguồn `lib/providers/habit_provider.dart`, dòng 219–226. Trích đoạn hiện trạng.

```dart
final date = anchor.subtract(Duration(days: i));
final dateStr = _dateFormat.format(date);
final weekday = date.weekday;

// Tính tổng số habit áp dụng cho thứ đó
final total = _habits.where((h) => h.appliesToWeekday(weekday)).length;
final completed = counts[dateStr] ?? 0;
final rate = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
```

### 11 Thống kê và thời điểm làm mới

- Kết quả tuần, tháng và hiệu suất nằm trong state riêng
- Provider thông báo thay đổi chưa tính lại các biến này
- Có nút refresh nhưng chưa tự đồng bộ sau CRUD hoặc check

Nguồn `lib/screens/statistics_screen.dart`, dòng 28–40. Trích đoạn hiện trạng.

```dart
Future<void> _loadStats() async {
  setState(() => _isLoading = true);
  final provider = Provider.of<HabitProvider>(context, listen: false);

  final weekly = await provider.getWeeklyStats();
  final monthly = await provider.getMonthlyStats();
  final perf = await provider.getHabitPerformances();

  if (mounted) {
    setState(() {
      _weeklyStats = weekly;
      _monthlyStats = monthly;
      _performances = perf;
```

### 12 Kết quả kiểm thử

- 2 test có sẵn đều đạt, chỉ kiểm tra model
- 5 ca hồi quy bổ sung đều tái hiện lỗi
- Phân tích tĩnh báo 44 vấn đề
- Chưa nghiệm thu UI hoặc thông báo trên điện thoại

### 13 Thứ tự hoàn thiện ứng dụng

- 1. Quy tắc ngày bắt đầu và lịch áp dụng
- 2. Công thức và cập nhật thống kê
- 3. Await, xử lý lỗi và khóa thao tác lưu
- 4. Tách dữ liệu demo, ngày tương lai và streak
- 5. Kiểm thử lưu trữ, UI và nhắc thật nếu cần

### 14 Kết luận và tài liệu nguồn

- Có bộ khung cho cả 5 mục checklist
- Thống kê và độ tin cậy dữ liệu còn cần sửa
- Mã minh họa lấy nguyên văn theo dòng nguồn
- Báo cáo và lời nói dùng cùng thứ tự với bộ slide

## Phát hiện và nghiệm thu chi tiết


Ngày kiểm tra: 05/11/2026. Phạm vi: đọc mã nguồn, phân tích tĩnh và chạy kiểm thử bằng database tạm. Chưa nghiệm thu giao diện trên điện thoại hoặc kiểm chứng thông báo thực tế. Không chỉnh sửa mã ứng dụng trong `lib/`.

## Đối chiếu năm yêu cầu

| Yêu cầu | Kết quả |
|---|---|
| Danh sách, thêm/sửa và thống kê | Có đủ màn hình và điều hướng. Phần thống kê tuần/tháng lưu cache có thể không cập nhật sau thao tác. |
| CRUD, tên, mô tả, tần suất và giờ nhắc | Có model, form và SQLite CRUD. Form thông báo thành công trước khi Future ghi dữ liệu hoàn tất. Giờ nhắc mới được lưu/hiển thị, chưa có hệ thống notification. Checklist chỉ yêu cầu thuộc tính giờ nhắc nên không tự động coi thiếu notification là trượt riêng mục này. |
| Đánh dấu hoàn thành theo ngày | Có UI và log theo ngày. Chưa chặn ngày trước khi tạo thói quen hoặc ngày tương lai. |
| SQLite hoặc SharedPreferences | Có SQLite thật, hai bảng và UNIQUE(habit_id,date_string). Bộ test hiện có chưa kiểm tra lưu rồi mở lại database. |
| Tỷ lệ ngày, tuần, tháng | Có UI và công thức, nhưng mẫu số bỏ qua ngày tạo, lịch hiện tại áp dụng ngược lịch sử và cache số liệu chưa đồng bộ. Chưa đủ cơ sở ghi hoàn tất 5/5. |

## Những vấn đề cần sửa

### P1 Thống kê tính cả những ngày trước khi tạo thói quen

`lib/providers/habit_provider.dart`: `habitsForSelectedDate` dòng 62, tổng ngày dòng 78, tuần dòng 224, tháng dòng 269, hiệu suất dòng 304.

Các phép lọc chỉ xét thứ trong tuần và không xét `createdAt`. Khi database chỉ có một thói quen hằng ngày vừa tạo hôm nay:

- Chọn hôm qua vẫn thấy thói quen.
- Sáu ngày trước trong biểu đồ tuần đều có một mục tiêu thay vì không có.
- Ngày 05/11, thống kê tháng tính 5 lượt kỳ vọng thay vì 1.
- Hiệu suất 30 ngày tính 30 ngày mục tiêu thay vì 1.

Cần một quy tắc áp dụng theo ngày đầy đủ, tối thiểu gồm ngày bắt đầu và lịch trong tuần, rồi dùng chung cho danh sách và mọi công thức. Khi cho phép sửa lịch, cần quyết định ngày có hiệu lực để tránh thay đổi toàn bộ lịch sử.

### P1 Biểu đồ tuần tháng và hiệu suất không tự nạp lại khi dữ liệu đổi

`lib/screens/home_screen.dart` dòng 32 dùng IndexedStack giữ màn hình thống kê tồn tại. `lib/screens/statistics_screen.dart` dòng 23 chỉ gọi `_loadStats` khi init; dòng 38–40 giữ `_weeklyStats`, `_monthlyStats`, `_performances` trong state.

Provider thay đổi làm build lại nhưng không tính lại các biến cache. Đánh dấu, thêm hoặc xóa thói quen rồi mở tab thống kê có thể vẫn thấy kết quả cũ cho tới khi bấm refresh. Màn hình thống kê còn khởi tạo cùng lúc với quá trình Provider nạp database nên có nguy cơ giữ kết quả ban đầu chưa đầy đủ.

Cần gắn dữ liệu thống kê với phiên bản thay đổi của Provider hoặc chủ động nạp lại sau khi init/CRUD/check hoàn tất. Tránh gọi tác vụ bất đồng bộ liên tục trong build.

### P1 Form báo thành công trước khi lưu xong

`lib/screens/habit_form_screen.dart` dòng 109 và 137–149; thao tác xóa tại dòng 169–177.

`_saveHabit` là void, gọi addHabit/updateHabit mà không await, rồi hiện thành công và đóng màn hình. Nếu SQLite lỗi, người dùng vẫn nhận thông báo đã lưu; bấm nhanh nhiều lần cũng có thể tạo nhiều bản ghi. Luồng xóa cũng bỏ qua Future.

Cần await, try/catch, trạng thái đang lưu và chỉ đóng màn hình/báo thành công sau khi ghi dữ liệu thành công.

### P2 Database mới có lịch sử hoàn thành giả

`lib/services/database_service.dart` dòng 83 và 152–163.

Khởi tạo database tự chèn 20 log hoàn thành của các ngày trước, dù người dùng chưa dùng ứng dụng. Chế độ reset cũng chèn lại. Một số log tạo cho cả ngày ngoài lịch của thói quen mẫu, trong khi thống kê đếm mọi log hoàn thành nên có thể tăng số lượt không hợp lệ.

Dữ liệu demo nên nằm trong chế độ riêng có nhãn rõ ràng. Database sử dụng thật bắt đầu không có lịch sử hoàn thành.

### P2 Streak đếm ngày lịch thay vì các buổi đến hạn

`lib/services/database_service.dart` dòng 268–303.

Hàm đi lùi từng ngày và dừng ngay khi không có log, không đọc tần suất thói quen. Với thói quen thứ 2–4–6, hoàn thành cả ba buổi gần nhất vẫn không được tính chuỗi 3 buổi do ngày nghỉ chen giữa. Đây là lỗi so với cách hiểu streak theo lịch đến hạn; cần công bố quy tắc nếu chủ ý dùng chuỗi ngày lịch.

### P2 Cho phép hoàn thành tương lai

`lib/widgets/date_strip_picker.dart` dòng 21 tạo thêm ba ngày tương lai. `lib/screens/home_screen.dart` dòng 227–229 vẫn gọi toggle. `HabitProvider.toggleHabitCompletion` và DatabaseService không kiểm tra ngày hợp lệ.

Nên cho phép xem kế hoạch tương lai nhưng vô hiệu hóa đánh dấu hoàn thành trước ngày đó. Quy tắc cho phép chỉnh quá khứ cần nêu rõ.

### Phần chưa triển khai nếu muốn nhắc thật

`reminderTime` chỉ có trong model, database, form và thẻ hiển thị. Không thấy service notification, lập lịch hoặc khôi phục lịch sau reboot. Nếu yêu cầu ứng dụng thực sự nhắc học/làm thói quen, phải bổ sung phần này cùng xử lý sửa/xóa lịch và quyền hệ điều hành. Không đánh đồng việc chọn giờ bằng TimePicker với phát thông báo.

## Kết quả kiểm tra

- `dart analyze lib test`: 44 vấn đề, gồm cảnh báo và thông báo lint/API cũ. Có cảnh báo IconData dùng codePoint không hằng, cần xem xét trước khi build release có tree shaking icon.
- `flutter test --no-pub --reporter expanded`: 2 test có sẵn đều đạt. Chúng chỉ kiểm tra serialize Habit và áp dụng thứ trong tuần.
- `flutter test --no-pub .review/checklist_audit_test.dart --reporter expanded`: 5 ca hồi quy đều thất bại trên code hiện tại, tái hiện danh sách trước ngày tạo, mẫu số tuần, tháng, 30 ngày và streak theo lịch thứ 2–4–6.
- Các test bổ sung dùng thư mục database tạm riêng, không truy cập hoặc xóa database người dùng.

## Thứ tự xử lý đề xuất

1. Thống nhất quy tắc ngày bắt đầu và lịch áp dụng, sửa công thức thống kê.
2. Cập nhật thống kê khi dữ liệu thay đổi và sau khi khởi tạo hoàn tất.
3. Sửa await và xử lý lỗi lưu/xóa, khóa thao tác trùng.
4. Tách dữ liệu demo, chặn hoàn thành tương lai và thống nhất cách đếm streak.
5. Bổ sung nhắc thật nếu thuộc phạm vi bài; chạy test CRUD, mở lại database và kiểm thử UI.

Đánh giá: đã có bộ khung chức năng theo đề, nhưng chưa đủ chất lượng để coi là ứng dụng hoàn chỉnh chỉ dựa vào tuyên bố README 5/5.

## Tài liệu đối chiếu

Mã nguồn trong thư mục KLCN, pubspec.yaml, lib/, test/widget_test.dart và .review/checklist_audit_test.dart. Các kết quả kiểm thử dựa trên lần rà soát ngày 05/11/2026. Xem KICH_BAN_THUYET_TRINH.md để có lời nói tương ứng từng slide.
