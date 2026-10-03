# B08.1 — Tìm kiếm và lọc buổi đã lưu

Trên baseline main `76d5118`, tab Buổi luyện đã có UI tìm kiếm, bộ lọc Tất cả/7/30 ngày và thứ tự mới/cũ. Production loader đọc Saved theo hồ sơ từ SQLite; không thay loader hoặc thêm truy vấn filtered vào nguồn Home/Progress, vì các màn đó cần lịch sử không bị bộ lọc danh sách chi phối.

`PracticeSessionsViewState` dùng `JournalText.searchKey` chung với BE: Unicode case folding, bỏ dấu và đ/Đ→d. Tìm substring riêng trong title/practiced/difficulty/next, không ghép trường để tạo kết quả khớp qua ranh giới ghi chú. Query được trim như UI hiện có; nội dung gốc giữ nguyên. `%`, `_`, `\` là ký tự literal khi lọc trong bộ nhớ; reader SQLite hiện có escape chúng khi dùng LIKE.

Cửa sổ ngày gồm hôm nay và 6/29 ngày lịch trước, loại ngày tương lai cả ở Tất cả. Giữ thứ tự FE theo ngày/ID, chiều mới nhất/cũ nhất, state query/filter riêng từng hồ sơ, không thay widget/layout/asset/theme. Bước này dùng chung normalization với reader; chưa chuyển tìm kiếm xuống SQLite hoặc phân trang.

`session_search_journey.dart` dùng database thử riêng: đối chiếu tập ID của UI filter với reader SQLite cho 12 queries × 3 periods; bao gồm title và cả ba notes, Unicode dạng phân rã, đ/Đ, Straße/STRASSE, ký tự LIKE literal, không khớp qua hai trường, cận ngày, owner, Review và thứ tự đảo chiều. Sau matrix, dọn fixture Review để luồng UI Saved không kích hoạt phục hồi timer; dùng production loader và ô tìm kiếm hiện có để kiểm tra `kho doi`/`strasse`. Cùng journey chạy host và Android qua `session_search_smoke_test.dart`.

Đổi tab/hồ sơ khi tải nhanh, lỗi/Retry cache và refresh mutation đầy đủ tiếp tục thuộc nghiệm thu B08.2. Không suy ra các trường hợp này đã đạt chỉ từ matrix tìm kiếm.

Kiểm chứng: 304 host tests đạt (`flutter test --concurrency=2`), gồm tests giao diện danh sách hiện có. Android API36 x86_64 đạt cùng matrix và ô tìm kiếm với package `.qa`/database UUID riêng; không thay dữ liệu production. Không nghiệm thu restore/backup, phân trang hoặc OEM performance trong bước này.
