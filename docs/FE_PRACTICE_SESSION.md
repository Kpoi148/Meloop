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

`PracticeReviewService` ở shared, implementation SQLite ở backend, adapter form và loader danh sách ở app. Migration v2 thêm BPM nullable; v3 thay giới hạn một draft toàn app bằng một draft mỗi hồ sơ và tối đa một buổi Running. Giữ nguyên migration cũ, session ID, checkpoint, review input, BPM và liên kết bản ghi. Bootstrap chỉ nạp draft của hồ sơ đang chọn; các buổi khác vẫn nằm trong SQLite, không cộng thời gian chờ hoặc đóng app. Review ghi snapshot input thô vào sidecar khi người dùng sửa; việc ghi được tuần tự hóa, giữ snapshot mới nhất và có Retry khi lỗi.

Màn chi tiết dùng đúng font/asset và bố cục `views.session` của Tempo: ngày/tên/nhạc cụ/thời lượng, tranh theo nhạc cụ, cặp cảm xúc/tập trung, ghi chú, thẻ vàng cho lần tiếp theo, bản ghi và hai nút cuối cùng. Hai nút cùng chiều cao; chữ lớn hoặc màn hẹp chuyển sang bố cục dọc.

Kiểm chứng: unit/widget suite, test rollback/lưu trùng/mở lại/migration v1→v2; `test/frontend/journal_practice_save_flow_test.dart` kiểm tra danh sách có thẻ đã lưu, tìm kiếm cũ, đổi hồ sơ giữa buổi và mở app lại bằng SQLite thật. Ảnh Guitar/Sáo sau lưu xuất vào `app/build/ui-review/` (không commit).

`test/frontend/profile_practice_drafts_test.dart` và `integration_test/profile_practice_drafts_smoke_test.dart` dùng cùng hành trình Guitar → tạm dừng → tạo Sáo → mở lại app → lưu Sáo → quay lại Guitar → tiếp tục/lưu. Kiểm tra hai ID riêng, checkpoint không đổi khi chờ, tranh đúng nhạc cụ, danh sách riêng và đúng một bản lưu mỗi hồ sơ. Test database kiểm tra nâng cấp v2→v3 giữ dữ liệu; test timer kiểm tra lỗi ghi khi chuyển buổi vẫn giữ thời gian RAM để Retry.

Chạy Android QA từ `app/` bằng package riêng để trình chạy integration không gỡ app người dùng:

```powershell
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/uc04_journal_smoke_test.dart -d <device-id>
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/profile_practice_drafts_smoke_test.dart -d <device-id>
```

Build QA dùng `com.meloop.meloop.qa` và database kiểm thử riêng; driver giữ ảnh bộ đếm, chi tiết sau lưu và danh sách trong `build/ui-review/`. Build thông thường qua `lib/main.dart` giữ package `com.meloop.meloop`; cài cập nhật để giữ dữ liệu đang có.

Nút Xóa buổi luyện trên chi tiết đã nối `PracticeSessionDeleteService` SQLite thật. Hủy/Android Back giữ buổi; xác nhận thành công làm mới danh sách và tổng số/thời gian ở Trang chủ, quay về tab Buổi luyện. Lỗi giữ hộp xác nhận và cho Thử lại; khóa thao tác khi đang ghi. Chỉ xóa buổi đã lưu của đúng owner; bản ghi âm vẫn giữ riêng theo `actions['delete-session']` của prototype. Buổi đã xóa không xuất hiện lại sau mở app. Đây là xóa nhật ký đã lưu, không phải thao tác hủy buổi chưa lưu của task 17.

`test/frontend/journal_saved_session_delete_test.dart` và `integration_test/saved_session_delete_smoke_test.dart` dùng cùng hành trình với app injection/SQLite thật: hủy, Android Back, lỗi transaction, retry/bấm trùng, cập nhật history/Home, giữ audio và draft hồ sơ khác, cold entry. Android chạy package `.qa` và database UUID riêng bằng driver trên, thay target thành `integration_test/saved_session_delete_smoke_test.dart`.

## Task 19 — Form lưu và sửa buổi luyện UC-04/05

Form chung hiển thị tên/ngày/thời lượng bắt buộc, nhạc cụ chỉ đọc, ba ghi chú và hai đánh giá tùy chọn. Thời lượng dùng số nguyên giờ/phút/giây (0–24/0–59/0–59), tổng từ 1 giây đến 24 giờ; giữ đúng giây đo được, không làm tròn thành phút. Tiêu đề tối đa 100 code point và ghi chú tối đa 2.000 code point có bộ đếm/lỗi tại trường; không cắt mất nội dung quá dài. Ngày chỉ chọn bằng lịch, từ 2000-01-01 đến hôm nay. Ghi chú giữ xuống dòng, toàn khoảng trắng thành chuỗi rỗng; đánh giá chưa chọn hoặc bấm lại giá trị đang chọn lưu SQL null.

Review giữ cả input chưa hợp lệ trong `review_input_json`, kể cả chuỗi giờ/phút/giây và BPM. Đọc được sidecar cũ chưa có BPM mà không đổi migration. Quay lại có lựa chọn tiếp tục sửa hoặc trở về buổi luyện và giữ input; chờ ghi nháp xong trước khi rời/lưu. Lỗi ghi giữ form và chỉ rõ snapshot mới nhất chưa được giữ, cho Thử lại. Mở lại app và mở Review lần nữa phục hồi các trường từ sidecar.

Edit gọi `PracticeSessionUpdateService`, chỉ update buổi Saved của đúng hồ sơ trong một transaction; không tạo session/draft hoặc đổi nhạc cụ, thời gian đo gốc, metadata khởi tạo và liên kết audio. Form không có thao tác ghi âm. Back/Trang chủ khi có sửa hỏi tiếp tục sửa hoặc bỏ thay đổi; bản đã commit chỉ thay đổi khi Save thành công. Save khóa gửi trùng, lỗi giữ input, thành công quay lại chi tiết và invalidates danh sách/Home. Thống kê cộng giây trước khi định dạng và chỉ tính ngày có ít nhất một buổi từ 60 giây; sửa từ 60 xuống 30 giây bỏ đóng góp ngày đó nếu không có buổi khác đủ điều kiện.

Kiểm chứng task 19: `session_form_ui_test.dart`, `session_form_srs_test.dart`, `practice_session_summary_test.dart`, `practice_review_test.dart`, `practice_session_update_test.dart`; `journal_session_form_test.dart` và `integration_test/session_form_smoke_test.dart` dùng chung hành trình SQLite thật Review → giữ input sai → mở lại app → Save → Edit lỗi → Retry → cập nhật history. Android dùng lệnh QA ở trên với target `integration_test/session_form_smoke_test.dart`; ảnh Review, Edit lỗi và chi tiết sau sửa nằm ở `build/ui-review/task19-*.png`.
