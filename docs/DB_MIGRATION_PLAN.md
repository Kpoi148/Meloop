# SQLite journal migration v1

Meloop Android lưu journal trong `meloop.db` ở thư mục database riêng của app. Migration tạo cấu trúc, không tạo hồ sơ, session, recording hoặc dữ liệu mẫu. Thanh toán và Pro được hoãn; schema này không có purchase, entitlement, tài khoản hay dữ liệu cloud.

Thiết kế dựa trên Report 2 Software Requirements Specification v1.1 ngày 27/09/2026, đặc biệt BR02–BR14, BR18–BR23 và mục 5.2. Report 2 thay thế các đề xuất cũ về danh mục bài tập, practice plan, archive và giới hạn Free. File báo cáo là tài liệu đầu vào; không cần commit nó cùng migration.

## Trạng thái triển khai

Sửa xóa buổi đã lưu: migration v4 thêm `deleted_at` nullable, saved view lọc `state='saved' AND deleted_at IS NULL`. Buổi không có recording được xóa metadata; buổi có recording giữ hàng FK với dấu xóa bất biến để bản ghi âm vẫn còn riêng theo prototype. History/detail và count hồ sơ đều dùng view này; draft, checkpoint, recording, settings và dữ liệu phiên bản trước không bị đổi. Không sửa migration v1–v3, không tạo lại DB. Xóa trong một transaction, retry không tác động thêm; Save không trả lại buổi đã xóa. Test nâng cấp v3→v4 và rollback kiểm tra toàn bộ hàng cũ.

Cập nhật UC-04: migration v2 thêm BPM nullable; v3 thay `one_unfinished_session` bằng unique partial index trên `profile_id` cho state khác saved, đồng thời giữ một Running toàn app. Mỗi hồ sơ có một buổi chưa lưu riêng; các buổi còn lại tạm dừng tại checkpoint. Start/Resume/Review/Save dùng đúng profile/session, bootstrap chỉ trả draft của hồ sơ đang chọn. Nâng cấp không tạo lại bảng hoặc đổi session ID, checkpoint, review input và liên kết bản ghi. Các mô tả v1/B01–B05 phía dưới ghi lại phiên bản ban đầu; v1/v2 không bị sửa.

Đã có DDL v1, opener sqflite, migration runner, cấu hình Android backup và test schema. B01 bổ sung owner connection chung, model/contract thuần Dart và SQLite readers; settings/ngôn ngữ dùng owner được app cấp qua Riverpod. B02 nối form tạo hồ sơ vào SQLite journal: UUID request ổn định, validation và giới hạn Free tại BE, profile/disabled goal/selection commit cùng transaction. Các control load/select/rename và delete hồ sơ không recording dùng journal. Delete có recording còn chặn đến khi worker cleanup được triển khai. `SessionFormSave`, timer, capture và import/export chưa nối journal. Database profile UI preview vẫn riêng, không tự chuyển sang journal và không cấp entitlement thật.

## Quy ước

B03 bổ sung bootstrap nguyên tử cho directory/count saved, selected preference và unfinished sidecar. Sửa selection mất hiệu lực mà không đổi language; draft không bị chuyển owner hoặc xóa. Entry journal đã tách khỏi preview profiles; timer recovery chỉ đọc đến B05/B06. Không thêm/sửa migration ở bước này.

B04 nối Setup Start qua `SqlitePracticeStartService`: UUID request ổn định, title NFC/code points, ngày/offset thiết bị; kiểm tra unfinished và insert Running cùng transaction. Trigger v1 tạo sidecar checkpoint 0; retry/concurrent Start trả draft đang có, lỗi sidecar rollback session. Mở Setup/Back không ghi. Draft chưa saved không tham gia history/stats; timer/checkpoint/review mutations thuộc B05/B06. Không thay migration v1.

B05 nối timer monotonic app scope và SQLite checkpoint/state transaction; không thay migration. Checkpoint 5 giây, Pause/Resume/Back/background, recovery Paused tại checkpoint và auto-stop Review ở 24 giờ. Lỗi giữ elapsed mới trong RAM, Retry persist Paused; không gọi fake Save. Wall clock chỉ ghi metadata và timestamp không giảm; ngày/offset/owner giữ nguyên. Review raw input không bị timer viết lại. Final Review/Save thuộc B06.

