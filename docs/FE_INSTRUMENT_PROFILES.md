# Task 14 — Màn hình hồ sơ nhạc cụ

UI cho UC-01/02/03/25 dùng theme và asset Tempo đã đóng gói trong app. Bố cục tham chiếu các màn `instrumentPicker`, `profiles`, `profileForm` của `meloop-tempo-html`. Hành vi theo SRS Report 2: sửa chỉ đổi tên, xóa vĩnh viễn thay vì lưu trữ, không chọn sẵn loại nhạc cụ khi tạo, giới hạn Free là ba hồ sơ.

## Xem thử tương tác

Trong `app/`:

```powershell
flutter run
```

`lib/main.dart` là điểm khởi chạy duy nhất. Lần đầu chưa có hồ sơ mở màn chào; tạo xong vào Trang chủ Tempo. Sau khi đóng/mở app, Trang chủ mở theo hồ sơ đã chọn gần nhất, kể cả khi có nhiều hồ sơ. Bấm nhạc cụ/ảnh hồ sơ ở góc trên phải để mở danh sách chọn. Cài đặt có nút Quản lý hồ sơ để thêm, đổi tên và xóa.

Để test lại lần mở đầu tiên, vào **Cài đặt → Xóa dữ liệu và bắt đầu lại** rồi xác nhận. Hồ sơ, lựa chọn và trạng thái UI được đặt lại, về màn chào; đóng/mở app vẫn giữ trạng thái trống. Bấm **Giữ dữ liệu** giữ nguyên hồ sơ. Nếu lưu/xóa lỗi, UI giữ trạng thái trước đó và cho thử lại.

`ProfilePreviewService` dùng bộ lưu snapshot được inject qua `ProfilePreviewStorage`. App cấp `SqliteProfilePreviewStorage` trong `app/lib/app/`; dữ liệu UI nằm trong database riêng `meloop_profile_ui_preview.db`, chưa phải service nghiệp vụ của Khanh. Thao tác chỉ báo thành công sau khi ghi xong; ghi lỗi khôi phục trạng thái trước đó. Các widget không gọi SQLite. Nhật ký của hồ sơ mới hiển thị trống; đổi hồ sơ chỉ đổi lựa chọn, không tạo buổi luyện hoặc hiện nhật ký minh họa của hồ sơ khác.

Trong Android Studio, mở thư mục `app/`, khởi động máy ảo bằng Device Manager và chọn tên máy ảo Android trên thanh công cụ trước khi Run. Windows không phải nền tảng được cấu hình trong dự án.

## Nối service hồ sơ cục bộ

`instrumentProfileServiceProvider` trong `app/lib/frontend/application/instrument_profile_service.dart` là ranh giới FE. App cần cấp implementation của service hồ sơ do Khanh làm qua `MeloopApp.overrides`. Các thao tác `load`, `create`, `rename`, `select`, `deletionImpact`, `delete` trả về dữ liệu đã commit; `create` nhận request ID ổn định cho lần thử lại. App truyền callback mở Home, xem Pro và mở buổi luyện chưa hoàn tất vào `InstrumentProfilesFeature`.

UI chỉ kiểm tra trường nhập và hiển thị giới hạn. Service phải kiểm tra lại tên trùng, giới hạn Free, trạng thái buổi luyện, tính bất biến loại nhạc cụ và giao dịch xóa. Service cũng phải trả số buổi luyện/bản ghi âm của hồ sơ cho xác nhận xóa; danh sách và thống kê ở các màn khác phải lọc theo profile ID đang chọn. Không dùng `ProfilePreviewService` cho bản phát hành.

## Kiểm chứng

```powershell
flutter test test/frontend/instrument_profiles_feature_test.dart
flutter test test/frontend/instrument_profiles_preview_test.dart
flutter test test/frontend/profile_preview_storage_test.dart
flutter test test/frontend/instrument_profiles_visual_test.dart
flutter analyze
flutter build apk --debug
```

Widget test kiểm tra tạo, đổi tên không đổi loại, giới hạn Free, xác nhận xóa, giữ form khi lỗi, đổi hồ sơ từ góc trên phải, khởi động lại và đặt lại dữ liệu. Test SQLite đóng/mở file để kiểm tra dữ liệu bền vững và lỗi ghi không tạo hồ sơ giả. Test hình ghi các màn hồ sơ, Trang chủ và Cài đặt dưới `app/build/ui-review/` để kiểm tra bố cục; không phải golden tự động.
