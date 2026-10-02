# SQLite journal services và readers

B05: `PracticeTimer` là engine app scope dùng `MonotonicClock` (Stopwatch runtime), không cộng số lần render hoặc dùng wall clock để tính thời lượng. Pulse cập nhật UI và checkpoint ít nhất mỗi 5 giây khi Running; Pause/Back/background/dispose đóng interval ngay và serialize ghi. Resume chỉ mở interval sau commit, không tự chạy khi app trở lại foreground. Cold recovery lưu Paused tại checkpoint cuối; Review/input giữ nguyên. Giới hạn 24 giờ dừng ở Review, chưa Save.

`SqlitePracticeTimerStore` kiểm tra session/profile identity, không nhận checkpoint nhỏ hơn giá trị đã lưu; update sidecar và state trong cùng transaction. UTC metadata được giữ không giảm khi đồng hồ thiết bị đổi ngược; offset/ngày lúc Start không đổi. Lỗi ghi dừng engine, giữ elapsed mới trong RAM và công bố failure/Retry; Retry ghi Paused rồi người dùng Resume riêng. Loader/browsing cùng session ID không được thay RAM mới bằng checkpoint cũ sau lỗi. Không log nội dung journal/SQL exception.

`AndroidPracticeScreenAwake` serialize platform calls qua channel `meloop/practice_screen_awake`; Activity dùng FLAG_KEEP_SCREEN_ON khi Running và bỏ flag khi Paused/Review/background. Chưa có audio capture/tools trong journal, nên B05 không giả thao tác audio hoặc quyền microphone. Finish/Review form/Save thuộc B06, timer journal không gọi fake save. FE preview vẫn độc lập khi không cấp timer service.

`SqlitePracticeStartService` (B04) validate UUID và title NFC 1–100 code points, đọc unfinished và tạo Running trong một transaction. Schema v1 tạo sidecar với checkpoint 0 atomically; không sửa migration. Retry giữ request/session ID, Start đồng thời hoặc khác hồ sơ trả buổi đang có và không đổi owner/title/checkpoint. ID đã saved không được dùng để tạo buổi khác. Lỗi sidecar rollback cả session; lỗi storage không log nội dung nhật ký. Start ghi ngày/offset thiết bị lúc tạo; B05 nối đo thời gian/Pause/Resume, Save thuộc B06.

Android Start QA dùng `integration_test/practice_start_smoke_test.dart`, `--no-uninstall`, `--dart-define=START_TEST_DB=start-process-<uuid>.db` và `START_TEST_PHASE=create/reopen`. Database test riêng, phase create giữ file qua force-stop; phase reopen chỉ xóa đúng file test. Không dùng database người dùng để seed hoặc inject lỗi.

Implement các port trong `shared/journal/`, đọc schema v1 qua cùng `JournalDatabaseOwner`. Không mở/đóng database riêng cho mỗi query.

- `SqliteJournalProfileReader`: danh sách theo created_at/id và tìm profile ID.
- `SqliteJournalSessionReader`: saved-only theo profile, ngày inclusive và search trên bốn key độc lập; detail query kiểm tra cả session ID và ownership. Unfinished đọc toàn app và trả sidecar cùng session; không tự chuyển state khi đọc.
- `SqliteJournalPreferencesReader`: language, selected profile và UTC updated_at; null nếu chưa bootstrap.
- `journal_row_mapper.dart`: map UTC/date/protocol enum và kiểm tra cấu trúc review JSON cố định. Corrupt review không trở thành draft rỗng hoặc bị xóa.

ID đầu vào phải là lowercase UUID v4. DB/query failure trả storage error; lỗi dữ liệu không hợp lệ trả corruptData; closed owner vẫn là closed. Không log payload hoặc SQL exception. Mọi mutation nghiệp vụ, recovery và file cleanup chưa thuộc readers.

`JournalDatabaseOwner` serialize open/read/transaction/close, retry được sau lỗi và close chờ thao tác đã nhận. Callback chỉ dùng executor trong thời gian callback; không giữ executor, đóng connection hoặc gọi lại owner từ trong callback/transaction (gây chờ lẫn nhau). Chủ app scope đóng owner; client store không được đóng.

