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
      'This session\'s journal entry and recordings will be deleted.';

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
}
