# B07.1 — Thống kê Home dùng chung

Phạm vi là UI Home đã có trên `main`. Không thêm hoặc thay bố cục, màu, asset, tab Progress, form mục tiêu, bộ lọc 30 ngày/All hay UI đánh giá.

`shared/journal/practice_statistics.dart` giữ phép tính thuần Dart; `PracticeSessionSummary` chỉ chuyển dữ liệu UI sang contract này. Home truyền selected profile ID rõ ràng. `SqlitePracticeStatisticsReader` đọc Saved chưa xóa của đúng hồ sơ qua reader hiện có; app cấp `journalStatisticsReaderProvider`. Reader không ghi dữ liệu hoặc lưu tổng trùng trong schema.

SRS UC-14/BR11: biểu đồ và tổng Home là 7 ngày lịch gần nhất kể cả hôm nay; cộng giây trước khi định dạng phút. Streak xét toàn bộ lịch sử, kết thúc hôm nay hoặc hôm qua. Một ngày hợp lệ có ít nhất một buổi >=60 giây; nhiều buổi ngắn không được gộp để đạt ngưỡng. Mục tiêu tuần xét Thứ Hai đến hôm nay, độc lập khoảng biểu đồ. Loại nháp, hồ sơ khác và ngày tương lai; dùng practiceDate và đồng hồ device-local, không lấy ngày UTC từ timestamp. Ngày trước giới hạn practiceDate vẫn được dùng làm nhãn biểu đồ nếu cửa sổ vượt mốc đầu năm 2000.

Nhánh FE `feat/home-selected-instrument-uc03-uc06-uc14` (6c4520d) đã làm Home loading/error/retry, goal reader, recent và UI Progress riêng; chưa nằm trong main khi bắt đầu B07.1. Không đưa UI chưa merge vào nhánh BE hoặc viết lại phần FE đã đảm nhận. Sau khi nhánh FE vào main, giữ các trường/UI mới của họ và thay phần tổng/thời lượng/streak/qualifying days trong adapter bằng calculator shared này; logic latest/rating của FE không thuộc đợt này. Weekly goal vẫn tắt mặc định, không tự bật/chỉnh target.

Kiểm thử: `practice_statistics_test.dart` kiểm tra tổng giây, ngưỡng từng buổi, owner/state/future, tuần so với rolling chart, streak dài qua cửa sổ, ranh giới năm/nhuận và empty. `practice_statistics_reader_test.dart` và `integration_test/practice_statistics_smoke_test.dart` dùng cùng hành trình SQLite thật: Saved + Review + hồ sơ khác, không ghi source khi đọc, Edit 60→30, Save thêm 30, Delete, empty và lỗi đọc sau đóng connection. UI adapter có test selected profile; suite Save/Edit/Delete hiện có bảo vệ refresh Home.

Android smoke dùng package `.qa` và database UUID riêng:

```powershell
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.qa --driver test_driver/uc04_journal_driver.dart --target integration_test/practice_statistics_smoke_test.dart -d <device-id>
```

Đây là nghiệm thu tính toán/SQLite, không phải nghiệm thu UI Home mới trên nhánh FE chưa merge.
