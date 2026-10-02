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
}
