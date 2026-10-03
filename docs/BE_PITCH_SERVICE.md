# UC-09 — Hướng dẫn backend nối service kiểm tra cao độ

Tài liệu bàn giao từ FE task 29. Backend ở đây chạy cục bộ trong app Android, xử lý quyền thiết bị và phân tích âm thanh. UI đã có; adapter đo cao độ thật chưa được triển khai. Bản `main_pitch_preview.dart` chỉ dùng dữ liệu mô phỏng để duyệt UI, không phải bằng chứng đã nhận âm thanh hoặc giải phóng micro thật.

## 1. Điểm nối và phạm vi

| File | Trách nhiệm hiện có |
| --- | --- |
| [`../app/lib/shared/pitch/pitch_service.dart`](../app/lib/shared/pitch/pitch_service.dart) | Contract `PitchService`, enum và snapshot dùng chung. |
| [`../app/lib/frontend/pitch/pitch_route.dart`](../app/lib/frontend/pitch/pitch_route.dart) | `pitchServiceProvider`, điều hướng và vòng đời màn hình. Provider mặc định là `null`. |
| [`../app/lib/frontend/pitch/pitch_controller.dart`](../app/lib/frontend/pitch/pitch_controller.dart) | Gửi Start/Stop/settings, xóa kết quả và chặn event muộn. |
| [`../app/lib/frontend/pitch/pitch_page.dart`](../app/lib/frontend/pitch/pitch_page.dart) | Hiển thị snapshot bằng chuỗi localization; không phân tích audio. |
| [`../app/lib/app/profile_preview_app.dart`](../app/lib/app/profile_preview_app.dart) | `createJournalProfileApp(overrides: ...)` là composition của entry chính. |

Đặt implementation trong `app/lib/backend/` theo trách nhiệm audio/cao độ; đặt provider khởi tạo và quản lý dependency trong `app/lib/app/`. Tên/lớp adapter cụ thể do BE chọn; hiện chưa có `AndroidPitchService` hoặc bộ phân xử micro chung. Dùng contract shared, không đưa SDK vào widget hoặc tạo HTTP/server.

Nối instance thật vào app bằng override hiện có:

```dart
// pitchService là instance BE đã khởi tạo và quản lý vòng đời ở lớp app.
createJournalProfileApp(
  overrides: [
    pitchServiceProvider.overrideWithValue(pitchService),
  ],
);
```

Ví dụ chỉ thể hiện điểm nối, không phải implementation hoàn chỉnh. Giữ các override khác khi tích hợp; không override bằng `PitchPreviewService` trong entry chính. Provider được route đọc một lần khi mở, nên phải có adapter trước khi mở màn. Đóng route chỉ Stop, không đóng vĩnh viễn service dùng chung; phải mở lại và Start được. App quản lý việc hủy adapter/stream khi scope kết thúc, vì `PitchService` hiện không có phương thức `dispose`.

UC-09 không tạo bản ghi âm, ghi journal, đổi session ID, lưu/hoàn tất buổi luyện hoặc gửi audio ra mạng. Quyền micro bị từ chối không được làm bootstrap journal thất bại. Phân tích trong bộ nhớ, không lưu audio hay nội dung nhật ký vào diagnostic log.

## 2. Dữ liệu gửi cho FE

`snapshot` phải luôn là trạng thái mới nhất, cập nhật trước khi phát qua `changes`. Stream phải cho phép controller của route mới đăng ký lại sau khi route trước hủy subscription; dùng broadcast khi service được chia sẻ. Không dùng việc kết thúc stream để biểu diễn tạm thời mất tín hiệu.

`PitchConfiguration` cung cấp `lowestNote`, `highestNote`, `referenceNote`, `referenceHz`. Mặc định tập trung trong `PitchConfiguration.standard` là C2–C6, A4 = 440 Hz. Nếu khả năng thực tế hoặc cấu hình runtime khác, gửi cấu hình đúng thay vì để UI hứa khoảng nốt không hỗ trợ. Ngưỡng tín hiệu, độ ổn định, ngưỡng đúng cao độ và cấu hình xử lý thuộc BE, phải có constant/config có tên và đơn vị; FE không tự đặt ngưỡng.

`PitchReading` gồm tên nốt `note`, tần số đo `frequencyHz`, sai lệch `cents` và `PitchDirection.low/inTune/high`. Tên nốt không rỗng, Hz phải hữu hạn và lớn hơn 0, cent phải hữu hạn. Cent âm là thấp, dương là cao; BE phân loại direction theo cấu hình. Gửi enum/dữ liệu, không gửi chuỗi thông báo UI. FE hiển thị Hz một chữ số thập phân, cent làm tròn; thước giới hạn hiển thị −50…+50 cent không phải ngưỡng phân loại của BE.

