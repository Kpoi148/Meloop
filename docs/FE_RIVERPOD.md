# Riverpod cho frontend Meloop

Frontend dùng `flutter_riverpod` 3.4.3, được ghi trong `app/pubspec.yaml` và `app/pubspec.lock`. Dùng provider viết tay, không cần code generation.

## Khởi tạo và dependency

`MeloopApp` bọc `MaterialApp` trong `ProviderScope`. Cấp các dependency bằng tham số `overrides` ở lúc khởi chạy; màn hình và các route dùng chung scope này.

`sessionFormSaveProvider` cung cấp callback `SessionFormSave`, có chữ ký:

```dart
Future<void> Function(SessionFormValues values)
```

Khi backend bàn giao, code khởi tạo app truyền callback thật:

```dart
MeloopApp(
  overrides: [
    sessionFormSaveProvider.overrideWithValue(saveSession),
  ],
  home: yourHomePage,
)
```

`saveSession` và `yourHomePage` là dependency/màn hình do tính năng cung cấp. Import provider từ `package:meloop/frontend/application/session_form_controller.dart` và kiểu dữ liệu từ `package:meloop/frontend/application/session_form_values.dart`. Callback phải trả Future hoàn tất đúng khi thao tác lưu hoàn tất; nếu lưu lỗi phải throw. Adapter tại app chuyển giá trị form sang model/backend contract do nhóm backend thống nhất. Không thêm SQLite hoặc nghiệp vụ vào widget/controller frontend.

Dependency lưu buổi luyện mặc định báo lỗi khi chưa được cấu hình. Entry `main.dart` nối form hồ sơ và Start draft vào SQLite journal thật qua `createJournalProfileApp()`; dữ liệu preview không tự nhập. `practiceStartServiceProvider` là port frontend được app cấp implementation BE, Setup chỉ gửi request/title và nhận thành công sau transaction. Shell giữ session ID/owner thật; timer production dùng PracticeTimerService để Pause/Resume và checkpoint thật; Finish/Save thuộc B06. Contract hồ sơ thuần Dart nằm trong `shared/profiles/`; provider frontend re-export để giữ import hiện có.

`InstrumentProfilePreview` cấp controller và dependency lưu buổi luyện mẫu trong một scope theo profile ID. Mô phỏng có độ trễ và bộ đếm lưu mẫu, không ghi nhật ký thật. `lib/main.dart` là điểm khởi chạy duy nhất. Chạy:

Entry journal hiện dùng `JournalProfileEntry` và `journalBootstrapLoaderProvider`. Loader được app cấp, trả directory/count và draft thật; widget không mở SQLite. Cold entry nhiều hồ sơ luôn mở picker, kể cả có selected ID; một hồ sơ mở Home; draft ưu tiên màn recovery. Đổi hồ sơ chỉ đổi browsing/selection, không thay profile ID của draft. Resume entry chỉ rõ tên hồ sơ sở hữu. Recovery mở draft vào engine app-scope, phục hồi Paused từ checkpoint; không cộng thời gian app đóng. Widget nhận snapshot stream, gửi Pause/Resume/Retry và pause khi Back. Lifecycle nằm trên điều hướng hồ sơ để background dừng interval. Review/Save triển khai ở B06. Preview độc lập vẫn có callback fake riêng.

```powershell
cd app
flutter pub get
flutter run
```

## Trạng thái giao diện

- `showcaseControllerProvider`: tab đang chọn, query lịch sử, cờ mô phỏng lỗi một lần và số lần lưu mẫu thành công. Widget theo dõi bằng `ref.watch`, gửi thao tác qua `ref.read(...notifier)`.
- `meloopShellControllerProvider`: điều hướng khởi động, các tab và buổi luyện mẫu đang mở. Luồng hồ sơ cấp snapshot từ hồ sơ đã chọn và override controller trong scope theo profile ID để không dùng lại trạng thái của hồ sơ trước.
- `sessionFormControllerProvider(formId)`: `AsyncValue<void>` của thao tác lưu, độc lập theo mỗi instance form. Provider tự giải phóng khi form đóng.
- Controller khóa đồng bộ trước khi await, giữ lỗi và stack trace trong state cho đến lần thử lại; không ghi dữ liệu form vào log. Widget hiển thị thông báo lỗi an toàn và giữ các ô nhập.
- Sau khi provider bị giải phóng, Future hoàn tất không ghi vào state hoặc yêu cầu đóng một màn khác.
- Ô nhập, focus, date/mood và validation tại trường vẫn là trạng thái cục bộ của widget. Không đưa mọi trạng thái widget dùng chung vào provider toàn cục.

