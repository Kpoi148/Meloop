# SQLite journal services và readers

`SqlitePracticeStartService` (B04) validate UUID và title NFC 1–100 code points, đọc unfinished và tạo Running trong một transaction. Schema v1 tạo sidecar với checkpoint 0 atomically; không sửa migration. Retry giữ request/session ID, Start đồng thời hoặc khác hồ sơ trả buổi đang có và không đổi owner/title/checkpoint. ID đã saved không được dùng để tạo buổi khác. Lỗi sidecar rollback cả session; lỗi storage không log nội dung nhật ký. Start ghi ngày/offset thiết bị lúc tạo; chưa triển khai đo thời gian, Pause/Resume hoặc Save (B05/B06).

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
