# Kết quả kiểm tra bản Việt hóa

Ngày kiểm tra: 26/10/2026. Môi trường: Windows, Flutter 3.47.2, Dart 3.13.2.

## Phần đã hoàn tất

- Cài thư viện từ `pubspec.lock`, giữ nguyên phiên bản gốc; thêm `web` là dependency trực tiếp để xuất tệp trên trình duyệt.
- Rà soát đủ 297 thông điệp tiếng Việt, kiểm tra khóa và tham số ICU so với bản tiếng Anh. Giữ tên định dạng, thương hiệu của ứng dụng nhập dữ liệu và ký hiệu kỹ thuật.
- Đặt tiếng Việt làm mặc định, thống nhất lựa chọn ngôn ngữ cho giao diện và nội dung khởi tạo của nguồn Android.
- Bổ sung bản Flutter Web riêng tại `lib/main_web.dart`, dùng chung mô hình Entry và tài nguyên bản dịch với dự án gốc.
- Đổi tên bản sửa đổi thành Nhật Ký Việt, giữ ghi công Demizo và cộng đồng cùng giấy phép GPL.

## Kiểm tra đã chạy

- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub test/web_journal_test.dart test/vietnamese_localization_test.dart test/utils/attachment_file_name_test.dart`: **18 kiểm thử đạt**.
- Kiểm tra tự động: khóa bản dịch/ICU, mặc định tiếng Việt trên thiết bị tiếng Anh, tạo/sửa/xóa, tìm kiếm, tải lại dữ liệu đã lưu, xuất/đọc JSON, từ chối bản sao lưu sai, giữ bản nháp khi lưu thất bại, điều hướng và bố cục rộng 320 px.
- `flutter build web --target lib/main_web.dart --no-pub --no-web-resources-cdn`: build thành công; kết quả ở `build/web`.
- Máy chủ HTTP tại `http://localhost:8080` trả về 200. Đã mở trang chủ và trình soạn thảo trong trình duyệt để kiểm tra tiếng Việt và bố cục thực tế. Đã tải tệp sao lưu JSON từ mục Cài đặt và xác nhận nội dung định dạng hợp lệ.

## Phạm vi và giới hạn

- Bản web lưu trong bộ nhớ trình duyệt theo origin (giao thức, tên máy, cổng). Chưa mã hóa nhật ký bằng mật khẩu; chưa có đồng bộ hoặc tài khoản máy chủ. Cần tải bản sao lưu JSON định kỳ.
- Bản sao lưu web bao gồm ảnh, nhãn và tâm trạng, có định dạng riêng; chưa chuyển đổi trực tiếp SQLite/ZIP từ Android. Kiểm thử khôi phục chạy trên dữ liệu và lưu trữ giả lập; chưa kiểm tra thủ công hộp thoại chọn tệp của mọi trình duyệt.
- Ảnh giới hạn 3 ảnh/nhật ký, tối đa 1,5 MB/ảnh; tổng dung lượng phụ thuộc hạn mức của trình duyệt. Video, ghi âm, sinh trắc học, nhắc nhở nền và đồng bộ thư mục Android chưa có trên web.
- Bộ kiểm thử gốc đã chạy trên Windows trước khi chuyển trọng tâm sang web: lần chạy tuần tự có 492 kiểm thử đạt và 17 lỗi. Phần lớn lỗi ở bước dọn tệp tạm (Windows báo tệp đang được sử dụng), cùng lỗi xử lý dấu phân cách tên tệp; lỗi tên tệp và đường dẫn đã được sửa và kiểm tra riêng. Không tuyên bố toàn bộ bộ kiểm thử Android đã đạt.
- Build Android lần đầu gặp lệch JVM target Java 17/Kotlin 25; đã thêm cấu hình Kotlin target 17 cho các module cục bộ. Việc build Android và máy ảo đã dừng theo yêu cầu người dùng, nên không xác nhận APK hoàn tất hoặc các chức năng thiết bị đã chạy thực tế.
- Workflow `Vietnamese Web` sẽ phân tích, kiểm thử và xuất artifact web khi push; kết quả CI chưa được tính là đã đạt cho đến khi GitHub chạy xong.