- Tên bảng/cột: snake_case. UUID v4 dạng TEXT lowercase cho profile, session, recording; giữ ID khi backup/restore. ID queue là INTEGER nội bộ, không thuộc định danh portable của SRS.
- `created_at`, `updated_at`, `checkpoint_at`, `next_attempt_at`: INTEGER Unix milliseconds UTC. Cập nhật do backend thực hiện, không dùng SQL `now` làm đồng hồ timer.
- `practice_date`: TEXT YYYY-MM-DD. SQL kiểm tra ngày thực tế và cận dưới 2000-01-01; nghiệp vụ còn phải kiểm tra không vượt device-local today. `start_offset_minutes` giữ offset lúc Start.
- Boolean: INTEGER 0/1. Notes: TEXT NOT NULL mặc định rỗng; ratings chưa chọn: NULL. Độ dài text tính Unicode code points.
- SQLite affinity có thể chuyển numeric string thành số. Import/domain phải kiểm tra kiểu trước khi bind, không nhận boolean như integer hoặc ép chuỗi thành số.
- Không dùng SQLite JSON functions hoặc STRICT tables để giữ khả năng chạy trên SQLite nền tảng Android cũ. Domain validate JSON riêng.

## Bảng và trường

### instrument_profiles

`id TEXT PK`, `name TEXT NOT NULL`, `name_key TEXT NOT NULL UNIQUE`, `instrument_type TEXT NOT NULL`, `custom_type TEXT NOT NULL DEFAULT ''`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`.

Tên 1–50 code points; type thuộc guitar/piano/ukulele/violin/flute/drums/other. Other có custom_type 1–40 code points; type khác phải rỗng. Domain tạo name_key từ NFC, case folding và chuẩn hóa whitespace, giữ dấu. SQL không tự làm Unicode normalization; caller phải dùng cùng helper cho tạo, rename và import. Trigger khóa id/type/custom_type sau Create.

### practice_sessions

`id TEXT PK`, `profile_id TEXT NOT NULL FK`, `state TEXT NOT NULL`, `title TEXT NOT NULL`, `practice_date TEXT NOT NULL`, `duration_seconds INTEGER NULL`, `measured_duration_seconds INTEGER NULL`, `start_offset_minutes INTEGER NOT NULL`, `practiced TEXT NOT NULL DEFAULT ''`, `difficulty TEXT NOT NULL DEFAULT ''`, `next_note TEXT NOT NULL DEFAULT ''`, `mood INTEGER NULL`, `focus INTEGER NULL`, `title_search TEXT NOT NULL DEFAULT ''`, `practiced_search TEXT NOT NULL DEFAULT ''`, `difficulty_search TEXT NOT NULL DEFAULT ''`, `next_search TEXT NOT NULL DEFAULT ''`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`.

State: running/paused/review/saved. Title 1–100 code points; notes tối đa 2.000; ratings 1–5 hoặc NULL. Saved bắt buộc duration 1–86.400 và measured duration 0–86.400. Trong draft, hai giá trị duration có thể NULL; timer lấy thời gian từ session_drafts. Khi Save, gán measured duration bằng accumulated_ms chia nguyên cho 1.000; duration người dùng sửa vẫn độc lập.

Một unique partial index trên hằng số 1 với điều kiện state <> saved chặn draft thứ hai trên toàn app. View saved_practice_sessions chỉ có saved. INSERT saved được phép cho restore; nghiệp vụ tạo session mới chỉ INSERT running sau khi Start hợp lệ. Trigger chặn đổi ownership, offset, chuyển trạng thái sai và thay đổi measurement sau Save.

Search columns là dữ liệu dẫn xuất do domain tạo, không dùng text gốc đã bị bỏ dấu. Normalize từng trường độc lập: Unicode case-insensitive, diacritic-insensitive, gồm đ/Đ. OR các truy vấn substring đã escape LIKE metacharacters. Khóa NFC uniqueness của profile khác với search key. Không xuất search columns vào backup; tạo lại khi import. SQL schema không tự thực hiện normalization.

