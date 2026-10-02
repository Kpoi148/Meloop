# UC-04 — Tạo buổi luyện và đếm giờ

Entry `main.dart` dùng SQLite journal thật. Phần giao diện UC-04 từ nhánh prototype được tích hợp với `PracticeStartService` và `PracticeTimerService` hiện tại; không dùng adapter lưu trong bộ nhớ cho entry Android.

- Tab Buổi luyện có icon + nổi ở góc dưới phải, nằm trên thanh điều hướng. Có bản nháp của hồ sơ đang chọn thì mở lại buổi đó; hồ sơ khác có thể tạo buổi riêng.
- Setup nhập tên rồi Start; giữ UUID qua retry và chờ transaction trước khi mở timer. Không tạo bài tập, kế hoạch hoặc màn ghi buổi quá khứ.
- Timer chỉ hiển thị snapshot đúng session/profile của service. Pause/Resume/Back/background/checkpoint dùng cùng engine app scope. Đổi hồ sơ ghi checkpoint và tạm dừng buổi cũ trước khi nạp buổi mới. Widget không giữ Timer, Stopwatch hoặc bộ đếm khác. Harness không cấp service chỉ hiển thị dữ liệu đọc.
- Ảnh vuông phía trên và tranh trung tâm đều lấy loại nhạc cụ của hồ sơ sở hữu buổi; Guitar dùng tranh gốc, các nhạc cụ khác dùng sprite và khung Tempo.
- Công cụ mở màn thẻ theo prototype với cùng session ID, không reset timer. `practiceToolOpenProvider` là port cho các task metronome/tuner/audio; khi chưa có implementation, thẻ thông báo chưa khả dụng.
- Kết thúc đóng interval và ghi Review trước khi mở form hiện có trên main. Back từ form chuyển cùng bản nháp về Paused. Lỗi checkpoint/read giữ buổi và cho thử lại.
- Save cập nhật hàng hiện có bằng session ID trong một transaction. Save cùng ID nhiều lần trả bản đã lưu đầu tiên. Thời gian đo từ checkpoint và thời gian người dùng sửa được lưu riêng. Sidecar được xóa bởi trigger trong cùng transaction.
- Save thành công mở chi tiết bằng bản đã lưu, làm mới đúng hồ sơ sở hữu buổi và giải phóng engine để Start buổi tiếp theo. Tìm kiếm/bộ lọc cũ của hồ sơ đó được xóa để buổi mới luôn hiển thị khi quay lại tab Buổi luyện, kể cả đã chọn nhạc cụ khác giữa buổi. Nút Trang chủ trên chi tiết sau lưu về tab Trang chủ. Chi tiết không yêu cầu Kết thúc thêm lần nữa.

`PracticeReviewService` ở shared, implementation SQLite ở backend, adapter form và loader danh sách ở app. Migration v2 thêm BPM nullable; v3 thay giới hạn một draft toàn app bằng một draft mỗi hồ sơ và tối đa một buổi Running. Giữ nguyên migration cũ, session ID, checkpoint, review input, BPM và liên kết bản ghi. Bootstrap chỉ nạp draft của hồ sơ đang chọn; các buổi khác vẫn nằm trong SQLite, không cộng thời gian chờ hoặc đóng app. Nội dung đang sửa trong form chỉ được ghi khi Save; chưa có autosave từng ký tự.

Màn chi tiết dùng đúng font/asset và bố cục `views.session` của Tempo: ngày/tên/nhạc cụ/thời lượng, tranh theo nhạc cụ, cặp cảm xúc/tập trung, ghi chú, thẻ vàng cho lần tiếp theo, bản ghi và hai nút cuối cùng. Hai nút cùng chiều cao; chữ lớn hoặc màn hẹp chuyển sang bố cục dọc.

Kiểm chứng: unit/widget suite, test rollback/lưu trùng/mở lại/migration v1→v2; `test/frontend/journal_practice_save_flow_test.dart` kiểm tra danh sách có thẻ đã lưu, tìm kiếm cũ, đổi hồ sơ giữa buổi và mở app lại bằng SQLite thật. Ảnh Guitar/Sáo sau lưu xuất vào `app/build/ui-review/` (không commit).

`test/frontend/profile_practice_drafts_test.dart` và `integration_test/profile_practice_drafts_smoke_test.dart` dùng cùng hành trình Guitar → tạm dừng → tạo Sáo → mở lại app → lưu Sáo → quay lại Guitar → tiếp tục/lưu. Kiểm tra hai ID riêng, checkpoint không đổi khi chờ, tranh đúng nhạc cụ, danh sách riêng và đúng một bản lưu mỗi hồ sơ. Test database kiểm tra nâng cấp v2→v3 giữ dữ liệu; test timer kiểm tra lỗi ghi khi chuyển buổi vẫn giữ thời gian RAM để Retry.

Chạy Android QA từ `app/` bằng package riêng để trình chạy integration không gỡ app người dùng:

```powershell
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/uc04_journal_smoke_test.dart -d <device-id>
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/profile_practice_drafts_smoke_test.dart -d <device-id>
```

Build QA dùng `com.meloop.meloop.qa` và database kiểm thử riêng; driver giữ ảnh bộ đếm, chi tiết sau lưu và danh sách trong `build/ui-review/`. Build thông thường qua `lib/main.dart` giữ package `com.meloop.meloop`; cài cập nhật để giữ dữ liệu đang có.
