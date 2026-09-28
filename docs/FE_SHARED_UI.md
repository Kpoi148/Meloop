# Task 10 — Theme Tempo và UI dùng chung

Hướng dẫn FE/Wei. Widget nhận callback/controller qua constructor; không gọi SQLite, file hay audio trực tiếp.

## Nguồn và phạm vi

Đã đối chiếu README, AGENT_GUIDELINES, Report 1 và SRS Report 2, đặc biệt 5.2.2 và CR01–CR06. Nguồn thiết kế là prototype `meloop-tempo-html`: `style.css` cộng lớp ghi đè cuối `fidelity.css`. Bản tham chiếu công khai: [Tempo](https://huyth96.github.io/meloop-tempo-html/).

Font Be Vietnam Pro 400/500/600/700, đường SVG, hình mặt cảm xúc và minh họa gốc được đóng gói cục bộ. Giữ thiết kế ở chữ thường; chữ lớn chuyển hàng thành cột và cuộn. Logo giữ kích thước thương hiệu; nhãn, lỗi và nội dung theo text scale hệ thống.

Validation theo SRS: tên buổi luyện bắt buộc (100 code point), tên hồ sơ 50, nhạc cụ khác 40, ghi chú tùy chọn 2.000, BPM nguyên 40–240, thời lượng 1–86.400 giây. Prototype cũ cho tên trống và giới hạn khác nên các quy tắc này không được sao chép từ HTML.

Đây là thư viện UI và màn mẫu, chưa triển khai toàn bộ 23 luồng của prototype. Controller lưu trữ, đồng hồ, audio, purchase và draft recovery thuộc task tính năng. Entry point mặc định chỉ có màn chào; CTA chờ callback tạo hồ sơ. Dữ liệu giả và mô phỏng lỗi nằm riêng trong `main_showcase.dart`, không đưa vào production navigation.

## Chạy mẫu

Trong `app/`:

```powershell
flutter pub get
flutter run -t lib/main_showcase.dart
```

Trang chủ → Tạo buổi luyện → form lưu mẫu. Cài đặt → Bộ thành phần cho Wei / Xem màn chào / Xem form lưu. Bật “Mô phỏng lỗi ở lần lưu tiếp” để thử giữ input và lưu lại. Lưu mẫu có độ trễ cho phép quan sát khóa nút; không ghi nhật ký lên thiết bị.

## Tokens

Nguồn duy nhất: `app/lib/frontend/theme/tokens/tempo_tokens.dart`. `MeloopTheme.light` kết nối vào ThemeData, input, card, dialog và màu chọn.

| Nhóm | Giá trị chính |
| --- | --- |
| Màu | Paper `#fdfbf4`, Ink `#003442`, Teal `#004651`, Yellow `#ffcc43`, Orange `#c75c28` |
| Màu phụ | Muted `#5d7579`, Line `#dce2d9`, Soft `#e9eee3`, Error `#9a3627` |
| Font | Be Vietnam Pro; body 16/1.6, heading 35/1.16, section 23/1.3, nút 20/1.3 |
| Khoảng cách | 4, 8, 12, 16, 20, 24, 32; trang 20 ngang, 22 trên, 30 dưới |
| Bo góc | Input 12, chip 10, card 19, nút 20 |
| Kích thước | Nội dung tối đa 460; nút tối thiểu 57; vùng chạm 48; icon 24/25/26 |

Các tỷ lệ minh họa, chart và số liệu giả chỉ thuộc composition màn mẫu. Không khai báo lại bảng màu/font ở màn tính năng.

## API dùng chung

```dart
import 'package:meloop/frontend/components/meloop_ui.dart';
```

| Thành phần | Mục đích |
| --- | --- |
| `MeloopPage` | Trang cuộn, safe area, resize theo bàn phím; ẩn bottom nav khi nhập |
| `MeloopResponsiveRow`, `MeloopCard` | Hàng tự đổi thành cột; thẻ cùng theme |
| `MeloopButton` | Primary/yellow/outline/soft/orange/danger; disabled/loading; khóa Future |
| `MeloopField` | Text/multiline/integer/decimal/email/phone; required/optional; lỗi tại trường |
| `MeloopDateField` | Calendar 01/01/2000–hôm nay; không nhập chuỗi ngày tùy ý |
| `MeloopSearch` | Query và nút xóa thông báo lại cho consumer |
| `MeloopChoiceGroup<T>` | Chip/radio/tab lọc; một lựa chọn, có thể cho bỏ chọn |
| `MeloopSelect<T>` | Danh sách giới hạn, required và lỗi tại trường |
| `MeloopRating` | Cảm xúc/tập trung 1–5; mặt như prototype; bấm lại trả null |
| `MeloopToggle` | Switch/checkbox với nhãn dài xuống dòng |
| `showMeloopConfirm` | Xác nhận; khóa hủy/Back khi chạy; giữ dialog khi lỗi |
| `showMeloopSheet<T>` | Bottom sheet cuộn, safe area và inset bàn phím |
| `MeloopNotice`, `MeloopNotifications.show` | Info/success/error inline hoặc snackbar |
| `MeloopStateView` | Loading/empty/error riêng biệt; CTA phục hồi |
| `MeloopTopBar`, `MeloopBottomNavigation` | Điều hướng và nhãn theo Tempo |
| `MeloopIcon`, `MeloopArt`, `MeloopIllustration` | SVG, sprite nhạc cụ/công cụ và hình gốc |

`initialValue` là giá trị khởi tạo FormField, không phải controlled property. Đặt lại qua FormFieldState.didChange/reset hoặc key theo bản ghi đang sửa.

## Ví dụ cho Wei

Tạo/dispose TextEditingController, GlobalKey<FormState> trong State. Màn mẫu hoàn chỉnh là `SessionFormExample`: nhận Future lưu, báo lỗi, giữ input, khóa toàn form và xác nhận khi rời form bẩn.

```dart
MeloopField(
  label: 'Tên buổi luyện',
  controller: titleController,
  requirement: MeloopFieldRequirement.required,
  validator: MeloopValidation.title,
  enabled: !controller.isSaving,
)

MeloopButton(
  label: 'Lưu buổi luyện',
  icon: MeloopIcons.check,
  isLoading: controller.isSaving,
  onPressed: () async {
    if (!formKey.currentState!.validate()) return;
    await controller.save();
    if (context.mounted) {
      MeloopNotifications.show(context, 'Đã lưu buổi luyện.',
        kind: MeloopNoticeKind.success);
    }
  },
  onError: (error, stackTrace) {
    if (context.mounted) {
      MeloopNotifications.show(context,
        'Chưa thể lưu. Nội dung của bạn vẫn ở đây.',
        kind: MeloopNoticeKind.error);
    }
  },
)
```

**Phải await/return Future của thao tác thật.** Nếu gọi lưu rồi bỏ Future, khóa nút kết thúc sớm. Controller giữ `isSaving` cho toàn form; backend vẫn cần UUID ổn định, idempotency và kiểm tra trong transaction. Không xóa controller, đóng form hoặc hiện success khi lưu lỗi/chưa hoàn tất. Không ghi nhật ký/audio vào diagnostic log.

```dart
await showMeloopConfirm(
  context,
  title: 'Xóa buổi luyện?',
  message: 'Nhật ký và bản ghi âm của buổi này sẽ bị xóa.',
  confirmLabel: 'Xóa buổi luyện',
  cancelLabel: 'Giữ lại',
  destructive: true,
  onConfirm: () => controller.deleteSession(),
  failureMessage: 'Chưa thể xóa. Vui lòng thử lại.',
);
```

## Bố cục và trạng thái

- Nút có minHeight, không đặt height cứng cho chữ/lỗi. Không dùng ellipsis hay maxLines 1 để che lỗi.
- Form/nút lưu nằm trong MeloopPage. Không đặt Expanded trong Column của vùng cuộn. Hàng dài dùng MeloopResponsiveRow hoặc Flexible cho nhãn.
- Keyboard theo kiểu dữ liệu. Báo lỗi số nguyên thay vì âm thầm biến `80.5` thành `805`.
- Required có `*`, semantics đọc “bắt buộc”. Optional ghi “(tùy chọn)”; bỏ trống không chặn lưu.
- Lỗi và notice có live region. Empty không thay load error; lỗi có CTA phục hồi.
- Toàn bộ dialog, gồm nút, cuộn theo chiều cao còn lại. Sheet cộng inset bàn phím. Không khóa text scale nội dung.
- Nội dung mẫu là tiếng Việt. Material date picker hỗ trợ vi/en; bản dịch nội dung tính năng thuộc task localization.

## Kiểm chứng

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/shared_ui_smoke_test.dart -d emulator-5554
flutter build apk --debug -t lib/main_showcase.dart
```

Tests bao phủ validation Unicode/SRS, keyboard, xóa tìm kiếm, bỏ chọn, bấm đúp trước rebuild, lỗi lưu giữ input, lỗi dialog và retry. Ma trận màn mẫu: 320/390/460 px × chữ 1/2/3× × keyboard inset 0/300 px với safe area trên/dưới. Dialog/sheet: 320×640, chữ 3×, keyboard 0/280 px.

`showcase_visual_test.dart` dựng ảnh bằng font thật vào `app/build/ui-review/` để QA đối chiếu; không phải golden tự khẳng định khớp pixel. Smoke test Android kiểm tra IME, validation, lưu lỗi và retry. Kết quả bàn giao thực tế: `docs/FE_UI_VALIDATION.md`. Android Back bằng gesture và TalkBack cần kiểm tra thủ công; widget test không thay thế thiết bị.

App ID và debug signing hiện phục vụ phát triển, chưa là cấu hình phát hành Google Play.
