# Đối chiếu yêu cầu TH3

Không đánh dấu hoàn tất kiểm thử thực nghiệm khi chưa có người tham gia. Checklist tham khảo của môn học là chỉ đọc; bảng này chỉ là tài liệu trong dự án.

| # | Yêu cầu | Triển khai và minh chứng | Trạng thái |
|---|---|---|---|
| 1 | CSDL người dùng, lịch sử, kết quả | SQLite users/sessions/settings, FK, index; test phân tách hồ sơ và mở lại DB | Đã triển khai, test tự động |
| 2 | Streak, thời gian, mục tiêu | Dashboard + 7 ngày, mục tiêu riêng từng hồ sơ, streak theo lịch, không nhân đôi ngày | Đã triển khai, test biên ngày/tháng/năm |
| 3 | API speech recognition, thu âm | Android SpeechRecognizer en-US, quyền micro runtime, lỗi mạng/im lặng/không dịch vụ, timeout và dọn vòng đời | Đã triển khai; cần thử micro người thật |
| 4 | AI hoặc so sánh âm vị | AI speech-to-text Android + IPA Levenshtein có truy vết, điểm 0–100, từ lạ không chấm | Đã triển khai thuật toán; chỉ là proxy transcript, chưa kiểm chứng độ chính xác âm học |
| 5 | Điểm, đánh dấu âm sai, bài cải thiện | Chip từng âm chuẩn→âm suy ra; bài luyện th, nguyên âm, r/l; lưu phản hồi | Đã triển khai; sai khác là suy luận, cần nghe xác nhận |
| 6 | Nhắc học và UI tiến độ | AlarmManager, quyền notification, khôi phục boot/timezone, 4 tab, hồ sơ/mục tiêu/biểu đồ | Đã triển khai; cần kiểm tra giao thông báo trên thiết bị |
| 7 | Nhiều người dùng, nhiều giọng, độ chính xác AI | Test tự động nhiều hồ sơ và các transcript giả lập; có ma trận, CSV và tiêu chí đánh giá thật | **Chưa hoàn tất thực nghiệm nhiều người/giọng** |

Không coi mock transcript hoặc unit test là bằng chứng mô hình nhận đúng các giọng. Xem TESTING.md để thực hiện mục 7 trước khi nộp.
