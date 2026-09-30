# Database tests

`journal_database_test.dart` dùng SQLite qua sqflite_common_ffi để chạy schema thật trong memory hoặc thư mục tạm. Kiểm tra bảng trống, FK, state transition, checkpoint, cleanup cascade và rollback migration. Test không chứng minh plugin Android hoạt động; kiểm tra native nằm ở `integration_test/journal_database_smoke_test.dart`.

Chạy từ `app/`: `flutter test test/backend/database`.
