# Kiểm thử và nghiệm thu trước nộp

## Tự động

```powershell
flutter analyze
flutter test --reporter expanded
flutter build apk --debug
```

Ngày 31/10/2026: phân tích tĩnh sạch, **16 kiểm thử đạt**:

- Giáo trình đầy đủ IPA; normalization; th/t; ship/sheep; thiếu/thừa âm; từ lạ và đầu vào rỗng; tái dựng alignment.
- Streak rỗng, trùng ngày, hôm qua, đứt chuỗi, qua tháng/năm, bỏ qua ngày tương lai.
- Hai hồ sơ không dùng chung lịch sử/mục tiêu; FK và thời lượng hợp lệ; NULL score; lưu feedback; mở lại database còn dữ liệu.
- Luồng UI chọn Luyện nói → mock speech → lưu SQLite → điểm → lịch sử → chi tiết, màn hình 430×1000.

Kiểm thử UI dùng MethodChannel giả lập, không chứng minh micro hoặc mô hình speech-to-text hoạt động trên mọi thiết bị.

Build Android debug đa kiến trúc đã thành công (`Gradle assembleDebug`, Flutter 3.47.2). APK và source ZIP được đóng gói trong thư mục `dist/`. Gradle có cảnh báo deprecated từ cấu hình/plugin Android; không gây lỗi build. Đây không thay thế các ca nghiệm thu micro, nhắc học và giọng thật dưới đây.

APK đã cài thành công lên emulator Pixel 7 qua ADB (`Success`); package `com.th3.english`, Activity `com.th3.english.MainActivity`, Android tối thiểu API 24, hỗ trợ ARM32/ARM64/x86_64. Màn hình Hôm nay đã hiển thị và database được khởi tạo. Tuy nhiên emulator hiện hộp thoại **System UI isn't responding**, nên chưa nghiệm thu được thao tác ổn định trên thiết bị; xem `screenshots/home.png`. Kiểm thử UI tự động vẫn đạt. Cần chạy lại trên thiết bị trước khi nộp, không coi việc cài thành công là nghiệm thu toàn bộ ứng dụng.

## Thử thiết bị

| Ca thử | Thao tác | Kết quả mong đợi |
|---|---|---|
| Micro | Cho quyền, nghe mẫu, đọc cả câu | Transcript, điểm/giải thích, lưu đúng hồ sơ |
| Từ chối micro | Từ chối trong hộp thoại | Thông báo lỗi, không tạo phiên hoặc tăng streak |
| Im lặng | Mở thu nhưng không nói | Báo thử lại, không treo, không lưu lượt rỗng |
| Mạng | Tắt Internet khi engine cần mạng | Báo lỗi, không có điểm giả |
| Không dịch vụ | Máy không cài speech engine | Hướng dẫn bật/cài dịch vụ |
| TTS | Nghe câu mẫu | Tiếng Anh en-US; không có giọng thì báo hướng dẫn |
| Vòng đời | Thu rồi đưa app nền | Dừng micro, quay lại không treo trạng thái thu |
| Hạn chế thao tác | Thu rồi mở tab khác | Không đổi hồ sơ/bài trong khi đang thu hoặc lưu |
| Lưu trữ | Luyện, đóng hẳn và mở lại app | Phiên, mục tiêu, hồ sơ còn nguyên |
| Notification | Bật quyền và bấm thử ngay | Hiện thông báo; chạm mở app |
| Từ chối thông báo | Bật nhắc rồi từ chối quyền | UI giữ tắt, giải thích cấp quyền |
| Nhắc theo giờ | Chọn giờ vài phút tới, đưa app nền | Nhận gần giờ đã chọn, có thể trễ do Android |
| Tắt nhắc | Tắt sau khi lập lịch | Không phát nhắc đã hủy |
| Reboot/múi giờ | Bật nhắc, reboot/đổi múi giờ | Lịch tự khôi phục theo giờ địa phương |
| Nhiều hồ sơ | Tạo A/B, học và đổi qua lại | Dữ liệu độc lập, lịch nhắc theo người đang chọn |
| Chữ lớn/màn nhỏ | Font 1.5×, xoay máy | Cuộn xem toàn bộ, không overflow |

Force-stop trong Android có thể vô hiệu hóa lịch cho tới khi người dùng mở app lại; đó không giống chỉ vuốt app khỏi recent. Quyền thông báo bị tắt ở cài đặt hệ thống có thể ngăn giao dù cấu hình ứng dụng đang bật.

## Thực nghiệm mục 7 (cần người thật)

Chưa thực hiện, không có số liệu accuracy thực tế. Dùng `voice_evaluation.csv` làm mẫu, một dòng cho mỗi lần đọc.

1. Tuyển ít nhất 5 người tự nguyện có trình độ khác nhau, giọng Việt Bắc/Trung/Nam và ít nhất một giọng tiếng Anh khác nếu có. Dùng mã ẩn danh P01…; không cần tên thật.
2. Mỗi người đọc 8 câu chuẩn, 3 lượt ở nơi yên tĩnh, rồi lặp nhóm câu th/t và ship/sheep trong môi trường có tiếng nền vừa phải. Ghi thiết bị, engine, mạng và điều kiện. Không ép người tham gia giả giọng dân tộc.
3. Giáo viên/người có chuyên môn nghe và ghi lỗi âm, chấm độc lập trước khi xem điểm app. Nếu cần lưu audio làm bằng chứng, xin đồng ý riêng và dùng công cụ ghi âm ngoài; app hiện không lưu audio.
4. Ghi transcript thực, điểm IPA, lỗi được đánh dấu và lỗi do người nghe xác nhận. Không nhập transcript nhân tạo vào số liệu giọng thật.
5. Tính WER = (thay + xóa + thêm từ) / số từ chuẩn; MAE = trung bình |điểm app − điểm người chấm|. Tính precision/recall của lỗi âm dựa trên nhãn người chấm và so sánh theo nhóm giọng, không chỉ báo trung bình tổng.
6. Báo trường hợp transcript khớp nhưng giáo viên nhận thấy lỗi âm: đây là false negative quan trọng của proxy. Phân tích chênh lệch giữa các nhóm giọng và ảnh hưởng tiếng nền/mạng.
7. Đề xuất ngưỡng nghiệm thu cùng giảng viên trước khi đo (ví dụ MAE ≤ 15 và recall lỗi ≥ 0.75). Đây là mục tiêu đánh giá, **không phải kết quả đạt sẵn**. Nếu proxy không đạt, thay bằng chấm điểm âm học chuyên dụng rồi chạy lại.

## Kịch bản demo 5 phút

1. Giới thiệu dữ liệu và 4 màn hình; đặt mục tiêu 1 phút.
2. Nghe mẫu, đọc thank you; xem máy nghe, IPA, độ tin cậy riêng với điểm.
3. Thử tank you hoặc thiếu từ; giải thích sai khác và bài luyện. Kết quả thực phụ thuộc engine, không hứa luôn nhận ra lỗi.
4. Mở lịch sử, đóng/mở app và đổi hồ sơ để chứng minh lưu trữ/độc lập.
5. Bật nhắc, thử thông báo; trình bày thuật toán, kết quả test tự động và giới hạn thực nghiệm trung thực.
