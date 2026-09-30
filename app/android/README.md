# Android platform

Chứa cấu hình và mã tích hợp Android do Flutter tạo hoặc do dự án bổ sung.

MVP chỉ nhắm Android. Các permission như microphone và notification phải được khai báo và kiểm thử tại đây khi tính năng tương ứng được triển khai.

## Quy tắc backup Android

Hai file XML trong `app/src/main/res/xml/` loại dữ liệu private của Meloop khỏi cloud backup và device transfer tự động. Backup journal do người dùng chủ động xuất sẽ được triển khai riêng. Không đổi các quy tắc này khi thêm audio hoặc purchase storage mà chưa đối chiếu yêu cầu dữ liệu cục bộ.
