# UI Showcase & Examples

Màn hình mẫu (Catalog) trưng bày và cung cấp ví dụ sử dụng thực tế cho toàn bộ theme, tokens và shared components.

Các thành viên phát triển màn hình tính năng tham khảo tại đây để tái sử dụng đúng thành phần chuẩn thay vì tự viết lại.

`main_pitch_preview.dart` là entry xem thử UC-09 riêng, dùng đúng `PitchRoute`/`PitchPage` với bộ chọn bảy trạng thái. Có nhãn dữ liệu mô phỏng, không dùng micro hoặc journal; chạy với app ID suffix `.pitchpreview`. Hướng dẫn: [`../../../../docs/FE_PITCH_UI.md`](../../../../docs/FE_PITCH_UI.md).

Chạy `flutter run` tại `app/`, hoặc chọn cấu hình `main.dart` trong Android Studio. Lần đầu vào màn chào, tạo hồ sơ xong vào Trang chủ; hồ sơ và lựa chọn được lưu cục bộ qua lần mở app. Bấm góc trên phải để đổi hồ sơ; trong Cài đặt có Quản lý hồ sơ và Xóa dữ liệu và bắt đầu lại. Nhật ký và buổi luyện mẫu vẫn chỉ phục vụ phát triển UI. `SessionFormExample` nhận callback lưu để nối controller.

Hướng dẫn cho Wei: [`../../../../docs/FE_SHARED_UI.md`](../../../../docs/FE_SHARED_UI.md).
