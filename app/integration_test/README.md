# Integration tests

Kiểm thử luồng thật trên Android emulator hoặc thiết bị: tạo item, timer, lưu session, quyền microphone, backup/restore và nâng cấp dữ liệu.

Task 10 có `shared_ui_smoke_test.dart`: mở form trên Android, lỗi bắt buộc tại trường, IME hệ thống, bấm đúp khi lưu, giữ input khi lỗi và thử lại thành công. Chỉ dùng callback/dữ liệu giả, không ghi storage.

```powershell
flutter test integration_test/shared_ui_smoke_test.dart -d emulator-5554
```

Thay device ID bằng thiết bị Android được liệt kê trong `flutter devices`. Audio, quyền, timer và lưu trữ sẽ có kiểm thử riêng khi các task đó triển khai.
