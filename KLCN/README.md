# Ứng Dụng Kỷ Luật Cá Nhân (Habit Tracker) - Flutter

Ứng dụng di động giúp theo dõi và quản lý thói quen hàng ngày nhằm rèn luyện kỷ luật cá nhân, được xây dựng hoàn chỉnh bằng Flutter theo chuẩn Material 3.

---

## 📋 Danh Sách Tiêu Chí Hoàn Thành (Checklist 5/5 Mục)

### 1. Thiết kế giao diện người dùng
- **Màn hình danh sách thói quen (`HomeScreen` / `_HabitListTab`)**:
  - Dải chọn ngày ngang (`DateStripPicker`) với highlight ngày chọn, nút quay lại "Hôm nay".
  - Thẻ tiến độ hôm nay (`ProgressCard`) với thanh tỷ lệ %, số lượng hoàn thành và lời nhắc động viên kỷ luật.
  - Bộ lọc trạng thái: **Tất cả**, **Chưa xong**, **Đã xong**.
  - Danh sách thẻ thói quen với hiệu ứng hoàn thành trực quan, icon, màu sắc và hiển thị streak 🔥.
- **Màn hình thêm/sửa thói quen (`HabitFormScreen`)**:
  - Giao diện form nhập liệu chuẩn chỉ với validation.
  - Chọn icon trực quan (hơn 16 icon đại diện cho học tập, sức khỏe, thể thao, thiền, đọc sách...).
  - Bảng chọn màu sắc đại diện (Color palette 10 màu sắc nét).
  - Chọn thời gian nhắc nhở bằng TimePicker trực quan.
- **Màn hình thống kê tiến độ (`StatisticsScreen`)**:
  - Thanh tab chuyển đổi linh hoạt: **Hôm nay (Ngày)**, **Theo Tuần**, **Theo Tháng**.
  - Biểu đồ cột trực quan (`BarChart` từ `fl_chart`) hiển thị tỷ lệ 7 ngày gần nhất.
  - Bảng xếp hạng chi tiết hiệu suất của từng thói quen trong 30 ngày qua.

### 2. Cài đặt tính năng Thêm, Xóa, Sửa thói quen
- Thuộc tính thói quen đầy đủ theo yêu cầu:
  - **Tên thói quen** (`title`)
  - **Mô tả / Động lực rèn luyện** (`description`)
  - **Tần suất thực hiện** (`frequencyType`): Hàng ngày (`daily`) hoặc Tùy chỉnh các ngày trong tuần (`specific_days`: Thứ 2 đến Chủ nhật)
  - **Thời gian nhắc nhở** (`reminderTime`: định dạng `HH:mm`)
  - **Màu sắc & Biểu tượng** (`colorValue`, `iconCodePoint`)
  - **Thời gian tạo & Lưu trữ** (`createdAt`, `isArchived`)
- Hỗ trợ thao tác CRUD đầy đủ: Thêm mới, Cập nhật thông tin và Xác nhận xóa với Dialog cảnh báo an toàn.

### 3. Đánh dấu hoàn thành thói quen với giao diện trực quan
- Checkbox tròn animated tương tác 1 chạm ngay trên thẻ thói quen.
- Khi hoàn thành:
  - Hiệu ứng đổi màu nền sang tông màu pastel của thói quen.
  - Tên thói quen gạch ngang (`lineThrough`).
  - Icon checkmark xuất hiện với hiệu ứng phóng to / thu nhỏ mượt mà.
  - Huy hiệu Streak 🔥 cập nhật ngay lập tức số ngày liên tiếp đạt được.
  - Thanh tiến độ & vòng tròn % trên đầu màn hình nhảy số tức thì.

### 4. Lưu trữ dữ liệu với SQLite (`sqflite` & `sqflite_common_ffi`)
- Tích hợp cơ sở dữ liệu quan hệ SQLite đảm bảo **không bao giờ mất dữ liệu khi tắt ứng dụng**.
- Cấu trúc 2 bảng chuẩn hóa:
  - Bảng `habits`: Lưu trữ thông tin thói quen, cấu hình tần suất, giờ nhắc, màu sắc, icon.
  - Bảng `habit_logs`: Lưu nhật ký hoàn thành theo từng ngày (`date_string`: YYYY-MM-DD), trạng thái `is_completed`, khóa ngoại liên kết `FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE`.
- Tự động nạp sẵn dữ liệu mẫu (Sample Data) khi cài đặt ứng dụng lần đầu (Uống 2L nước, Đọc sách, Tập thể dục, Học tiếng Anh, Dậy sớm).
- Tương thích đa nền tảng: Chạy mượt mà trên cả Android, iOS và Windows/Linux Desktop.

### 5. Màn hình thống kê tỷ lệ hoàn thành theo Ngày, Tuần và Tháng
- **Theo Ngày**:
  - Tỷ lệ hoàn thành %, số lượng đã làm / tổng số mục tiêu, số lượng còn lại.
- **Theo Tuần**:
  - Biểu đồ cột 7 ngày gần nhất (`BarChart`) với các mức màu trực quan: Xanh lá (≥ 80%), Xanh dương (≥ 50%), Cam (< 50%).
  - Tỷ lệ hoàn thành trung bình tuần, tổng số lượt thực hiện.
- **Theo Tháng**:
  - Tỷ lệ kỷ luật trong tháng %, thanh tiến độ tổng thể, số lượt hoàn thành trên tổng số mục tiêu dự kiến của các ngày trong tháng.
- **Hiệu suất từng thói quen**:
  - Tỷ lệ % hoàn thành, số ngày hoàn thành / số ngày mục tiêu trong 30 ngày, streak hiện tại.

---

## 📁 Cấu Trúc Mã Nguồn

```
lib/
├── main.dart                      # Khởi tạo App, SQLite FFI, Localization & Theme M3
├── models/
│   ├── habit.dart                 # Model Habit (đầy đủ thuộc tính, toMap, fromMap)
│   └── habit_log.dart             # Model HabitLog (ghi nhận ngày & trạng thái hoàn thành)
├── services/
│   └── database_service.dart      # SQLite Database Service (CRUD, tính Streak, Thống kê)
├── providers/
│   └── habit_provider.dart        # Provider quản lý State phản ứng nhanh
├── screens/
│   ├── home_screen.dart           # Màn hình chính (Dải ngày, Thẻ tiến độ, Bộ lọc, Danh sách)
│   ├── habit_form_screen.dart     # Màn hình Thêm / Chỉnh sửa thói quen
│   ├── statistics_screen.dart     # Màn hình Thống kê Ngày, Tuần, Tháng & Biểu đồ
│   └── settings_screen.dart       # Cài đặt, Khôi phục dữ liệu mẫu & Triết lý kỷ luật
└── widgets/
    ├── date_strip_picker.dart     # Dải cuộn chọn ngày ngang
    ├── habit_card.dart            # Thẻ thói quen với hiệu ứng check hoàn thành
    └── progress_card.dart         # Thẻ tóm tắt tiến độ ngày hôm nay
```

---

## 🚀 Hướng Dẫn Chạy Ứng Dụng

1. Cài đặt các thư viện:
   ```bash
   flutter pub get
   ```

2. Chạy ứng dụng trên thiết bị Android / Giả lập hoặc Windows:
   ```bash
   flutter run
   ```

3. Chạy kiểm thử tự động (Unit Tests):
   ```bash
   flutter test
   ```
