# UC-04 — Tạo buổi luyện và đếm giờ

Entry `main.dart` dùng SQLite journal thật. Phần giao diện UC-04 từ nhánh prototype được tích hợp với `PracticeStartService` và `PracticeTimerService` hiện tại; không dùng adapter lưu trong bộ nhớ cho entry Android.

- Tab Buổi luyện có icon + nổi ở góc dưới phải, nằm trên thanh điều hướng. Có bản nháp thì mở lại buổi đó, kể cả bản nháp thuộc hồ sơ khác.
- Setup nhập tên rồi Start; giữ UUID qua retry và chờ transaction trước khi mở timer. Không tạo bài tập, kế hoạch hoặc màn ghi buổi quá khứ.
- Timer chỉ hiển thị snapshot của service. Pause/Resume/Back/background/checkpoint dùng cùng engine app scope. Widget không giữ Timer, Stopwatch hoặc bộ đếm khác. Harness không cấp service chỉ hiển thị dữ liệu đọc.
- Ảnh vuông phía trên và tranh trung tâm đều lấy loại nhạc cụ của hồ sơ sở hữu buổi; Guitar dùng tranh gốc, các nhạc cụ khác dùng sprite và khung Tempo.
- Công cụ mở màn thẻ theo prototype với cùng session ID, không reset timer. `practiceToolOpenProvider` là port cho các task metronome/tuner/audio; khi chưa có implementation, thẻ thông báo chưa khả dụng.
- Kết thúc đóng interval và ghi Review trước khi mở form hiện có trên main. Back từ form chuyển cùng bản nháp về Paused. Lỗi checkpoint/read giữ buổi và cho thử lại.
- Save cập nhật hàng hiện có bằng session ID trong một transaction. Save cùng ID nhiều lần trả bản đã lưu đầu tiên. Thời gian đo từ checkpoint và thời gian người dùng sửa được lưu riêng. Sidecar được xóa bởi trigger trong cùng transaction.
- Save thành công mở chi tiết, cập nhật danh sách và giải phóng engine để Start buổi tiếp theo. Chi tiết không yêu cầu Kết thúc thêm lần nữa.

`PracticeReviewService` ở shared, implementation SQLite ở backend, adapter form và loader danh sách ở app. Migration v2 thêm BPM nullable, giữ nguyên migration v1 và nhật ký đang có. Nội dung đang sửa trong form chỉ được ghi khi Save; chưa có autosave từng ký tự.

Kiểm chứng: unit/widget suite, test rollback/lưu trùng/mở lại/migration v1→v2 và `integration_test/uc04_journal_smoke_test.dart` trên Android với database riêng. Bộ kiểm thử không xóa hoặc nhập dữ liệu vào database người dùng.
