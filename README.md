# Mobile · Bài tập lập trình di động

Tổng hợp mã nguồn các bài tập và dự án môn học. Mỗi thư mục là một dự án độc lập; mở và chạy từ thư mục tương ứng.

| Thư mục | Nội dung |
|---|---|
| `hello_flutter/` | Bài làm quen Flutter |
| `portfolio/` | Ứng dụng portfolio Android |
| `QLTLHT/` | Quản lý tài liệu học tập với Flutter, Firebase và Supabase |
| `Cashew/` | Dự án quản lý chi tiêu tùy biến từ Cashew; ứng dụng trong `budget/` |
| `Daily_You/` | Nhật Ký Việt, bản Việt hóa và tùy biến từ Daily You |
| `TH2/` | Thư mục bài thực hành 2 hiện chưa có mã nguồn |
| `TH3/` | English Flow: thói quen học tiếng Anh và đối chiếu phát âm |

## Chạy các dự án Flutter

Trong `hello_flutter`, `QLTLHT`, `Daily_You`, `TH3`, hoặc `Cashew/budget`:

```sh
flutter pub get
flutter run
```

Xem README của từng dự án để biết phiên bản Flutter, cấu hình dịch vụ và các chế độ chạy riêng. `portfolio/` mở bằng Android Studio hoặc dùng Gradle wrapper. Tạo lại `local.properties` theo Android SDK trên máy; cache, build output, APK, khóa ký và cấu hình máy cá nhân không nằm trong repo.

Cấu hình Firebase trong bản công khai dùng giá trị `CONFIGURE_YOUR_FIREBASE_PROJECT`. Trước khi dùng tính năng cloud của QLTLHT/Cashew, tạo cấu hình Firebase của bạn: cập nhật `firebase_options.dart`, cấu hình web nếu có, và thêm `google-services.json`/`GoogleService-Info.plist` trên máy. Các tệp cấu hình nền tảng và `.envrc` được loại khỏi repo; cấu hình gốc trong các dự án trên máy không bị sửa.

Các thư mục được lưu dưới dạng mã nguồn đầy đủ, không phải Git submodule. Dùng Flutter SDK cài trên máy; bản Flutter SDK lồng trong dự án không được đưa vào repo tổng hợp.

## Giấy phép và nguồn gốc

Giữ nguyên LICENSE, tác giả và thông báo bản quyền trong từng dự án. Cashew và Daily You là các bản tùy biến dựa trên phần mềm nguồn mở, không tuyên bố toàn bộ mã nguồn thuộc tác giả bài tập. Xem README và LICENSE của từng thư mục để biết nguồn gốc và điều kiện sử dụng.

## Kiểm thử TH3

TH3 có tài liệu thiết kế dữ liệu, đối chiếu checklist và quy trình kiểm thử trong `TH3/docs/`. Điểm IPA của bản hiện tại suy ra từ transcript nhận dạng; thực nghiệm nhiều người và nhiều giọng thật chưa hoàn tất. Xem `TH3/docs/TESTING.md` trước khi nộp bài.
