// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Meloop';

  @override
  String get back => 'Quay lại';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get cancel => 'Hủy';

  @override
  String get processing => 'Đang xử lý…';

  @override
  String get saving => 'Đang lưu…';

  @override
  String get retrying => 'Đang thử lại…';

  @override
  String get requiredSuffix => ' *';

  @override
  String get optionalSuffix => ' (tùy chọn)';

  @override
  String get requiredSemantics => 'bắt buộc';

  @override
  String get optionalSemantics => 'tùy chọn';

  @override
  String requiredField(String label) {
    return 'Vui lòng nhập $label.';
  }

  @override
  String requiredChoice(String label) {
    return 'Vui lòng chọn $label.';
  }

  @override
  String invalidSingleLine(String label) {
    return '$label không được có xuống dòng hoặc ký tự điều khiển.';
  }

  @override
  String maxCharacters(String label, int count) {
    return '$label tối đa $count ký tự.';
  }

  @override
  String get invalidNoteControl => 'Ghi chú có ký tự điều khiển không hợp lệ.';

  @override
  String get noteMaxCharacters => 'Ghi chú tối đa 2.000 ký tự.';

  @override
  String integerRequired(String label) {
    return '$label phải là số nguyên.';
  }

  @override
  String integerRange(String label, int min, int max) {
    return '$label phải từ $min đến $max.';
  }

  @override
  String get validDateRange => 'Chọn ngày từ 01/01/2000 đến hôm nay.';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get searchHint => 'Tìm buổi luyện, ghi chú…';

  @override
  String ratingSemantics(String label, int value) {
    return '$label $value trên 5';
  }

  @override
  String get moodRatingHint =>
      '1 · Không vui → 5 · Rất vui. Bấm lại để bỏ chọn.';

  @override
  String get focusRatingHint =>
      '1 · Khó tập trung → 5 · Rất tập trung. Bấm lại để bỏ chọn.';

  @override
  String get genericFailure => 'Chưa thể hoàn tất. Vui lòng thử lại.';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navHistory => 'Buổi luyện';

  @override
  String get navProgress => 'Tiến độ';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageViCode => 'VI';

  @override
  String get languageEnCode => 'EN';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageSaved => 'Đã đổi ngôn ngữ.';

  @override
  String get languageSaveFailed => 'Chưa thể lưu ngôn ngữ. Vui lòng thử lại.';

  @override
  String get welcomeTitle => 'Một chút âm nhạc.\nMỗi ngày.';

  @override
  String get welcomeSubtitle =>
      'Luyện tập, ghi lại và nhìn thấy\nhành trình của chính bạn.';

  @override
  String get welcomePrivacy =>
      'Không cần tài khoản. Nhật ký lưu trên thiết bị.';

  @override
  String get createFirstProfile => 'Tạo hồ sơ đầu tiên';

  @override
  String get continueWithInstrument => 'Tiếp tục với nhạc cụ của tôi';

  @override
  String get instrumentPickerTitle => 'Hôm nay bạn chơi\nnhạc cụ nào?';

  @override
  String get instrumentPickerSubtitle =>
      'Chọn một nhạc cụ để tiếp tục hành trình.';

  @override
  String get manageInstruments => 'Quản lý nhạc cụ';

  @override
  String get selected => 'Đang chọn';

  @override
  String get addInstrument => 'Thêm nhạc cụ';

  @override
  String get freeProfileLimit => 'Miễn phí: tối đa 3 hồ sơ nhạc cụ.';

  @override
  String get noPracticeSessions => 'Chưa có buổi luyện';

  @override
  String get profileSessionsEmptyMessage =>
      'Buổi luyện của hồ sơ này sẽ hiện ở đây.';

  @override
  String get openWelcomePreview => 'Xem màn chào Tempo';

  @override
  String savedSessions(int count) {
    return '$count buổi luyện đã lưu';
  }

  @override
  String get unfinishedSessionTitle => 'Bạn còn một buổi luyện.';

  @override
  String get unfinishedSessionMessage =>
      'Hoàn tất hoặc hủy buổi luyện hiện tại trước khi đổi nhạc cụ.';

  @override
  String get understood => 'Đã hiểu';

  @override
  String get profileFormTitle => 'Nhạc cụ của bạn';

  @override
  String get profileQuestion => 'Bạn chơi nhạc cụ gì?';

  @override
  String get profileSubtitle => 'Chọn âm thanh thuộc về bạn.';

  @override
  String get instrumentOtherDescription => 'Nhạc cụ mang âm sắc của riêng bạn';

  @override
  String get customInstrumentName => 'Tên nhạc cụ';

  @override
  String get customInstrumentHint => 'Ví dụ: Saxophone';

  @override
  String get profileName => 'Tên hồ sơ';

  @override
  String get profileNameHint => 'Ví dụ: Guitar của tôi';

  @override
  String get saveProfile => 'Lưu hồ sơ';

  @override
  String get profileFootnote => 'Có thể đổi tên sau. Không cần đăng nhập.';

  @override
  String get instrumentGuitar => 'Guitar';

  @override
  String get instrumentPiano => 'Piano';

  @override
  String get instrumentUkulele => 'Ukulele';

  @override
  String get instrumentViolin => 'Violin';

  @override
  String get instrumentFlute => 'Sáo';

  @override
  String get instrumentDrums => 'Bộ gõ';

  @override
  String get instrumentOther => 'Khác';

  @override
  String get defaultProfileName => 'Guitar của tôi';

  @override
  String get samplePianoProfile => 'Piano buổi tối';

  @override
  String get overview => 'Tổng quan';

  @override
  String get practiceOverviewLoading => 'Đang đọc dữ liệu luyện tập…';

  @override
  String get practiceOverviewLoadFailed =>
      'Không thể đọc dữ liệu luyện tập. Hãy thử lại.';

  @override
  String get weeklyGoalOff => 'Đang tắt';

  @override
  String qualifyingDaysThisWeek(int days) {
    return 'Tuần này đã luyện $days ngày';
  }

  @override
  String get qualifyingPracticeDayHint =>
      'Một ngày được tính khi có ít nhất một buổi đã lưu từ 1 phút. Tuần tính từ thứ Hai đến Chủ nhật.';

  @override
  String practiceChartDay(String date, int minutes) {
    return '$date: $minutes phút luyện';
  }

  @override
  String get practiceRatingsHeading => 'Cảm xúc & tập trung';

  @override
  String get practiceRatingsPeriod =>
      '7 ngày gần nhất · Do bạn tự đánh giá sau buổi luyện';

  @override
  String get practiceRatingsDisclaimer =>
      'Đây là cảm nhận của bạn, không phải điểm kỹ năng.';

  @override
  String get practiceNoRatings => 'Chưa có đánh giá';

  @override
  String practiceRatingAverage(String average, int count) {
    return '$average/5 · $count lượt đánh giá';
  }

  @override
  String get practiceViewHistory => 'Xem nhật ký luyện tập';

  @override
  String get practiceToolsStandaloneHint =>
      'Mở công cụ từ Trang chủ không tạo buổi luyện. Công cụ cần buổi luyện sẽ khả dụng khi bạn bắt đầu một buổi.';

  @override
  String get changeInstrument => 'Đổi nhạc cụ';

  @override
  String get lastSevenDays => '7 ngày gần nhất';

  @override
  String get details => 'Chi tiết ›';

  @override
  String get practiceMinutes => 'phút luyện';

  @override
  String get practiceSessions => 'buổi luyện';

  @override
  String get consecutiveDays => 'ngày liên tiếp';

  @override
  String get weeklyGoal => 'Mục tiêu tuần';

  @override
  String goalProgress(int current, int target) {
    return '$current/$target ngày';
  }

  @override
  String get mondayToSunday => 'Thứ Hai – Chủ nhật';

  @override
  String get createPractice => 'Tạo buổi luyện';

  @override
  String get continuePractice => 'Tiếp tục buổi luyện';

  @override
  String get practiceTools => 'Công cụ luyện tập';

  @override
  String get recentSession => 'Buổi gần nhất';

  @override
  String get viewAll => 'Xem tất cả ›';

  @override
  String get sampleSessionTitle => 'Luyện gam C';

  @override
  String get sampleSessionMeta => 'Hôm nay · 35 phút · 80 BPM';

  @override
  String get sampleSessionNotes =>
      'Gam C trưởng, chuyển hợp âm C – G – Am – F.';

  @override
  String get nextPracticeUpper => 'CHO LẦN LUYỆN TIẾP';

  @override
  String get sampleNextNotes => 'Giữ nhịp ở 80 BPM, thả lỏng bàn tay.';

  @override
  String get setupTitle => 'Tạo buổi luyện';

  @override
  String get newPracticeUpper => 'BUỔI LUYỆN MỚI';

  @override
  String get setupQuestion => 'Hôm nay bạn\nmuốn tập gì?';

  @override
  String get sessionTitle => 'Tên buổi luyện';

  @override
  String get sessionTitleHint => 'Ví dụ: Luyện gam C';

  @override
  String get sessionTitleHelper =>
      'Đặt tên để dễ tìm lại. Có thể đổi khi xem lại.';

  @override
  String get timerStartsHint => 'Bộ đếm bắt đầu khi bạn bấm Bắt đầu luyện.';

  @override
  String get startPractice => 'Bắt đầu luyện';

  @override
  String get timerTitle => 'Buổi luyện';

  @override
  String get timerOptions => 'Tùy chọn buổi luyện';

  @override
  String get timerOptionalTitle => 'Tên buổi luyện · tùy chọn';

  @override
  String get setPracticeName => 'Đặt tên buổi luyện';

  @override
  String get timerPaused => 'Tạm dừng';

  @override
  String get timerRunning => 'Đang luyện';

  @override
  String get practiceTime => 'Thời gian luyện tập';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get finish => 'Kết thúc';

  @override
  String get recoveredDraftTitle => 'Đã khôi phục buổi luyện';

  @override
  String get recoveredDraftMessage =>
      'Thời gian đã lưu được giữ nguyên. Buổi luyện được tạm dừng sau khi mở lại.';

  @override
  String get historySubtitle => 'Những nốt nhạc làm nên hành trình.';

  @override
  String get practiceTodayLabel => 'Hôm nay';

  @override
  String get practiceYesterdayLabel => 'Hôm qua';

  @override
  String practiceRatingShort(int value) {
    return '$value/5';
  }

  @override
  String practiceDurationWithBpm(String duration, int bpm) {
    return '$duration · $bpm BPM';
  }

  @override
  String get practiceSort => 'Sắp xếp';

  @override
  String get practiceFilters => 'Bộ lọc';

  @override
  String get practiceApplyFilters => 'Áp dụng';

  @override
  String get practiceClearFilters => 'Xóa bộ lọc';

  @override
  String get practiceNewest => 'Mới nhất';

  @override
  String get practiceOldest => 'Cũ nhất';

  @override
  String get practiceClearSearchAndFilters => 'Xóa tìm kiếm và bộ lọc';

  @override
  String get practiceNoResultsMessage =>
      'Thử từ khóa khác hoặc thay đổi bộ lọc để tìm buổi luyện của bạn.';

  @override
  String get practiceEmptyMessage =>
      'Bắt đầu buổi luyện đầu tiên, ghi lại những điều bạn muốn nhớ.';

  @override
  String get practiceSessionDetails => 'Chi tiết buổi luyện';

  @override
  String get practiceFocusLabel => 'Tập trung';

  @override
  String get practiceEmptyRating => '—';

  @override
  String get sessionOptionalSuffix => ' (không bắt buộc)';

  @override
  String get sessionMoodHint =>
      '1 · Không vui → 5 · Rất vui · Bấm lại để bỏ chọn.';

  @override
  String get sessionFocusHint =>
      '1 · Khó tập trung → 5 · Rất tập trung · Bấm lại để bỏ chọn.';

  @override
  String get nextPracticeHint => 'Một lời nhắn cho bạn ở buổi sau…';

  @override
  String get practiceSampleGuitarDifficulty =>
      'Chuyển từ G sang Am cần mượt hơn.';

  @override
  String get practiceRatingSuffix => ' / 5';

  @override
  String get practiceNextEmpty => 'Hẹn bạn ở buổi luyện tiếp theo.';

  @override
  String get editSessionJournal => 'Sửa nhật ký';

  @override
  String get editSessionTitle => 'Sửa buổi luyện';

  @override
  String get editSessionHeading => 'Nhìn lại buổi luyện.';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get sessionDurationMinutes => 'Thời lượng (phút)';

  @override
  String get sessionDuration => 'Thời lượng';

  @override
  String get instrumentLabel => 'Nhạc cụ';

  @override
  String get leaveReviewTitle => 'Quay lại buổi luyện?';

  @override
  String get leaveReviewMessage =>
      'Nội dung bạn đã nhập sẽ được giữ để sửa tiếp khi mở lại form.';

  @override
  String get returnToPractice => 'Quay lại buổi luyện';

  @override
  String get reviewDraftFailed =>
      'Chưa thể giữ bản nháp mới nhất. Nội dung vẫn ở form này; hãy thử lại trước khi rời đi.';

  @override
  String get sessionPracticeBpm => 'Tốc độ luyện (BPM)';

  @override
  String get notRequired => 'Không bắt buộc';

  @override
  String get deleteSessionTitle => 'Xóa buổi luyện?';

  @override
  String get sessionDeleted => 'Đã xóa buổi luyện.';

  @override
  String get deleteSessionFailed =>
      'Chưa thể xóa. Buổi luyện và bản ghi âm vẫn được giữ. Vui lòng thử lại.';

  @override
  String get deleteRecordingTitle => 'Xóa bản ghi âm?';

  @override
  String get deleteRecording => 'Xóa bản ghi';

  @override
  String get deleteRecordingMessage =>
      'Chỉ bản ghi âm này bị xóa. Nhật ký buổi luyện được giữ nguyên.';

  @override
  String get listenRecording => 'Nghe lại';

  @override
  String get exportRecording => 'Xuất bản ghi';

  @override
  String get recordingLinked => 'Đã gắn với nhật ký';

  @override
  String get recordingUnlinked => 'Chưa gắn nhật ký';

  @override
  String get recordingMissingFile => 'Tệp không còn trên thiết bị';

  @override
  String get recordingMissingMessage =>
      'Không tìm thấy tệp âm thanh. Bạn có thể xóa bản ghi này khỏi danh sách.';

  @override
  String recordingMetadata(String duration, String status) {
    return '$duration · $status';
  }

  @override
  String get recordingMelodyTitle => 'Ý tưởng giai điệu';

  @override
  String get recordingDeleted => 'Đã xóa bản ghi âm.';

  @override
  String get recordingDeleteAction => 'Xóa';

  @override
  String get recordingShare => 'Chia sẻ bản ghi';

  @override
  String get recordingShareDescription => 'Chọn ứng dụng để gửi tệp âm thanh.';

  @override
  String get recordingSaveFile => 'Lưu vào tệp';

  @override
  String get recordingSaveFileDescription =>
      'Chọn nơi lưu trên thiết bị của bạn.';

  @override
  String get recordingExported => 'Đã xuất bản ghi âm.';

  @override
  String get recordingExportFailed =>
      'Chưa thể xuất bản ghi âm. Vui lòng thử lại.';

  @override
  String get recordingActionFailed =>
      'Chưa thể mở bản ghi âm. Vui lòng thử lại.';

  @override
  String get noSessionRecordings => 'Chưa có bản ghi âm.';

  @override
  String get noSessionRecordingsMessage =>
      'Buổi luyện này chưa có bản ghi âm được lưu.';

  @override
  String practiceRecordingTake(String title, int take) {
    return '$title · Lần $take';
  }

  @override
  String get practiceWhatWasPracticed => 'Đã luyện';

  @override
  String get practiceSessionRecordings => 'Bản ghi của buổi này';

  @override
  String get practiceNotRated => 'Chưa đánh giá';

  @override
  String get practiceNoNotes => 'Chưa có ghi chú.';

  @override
  String practiceToday(String date) {
    return 'Hôm nay · $date';
  }

  @override
  String practiceYesterday(String date) {
    return 'Hôm qua · $date';
  }

  @override
  String practiceDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String practiceDurationSeconds(int seconds) {
    return '$seconds giây';
  }

  @override
  String practiceHoursMinutes(int hours, int minutes) {
    return '$hours giờ $minutes phút';
  }

  @override
  String practiceBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String practiceMoodScore(int value) {
    return 'Cảm xúc $value/5';
  }

  @override
  String practiceFocusScore(int value) {
    return 'Tập trung $value/5';
  }

  @override
  String practiceRecordingCount(int count) {
    return '$count bản ghi';
  }

  @override
  String practiceRatingValue(int value) {
    return '$value / 5';
  }

  @override
  String get practiceSampleRhythm => 'Nhịp điệu cơ bản';

  @override
  String get practiceSampleSong => 'Ôn bài nhạc yêu thích';

  @override
  String get practiceSampleMinorScale => 'Luyện gam Am';

  @override
  String get practiceSampleTechnique => 'Luyện kỹ thuật tay';

  @override
  String get practiceSampleReview => 'Ôn lại những đoạn khó';

  @override
  String get practiceSampleSlowPractice => 'Luyện chậm, giữ nhịp đều';

  @override
  String get practiceSampleScaleNotes =>
      'Gam C trưởng, luyện từng nốt rõ tiếng theo hai chiều.';

  @override
  String get practiceSampleSteadyNotes =>
      'Luyện chậm từng đoạn, giữ nhịp đều và rõ tiếng.';

  @override
  String get practiceSampleDifficulty =>
      'Đoạn chuyển cần mượt hơn, giữ nhịp khi tăng tốc độ.';

  @override
  String get unfinishedPractice => 'Buổi luyện chưa hoàn tất';

  @override
  String get finishPractice => 'Hoàn tất';

  @override
  String get timeRange => 'Khoảng thời gian';

  @override
  String get all => 'Tất cả';

  @override
  String get sevenDays => '7 ngày';

  @override
  String get thirtyDays => '30 ngày';

  @override
  String get noMatchingSessions => 'Không có buổi luyện phù hợp.';

  @override
  String get clearSearchAction => 'Xóa tìm kiếm';

  @override
  String get sampleSessionDate => '23/09/2026 · 30 phút';

  @override
  String showcaseSaveCount(int count) {
    return 'Mẫu UI · $count lần lưu mẫu hoàn tất. Không ghi dữ liệu lên thiết bị.';
  }

  @override
  String get progressHeading => 'Mỗi ngày,\nmột bước tiến.';

  @override
  String get noProgressTitle => 'Chưa có dữ liệu tiến độ.';

  @override
  String get noProgressMessage =>
      'Hoàn tất một buổi luyện để nhìn lại hành trình.';

  @override
  String get settingsHeading => 'Theo cách bạn.';

  @override
  String get settingsFreePlan => 'FREE';

  @override
  String get settingsEyebrow => 'MELOOP · KHÔNG GIAN CỦA BẠN';

  @override
  String get settingsManageProfiles => 'Quản lý hồ sơ nhạc cụ';

  @override
  String get settingsProDescription =>
      'Thêm hồ sơ nhạc cụ và lọc thống kê nâng cao.';

  @override
  String get settingsExplorePro => 'Khám phá Pro';

  @override
  String get settingsPersonalGroup => 'Theo cách của bạn';

  @override
  String get settingsReminderOff => 'Tắt';

  @override
  String get settingsDeviceData => 'Dữ liệu trên thiết bị';

  @override
  String get settingsInformationGroup => 'Thông tin & hỗ trợ';

  @override
  String get settingsPrivacy => 'Quyền riêng tư';

  @override
  String get settingsContactSupport => 'Liên hệ hỗ trợ';

  @override
  String get settingsRestorePro => 'Khôi phục Pro';

  @override
  String settingsVersion(String version) {
    return 'Meloop · $version';
  }

  @override
  String get settingsStudioCredit => 'Made with care by Moss Studio';

  @override
  String get instrumentProfilesTitle => 'Hồ sơ nhạc cụ';

  @override
  String get instrumentProfilesHeading => 'Mỗi nhạc cụ,\nmột hành trình.';

  @override
  String get instrumentProfilesSubtitle => 'Những âm thanh làm nên bạn.';

  @override
  String get profileInUse => 'Đang sử dụng';

  @override
  String get profileArchived => 'Đã lưu trữ';

  @override
  String get editProfile => 'Sửa hồ sơ';

  @override
  String get archiveProfile => 'Lưu trữ';

  @override
  String get reactivateProfile => 'Kích hoạt lại';

  @override
  String get freeProfilesNote =>
      'Miễn phí có 3 hồ sơ. Lưu trữ giữ nguyên lịch sử và không giải phóng suất hồ sơ.';

  @override
  String settingsLanguageDescription(String language) {
    return '$language';
  }

  @override
  String get componentCatalog => 'Bộ thành phần UI';

  @override
  String get openSessionForm => 'Xem form lưu buổi luyện';

  @override
  String get simulateNextSaveFailure => 'Lần lưu tiếp theo gặp lỗi';

  @override
  String get saveSessionTitle => 'Lưu buổi luyện';

  @override
  String get sessionFormHeading => 'Một buổi luyện,\nmột bước tiến.';

  @override
  String get sessionFormTitleHint => 'Buổi luyện';

  @override
  String get sessionFormSubtitle => 'Ghi lại điều bạn muốn nhớ.';

  @override
  String get practiceDate => 'Ngày luyện';

  @override
  String get hours => 'Giờ';

  @override
  String get minutes => 'Phút';

  @override
  String get seconds => 'Giây';

  @override
  String get durationRange => 'Thời lượng phải từ 1 giây đến 24 giờ.';

  @override
  String get mood => 'Cảm xúc';

  @override
  String get focusLevel => 'Mức độ tập trung';

  @override
  String get practicedWhat => 'Bạn đã luyện gì?';

  @override
  String get practicedHint => 'Gam, hợp âm, bài nhạc…';

  @override
  String get difficulty => 'Điều còn vướng';

  @override
  String get difficultyHint => 'Một đoạn khó, một điều muốn cải thiện…';

  @override
  String get nextPractice => 'Cho lần luyện tiếp';

  @override
  String get savePractice => 'Lưu buổi luyện';

  @override
  String get discardChangesTitle => 'Bỏ thay đổi?';

  @override
  String get discardChangesMessage => 'Những thay đổi chưa lưu sẽ bị bỏ.';

  @override
  String get discardChanges => 'Bỏ thay đổi';

  @override
  String get continueEditing => 'Tiếp tục sửa';

  @override
  String get saveSessionFailed =>
      'Chưa thể lưu buổi luyện. Nội dung của bạn vẫn ở đây. Vui lòng thử lại.';

  @override
  String get savedSessionCompletionFailed =>
      'Buổi luyện đã được lưu. Chưa thể hoàn tất bước tiếp theo. Vui lòng thử lại.';

  @override
  String get catalogTitle => 'Thành phần dùng chung';

  @override
  String get catalogHeading => 'Cùng một nhịp\nthiết kế.';

  @override
  String get catalogSubtitle =>
      'Mẫu UI Tempo · dữ liệu minh họa chỉ nằm trong bộ nhớ.';

  @override
  String get catalogButtons => 'Nút & trạng thái đang lưu';

  @override
  String get catalogFields => 'Ô nhập & lỗi tại trường';

  @override
  String get catalogChoices => 'Lựa chọn & tab';

  @override
  String get catalogDialogs => 'Hộp thoại & thông báo';

  @override
  String get catalogStates => 'Tải / trống / lỗi';

  @override
  String get save => 'Lưu';

  @override
  String get unavailable => 'Không khả dụng';

  @override
  String get addProfile => 'Thêm hồ sơ';

  @override
  String get deleteSession => 'Xóa buổi luyện';

  @override
  String get endPractice => 'Kết thúc';

  @override
  String get profileHelper => '1–50 ký tự. Giữ nội dung nếu lưu thất bại.';

  @override
  String get tempoBpm => 'Tốc độ (BPM)';

  @override
  String get metronomeTitle => 'Máy đếm nhịp';

  @override
  String get metronomeBpmUnit => 'nhịp / phút';

  @override
  String get decreaseMetronomeBpm => 'Giảm nhịp';

  @override
  String get increaseMetronomeBpm => 'Tăng nhịp';

  @override
  String get startMetronome => 'Bắt đầu';

  @override
  String get stopMetronome => 'Dừng máy đếm nhịp';

  @override
  String get metronomeFootnote =>
      'Nhấn ở phách đầu để dễ bắt nhịp.\nÂm thanh phát trực tiếp trên thiết bị của bạn.';

  @override
  String metronomeCurrentBeat(int current, int total) {
    return 'Phách $current / $total';
  }

  @override
  String metronomeBpmRangeError(int min, int max) {
    return 'Tốc độ phải từ $min đến $max BPM.';
  }

  @override
  String metronomeBeatsRangeError(int min, int max) {
    return 'Số phách mỗi ô nhịp phải từ $min đến $max.';
  }

  @override
  String get metronomeAudioBusy =>
      'Một công cụ âm thanh khác đang hoạt động. Hãy dừng công cụ đó trước khi bật máy đếm nhịp.';

  @override
  String get bpm => 'BPM';

  @override
  String get validateData => 'Kiểm tra dữ liệu';

  @override
  String get beatsPerBar => 'Số phách mỗi ô nhịp';

  @override
  String beats(int count) {
    return '$count phách';
  }

  @override
  String get reminder => 'Nhắc lịch luyện';

  @override
  String get reminderDescription => 'Nhắc một chút âm nhạc mỗi ngày.';

  @override
  String get attachDiagnostics => 'Đính kèm thông tin chẩn đoán';

  @override
  String get attachDiagnosticsDescription => 'Chỉ khi bạn chủ động chọn.';

  @override
  String get openConfirmDialog => 'Mở hộp thoại xác nhận';

  @override
  String get deleteSessionMessage =>
      'Buổi luyện này sẽ được xóa khỏi nhật ký và thống kê. Bản ghi âm vẫn được giữ riêng.';

  @override
  String get openChoiceSheet => 'Mở bảng lựa chọn';

  @override
  String get tempoComponents => 'Bộ thành phần Tempo';

  @override
  String get sharedThemeNotice =>
      'Các màn hình dùng cùng theme, font, màu và icon.';

  @override
  String get showNotification => 'Hiện thông báo';

  @override
  String get sampleActionComplete => 'Đã hoàn tất thao tác mẫu.';

  @override
  String get journalOnDevice => 'Nhật ký lưu trên thiết bị.';

  @override
  String get sessionSaved => 'Đã lưu buổi luyện.';

  @override
  String get saveFailedKeepsContent => 'Chưa thể lưu. Nội dung vẫn ở đây.';

  @override
  String get loadingSessions => 'Đang tải buổi luyện…';

  @override
  String get journeyStartsToday => 'Hành trình bắt đầu từ hôm nay.';

  @override
  String get saveFirstSession => 'Lưu buổi luyện đầu tiên của bạn.';

  @override
  String get loadSessionsFailed => 'Chưa thể tải buổi luyện.';

  @override
  String get dataKeptRetry => 'Vui lòng thử lại. Dữ liệu của bạn vẫn được giữ.';

  @override
  String get retry => 'Thử lại';

  @override
  String get proTitle => 'Meloop Pro';

  @override
  String get proOneTimeBadge => 'MUA MỘT LẦN · KHÔNG GIA HẠN';

  @override
  String get proHeading => 'Thêm không gian\ncho đam mê.';

  @override
  String get proSubtitle => 'Một người bạn đồng hành, theo cách của bạn.';

  @override
  String get proIllustrativePrice => '49.000đ';

  @override
  String get proPriceCaption => 'Giá minh họa · Mua một lần';

  @override
  String get proProfilesBenefit => 'Thêm hồ sơ nhạc cụ';

  @override
  String get proProfilesDescription =>
      'Tách riêng nhật ký cho mỗi âm sắc bạn yêu.';

  @override
  String get proFiltersBenefit => 'Bộ lọc tiến độ nâng cao';

  @override
  String get proFiltersDescription =>
      'Xem các khoảng thời gian dài hơn hoặc tùy chọn.';

  @override
  String get proFreeFeatures =>
      'Nhật ký, công cụ, ghi âm, mục tiêu, lịch nhắc, sao lưu và xuất âm thanh vẫn miễn phí.';

  @override
  String get proPreviewTry => 'Dùng thử Meloop Pro';

  @override
  String get proPreviewActive => 'Đang xem thử Meloop Pro';

  @override
  String get proPreviewPlan => 'PRO · XEM THỬ';

  @override
  String get proPreviewFootnote =>
      'Bản UI mô phỏng quyền Pro, không có giao dịch thật.\nGiá chính thức do cửa hàng cung cấp.';

  @override
  String get proPreviewConfirmTitle => 'Xem thử Meloop Pro';

  @override
  String get proPreviewConfirmMessage =>
      'Thao tác này bật chế độ xem thử Pro để bạn trải nghiệm giao diện và tạo thêm hồ sơ. Không thu tiền, không kết nối cửa hàng.';

  @override
  String get proPreviewEnable => 'Bật xem thử';

  @override
  String get proPreviewEnabled => 'Đã bật Pro để xem thử.';

  @override
  String get proPreviewFailed =>
      'Chưa thể bật Pro. Dữ liệu của bạn vẫn được giữ. Hãy thử lại.';

  @override
  String get proPreviewActiveTitle => 'Meloop Pro đang bật để xem thử.';

  @override
  String get proPreviewActiveMessage =>
      'Bạn có thể tạo thêm hồ sơ trong chế độ xem thử. Không có khoản thanh toán nào được thực hiện.';

  @override
  String get proRestoreTransaction => 'Khôi phục giao dịch';

  @override
  String get proRestoreFootnote => 'Khôi phục với cùng tài khoản và cửa hàng.';

  @override
  String get proRestoreTitle => 'Khôi phục Meloop Pro';

  @override
  String get proRestoreMessage =>
      'Bản UI chưa kết nối Google Play nên không thể kiểm tra giao dịch. Chế độ xem thử Pro chỉ lưu trên thiết bị này.';

  @override
  String get proClose => 'Đóng';

  @override
  String get previewResetAction => 'Xóa dữ liệu và bắt đầu lại';

  @override
  String get previewResetTitle => 'Bắt đầu lại từ màn chào?';

  @override
  String get previewResetMessage =>
      'Toàn bộ hồ sơ, lựa chọn nhạc cụ, dữ liệu thử và quyền xem thử Pro trên thiết bị sẽ được xóa. Ứng dụng trở về màn chào và gói Free để bạn bắt đầu lại.';

  @override
  String get previewResetConfirm => 'Xóa và bắt đầu lại';

  @override
  String get previewResetCancel => 'Giữ dữ liệu';

  @override
  String get previewResetFailed =>
      'Chưa thể xóa dữ liệu. Hồ sơ của bạn vẫn được giữ. Hãy thử lại.';

  @override
  String get profilesLoading => 'Đang mở hồ sơ…';

  @override
  String get journalReviewState => 'Đang rà soát';

  @override
  String get profilesLoadFailed => 'Chưa thể mở hồ sơ trên thiết bị.';

  @override
  String get journalRecoveryPending =>
      'Buổi luyện vẫn được giữ trên thiết bị. Bạn có thể xem hoặc thêm hồ sơ; chưa thể tiếp tục hay lưu buổi này ở phiên bản hiện tại.';

  @override
  String continueInstrumentPractice(String instrument) {
    return 'Tiếp tục · $instrument';
  }

  @override
  String get practiceStartFailed =>
      'Chưa thể bắt đầu buổi luyện. Tiêu đề vẫn được giữ; hãy thử lại.';

  @override
  String get timerCheckpointFailed =>
      'Buổi luyện đã tạm dừng do lỗi. Thời gian mới chưa được xác nhận lưu; hãy thử lại.';

  @override
  String get practiceActionFailed =>
      'Chưa thể cập nhật buổi luyện. Vui lòng thử lại.';

  @override
  String get practiceToolsHeading => 'Những người bạn\ncủa buổi luyện.';

  @override
  String get practiceToolsSubtitle => 'Tìm đúng nhịp. Lắng nghe kỹ hơn.';

  @override
  String get metronomeTool => 'Máy đếm nhịp';

  @override
  String get pitchTool => 'Kiểm tra cao độ';

  @override
  String get practiceToolUnavailable => 'Công cụ này chưa khả dụng.';

  @override
  String get renamePractice => 'Đổi tên buổi luyện';

  @override
  String get metronomeToolHint => 'Giữ nhịp, theo cách của bạn.';

  @override
  String get pitchToolHint => 'Lắng nghe từng nốt.';

  @override
  String get recordTool => 'Ghi âm';

  @override
  String get recordToolHint => 'Giữ lại một khoảnh khắc.';

  @override
  String get recordingsTool => 'Bản ghi âm';

  @override
  String get recordingsToolHint => 'Nghe lại hành trình.';

  @override
  String get practiceToolsFree => 'Các công cụ luôn miễn phí.';

  @override
  String get practiceToolsTimingHint =>
      'Một công cụ âm thanh hoạt động mỗi lúc; bộ đếm giờ vẫn tiếp tục.';

  @override
  String get recordingTitle => 'Ghi âm luyện tập';

  @override
  String get sessionRecordingsTitle => 'Bản ghi của buổi luyện';

  @override
  String get sessionRecordingsHeading => 'Lắng nghe\nhành trình của bạn.';

  @override
  String get sessionRecordingsSubtitle => 'Những âm thanh bạn muốn giữ lại.';

  @override
  String get sessionRecordingsEmptyMessage =>
      'Ghi lại một đoạn trong buổi luyện để nghe lại sau.';

  @override
  String get recordPracticeSession => 'Ghi âm buổi luyện';

  @override
  String get sessionRecordingsDeleteHint =>
      'Xóa một bản ghi không xóa nhật ký buổi luyện.';

  @override
  String get recordingDefaultTitle => 'Buổi luyện của tôi';

  @override
  String get recordingEmptyHeading => 'Giữ lại âm thanh\ncủa hôm nay.';

  @override
  String get recordingEmptyTitle => 'Bắt đầu một buổi luyện trước.';

  @override
  String get recordingEmptyDescription =>
      'Bản ghi sẽ đi cùng nhật ký buổi luyện đang diễn ra.';

  @override
  String get recordingStart => 'Bắt đầu ghi âm';

  @override
  String get recordingStop => 'Dừng ghi âm';

  @override
  String get recordingPending => 'Bản ghi chưa được giữ';

  @override
  String get recordingMute => 'Tắt âm';

  @override
  String get recordingUnmute => 'Bật âm';

  @override
  String get recordingPlaybackOptions => 'Tùy chọn bản ghi';

  @override
  String get recordingRestartPlayback => 'Nghe lại từ đầu';

  @override
  String get recordingPendingHint =>
      'Nghe lại rồi giữ hoặc bỏ bản ghi này trước khi bắt đầu bản mới.';

  @override
  String recordingActive(int minutes) {
    return 'Đang ghi âm · Tối đa $minutes phút';
  }

  @override
  String recordingReady(int minutes) {
    return 'Micro sẵn sàng · Tối đa $minutes phút';
  }

  @override
  String recordingMicrophoneOff(int minutes) {
    return 'Micro chưa bật · Tối đa $minutes phút';
  }

  @override
  String get recordingFootnote =>
      'Bản ghi được lưu trên thiết bị của bạn.\nGhi âm không kết thúc đồng hồ buổi luyện.';

  @override
  String recordingFreeQuota(int count, int limit) {
    return 'Free · $count/$limit bản ghi';
  }

  @override
  String recordingProQuota(int minutes) {
    return 'Pro · Tối đa $minutes phút mỗi bản ghi';
  }

  @override
  String get recordingViewPro => 'Xem Meloop Pro';

  @override
  String get recordingProTitle => 'Thêm không gian cho đam mê.';

  @override
  String get recordingProDescription =>
      'Meloop Pro mở rộng thời lượng và số bản ghi cho những buổi luyện của bạn.';

  @override
  String get recordingProJournalHint =>
      'Bạn luôn có thể tiếp tục luyện tập và lưu nhật ký với Free, kể cả khi không cấp quyền micro.';

  @override
  String get recordingContinuePractice => 'Tiếp tục luyện tập';

  @override
  String get recordingReviewTitle => 'Nghe lại một chút.';

  @override
  String get recordingKeep => 'Giữ bản ghi';

  @override
  String get recordingDiscard => 'Bỏ bản ghi';

  @override
  String get recordingDiscardTitle => 'Bỏ bản ghi vừa rồi?';

  @override
  String get recordingDiscardMessage => 'Bản ghi chưa được giữ sẽ bị xóa.';

  @override
  String get recordingKept => 'Đã giữ bản ghi trên thiết bị.';

  @override
  String get recordingPausePlayback => 'Tạm dừng nghe lại';

  @override
  String get recordingMicrophoneDenied =>
      'Bạn chưa cấp quyền micro. Bật quyền micro trong Cài đặt của thiết bị rồi thử lại. Bạn vẫn có thể lưu nhật ký buổi luyện.';

  @override
  String get recordingMicrophoneUnavailable =>
      'Không tìm thấy micro trên thiết bị. Kiểm tra micro rồi thử lại. Bạn vẫn có thể tiếp tục luyện tập và lưu nhật ký.';

  @override
  String get recordingStorageFull =>
      'Không đủ dung lượng để ghi âm. Giải phóng bộ nhớ rồi thử lại. Nhật ký buổi luyện vẫn có thể lưu.';

  @override
  String get recordingAudioBusy =>
      'Một công cụ âm thanh khác đang hoạt động. Dừng công cụ đó rồi thử ghi âm lại.';

  @override
  String get recordingStartFailed =>
      'Chưa thể bắt đầu ghi âm. Thử lại khi micro sẵn sàng. Trạng thái buổi luyện vẫn được giữ.';

  @override
  String get recordingSaveFailed =>
      'Chưa giữ được bản ghi. Bản ghi vẫn ở đây để bạn nghe lại hoặc thử giữ lần nữa.';

  @override
  String get recordingInterrupted =>
      'Ghi âm đã dừng do gián đoạn. Nghe lại rồi giữ hoặc bỏ bản ghi trước khi ghi tiếp.';

  @override
  String recordingDurationLimit(int minutes) {
    return 'Đã đạt giới hạn $minutes phút. Bản ghi đã dừng để bạn nghe lại và giữ. Bạn vẫn có thể lưu nhật ký buổi luyện.';
  }

  @override
  String recordingFileLimit(int limit) {
    return 'Đã đủ $limit bản ghi Free. Xóa bớt bản ghi hoặc xem Meloop Pro để ghi thêm. Bạn vẫn có thể lưu nhật ký buổi luyện.';
  }

  @override
  String get recordingPracticePaused =>
      'Buổi luyện đang tạm dừng. Tiếp tục buổi luyện trước khi ghi âm.';

  @override
  String get privacyTitle => 'Quyền riêng tư';

  @override
  String get privacyHeading => 'Âm nhạc là của bạn.\nNhật ký cũng vậy.';

  @override
  String get privacySubtitle => 'Bạn kiểm soát những gì mình ghi lại.';

  @override
  String get privacyLocalTitle => 'Nhật ký và âm thanh';

  @override
  String get privacyLocalBody =>
      'Nhật ký luyện tập được lưu cục bộ trên thiết bị Android của bạn. Luồng hỗ trợ không đọc hay tự đính kèm nhật ký, cơ sở dữ liệu hoặc bản ghi âm vào email.';

  @override
  String get privacyPermissionsTitle => 'Micro và lịch nhắc';

  @override
  String get privacyPermissionsBody =>
      'Màn riêng tư và hỗ trợ không yêu cầu quyền micro hay thông báo. Bạn có thể xem và thay đổi quyền của Meloop trong Cài đặt ứng dụng của Android.';

  @override
  String get privacyPurchasesTitle => 'Mua hàng và Meloop Pro';

  @override
  String get privacyPurchasesBody =>
      'Màn Pro hiện là chế độ xem thử, không thu tiền và chưa kết nối Google Play. Thông tin giao dịch của bản phát hành cần được công bố trong chính sách chính thức.';

  @override
  String get privacyDiagnosticsTitle => 'Chẩn đoán và lỗi';

  @override
  String get privacyDiagnosticsBody =>
      'Thông tin kỹ thuật trong email hỗ trợ mặc định tắt. Chỉ khi bạn chọn, bản nháp mới kèm phiên bản ứng dụng, phiên bản Android và mẫu thiết bị để bạn xem trước. Không kèm nội dung nhật ký, âm thanh hay thông tin giao dịch.';

  @override
  String get privacyChoicesTitle => 'Bạn có quyền lựa chọn';

  @override
  String get privacyChoicesBody =>
      'Bạn có thể sửa nội dung, bỏ thông tin kỹ thuật hoặc hủy bản nháp hỗ trợ. Nếu muốn chia sẻ bản ghi âm, bạn tự chọn và đính kèm bằng ứng dụng email. Meloop không tự gửi thư hoặc dữ liệu.';

  @override
  String get privacySummaryFootnote =>
      'Thông tin trên mô tả phiên bản ứng dụng hiện tại. Chính sách chính thức cần được xác nhận trước khi phát hành.';

  @override
  String get privacyNotPublished =>
      'Chính sách riêng tư chính thức chưa được công bố. Thông tin trên vẫn có thể đọc khi không có mạng.';

  @override
  String get privacyOpenPublished => 'Mở chính sách chính thức';

  @override
  String get privacyOpenFailed =>
      'Chưa thể mở liên kết. Bạn có thể thử lại hoặc sao chép liên kết để mở bằng trình duyệt.';

  @override
  String get privacyCopyLink => 'Sao chép liên kết';

  @override
  String get supportHeading => 'Mình đang lắng nghe.';

  @override
  String get supportSubtitle => 'Một góp ý nhỏ có thể giúp Meloop tốt hơn.';

  @override
  String get supportNotPublished =>
      'Địa chỉ hỗ trợ chưa được công bố. Bạn có thể soạn, xem trước và sao chép nội dung để gửi sau.';

  @override
  String get supportAddress => 'Địa chỉ hỗ trợ';

  @override
  String get supportSubject => 'Tiêu đề';

  @override
  String get supportSubjectHint => 'Bạn muốn chia sẻ điều gì?';

  @override
  String get supportDescription => 'Nội dung';

  @override
  String get supportDescriptionHint =>
      'Mô tả điều bạn gặp phải hoặc góp ý của bạn…';

  @override
  String supportDescriptionLimit(int limit) {
    return 'Tối đa $limit ký tự; có thể để trống.';
  }

  @override
  String supportSubjectInvalid(int limit) {
    return 'Nhập tiêu đề từ 1 đến $limit ký tự, không xuống dòng hoặc chứa ký tự điều khiển.';
  }

  @override
  String supportDescriptionInvalid(int limit) {
    return 'Nội dung tối đa $limit ký tự và không chứa ký tự điều khiển không hợp lệ.';
  }

  @override
  String get supportIncludeDiagnostics => 'Kèm thông tin kỹ thuật';

  @override
  String get supportDiagnosticsExplanation =>
      'Chỉ phiên bản ứng dụng, phiên bản Android và mẫu thiết bị. Bạn sẽ được xem trước khi mở email.';

  @override
  String supportDiagnosticsBlock(
    String appVersion,
    String androidVersion,
    String deviceModel,
  ) {
    return 'Thông tin kỹ thuật\nPhiên bản ứng dụng: $appVersion\nPhiên bản Android: $androidVersion\nMẫu thiết bị: $deviceModel';
  }

  @override
  String get supportPrivacyNote =>
      'Không tự động đính kèm nhật ký hay âm thanh. Meloop chỉ mở bản nháp để bạn sửa và gửi trong ứng dụng email.';

  @override
  String get supportPreview => 'Xem trước nội dung';

  @override
  String get supportPreviewFailed =>
      'Chưa thể lấy thông tin kỹ thuật. Nội dung vẫn được giữ. Hãy thử lại hoặc bỏ chọn thông tin kỹ thuật.';

  @override
  String get supportDraftHeading => 'Một lời nhắn của bạn.';

  @override
  String get supportReviewNote =>
      'Kiểm tra nội dung bên dưới. Bạn có thể quay lại sửa hoặc tiếp tục sửa trong ứng dụng email trước khi gửi.';

  @override
  String get supportEmptyBody => 'Chưa có nội dung.';

  @override
  String get supportCompose => 'Soạn email';

  @override
  String get supportEmailUnavailable =>
      'Không mở được ứng dụng email. Hãy sao chép địa chỉ và nội dung để liên hệ bằng cách khác.';

  @override
  String get supportCopyAddress => 'Sao chép địa chỉ';

  @override
  String get supportCopyDetails => 'Sao chép nội dung';

  @override
  String get supportEditDraft => 'Sửa nội dung';

  @override
  String get supportCopied => 'Đã sao chép.';

  @override
  String get supportCopyFailed =>
      'Chưa thể sao chép. Hãy thử lại hoặc chọn văn bản để sao chép.';

  @override
  String pitchRange(String lowest, String highest) {
    return 'Chromatic · $lowest – $highest';
  }

  @override
  String pitchReference(String note, String frequency) {
    return '$note = $frequency Hz';
  }

  @override
  String get pitchEmptyNote => '—';

  @override
  String get pitchNoSignal => 'Chưa có tín hiệu';

  @override
  String get pitchListening => 'Đang lắng nghe…';

  @override
  String get pitchRequestingPermission => 'Đang chờ quyền micro…';

  @override
  String get pitchWeakSignal => 'Chưa đủ tín hiệu';

  @override
  String get pitchWeakSignalHint =>
      'Tín hiệu yếu hoặc chưa ổn định. Chơi một nốt rõ và giữ đều, gần micro hơn một chút.';

  @override
  String pitchMeasurement(String frequency, String cents) {
    return '$frequency Hz · $cents cent';
  }

  @override
  String pitchCentsNegative(int cents) {
    return '−$cents cent';
  }

  @override
  String pitchCentsPositive(int cents) {
    return '+$cents cent';
  }

  @override
  String get pitchGaugeCenter => 'Đúng cao độ';

  @override
  String get pitchInstruction =>
      'Chơi một nốt rõ và đều, trong không gian yên tĩnh.';

  @override
  String get pitchLow => 'Hơi thấp · nâng cao độ một chút.';

  @override
  String get pitchInTune => 'Đúng cao độ. Giữ nốt thật đều.';

  @override
  String get pitchHigh => 'Hơi cao · hạ cao độ một chút.';

  @override
  String get pitchStart => 'Bật micro';

  @override
  String get pitchStop => 'Tắt micro';

  @override
  String get pitchStopping => 'Đang tắt micro…';

  @override
  String get pitchPermissionDenied =>
      'Quyền micro chưa được cấp. Bạn có thể thử cấp quyền lại hoặc mở cài đặt. Việc luyện tập và lưu nhật ký vẫn tiếp tục.';

  @override
  String get pitchPermissionBlocked =>
      'Quyền micro đã bị chặn. Cho phép micro trong cài đặt ứng dụng rồi thử lại. Bạn vẫn có thể luyện tập và lưu nhật ký.';

  @override
  String get pitchSettingsGuide =>
      'Trong Cài đặt Android, mở mục Ứng dụng, chọn Meloop, rồi Quyền và Micro. Cho phép khi dùng ứng dụng, quay lại rồi bấm Bật micro.';

  @override
  String get pitchOpenSettings => 'Mở cài đặt';

  @override
  String get pitchOpeningSettings => 'Đang mở cài đặt…';

  @override
  String get pitchSettingsFailed =>
      'Chưa mở được cài đặt tự động. Hãy mở Cài đặt Android theo hướng dẫn trên; bạn vẫn có thể quay lại buổi luyện.';

  @override
  String get pitchUnavailable =>
      'Kiểm tra cao độ chưa khả dụng trên thiết bị này. Bạn vẫn có thể quay lại luyện tập và lưu nhật ký.';

  @override
  String get pitchAudioBusy =>
      'Một công cụ âm thanh khác đang hoạt động. Dừng công cụ đó rồi thử lại; bộ đếm giờ vẫn tiếp tục.';

  @override
  String get pitchFailed =>
      'Chưa thể nghe micro. Hãy thử lại. Dữ liệu buổi luyện vẫn được giữ.';

  @override
  String get pitchStopFailed =>
      'Chưa thể xác nhận micro đã dừng. Bấm Tắt micro để thử lại; kết quả đo đã được xóa.';

  @override
  String get pitchPrivacy =>
      'Micro chỉ bật khi bạn cho phép. Âm thanh được phân tích trên thiết bị, không được lưu hay gửi đi.';

  @override
  String get pitchLimitations =>
      'Công cụ nhận từng nốt, không nhận hợp âm và có thể không phù hợp với mọi nhạc cụ.';

  @override
  String get pitchPreviewTitle => 'Xem thử UI cao độ';

  @override
  String get pitchPreviewExplanation =>
      'Xem các trạng thái đang nghe, nhận nốt, tín hiệu yếu và quyền bị từ chối bằng dữ liệu mô phỏng. Bản xem thử không bật micro và không truy cập nhật ký của bạn.';

  @override
  String get pitchPreviewOpen => 'Mở màn cao độ';

  @override
  String get pitchPreviewBadge =>
      'Xem thử UI · Dữ liệu mô phỏng · Không dùng micro';

  @override
  String get pitchPreviewScenario => 'Trạng thái muốn xem';

  @override
  String get pitchPreviewStartHint =>
      'Chọn trạng thái, sau đó bấm Bật micro để xem. Tắt micro sẽ xóa nốt và kim đo.';

  @override
  String get pitchPreviewListening => 'Đang nghe, chờ âm thanh';

  @override
  String get pitchPreviewInTune => 'Đã nhận nốt, đúng cao độ';

  @override
  String get pitchPreviewLow => 'Đã nhận nốt, hơi thấp';

  @override
  String get pitchPreviewHigh => 'Đã nhận nốt, hơi cao';

  @override
  String get pitchPreviewWeakSignal => 'Chưa đủ tín hiệu';

  @override
  String get pitchPreviewDenied => 'Quyền micro bị từ chối';

  @override
  String get pitchPreviewBlocked => 'Quyền micro bị chặn';
}
