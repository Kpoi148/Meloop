# Migrations

Migration v1 tạo chín bảng journal, index, view và trigger. Không có INSERT seed; các INSERT trong trigger chỉ chạy khi nghiệp vụ phát sinh.

Thêm migration mới với phiên bản liên tiếp khi schema thay đổi; giữ nguyên migration đã phát hành. Database version độc lập với JSON backup schemaVersion. Lỗi migration phải rollback, không xóa DB để tạo lại.
