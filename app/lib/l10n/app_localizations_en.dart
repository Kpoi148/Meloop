// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Meloop';

  @override
  String get back => 'Back';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get processing => 'Processing…';

  @override
  String get saving => 'Saving…';

  @override
  String get retrying => 'Retrying…';

  @override
  String get requiredSuffix => ' *';

  @override
  String get optionalSuffix => ' (optional)';

  @override
  String get requiredSemantics => 'required';

  @override
  String get optionalSemantics => 'optional';

  @override
  String requiredField(String label) {
    return 'Please enter $label.';
  }

  @override
  String requiredChoice(String label) {
    return 'Please select $label.';
  }

  @override
  String invalidSingleLine(String label) {
    return '$label cannot contain line breaks or control characters.';
  }

  @override
  String maxCharacters(String label, int count) {
    return '$label can contain at most $count characters.';
  }

  @override
  String get invalidNoteControl =>
      'The note contains an invalid control character.';

  @override
  String get noteMaxCharacters => 'Notes can contain at most 2,000 characters.';

  @override
  String integerRequired(String label) {
    return '$label must be a whole number.';
  }

  @override
  String integerRange(String label, int min, int max) {
    return '$label must be between $min and $max.';
  }

  @override
  String get validDateRange => 'Choose a date from Jan 1, 2000 through today.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchHint => 'Search sessions and notes…';

  @override
  String ratingSemantics(String label, int value) {
    return '$label $value out of 5';
  }

  @override
  String get moodRatingHint =>
      '1 · Unhappy → 5 · Very happy. Tap again to clear.';

  @override
  String get focusRatingHint =>
      '1 · Hard to focus → 5 · Very focused. Tap again to clear.';

  @override
  String get genericFailure => 'Could not finish. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'Sessions';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSettings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageViCode => 'VI';

  @override
  String get languageEnCode => 'EN';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageSaved => 'Language changed.';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String get welcomeTitle => 'A little music.\nEvery day.';

  @override
  String get welcomeSubtitle =>
      'Practice, keep notes, and see\nyour own journey unfold.';

  @override
  String get welcomePrivacy =>
      'No account needed. Your journal stays on this device.';

  @override
  String get createFirstProfile => 'Create your first profile';

  @override
  String get continueWithInstrument => 'Continue with my instrument';

  @override
  String get instrumentPickerTitle => 'What are you playing\ntoday?';

  @override
  String get instrumentPickerSubtitle =>
      'Choose an instrument to continue your journey.';

  @override
  String get manageInstruments => 'Manage instruments';

  @override
  String get selected => 'Selected';

  @override
  String get addInstrument => 'Add instrument';

  @override
  String get freeProfileLimit => 'Free: up to 3 instrument profiles.';

  @override
  String get noPracticeSessions => 'No practice sessions yet';

  @override
  String get profileSessionsEmptyMessage =>
      'Practice sessions for this profile will appear here.';

  @override
  String get openWelcomePreview => 'Preview Tempo welcome';

  @override
  String savedSessions(int count) {
    return '$count saved sessions';
  }

  @override
  String get unfinishedSessionTitle => 'You still have a practice session.';

  @override
  String get unfinishedSessionMessage =>
      'Finish or discard the current session before changing instruments.';

  @override
  String get understood => 'Got it';

  @override
  String get profileFormTitle => 'Your instrument';

  @override
  String get profileQuestion => 'What do you play?';

  @override
  String get profileSubtitle => 'Choose the sound that feels like yours.';

  @override
  String get instrumentOtherDescription => 'An instrument with its own voice';

  @override
  String get customInstrumentName => 'Instrument name';

  @override
  String get customInstrumentHint => 'For example: Saxophone';

  @override
  String get profileName => 'Profile name';

  @override
  String get profileNameHint => 'For example: My guitar';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileFootnote => 'You can rename it later. No sign-in needed.';

  @override
  String get instrumentGuitar => 'Guitar';

  @override
  String get instrumentPiano => 'Piano';

  @override
  String get instrumentUkulele => 'Ukulele';

  @override
  String get instrumentViolin => 'Violin';

  @override
  String get instrumentFlute => 'Flute';

  @override
  String get instrumentDrums => 'Percussion';

  @override
  String get instrumentOther => 'Other';

  @override
  String get defaultProfileName => 'My guitar';

  @override
  String get samplePianoProfile => 'Evening piano';

  @override
  String get overview => 'Overview';

  @override
  String get practiceOverviewLoading => 'Loading practice data…';

  @override
  String get practiceOverviewLoadFailed =>
      'Unable to load practice data. Please try again.';

  @override
  String get weeklyGoalOff => 'Off';

  @override
  String qualifyingDaysThisWeek(int days) {
    return 'Practiced on $days days this week';
  }

  @override
  String get qualifyingPracticeDayHint =>
      'A day counts when at least one saved session lasts 1 minute or more. The week runs Monday to Sunday.';

  @override
  String practiceChartDay(String date, int minutes) {
    return '$date: $minutes practice minutes';
  }

  @override
  String get practiceRatingsHeading => 'Mood & focus';

  @override
  String get practiceRatingsPeriod =>
      'Last 7 days · Your own ratings after practice';

  @override
  String get practiceRatingsDisclaimer =>
      'These are your feelings, not skill scores.';

  @override
  String get practiceNoRatings => 'No ratings yet';

  @override
  String practiceRatingAverage(String average, int count) {
    return '$average/5 · $count ratings';
  }

  @override
  String get practiceViewHistory => 'View practice journal';

  @override
  String get practiceToolsStandaloneHint =>
      'Opening tools from Home does not create a practice session. Session tools become available when you start practicing.';

  @override
  String get changeInstrument => 'Change instrument';

  @override
  String get lastSevenDays => 'Last 7 days';

  @override
  String get details => 'Details ›';

  @override
  String get practiceMinutes => 'practice minutes';

  @override
  String get practiceSessions => 'sessions';

  @override
  String get consecutiveDays => 'day streak';

  @override
  String get weeklyGoal => 'Weekly goal';

  @override
  String goalProgress(int current, int target) {
    return '$current/$target days';
  }

  @override
  String get mondayToSunday => 'Monday – Sunday';

  @override
  String get createPractice => 'Create practice session';

  @override
  String get continuePractice => 'Continue practice session';

  @override
  String get practiceTools => 'Practice tools';

  @override
  String get recentSession => 'Latest session';

  @override
  String get viewAll => 'View all ›';

  @override
  String get sampleSessionTitle => 'C major scale';

  @override
  String get sampleSessionMeta => 'Today · 35 minutes · 80 BPM';

  @override
  String get sampleSessionNotes =>
      'C major scale and C – G – Am – F chord changes.';

  @override
  String get nextPracticeUpper => 'FOR NEXT TIME';

  @override
  String get sampleNextNotes => 'Keep 80 BPM and relax the fretting hand.';

  @override
  String get setupTitle => 'Create practice session';

  @override
  String get newPracticeUpper => 'NEW PRACTICE SESSION';

  @override
  String get setupQuestion => 'What would you like\nto practice today?';

  @override
  String get sessionTitle => 'Session name';

  @override
  String get sessionTitleHint => 'For example: C major scale';

  @override
  String get sessionTitleHelper =>
      'Name it so it is easy to find. You can change it later.';

  @override
  String get timerStartsHint =>
      'The timer starts when you tap Start practicing.';

  @override
  String get startPractice => 'Start practicing';

  @override
  String get timerTitle => 'Practice session';

  @override
  String get timerOptions => 'Practice session options';

  @override
  String get timerOptionalTitle => 'Session name · optional';

  @override
  String get setPracticeName => 'Name this session';

  @override
  String get timerPaused => 'Paused';

  @override
  String get timerRunning => 'Practicing';

  @override
  String get practiceTime => 'Practice time';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get finish => 'Finish';

  @override
  String get recoveredDraftTitle => 'Practice session restored';

  @override
  String get recoveredDraftMessage =>
      'Your saved time is intact. The session was paused when the app reopened.';

  @override
  String get historySubtitle => 'The notes that shape your journey.';

  @override
  String get practiceTodayLabel => 'Today';

  @override
  String get practiceYesterdayLabel => 'Yesterday';

  @override
  String practiceRatingShort(int value) {
    return '$value/5';
  }

  @override
  String practiceDurationWithBpm(String duration, int bpm) {
    return '$duration · $bpm BPM';
  }

  @override
  String get practiceSort => 'Sort by';

  @override
  String get practiceFilters => 'Filters';

  @override
  String get practiceApplyFilters => 'Apply';

  @override
  String get practiceClearFilters => 'Clear filters';

  @override
  String get practiceNewest => 'Newest first';

  @override
  String get practiceOldest => 'Oldest first';

  @override
  String get practiceClearSearchAndFilters => 'Clear search and filters';

  @override
  String get practiceNoResultsMessage =>
      'Try another keyword or change your filters to find your practice sessions.';

  @override
  String get practiceEmptyMessage =>
      'Start your first practice session and keep the things you want to remember.';

  @override
  String get practiceSessionDetails => 'Practice session details';

  @override
  String get practiceFocusLabel => 'Focus';

  @override
  String get practiceEmptyRating => '—';

  @override
  String get sessionOptionalSuffix => ' (optional)';

  @override
  String get sessionMoodHint =>
      '1 · Unhappy → 5 · Very happy · Tap again to clear.';

  @override
  String get sessionFocusHint =>
      '1 · Distracted → 5 · Very focused · Tap again to clear.';

  @override
  String get nextPracticeHint => 'A note for your next session…';

  @override
  String get practiceSampleGuitarDifficulty =>
      'Make the transition from G to Am smoother.';

  @override
  String get practiceRatingSuffix => ' / 5';

  @override
  String get practiceNextEmpty => 'See you at your next practice session.';

  @override
  String get editSessionJournal => 'Edit journal';

  @override
  String get editSessionTitle => 'Edit practice session';

  @override
  String get editSessionHeading => 'Look back on your practice.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get sessionDurationMinutes => 'Duration (minutes)';

  @override
  String get sessionDuration => 'Duration';

  @override
  String get instrumentLabel => 'Instrument';

  @override
  String get leaveReviewTitle => 'Return to practice?';

  @override
  String get leaveReviewMessage =>
      'Your input will be kept so you can continue editing when you reopen this form.';

  @override
  String get returnToPractice => 'Return to practice';

  @override
  String get reviewDraftFailed =>
      'Could not preserve the latest draft. Your input is still in this form; retry before leaving.';

  @override
  String get sessionPracticeBpm => 'Practice tempo (BPM)';

  @override
  String get notRequired => 'Optional';

  @override
  String get deleteSessionTitle => 'Delete practice session?';

  @override
  String get sessionDeleted => 'Practice session deleted.';

  @override
  String get deleteSessionFailed =>
      'Could not delete. Your session and recordings are still here. Please try again.';

  @override
  String get deleteRecordingTitle => 'Delete recording?';

  @override
  String get deleteRecording => 'Delete recording';

  @override
  String get deleteRecordingMessage =>
      'Only this recording will be deleted. Your practice journal will be kept.';

  @override
  String get listenRecording => 'Listen again';

  @override
  String get exportRecording => 'Export recording';

  @override
  String get recordingLinked => 'Linked to journal';

  @override
  String get recordingUnlinked => 'Not linked to journal';

  @override
  String get recordingMissingFile => 'File no longer on this device';

  @override
  String get recordingMissingMessage =>
      'The audio file could not be found. You can remove this recording from the list.';

  @override
  String recordingMetadata(String duration, String status) {
    return '$duration · $status';
  }

  @override
  String get recordingMelodyTitle => 'Melody idea';

  @override
  String get recordingDeleted => 'Recording deleted.';

  @override
  String get recordingDeleteAction => 'Delete';

  @override
  String get recordingShare => 'Share recording';

  @override
  String get recordingShareDescription =>
      'Choose an app to send the audio file.';

  @override
  String get recordingSaveFile => 'Save to files';

  @override
  String get recordingSaveFileDescription =>
      'Choose where to save on your device.';

  @override
  String get recordingExported => 'Recording exported.';

  @override
  String get recordingExportFailed =>
      'Could not export this recording. Please try again.';

  @override
  String get recordingActionFailed =>
      'Could not open the recording. Please try again.';

  @override
  String get noSessionRecordings => 'No recordings yet.';

  @override
  String get noSessionRecordingsMessage =>
      'This practice session has no saved recordings.';

  @override
  String practiceRecordingTake(String title, int take) {
    return '$title · Take $take';
  }

  @override
  String get practiceWhatWasPracticed => 'What you practiced';

  @override
  String get practiceSessionRecordings => 'Recordings from this session';

  @override
  String get practiceNotRated => 'Not rated yet';

  @override
  String get practiceNoNotes => 'No notes yet.';

  @override
  String practiceToday(String date) {
    return 'Today · $date';
  }

  @override
  String practiceYesterday(String date) {
    return 'Yesterday · $date';
  }

  @override
  String practiceDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String practiceDurationSeconds(int seconds) {
    return '$seconds sec';
  }

  @override
  String practiceHoursMinutes(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String practiceBpm(int bpm) {
    return '$bpm BPM';
  }

  @override
  String practiceMoodScore(int value) {
    return 'Mood $value/5';
  }

  @override
  String practiceFocusScore(int value) {
    return 'Focus $value/5';
  }

  @override
  String practiceRecordingCount(int count) {
    return '$count recordings';
  }

  @override
  String practiceRatingValue(int value) {
    return '$value / 5';
  }

  @override
  String get practiceSampleRhythm => 'Basic rhythm';

  @override
  String get practiceSampleSong => 'Revisit a favorite song';

  @override
  String get practiceSampleMinorScale => 'A minor scales';

  @override
  String get practiceSampleTechnique => 'Hand technique';

  @override
  String get practiceSampleReview => 'Revisit difficult passages';

  @override
  String get practiceSampleSlowPractice => 'Slow and steady practice';

  @override
  String get practiceSampleScaleNotes =>
      'C major scales, playing each note clearly in both directions.';

  @override
  String get practiceSampleSteadyNotes =>
      'Practice each passage slowly, keeping a steady rhythm and clear notes.';

  @override
  String get practiceSampleDifficulty =>
      'Make the transition smoother and keep the rhythm as the tempo increases.';

  @override
  String get unfinishedPractice => 'Unfinished practice session';

  @override
  String get finishPractice => 'Finish';

  @override
  String get timeRange => 'Time range';

  @override
  String get all => 'All';

  @override
  String get sevenDays => '7 days';

  @override
  String get thirtyDays => '30 days';

  @override
  String get noMatchingSessions => 'No matching practice sessions.';

  @override
  String get clearSearchAction => 'Clear search';

  @override
  String get sampleSessionDate => 'Sep 23, 2026 · 30 minutes';

  @override
  String showcaseSaveCount(int count) {
    return 'UI preview · $count sample saves completed. Nothing was written to the device.';
  }

  @override
  String get progressHeading => 'A little progress,\nevery day.';

  @override
  String get noProgressTitle => 'No progress data yet.';

  @override
  String get noProgressMessage =>
      'Finish a practice session to look back on your journey.';

  @override
  String get settingsHeading => 'Make it yours.';

  @override
  String get settingsFreePlan => 'FREE';

  @override
  String get settingsEyebrow => 'MELOOP · YOUR SPACE';

  @override
  String get settingsManageProfiles => 'Manage instrument profiles';

  @override
  String get settingsProDescription =>
      'Add instrument profiles and unlock advanced progress filters.';

  @override
  String get settingsExplorePro => 'Explore Pro';

  @override
  String get settingsPersonalGroup => 'Make it yours';

  @override
  String get settingsReminderOff => 'Off';

  @override
  String get settingsDeviceData => 'Data on this device';

  @override
  String get settingsInformationGroup => 'Information & support';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsRestorePro => 'Restore Pro';

  @override
  String settingsVersion(String version) {
    return 'Meloop · $version';
  }

  @override
  String get settingsStudioCredit => 'Made with care by Moss Studio';

  @override
  String get instrumentProfilesTitle => 'Instrument profiles';

  @override
  String get instrumentProfilesHeading => 'Every instrument,\nits own journey.';

  @override
  String get instrumentProfilesSubtitle =>
      'The sounds that make you who you are.';

  @override
  String get profileInUse => 'In use';

  @override
  String get profileArchived => 'Archived';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get archiveProfile => 'Archive';

  @override
  String get reactivateProfile => 'Reactivate';

  @override
  String get freeProfilesNote =>
      'The free plan includes 3 profiles. Archiving preserves history and does not free a profile slot.';

  @override
  String settingsLanguageDescription(String language) {
    return '$language';
  }

  @override
  String get componentCatalog => 'UI component catalog';

  @override
  String get openSessionForm => 'Open the session form';

  @override
  String get simulateNextSaveFailure => 'Next save returns an error';

  @override
  String get saveSessionTitle => 'Save practice session';

  @override
  String get sessionFormHeading => 'One practice session,\none step forward.';

  @override
  String get sessionFormTitleHint => 'Practice session';

  @override
  String get sessionFormSubtitle => 'Keep what you want to remember.';

  @override
  String get practiceDate => 'Practice date';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String get durationRange => 'Duration must be between 1 second and 24 hours.';

  @override
  String get mood => 'Mood';

  @override
  String get focusLevel => 'Focus';

  @override
  String get practicedWhat => 'What did you practice?';

  @override
  String get practicedHint => 'Scales, chords, songs…';

  @override
  String get difficulty => 'What felt difficult';

  @override
  String get difficultyHint => 'A hard passage or something to improve…';

  @override
  String get nextPractice => 'For next time';

  @override
  String get savePractice => 'Save practice session';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage => 'Your unsaved changes will be discarded.';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get saveSessionFailed =>
      'Could not save the practice session. Your content is still here. Please try again.';

  @override
  String get savedSessionCompletionFailed =>
      'The practice session is saved. Could not finish the next step. Please try again.';

  @override
  String get catalogTitle => 'Shared components';

  @override
  String get catalogHeading => 'One design\nrhythm.';

  @override
  String get catalogSubtitle =>
      'Tempo UI preview · sample data lives in memory only.';

  @override
  String get catalogButtons => 'Buttons & saving states';

  @override
  String get catalogFields => 'Fields & inline errors';

  @override
  String get catalogChoices => 'Choices & tabs';

  @override
  String get catalogDialogs => 'Dialogs & notices';

  @override
  String get catalogStates => 'Loading / empty / error';

  @override
  String get save => 'Save';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get addProfile => 'Add profile';

  @override
  String get deleteSession => 'Delete session';

  @override
  String get endPractice => 'Finish';

  @override
  String get profileHelper =>
      '1–50 characters. Keep the content if saving fails.';

  @override
  String get tempoBpm => 'Tempo (BPM)';

  @override
  String get metronomeTitle => 'Metronome';

  @override
  String get metronomeBpmUnit => 'beats / minute';

  @override
  String get decreaseMetronomeBpm => 'Decrease tempo';

  @override
  String get increaseMetronomeBpm => 'Increase tempo';

  @override
  String get startMetronome => 'Start';

  @override
  String get stopMetronome => 'Stop metronome';

  @override
  String get metronomeFootnote =>
      'Accent the first beat to find your rhythm.\nAudio plays directly on your device.';

  @override
  String metronomeCurrentBeat(int current, int total) {
    return 'Beat $current / $total';
  }

  @override
  String metronomeBpmRangeError(int min, int max) {
    return 'Tempo must be between $min and $max BPM.';
  }

  @override
  String metronomeBeatsRangeError(int min, int max) {
    return 'Beats per bar must be between $min and $max.';
  }

  @override
  String get metronomeAudioBusy =>
      'Another audio tool is active. Stop it before starting the metronome.';

  @override
  String get bpm => 'BPM';

  @override
  String get validateData => 'Validate data';

  @override
  String get beatsPerBar => 'Beats per bar';

  @override
  String beats(int count) {
    return '$count beats';
  }

  @override
  String get reminder => 'Practice reminder';

  @override
  String get reminderDescription => 'A little music each day.';

  @override
  String get attachDiagnostics => 'Attach diagnostic information';

  @override
  String get attachDiagnosticsDescription =>
      'Only when you actively choose to.';

  @override
  String get openConfirmDialog => 'Open confirmation dialog';

  @override
  String get deleteSessionMessage =>
      'This session will be removed from your journal and statistics. Recordings will be kept separately.';

  @override
  String get openChoiceSheet => 'Open choice sheet';

  @override
  String get tempoComponents => 'Tempo components';

  @override
  String get sharedThemeNotice =>
      'Every screen uses the same theme, font, colors, and icons.';

  @override
  String get showNotification => 'Show notification';

  @override
  String get sampleActionComplete => 'Sample action completed.';

  @override
  String get journalOnDevice => 'Your journal stays on this device.';

  @override
  String get sessionSaved => 'Practice session saved.';

  @override
  String get saveFailedKeepsContent =>
      'Could not save. Your content is still here.';

  @override
  String get loadingSessions => 'Loading practice sessions…';

  @override
  String get journeyStartsToday => 'Your journey starts today.';

  @override
  String get saveFirstSession => 'Save your first practice session.';

  @override
  String get loadSessionsFailed => 'Could not load practice sessions.';

  @override
  String get dataKeptRetry => 'Please try again. Your data is still safe.';

  @override
  String get retry => 'Try again';

  @override
  String get proTitle => 'Meloop Pro';

  @override
  String get proOneTimeBadge => 'ONE-TIME PURCHASE · NO RENEWAL';

  @override
  String get proHeading => 'More room\nfor your passion.';

  @override
  String get proSubtitle => 'A companion, your way.';

  @override
  String get proIllustrativePrice => '49,000₫';

  @override
  String get proPriceCaption => 'Illustrative price · One-time purchase';

  @override
  String get proProfilesBenefit => 'More instrument profiles';

  @override
  String get proProfilesDescription =>
      'Keep a separate journal for every sound you love.';

  @override
  String get proFiltersBenefit => 'Advanced progress filters';

  @override
  String get proFiltersDescription => 'Explore longer or custom time ranges.';

  @override
  String get proFreeFeatures =>
      'Journaling, tools, recording, goals, reminders, backups and audio export remain free.';

  @override
  String get proPreviewTry => 'Try Meloop Pro';

  @override
  String get proPreviewActive => 'Previewing Meloop Pro';

  @override
  String get proPreviewPlan => 'PRO · PREVIEW';

  @override
  String get proPreviewFootnote =>
      'This UI simulates Pro access. No real transaction takes place.\nThe store provides the official price.';

  @override
  String get proPreviewConfirmTitle => 'Preview Meloop Pro';

  @override
  String get proPreviewConfirmMessage =>
      'This enables the Pro preview so you can explore the interface and add more profiles. No charge or store connection is involved.';

  @override
  String get proPreviewEnable => 'Enable preview';

  @override
  String get proPreviewEnabled => 'Pro preview enabled.';

  @override
  String get proPreviewFailed =>
      'Could not enable Pro. Your data is still safe. Please try again.';

  @override
  String get proPreviewActiveTitle => 'Meloop Pro preview is enabled.';

  @override
  String get proPreviewActiveMessage =>
      'You can add more profiles in preview mode. No payment has been made.';

  @override
  String get proRestoreTransaction => 'Restore purchase';

  @override
  String get proRestoreFootnote => 'Restore using the same account and store.';

  @override
  String get proRestoreTitle => 'Restore Meloop Pro';

  @override
  String get proRestoreMessage =>
      'This UI is not connected to Google Play and cannot verify purchases. Pro preview is saved only on this device.';

  @override
  String get proClose => 'Close';

  @override
  String get previewResetAction => 'Delete data and start again';

  @override
  String get previewResetTitle => 'Start again from the welcome screen?';

  @override
  String get previewResetMessage =>
      'All profiles, instrument selection, preview data and Pro preview access on this device will be deleted. The app will return to the welcome screen and Free plan.';

  @override
  String get previewResetConfirm => 'Delete and start again';

  @override
  String get previewResetCancel => 'Keep data';

  @override
  String get previewResetFailed =>
      'Could not delete data. Your profiles are still safe. Please try again.';

  @override
  String get profilesLoading => 'Opening profiles…';

  @override
  String get journalReviewState => 'In review';

  @override
  String get profilesLoadFailed => 'Could not open profiles on this device.';

  @override
  String get journalRecoveryPending =>
      'This practice is kept on your device. You can browse or add profiles; resuming or saving this practice is not available in this version yet.';

  @override
  String continueInstrumentPractice(String instrument) {
    return 'Continue · $instrument';
  }

  @override
  String get practiceStartFailed =>
      'Could not start practice. Your title is retained; please try again.';

  @override
  String get timerCheckpointFailed =>
      'Practice paused after an error. The latest time has not been confirmed saved; please retry.';

  @override
  String get practiceActionFailed =>
      'Could not update practice. Please try again.';

  @override
  String get practiceToolsHeading => 'Companions\nfor your practice.';

  @override
  String get practiceToolsSubtitle => 'Find your rhythm. Listen more closely.';

  @override
  String get metronomeTool => 'Metronome';

  @override
  String get pitchTool => 'Check pitch';

  @override
  String get practiceToolUnavailable => 'This tool is not available yet.';

  @override
  String get renamePractice => 'Rename practice session';

  @override
  String get metronomeToolHint => 'Keep time, your way.';

  @override
  String get pitchToolHint => 'Listen to every note.';

  @override
  String get recordTool => 'Record';

  @override
  String get recordToolHint => 'Keep a moment.';

  @override
  String get recordingsTool => 'Recordings';

  @override
  String get recordingsToolHint => 'Listen to your journey.';

  @override
  String get practiceToolsFree => 'Practice tools are always free.';

  @override
  String get practiceToolsTimingHint =>
      'One audio tool runs at a time; the practice timer continues.';

  @override
  String get recordingTitle => 'Practice recording';

  @override
  String get sessionRecordingsTitle => 'Session recordings';

  @override
  String get sessionRecordingsHeading => 'Listen to\nyour journey.';

  @override
  String get sessionRecordingsSubtitle => 'The sounds you want to keep.';

  @override
  String get sessionRecordingsEmptyMessage =>
      'Record a passage during practice to listen back later.';

  @override
  String get recordPracticeSession => 'Record a practice session';

  @override
  String get sessionRecordingsDeleteHint =>
      'Deleting a recording does not delete your practice journal.';

  @override
  String get recordingDefaultTitle => 'My practice session';

  @override
  String get recordingEmptyHeading => 'Keep the sound\nof today.';

  @override
  String get recordingEmptyTitle => 'Start a practice session first.';

  @override
  String get recordingEmptyDescription =>
      'The recording will go with the journal of your ongoing practice session.';

  @override
  String get recordingStart => 'Start recording';

  @override
  String get recordingStop => 'Stop recording';

  @override
  String get recordingPending => 'Recording not kept yet';

  @override
  String get recordingMute => 'Mute';

  @override
  String get recordingUnmute => 'Unmute';

  @override
  String get recordingPlaybackOptions => 'Recording options';

  @override
  String get recordingRestartPlayback => 'Listen from the beginning';

  @override
  String get recordingPendingHint =>
      'Listen back and keep or discard this recording before starting another.';

  @override
  String recordingActive(int minutes) {
    return 'Recording · Up to $minutes minutes';
  }

  @override
  String recordingReady(int minutes) {
    return 'Microphone ready · Up to $minutes minutes';
  }

  @override
  String recordingMicrophoneOff(int minutes) {
    return 'Microphone off · Up to $minutes minutes';
  }

  @override
  String get recordingFootnote =>
      'Recordings are stored on your device.\nRecording does not end the practice timer.';

  @override
  String recordingFreeQuota(int count, int limit) {
    return 'Free · $count/$limit recordings';
  }

  @override
  String recordingProQuota(int minutes) {
    return 'Pro · Up to $minutes minutes per recording';
  }

  @override
  String get recordingViewPro => 'View Meloop Pro';

  @override
  String get recordingProTitle => 'More room for your passion.';

  @override
  String get recordingProDescription =>
      'Meloop Pro expands recording duration and capacity for your practice sessions.';

  @override
  String get recordingProJournalHint =>
      'You can always keep practicing and save your journal with Free, even without microphone permission.';

  @override
  String get recordingContinuePractice => 'Keep practicing';

  @override
  String get recordingReviewTitle => 'Listen back for a moment.';

  @override
  String get recordingKeep => 'Keep recording';

  @override
  String get recordingDiscard => 'Discard recording';

  @override
  String get recordingDiscardTitle => 'Discard this recording?';

  @override
  String get recordingDiscardMessage =>
      'The recording you have not kept will be deleted.';

  @override
  String get recordingKept => 'Recording kept on your device.';

  @override
  String get recordingPausePlayback => 'Pause playback';

  @override
  String get recordingMicrophoneDenied =>
      'Microphone permission has not been granted. Enable it in your device settings and try again. You can still save your practice journal.';

  @override
  String get recordingMicrophoneUnavailable =>
      'No microphone found. Check your microphone and try again. You can still practice and save your journal.';

  @override
  String get recordingStorageFull =>
      'Not enough storage to record. Free up space and try again. You can still save your practice journal.';

  @override
  String get recordingAudioBusy =>
      'Another audio tool is running. Stop it before recording again.';

  @override
  String get recordingStartFailed =>
      'Could not start recording. Try again when the microphone is ready. Your practice state is unchanged.';

  @override
  String get recordingSaveFailed =>
      'Could not keep this recording. It is still here to listen to or try keeping again.';

  @override
  String get recordingInterrupted =>
      'Recording stopped after an interruption. Listen back and keep or discard it before recording again.';

  @override
  String recordingDurationLimit(int minutes) {
    return 'Reached the $minutes-minute limit. Recording has stopped so you can listen back and keep it. You can still save your practice journal.';
  }

  @override
  String recordingFileLimit(int limit) {
    return 'You have reached $limit Free recordings. Remove a recording or view Meloop Pro to record more. You can still save your practice journal.';
  }

  @override
  String get recordingPracticePaused =>
      'Practice is paused. Resume your practice session before recording.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyHeading => 'Your music.\nYour journal.';

  @override
  String get privacySubtitle => 'You control what you record.';

  @override
  String get privacyLocalTitle => 'Journal and audio';

  @override
  String get privacyLocalBody =>
      'Your practice journal is stored locally on your Android device. The support flow does not read or automatically attach journal entries, databases or recordings to email.';

  @override
  String get privacyPermissionsTitle => 'Microphone and reminders';

  @override
  String get privacyPermissionsBody =>
      'The privacy and support screens do not request microphone or notification access. You can review and change Meloop permissions in Android app settings.';

  @override
  String get privacyPurchasesTitle => 'Purchases and Meloop Pro';

  @override
  String get privacyPurchasesBody =>
      'The Pro screen currently offers a preview, with no charges or Google Play connection. Purchase information for the release must be disclosed in the official policy.';

  @override
  String get privacyDiagnosticsTitle => 'Diagnostics and errors';

  @override
  String get privacyDiagnosticsBody =>
      'Technical details in support email are off by default. Only if you choose, the draft includes the app version, Android version and device model for your review. Journal content, audio and purchase information are excluded.';

  @override
  String get privacyChoicesTitle => 'You have a choice';

  @override
  String get privacyChoicesBody =>
      'You can edit your message, leave out technical details or cancel your support draft. To share a recording, select and attach it yourself in your email app. Meloop never sends messages or data automatically.';

  @override
  String get privacySummaryFootnote =>
      'This information describes the current app version. The official policy must be confirmed before release.';

  @override
  String get privacyNotPublished =>
      'The official privacy policy has not been published yet. The information above remains readable offline.';

  @override
  String get privacyOpenPublished => 'Open the official policy';

  @override
  String get privacyOpenFailed =>
      'Could not open the link. Try again or copy the link to open it in a browser.';

  @override
  String get privacyCopyLink => 'Copy link';

  @override
  String get supportHeading => 'We’re listening.';

  @override
  String get supportSubtitle =>
      'A small suggestion can help Meloop get better.';

  @override
  String get supportNotPublished =>
      'The support address has not been published yet. You can compose, preview and copy your message to send later.';

  @override
  String get supportAddress => 'Support address';

  @override
  String get supportSubject => 'Subject';

  @override
  String get supportSubjectHint => 'What would you like to share?';

  @override
  String get supportDescription => 'Message';

  @override
  String get supportDescriptionHint =>
      'Describe the issue or share your feedback…';

  @override
  String supportDescriptionLimit(int limit) {
    return 'Up to $limit characters; you can leave this blank.';
  }

  @override
  String supportSubjectInvalid(int limit) {
    return 'Enter a subject of 1–$limit characters without line breaks or control characters.';
  }

  @override
  String supportDescriptionInvalid(int limit) {
    return 'Use up to $limit characters without invalid control characters.';
  }

  @override
  String get supportIncludeDiagnostics => 'Include technical details';

  @override
  String get supportDiagnosticsExplanation =>
      'App version, Android version and device model only. You will review them before opening email.';

  @override
  String supportDiagnosticsBlock(
    String appVersion,
    String androidVersion,
    String deviceModel,
  ) {
    return 'Technical details\nApp version: $appVersion\nAndroid version: $androidVersion\nDevice model: $deviceModel';
  }

  @override
  String get supportPrivacyNote =>
      'Journal entries and audio are never attached automatically. Meloop only opens a draft for you to edit and send in your email app.';

  @override
  String get supportPreview => 'Preview message';

  @override
  String get supportPreviewFailed =>
      'Could not get technical details. Your message is still here. Try again or deselect technical details.';

  @override
  String get supportDraftHeading => 'A message from you.';

  @override
  String get supportReviewNote =>
      'Review the content below. Go back to edit or keep editing in your email app before sending.';

  @override
  String get supportEmptyBody => 'No message entered.';

  @override
  String get supportCompose => 'Compose email';

  @override
  String get supportEmailUnavailable =>
      'Could not open an email app. Copy the address and message to contact support another way.';

  @override
  String get supportCopyAddress => 'Copy address';

  @override
  String get supportCopyDetails => 'Copy message';

  @override
  String get supportEditDraft => 'Edit message';

  @override
  String get supportCopied => 'Copied.';

  @override
  String get supportCopyFailed =>
      'Could not copy. Try again or select the text to copy it.';

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
  String get pitchNoSignal => 'No signal yet';

  @override
  String get pitchListening => 'Listening…';

  @override
  String get pitchRequestingPermission => 'Waiting for microphone permission…';

  @override
  String get pitchWeakSignal => 'Not enough signal';

  @override
  String get pitchWeakSignalHint =>
      'The signal is weak or unstable. Play one clear, steady note a little closer to the microphone.';

  @override
  String pitchMeasurement(String frequency, String cents) {
    return '$frequency Hz · $cents cents';
  }

  @override
  String pitchCentsNegative(int cents) {
    return '−$cents cents';
  }

  @override
  String pitchCentsPositive(int cents) {
    return '+$cents cents';
  }

  @override
  String get pitchGaugeCenter => 'In tune';

  @override
  String get pitchInstruction =>
      'Play one clear, steady note in a quiet space.';

  @override
  String get pitchLow => 'Slightly low · raise the pitch a little.';

  @override
  String get pitchInTune => 'In tune. Keep the note steady.';

  @override
  String get pitchHigh => 'Slightly high · lower the pitch a little.';

  @override
  String get pitchStart => 'Turn on microphone';

  @override
  String get pitchStop => 'Turn off microphone';

  @override
  String get pitchStopping => 'Turning off microphone…';

  @override
  String get pitchPermissionDenied =>
      'Microphone permission has not been granted. Try granting it again or open settings. You can keep practicing and save your journal.';

  @override
  String get pitchPermissionBlocked =>
      'Microphone permission is blocked. Allow it in app settings, then try again. You can still practice and save your journal.';

  @override
  String get pitchSettingsGuide =>
      'In Android Settings, go to Apps → Meloop → Permissions → Microphone and allow access while using the app. Return and turn on the microphone.';

  @override
  String get pitchOpenSettings => 'Open settings';

  @override
  String get pitchOpeningSettings => 'Opening settings…';

  @override
  String get pitchSettingsFailed =>
      'Could not open settings automatically. Follow the Android Settings steps above; you can still return to your practice.';

  @override
  String get pitchUnavailable =>
      'Pitch checking is unavailable on this device. You can still return to your practice and save your journal.';

  @override
  String get pitchAudioBusy =>
      'Another audio tool is active. Stop it and try again; your practice timer keeps running.';

  @override
  String get pitchFailed =>
      'Could not listen to the microphone. Try again. Your practice data is still here.';

  @override
  String get pitchStopFailed =>
      'Could not confirm that the microphone stopped. Turn it off again to retry; the reading has been cleared.';

  @override
  String get pitchPrivacy =>
      'The microphone is used only with your permission. Audio is analyzed on this device, without being saved or sent anywhere.';

  @override
  String get pitchLimitations =>
      'The tool detects single notes, not chords, and may not work with every instrument.';

  @override
  String get pitchPreviewTitle => 'Pitch UI preview';

  @override
  String get pitchPreviewExplanation =>
      'Review listening, detected notes, weak signals and denied permissions using simulated data. This preview does not use the microphone or access your journal.';

  @override
  String get pitchPreviewOpen => 'Open pitch screen';

  @override
  String get pitchPreviewBadge => 'UI preview · Simulated data · No microphone';

  @override
  String get pitchPreviewScenario => 'State to preview';

  @override
  String get pitchPreviewStartHint =>
      'Choose a state, then turn on the microphone to preview it. Turning it off clears the note and needle.';

  @override
  String get pitchPreviewListening => 'Listening, waiting for audio';

  @override
  String get pitchPreviewInTune => 'Note detected, in tune';

  @override
  String get pitchPreviewLow => 'Note detected, slightly low';

  @override
  String get pitchPreviewHigh => 'Note detected, slightly high';

  @override
  String get pitchPreviewWeakSignal => 'Not enough signal';

  @override
  String get pitchPreviewDenied => 'Microphone permission denied';

  @override
  String get pitchPreviewBlocked => 'Microphone permission blocked';
}
