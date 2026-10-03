# B07.1 — Thống kê Home dùng chung

Phần backend cung cấp phép tính và reader thống kê cho Home. Bố cục, tab Progress, buổi gần nhất và UI đánh giá thuộc phần frontend mô tả trong `FE_HOME.md`; form mục tiêu và bộ lọc 30 ngày/All thuộc task khác.

`shared/journal/practice_statistics.dart` giữ phép tính thuần Dart; `PracticeSessionSummary` chỉ chuyển dữ liệu UI sang contract này. Home truyền selected profile ID rõ ràng. `SqlitePracticeStatisticsReader` đọc Saved chưa xóa của đúng hồ sơ qua reader hiện có; app cấp `journalStatisticsReaderProvider`. Reader không ghi dữ liệu hoặc lưu tổng trùng trong schema.

SRS UC-14/BR11: biểu đồ và tổng Home là 7 ngày lịch gần nhất kể cả hôm nay; cộng giây trước khi định dạng phút. Streak xét toàn bộ lịch sử, kết thúc hôm nay hoặc hôm qua. Một ngày hợp lệ có ít nhất một buổi >=60 giây; nhiều buổi ngắn không được gộp để đạt ngưỡng. Mục tiêu tuần xét Thứ Hai đến hôm nay, độc lập khoảng biểu đồ. Loại nháp, hồ sơ khác và ngày tương lai; dùng practiceDate và đồng hồ device-local, không lấy ngày UTC từ timestamp. Ngày trước giới hạn practiceDate vẫn được dùng làm nhãn biểu đồ nếu cửa sổ vượt mốc đầu năm 2000.

Home loading/error/retry, goal reader, buổi gần nhất và UI Progress đã được tích hợp với calculator shared. `practiceOverviewProvider` truyền selected profile ID vào adapter; tổng/thời lượng/streak/qualifying days dùng `PracticeStatistics`, còn latest/rating dùng cùng danh sách Saved đã lọc theo hồ sơ và ngày. Home và Progress nhận cùng overview, không đọc thêm một bản thống kê riêng hoặc sao chép quy tắc tính ở frontend. Weekly goal vẫn tắt mặc định, không tự bật/chỉnh target.

Kiểm thử: `practice_statistics_test.dart` kiểm tra tổng giây, ngưỡng từng buổi, owner/state/future, tuần so với rolling chart, streak dài qua cửa sổ, ranh giới năm/nhuận và empty. `practice_statistics_reader_test.dart` và `integration_test/practice_statistics_smoke_test.dart` dùng cùng hành trình SQLite thật: Saved + Review + hồ sơ khác, không ghi source khi đọc, Edit 60→30, Save thêm 30, Delete, empty và lỗi đọc sau đóng connection. UI adapter có test selected profile; suite Save/Edit/Delete hiện có bảo vệ refresh Home.

Android smoke dùng package `.qa` và database UUID riêng:

```powershell
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/practice_statistics_smoke_test.dart -d <device-id>
```

Smoke trên xác minh tính toán/SQLite. Hành trình Home và Progress được kiểm tra thêm trong `home_overview_smoke_test.dart`; xem `FE_HOME.md`.

## Nghiệm thu Home sau khi FE merge

Main `da650f6` đã có PR #30 (Home/Progress) và PR #32 (calculator BE). Không cần nối lại hoặc thay UI: production cấp Saved reader và weekly goal reader từ SQLite, hai tab dùng cùng overview; Save/Edit/Delete invalidate dữ liệu, mở lại app invalidate cả session/goal/ngày lịch.

`home_overview_test.dart` bổ sung tình huống đổi hồ sơ khi session và goal của hồ sơ cũ còn đang tải, đọc goal lỗi rồi Retry cả hai nguồn, qua nửa đêm cập nhật cửa sổ ngày và resume đọc lại dữ liệu đã commit. Các case kiểm tra dữ liệu hiển thị, không thay thành phần/bố cục FE. Hành trình SQLite dùng chung cho host/native tiếp tục kiểm tra owner, mục tiêu bật/tắt, đánh giá, sửa 90→30 giây và xóa buổi cuối trên Home/Progress.

Form cấu hình mục tiêu tuần và bộ lọc Progress 30 ngày/All chưa có UI trong phạm vi này, tiếp tục chờ FE. Việc đọc và hiển thị mục tiêu có sẵn không đồng nghĩa người dùng đã có thể bật/tắt/chỉnh mục tiêu.

Kiểm chứng trên baseline `da650f6`: 294 host tests đạt với `flutter test --concurrency=2`, `flutter analyze` sạch. Android API36 x86_64 đạt `home_overview_smoke_test.dart` với package `.homeqa` và database UUID riêng; đã kiểm tra ảnh Home hồ sơ rỗng và Progress có Saved. Đổi ngày, resume, lỗi/Retry và race là widget tests với clock/loader kiểm soát; không thay cho nghiệm thu force-stop, TalkBack, cỡ chữ lớn hoặc máy OEM.
