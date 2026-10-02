# Integration tests

`journal_database_smoke_test.dart` kiểm tra plugin SQLite thật trên Android bằng DB memory không có dữ liệu mẫu. Chạy từ `app/`: `flutter test integration_test/journal_database_smoke_test.dart -d <android-device>`.

Kiểm thử luồng thật trên Android emulator hoặc thiết bị: tạo item, timer, lưu session, quyền microphone, backup/restore và nâng cấp dữ liệu.

Task 10 có `shared_ui_smoke_test.dart`: mở form trên Android, lỗi bắt buộc tại trường, IME hệ thống, bấm đúp khi lưu, giữ input khi lỗi và thử lại thành công. Chỉ dùng callback/dữ liệu giả, không ghi storage.

```powershell
flutter test integration_test/shared_ui_smoke_test.dart -d emulator-5554
```

Thay device ID bằng thiết bị Android được liệt kê trong `flutter devices`. Audio, quyền, timer và lưu trữ sẽ có kiểm thử riêng khi các task đó triển khai.

UC-04: `flutter test integration_test/uc04_journal_smoke_test.dart -d <android-device>` kiểm tra icon +, ảnh Sáo đồng bộ, tools giữ session ID, Pause/Resume, Review, khóa Save trùng, lưu SQLite, mở lại và Start tiếp theo. Test dùng file database UUID riêng, giữ nguyên database người dùng.
