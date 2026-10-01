# Journal contracts (B01)

Model/contract thuần Dart cho SQLite journal v1, không phụ thuộc Flutter/Riverpod hay enum/label widget.

- `journal_models.dart`: profile, session, draft/review input và preferences. UTC timestamps dùng `DateTime`; practice date là calendar date riêng; corrected/measured duration độc lập. Review giữ chuỗi input chưa hợp lệ.
- `journal_readers.dart`: port đọc profiles, saved sessions, unfinished session và preferences. List trả về immutable; null/empty chỉ là đọc thành công không có bản ghi. Lỗi không được đổi thành empty.
- `journal_runtime.dart`: clock/UUID v4 injectable. Sinh ID một lần tại command boundary rồi giữ qua retry; không lấy ID preview làm ID journal.
- `journal_text.dart`: NFC cho display name; full default Unicode case folding + whitespace cho uniqueness, giữ dấu. Search key loại combining marks và đổi đ thành d; LIKE escape giữ query literal. Dữ liệu gốc không bị thay thế.
- `practice_date.dart`: YYYY-MM-DD hợp lệ từ 2000-01-01. Service ghi còn phải kiểm tra không vượt device-local today qua clock; parser không lấy giờ hệ thống ngầm.
- `journal_failure.dart`: mã lỗi an toàn, không chứa journal text hoặc SQL.

Normalization dùng unorm_dart 0.3.2 (Unicode 17), bảng C+F Unicode 17.0.0 được sinh bằng `dart run tool/generate_case_folding.dart` từ thư mục app. Bảng chạy offline; license ở `tool/unicode-LICENSE.txt`. Không tự cập nhật phiên bản Unicode/key trên DB đang dùng; thay đổi thuật toán cần kế hoạch re-key và kiểm tra collision trước.

B01 chỉ có port đọc thật và nền tảng transaction. Lệnh create/rename/delete/save, timer/recovery và adapter service hồ sơ FE triển khai ở các bước tiếp theo, không trả thành công giả. Contract FE mới tại `frontend/application/instrument_profile_service.dart` vẫn giữ nguyên; app sẽ map model domain sang port đó khi nối service thật.
