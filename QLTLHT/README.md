# HỆ THỐNG QUẢN LÝ TÀI LIỆU HỌC TẬP ĐA NỀN TẢNG (QLTLHT)
### Nâng cấp Tích Hợp Hệ Sinh Thái Cloud: Flutter • Firebase • Supabase
**Kiến trúc kết hợp: Local-First (Cashew Pattern) & Cloud RBAC Multi-User**

Ứng dụng **Quản lý Tài liệu Học tập (QLTLHT)** được phát triển và nâng cấp nhằm phục vụ nhu cầu lưu trữ, phân loại, tìm kiếm, lưu trữ tệp tin vật lý trên đám mây và chia sẻ tài liệu an toàn giữa nhiều người dùng với cơ chế phân quyền truy cập nghiêm ngặt.

---

## 🌟 ĐẶC ĐIỂM NỔI BẬT & CÁC TÍNH NĂNG ĐÃ NÂNG CẤP (CHECKLIST 6 MỤC)

### 1. Xác thực Người dùng với Firebase Authentication & Google Sign-In
- Tích hợp đăng nhập Google bằng `firebase_auth` & `google_sign_in`.
- Quản lý hồ sơ người dùng đa tài khoản, lưu vết UID, Email, Display Name, Photo URL.
- **Tính năng đặc biệt phục vụ chấm bài / Demo**: Tích hợp **Test Account Switcher** trực quan ngay trên AppBar & Cài đặt, cho phép chuyển đổi tức thì giữa 4 tài khoản kiểm thử:
  - 👤 **Alice (Owner)**: `alice.owner@student.edu.vn` (Chủ sở hữu)
  - 👤 **Bob (Viewer)**: `bob.viewer@student.edu.vn` (Người chỉ có quyền xem)
  - 👤 **Charlie (Editor)**: `charlie.editor@student.edu.vn` (Người được cấp quyền chỉnh sửa)
  - 👤 **Dave (Unauthorized)**: `dave.stranger@student.edu.vn` (Người lạ không có quyền)

### 2. Lưu trữ Tệp tin Vật lý trên Firebase Storage
- Cấu trúc thư mục chuẩn hóa: `documents/{userId}/{documentId}/{fileName}`.
- Tích hợp bộ chọn tệp đa định dạng `file_picker` (PDF, DOCX, XLSX, PPTX, hình ảnh,...).
- Tải tệp lên Firebase Storage, lấy `downloadUrl` và `storagePath`, liên kết trực tiếp vào siêu dữ liệu bảng `documents` trên Supabase.

### 3. Thiết kế CSDL Quan hệ trên Supabase
- Thiết kế hệ thống bảng quan hệ chuẩn hóa 3NF:
  - `users`: Quản lý người dùng đồng bộ từ Firebase Auth UID.
  - `documents`: Quản lý thông tin tài liệu, chủ sở hữu `owner_id`, liên kết Firebase Storage URL và `storage_path`.
  - `document_permissions`: Quản lý phân quyền chi tiết theo từng tài liệu (`permission_level`: `'view'`, `'edit'`, `'admin'`).