| `PitchPhase` | Khi nào BE gửi | UI hiện có |
| --- | --- | --- |
| `idle` | Chưa Start hoặc đã Stop thành công; không có sample. | Dấu trống, chưa có tín hiệu, Bật micro. |
| `requestingPermission` | Đang chờ kết quả xin quyền sau thao tác Start. | Đang xin quyền; có thể yêu cầu Stop. |
| `listening` | Capture đã bắt đầu, đang chờ âm thanh đủ điều kiện. | Đang lắng nghe, không có nốt/kim. |
| `weakSignal` | Có tín hiệu nhưng không đủ chất lượng/ổn định để nhận một nốt. | Báo tín hiệu yếu và cách thử lại, không có nốt/kim. |
| `detected` | Có một `PitchReading` hợp lệ của lượt nghe hiện tại. | Nốt, Hz, cent, kim và chỉ báo thấp/đúng/cao. |
| `permissionDenied` | Quyền bị từ chối, còn đường xin lại theo API quyền được dùng. | Thông báo, Bật micro để thử lại, Mở cài đặt và hướng dẫn thủ công. |
| `permissionBlocked` | Quyền bị chặn, cần người dùng xử lý trong cài đặt. | Hướng dẫn quyền micro, Mở cài đặt; Back vẫn dùng được. |
| `unavailable` | Thiết bị/adapter không hỗ trợ hoặc micro không dùng được. | Chưa khả dụng; có thể quay lại luyện và lưu nhật ký. |
| `audioBusy` | Không thể lấy quyền sử dụng nguồn audio vì đang có tác vụ khác. | Báo audio đang bận, cho thử lại. |
| `failed` | Capture/phân tích gặp lỗi, đã xử lý tài nguyên của lượt nghe đó. | Báo lỗi, cho thử lại, không giữ kết quả đo. |
| `stopFailed` | FE controller đặt khi lời gọi `stop()` thất bại. | Xóa kết quả, thử Tắt micro lại; chưa cho rời màn như đã dừng thành công. |

Khi mất tín hiệu sau `detected`, gửi `weakSignal` hoặc `listening` với `sample: null` ngay theo chính sách mất tín hiệu của BE; không giữ nốt cuối như kết quả đang đo. `PitchSnapshot.reading` chỉ trả sample hợp lệ ở `detected`; controller chuyển detected thiếu/không hợp lệ thành weakSignal để bảo vệ UI. BE vẫn phải kiểm tra dữ liệu trước khi gửi.

## 3. Hợp đồng Start/Stop và quyền micro

`start()` chỉ xin quyền và lấy micro sau thao tác **Bật micro**. Không tự nghe lúc bootstrap, mở màn hoặc trở về từ background/settings. Future của Start hoàn tất sau khi xử lý quyền và khởi động capture, hoặc xác định trạng thái không thể bắt đầu; không giữ Future chờ suốt phiên đo. Sau đó kết quả liên tục đi qua `changes`. Các tình huống dự kiến như denied/blocked/audioBusy nên được biểu diễn bằng phase; exception bất ngờ sẽ được FE chuyển thành failed và gọi Stop để giải phóng tài nguyên.

Backend cần bổ sung cấu hình quyền micro Android phù hợp với SDK/adapter được chọn; manifest chính hiện chưa khai báo quyền thu âm. Ánh xạ quyền thật sang denied/blocked, không lấy trạng thái giả từ showcase. `openAppSettings()` mở phần cài đặt của đúng application ID runtime, trả `true` nếu mở thành công, `false` nếu không thể mở. FE đã có hướng dẫn thủ công khi trả false hoặc throw. Khi người dùng trở lại, kiểm tra quyền lại ở lần Start tiếp theo; không tự bật micro.

`stop()` phải **idempotent**: gọi nhiều lần, trước Start, trong lúc xin quyền hoặc sau Stop đều an toàn. Chỉ hoàn tất bình thường khi capture đã dừng, callback/subscription của lượt nghe đã bị vô hiệu hóa và quyền sở hữu micro đã được trả. Khi không thể xác nhận đã dừng, phải **throw** để controller hiển thị `stopFailed` và giữ đường retry. Chỉ phát phase stopFailed rồi trả thành công không đủ: điều hướng dựa vào kết quả lời gọi Stop.

