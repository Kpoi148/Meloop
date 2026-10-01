# App shell

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`journal_providers.dart` cấp một `JournalDatabaseOwner` lazy cho mỗi ProviderScope, clock/UUID, các reader journal và settings store. Opener có thể override để test trên file riêng; scope đóng owner sau các thao tác đã nhận. Profile preview vẫn dùng database riêng và không nhập dữ liệu hoặc quyền Pro thử vào journal.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. `main.dart` dùng `createJournalProfileApp()`: hồ sơ đọc/ghi SQLite journal thật qua owner chung, không nhập snapshot hoặc Pro từ database preview. Form/layout cũ được giữ; UUID request cũng là profile ID bền vững. Settings giữ ngôn ngữ khi profile selection thay đổi. Reset preview chỉ xuất hiện khi dùng service preview.

`createProfilePreviewApp()` vẫn dành cho kiểm thử FE độc lập với snapshot và callback lưu mẫu riêng. Entry journal cấp `PracticeStartService` qua DI: Start ghi draft thật, còn timer/review mutations chưa nối BE và không được báo thành công bằng fake save. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).

B03: `createJournalProfileApp()` dùng `JournalProfileEntry` với loader `SqliteJournalBootstrap`. Đọc profiles/count saved, selected preference và unfinished sidecar cùng transaction. Entry 0/1/nhiều là Welcome/Home/picker; draft hợp lệ ưu tiên recovery. Sửa selected ID mất hiệu lực, giữ language; lỗi đọc có retry, không thành empty. Browsing/đổi/thêm hồ sơ không đổi ownership draft. Snapshot và controls timer recovery thật chỉ đọc; Resume/Finish chưa bật đến B05/B06, không dùng fake save cho journal. Draft Review/input được giữ nguyên trong DB. Home/session queries đầy đủ còn B07/B08.

B04: Setup không ghi khi mở/Back. Start async với UUID giữ qua retry; chỉ đưa draft/session ID thật vào shell sau commit. Ghi lỗi giữ input và action Start; pending khóa gửi lại/Back/chỉnh title. Back khi có title dùng dialog Keep editing/Discard hiện có. Draft mới cũng dùng timer chỉ đọc đến B05/B06, tránh giả thời gian/lưu. Profile browsing/bootstrap tiếp tục giữ draft vừa tạo.
