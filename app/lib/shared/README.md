# Mã dùng chung

Kiểu dữ liệu, contract và tiện ích thuần Dart được frontend và backend cùng sử dụng. Không đặt logic phụ thuộc vào widget ở đây.

Model, contract đọc journal v1, clock/UUID và normalization: [`journal/README.md`](journal/README.md).

Contract service và directory hồ sơ trong `profiles/instrument_profile_service.dart`; không phụ thuộc Flutter/Riverpod. Provider và label hiển thị vẫn ở frontend, file frontend re-export contract để giữ các import FE hiện có.
