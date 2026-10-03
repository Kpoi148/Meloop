# Task 24 — Trang chủ theo nhạc cụ đang chọn (UC-03/06/14)

Đối chiếu SRS Report 2 (UC-03/06/14, BR11/BR12) và Home/Progress/Tools của prototype Tempo. Trước task này, Trang chủ chưa hiển thị buổi gần nhất từ journal, mục tiêu tuần còn cố định và Tiến độ là trạng thái trống.

## Hành vi

- Header dùng tên hồ sơ, loại nhạc cụ đang chọn; chip mở chọn hồ sơ. Nguồn dữ liệu được giải phóng khi không còn dùng và đọc lại khi chọn hồ sơ; không giữ số liệu hồ sơ cũ trong lúc tải.
- **Buổi gần nhất** chỉ tóm tắt buổi Saved mới nhất: tên, ngày, thời lượng, BPM nếu có và nội dung đã luyện. Không có nhãn trạng thái, liên kết, thao tác mở chi tiết hay nút tiếp tục. Nhật ký đầy đủ nằm ở tab Buổi luyện.
- Nút chính tạo buổi mới; chỉ mời tiếp tục khi có bản nháp thuộc chính hồ sơ đang chọn. Buổi đã kết thúc/lưu không tạo lời mời tiếp tục.
- Trang chủ và Tiến độ dùng chung `practiceOverviewProvider` và các widget tổng quan. Bộ lọc/tìm kiếm lịch sử không ảnh hưởng thống kê. Nhãn ngày theo lịch thực tế, chiều cao biểu đồ chuẩn hóa theo giá trị lớn nhất.
- Cộng giây trước khi đổi sang phút. Ngày đủ điều kiện có ít nhất một buổi từ 60 giây; hai buổi 30 giây không được cộng thành ngày đủ điều kiện. Chuỗi ngày kết thúc hôm nay/hôm qua. Tuần tính thứ Hai–Chủ nhật đến hôm nay; không cộng ngày tương lai.
- Mục tiêu đọc từ `weekly_goals`, không đổi schema hay tự bật. Chưa cấu hình/đang tắt hiện **Đang tắt**, cùng số ngày đã luyện trong tuần. Khi bật, hiện số ngày thực tế/target đã lưu; thanh tiến độ tối đa 100%.
- Tiến độ mặc định có cùng tổng quan 7 ngày, mục tiêu và cảm xúc/tập trung. Điểm chỉ lấy phản hồi đã nhập, làm tròn một chữ số sau khi cộng; thiếu phản hồi hiện **Chưa có đánh giá**. Có điểm thì kèm số lượt. Bộ lọc khoảng thời gian Pro và form điều chỉnh mục tiêu thuộc task khác.
- Tải, lỗi đọc/Thử lại và trống là trạng thái riêng. Lưu/sửa/xóa dùng invalidation hiện có; đổi ngày và trở lại app làm mới số liệu. Không seed dữ liệu mẫu trong app thật.
- **Công cụ luyện tập** mở màn thẻ công cụ theo prototype. Mở từ Home không tạo session ID/bản nháp. Máy đếm nhịp dùng luồng hiện có; công cụ chưa tích hợp/cần session dùng trạng thái chưa khả dụng hiện có.

## Ranh giới

`frontend/home/` chứa state và widget tổng quan; `HomeExample` giữ composition Trang chủ đang được app sử dụng. Widget không đọc SQLite. App inject loader Saved và `SqliteWeeklyPracticeGoalReader`; contract/model mục tiêu ở `shared/journal/`. Bản ghi minh họa chỉ ở test hoặc showcase riêng.

## Kiểm chứng

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter drive --dart-define=MELOOP_TEST_APPLICATION_ID_SUFFIX=.homeqa --driver test_driver/uc04_journal_driver.dart --target integration_test/home_overview_smoke_test.dart -d <device-id>
```

`home_overview_test.dart` kiểm tra số liệu theo hồ sơ, khối gần nhất không có thao tác, lỗi/retry, trống, không tạo draft khi mở công cụ, chọn lại hồ sơ đọc dữ liệu mới và giới hạn biểu đồ. `practice_session_summary_test.dart` kiểm tra ranh giới tuần/7 ngày, ngưỡng 60 giây và làm tròn đánh giá.

`journal_home_overview_test.dart` và Android smoke dùng cùng hành trình SQLite thật: Guitar có dữ liệu → đối chiếu Tiến độ → Sáo trống → Guitar → sửa 90 xuống 30 giây qua form → kiểm tra khối gần nhất/streak/goal → xóa buổi cuối → kiểm tra trống ở cả hai tab. Test Save/Edit/Delete hiện có tiếp tục kiểm tra refresh và cold entry. QA dùng package/database riêng; ảnh ở `app/build/ui-review/task24-*.png`, không commit ảnh/dữ liệu QA.
