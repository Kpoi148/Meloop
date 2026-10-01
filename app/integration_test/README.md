# Integration tests

`journal_database_smoke_test.dart` kiểm tra plugin SQLite thật trên Android bằng DB memory không có dữ liệu mẫu. Chạy từ `app/`: `flutter test integration_test/journal_database_smoke_test.dart -d <android-device>`.

Kiểm thử luồng thật trên Android emulator hoặc thiết bị: tạo item, timer, lưu session, quyền microphone, backup/restore và nâng cấp dữ liệu.

Task 10 có `shared_ui_smoke_test.dart`: mở form trên Android, lỗi bắt buộc tại trường, IME hệ thống, bấm đúp khi lưu, giữ input khi lỗi và thử lại thành công. Chỉ dùng callback/dữ liệu giả, không ghi storage.

```powershell
flutter test integration_test/shared_ui_smoke_test.dart -d emulator-5554
```

Thay device ID bằng thiết bị Android được liệt kê trong `flutter devices`. Audio, quyền và lưu trữ sẽ có kiểm thử riêng khi các task đó triển khai.

Task 16 có `practice_session_smoke_test.dart`: tạo từ icon Buổi luyện, nhập bằng IME Android, Pause/Resume, Finish → Review → Save và chống gửi trùng. Timer do service xem thử cung cấp; dữ liệu chỉ ở bộ nhớ, không ghi nhật ký của thiết bị.

```powershell
flutter test integration_test/practice_session_smoke_test.dart -d <android-device>
```
