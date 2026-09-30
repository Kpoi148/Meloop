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

## Theme và UI Tempo (task 10)

Project Flutter Android đã được khởi tạo. Mở bộ mẫu bằng `flutter run -t lib/main_showcase.dart` trong `app/`. Entry point mặc định chỉ có màn chào, chờ nối controller tính năng; dữ liệu mẫu chỉ thuộc showcase và không được ghi vào storage.

Hướng dẫn tokens, component, ví dụ cho Wei và kiểm chứng: [`../docs/FE_SHARED_UI.md`](../docs/FE_SHARED_UI.md). Import từ `package:meloop/frontend/components/meloop_ui.dart`.

## Riverpod cho frontend

`MeloopApp` khởi tạo `ProviderScope`; controller quản lý tab/tìm kiếm showcase và trạng thái lưu form. App cấp dependency qua `overrides`, showcase dùng bộ xử lý giả riêng. Callback `onSave` của component vẫn được hỗ trợ. Hướng dẫn nối backend sau và kiểm thử: [`../docs/FE_RIVERPOD.md`](../docs/FE_RIVERPOD.md).

## SQLite journal

`JournalDatabase.open()` tại `lib/backend/database/` cung cấp schema v1 gồm 9 bảng cục bộ, không seed. DB chưa được nối vào entry point hoặc form. Android backup tự động đã được tắt; thanh toán để giai đoạn sau. Xem [`../docs/DB_MIGRATION_PLAN.md`](../docs/DB_MIGRATION_PLAN.md).

## Xem thử màn hồ sơ nhạc cụ

Chạy `flutter run -t lib/main_profile_preview.dart` để dùng các màn chọn, tạo, đổi tên và xóa hồ sơ theo Tempo. Dữ liệu xem thử chỉ ở bộ nhớ, không phải service lưu trữ. Cách nối service hồ sơ cục bộ và phạm vi kiểm chứng nằm trong [`../docs/FE_INSTRUMENT_PROFILES.md`](../docs/FE_INSTRUMENT_PROFILES.md).
