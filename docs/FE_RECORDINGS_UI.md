# UC-11–13 — Danh sách, nghe lại, xuất và xóa bản ghi

Đối chiếu `views.recordings`, `renderRecordings()` và `actions['delete-clip']` trong prototype Tempo HTML. Dùng cùng font Be Vietnam Pro, sprite nhạc cụ/cuộn băng và cascade CSS: thẻ có viền, ảnh nhạc cụ 62 px, tên, thời lượng, trạng thái gắn nhật ký, thanh nghe lại và thao tác phụ xuất/xóa. Sprite dùng bộ lọc high để giữ nét khi thu nhỏ. Nút ghi mới chỉ có trong thư viện; màn bản ghi của buổi đã kết thúc không có nút này theo yêu cầu UC-11–13.

Theo điều chỉnh giao diện, tiêu đề và lời dẫn dùng cột trái, ảnh cuộn băng chiếm cột phải với kích thước theo chiều rộng màn hình, tối đa 160 px. Ảnh không đè lên chữ; danh sách cách phần mở đầu 16 px, không giữ thêm chiều cao trống. Khi tăng cỡ chữ, ảnh và nội dung xếp dọc để chữ có đủ chiều rộng. Nút **Ghi âm buổi luyện** cùng chú thích cố định ở cạnh dưới trong safe area. Danh sách cuộn trong vùng phía trên nên bản ghi cuối vẫn có thể truy cập mà không bị nút che.

Mở từ **Trang chủ → Công cụ luyện tập → Bản ghi âm**, từ Công cụ của buổi đang luyện, hoặc **Buổi luyện → Chi tiết → Bản ghi của buổi này**. Thư viện lọc theo hồ sơ hiện tại; màn chi tiết chỉ nhận bản ghi của đúng buổi. Không thêm màn công cụ hoặc điều hướng mới ngoài danh sách này.

`RecordingsPage` nhận dữ liệu và callback xóa; `PracticeSessionRecordingsPage` cập nhật số bản ghi của buổi qua `onChanged`. Dữ liệu tạm và các ID chỉ nằm trong `showcase/recordings_preview_library.dart`; xóa được giữ trong bộ nhớ để mở lại danh sách không xuất hiện lại bản vừa xóa. Quota UI của màn ghi âm dùng số lượng còn lại. Không sửa nhật ký, tệp âm thanh hay SQLite trong task này.

`RecordingsPlaybackPreview` chạy đồng hồ hiển thị và tua theo ID bản ghi, chỉ có một bản phát mỗi lúc. Đổi bản bắt đầu từ đầu; tạm dừng giữ vị trí; kết thúc hoặc tua quá cuối dừng phát; phát lại từ cuối về đầu. Bắt đầu nghe lại dừng trạng thái của công cụ khác; bắt đầu công cụ khác dừng nghe lại. Rời màn hoặc ứng dụng vào nền dừng nghe lại. Đây là trạng thái giao diện, chưa phát âm thanh thiết bị.

Xuất mở sheet **Chia sẻ bản ghi / Lưu vào tệp**. `recordingsExportProvider` nhận adapter có đích `share` hoặc `saveFile`, trả kết quả `success`, `cancelled`, `failed` hoặc `missingFile`. Hủy không báo thành công; lỗi giữ bản gốc và báo lỗi; tệp bị thiếu chuyển sang trạng thái không thể nghe/xuất nhưng vẫn xóa được. Adapter mặc định chưa nối Android; chọn đích chỉ đóng sheet và không báo xuất thành công. Backend sau này cung cấp share sheet hoặc file picker Android qua adapter này.

Xóa yêu cầu xác nhận theo hộp thoại prototype. Hủy giữ danh sách; xác nhận dừng bản đang phát trước khi xóa, cập nhật danh sách/số lượng khi callback hoàn tất và giữ nguyên nhật ký. Callback lỗi giữ bản ghi và cho thử lại. Tệp đã mất và danh sách trống có giao diện riêng.

Kiểm chứng từ `app/`:

```text
dart format --output=none --set-exit-if-changed lib/frontend/recording lib/frontend/showcase/recordings_example.dart lib/frontend/showcase/recordings_playback_preview.dart lib/frontend/showcase/recordings_preview_library.dart test/frontend/recordings_ui_test.dart integration_test/recordings_ui_smoke_test.dart
flutter analyze --no-pub
flutter test --no-pub test/frontend/recordings_ui_test.dart test/frontend/recording_ui_test.dart test/frontend/practice_session_detail_test.dart test/frontend/practice_timer_ui_test.dart test/frontend/metronome_ui_test.dart
flutter test --no-pub --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.uc1113qa integration_test/recordings_ui_smoke_test.dart integration_test/recording_ui_smoke_test.dart -d <device-id>
flutter build apk --debug --no-pub
```

Ảnh prototype và Flutter 390/460 px, màn 320 px với chữ 2× nằm trong `app/build/uc11-13-review/`, gồm danh sách, xuất, xác nhận xóa, tệp bị thiếu và danh sách trống. Kiểm tra Android xác minh giao diện và tương tác bằng dữ liệu trong bộ nhớ; phát audio thật, xuất/lưu/xóa tệp thật và quota bền vững cần adapter backend, nằm ngoài task giao diện này.