Hủy Start đang chờ quyền bằng token/thế hệ của lượt nghe hoặc cơ chế tương đương. Stop phải làm Future Start đang chờ kết thúc được, không treo cho đến khi người dùng trả lời hộp quyền. Callback cấp quyền đến sau Stop không được khởi động lại capture. Không tổ chức khóa/hàng đợi khiến Stop chờ Start trong khi Start lại cần Stop hoàn tất. Controller gọi Stop lần nữa sau khi Start đang chờ kết thúc để bảo vệ race này; adapter phải chịu được việc đó và không phát sample của lượt cũ vào lượt mới.

Khi đã vào denied/blocked/unavailable/audioBusy/failed, adapter không giữ micro hoặc tác vụ capture chạy ngầm. Nếu có lỗi capture thật sự, giải phóng tài nguyên và báo lỗi có ngữ cảnh, không nuốt lỗi rồi báo dừng thành công. Trường hợp không giải phóng được phải đi qua Stop thất bại/retry.

Nếu có ghi âm hoặc công cụ audio khác, BE phân xử quyền sử dụng tài nguyên ở tầng audio. Không chiếm hoặc dừng tác vụ khác một cách âm thầm; gửi audioBusy khi không thể bắt đầu. Chưa có coordinator audio thật trong phần UC-09 đã bàn giao.

## 4. Vòng đời FE đã xử lý

- **Tắt micro:** xóa nốt/kim ngay, khóa thao tác bật trong lúc chờ Stop; Stop lỗi hiển thị retry.
- **Back trên UI, Back Android hoặc Trang chủ:** chờ Stop thành công rồi rời màn. Back giữ đúng nơi đã mở công cụ và không sửa timer/session; Trang chủ dùng hành vi tạm dừng buổi luyện hiện có.
- **hidden/paused/detached:** gọi Stop. **resumed** không tự Start. **inactive** riêng lẻ không gọi Stop để tránh hủy popup xin quyền.
- **Route dispose ngoài luồng Back:** gọi Stop và hủy subscription, không thể chờ điều hướng; adapter vẫn phải hoàn thành giải phóng tài nguyên dù route đã mất.

FE bỏ event sau Stop nhưng không thể tự dừng micro vật lý thay BE. Mỗi lần Start mới phải có dữ liệu của lượt mới; không gửi snapshot detected cũ khi mở lại.

## 5. Kiểm tra trước khi bàn giao BE

Kiểm thử adapter với nguồn audio/quyền giả để kiểm tra Start/Stop lặp, Stop khi đang xin quyền, callback đến muộn sau Stop và sau Start mới, mất tín hiệu sau khi nhận nốt, lỗi capture/Stop, retry Stop và tranh chấp audio. Dữ liệu test chỉ nằm trong test/showcase.

Sau đó kiểm tra trên Android với adapter thật, ghi rõ thiết bị/API và kết quả thực tế:

1. Mở từ Home và buổi luyện: không xin quyền hoặc nghe trước khi bấm Bật micro.
2. Cho phép quyền: UI đi qua đang nghe, nhận nốt với Hz/cent/direction phù hợp; giảm hoặc ngừng âm thanh chuyển sang chưa đủ tín hiệu/chờ và xóa kết quả cũ.
3. Từ chối rồi chặn quyền: đúng thông báo, retry/settings/manual guide hoạt động. Quay lại vẫn thao tác và lưu nhật ký được.
4. Stop, Back, Trang chủ và đưa app xuống nền: xác nhận capture dừng và micro được trả bằng quan sát/plugin/device thực tế. Không chỉ kiểm tra nút hoặc kim đã biến mất.
5. Rời khi đang xin quyền, sau đó cấp quyền muộn: không tự nghe lại. Mở lại hoặc resume vẫn chờ Bật micro.
6. Buổi luyện có sẵn: Back giữ session ID và thời gian; Trang chủ giữ draft theo hành vi timer. Không tạo, xóa hoặc đổi dữ liệu nhật ký do đo cao độ.
7. Có công cụ audio cạnh tranh và lỗi giải phóng: audioBusy/stopFailed có đường retry; không giữ nốt như đang đo, không báo thành công giả.

Chạy lại kiểm tra FE liên quan tại `app/` sau khi nối DI:

```text
flutter analyze --no-pub
flutter test --no-pub test/frontend/pitch_controller_test.dart test/frontend/pitch_ui_test.dart test/frontend/pitch_preview_test.dart test/frontend/practice_timer_ui_test.dart test/frontend/journal_practice_save_flow_test.dart
```

Các test/smoke của showcase vẫn dùng service mô phỏng; phải bổ sung kiểm thử adapter và Android thật để nghiệm thu audio. Hướng dẫn xem thử UI và kết quả FE hiện có: [`FE_PITCH_UI.md`](FE_PITCH_UI.md). Không dùng bản `.pitchpreview` để kết luận quyền hoặc microphone thật đã đạt.
