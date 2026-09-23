# Meloop Android app

Đây là project Flutter chính của Meloop. Frontend và backend đều chạy trong cùng process ứng dụng Android.

- `lib/main.dart`: điểm khởi chạy ứng dụng.
- `lib/app/`: khởi tạo app và kết nối dependency.
- `lib/frontend/`: màn hình, widget, UI state và theme.
- `lib/backend/`: nghiệp vụ, SQLite, file cục bộ và audio.
- `lib/shared/`: model và contract dùng chung.
- `android/`: mã cấu hình nền tảng Android.
- `assets/`: tài nguyên được bundle vào app.
- `test/`: unit test và widget test.
- `integration_test/`: kiểm thử luồng trên emulator hoặc thiết bị Android.

Không tạo HTTP API giữa frontend và backend. Frontend gọi backend qua contract Dart.
