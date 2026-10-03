# UC-10 — Giao diện ghi âm trong buổi luyện

Đối chiếu `views.recorder`, `restoreRecordReview()` và cascade cuối của `style.css` / `fidelity.css` trong prototype Tempo HTML. Dùng nguyên sprite micro và icon, font Be Vietnam Pro, bố cục tiêu đề buổi/nhạc cụ, tranh micro, sóng âm, bộ đếm, nút ghi/dừng, thẻ nghe lại, xác nhận bỏ và nút giữ. Giới hạn hiển thị của Free theo UC-10 là 5 phút mỗi tệp và 10 tệp; khác giới hạn 10 phút trong bản HTML.

Mở từ **Buổi luyện → Công cụ luyện tập → Ghi âm** hoặc **Trang chủ → Công cụ luyện tập → Ghi âm**. Khi chưa có buổi luyện, `RecordingEmptyPage` hiển thị đúng nhánh không có draft của prototype: tiêu đề, tranh micro, thẻ giới thiệu và nút **Tạo buổi luyện** mở luồng tạo buổi hiện có. Hủy tạo trở về màn này; bắt đầu xong chuyển đến bộ đếm. Khi đã có buổi luyện, màn ghi âm dùng đúng session ID và trạng thái của buổi đó. `RecordingPage` chỉ nhận snapshot và callback; không có plugin audio, quyền micro Android, file storage, database hay purchase mới. `RecordingPreviewInputs` và `RecordingPreviewController` trong `frontend/showcase/` cấp dữ liệu tạm và điều khiển các trạng thái để xem giao diện. Các bản giữ chỉ nằm trong bộ nhớ, không được nhập vào journal hoặc danh sách audio thật. Backend sau này thay nguồn quota/micro và callback bằng dữ liệu runtime.

Trạng thái ghi thuộc session ID hiện tại. Quay lại dừng ghi và giữ phần nghe lại để mở lại cùng buổi. Pause/Finish/background dừng ghi; Resume không tự ghi tiếp. Lỗi ghi không gọi Resume của bộ đếm. Buổi Paused/Review/Saved không bắt đầu bản mới. Đạt 5 phút chuyển sang nghe lại, giữ/bỏ; đủ 10 tệp chặn bản mới và hiển thị lý do. Lỗi giữ giữ nguyên bản đang nghe lại để thử lại. Từ chối/không có micro, thiếu dung lượng và xung đột công cụ có thông báo; không chặn form lưu nhật ký.

**Chi tiết buổi luyện → Bản ghi của buổi này** mở màn `PracticeSessionRecordingsPage` theo `views.recordings`: tranh cuộn băng, tiêu đề và lời dẫn, khung trống nét đứt, nút ghi âm và chú thích. Danh sách và thao tác nghe/xuất/xóa vẫn dùng dữ liệu và callback có sẵn. Nút **Ghi âm buổi luyện** mở cùng lối ghi âm của Trang chủ, dùng buổi đang luyện hoặc màn chưa có buổi; không truyền ID buổi đã lưu sang ghi âm. Quay lại trở về chi tiết; Trang chủ đóng các màn đang mở và chọn tab Trang chủ.

Quota, trạng thái micro, thời lượng và lỗi được truyền vào UI. Không có chữ giải thích dữ liệu thử trên màn hình. Lối Xem Meloop Pro mở sheet thông tin ngay tại đây, có nút tiếp tục luyện tập; không mở màn mua hàng hay chức năng ngoài UC-10.

Kiểm chứng từ `app/`:

```text
flutter analyze --no-pub
flutter test --no-pub test/frontend/recording_ui_test.dart test/frontend/practice_timer_ui_test.dart test/frontend/metronome_ui_test.dart test/frontend/journal_practice_save_flow_test.dart test/frontend/practice_session_detail_test.dart
flutter drive --no-pub --no-start-paused --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.uc10qa --driver test_driver/uc04_journal_driver.dart --target integration_test/recording_ui_smoke_test.dart -d <device-id>
```

Ảnh đối chiếu Flutter 390/460 px, màn 320 px với chữ 2× nằm trong `app/build/uc10-review/`; ảnh Android của driver nằm trong `app/build/ui-review/uc10-*.png`. Package Android QA riêng không gỡ app người dùng. Kiểm tra này xác minh giao diện và trạng thái tạm; thu/phát micro thật, lưu tệp an toàn và quota bền vững thuộc phần backend chưa được nối ở task UI này.
