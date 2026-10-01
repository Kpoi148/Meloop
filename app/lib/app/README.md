# App shell

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`journal_providers.dart` cấp một `JournalDatabaseOwner` lazy cho mỗi ProviderScope, clock/UUID, các reader journal và settings store. Opener có thể override để test trên file riêng; scope đóng owner sau các thao tác đã nhận. Profile preview vẫn dùng database riêng và không nhập dữ liệu hoặc quyền Pro thử vào journal.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. `main.dart` dùng `createJournalProfileApp()`: hồ sơ đọc/ghi SQLite journal thật qua owner chung, không nhập snapshot hoặc Pro từ database preview. Form/layout cũ được giữ; UUID request cũng là profile ID bền vững. Settings giữ ngôn ngữ khi profile selection thay đổi. Reset preview chỉ xuất hiện khi dùng service preview.

`createProfilePreviewApp()` vẫn dành cho kiểm thử FE độc lập với snapshot và callback lưu mẫu riêng. Trong entry journal, ghi session/timer/review chưa nối BE và không được báo thành công bằng fake save. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).

B03: `createJournalProfileApp()` dùng `JournalProfileEntry` với loader `SqliteJournalBootstrap`. Đọc profiles/count saved, selected preference và unfinished sidecar cùng transaction. Entry 0/1/nhiều là Welcome/Home/picker; draft hợp lệ ưu tiên recovery. Sửa selected ID mất hiệu lực, giữ language; lỗi đọc có retry, không thành empty. Browsing/đổi/thêm hồ sơ không đổi ownership draft. Snapshot và controls timer recovery thật chỉ đọc; Resume/Finish chưa bật đến B05/B06, không dùng fake save cho journal. Draft Review/input được giữ nguyên trong DB. Luồng Start mới chưa nối BE (B04); Home/session queries đầy đủ còn B07/B08.
