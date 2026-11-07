# Khắc phục microphone khi chạy Android Studio

## Android Emulator

1. Khởi động AVD. Mở Extended Controls (dấu ba chấm) → Microphone.
2. Bật **Enable Host Microphone Access**, hoặc **Virtual microphone uses host audio input** tùy phiên bản Emulator. Tùy chọn này có thể bị tắt lại sau khi khởi động giả lập.
3. Windows Settings → Privacy & security → Microphone: bật quyền truy cập microphone và quyền cho desktop apps. Kiểm tra đúng thiết bị đầu vào tại System → Sound → Input.
4. Trong TH3 → Luyện nói → Bắt đầu thu âm, cấp quyền micro. Chờ “Micro đã sẵn sàng” rồi đọc câu tiếng Anh. Android tự phát hiện kết thúc câu; nút “Kết thúc câu” yêu cầu trả kết quả sớm hơn. Khi “Đang nhận dạng lời nói”, chờ kết quả hoặc hủy.
5. Nếu báo thiếu dịch vụ nhận dạng, dùng AVD có Google Play và cài/cập nhật Speech Recognition & Synthesis của Google, kết nối Internet.

Có thể bật chuyển tiếp mic bằng terminal sau khi giả lập khởi động:

```powershell
adb -s emulator-5554 emu avd hostmicon
```

Không cần bật các tùy chọn mô phỏng headset để thu qua microphone máy tính.

## Điện thoại thật

Cấp quyền microphone cho English Flow trong Settings → Apps → Permissions; bật Internet và dịch vụ nhận dạng tiếng Anh. Chạy lại đầy đủ ứng dụng sau khi sửa Kotlin; hot reload không cập nhật mã Android.

## Bản sửa

- Giao diện phân biệt đang mở mic, mic sẵn sàng và đang chờ nhận dạng; không báo đang nghe trước callback onReadyForSpeech.
- Chỉ gọi stopListening khi mic sẵn sàng, vẫn chờ onResults/onError; có thể hủy phiên đang mở/chờ kết quả.
- Bỏ qua callback trễ của phiên cũ; hủy và giải phóng recognizer khi kết thúc/lỗi.
- Giới hạn chờ nhận dạng sau khi kết thúc lời nói là 15 giây.
- Kiểm thử Flutter mô phỏng các trạng thái và việc lưu kết quả. Những kiểm thử này không thay thế việc nói thật vào mic trên thiết bị.

Nguồn: https://developer.android.com/studio/releases/emulator và https://developer.android.com/reference/android/speech/SpeechRecognizer
