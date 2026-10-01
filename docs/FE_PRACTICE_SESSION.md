# Task 16 — Tạo buổi luyện và màn hình đếm giờ

Phần FE của UC-04 dùng bố cục `sessionSetup`, `timer` và `tools` trong prototype Tempo. Đã đọc README, hướng dẫn repository, Report 1 và SRS Report 2; áp dụng UC-04 trong Report 2 và yêu cầu task hiện tại. Không thêm bài tập, kế hoạch hay màn ghi lại buổi quá khứ.

## Luồng giao diện

- **Buổi luyện → icon + góc dưới phải** mở form tạo buổi. Nút nằm trong Scaffold phía trên bottom navigation, có tooltip và vùng chạm riêng; nội dung cuối trang chừa khoảng trống cho nút. Nút ẩn khi bàn phím mở.
- Nhập tên bắt buộc rồi **Bắt đầu luyện**. Chỉ rời form sau khi service hoàn tất Start; lỗi giữ tên và cho thử lại. Nếu service đã có buổi chưa lưu, mở buổi đó và không tạo ID mới.
- Màn đếm giờ hiển thị hồ sơ, tên buổi, thời gian và trạng thái từ service. Widget không tạo Timer, Stopwatch hoặc bộ đếm riêng. Tạm dừng, tiếp tục, đổi tên và hủy đều gọi service.
- **Công cụ** mở các thẻ theo prototype và chuyển cùng session ID cho tính năng công cụ. Việc mở/đóng route không reset hoặc kết thúc timer.
- Back về tab trước hoặc app vào nền gọi Pause. Khi trở lại phải bấm Tiếp tục. Back từ màn xem lại trả về buổi Paused với cùng ID.
- **Kết thúc** gọi Finish rồi mở form xem lại với tên, ngày bắt đầu và thời gian service trả về. Không tự nâng thời lượng 0 lên 1 giây; form báo lỗi để người dùng sửa.
- **Lưu buổi luyện** khóa gửi trùng, gọi Save bằng ID bản nháp cố định. Thành công mở chi tiết đã lưu và cập nhật danh sách Buổi luyện cùng thẻ buổi gần nhất ở Trang chủ. Chi tiết không có nút Tiếp tục/Kết thúc. Lỗi giữ nội dung, bản nháp và ID để thử lại.

## Ranh giới service

Contract thuần Dart nằm ở `app/lib/shared/practice/practice_session_service.dart`. `SessionFormValues` chuyển sang shared; đường import frontend cũ vẫn được re-export để tương thích. `PracticeSessionState` chứa một draft và danh sách đã lưu; FE chỉ chiếu snapshot vào shell để hiển thị và điều hướng.

Backend cần triển khai:

- `current` và stream `changes` đồng bộ sau mỗi thao tác/checkpoint.
- `start`, `pause`, `resume`, `finish`, `leaveReview`, `rename`, `discard` và `save(draftId, values)`.
- Start kiểm tra một buổi chưa lưu trên toàn ứng dụng, giữ nguyên hồ sơ gốc và trả ID ổn định. Save phải idempotent theo draft ID, commit trước khi trả kết quả và chỉ xóa draft sau thành công.
- Clock monotonic, checkpoint SQLite, khôi phục Paused sau restart, giữ trường review và xử lý lỗi lưu theo SRS. Pause/Finish/Discard chịu trách nhiệm dừng audio và xử lý bản ghi liên quan.

Cấp service thật ở composition qua `MeloopApp(practiceSessionService: service, home: ...)`. `practiceSessionServiceProvider` là port FE. Các route setup, review và tools giữ cùng ProviderScope của tính năng. `practiceToolOpenProvider` nhận callback mở tính năng công cụ với `(context, sessionId, tool)`.

## Phạm vi bản xem thử hiện tại

Repository chưa có implementation service nghiệp vụ UC-04. Entry hiện tại vẫn là bản FE xem thử: `InstrumentProfilePreview` cấp `PracticePreviewService`, timer dùng một Stopwatch monotonic, bản nháp và các buổi đã lưu chỉ ở bộ nhớ. Profile preview đã có bộ lưu SQLite riêng; adapter buổi luyện không ghi vào journal database và không giữ buổi qua process restart. Không dùng adapter này cho bản phát hành.

Adapter khóa Save đồng thời, dùng lại ID khi thử lại và khi nhận lại một request đã lưu. Callback lưu mặc định chưa cấu hình vẫn báo lỗi; entry profile preview cấp callback mô phỏng rõ ràng. Thẻ công cụ đã nối port; khi chưa cấp implementation audio, UI báo chưa khả dụng và giữ buổi luyện. Thống kê nghiệp vụ, persist review/draft, recording, permission và recovery thật thuộc backend/các task liên quan.

## Kiểm chứng

Chạy tại `app/`:

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/practice_session_smoke_test.dart -d <android-device>
flutter build apk --debug
```

`practice_session_feature_test.dart` kiểm tra service cập nhật từ bên ngoài, paused interval, lỗi Start/Save, review thời lượng 0, Back, lifecycle nền, cùng ID khi mở công cụ, lưu đồng thời/idempotent, đổi tên và xác nhận hủy. Kiểm tra bố cục 320/390/460 px với chữ 1×/3× và safe area; nút tạo nằm phía trên thanh điều hướng.

`practice_session_visual_test.dart` dựng ảnh với font Be Vietnam Pro và asset gốc tại `app/build/ui-review/practice-timer-390.png`, `practice-history-390.png` và `practice-tools-390.png`. Đã xem ảnh Flutter và đối chiếu thông số source CSS/asset prototype; chưa có golden baseline để khẳng định trùng từng pixel.

Kết quả ngày 01/10/2026: định dạng đạt; phân tích mã không có issue; toàn bộ 91 unit/widget tests đạt, trong đó có 14 tests UC-04. APK debug đã build thành công. `practice_session_smoke_test.dart` đạt trên Medium_Phone (`emulator-5554`, Android 15 / API 35), kiểm tra IME Android và toàn bộ luồng tạo → Pause → Resume → Finish → Review → Save. Smoke test dùng adapter bộ nhớ, không ghi dữ liệu người dùng. Chưa kiểm chứng service backend, lưu bền vững, audio hoặc TalkBack.

Trên môi trường Windows hiện tại, native-assets hook gặp lỗi khi SDK nằm ở đường dẫn có khoảng trắng. Lượt kiểm chứng sử dụng junction tạm tới SDK để chạy Flutter, không commit đường dẫn máy cá nhân hoặc thay cấu hình ứng dụng.
