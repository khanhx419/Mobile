# Kịch bản thuyết trình KLCN

## Slide 1 Kỷ luật cá nhân với Flutter

Kính thưa thầy cô, em trình bày ứng dụng Kỷ luật cá nhân bằng Flutter. Nội dung đi theo năm tiêu chí của bài thực hành. Em phân biệt chức năng đã triển khai với các lỗi còn cần hoàn thiện, thay vì chỉ dựa vào tuyên bố trong README.

## Slide 2 Cấu trúc và luồng dữ liệu

Mã nguồn chia thành màn hình, widget, model, Provider và service. Người dùng thao tác trên màn hình, Provider gọi DatabaseService rồi thông báo thay đổi giao diện. Hai nhóm dữ liệu chính là cấu hình thói quen và nhật ký hoàn thành. Đây là phân lớp theo trách nhiệm, chưa đủ cơ sở gọi là một triển khai Clean Architecture đầy đủ.

Mở `lib/main.dart`, dòng 29–36.

## Slide 3 Checklist 1  Các màn hình chính

Mục thứ nhất đã có đủ màn hình. HomeScreen đặt danh sách, thống kê và cài đặt trong IndexedStack. Cách này giữ trạng thái tab nhưng cũng có nghĩa initState của màn hình thống kê không chạy lại mỗi lần chuyển tab. Đây là nguyên nhân cần quan tâm khi cập nhật biểu đồ.

Mở `lib/screens/home_screen.dart`, dòng 23–35.

## Slide 4 Checklist 2  Thuộc tính thói quen

Mục thứ hai có đầy đủ dữ liệu cần nhập. Model Habit lưu tên, mô tả, tần suất, danh sách ngày, giờ nhắc và ngày tạo. Tuy nhiên, thời gian nhắc hiện chỉ là thuộc tính dữ liệu. Chưa thấy dịch vụ lập lịch hoặc phát thông báo. Checklist yêu cầu thuộc tính giờ nhắc nên cần phân biệt điều này với yêu cầu nhắc thật.

Mở `lib/models/habit.dart`, dòng 4–13.

## Slide 5 CRUD và phản hồi khi lưu

Form có gọi thêm và sửa, nhưng đoạn mã này gọi Future mà không chờ. Sau đó nó báo thành công và đóng màn hình. Khi ghi SQLite thất bại, thông báo vẫn có thể nói đã lưu. Hướng sửa là chuyển hàm lưu thành async, await thao tác, bắt lỗi và chỉ báo thành công sau khi ghi xong. Đây là hướng sửa đề xuất, chưa phải code đã sửa.

Mở `lib/screens/habit_form_screen.dart`, dòng 137–149.

## Slide 6 Checklist 3  Hoàn thành theo ngày

Đánh dấu hoàn thành đã có luồng ghi thật. Provider gửi mã thói quen cùng ngày chọn xuống database, rồi cập nhật tập mã đã hoàn thành. Nhưng nó chưa kiểm tra ngày đó có nằm trước ngày tạo hoặc sau hôm nay không. Dải chọn ngày cho phép ba ngày tương lai, nên hiện có thể ghi hoàn thành trước hạn.

Mở `lib/providers/habit_provider.dart`, dòng 181–191.

## Slide 7 Streak với lịch tùy chỉnh

Streak là chức năng bổ sung ngoài checklist. Test đã cho một thói quen theo lịch thứ hai, thứ tư và thứ sáu hoàn thành ba buổi đến hạn gần nhất. Kết quả trả về một vì hàm đi lùi từng ngày rồi dừng ở ngày không có log. Nếu muốn streak theo lịch hẹn, cần bỏ qua ngày nghỉ và công bố rõ quy tắc.

Mở `lib/services/database_service.dart`, dòng 295–305.

## Slide 8 Checklist 4  Lưu bằng SQLite

