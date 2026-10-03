import 'package:unorm_dart/unorm_dart.dart' as unicode;

import 'journal_failure.dart';
import 'unicode_case_folding.g.dart';

class ProfileRules {
  ProfileRules._();
  static const nameMaxCodePoints = 50;
  static const customTypeMaxCodePoints = 40;
  static const freeProfileLimit = 3;
}

class PracticeRules {
  PracticeRules._();
  static const titleMaxCodePoints = 100;
  static const maximumDuration = Duration(hours: 24);
  static const minimumDurationSeconds = 1;
  static const qualifyingDayDuration = Duration(minutes: 1);
  static const checkpointInterval = Duration(seconds: 5);
  static const timerRefreshInterval = Duration(seconds: 1);
  static const noteMaxCodePoints = 2000;
  static const minimumRating = 1;
  static const maximumRating = 5;
  static const minimumBpm = 20;
  static const maximumBpm = 400;
}

class JournalText {
  JournalText._();
  static final _whitespace = RegExp(r'\s+', unicode: true);
  static final _controls = RegExp(r'[\p{Cc}\p{Cs}\p{Zl}\p{Zp}]', unicode: true);
  static final _invisibleOnly = RegExp(r'^[\p{Cf}\p{Z}\s]*$', unicode: true);
  static final _marks = RegExp(r'\p{M}', unicode: true);

  static String profileName(
    String input, {
    int maxCodePoints = ProfileRules.nameMaxCodePoints,
  }) {
    // Reject controls before trimming so a trailing newline cannot disappear.
    if (_controls.hasMatch(input)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final name = unicode.nfc(input.trim());
    if (name.isEmpty ||
        _invisibleOnly.hasMatch(name) ||
        name.runes.length > maxCodePoints) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    return name;
  }

  static String sessionTitle(String input) =>
      profileName(input, maxCodePoints: PracticeRules.titleMaxCodePoints);

  static final _noteControls = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  static String note(String input) {
    if (input.runes.length > PracticeRules.noteMaxCodePoints ||
        _noteControls.hasMatch(input)) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    return input.trim().isEmpty ? '' : input;
  }

  static String _fold(String input) => String.fromCharCodes(
    input.runes.expand(
      (rune) => (unicodeCaseFolding[rune] ?? String.fromCharCode(rune)).runes,
    ),
  );

  /// Preserve accents; only canonical form, case and repeated whitespace fold.
  static String profileKey(String normalizedName) => unicode.nfc(
    _fold(unicode.nfc(normalizedName.trim())).replaceAll(_whitespace, ' '),
  );

  /// Derived per-field key; never replaces original journal text.
  static String searchKey(String input) => unicode.nfc(
    unicode
        .nfd(_fold(unicode.nfc(input)))
        .replaceAll(_marks, '')
        .replaceAll('đ', 'd'),
  );

  static String literalLikePattern(String query) =>
      '%${searchKey(query).replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
}
