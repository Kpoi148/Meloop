# Trạng thái và điều phối frontend

Các controller Riverpod quản lý trạng thái giao diện và gọi dependency được app cung cấp. Nghiệp vụ và lưu trữ vẫn thuộc nhóm backend.

- `session_form_values.dart`: re-export giá trị từ form và callback `SessionFormSave` từ shared; không phải model SQLite.
- `session_form_controller.dart`: dependency lưu, trạng thái đang lưu/lỗi, khóa gửi trùng và xử lý hoàn tất sau khi form đã đóng.
- `practice_session_provider.dart`: port service buổi luyện và mở công cụ với cùng session ID; shell hiển thị snapshot do service cung cấp.

Mỗi form có identity riêng; provider tự giải phóng khi form không còn được dùng. `TextEditingController`, focus, lựa chọn cục bộ và validation hiển thị vẫn do widget quản lý. Không lưu nội dung nhập vào provider toàn cục hoặc diagnostic log.

Hướng dẫn cấp dependency và kiểm thử: [`../../../../docs/FE_RIVERPOD.md`](../../../../docs/FE_RIVERPOD.md).
