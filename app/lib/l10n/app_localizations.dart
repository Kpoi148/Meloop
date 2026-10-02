import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Meloop'**
  String get appTitle;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @processing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý…'**
  String get processing;

  /// No description provided for @saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get saving;

  /// No description provided for @retrying.
  ///
  /// In vi, this message translates to:
  /// **'Đang thử lại…'**
  String get retrying;

  /// No description provided for @requiredSuffix.
  ///
  /// In vi, this message translates to:
  /// **' *'**
  String get requiredSuffix;

  /// No description provided for @optionalSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (tùy chọn)'**
  String get optionalSuffix;

  /// No description provided for @requiredSemantics.
  ///
  /// In vi, this message translates to:
  /// **'bắt buộc'**
  String get requiredSemantics;

  /// No description provided for @optionalSemantics.
  ///
  /// In vi, this message translates to:
  /// **'tùy chọn'**
  String get optionalSemantics;

  /// No description provided for @requiredField.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập {label}.'**
  String requiredField(String label);

  /// No description provided for @requiredChoice.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn {label}.'**
  String requiredChoice(String label);

  /// No description provided for @invalidSingleLine.
  ///
  /// In vi, this message translates to:
  /// **'{label} không được có xuống dòng hoặc ký tự điều khiển.'**
  String invalidSingleLine(String label);

  /// No description provided for @maxCharacters.
  ///
  /// In vi, this message translates to:
  /// **'{label} tối đa {count} ký tự.'**
  String maxCharacters(String label, int count);

  /// No description provided for @invalidNoteControl.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú có ký tự điều khiển không hợp lệ.'**
  String get invalidNoteControl;

  /// No description provided for @noteMaxCharacters.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú tối đa 2.000 ký tự.'**
  String get noteMaxCharacters;

  /// No description provided for @integerRequired.
  ///
  /// In vi, this message translates to:
  /// **'{label} phải là số nguyên.'**
  String integerRequired(String label);

  /// No description provided for @integerRange.
  ///
  /// In vi, this message translates to:
  /// **'{label} phải từ {min} đến {max}.'**
  String integerRange(String label, int min, int max);

  /// No description provided for @validDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày từ 01/01/2000 đến hôm nay.'**
  String get validDateRange;

  /// No description provided for @clearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearch;

  /// No description provided for @searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm buổi luyện, ghi chú…'**
  String get searchHint;

  /// No description provided for @ratingSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{label} {value} trên 5'**
  String ratingSemantics(String label, int value);

  /// No description provided for @moodRatingHint.
  ///
  /// In vi, this message translates to:
  /// **'1 · Không vui → 5 · Rất vui. Bấm lại để bỏ chọn.'**
  String get moodRatingHint;

  /// No description provided for @focusRatingHint.
  ///
  /// In vi, this message translates to:
  /// **'1 · Khó tập trung → 5 · Rất tập trung. Bấm lại để bỏ chọn.'**
  String get focusRatingHint;

  /// No description provided for @genericFailure.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể hoàn tất. Vui lòng thử lại.'**
  String get genericFailure;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện'**
  String get navHistory;

  /// No description provided for @navProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageViCode.
  ///
  /// In vi, this message translates to:
  /// **'VI'**
  String get languageViCode;

  /// No description provided for @languageEnCode.
  ///
  /// In vi, this message translates to:
  /// **'EN'**
  String get languageEnCode;

  /// No description provided for @chooseLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get chooseLanguage;

  /// No description provided for @languageSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ngôn ngữ.'**
  String get languageSaved;

  /// No description provided for @languageSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể lưu ngôn ngữ. Vui lòng thử lại.'**
  String get languageSaveFailed;

  /// No description provided for @welcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Một chút âm nhạc.\nMỗi ngày.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện tập, ghi lại và nhìn thấy\nhành trình của chính bạn.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomePrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Không cần tài khoản. Nhật ký lưu trên thiết bị.'**
  String get welcomePrivacy;

  /// No description provided for @createFirstProfile.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hồ sơ đầu tiên'**
  String get createFirstProfile;

  /// No description provided for @continueWithInstrument.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với nhạc cụ của tôi'**
  String get continueWithInstrument;

  /// No description provided for @instrumentPickerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn chơi\nnhạc cụ nào?'**
  String get instrumentPickerTitle;

  /// No description provided for @instrumentPickerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một nhạc cụ để tiếp tục hành trình.'**
  String get instrumentPickerSubtitle;

  /// No description provided for @manageInstruments.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý nhạc cụ'**
  String get manageInstruments;

  /// No description provided for @selected.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn'**
  String get selected;

  /// No description provided for @addInstrument.
  ///
  /// In vi, this message translates to:
  /// **'Thêm nhạc cụ'**
  String get addInstrument;

  /// No description provided for @freeProfileLimit.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí: tối đa 3 hồ sơ nhạc cụ.'**
  String get freeProfileLimit;

  /// No description provided for @noPracticeSessions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có buổi luyện'**
  String get noPracticeSessions;

  /// No description provided for @profileSessionsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện của hồ sơ này sẽ hiện ở đây.'**
  String get profileSessionsEmptyMessage;

  /// No description provided for @openWelcomePreview.
  ///
  /// In vi, this message translates to:
  /// **'Xem màn chào Tempo'**
  String get openWelcomePreview;

  /// No description provided for @savedSessions.
  ///
  /// In vi, this message translates to:
  /// **'{count} buổi luyện đã lưu'**
  String savedSessions(int count);

  /// No description provided for @unfinishedSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn còn một buổi luyện.'**
  String get unfinishedSessionTitle;

  /// No description provided for @unfinishedSessionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất hoặc hủy buổi luyện hiện tại trước khi đổi nhạc cụ.'**
  String get unfinishedSessionMessage;

  /// No description provided for @understood.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get understood;

  /// No description provided for @profileFormTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc cụ của bạn'**
  String get profileFormTitle;

  /// No description provided for @profileQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chơi nhạc cụ gì?'**
  String get profileQuestion;

  /// No description provided for @profileSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn âm thanh thuộc về bạn.'**
  String get profileSubtitle;

  /// No description provided for @instrumentOtherDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc cụ mang âm sắc của riêng bạn'**
  String get instrumentOtherDescription;

  /// No description provided for @customInstrumentName.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhạc cụ'**
  String get customInstrumentName;

  /// No description provided for @customInstrumentHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Saxophone'**
  String get customInstrumentHint;

  /// No description provided for @profileName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hồ sơ'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Guitar của tôi'**
  String get profileNameHint;

  /// No description provided for @saveProfile.
  ///
  /// In vi, this message translates to:
  /// **'Lưu hồ sơ'**
  String get saveProfile;

  /// No description provided for @profileFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Có thể đổi tên sau. Không cần đăng nhập.'**
  String get profileFootnote;

  /// No description provided for @instrumentGuitar.
  ///
  /// In vi, this message translates to:
  /// **'Guitar'**
  String get instrumentGuitar;

  /// No description provided for @instrumentPiano.
  ///
  /// In vi, this message translates to:
  /// **'Piano'**
  String get instrumentPiano;

  /// No description provided for @instrumentUkulele.
  ///
  /// In vi, this message translates to:
  /// **'Ukulele'**
  String get instrumentUkulele;

  /// No description provided for @instrumentViolin.
  ///
  /// In vi, this message translates to:
  /// **'Violin'**
  String get instrumentViolin;

  /// No description provided for @instrumentFlute.
  ///
  /// In vi, this message translates to:
  /// **'Sáo'**
  String get instrumentFlute;

  /// No description provided for @instrumentDrums.
  ///
  /// In vi, this message translates to:
  /// **'Bộ gõ'**
  String get instrumentDrums;

  /// No description provided for @instrumentOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get instrumentOther;

  /// No description provided for @defaultProfileName.
  ///
  /// In vi, this message translates to:
  /// **'Guitar của tôi'**
  String get defaultProfileName;

  /// No description provided for @samplePianoProfile.
  ///
  /// In vi, this message translates to:
  /// **'Piano buổi tối'**
  String get samplePianoProfile;

  /// No description provided for @overview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get overview;

  /// No description provided for @changeInstrument.
  ///
  /// In vi, this message translates to:
  /// **'Đổi nhạc cụ'**
  String get changeInstrument;

  /// No description provided for @lastSevenDays.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày gần nhất'**
  String get lastSevenDays;

  /// No description provided for @details.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết ›'**
  String get details;

  /// No description provided for @practiceMinutes.
  ///
  /// In vi, this message translates to:
  /// **'phút luyện'**
  String get practiceMinutes;

  /// No description provided for @practiceSessions.
  ///
  /// In vi, this message translates to:
  /// **'buổi luyện'**
  String get practiceSessions;

  /// No description provided for @consecutiveDays.
  ///
  /// In vi, this message translates to:
  /// **'ngày liên tiếp'**
  String get consecutiveDays;

  /// No description provided for @weeklyGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu tuần'**
  String get weeklyGoal;

  /// No description provided for @goalProgress.
  ///
  /// In vi, this message translates to:
  /// **'{current}/{target} ngày'**
  String goalProgress(int current, int target);

  /// No description provided for @mondayToSunday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Hai – Chủ nhật'**
  String get mondayToSunday;

  /// No description provided for @createPractice.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi luyện'**
  String get createPractice;

  /// No description provided for @continuePractice.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục buổi luyện'**
  String get continuePractice;

  /// No description provided for @practiceTools.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ'**
  String get practiceTools;

  /// No description provided for @recentSession.
  ///
  /// In vi, this message translates to:
  /// **'Buổi gần nhất'**
  String get recentSession;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả ›'**
  String get viewAll;

  /// No description provided for @sampleSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luyện gam C'**
  String get sampleSessionTitle;

  /// No description provided for @sampleSessionMeta.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · 35 phút · 80 BPM'**
  String get sampleSessionMeta;

  /// No description provided for @sampleSessionNotes.
  ///
  /// In vi, this message translates to:
  /// **'Gam C trưởng, chuyển hợp âm C – G – Am – F.'**
  String get sampleSessionNotes;

  /// No description provided for @nextPracticeUpper.
  ///
  /// In vi, this message translates to:
  /// **'CHO LẦN LUYỆN TIẾP'**
  String get nextPracticeUpper;

  /// No description provided for @sampleNextNotes.
  ///
  /// In vi, this message translates to:
  /// **'Giữ nhịp ở 80 BPM, thả lỏng bàn tay.'**
  String get sampleNextNotes;

  /// No description provided for @setupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo buổi luyện'**
  String get setupTitle;

  /// No description provided for @newPracticeUpper.
  ///
  /// In vi, this message translates to:
  /// **'BUỔI LUYỆN MỚI'**
  String get newPracticeUpper;

  /// No description provided for @setupQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn\nmuốn tập gì?'**
  String get setupQuestion;

  /// No description provided for @sessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên buổi luyện'**
  String get sessionTitle;

  /// No description provided for @sessionTitleHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Luyện gam C'**
  String get sessionTitleHint;

  /// No description provided for @sessionTitleHelper.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên để dễ tìm lại. Có thể đổi khi xem lại.'**
  String get sessionTitleHelper;

  /// No description provided for @timerStartsHint.
  ///
  /// In vi, this message translates to:
  /// **'Bộ đếm bắt đầu khi bạn bấm Bắt đầu luyện.'**
  String get timerStartsHint;

  /// No description provided for @startPractice.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu luyện'**
  String get startPractice;

  /// No description provided for @timerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện'**
  String get timerTitle;

  /// No description provided for @timerOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn buổi luyện'**
  String get timerOptions;

  /// No description provided for @timerOptionalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên buổi luyện · tùy chọn'**
  String get timerOptionalTitle;

  /// No description provided for @setPracticeName.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tên buổi luyện'**
  String get setPracticeName;

  /// No description provided for @timerPaused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get timerPaused;

  /// No description provided for @timerRunning.
  ///
  /// In vi, this message translates to:
  /// **'Đang luyện'**
  String get timerRunning;

  /// No description provided for @practiceTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian luyện tập'**
  String get practiceTime;

  /// No description provided for @pause.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get resume;

  /// No description provided for @finish.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get finish;

  /// No description provided for @recoveredDraftTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục buổi luyện'**
  String get recoveredDraftTitle;

  /// No description provided for @recoveredDraftMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian đã lưu được giữ nguyên. Buổi luyện được tạm dừng sau khi mở lại.'**
  String get recoveredDraftMessage;

  /// No description provided for @historySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những nốt nhạc làm nên hành trình.'**
  String get historySubtitle;

  /// No description provided for @practiceTodayLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get practiceTodayLabel;

  /// No description provided for @practiceYesterdayLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get practiceYesterdayLabel;

  /// No description provided for @practiceRatingShort.
  ///
  /// In vi, this message translates to:
  /// **'{value}/5'**
  String practiceRatingShort(int value);

  /// No description provided for @practiceDurationWithBpm.
  ///
  /// In vi, this message translates to:
  /// **'{duration} · {bpm} BPM'**
  String practiceDurationWithBpm(String duration, int bpm);

  /// No description provided for @practiceSort.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp'**
  String get practiceSort;

  /// No description provided for @practiceFilters.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get practiceFilters;

  /// No description provided for @practiceApplyFilters.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get practiceApplyFilters;

  /// No description provided for @practiceClearFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get practiceClearFilters;

  /// No description provided for @practiceNewest.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất'**
  String get practiceNewest;

  /// No description provided for @practiceOldest.
  ///
  /// In vi, this message translates to:
  /// **'Cũ nhất'**
  String get practiceOldest;

  /// No description provided for @practiceClearSearchAndFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm và bộ lọc'**
  String get practiceClearSearchAndFilters;

  /// No description provided for @practiceNoResultsMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khóa khác hoặc thay đổi bộ lọc để tìm buổi luyện của bạn.'**
  String get practiceNoResultsMessage;

  /// No description provided for @practiceEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu buổi luyện đầu tiên, ghi lại những điều bạn muốn nhớ.'**
  String get practiceEmptyMessage;

  /// No description provided for @practiceSessionDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết buổi luyện'**
  String get practiceSessionDetails;

  /// No description provided for @practiceFocusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tập trung'**
  String get practiceFocusLabel;

  /// No description provided for @practiceEmptyRating.
  ///
  /// In vi, this message translates to:
  /// **'—'**
  String get practiceEmptyRating;

  /// No description provided for @sessionOptionalSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (không bắt buộc)'**
  String get sessionOptionalSuffix;

  /// No description provided for @sessionMoodHint.
  ///
  /// In vi, this message translates to:
  /// **'1 · Không vui → 5 · Rất vui · Bấm lại để bỏ chọn.'**
  String get sessionMoodHint;

  /// No description provided for @sessionFocusHint.
  ///
  /// In vi, this message translates to:
  /// **'1 · Khó tập trung → 5 · Rất tập trung · Bấm lại để bỏ chọn.'**
  String get sessionFocusHint;

  /// No description provided for @nextPracticeHint.
  ///
  /// In vi, this message translates to:
  /// **'Một lời nhắn cho bạn ở buổi sau…'**
  String get nextPracticeHint;

  /// No description provided for @practiceSampleGuitarDifficulty.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển từ G sang Am cần mượt hơn.'**
  String get practiceSampleGuitarDifficulty;

  /// No description provided for @practiceRatingSuffix.
  ///
  /// In vi, this message translates to:
  /// **' / 5'**
  String get practiceRatingSuffix;

  /// No description provided for @practiceNextEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn bạn ở buổi luyện tiếp theo.'**
  String get practiceNextEmpty;

  /// No description provided for @editSessionJournal.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhật ký'**
  String get editSessionJournal;

  /// No description provided for @editSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa buổi luyện'**
  String get editSessionTitle;

  /// No description provided for @editSessionHeading.
  ///
  /// In vi, this message translates to:
  /// **'Nhìn lại buổi luyện.'**
  String get editSessionHeading;

  /// No description provided for @saveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get saveChanges;

  /// No description provided for @sessionDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng (phút)'**
  String get sessionDurationMinutes;

  /// No description provided for @sessionPracticeBpm.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ luyện (BPM)'**
  String get sessionPracticeBpm;

  /// No description provided for @notRequired.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc'**
  String get notRequired;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa buổi luyện?'**
  String get deleteSessionTitle;

  /// No description provided for @sessionDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa buổi luyện.'**
  String get sessionDeleted;

  /// No description provided for @deleteSessionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể xóa. Buổi luyện và bản ghi âm vẫn được giữ. Vui lòng thử lại.'**
  String get deleteSessionFailed;

  /// No description provided for @deleteRecordingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi âm?'**
  String get deleteRecordingTitle;

  /// No description provided for @deleteRecording.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản ghi'**
  String get deleteRecording;

  /// No description provided for @deleteRecordingMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ bản ghi âm này bị xóa. Nhật ký buổi luyện được giữ nguyên.'**
  String get deleteRecordingMessage;

  /// No description provided for @listenRecording.
  ///
  /// In vi, this message translates to:
  /// **'Nghe lại'**
  String get listenRecording;

  /// No description provided for @exportRecording.
  ///
  /// In vi, this message translates to:
  /// **'Xuất bản ghi'**
  String get exportRecording;

  /// No description provided for @recordingActionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở bản ghi âm. Vui lòng thử lại.'**
  String get recordingActionFailed;

  /// No description provided for @noSessionRecordings.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản ghi âm.'**
  String get noSessionRecordings;

  /// No description provided for @noSessionRecordingsMessage.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện này chưa có bản ghi âm được lưu.'**
  String get noSessionRecordingsMessage;

  /// No description provided for @practiceRecordingTake.
  ///
  /// In vi, this message translates to:
  /// **'{title} · Lần {take}'**
  String practiceRecordingTake(String title, int take);

  /// No description provided for @practiceWhatWasPracticed.
  ///
  /// In vi, this message translates to:
  /// **'Đã luyện'**
  String get practiceWhatWasPracticed;

  /// No description provided for @practiceSessionRecordings.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi của buổi này'**
  String get practiceSessionRecordings;

  /// No description provided for @practiceNotRated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đánh giá'**
  String get practiceNotRated;

  /// No description provided for @practiceNoNotes.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ghi chú.'**
  String get practiceNoNotes;

  /// No description provided for @practiceToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay · {date}'**
  String practiceToday(String date);

  /// No description provided for @practiceYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua · {date}'**
  String practiceYesterday(String date);

  /// No description provided for @practiceDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String practiceDurationMinutes(int minutes);

  /// No description provided for @practiceDurationSeconds.
  ///
  /// In vi, this message translates to:
  /// **'{seconds} giây'**
  String practiceDurationSeconds(int seconds);

  /// No description provided for @practiceHoursMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ {minutes} phút'**
  String practiceHoursMinutes(int hours, int minutes);

  /// No description provided for @practiceBpm.
  ///
  /// In vi, this message translates to:
  /// **'{bpm} BPM'**
  String practiceBpm(int bpm);

  /// No description provided for @practiceMoodScore.
  ///
  /// In vi, this message translates to:
  /// **'Cảm xúc {value}/5'**
  String practiceMoodScore(int value);

  /// No description provided for @practiceFocusScore.
  ///
  /// In vi, this message translates to:
  /// **'Tập trung {value}/5'**
  String practiceFocusScore(int value);

  /// No description provided for @practiceRecordingCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bản ghi'**
  String practiceRecordingCount(int count);

  /// No description provided for @practiceRatingValue.
  ///
  /// In vi, this message translates to:
  /// **'{value} / 5'**
  String practiceRatingValue(int value);

  /// No description provided for @practiceSampleRhythm.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp điệu cơ bản'**
  String get practiceSampleRhythm;

  /// No description provided for @practiceSampleSong.
  ///
  /// In vi, this message translates to:
  /// **'Ôn bài nhạc yêu thích'**
  String get practiceSampleSong;

  /// No description provided for @practiceSampleMinorScale.
  ///
  /// In vi, this message translates to:
  /// **'Luyện gam Am'**
  String get practiceSampleMinorScale;

  /// No description provided for @practiceSampleTechnique.
  ///
  /// In vi, this message translates to:
  /// **'Luyện kỹ thuật tay'**
  String get practiceSampleTechnique;

  /// No description provided for @practiceSampleReview.
  ///
  /// In vi, this message translates to:
  /// **'Ôn lại những đoạn khó'**
  String get practiceSampleReview;

  /// No description provided for @practiceSampleSlowPractice.
  ///
  /// In vi, this message translates to:
  /// **'Luyện chậm, giữ nhịp đều'**
  String get practiceSampleSlowPractice;

  /// No description provided for @practiceSampleScaleNotes.
  ///
  /// In vi, this message translates to:
  /// **'Gam C trưởng, luyện từng nốt rõ tiếng theo hai chiều.'**
  String get practiceSampleScaleNotes;

  /// No description provided for @practiceSampleSteadyNotes.
  ///
  /// In vi, this message translates to:
  /// **'Luyện chậm từng đoạn, giữ nhịp đều và rõ tiếng.'**
  String get practiceSampleSteadyNotes;

  /// No description provided for @practiceSampleDifficulty.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn chuyển cần mượt hơn, giữ nhịp khi tăng tốc độ.'**
  String get practiceSampleDifficulty;

  /// No description provided for @unfinishedPractice.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện chưa hoàn tất'**
  String get unfinishedPractice;

  /// No description provided for @finishPractice.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get finishPractice;

  /// No description provided for @timeRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian'**
  String get timeRange;

  /// No description provided for @all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get all;

  /// No description provided for @sevenDays.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày'**
  String get sevenDays;

  /// No description provided for @thirtyDays.
  ///
  /// In vi, this message translates to:
  /// **'30 ngày'**
  String get thirtyDays;

  /// No description provided for @noMatchingSessions.
  ///
  /// In vi, this message translates to:
  /// **'Không có buổi luyện phù hợp.'**
  String get noMatchingSessions;

  /// No description provided for @clearSearchAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tìm kiếm'**
  String get clearSearchAction;

  /// No description provided for @sampleSessionDate.
  ///
  /// In vi, this message translates to:
  /// **'23/09/2026 · 30 phút'**
  String get sampleSessionDate;

  /// No description provided for @showcaseSaveCount.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu UI · {count} lần lưu mẫu hoàn tất. Không ghi dữ liệu lên thiết bị.'**
  String showcaseSaveCount(int count);

  /// No description provided for @progressHeading.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày,\nmột bước tiến.'**
  String get progressHeading;

  /// No description provided for @noProgressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu tiến độ.'**
  String get noProgressTitle;

  /// No description provided for @noProgressMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất một buổi luyện để nhìn lại hành trình.'**
  String get noProgressMessage;

  /// No description provided for @settingsHeading.
  ///
  /// In vi, this message translates to:
  /// **'Theo cách bạn.'**
  String get settingsHeading;

  /// No description provided for @settingsFreePlan.
  ///
  /// In vi, this message translates to:
  /// **'FREE'**
  String get settingsFreePlan;

  /// No description provided for @settingsEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'MELOOP · KHÔNG GIAN CỦA BẠN'**
  String get settingsEyebrow;

  /// No description provided for @settingsManageProfiles.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý hồ sơ nhạc cụ'**
  String get settingsManageProfiles;

  /// No description provided for @settingsProDescription.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hồ sơ nhạc cụ và lọc thống kê nâng cao.'**
  String get settingsProDescription;

  /// No description provided for @settingsExplorePro.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá Pro'**
  String get settingsExplorePro;

  /// No description provided for @settingsPersonalGroup.
  ///
  /// In vi, this message translates to:
  /// **'Theo cách của bạn'**
  String get settingsPersonalGroup;

  /// No description provided for @settingsReminderOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get settingsReminderOff;

  /// No description provided for @settingsDeviceData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trên thiết bị'**
  String get settingsDeviceData;

  /// No description provided for @settingsInformationGroup.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin & hỗ trợ'**
  String get settingsInformationGroup;

  /// No description provided for @settingsPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get settingsPrivacy;

  /// No description provided for @settingsContactSupport.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get settingsContactSupport;

  /// No description provided for @settingsRestorePro.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục Pro'**
  String get settingsRestorePro;

  /// No description provided for @settingsVersion.
  ///
  /// In vi, this message translates to:
  /// **'Meloop · {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsStudioCredit.
  ///
  /// In vi, this message translates to:
  /// **'Made with care by Moss Studio'**
  String get settingsStudioCredit;

  /// No description provided for @instrumentProfilesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ nhạc cụ'**
  String get instrumentProfilesTitle;

  /// No description provided for @instrumentProfilesHeading.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi nhạc cụ,\nmột hành trình.'**
  String get instrumentProfilesHeading;

  /// No description provided for @instrumentProfilesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những âm thanh làm nên bạn.'**
  String get instrumentProfilesSubtitle;

  /// No description provided for @profileInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang sử dụng'**
  String get profileInUse;

  /// No description provided for @profileArchived.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get profileArchived;

  /// No description provided for @editProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hồ sơ'**
  String get editProfile;

  /// No description provided for @archiveProfile.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get archiveProfile;

  /// No description provided for @reactivateProfile.
  ///
  /// In vi, this message translates to:
  /// **'Kích hoạt lại'**
  String get reactivateProfile;

  /// No description provided for @freeProfilesNote.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí có 3 hồ sơ. Lưu trữ giữ nguyên lịch sử và không giải phóng suất hồ sơ.'**
  String get freeProfilesNote;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In vi, this message translates to:
  /// **'{language}'**
  String settingsLanguageDescription(String language);

  /// No description provided for @componentCatalog.
  ///
  /// In vi, this message translates to:
  /// **'Bộ thành phần UI'**
  String get componentCatalog;

  /// No description provided for @openSessionForm.
  ///
  /// In vi, this message translates to:
  /// **'Xem form lưu buổi luyện'**
  String get openSessionForm;

  /// No description provided for @simulateNextSaveFailure.
  ///
  /// In vi, this message translates to:
  /// **'Lần lưu tiếp theo gặp lỗi'**
  String get simulateNextSaveFailure;

  /// No description provided for @saveSessionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu buổi luyện'**
  String get saveSessionTitle;

  /// No description provided for @sessionFormHeading.
  ///
  /// In vi, this message translates to:
  /// **'Một buổi luyện,\nmột bước tiến.'**
  String get sessionFormHeading;

  /// No description provided for @sessionFormTitleHint.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện'**
  String get sessionFormTitleHint;

  /// No description provided for @sessionFormSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại điều bạn muốn nhớ.'**
  String get sessionFormSubtitle;

  /// No description provided for @practiceDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày luyện'**
  String get practiceDate;

  /// No description provided for @hours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In vi, this message translates to:
  /// **'Giây'**
  String get seconds;

  /// No description provided for @durationRange.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng phải từ 1 giây đến 24 giờ.'**
  String get durationRange;

  /// No description provided for @mood.
  ///
  /// In vi, this message translates to:
  /// **'Cảm xúc'**
  String get mood;

  /// No description provided for @focusLevel.
  ///
  /// In vi, this message translates to:
  /// **'Mức độ tập trung'**
  String get focusLevel;

  /// No description provided for @practicedWhat.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã luyện gì?'**
  String get practicedWhat;

  /// No description provided for @practicedHint.
  ///
  /// In vi, this message translates to:
  /// **'Gam, hợp âm, bài nhạc…'**
  String get practicedHint;

  /// No description provided for @difficulty.
  ///
  /// In vi, this message translates to:
  /// **'Điều còn vướng'**
  String get difficulty;

  /// No description provided for @difficultyHint.
  ///
  /// In vi, this message translates to:
  /// **'Một đoạn khó, một điều muốn cải thiện…'**
  String get difficultyHint;

  /// No description provided for @nextPractice.
  ///
  /// In vi, this message translates to:
  /// **'Cho lần luyện tiếp'**
  String get nextPractice;

  /// No description provided for @savePractice.
  ///
  /// In vi, this message translates to:
  /// **'Lưu buổi luyện'**
  String get savePractice;

  /// No description provided for @discardChangesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In vi, this message translates to:
  /// **'Những thay đổi chưa lưu sẽ bị bỏ.'**
  String get discardChangesMessage;

  /// No description provided for @discardChanges.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get discardChanges;

  /// No description provided for @continueEditing.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục sửa'**
  String get continueEditing;

  /// No description provided for @saveSessionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể lưu buổi luyện. Nội dung của bạn vẫn ở đây. Vui lòng thử lại.'**
  String get saveSessionFailed;

  /// No description provided for @catalogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành phần dùng chung'**
  String get catalogTitle;

  /// No description provided for @catalogHeading.
  ///
  /// In vi, this message translates to:
  /// **'Cùng một nhịp\nthiết kế.'**
  String get catalogHeading;

  /// No description provided for @catalogSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu UI Tempo · dữ liệu minh họa chỉ nằm trong bộ nhớ.'**
  String get catalogSubtitle;

  /// No description provided for @catalogButtons.
  ///
  /// In vi, this message translates to:
  /// **'Nút & trạng thái đang lưu'**
  String get catalogButtons;

  /// No description provided for @catalogFields.
  ///
  /// In vi, this message translates to:
  /// **'Ô nhập & lỗi tại trường'**
  String get catalogFields;

  /// No description provided for @catalogChoices.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn & tab'**
  String get catalogChoices;

  /// No description provided for @catalogDialogs.
  ///
  /// In vi, this message translates to:
  /// **'Hộp thoại & thông báo'**
  String get catalogDialogs;

  /// No description provided for @catalogStates.
  ///
  /// In vi, this message translates to:
  /// **'Tải / trống / lỗi'**
  String get catalogStates;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @unavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không khả dụng'**
  String get unavailable;

  /// No description provided for @addProfile.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hồ sơ'**
  String get addProfile;

  /// No description provided for @deleteSession.
  ///
  /// In vi, this message translates to:
  /// **'Xóa buổi luyện'**
  String get deleteSession;

  /// No description provided for @endPractice.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get endPractice;

  /// No description provided for @profileHelper.
  ///
  /// In vi, this message translates to:
  /// **'1–50 ký tự. Giữ nội dung nếu lưu thất bại.'**
  String get profileHelper;

  /// No description provided for @tempoBpm.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ (BPM)'**
  String get tempoBpm;

  /// No description provided for @metronomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Máy đếm nhịp'**
  String get metronomeTitle;

  /// No description provided for @metronomeBpmUnit.
  ///
  /// In vi, this message translates to:
  /// **'nhịp / phút'**
  String get metronomeBpmUnit;

  /// No description provided for @decreaseMetronomeBpm.
  ///
  /// In vi, this message translates to:
  /// **'Giảm nhịp'**
  String get decreaseMetronomeBpm;

  /// No description provided for @increaseMetronomeBpm.
  ///
  /// In vi, this message translates to:
  /// **'Tăng nhịp'**
  String get increaseMetronomeBpm;

  /// No description provided for @startMetronome.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get startMetronome;

  /// No description provided for @stopMetronome.
  ///
  /// In vi, this message translates to:
  /// **'Dừng máy đếm nhịp'**
  String get stopMetronome;

  /// No description provided for @metronomeFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn ở phách đầu để dễ bắt nhịp.\nÂm thanh phát trực tiếp trên thiết bị của bạn.'**
  String get metronomeFootnote;

  /// No description provided for @metronomeCurrentBeat.
  ///
  /// In vi, this message translates to:
  /// **'Phách {current} / {total}'**
  String metronomeCurrentBeat(int current, int total);

  /// No description provided for @metronomeBpmRangeError.
  ///
  /// In vi, this message translates to:
  /// **'Tốc độ phải từ {min} đến {max} BPM.'**
  String metronomeBpmRangeError(int min, int max);

  /// No description provided for @metronomeBeatsRangeError.
  ///
  /// In vi, this message translates to:
  /// **'Số phách mỗi ô nhịp phải từ {min} đến {max}.'**
  String metronomeBeatsRangeError(int min, int max);

  /// No description provided for @metronomeAudioBusy.
  ///
  /// In vi, this message translates to:
  /// **'Một công cụ âm thanh khác đang hoạt động. Hãy dừng công cụ đó trước khi bật máy đếm nhịp.'**
  String get metronomeAudioBusy;

  /// No description provided for @bpm.
  ///
  /// In vi, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @validateData.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra dữ liệu'**
  String get validateData;

  /// No description provided for @beatsPerBar.
  ///
  /// In vi, this message translates to:
  /// **'Số phách mỗi ô nhịp'**
  String get beatsPerBar;

  /// No description provided for @beats.
  ///
  /// In vi, this message translates to:
  /// **'{count} phách'**
  String beats(int count);

  /// No description provided for @reminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lịch luyện'**
  String get reminder;

  /// No description provided for @reminderDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc một chút âm nhạc mỗi ngày.'**
  String get reminderDescription;

  /// No description provided for @attachDiagnostics.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm thông tin chẩn đoán'**
  String get attachDiagnostics;

  /// No description provided for @attachDiagnosticsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khi bạn chủ động chọn.'**
  String get attachDiagnosticsDescription;

  /// No description provided for @openConfirmDialog.
  ///
  /// In vi, this message translates to:
  /// **'Mở hộp thoại xác nhận'**
  String get openConfirmDialog;

  /// No description provided for @deleteSessionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện này sẽ được xóa khỏi nhật ký và thống kê. Bản ghi âm vẫn được giữ riêng.'**
  String get deleteSessionMessage;

  /// No description provided for @openChoiceSheet.
  ///
  /// In vi, this message translates to:
  /// **'Mở bảng lựa chọn'**
  String get openChoiceSheet;

  /// No description provided for @tempoComponents.
  ///
  /// In vi, this message translates to:
  /// **'Bộ thành phần Tempo'**
  String get tempoComponents;

  /// No description provided for @sharedThemeNotice.
  ///
  /// In vi, this message translates to:
  /// **'Các màn hình dùng cùng theme, font, màu và icon.'**
  String get sharedThemeNotice;

  /// No description provided for @showNotification.
  ///
  /// In vi, this message translates to:
  /// **'Hiện thông báo'**
  String get showNotification;

  /// No description provided for @sampleActionComplete.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất thao tác mẫu.'**
  String get sampleActionComplete;

  /// No description provided for @journalOnDevice.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký lưu trên thiết bị.'**
  String get journalOnDevice;

  /// No description provided for @sessionSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu buổi luyện.'**
  String get sessionSaved;

  /// No description provided for @saveFailedKeepsContent.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể lưu. Nội dung vẫn ở đây.'**
  String get saveFailedKeepsContent;

  /// No description provided for @loadingSessions.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải buổi luyện…'**
  String get loadingSessions;

  /// No description provided for @journeyStartsToday.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình bắt đầu từ hôm nay.'**
  String get journeyStartsToday;

  /// No description provided for @saveFirstSession.
  ///
  /// In vi, this message translates to:
  /// **'Lưu buổi luyện đầu tiên của bạn.'**
  String get saveFirstSession;

  /// No description provided for @loadSessionsFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tải buổi luyện.'**
  String get loadSessionsFailed;

  /// No description provided for @dataKeptRetry.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng thử lại. Dữ liệu của bạn vẫn được giữ.'**
  String get dataKeptRetry;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @proTitle.
  ///
  /// In vi, this message translates to:
  /// **'Meloop Pro'**
  String get proTitle;

  /// No description provided for @proOneTimeBadge.
  ///
  /// In vi, this message translates to:
  /// **'MUA MỘT LẦN · KHÔNG GIA HẠN'**
  String get proOneTimeBadge;

  /// No description provided for @proHeading.
  ///
  /// In vi, this message translates to:
  /// **'Thêm không gian\ncho đam mê.'**
  String get proHeading;

  /// No description provided for @proSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Một người bạn đồng hành, theo cách của bạn.'**
  String get proSubtitle;

  /// No description provided for @proIllustrativePrice.
  ///
  /// In vi, this message translates to:
  /// **'49.000đ'**
  String get proIllustrativePrice;

  /// No description provided for @proPriceCaption.
  ///
  /// In vi, this message translates to:
  /// **'Giá minh họa · Mua một lần'**
  String get proPriceCaption;

  /// No description provided for @proProfilesBenefit.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hồ sơ nhạc cụ'**
  String get proProfilesBenefit;

  /// No description provided for @proProfilesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tách riêng nhật ký cho mỗi âm sắc bạn yêu.'**
  String get proProfilesDescription;

  /// No description provided for @proFiltersBenefit.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc tiến độ nâng cao'**
  String get proFiltersBenefit;

  /// No description provided for @proFiltersDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem các khoảng thời gian dài hơn hoặc tùy chọn.'**
  String get proFiltersDescription;

  /// No description provided for @proFreeFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký, công cụ, ghi âm, mục tiêu, lịch nhắc, sao lưu và xuất âm thanh vẫn miễn phí.'**
  String get proFreeFeatures;

  /// No description provided for @proPreviewTry.
  ///
  /// In vi, this message translates to:
  /// **'Dùng thử Meloop Pro'**
  String get proPreviewTry;

  /// No description provided for @proPreviewActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem thử Meloop Pro'**
  String get proPreviewActive;

  /// No description provided for @proPreviewPlan.
  ///
  /// In vi, this message translates to:
  /// **'PRO · XEM THỬ'**
  String get proPreviewPlan;

  /// No description provided for @proPreviewFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Bản UI mô phỏng quyền Pro, không có giao dịch thật.\nGiá chính thức do cửa hàng cung cấp.'**
  String get proPreviewFootnote;

  /// No description provided for @proPreviewConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem thử Meloop Pro'**
  String get proPreviewConfirmTitle;

  /// No description provided for @proPreviewConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này bật chế độ xem thử Pro để bạn trải nghiệm giao diện và tạo thêm hồ sơ. Không thu tiền, không kết nối cửa hàng.'**
  String get proPreviewConfirmMessage;

  /// No description provided for @proPreviewEnable.
  ///
  /// In vi, this message translates to:
  /// **'Bật xem thử'**
  String get proPreviewEnable;

  /// No description provided for @proPreviewEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật Pro để xem thử.'**
  String get proPreviewEnabled;

  /// No description provided for @proPreviewFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể bật Pro. Dữ liệu của bạn vẫn được giữ. Hãy thử lại.'**
  String get proPreviewFailed;

  /// No description provided for @proPreviewActiveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Meloop Pro đang bật để xem thử.'**
  String get proPreviewActiveTitle;

  /// No description provided for @proPreviewActiveMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể tạo thêm hồ sơ trong chế độ xem thử. Không có khoản thanh toán nào được thực hiện.'**
  String get proPreviewActiveMessage;

  /// No description provided for @proRestoreTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục giao dịch'**
  String get proRestoreTransaction;

  /// No description provided for @proRestoreFootnote.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục với cùng tài khoản và cửa hàng.'**
  String get proRestoreFootnote;

  /// No description provided for @proRestoreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục Meloop Pro'**
  String get proRestoreTitle;

  /// No description provided for @proRestoreMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bản UI chưa kết nối Google Play nên không thể kiểm tra giao dịch. Chế độ xem thử Pro chỉ lưu trên thiết bị này.'**
  String get proRestoreMessage;

  /// No description provided for @proClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get proClose;

  /// No description provided for @previewResetAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu và bắt đầu lại'**
  String get previewResetAction;

  /// No description provided for @previewResetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu lại từ màn chào?'**
  String get previewResetTitle;

  /// No description provided for @previewResetMessage.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ hồ sơ, lựa chọn nhạc cụ, dữ liệu thử và quyền xem thử Pro trên thiết bị sẽ được xóa. Ứng dụng trở về màn chào và gói Free để bạn bắt đầu lại.'**
  String get previewResetMessage;

  /// No description provided for @previewResetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa và bắt đầu lại'**
  String get previewResetConfirm;

  /// No description provided for @previewResetCancel.
  ///
  /// In vi, this message translates to:
  /// **'Giữ dữ liệu'**
  String get previewResetCancel;

  /// No description provided for @previewResetFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể xóa dữ liệu. Hồ sơ của bạn vẫn được giữ. Hãy thử lại.'**
  String get previewResetFailed;

  /// No description provided for @profilesLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở hồ sơ…'**
  String get profilesLoading;

  /// No description provided for @journalReviewState.
  ///
  /// In vi, this message translates to:
  /// **'Đang rà soát'**
  String get journalReviewState;

  /// No description provided for @profilesLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở hồ sơ trên thiết bị.'**
  String get profilesLoadFailed;

  /// No description provided for @journalRecoveryPending.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện vẫn được giữ trên thiết bị. Bạn có thể xem hoặc thêm hồ sơ; chưa thể tiếp tục hay lưu buổi này ở phiên bản hiện tại.'**
  String get journalRecoveryPending;

  /// No description provided for @continueInstrumentPractice.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục · {instrument}'**
  String continueInstrumentPractice(String instrument);

  /// No description provided for @practiceStartFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể bắt đầu buổi luyện. Tiêu đề vẫn được giữ; hãy thử lại.'**
  String get practiceStartFailed;

  /// No description provided for @timerCheckpointFailed.
  ///
  /// In vi, this message translates to:
  /// **'Buổi luyện đã tạm dừng do lỗi. Thời gian mới chưa được xác nhận lưu; hãy thử lại.'**
  String get timerCheckpointFailed;

  /// No description provided for @practiceActionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể cập nhật buổi luyện. Vui lòng thử lại.'**
  String get practiceActionFailed;

  /// No description provided for @practiceToolsHeading.
  ///
  /// In vi, this message translates to:
  /// **'Những người bạn\ncủa buổi luyện.'**
  String get practiceToolsHeading;

  /// No description provided for @practiceToolsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm đúng nhịp. Lắng nghe kỹ hơn.'**
  String get practiceToolsSubtitle;

  /// No description provided for @metronomeTool.
  ///
  /// In vi, this message translates to:
  /// **'Máy đếm nhịp'**
  String get metronomeTool;

  /// No description provided for @pitchTool.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra cao độ'**
  String get pitchTool;

  /// No description provided for @practiceToolUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ này chưa khả dụng. Bạn vẫn có thể tiếp tục buổi luyện.'**
  String get practiceToolUnavailable;

  /// No description provided for @renamePractice.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên buổi luyện'**
  String get renamePractice;

  /// No description provided for @metronomeToolHint.
  ///
  /// In vi, this message translates to:
  /// **'Giữ nhịp, theo cách của bạn.'**
  String get metronomeToolHint;

  /// No description provided for @pitchToolHint.
  ///
  /// In vi, this message translates to:
  /// **'Lắng nghe từng nốt.'**
  String get pitchToolHint;

  /// No description provided for @recordTool.
  ///
  /// In vi, this message translates to:
  /// **'Ghi âm'**
  String get recordTool;

  /// No description provided for @recordToolHint.
  ///
  /// In vi, this message translates to:
  /// **'Giữ lại một khoảnh khắc.'**
  String get recordToolHint;

  /// No description provided for @recordingsTool.
  ///
  /// In vi, this message translates to:
  /// **'Bản ghi âm'**
  String get recordingsTool;

  /// No description provided for @recordingsToolHint.
  ///
  /// In vi, this message translates to:
  /// **'Nghe lại hành trình.'**
  String get recordingsToolHint;

  /// No description provided for @practiceToolsFree.
  ///
  /// In vi, this message translates to:
  /// **'Các công cụ luôn miễn phí.'**
  String get practiceToolsFree;

  /// No description provided for @practiceToolsTimingHint.
  ///
  /// In vi, this message translates to:
  /// **'Một công cụ âm thanh hoạt động mỗi lúc; bộ đếm giờ vẫn tiếp tục.'**
  String get practiceToolsTimingHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
