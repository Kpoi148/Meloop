# Backend cục bộ

Backend của Meloop chạy bên trong app Android, không phải server riêng. Phần này xử lý nghiệp vụ, lưu dữ liệu và tích hợp API của thiết bị.

Backend cung cấp contract ổn định cho frontend và là nơi kiểm tra các quy tắc như chống lưu trùng, streak, draft recovery và giới hạn Free/Pro.

Nền tảng B01 có `JournalDatabaseOwner` quản lý connection chung và [`journal/`](journal/README.md) implement các port đọc thuần Dart. Settings dùng owner được app cấp; không tự đóng DB sau mỗi thao tác. Nghiệp vụ ghi profiles/sessions chưa được nối vào FE.

Schema SQLite journal v1 và opener nằm trong [`database/`](database/README.md). Dữ liệu chỉ ở trên thiết bị; migration không seed dữ liệu. Thanh toán/Pro chưa triển khai. Thiết kế chi tiết: [`../../../docs/DB_MIGRATION_PLAN.md`](../../../docs/DB_MIGRATION_PLAN.md).

UC-09 đã có contract `PitchService` trong shared và màn FE, chưa có adapter đo cao độ/micro thật. Hướng dẫn điểm nối, trạng thái, quyền micro và Start/Stop: [`../../../docs/BE_PITCH_SERVICE.md`](../../../docs/BE_PITCH_SERVICE.md).