Ứng dụng có SQLite thật, không chỉ lưu trên bộ nhớ của Provider. Bảng habit_logs liên kết mã thói quen và ngày, có ràng buộc duy nhất cho cặp này. Tuy nhiên, bộ test hiện tại chưa kiểm chứng tắt và mở lại ứng dụng. Không nên diễn đạt bảo đảm tuyệt đối rằng dữ liệu không bao giờ mất chỉ vì đã dùng SQLite.

Mở `lib/services/database_service.dart`, dòng 71–81.

## Slide 9 Dữ liệu mẫu và lịch sử thực tế

Trong quá trình khởi tạo, ứng dụng chèn các log của những ngày trước để biểu đồ có dữ liệu. Test trên database tạm mới xác nhận có hai mươi log trước khi người dùng thực hiện gì. Đó là dữ liệu giả lập, không phải tiến độ thật. Nên chỉ tạo trong chế độ demo có nhãn rõ và không trộn vào lịch sử sử dụng thật.

Mở `lib/services/database_service.dart`, dòng 152–163.

## Slide 10 Checklist 5  Mẫu số thống kê

Mục thứ năm chưa đạt về tính đúng. Đoạn mã tuần đếm các thói quen áp dụng cho thứ đó nhưng không xét ngày tạo. Trong database chỉ có một thói quen mới hôm nay, sáu ngày trước vẫn có mục tiêu. Ngày kiểm tra là ngày năm tháng mười một, thống kê tháng tính năm mục tiêu thay vì một. Hiệu suất ba mươi ngày cũng tính ba mươi thay vì một.

Mở `lib/providers/habit_provider.dart`, dòng 219–226.

## Slide 11 Thống kê và thời điểm làm mới

StatisticsScreen nạp ba nhóm thống kê rồi giữ trong các biến state. Lời gọi nạp ban đầu chỉ nằm trong initState, ngoài ra có nút refresh. Provider khiến build chạy lại nhưng không tự cập nhật ba kết quả đã lưu. Do tab tồn tại trong IndexedStack, chuyển tab không bảo đảm số liệu mới. Cần nối quá trình nạp lại với thay đổi dữ liệu và hoàn tất khởi tạo.

Mở `lib/screens/statistics_screen.dart`, dòng 28–40.

## Slide 12 Kết quả kiểm thử

Hai test có sẵn kiểm tra chuyển đổi model và áp dụng thứ trong tuần. Năm ca bổ sung kiểm tra danh sách trước ngày tạo, mẫu số tuần, tháng, ba mươi ngày và streak lịch tùy chỉnh. Cả năm đều thất bại theo kỳ vọng đúng, giúp tái hiện lỗi hiện tại. Các ca này dùng database tạm, không đụng dữ liệu người dùng. Bốn mươi bốn vấn đề phân tích tĩnh gồm cảnh báo và thông báo lint, không đồng nghĩa bốn mươi bốn lỗi làm ứng dụng không chạy.

## Slide 13 Thứ tự hoàn thiện ứng dụng

Em đề xuất sửa phần dữ liệu trước khi làm đẹp thêm. Trước hết cần quy tắc chung xác định một thói quen áp dụng vào ngày nào. Sau đó dùng quy tắc ấy trong danh sách, thống kê và streak. Tiếp theo sửa luồng lưu và cập nhật dữ liệu. Cuối cùng mới nghiệm thu thao tác UI, mở lại dữ liệu và thông báo nếu chức năng này thuộc phạm vi hoàn thiện.

## Slide 14 Kết luận và tài liệu nguồn

Ứng dụng đã có nền tảng theo yêu cầu nhưng chưa đủ cơ sở công bố hoàn chỉnh năm trên năm. Các đoạn code trong slide là mã hiện có, không phải bản sửa đã triển khai. Những điểm còn thiếu được xác định bằng đọc mã và các test tái hiện. Em xin kết thúc phần trình bày. Nguồn là các tệp trong KLCN, REVIEW_CHECKLIST.md và .review/checklist_audit_test.dart.