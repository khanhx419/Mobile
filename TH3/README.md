# TH3 · English Flow

Ứng dụng Flutter cho Android kết hợp thói quen học hàng ngày và luyện phát âm tiếng Anh.

## Chạy ứng dụng

Yêu cầu: Flutter 3.47.2 / Dart 3.13.2 hoặc tương thích, Android SDK, JDK phù hợp Gradle, điện thoại/emulator Android có dịch vụ Speech Recognition và giọng Text-to-speech tiếng Anh (en-US).

```powershell
cd TH3
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Bản debug phục vụ thực hành; cấu hình release hiện dùng khóa debug, cần khóa riêng khi phát hành chính thức.

Chạy `./package_submission.ps1` sau khi build để tạo `dist/TH3-source.zip` và sao chép APK vào `dist/EnglishFlow-TH3-debug.apk`. Gói mã nguồn loại cache, build output và cấu hình đường dẫn máy cục bộ.

Mở thư mục `TH3` trong VS Code hoặc `TH3/android` trong Android Studio. `android/local.properties` là cấu hình máy cục bộ, không đưa vào bài nộp; tạo lại đường dẫn `sdk.dir` và `flutter.sdk` theo máy đích. Không cần API key hoặc tài khoản trả phí.

## Tính năng

- Hôm nay: mục tiêu phút, streak theo ngày địa phương, lộ trình 8 bài và số lượt luyện.
- Luyện nói: câu tiếng Anh, nghĩa tiếng Việt, IPA, giọng mẫu en-US, micro thực qua Android SpeechRecognizer, phản hồi và bài tập sửa âm.
- Tiến độ: biểu đồ 7 ngày, tổng thời gian, điểm IPA trung bình, lịch sử và chi tiết từng lượt.
- Cá nhân: nhiều hồ sơ cục bộ độc lập, đổi mục tiêu, chọn giờ nhắc, bật/tắt và thử thông báo.
- SQLite giữ hồ sơ đang chọn, mục tiêu, lịch sử, câu chuẩn, transcript, điểm và phân tích âm vị sau khi khởi động lại ứng dụng.
- Nhắc học dùng AlarmManager, tự lập lịch lại sau reboot, thay đổi giờ/múi giờ và cập nhật app. Android 13+ xin quyền thông báo lúc người dùng bật. Lịch không chính xác tuyệt đối; hệ điều hành có thể trì hoãn.

## Thuật toán và giới hạn cần trình bày khi bảo vệ

Phương án trong checklist là **thuật toán so sánh âm vị**, kết hợp mô hình AI nhận dạng do Android cung cấp; không tự huấn luyện mô hình âm học.

1. SpeechRecognizer nhận âm thanh qua micro, trả transcript và độ tin cậy (nếu có).
2. Chuẩn hóa văn bản; tra bảng IPA Mỹ đã biên soạn cho các bài học và một số từ dễ nhầm.
3. Căn chỉnh hai dãy âm vị bằng Levenshtein, truy vết phép thay/thêm/xóa.
4. `score = round(100 × (1 − editDistance / max(số âm chuẩn, số âm suy ra)))`.
5. Hiển thị từng cặp âm, đánh dấu khác biệt và chọn bài luyện /θ, ð/, /ɪ, iː/, /ɹ, l/ theo âm cần cải thiện.

**Đây là điểm tương đồng IPA suy ra từ văn bản, không phải điểm âm học trực tiếp.** Mô hình speech-to-text có thể sửa lỗi của người nói; transcript đúng vẫn có thể phát âm sai. Điểm không đo ngữ điệu, trọng âm, độ trôi chảy hoặc mức độ giống người bản xứ. Không dùng confidence làm điểm phát âm. Từ ngoài từ điển hoặc lời nói rỗng không được chấm giả thành 0/100; UI nêu nguyên nhân. IPA không thể hiện mọi biến thể giọng hợp lệ.

Nếu giảng viên yêu cầu điểm âm vị trực tiếp từ waveform, cần thay module này bằng dịch vụ pronunciation assessment có căn chỉnh âm học hoặc mô hình forced alignment và thu thập dữ liệu đánh giá thật. Phiên bản hiện tại không tuyên bố đã đáp ứng tiêu chí âm học này.

## Dữ liệu và quy tắc tiến độ

Xem [thiết kế cơ sở dữ liệu](docs/DATABASE.md), [đối chiếu checklist](docs/CHECKLIST.md), [quy trình kiểm thử](docs/TESTING.md).

Một ngày được tính streak khi có ít nhất một phiên thu âm được nhận dạng thành công. Khi chưa luyện hôm nay, chuỗi kết thúc hôm qua vẫn được giữ đến hết ngày. Mục tiêu phút độc lập với streak; đổi mục tiêu không sửa lịch sử. Thời gian được tính từ phiên micro có kết quả, không phải thời gian chỉ mở màn hình. Biểu đồ so với mục tiêu hiện tại.

Hồ sơ cục bộ không phải tài khoản được xác thực; không có mật khẩu hoặc đồng bộ. Mỗi thiết bị có một lịch nhắc, theo hồ sơ đang chọn. Ứng dụng không lưu tệp âm thanh; dịch vụ nhận dạng Android có thể gửi âm thanh tới nhà cung cấp, tùy cài đặt và thiết bị. Gỡ ứng dụng sẽ xóa dữ liệu, backup Android đã tắt.

## Cấu trúc

| Tệp | Trách nhiệm |
|---|---|
| `lib/main.dart` | Giao diện, luồng luyện, hồ sơ và tiến độ |
| `lib/learning.dart` | Giáo trình IPA, căn chỉnh, điểm, phản hồi, streak |
| `lib/storage.dart` | SQLite, ràng buộc, truy vấn theo người học |
| `lib/platform.dart` | MethodChannel Dart ↔ Android |
| `android/app/src/main/kotlin/com/th3/english/MainActivity.kt` | Micro, quyền, SpeechRecognizer, TTS |
| `android/app/src/main/kotlin/com/th3/english/ReminderReceiver.kt` | AlarmManager, thông báo, khôi phục lịch |
| `test/` | Kiểm thử thuật toán, dữ liệu và luồng giao diện |

Tài liệu API chính thức đã đối chiếu: [SpeechRecognizer](https://developer.android.com/reference/android/speech/SpeechRecognizer), [AlarmManager](https://developer.android.com/reference/android/app/AlarmManager).
