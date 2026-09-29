# Task 10 — Kết quả kiểm chứng UI

Ngày kiểm chứng: 28/09/2026. Phạm vi là theme, thành phần dùng chung và màn mẫu FE. Hướng dẫn tích hợp: [FE_SHARED_UI.md](FE_SHARED_UI.md).

## Môi trường

- Windows, Flutter 3.47.5 stable / Dart 3.13.4.
- Android SDK compile/target 36, NDK 28.2.13676358; cấu hình mặc định của Flutter.
- Máy ảo Medium_Phone (`emulator-5554`), Android 15 / API 35, x86_64, 1080×2400, density 420.
- Dữ liệu kiểm thử giả; không nối SQLite, nhật ký, audio hoặc tài khoản.

## Kết quả

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Đạt, 31 file không cần thay đổi |
| `flutter analyze` | Đạt, không có issue |
| `flutter test` | Đạt, 22 unit/widget tests |
| `flutter test integration_test/shared_ui_smoke_test.dart -d emulator-5554` | Đạt, 1 test trên Android |
| `flutter build apk --debug -t lib/main_showcase.dart` | Đạt, tạo APK debug |
| `flutter run -d emulator-5554 -t lib/main_showcase.dart --no-resident` | Đạt, cài và khởi chạy showcase trên Android |

### Hành vi nhập và lưu

- Trường bắt buộc trống báo lỗi tại trường; trường tùy chọn cho phép bỏ trống.
- Validation kiểm tra Unicode, ký tự điều khiển, độ dài theo SRS và số nguyên trong khoảng. `80.5` không bị âm thầm chuyển thành `805`.
- Keyboard text/multiline/number được kiểm tra; Android smoke test xác nhận IME hệ thống thực sự tạo inset lớn hơn 0.
- Bấm hai lần trước rebuild chỉ gọi callback lưu/xác nhận một lần; nút hiển thị trạng thái đang xử lý và khóa trong lúc chờ Future.
- Lưu lỗi giữ tên và ghi chú, báo lỗi rõ ràng, cho phép thử lại. Android smoke test kiểm tra cả lần thử lại thành công và quay về màn trước.
- Lựa chọn bắt buộc báo lỗi khi chưa chọn; cảm xúc/tập trung bấm lại giá trị đang chọn trả `null`.
- Xóa tìm kiếm cập nhật cả controller và callback. Hộp thoại lỗi giữ mở, cho hủy sau khi thao tác kết thúc.

### Màn nhỏ, chữ lớn, safe area và bàn phím

Widget tests chạy 5 màn mẫu: home, welcome, setup, form lưu và catalog. Ma trận 320/390/460 px × text scale 1/2/3× × keyboard inset 0/300 px; safe area trên/dưới 24 px. Tổng cộng 90 cấu hình màn mẫu.

Không ghi nhận lỗi overflow trong lần dựng đầu và sau khi cuộn đến cuối. Bottom navigation được ẩn khi có keyboard inset. Dialog và bottom sheet kiểm tra riêng ở 320×640, chữ 3×, bàn phím 0/280 px; nút hủy vẫn cuộn tới và bấm được.

IME Android thật đã được mở trên form; kiểm tra tiếp thao tác lưu khi bàn phím mở và không ghi nhận exception layout.

### Đối chiếu Tempo

Tokens lấy từ cascade cuối `style.css` + `fidelity.css` của prototype. Bundle đúng Be Vietnam Pro, SVG, mood icon và PNG gốc. Đã quan sát mẫu home/welcome/setup/form bằng font thật và đối chiếu trang tham chiếu Tempo ở chiều rộng 390 px.

Chạy `flutter test test/frontend/showcase_visual_test.dart` để tạo lại ảnh QA:

- `app/build/ui-review/home-390.png`
- `app/build/ui-review/welcome-390.png`
- `app/build/ui-review/setup-390.png`
- `app/build/ui-review/form-390.png`

Đây là kiểm tra trực quan và layout; chưa có baseline golden để xác nhận trùng từng pixel. Chữ lớn có bố cục thích ứng; validation theo SRS mới thay cho quy tắc cũ của prototype.

## Phạm vi chưa kiểm chứng

- TalkBack, gesture Back và mọi bàn phím OEM chưa được kiểm tra thủ công. Form/dialog đã có semantics, live region và PopScope; vẫn cần QA trên thiết bị trước phát hành.
- Các màn là ví dụ sử dụng bộ UI, chưa phải toàn bộ 23 luồng trong HTML. Timer, audio, purchase, draft recovery và lưu trữ thuộc task tính năng.
- Chống gửi trùng đã kiểm chứng ở callback UI; tính duy nhất của bản ghi vẫn cần backend/controller bảo đảm khi nối dữ liệu thật.
- Chỉ build debug Android; chưa cấu hình ký bản phát hành.
