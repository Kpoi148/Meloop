# B08.2 — Nghiệm thu tìm kiếm/lọc trên UI đã có

Baseline main `93a2956`. Chỉ dùng tab Buổi luyện hiện có (Tất cả/7/30 ngày, mới/cũ, tìm kiếm, chi tiết, Edit/Delete). Không thêm màn/widget, không đổi layout, assets, theme hoặc nút FE. Không triển khai reset, thanh toán hay khôi phục Pro.

Ba lỗi logic đã sửa: reader SQLite trim query giống ô tìm kiếm; app adapter giữ `createdAt` trong model UI (và `withRecordings`), controller sort theo ngày luyện → thời điểm tạo → ID như BR13/Table 35; `JournalProfileEntry` tạo controller danh sách riêng cho mỗi lần vào hồ sơ để đổi instrument reset query/filter theo UC06. Query/filter trong cùng entry vẫn giữ qua tab/chi tiết/Retry/Edit/Delete. Preview thiếu createdAt dùng date làm fallback, không phát sinh thời gian tạo giả từ clock hiện tại. Không migration hoặc đổi dữ liệu gốc.

Matrix shared SQLite/FE kiểm tra 16 queries × 3 period, đối chiếu danh sách ID có thứ tự thay vì chỉ tập ID; các kết quả title/ba notes, Unicode phân rã, đ/Đ, Straße, `%`, `_`, `\`, khoảng trắng, không khớp qua ranh giới hai trường có expected ID độc lập. Bao gồm cận 6/7/29/30 ngày, tương lai, owner khác, Review, tie createdAt trái thứ tự ID và tie ID khi timestamps bằng nhau; đảo thứ tự oldest/newest.

`session_search_acceptance_journey.dart` dùng SQLite thật và production loader/action ports. Save gọi cùng Save/complete ports để chứng minh invalidate list; không tuyên bố journey này nghiệm thu timer/Finish/form Save toàn bộ. Edit/Delete đi qua các màn/nút FE thật. Query không còn khớp sau Edit chuyển sang no-results; query mới thấy bản sửa; Delete không còn trả buổi; state vẫn giữ, còn Back từ chi tiết giữ scroll. Khi danh sách ngắn đi, scroll được clamp theo extent mới. Đổi sang owner khác và quay lại không hồi sinh query/filter cũ, không hiển thị buổi của owner khác.

Hai widget race tests dùng loader điều khiển bằng Completer: source cũ đã bắt đầu đọc, hoàn thành data/error sau đổi owner không thay danh sách hiện tại; lỗi nguồn hiện tại khác empty state; Retry giữ query/filter và chỉ hiển thị current owner; tab switch giữ state, Clear đưa về defaults. Đây là widget acceptance với nguồn giả, không phải bằng chứng lỗi I/O/timing Android thật. Journey host/Android dùng database thử riêng; dữ liệu giả không đi vào production.

Giới hạn: không UI Restore/custom date picker mới, không phân trang/tìm kiếm xuống SQLite trong production loader, không mở rộng giới hạn query 100 code points hoặc đo NFR 10.000 buổi trên thiết bị vật lý. Restore search-key regeneration đã kiểm tra riêng ở B11.3; chưa có FE restore nên không tuyên bố refresh UI restore tại đây.

Kiểm chứng: 328 full host tests và 15 targeted tests đạt, flutter analyze sạch. Android API36 package .qa/UUID database riêng (--no-uninstall) đạt ordered matrix, Save-complete ports, UI Edit/Delete/context reset; không đụng DB production. Bản app thường được mở lại sau QA để người dùng test.
