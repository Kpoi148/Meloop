# UC-09 — Giao diện kiểm tra cao độ

Task 29, phạm vi frontend Android. Bố cục lấy từ `views.tuner` và cascade cuối của `style.css` / `fidelity.css` trong prototype Tempo HTML: hai nhãn khoảng nốt và tần số tham chiếu, tranh máy cao độ 275 px trong vùng 270 px, thẻ nốt lớn, tần số/sai lệch, thước −50…+50 cent và kim vàng. Dùng nguyên sprite `tools-v2.png`, icon và font Be Vietnam Pro đang có. Bổ sung trạng thái tín hiệu, quyền và giới hạn nhận từng nốt theo UC-09.

Mở từ **Trang chủ → Công cụ luyện tập → Kiểm tra cao độ** hoặc **Buổi luyện → Công cụ luyện tập → Kiểm tra cao độ**. Back trên thanh tiêu đề và Back Android chờ service dừng rồi trả về đúng thẻ công cụ đã mở; Back tiếp trở về Trang chủ/buổi luyện. Timer và session ID không bị sửa bởi màn cao độ. Nút Trang chủ dừng nghe và dùng hành vi hiện có của buổi luyện: tạm dừng timer, giữ draft và thời gian.

## Contract và tích hợp backend

`shared/pitch/pitch_service.dart` định nghĩa `PitchService`, `PitchSnapshot`, `PitchReading` và `PitchConfiguration`. App cấp implementation qua `pitchServiceProvider` trong `frontend/pitch/pitch_route.dart`. `PitchPage` chỉ nhận snapshot/callback; không phân tích audio, xin quyền qua SDK, ghi file hay truy cập journal. Service cung cấp khoảng nốt, tần số tham chiếu, tên nốt, Hz, cent và phân loại thấp/đúng/cao. Widget không tự đặt ngưỡng phân loại. Cấu hình mặc định chuẩn nằm trong `PitchConfiguration.standard`; implementation có thể thay bằng cấu hình runtime.

`PitchController` quản lý vòng đời cho một route: chỉ Start sau thao tác Bật micro, Stop khi Back/Home/background/dispose, bỏ event đến muộn và gọi Stop lại khi Start đang chờ quyền hoàn tất muộn. `PitchService.stop()` phải idempotent, hủy Start đang chờ và hoàn tất sau khi đã giải phóng micro. Service phải báo denied/blocked, không đủ tín hiệu, công cụ audio đang bận và lỗi qua snapshot; không ghi âm hay truyền âm thanh ra mạng.

`PitchSnapshot.reading` chỉ có giá trị khi trạng thái detected và dữ liệu hợp lệ. Listening, weakSignal và mọi trạng thái đã dừng đều hiển thị dấu trống và không có kim đo. Lỗi Stop xóa kết quả, giữ đường thử dừng lại và không báo micro đã tắt thành công. Route chỉ rời đi sau khi dừng thành công. Khi app ở paused/hidden/detached, Stop chạy ngay; resume không tự nghe lại. `inactive` riêng lẻ không hủy yêu cầu quyền Android đang hiển thị.

Denied cho phép xin lại quyền; blocked hướng dẫn vào **Cài đặt Android, Ứng dụng, Meloop, Quyền, Micro** và có nút Mở cài đặt gọi `PitchService.openAppSettings()`. Nếu không mở được, giữ hướng dẫn thao tác thủ công. Cả hai trạng thái cho phép Back và giữ nguyên buổi luyện, không khóa nhật ký.

**Chưa có implementation đo cao độ/micro Android trong repository.** Provider mặc định là `null`: Bật micro báo chưa khả dụng, không hiển thị nốt giả hay trạng thái đang đo giả. `frontend/showcase/pitch_preview_service.dart` chỉ dùng để duyệt giao diện và test, không được cài vào ứng dụng nhật ký. Việc xin quyền thật, mở Android Settings thật, phân tích nốt và phân xử micro với công cụ khác cần backend triển khai contract trước khi nghiệm thu tính năng audio đầy đủ.

## Kiểm chứng

Ngày 03/10/2026: `flutter analyze --no-pub` không có issue; 74 controller/widget/hồi quy test đều qua. Android smoke test qua trên emulator Android 15 / API 35, build APK debug thành công với app ID `.uc09qa`.

Kiểm thử controller/widget bao phủ nghe/nhận nốt/tín hiệu yếu, cả ba hướng sai lệch, xóa kết quả và kim khi dừng, event muộn, Stop khi Start đang chờ quyền, lỗi Start/Stop/settings, route bị dispose, background/resume, denied/blocked và điều hướng từ Home/buổi luyện. Test buổi luyện dùng timer thật với store giả, kiểm tra giữ session ID và thời gian, Back vẫn Running, Home thành Paused. Kiểm thử hồi quy gồm metronome, ghi âm, timer, lưu journal thật và component dùng chung.

Ảnh Flutter 390/460 px và màn 320 px với chữ 2× sinh trong `app/build/uc09-review/`. Android smoke test dùng service xem thử và gói `.uc09qa`, không truy cập dữ liệu của app người dùng. Ảnh Android sinh trong `app/build/ui-review/uc09-*.png`. Smoke test xác minh rendering và callback; không phải kiểm chứng thu micro hoặc mở Settings thật.

Chạy tại `app/`:

```text
flutter analyze --no-pub
flutter test --no-pub test/frontend/pitch_controller_test.dart test/frontend/pitch_ui_test.dart test/frontend/metronome_ui_test.dart test/frontend/recording_ui_test.dart test/frontend/practice_timer_ui_test.dart test/frontend/journal_practice_save_flow_test.dart test/frontend/components
flutter drive --no-pub --no-start-paused --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.uc09qa --driver test_driver/uc04_journal_driver.dart --target integration_test/pitch_ui_smoke_test.dart -d <device-id>
```

Trên Windows, hook SQLite của bộ test hiện có cần đường dẫn SDK không có khoảng trắng. Kiểm chứng dùng ánh xạ ổ đĩa tạm tới SDK, không thay dependency hoặc bỏ kiểm tra.
