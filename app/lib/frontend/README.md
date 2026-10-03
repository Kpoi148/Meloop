# Frontend

Lớp giao diện của ứng dụng: hiển thị state, nhận thao tác người dùng và gửi command tới backend.

- `theme/`: cấu hình `ThemeData` và bộ design tokens chuẩn hóa từ thiết kế Tempo.
- `components/`: các thành phần giao diện dùng chung (nút, ô nhập, lựa chọn, hộp thoại, điều hướng, trạng thái tải/trống/lỗi và khung bố cục).
- `showcase/`: màn hình mẫu và ví dụ sử dụng các thành phần dùng chung.
- `home/`: tổng quan theo hồ sơ đang chọn, thẻ thống kê/mục tiêu dùng chung với Tiến độ và trạng thái tải/trống/lỗi. Xem `docs/FE_HOME.md` tại gốc repository.
- `application/`: controller Riverpod, trạng thái thao tác và dependency frontend được app cấp; không triển khai nghiệp vụ hoặc lưu trữ backend.
- `practice_sessions/`: giao diện UC-06, tìm kiếm và bộ lọc theo hồ sơ, danh sách nhóm theo ngày và chi tiết chỉ xem. Nguồn danh sách được cấp qua `practiceSessionsLoaderProvider`; nội dung tạm để duyệt giao diện nằm trong `showcase/practice_session_examples.dart` và không ghi storage.

Widget không truy cập SQLite, file system hoặc SDK mua hàng trực tiếp.
