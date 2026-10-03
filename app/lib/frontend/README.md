# Frontend

Lớp giao diện của ứng dụng: hiển thị state, nhận thao tác người dùng và gửi command tới backend.

- `theme/`: cấu hình `ThemeData` và bộ design tokens chuẩn hóa từ thiết kế Tempo.
- `components/`: các thành phần giao diện dùng chung (nút, ô nhập, lựa chọn, hộp thoại, điều hướng, trạng thái tải/trống/lỗi và khung bố cục).
- `showcase/`: màn hình mẫu và ví dụ sử dụng các thành phần dùng chung.
- `home/`: tổng quan theo hồ sơ đang chọn, nguồn buổi đã lưu/mục tiêu dùng chung với Tiến độ và trạng thái tải/trống/lỗi. Xem `docs/FE_HOME.md` tại gốc repository.
- `progress/`: giao diện Tiến độ UC-14 theo prototype Tempo, popup lọc khoảng ngày cho Pro với ảnh gốc Tempo, biểu đồ thời gian/cảm xúc/tập trung và adapter trình bày từ cùng nguồn buổi đã lưu với Trang chủ. Hướng dẫn xem giao diện và kiểm chứng: [`../../../docs/FE_PROGRESS_UI.md`](../../../docs/FE_PROGRESS_UI.md).
- `application/`: controller Riverpod, trạng thái thao tác và dependency frontend được app cấp; không triển khai nghiệp vụ hoặc lưu trữ backend.
- `practice_sessions/`: giao diện UC-06, tìm kiếm và bộ lọc theo hồ sơ, danh sách nhóm theo ngày và chi tiết chỉ xem. Nguồn danh sách được cấp qua `practiceSessionsLoaderProvider`; nội dung tạm để duyệt giao diện nằm trong `showcase/practice_session_examples.dart` và không ghi storage.

Widget không truy cập SQLite, file system hoặc SDK mua hàng trực tiếp.

`pitch/` có UI kiểm tra cao độ UC-09 theo prototype Tempo, controller quản lý Start/Stop và route từ Home/buổi luyện. Dữ liệu nốt và quyền được cấp qua `PitchService` trong shared; service xem thử nằm riêng ở `showcase/`, không được nối vào journal app. Hướng dẫn tích hợp và giới hạn hiện tại: [`../../../docs/FE_PITCH_UI.md`](../../../docs/FE_PITCH_UI.md).

`recording/` có màn ghi âm UC-10 và danh sách bản ghi UC-11–13. Danh sách dùng chung bố cục cho thư viện theo hồ sơ và bản ghi của buổi đã lưu; buổi đã lưu không có thao tác ghi mới. Nguồn dữ liệu và đồng hồ nghe lại để duyệt giao diện nằm trong `showcase/recordings_*.dart`, không ghi dữ liệu thiết bị. Hướng dẫn thay adapter và kiểm chứng: [`../../../docs/FE_RECORDINGS_UI.md`](../../../docs/FE_RECORDINGS_UI.md).
