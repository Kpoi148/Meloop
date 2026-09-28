# Frontend

Lớp giao diện của ứng dụng: hiển thị state, nhận thao tác người dùng và gửi command tới backend.

- `theme/`: cấu hình `ThemeData` và bộ design tokens chuẩn hóa từ thiết kế Tempo.
- `components/`: các thành phần giao diện dùng chung (nút, ô nhập, lựa chọn, hộp thoại, điều hướng, trạng thái tải/trống/lỗi và khung bố cục).
- `showcase/`: màn hình mẫu và ví dụ sử dụng các thành phần dùng chung.

Widget không truy cập SQLite, file system hoặc SDK mua hàng trực tiếp.