- Tệp định nghĩa DDL và RLS hoàn chỉnh: [**`supabase_schema_rls.sql`**](file:///c:/Users/Admin/Desktop/code/android/QLTLHT/supabase_schema_rls.sql).

### 4. Tìm kiếm, Cập nhật & Chia sẻ Tài liệu An toàn
- **Tìm kiếm & Bộ lọc đa tiêu chí**: Tìm kiếm toàn văn (tiêu đề, mô tả, từ khóa, tên file), lọc theo môn học, định dạng file, trạng thái hoàn thành.
- **Bộ lọc phân quyền**: Phân loại rõ ràng 3 chế độ xem: `Tất cả tài liệu`, `Tài liệu của tôi (My Documents)`, `Được chia sẻ với tôi (Shared with Me)`.
- **Hộp thoại Chia sẻ tài liệu (Share Dialog)**:
  - Nhập email hoặc chọn nhanh từ danh sách tài khoản hệ thống.
  - Chọn cấp quyền: `Chỉ xem (Viewer)` hoặc `Chỉnh sửa (Editor)`.
  - Thay đổi cấp độ quyền hoặc thu hồi quyền truy cập (Revoke) theo thời gian thực.

### 5. Chính sách Bảo mật Row Level Security (RLS) trên Supabase
- Kích hoạt RLS trên cả 3 bảng `users`, `documents`, `document_permissions`.
- **Chính sách SELECT**: Chỉ chủ sở hữu hoặc người được cấp quyền trong `document_permissions` mới đọc được tài liệu.
- **Chính sách INSERT**: Người dùng chỉ được tạo tài liệu với quyền sở hữu cá nhân (`owner_id = current_user`).
- **Chính sách UPDATE**: Chỉ chủ sở hữu hoặc người có quyền `edit` / `admin` mới được sửa thông tin tài liệu.
- **Chính sách DELETE**: CHỈ DUY NHẤT chủ sở hữu (`owner_id`) mới có quyền xóa tài liệu.
- **Chính sách Permissions**: Chỉ chủ sở hữu mới có quyền cấp, sửa hoặc thu hồi quyền chia sẻ.

### 6. Kiểm thử Tự động (Testing) Toàn diện với 3 Tài khoản Người dùng
- Bộ kiểm thử tự động gồm **32 test cases** bao phủ toàn bộ luồng hoạt động:
  - `test/cloud_permission_flow_test.dart` (12 tests chuyên sâu về Google Auth, Firebase Storage và RBAC/RLS giữa Alice, Bob, Charlie, Dave).
  - `test/document_dao_test.dart` (Persistence SQLite).
  - `test/document_repository_test.dart` (Domain Logic).
  - `test/document_provider_test.dart` (State Management).
  - `test/backup_service_test.dart` (JSON Snapshots).
  - `test/widget_test.dart` (Presentation Widgets).

---

## 🧪 KẾT QUẢ KIỂM THỬ TỰ ĐỘNG

Chạy lệnh kiểm thử toàn bộ hệ thống:
```bash
flutter test
```

Kết quả:
```text
00:02 +32: All tests passed!
```

---

## 🚀 HƯỚNG DẪN KHỞI CHẠY ỨNG DỤNG

1. **Cài đặt các gói phụ thuộc**:
   ```bash
   flutter pub get
   ```

2. **Khởi chạy ứng dụng**:
   ```bash
   # Chạy trên Windows Desktop:
   flutter run -d windows

   # Chạy trên Android Emulator hoặc thiết bị thật:
   flutter run -d android

   # Chạy trên Web:
   flutter run -d chrome
   ```

3. **Thiết lập Supabase (Tùy chọn khi triển khai Cloud Live)**:
   - Đăng nhập vào [Supabase Dashboard](https://supabase.com).
   - Mở **SQL Editor**, dán toàn bộ nội dung file [**`supabase_schema_rls.sql`**](file:///c:/Users/Admin/Desktop/code/android/QLTLHT/supabase_schema_rls.sql) và nhấn **Run**.
   - Cập nhật URL và Anon Key trong file [**`lib/core/config/supabase_config.dart`**](file:///c:/Users/Admin/Desktop/code/android/QLTLHT/lib/core/config/supabase_config.dart).

---

## 📑 BÁO CÁO GIẢI TRÌNH KIẾN TRÚC CHI TIẾT
- 📄 [**BAO_CAO_NANG_CAP_CLOUD_QLTLHT.md**](file:///c:/Users/Admin/Desktop/code/android/QLTLHT/BAO_CAO_NANG_CAP_CLOUD_QLTLHT.md): Báo cáo chi tiết về việc nâng cấp Cloud, phân quyền RBAC và kịch bản kiểm thử 3 tài khoản.
- 📄 [**BAO_CAO_KIEN_TRUC_QLTLHT.md**](file:///c:/Users/Admin/Desktop/code/android/QLTLHT/BAO_CAO_KIEN_TRUC_QLTLHT.md): Báo cáo kiến trúc Local-First Cashew nền tảng.