`SqliteInstrumentProfileService` implement contract thuần Dart trong `shared/profiles/`. Create validate NFC/code points, name key giữ dấu, Free tối đa 3; UUID request là profile ID để retry sau reopen không tạo thêm. Insert profile, disabled weekly goal và selected preference cùng transaction; lỗi giữ nguyên DB. Không nhận Pro mô phỏng. Adapter load/select/rename/delete giữ các control FE đang có hoạt động trên journal; count chỉ lấy saved sessions. Delete chặn unfinished và hồ sơ có recording vì worker xóa file chưa triển khai; không báo đã xóa file khi chưa xử lý. Không sửa schema v1.

`SqliteJournalBootstrap` đọc directory và unfinished draft trên cùng executor trong transaction, chỉ sửa selected preference nếu thiếu/mất hiệu lực. Không tự chọn hồ sơ đầu khi có nhiều hồ sơ; không đổi language hoặc state/checkpoint/review input. Draft hỏng hoặc không có owner là corruptData, storage lỗi không trở thành snapshot rỗng. `readProfileDirectory` và `readUnfinishedDraft` được tái sử dụng để tránh reenter owner từ transaction.

Android QA: `flutter test integration_test/profile_create_smoke_test.dart -d emulator-5554 --no-uninstall` dùng file UUID riêng và dọn đúng file đó. Khi kiểm tra process restart, dùng cùng `--dart-define=PROFILE_TEST_DB=profile-process-<uuid>.db`, chạy phase `create`, force-stop package rồi chạy phase `reopen`. Luôn thêm `--no-uninstall`: runner Flutter mặc định gỡ app sau test và xóa cả sandbox, khiến phép kiểm tra restart sai và có thể mất dữ liệu app trên thiết bị test. Không chạy test gỡ app trên thiết bị có journal cần giữ.
Android timer QA dùng `integration_test/practice_timer_smoke_test.dart`, `--no-uninstall --no-pub`, `TIMER_TEST_DB=timer-process-<uuid>.db` và `TIMER_TEST_PHASE=create/reopen`. Chỉ dùng file test riêng. Create kiểm tra checkpoint/Pause/Resume/inject lỗi/Retry/owner. Với `TIMER_TEST_EXTERNAL_BACKGROUND=true`, chờ marker `MELOOP_TIMER_QA_BACKGROUND_READY`, gửi Android Home rồi đưa Activity trở lại; kiểm tra Paused và không tự Resume. Với `TIMER_TEST_EXTERNAL_TERMINATE=true`, chờ `MELOOP_TIMER_QA_KILL_READY`, force-stop app khi Running rồi chạy phase reopen cùng file: runner create bị ngắt là dự kiến, kết quả reopen mới xác nhận cold recovery. Phase reopen kiểm tra đúng checkpoint/UUID/owner, không cộng thời gian đóng và không tạo buổi thứ hai; chỉ xóa file test đó. Không uninstall/reset dữ liệu người dùng.
Cập nhật Finish cho FE: nút Kết thúc journal đã mở để vào SessionFormExample hiện có. Trước khi mở form, Pause ghi checkpoint; lỗi giữ màn timer/Retry, pending khóa thao tác trùng. Form nhận session ID và measured duration thật; dữ liệu draft bền vững vẫn Paused. Đây là mở điều hướng UI để FE điều chỉnh; chuyển Review bền vững, lưu input và Save session còn B06. Không fake Save; đóng/mở app quay về checkpoint Paused, không hứa phục hồi input form.


## Tích hợp UC-04

Review/Save đã nối SQLite journal thật qua `PracticeReviewService`. Finish ghi Review bằng timer service, Save cập nhật cùng session ID và trả bản lưu đầu tiên khi retry. Save thành công mở chi tiết, xóa draft và cho phép Start buổi tiếp theo. Phần mô tả B04/B05 phía trên là mốc lịch sử; chi tiết trạng thái hiện tại ở `docs/FE_PRACTICE_SESSION.md`. Các công cụ audio/metronome/tuner vẫn dùng port riêng; form chưa autosave nội dung trước Save.
