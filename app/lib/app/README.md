# App shell

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. Truyền các override vào app để cấp dependency; `main_showcase.dart` cấp callback lưu giả riêng, `main.dart` không cài dependency giả. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).