### session_drafts

`session_id TEXT PK/FK`, `accumulated_ms INTEGER NOT NULL DEFAULT 0`, `checkpoint_at INTEGER NOT NULL`, `review_input_json TEXT NULL`, `updated_at INTEGER NOT NULL`.

Tạo tự động cùng INSERT session chưa lưu. Accumulated_ms 0–86.400.000, không giảm qua checkpoint. Checkpoint ít nhất mỗi 5 giây và khi đổi trạng thái thuộc timer service tương lai; khi restart phải phục hồi paused, không cộng thời gian wall-clock lúc app đóng.

Review input JSON có giới hạn 65.536 code points và cấu trúc cố định được domain kiểm tra: title, practiceDate, durationHoursInput, durationMinutesInput, durationSecondsInput, practiced, difficulty, next, mood, focus. Các ô thời lượng lưu chuỗi input để giữ giá trị chưa hợp lệ. Không thực thi JSON hoặc nhận path từ nó. Save validate vào cột canonical trước rồi trigger xóa sidecar trong cùng transaction. Không nhận draft từ backup.

### recordings

`id TEXT PK`, `session_id TEXT NOT NULL FK`, `status TEXT NOT NULL`, `temp_relative_path TEXT NULL UNIQUE`, `local_relative_path TEXT NULL UNIQUE`, `filename TEXT NULL`, `duration_ms INTEGER NULL`, `size_bytes INTEGER NULL`, `sample_rate_hz INTEGER NULL`, `channel_count INTEGER NULL`, `codec TEXT NOT NULL DEFAULT 'aac'`, `container TEXT NOT NULL DEFAULT 'm4a'`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`.

Pending cần temp path và không hiển thị như clip phát được; ready/unavailable cần metadata đầy đủ, temp path NULL, duration >= 1.000 ms, size > 0, rate 44.100/48.000, mono và đuôi M4A. Unavailable giữ metadata khi file mất, không tự xóa journal. Capture mới chỉ liên kết session chưa lưu; pending chỉ bắt đầu ở running/paused. Save chặn khi còn pending capture.

Path luôn tương đối, do app tạo, không chứa absolute root, backslash, colon, NUL, đoạn . hoặc ..; file storage phải resolve và xác nhận vẫn trong sandbox, kể cả symlink nếu có. File không nằm trong DB. DDL chỉ bảo vệ metadata; không chứng minh file tồn tại hoặc decode được. Capture service phải xác minh trước khi ready và serialize audio operations.

### weekly_goals

`profile_id TEXT PK/FK`, `enabled INTEGER NOT NULL DEFAULT 0`, `target_days INTEGER NOT NULL DEFAULT 4`, `updated_at INTEGER NOT NULL`.

Một goal mỗi profile, target 1–7. Use case Create profile sẽ tạo disabled goal cùng transaction; migration không seed goal. Streak, qualifying days và averages được tính từ saved sessions, không lưu trùng trong bảng.

### app_preferences

`id INTEGER PK CHECK id=1`, `language TEXT NOT NULL`, `selected_profile_id TEXT NULL FK`, `updated_at INTEGER NOT NULL`.

Language vi/en, chọn từ locale thiết bị khi bootstrap settings. Profile selection bị SET NULL khi profile bị xóa và không có trong backup. Sau delete/restore, áp dụng entry rule zero/one/multiple profiles. Không dùng preferences để cấp quyền Pro.

### reminder_settings

`id INTEGER PK CHECK id=1`, `enabled INTEGER NOT NULL DEFAULT 0`, `weekdays_mask INTEGER NOT NULL DEFAULT 0`, `local_time_minutes INTEGER NOT NULL DEFAULT 1170`, `schedule_revision INTEGER NOT NULL DEFAULT 1`, `applied_revision INTEGER NULL`, `last_delivered_local_date TEXT NULL`, `updated_at INTEGER NOT NULL`.

Weekday mask 0–127, bit 0 = thứ Hai, bit 6 = Chủ nhật. Enabled cần mask > 0; time 0–1.439, mặc định 19:30. Revision dùng đối chiếu lịch desired/applied; applied không chứng minh quyền OS hiện tại. Domain validate last_delivered_local_date như local date; OS adapter phải phối hợp chống giao lặp và reschedule. Runtime fields không có trong backup.

### metronome_settings

`id INTEGER PK CHECK id=1`, `bpm INTEGER NOT NULL DEFAULT 80`, `beats_per_bar INTEGER NOT NULL DEFAULT 4`, `updated_at INTEGER NOT NULL`.

BPM 40–240, beat 1–12. Trạng thái playing không được lưu để tự phát lại khi mở app.

### file_cleanup_queue

`id INTEGER PK`, `storage_namespace TEXT NOT NULL`, `relative_path TEXT NOT NULL`, `reason TEXT NOT NULL`, `attempt_count INTEGER NOT NULL DEFAULT 0`, `next_attempt_at INTEGER NULL`, `last_error_code TEXT NULL`, `created_at INTEGER NOT NULL`.

Namespace: audio/audio_temp/export_temp. UNIQUE(namespace,path), không FK tới journal đã xóa. Reason: recording_deleted/capture_finalized/restore/reset/orphan_temp. Trigger queue_recording_cleanup ghi tác vụ trước khi xóa metadata, kể cả cascade xóa session/profile; queue_finalized_temp giữ ý định dọn file tạm khi finalize. Không xóa file trong transaction SQL.

Worker tương lai chỉ thao tác file app quản lý; file đã không tồn tại được coi là cleanup thành công. Giữ queue qua reset/restore cho đến khi thực hiện xong. Không báo device erasure hoàn tất nếu còn task. Không ghi journal/credential vào last_error_code.

## Index, quan hệ và transaction

- `instrument_profiles.name_key`: UNIQUE.
- `one_unfinished_session`: UNIQUE partial index.
- `sessions_profile_state_date`: profile_id/state/practice_date DESC/created_at DESC/id DESC.
- `recordings_session`: session_id/created_at/id.
- `cleanup_retry`: next_attempt_at/id.
- Profile -> sessions/goals: CASCADE; session -> draft/recordings: CASCADE; selected profile: SET NULL. Profile có unfinished session bị trigger chặn xóa. Khi reset, xóa session trước profile.
- Save: cập nhật checkpoint, finalize audio trước, UPDATE review -> saved với metadata đã validate; draft tự bị xóa trong transaction, recording links không đổi. Retry dùng UUID cố định và điều kiện state để không tạo bản ghi thứ hai.
- Delete/cancel: DB commit logical deletion cùng queue; worker xóa file sau commit. Transaction lỗi rollback cả journal lẫn queue.

## Migration và backup contract

Database user_version v1 do sqflite quản lý. onCreate/onUpgrade đã có transaction; runner không mở nested transaction. Bật foreign_keys trên connection trong onConfigure. Lỗi bất kỳ DDL hoặc foreign_key_check làm callback throw, rollback và giữ version cũ. Downgrade bị từ chối, không dùng deleteDatabase hoặc onDatabaseDowngradeDelete. Migration tương lai phải giữ dữ liệu hợp lệ; v1 không giả lập v2.

Backup schemaVersion 1 độc lập với database version. Khi có exporter/importer, mapping snake_case -> camelCase theo SRS:

- profiles: id, name, instrumentType, customType, createdAt, updatedAt.
- sessions: chỉ saved; id, profileId, title, practiceDate, durationSeconds, measuredDurationSeconds, startOffsetMinutes, createdAt, updatedAt, practiced, difficulty, next, mood, focus. next_note -> next. UTC milliseconds -> ISO 8601 Z.
- goals: profileId, enabled, targetDays.
- settings: language, reminder(enabled/weekdays/localTime), metronome(bpm/beatsPerBar).
- Không export recording/metadata/path, draft, selection, queue, native runtime, permission hoặc purchase.

Restore phải validate trước vào staging, tạo lại normalization/search keys, transaction thay thế journal/settings có chọn lọc và enqueue audio cũ, giữ queue. Không swap toàn bộ DB một cách làm mất queue. Đổi lịch native chỉ sau commit. Restore/backups không được triển khai trong task schema này.

## Dữ liệu cục bộ trên Android

Manifest allowBackup=false; backup_rules.xml và data_extraction_rules.xml loại sandbox khỏi cloud backup và device transfer tự động trên các Android version tương ứng. Dữ liệu không được commit lên Git. Backup do người dùng chọn lưu hoặc chia sẻ trong tương lai là hành động riêng có thông báo, không phải đồng bộ tự động.

## Tiêu chí kiểm tra

- DB mới có đúng 9 bảng và tất cả bảng trống; version 1, FK enabled.
- Chặn orphan, UUID/type/range/date sai, tên key trùng và session chưa lưu thứ hai.
- Save giữ recording links, tách measured/corrected duration, xóa draft đúng một lần.
- Session saved không quay lại timer hoặc nhận capture mới.
- Cascade queue file; rollback deletion giữ journal/audio metadata và không để task xóa nhầm.
- Reopen giữ bản ghi đã commit; migration lỗi không để schema hoặc version nửa chừng; DB mới hơn bị từ chối mà vẫn giữ dữ liệu.
- Kiểm tra plugin trên Android riêng với `flutter test integration_test/journal_database_smoke_test.dart -d <android-device>`.

Thư viện: sqflite 2.4.4 cho Android, sqflite_common_ffi 2.4.3 chỉ là dev dependency cho test SQLite trên desktop. Đã chạy Flutter pub get và cập nhật lockfile bằng công cụ; không sửa lockfile thủ công.

### Kết quả kiểm chứng ngày 30/09/2026

Flutter 3.47.5 / Dart 3.13.4 trên Windows. `flutter analyze` không có lỗi; `flutter test` qua 47 test, trong đó 16 test database. Test DB dùng SQLite FFI trên máy phát triển; kiểm tra cả lỗi onCreate và lỗi onUpgrade để xác nhận schema/version được rollback, dữ liệu cũ được giữ.

`flutter build apk --debug` chưa chạy thành công vì môi trường không có Android SDK. Không có emulator/thiết bị Android kết nối, nên integration test sqflite và hành vi backup trên Android chưa được xác minh. Desktop test không thay thế kiểm tra plugin trên Android.

Nguồn kỹ thuật: [sqflite transaction callbacks](https://pub.dev/packages/sqflite), [SQLite foreign keys](https://www.sqlite.org/foreignkeys.html), [SQLite partial indexes](https://www.sqlite.org/partialindex.html), [Android Auto Backup controls](https://developer.android.com/identity/data/autobackup).

### B01 — Nền tảng journal ngày 01/10/2026

Thêm model/reader contract thuần Dart trong `app/lib/shared/journal/`, SQLite readers trong `app/lib/backend/journal/` và app providers. Một `JournalDatabaseOwner` lazy quản lý connection cho settings/readers; serialize cả open/transaction/close, không để store đóng DB của bên khác. Gọi lại owner từ trong callback bị từ chối để tránh deadlock. Schema và migration v1 giữ nguyên; create/save/recovery/file cleanup chưa triển khai. Hồ sơ và Pro preview tiếp tục ở store FE riêng.

Kiểm chứng Windows Flutter 3.47.5 / Dart 3.13.4: 92 unit/widget/database tests đạt, gồm 16 test nền tảng mới. Test bảo vệ rollback, close khi open còn chờ, retry lỗi, dữ liệu sau reopen, query ownership, review input invalid, Unicode NFC/full case fold/diacritic search và LIKE literal escaping. Test schema/migration cũ vẫn đạt.

Android API 36 x86_64: `flutter test integration_test/journal_foundation_smoke_test.dart -d emulator-5554 --no-pub` đạt 1 test với database test tên riêng; chứng minh shared owner, rollback và settings qua reopen hoạt động trên sqflite Android. Không reset database người dùng, không coi đây là kiểm thử restart/kill toàn app hoặc acceptance các feature journal chưa nối FE.
