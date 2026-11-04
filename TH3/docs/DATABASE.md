# Thiết kế cơ sở dữ liệu

SQLite schema version 1, tệp `english_th3.db`, bật `PRAGMA foreign_keys = ON` mỗi lần mở. Dùng truy vấn tham số hóa. `users` 1–N `sessions`; `settings` lưu lựa chọn toàn ứng dụng.

| Bảng | Cột | Ý nghĩa |
|---|---|---|
| users | id INTEGER PK AUTOINCREMENT | Mã hồ sơ |
| users | name TEXT NOT NULL | Tên hiển thị |
| users | goal_minutes INTEGER | Mục tiêu 1–120 phút, mặc định 5 |
| users | reminder_hour, reminder_minute INTEGER | Giờ địa phương, mặc định 20:00 |
| users | reminder_enabled INTEGER | Bật/tắt nhắc học |
| sessions | id INTEGER PK AUTOINCREMENT | Mã lượt luyện |
| sessions | user_id INTEGER FK | Tham chiếu users.id, không nhận mã không tồn tại |
| sessions | lesson_index INTEGER | Bài trong giáo trình |
| sessions | practiced_at TEXT | Thời gian ISO 8601 theo máy |
| sessions | local_day TEXT | Ngày học địa phương YYYY-MM-DD, giữ ngày lúc luyện |
| sessions | seconds INTEGER CHECK > 0 | Thời lượng phiên micro có kết quả |
| sessions | transcript, reference TEXT | Văn bản nhận dạng và câu chuẩn snapshot |
| sessions | confidence REAL NULL | Độ tin cậy nhận dạng, độc lập điểm |
| sessions | score INTEGER NULL | Điểm IPA; NULL khi không đủ dữ liệu |
| sessions | analysis_json TEXT | Cặp âm, từ chưa biết, gợi ý bài tập |
| sessions | engine TEXT | Phiên bản phương pháp dùng để tái hiện kết quả |
| settings | key TEXT PK, value TEXT | active_user: mã hồ sơ hiện tại |

Index `sessions_user_day(user_id, local_day)` hỗ trợ thống kê theo người học/ngày. Mỗi insert session lưu đồng thời điểm và phân tích trong một bản ghi nguyên tử. Không trộn dữ liệu demo vào database thật. Tổng thời gian = SUM(seconds), điểm trung bình chỉ tính score khác NULL.

Ví dụ analysis_json:

```json
{"pairs":[{"expected":"θ","heard":"t"}],"tips":["Luyện thank–tank"],"unknown":[]}
```

Trong cặp âm, `expected: null` là âm thừa; `heard: null` là âm bị thiếu. Dữ liệu nhắc học đang hoạt động được sao sang SharedPreferences Android để BroadcastReceiver có thể khôi phục lịch khi Flutter không chạy; bản SQLite giữ cấu hình riêng từng hồ sơ.
