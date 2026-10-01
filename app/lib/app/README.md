# App shell

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`journal_providers.dart` cấp một `JournalDatabaseOwner` lazy cho mỗi ProviderScope, clock/UUID, các reader journal và settings store. Opener có thể override để test trên file riêng; scope đóng owner sau các thao tác đã nhận. Profile preview vẫn dùng database riêng và không nhập dữ liệu hoặc quyền Pro thử vào journal.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. `main.dart` dùng `createJournalProfileApp()`: hồ sơ đọc/ghi SQLite journal thật qua owner chung, không nhập snapshot hoặc Pro từ database preview. Form/layout cũ được giữ; UUID request cũng là profile ID bền vững. Settings giữ ngôn ngữ khi profile selection thay đổi. Reset preview chỉ xuất hiện khi dùng service preview.

`createProfilePreviewApp()` vẫn dành cho kiểm thử FE độc lập. Home/timer/session còn dùng preview và callback lưu mẫu, chưa lưu journal; bootstrap draft/recovery đầy đủ chưa nối. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).
