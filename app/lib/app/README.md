# App shell

B05: app cấp một `PracticeTimer` qua provider được cache ở scope ứng dụng, không tạo lại theo hồ sơ/ngôn ngữ. `JournalPracticeLifecycle` nằm trên điều hướng hồ sơ/tab, gửi inactive/hidden/paused/detached vào engine để Pause; resumed chỉ mở quyền thao tác, không tự Resume. Bootstrap mở draft vào engine trước khi render; Start mới mở Running sau commit. Màn timer dùng snapshot stream và gửi lệnh qua contract; Back/dispose đóng interval, checkpoint lỗi giữ màn và Retry. Port giữ màn hình sáng nằm ở backend Android; không thêm dependency package. Timer journal hỗ trợ Pause/Resume, còn Finish/Save vẫn chờ B06; preview FE giữ luồng riêng.

Khởi tạo app, dependency injection, theme và điều hướng toàn cục. Không đặt nghiệp vụ journal hoặc widget màn hình cụ thể ở đây.

`journal_providers.dart` cấp một `JournalDatabaseOwner` lazy cho mỗi ProviderScope, clock/UUID, các reader journal và settings store. Opener có thể override để test trên file riêng; scope đóng owner sau các thao tác đã nhận. Profile preview vẫn dùng database riêng và không nhập dữ liệu hoặc quyền Pro thử vào journal.

`MeloopApp` đặt `ProviderScope` phía trên Navigator. `main.dart` dùng `createJournalProfileApp()`: hồ sơ đọc/ghi SQLite journal thật qua owner chung, không nhập snapshot hoặc Pro từ database preview. Form/layout cũ được giữ; UUID request cũng là profile ID bền vững. Settings giữ ngôn ngữ khi profile selection thay đổi. Reset preview chỉ xuất hiện khi dùng service preview.

`createProfilePreviewApp()` vẫn dành cho kiểm thử FE độc lập với snapshot và callback lưu mẫu riêng. Entry journal cấp `PracticeStartService` qua DI: Start ghi draft thật, timer Pause/Resume/checkpoint đã nối BE; Review/Save chưa nối BE và không được báo thành công bằng fake save. Chi tiết: [`../../../docs/FE_RIVERPOD.md`](../../../docs/FE_RIVERPOD.md).

B03: `createJournalProfileApp()` dùng `JournalProfileEntry` với loader `SqliteJournalBootstrap`. Đọc profiles/count saved, selected preference và unfinished sidecar cùng transaction. Entry 0/1/nhiều là Welcome/Home/picker; draft hợp lệ ưu tiên recovery. Sửa selected ID mất hiệu lực, giữ language; lỗi đọc có retry, không thành empty. Browsing/đổi/thêm hồ sơ không đổi ownership draft. B05 đã bật Pause/Resume và recovery từ checkpoint; Finish/Save thuộc B06, không dùng fake save cho journal. Draft Review/input được giữ nguyên trong DB. Home/session queries đầy đủ còn B07/B08.

B04: Setup không ghi khi mở/Back. Start async với UUID giữ qua retry; chỉ đưa draft/session ID thật vào shell sau commit. Ghi lỗi giữ input và action Start; pending khóa gửi lại/Back/chỉnh title. Back khi có title dùng dialog Keep editing/Discard hiện có. B05 đã nối draft mới với timer monotonic thật; Finish/Save thuộc B06. Profile browsing/bootstrap tiếp tục giữ draft vừa tạo.
Cập nhật Finish cho FE: nút Kết thúc journal đã mở để vào SessionFormExample hiện có. Trước khi mở form, Pause ghi checkpoint; lỗi giữ màn timer/Retry, pending khóa thao tác trùng. Form nhận session ID và measured duration thật; dữ liệu draft bền vững vẫn Paused. Đây là mở điều hướng UI để FE điều chỉnh; chuyển Review bền vững, lưu input và Save session còn B06. Không fake Save; đóng/mở app quay về checkpoint Paused, không hứa phục hồi input form.


## Tích hợp UC-04

Review/Save đã nối SQLite journal thật qua `PracticeReviewService`. Finish ghi Review bằng timer service, Save cập nhật cùng session ID và trả bản lưu đầu tiên khi retry. Save thành công mở chi tiết, xóa draft và cho phép Start buổi tiếp theo. Phần mô tả B04/B05 phía trên là mốc lịch sử; chi tiết trạng thái hiện tại ở `docs/FE_PRACTICE_SESSION.md`. Các công cụ audio/metronome/tuner vẫn dùng port riêng; form chưa autosave nội dung trước Save.
