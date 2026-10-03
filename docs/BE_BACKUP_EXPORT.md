# B11.1 — Xuất backup BE độc lập (UC-17)

Theo Report 2, UC-17/BR22/BR23 và bảng40 (schema JSON v1). Người dùng cho phép làm BE trước UI cho UC17–19. Chỉ xuất snapshot UTF-8 JSON trong bước này; chưa có document picker, ghi/đóng stream, xác nhận plaintext/no audio, restore hoặc reset.

`JournalBackupExporter.export()` trả bytes qua shared contract. `SqliteJournalBackupExporter` dùng một transaction đọc trên owner hiện có, không ghi dữ liệu và không mở database khác. Chặn khi có session Running/Paused/Review thuộc bất kỳ hồ sơ nào; caller xử lý `BackupFailureCode.unfinishedSession` để đưa về buổi đang có. Không tự lưu/hủy draft.

Whitelist xuất: `app`, `schemaVersion`, `exportedAt`, `profiles`, `sessions`, `goals`, `settings`. Chỉ Saved chưa xóa từ saved view; giữ UUID, text gốc/Unicode/newline, thời lượng đo và chỉnh sửa, ngày luyện local, offset và timestamps UTC. Notes/rating giữ empty/null. Settings chỉ language/reminder/metronome; weekdays1–7 (Monday=1), localTimeHH:mm. Goal thiếu được biểu diễn disabled/4. Default reminder/metronome dùng giá trị schema v1 nhưng không insert hàng mặc định vào database.

Không xuất session state/BPM journal (bảng40 không có trường này), audio/metadata/path, search keys, selection, permission, revision/lịch OS, diagnostics hoặc purchase/Pro. Bpm metronome thuộc settings vẫn được xuất. Nội dung không mã hóa; FE phải giải thích trước khi ghi tệp. Không có điều kiện entitlement, nên contract dùng được ở cả Free và Pro.

App cấp `journalBackupExporterProvider(language)` với `JournalLanguage` đang dùng cho database chưa có preferences; nếu đã lưu language, service ưu tiên giá trị trong snapshot. Provider là lazy, chưa gắn callback Settings hoặc đổi UI. Tầng gọi có thể lấy bytes rồi ghi qua adapter document destination trong B11.5; lấy bytes không đồng nghĩa đã lưu thành công một tệp.

Kiểm tra export: cận1000profiles/100000sessions, ID/owner/timestamp/calendar/field rules, settings/goals hợp lệ. Đọc vượt cận tối đa một hàng để từ chối, không trả bản cắt ngắn. JSON UTF-8 được mã hóa theo chunk và dừng khi quá20MiB. Lỗi SQLite/corrupt/closed qua JournalFailure; unfinished/capacity qua BackupFailure, không chứa journal text. Đây chưa phải bộ parser/validator import B11.2.

Test host và native dùng cùng `backup_export_journey.dart`: empty không tạo dữ liệu, snapshot mọi bảng trước/sau, Saved có audio và deleted có audio, goal/default/settings whitelist, text/ratings/UTC khác local, draft ba trạng thái ở hồ sơ khác, future-date fail giữ dữ liệu/retry, export trước mutation trong hàng đợi owner và closed connection. Tests encoder kiểm tra UTF-8 byte cap và cận số bản ghi; fault injection mất bảng settings kiểm tra storage failure. Native dùng package `.qa` và database UUID riêng, không gọi document picker hoặc sửa dữ liệu production.

Kết quả trên baseline main810571d: 309 host tests đạt với concurrency2, flutter analyze sạch; Android API36 x86_64 đạt export journey trên SQLite native. Boundary1000profiles thực xuất đủ, 1001 báo capacity thay vì truncate, không cần Pro. Đây là acceptance BE-only, chưa xác nhận một tệp ngoài ứng dụng đã được ghi thành công hoặc có thể restore bằng app.
