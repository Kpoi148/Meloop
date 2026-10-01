# Frontend

Lớp giao diện của ứng dụng: hiển thị state, nhận thao tác người dùng và gửi command tới backend.

- `theme/`: cấu hình `ThemeData` và bộ design tokens chuẩn hóa từ thiết kế Tempo.
- `components/`: các thành phần giao diện dùng chung (nút, ô nhập, lựa chọn, hộp thoại, điều hướng, trạng thái tải/trống/lỗi và khung bố cục).
- `showcase/`: màn hình mẫu và ví dụ sử dụng các thành phần dùng chung.
- `application/`: controller Riverpod, trạng thái thao tác và dependency frontend được app cấp; không triển khai nghiệp vụ hoặc lưu trữ backend.
- `practice/`: định dạng thời gian, UI công cụ, đổi tên buổi đang luyện và chi tiết buổi đã lưu; sử dụng contract service UC-04 từ shared.

Widget không truy cập SQLite, file system hoặc SDK mua hàng trực tiếp.
