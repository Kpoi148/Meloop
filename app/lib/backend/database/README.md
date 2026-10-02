# SQLite cục bộ

`JournalDatabase.open()` mở `meloop.db` trong thư mục database riêng của app Android. Có thể truyền `DatabaseFactory` và đường dẫn khác khi kiểm thử. Không mở DB trên bộ nhớ dùng chung, không gọi mạng và không tạo dữ liệu mẫu.

- `journal_database.dart`: cấu hình connection, bật khóa ngoại, mở DB theo phiên bản và chặn downgrade.
- `migration_runner.dart`: chạy tuần tự các migration trong transaction do sqflite quản lý.
- `migrations/`: DDL đã đánh số phiên bản; không sửa migration đã phát hành.

Schema và ranh giới validation được mô tả tại [`../../../../docs/DB_MIGRATION_PLAN.md`](../../../../docs/DB_MIGRATION_PLAN.md). Entry Android và form dùng journal SQLite thật. Migration v3 thay index một draft toàn app bằng một draft mỗi hồ sơ, giữ tối đa một buổi Running; không sửa migration v1/v2 hoặc tạo lại database.

Migration v4 thêm `deleted_at` nullable cho buổi đã lưu và loại buổi đã xóa khỏi view `saved_practice_sessions`. Dữ liệu v1–v3 được giữ nguyên. Nếu buổi có bản ghi âm, service giữ hàng liên kết để tránh cascade xóa audio; buổi không có bản ghi được xóa khỏi bảng. Readers và số buổi của hồ sơ cùng dùng saved view.
