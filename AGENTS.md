# Meloop agent instructions

Meloop là một ứng dụng Android viết bằng Dart/Flutter. Frontend và backend cục bộ cùng nằm trong `app/lib/`; dữ liệu người dùng lưu trên thiết bị. Chưa có server, tài khoản, đồng bộ cloud hoặc phạm vi iOS.

Trước khi thay đổi mã nguồn hoặc tài liệu, đọc [AGENT_GUIDELINES.md](AGENT_GUIDELINES.md). File đó quy định ranh giới code, cách kiểm chứng kết quả, bảo vệ dữ liệu và quy trình Git. Khi yêu cầu hiện tại của người dùng khác với hướng dẫn trong repository, ưu tiên yêu cầu của người dùng.

## Không hard code

Không hard code dữ liệu người dùng, ID, đường dẫn máy cá nhân, credential, chuỗi giao diện hoặc giá trị cấu hình trong logic/widget. Dùng dữ liệu runtime, dependency injection, localization, theme token và cấu hình/constant có tên đúng trách nhiệm. Không lặp magic number hoặc giá trị nghiệp vụ ở nhiều nơi; xem quy định chi tiết trong `AGENT_GUIDELINES.md`.

## Quy tắc Git bắt buộc

- Cấm push trực tiếp lên `main`, kể cả force push hoặc push từ nhánh khác với refspec đích là `main`.
- Mỗi công việc phải tạo nhánh mới từ `main` cập nhật, đặt tên theo prefix trong `AGENT_GUIDELINES.md`; commit và push lên nhánh đó.
- Thay đổi vào `main` phải qua Pull Request. Không tự merge khi chưa được người dùng yêu cầu.
- Không tắt ruleset, thêm quyền bypass hoặc tìm cách vượt bảo vệ nhánh. Nếu push bị từ chối, xử lý qua nhánh riêng và PR.

## CodeGraph

Nếu có thư mục `.codegraph/` tại gốc repository, dùng CodeGraph trước khi tìm kiếm hoặc đọc file để hiểu code. Ưu tiên công cụ `codegraph_explore` nếu có; nếu không, dùng `codegraph explore "<câu hỏi hoặc tên symbol>"`. Nếu không có `.codegraph/`, bỏ qua CodeGraph; không tự tạo chỉ mục.
