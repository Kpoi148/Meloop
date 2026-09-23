# Meloop

Meloop là ứng dụng nhật ký luyện tập âm nhạc, phát triển bằng Flutter và Dart.

Phạm vi hiện tại:

- Chỉ build và kiểm thử Android.
- Dữ liệu nhật ký lưu cục bộ trên thiết bị người dùng.
- Frontend và backend cùng chạy trong một ứng dụng Flutter.
- Chưa có API server, tài khoản, đồng bộ cloud hoặc backend triển khai riêng.

## Cấu trúc chính

- `docs/`: tài liệu dự án.
- `assets/`: tài nguyên thiết kế gốc.
- `app/`: một project Flutter Android duy nhất.

Đọc `app/README.md` để hiểu ranh giới của project Flutter.

Quy tắc làm việc cho agent nằm ở [`AGENTS.md`](AGENTS.md); phần giải thích chi tiết ở [`AGENT_GUIDELINES.md`](AGENT_GUIDELINES.md).
