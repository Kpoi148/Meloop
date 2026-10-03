# UC-14 — Giao diện Tiến độ

Đối chiếu `views.progress`, `ratingWide`, `ratingBars` trong prototype Tempo HTML và cascade `style.css` + `fidelity.css`.

`app/lib/frontend/progress/` chứa giao diện, design tokens và adapter trình bày. Tab Tiến độ có tiêu đề/ảnh gốc, thẻ thời gian và số buổi, chuỗi ngày/mục tiêu tuần, hai biểu đồ đánh giá, chú thích và hai hàng cuối theo prototype. Hàng Lịch sử mở tab Buổi luyện đã có; hàng Điều chỉnh mục tiêu giữ bố cục và chưa gắn hành động vì màn mục tiêu ngoài phạm vi UC-14.

Bộ lọc Pro mở một popup giữa tab Tiến độ, dùng nền kem, màu teal/vàng, font Be Vietnam Pro và ảnh gốc Tempo ở góc phải trên. Popup có nhãn Meloop Pro, hồ sơ đang xem, lựa chọn nhanh 7 ngày/30 ngày/tháng này/tùy chọn, hai ô ngày biên và nút “Xem tiến độ” cố định phía dưới. Nhấn Tùy chọn hoặc ô ngày biên sẽ mở lịch theo tháng trong cùng popup; không mở thêm màn hình hay bộ chọn ngày thứ hai. Khoảng đã chọn được tô nền, ngày tương lai bị vô hiệu; thay đổi chỉ áp dụng khi nhấn nút. Nhấn dấu đóng, vùng ngoài popup hoặc Back giữ nguyên khoảng trước đó. Khi chữ lớn, các ô ngày xếp dọc và nội dung cuộn để giữ nút xác nhận đọc được.

`PracticeProgressPage` nhận `isPro` và `onViewPro` từ shell hiện có; `JournalProfileEntry` truyền trạng thái Pro từ directory đã tải. Bản Free vẫn xem 7 ngày gần nhất; nhấn Lọc mở popup giới thiệu Pro cùng phong cách và gọi luồng xem Pro đã có. Không thêm màn mua hàng hoặc backend entitlement. Entry duyệt Tiến độ cấp `isPro: true` trong showcase để kiểm tra giao diện trả phí.

Tổng thời gian, số buổi và cả hai biểu đồ dùng chung hồ sơ/khoảng ngày, tính cả hai ngày biên. Chuỗi ngày và mục tiêu tuần vẫn phản ánh lịch sử/tuần hiện tại đúng ý nghĩa nhãn. Khoảng dài cho phép cuộn ngang để giữ số liệu đọc được. Có nút trở lại 7 ngày gần nhất.

Tab trong `main.dart` đọc nguồn buổi đã lưu và mục tiêu có sẵn. Provider theo dõi việc nguồn được refresh sau thêm/sửa/xóa/khôi phục; không thêm backend, ghi dữ liệu hoặc triển khai mua Pro. Đánh giá null không tham gia trung bình, không vẽ cột; ngày thiếu đánh giá hiện `—` và mô tả tương ứng cho trình đọc màn hình. Không có buổi trong khoảng đã chọn thì hiện trạng thái trống. Chữ lớn chuyển các khối sang chiều dọc.

Để duyệt ngay bố cục có số liệu, chạy từ `app/`:

```powershell
flutter run -t lib/main_progress_preview.dart --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.progresspreview
```

Entry riêng này dùng `showcase/progress_examples.dart` trong bộ nhớ và mở trực tiếp Tiến độ; không đọc/ghi nhật ký thiết bị. Package suffix có sẵn trong cấu hình Gradle giúp chạy song song với app chính. Giao diện không thêm nhãn mô phỏng. `main.dart` vẫn là entry ứng dụng.

Kiểm tra:

```powershell
flutter analyze
flutter test test/frontend/progress_ui_test.dart test/frontend/progress_visual_test.dart test/frontend/journal_profile_entry_test.dart test/frontend/home_overview_test.dart test/frontend/pro_preview_test.dart
flutter build apk --debug
```

Test visual tải font Be Vietnam Pro và ảnh gốc, xuất ảnh vào `app/build/ui-review/flutter-progress-{320,390,460}.png`, `flutter-progress-filter-popup-{320,390,460}.png` và `flutter-progress-filter-popup-custom-{320,390,460}.png`. Test UI kiểm tra ngày biên, nhiều đánh giá cùng ngày, null, đổi khoảng ngày, refresh sau thay đổi nguồn, mô tả accessibility và chữ phóng to 3 lần trong tiếng Việt/Anh. Popup lọc được kiểm tra thêm quyền Pro từ journal entry, áp dụng đồng bộ mọi biểu đồ, hủy bằng vùng ngoài, khoảng qua hai tháng và ngày tương lai. Không yêu cầu backend mới cho UC-14.

Đã đối chiếu ảnh tab Tiến độ với HTML và duyệt ảnh bảng lọc ở 320/390/460 px. Trong lần chạy Android trước, package `.progresspreview` khởi chạy và có cây accessibility trên emulator; ảnh chụp màn hình ra đen nên phần trực quan được kiểm chứng bằng ảnh widget. Chưa xác định nguyên nhân của ảnh đen, không thay cấu hình renderer trong repository.

Kiểm chứng sau khi đổi sang popup: analyze sạch; 30 test trong năm file trên đã qua; APK debug cho entry chính và entry Tiến độ đều build thành công. Đã cập nhật cả hai package trên `emulator-5554` bằng `adb install -r`, không xóa dữ liệu ứng dụng. Ảnh popup thường và khoảng tùy chọn được kiểm chứng bằng widget; ảnh native trên emulator vẫn đen, chưa xác nhận thao tác mở popup bằng điều khiển ADB.
