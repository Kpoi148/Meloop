# SQLite journal readers

Implement các port trong `shared/journal/`, đọc schema v1 qua cùng `JournalDatabaseOwner`. Không mở/đóng database riêng cho mỗi query.

- `SqliteJournalProfileReader`: danh sách theo created_at/id và tìm profile ID.
- `SqliteJournalSessionReader`: saved-only theo profile, ngày inclusive và search trên bốn key độc lập; detail query kiểm tra cả session ID và ownership. Unfinished đọc toàn app và trả sidecar cùng session; không tự chuyển state khi đọc.
- `SqliteJournalPreferencesReader`: language, selected profile và UTC updated_at; null nếu chưa bootstrap.
- `journal_row_mapper.dart`: map UTC/date/protocol enum và kiểm tra cấu trúc review JSON cố định. Corrupt review không trở thành draft rỗng hoặc bị xóa.

ID đầu vào phải là lowercase UUID v4. DB/query failure trả storage error; lỗi dữ liệu không hợp lệ trả corruptData; closed owner vẫn là closed. Không log payload hoặc SQL exception. Mọi mutation nghiệp vụ, recovery và file cleanup chưa thuộc readers.

`JournalDatabaseOwner` serialize open/read/transaction/close, retry được sau lỗi và close chờ thao tác đã nhận. Callback chỉ dùng executor trong thời gian callback; không giữ executor, đóng connection hoặc gọi lại owner từ trong callback/transaction (gây chờ lẫn nhau). Chủ app scope đóng owner; client store không được đóng.
