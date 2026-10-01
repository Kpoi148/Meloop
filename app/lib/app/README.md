# App shell

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`journal_providers.dart` cấp một `JournalDatabaseOwner` lazy cho mỗi ProviderScope, clock/UUID, các reader journal và settings store. Opener có thể override để test trên file riêng; scope đóng owner sau các thao tác đã nhận. Profile preview vẫn dùng database riêng và không nhập dữ liệu hoặc quyền Pro thử vào journal.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. `main.dart` gọi `runProfilePreviewApp()` để khởi tạo luồng hồ sơ và bộ lưu thử cục bộ. `InstrumentProfilePreview` cấp callback lưu buổi luyện mẫu trong scope theo hồ sơ; nhật ký nghiệp vụ chưa được nối. Truyền các override vào app để cấp dependency thật khi backend bàn giao. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).
