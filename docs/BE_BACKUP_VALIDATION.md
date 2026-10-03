# B11.2 — Kiểm tra backup trước khôi phục

`JournalBackupValidator.validate(Stream<List<int>>)` trả `BackupPreview` gồm immutable typed document, exportedAt và số profiles/sessions. App cấp `journalBackupValidatorProvider`. Không database dependency, không staging/write/reset, không chọn tệp hoặc hiển thị xác nhận; chưa phải restore. B11.3 phải giữ ranh giới xác nhận/thay thế và revalidate dữ liệu tại thời điểm restore, không coi preview tự tạo là quyền ghi.

Đối chiếu Report2 UC18/BR23, bảng38/40: nhận UTF8 JSON Meloop schemaVersion1; giới hạn20MiB kiểm tra trong lúc đọc, dừng/cancel nguồn khi vượt cận, không trả kết quả cắt ngắn. Cận1000profiles/100000sessions, integer/bool/string đúng kiểu không coercion. Phiên bản khác trả unsupportedVersion; sai JSON/UTF8/schema/data trả invalidBackup; lỗi nguồn đọc trả readFailure. Failure không chứa nội dung hoặc đường dẫn nhập.

Whitelist trường trên mọi object, kể cả settings/reminder/metronome. Validate UUID theo quy tắc store, uniqueness từng collection và liên kết profile; không duplicate goals hoặc profile names đã chuẩn hóa. Chỉ nhận saved-session fields, không state/audio/path/BPM journal/purchase/permissions/selection. Không thực thi imported text; strings ở trường ghi chú vẫn chỉ là nội dung.

UTC timestamps có Z, calendar/time hợp lệ, không normalization rollover của DateTime.parse; timestamp phải tương thích store epoch, updatedAt>=createdAt. PracticeDate2000–device-local today, không suy ra từ UTC export timestamp. Duration/measurement/offset/notes/ratings/goals và settings áp dụng cận SRS hiện có. Notes/rating vắng thành empty/null, notes null hoặc sai kiểu bị từ chối. Goal thiếu thành disabled/4; goal disabled vẫn giữ target. Empty dataset hợp lệ nhưng B11.3 vẫn cần replacement warning.

Guard độ sâu JSON16 trước decode tránh input lồng bất thường; schema v1 không cần độ sâu này. Chuỗi có braces/escaped quotes không bị tính vào depth. Model kết quả dùng collections unmodifiable; validator copy byte chunks để nguồn đọc không đổi các buffers đã nhận. Preview không kiểm tra Free quota: dữ liệu vượt quota vẫn được nhận theo SRS, giới hạn tạo mới thuộc B11.3/creation rules.

Tests gồm fixtures SRS độc lập, malformed matrix, đúng20MiB/vượt/cancel, UTF8 chia nhỏ, nonfinite/double/bool/string numbers, IDs/references/fields/goals, cận ngày và timestamp rollover, unsupported version và collection cap. Journey host/native xuất từ SQLite thật rồi validate và retry malformed input, snapshot mọi bảng không đổi. Các tests này chưa xác nhận Android document picker, tệp trên filesystem, restore hoặc rollback replacement.

Baseline main476e241: 7 targeted tests và316 host tests đạt (concurrency2), flutter analyze sạch; AndroidAPI36 x86_64 export/validate/retry/source-unchanged journey đạt với isolated `.qa`+UUID database. Kiểm thử giới hạn20MiB và malformed matrix chạy host, không suy ra native document picker hoặc OEM memory acceptance.
