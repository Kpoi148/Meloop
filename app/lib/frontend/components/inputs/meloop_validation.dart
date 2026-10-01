import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/journal/journal_text.dart';
import '../../../shared/journal/journal_failure.dart';

/// Presentation validation only. The domain must validate before committing.
abstract final class MeloopValidation {
  static final _singleLineControls = RegExp(r'[\x00-\x1F\x7F]');
  static final _noteControls = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');
  static final AppLocalizations _vi = lookupAppLocalizations(
    const Locale('vi'),
  );

  static String? singleLine(
    String? value, {
    required String label,
    required int maxLength,
    AppLocalizations? strings,
  }) {
    final copy = strings ?? _vi;
    final text = (value ?? '').trim();
    if (text.isEmpty) return copy.requiredField(label.toLowerCase());
    if (_singleLineControls.hasMatch(value ?? '')) {
      return copy.invalidSingleLine(label);
    }
    if (text.runes.length > maxLength) {
      return copy.maxCharacters(label, maxLength);
    }
    return null;
  }

  static String? title(String? value) => titleFor(value, _vi);
  static String? titleFor(String? value, AppLocalizations strings) => _profile(
    value,
    strings.sessionTitle,
    PracticeRules.titleMaxCodePoints,
    strings,
  );
  static String? profileName(String? value) => profileNameFor(value, _vi);
  static String? profileNameFor(String? value, AppLocalizations strings) =>
      _profile(
        value,
        strings.profileName,
        ProfileRules.nameMaxCodePoints,
        strings,
      );
  static String? customInstrument(String? value) =>
      customInstrumentFor(value, _vi);
  static String? customInstrumentFor(String? value, AppLocalizations strings) =>
      _profile(
        value,
        strings.customInstrumentName,
        ProfileRules.customTypeMaxCodePoints,
        strings,
      );

  static String? _profile(
    String? value,
    String label,
    int limit,
    AppLocalizations strings,
  ) {
    try {
      JournalText.profileName(value ?? '', maxCodePoints: limit);
      return null;
    } on JournalFailure {
      final basic = singleLine(
        value,
        label: label,
        maxLength: limit,
        strings: strings,
      );
      return basic ?? strings.invalidSingleLine(label);
    }
  }

  static String? note(String? value) => noteFor(value, _vi);
  static String? noteFor(String? value, AppLocalizations strings) {
    if (_noteControls.hasMatch(value ?? '')) {
      return strings.invalidNoteControl;
    }
    if ((value ?? '').runes.length > 2000) return strings.noteMaxCharacters;
    return null;
  }

  static String? integer(
    String? value, {
    required String label,
    required int min,
    required int max,
    AppLocalizations? strings,
  }) {
    final copy = strings ?? _vi;
    final text = (value ?? '').trim();
    if (text.isEmpty) return copy.requiredField(label.toLowerCase());
    if (!RegExp(r'^\d+$').hasMatch(text)) return copy.integerRequired(label);
    final number = int.tryParse(text);
    if (number == null || number < min || number > max) {
      return copy.integerRange(label, min, max);
    }
    return null;
  }
}