`SessionFormExample` và `SetupExample` vẫn nhận callback `onSave` để các ví dụ component cũ hoạt động. Nếu truyền callback, callback đó được ưu tiên; nếu không, form nhận callback qua `sessionFormSaveProvider`. `SessionFormValues` vẫn được export từ file form để giữ tương thích import cũ.

## Kiểm chứng

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
```

Test mới kiểm tra callback qua override app được dùng trên route con, khóa gửi trùng, lỗi/thử lại, input còn nguyên khi lỗi, điều hướng chỉ sau khi lưu thành công, state độc lập giữa hai form, hoàn tất sau khi provider bị giải phóng, thiếu dependency không báo thành công và giữ tìm kiếm khi đổi tab. Bộ kiểm thử UI cũ vẫn được giữ.

Kết quả ngày 29/09/2026 trên Windows, Flutter 3.47.5 stable / Dart 3.13.4:

- Định dạng: 37 file, không cần thay đổi.
- Phân tích mã: không có issue.
- Toàn bộ unit/widget tests: 31 test đạt, gồm 22 test cũ và 9 test mới.
- Build APK debug của entry mặc định và entry showcase thời điểm đó: đều thành công. Entry showcase riêng đã được gỡ ngày 01/10/2026; hiện chạy bằng `lib/main.dart`.
- Chưa chạy lại integration test trên emulator hoặc máy Android thật trong lượt tích hợp này. Build debug không xác nhận backend lưu trữ hoặc cấu hình release.

Khi kiểm tra tìm kiếm thủ công, đóng bàn phím bằng Back Android trước khi đổi tab: `MeloopPage` ẩn bottom navigation khi bàn phím mở. Từ khóa vẫn được giữ sau khi đóng bàn phím và chuyển tab.

Trong lần thử thủ công trên Medium_Phone ngày 29/09, log ghi nhận ANR do input timeout ở cả Meloop và System UI. Chưa xác định nguyên nhân; cần kiểm tra lại trên máy ảo khởi động sạch và thiết bị thật trước khi kết luận về hiệu năng.

Tài liệu API: [Providers](https://riverpod.dev/docs/concepts2/providers), [Provider overrides](https://riverpod.dev/docs/concepts2/overrides), [Refs](https://riverpod.dev/docs/concepts2/refs).
Cập nhật Finish cho FE: nút Kết thúc journal đã mở để vào SessionFormExample hiện có. Trước khi mở form, Pause ghi checkpoint; lỗi giữ màn timer/Retry, pending khóa thao tác trùng. Form nhận session ID và measured duration thật; dữ liệu draft bền vững vẫn Paused. Đây là mở điều hướng UI để FE điều chỉnh; chuyển Review bền vững, lưu input và Save session còn B06. Không fake Save; đóng/mở app quay về checkpoint Paused, không hứa phục hồi input form.


## Tích hợp UC-04

Review/Save đã nối SQLite journal thật qua `PracticeReviewService`. Finish ghi Review bằng timer service, Save cập nhật cùng session ID và trả bản lưu đầu tiên khi retry. Save thành công mở chi tiết, xóa draft và cho phép Start buổi tiếp theo. Phần mô tả B04/B05 phía trên là mốc lịch sử; chi tiết trạng thái hiện tại ở `docs/FE_PRACTICE_SESSION.md`. Các công cụ audio/metronome/tuner vẫn dùng port riêng; form chưa autosave nội dung trước Save.
