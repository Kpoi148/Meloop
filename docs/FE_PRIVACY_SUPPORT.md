# Task 44 — FE Lộc — Quyền riêng tư và liên hệ hỗ trợ (UC-21/22)

Màn riêng tư và hỗ trợ được chuyển từ prototype Tempo sang Flutter Android. Giữ font, màu, hình cuốn sách/phong bì, năm mục mở/thu gọn và bố cục form của prototype. Chuỗi giao diện nằm trong `app_vi.arb` và `app_en.arb`; kích thước riêng của hai màn nằm trong `frontend/support/contact_tokens.dart`.

## Luồng sử dụng

- Cài đặt → Quyền riêng tư: đọc thông tin của phiên bản Android, đổi Việt/Anh, mở đúng URL tương ứng khi đã cấu hình. Khi mở liên kết lỗi, giữ nội dung trên màn và cho thử lại/sao chép URL. Màn Pro cũng mở được trang riêng tư; Back giữ màn trước.
- Cài đặt → Liên hệ hỗ trợ: nhập tiêu đề và nội dung tùy chọn → Xem trước nội dung → Sửa nội dung hoặc Soạn email. Meloop chỉ mở bản nháp trong ứng dụng email; không xác nhận rằng thư đã được gửi.
- Kèm thông tin kỹ thuật luôn mặc định tắt khi mở form mới. Chỉ lúc người dùng chọn rồi bấm Xem trước mới đọc phiên bản app, phiên bản Android và mẫu thiết bị. Màn xem trước hiển thị chính xác phần sẽ chuyển sang email. Quay lại bỏ chọn tạo bản nháp mới không có chẩn đoán.
- Thiếu hoặc lỗi ứng dụng email: giữ nguyên bản nháp, cho sao chép địa chỉ và nội dung. Sao chép là thao tác chủ động; lỗi clipboard được thông báo và văn bản vẫn có thể chọn thủ công.
- Không đọc SQLite, nhật ký, file audio, crash log, ID thiết bị hoặc thông tin giao dịch. Không có attachment, mạng gửi email hoặc API tự gửi. Nội dung form chỉ tồn tại trong bộ nhớ màn, không lưu vào journal/backup/log.

Nội dung hỗ trợ cho phép trống, giới hạn 2.000 Unicode code point và dùng quy tắc ký tự điều khiển của notes trong SRS. Tiêu đề bắt buộc, giới hạn 160 code point theo prototype. Form giữ input khi đọc chẩn đoán thất bại; có thể thử lại hoặc bỏ chọn. Các màn cuộn và thích ứng với chữ lớn/bàn phím.

## Ranh giới và cấu hình PM

`shared/support/` định nghĩa `ContactConfiguration`, bản nháp, ba trường kỹ thuật và `ContactPlatform`. FE dùng controller/provider; app cấp dependency tại `app/contact_dependencies.dart`. `backend/support/AndroidContactPlatform` nối clipboard và Android qua channel; `ContactSupportChannel.kt` chỉ mở `ACTION_VIEW`/`ACTION_SENDTO` hoặc đọc ba trường kỹ thuật. `mailto:` mã hóa tiêu đề/nội dung và truyền cùng các email extras, không cấp quyền đọc file.

Ba giá trị cấu hình bản phát hành:

| Khóa | Giá trị PM cần cung cấp |
| --- | --- |
| `MELOOP_PRIVACY_URL_VI` | URL HTTPS chính sách tiếng Việt |
| `MELOOP_PRIVACY_URL_EN` | URL HTTPS chính sách tiếng Anh |
| `MELOOP_SUPPORT_EMAIL` | Một địa chỉ email hỗ trợ chính thức |

Dùng `--dart-define` hoặc `--dart-define-from-file` khi chạy/build; không chỉnh URL/email trong widget, không lấy email cá nhân làm mặc định. URL phải là HTTPS có host, không có userinfo/khoảng trắng. Hai ngôn ngữ không tự thay thế URL cho nhau. Có thể dùng cùng URL cho cả hai nếu PM cung cấp một trang hỗ trợ song ngữ. App từ chối khởi chạy ở release mode khi thiếu/sai một trong ba giá trị; đây là kiểm tra khi khởi tạo, không phải chứng nhận nội dung chính sách hoặc kiểm tra URL còn hoạt động.

Ngày 03/10/2026 người dùng xác nhận PM chưa cung cấp URL/email. Debug hiển thị trạng thái chưa công bố, vẫn đọc phần giải thích và soạn/xem trước/sao chép nội dung; nút Soạn email bị vô hiệu hóa khi chưa có địa chỉ. Không có địa chỉ hoặc URL mẫu trong luồng thật. Các giá trị `example.invalid` chỉ dùng trong test.

Nội dung năm mục là lời giải thích về phiên bản hiện tại, không được trình bày như chính sách chính thức đã duyệt. Task hiện tại cho phép mở chính sách bằng liên kết. SRS còn yêu cầu bản chính sách chính thức offline với ngày hiệu lực; chưa có nội dung PM nên chưa bundle được bản này. Trước phát hành cần PM cung cấp nội dung đã duyệt, ngày hiệu lực, URL/email thật, rồi kiểm tra khớp URL và khả năng đọc chính sách chính thức offline nếu giữ yêu cầu SRS đó.

## Kiểm chứng

- `flutter analyze`: không có issue.
- Toàn bộ 224 unit/widget test đã qua; sau chỉnh UI và thêm kiểm tra điều hướng, chạy lại riêng 18 test task 44 đều qua: URL Việt/Anh, mở liên kết lỗi, chẩn đoán opt-in/bỏ chọn, xem trước trước khi mở email, giữ input khi lỗi, sao chép khi không có email app, lỗi clipboard, dispose và giới hạn Unicode.
- `contact_visual_test.dart`: ảnh QA với font Be Vietnam Pro và PNG gốc; kiểm tra ba màn ở 320/390/460 px, chữ 1×/3×, Việt/Anh, safe area và bàn phím. Ảnh sinh tại `app/build/ui-review/privacy-390.png`, `support-390.png`, `support-draft-390.png`.
- `contact_support_smoke_test.dart`: 1 test đã qua trên emulator Android 15 / API 35 với app ID suffix `.supportqa`; chỉ dùng nội dung giả, đọc metadata khi đã chọn và mở bản nháp. Không gửi thư, không truy cập database của ứng dụng đang dùng.
- `flutter build apk --debug -t lib/main.dart`: đã tạo APK debug thành công.

Chạy trong `app/`:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/contact_support_smoke_test.dart -d emulator-5554 --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.supportqa
flutter build apk --debug
```

Trên Windows, hook native assets của SQLite trong bộ test có thể lỗi nếu Flutter SDK nằm trong đường dẫn có khoảng trắng. Lần kiểm chứng này dùng một ánh xạ ổ đĩa tạm tới SDK để chạy, không thay dependency hoặc bỏ test.

Chưa thể nghiệm thu URL/email chính thức khi PM chưa cung cấp. Máy ảo có Gmail; trường hợp không có email app kiểm tra bằng fake platform ở widget tests. Chưa kiểm tra tài khoản email thật, việc gửi thư, TalkBack và gesture Back thủ công. Android intent theo [tài liệu Android](https://developer.android.com/guide/components/intents-common#Email); Dart adapter theo [tài liệu Flutter MethodChannel](https://api.flutter.dev/flutter/services/MethodChannel-class.html).
