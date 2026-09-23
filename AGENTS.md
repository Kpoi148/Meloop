# Meloop agent instructions

Meloop là một ứng dụng Android viết bằng Dart/Flutter. Frontend và backend cục bộ cùng nằm trong `app/lib/`; dữ liệu người dùng lưu trên thiết bị. Chưa có server, tài khoản, đồng bộ cloud hoặc phạm vi iOS.

Trước khi thay đổi mã nguồn hoặc tài liệu, đọc [AGENT_GUIDELINES.md](AGENT_GUIDELINES.md). File đó quy định ranh giới code, cách kiểm chứng kết quả, bảo vệ dữ liệu và quy trình Git. Khi yêu cầu hiện tại của người dùng khác với hướng dẫn trong repository, ưu tiên yêu cầu của người dùng.

## CodeGraph

Nếu có thư mục `.codegraph/` tại gốc repository, dùng CodeGraph trước khi tìm kiếm hoặc đọc file để hiểu code. Ưu tiên công cụ `codegraph_explore` nếu có; nếu không, dùng `codegraph explore "<câu hỏi hoặc tên symbol>"`. Nếu không có `.codegraph/`, bỏ qua CodeGraph; không tự tạo chỉ mục.
