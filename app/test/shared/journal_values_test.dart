import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/shared/journal/journal_failure.dart';
import 'package:meloop/shared/journal/journal_runtime.dart';
import 'package:meloop/shared/journal/journal_text.dart';
import 'package:meloop/shared/journal/practice_date.dart';

void main() {
  test('profile uniqueness preserves accents, folds NFC/case/whitespace', () {
    final display = JournalText.profileName('  ĐA\u0300N  của Tôi 🎸  ');
    expect(display, 'ĐÀN  của Tôi 🎸');
    expect(JournalText.profileKey(display), 'đàn của tôi 🎸');
    expect(
      JournalText.profileKey(display),
      JournalText.profileKey('đàn của tôi 🎸'),
    );
    expect(JournalText.profileKey('Đàn'), isNot(JournalText.profileKey('Dan')));
    expect(JournalText.profileKey('Straße'), JournalText.profileKey('STRASSE'));
    expect(JournalText.profileKey('Σςσ'), 'σσσ');
    expect(JournalText.profileKey('Kelvin'), 'kelvin');
  });

  test(
    'profile length counts normalized code points, controls never disappear',
    () {
      expect(
        JournalText.profileName(List.filled(50, '🎹').join()).runes.length,
        50,
      );
      for (final invalid in [
        '',
        '   ',
        'Name\n',
        '\tName',
        'Name\u0000',
        'Name\u2028',
        '\u200b',
        '\ud800',
        List.filled(51, '🎹').join(),
      ]) {
        expect(
          () => JournalText.profileName(invalid),
          throwsA(isA<JournalFailure>()),
        );
      }
      expect(JournalText.profileName('e\u0301'), 'é');
    },
  );

  test(
    'search removes Vietnamese marks and đ without changing profile keys',
    () {
      expect(
        JournalText.searchKey('ĐẮNG độ 🎸 Straße'),
        'dang do 🎸 strasse',
      );
      expect(JournalText.profileKey('ĐẮNG'), 'đắng');
      expect(JournalText.literalLikePattern(r'Đàn 100%_\'), r'%dan 100\%\_\\%');
    },
  );

  test(
    'calendar date rejects rollovers and uses supplied local calendar fields',
    () {
      expect(PracticeDate.parse('2024-02-29').value, '2024-02-29');
      expect(
        PracticeDate.fromLocal(DateTime(2026, 10, 1, 0, 1)).value,
        '2026-10-01',
      );
      expect(
        PracticeDate.parse('2026-10-01')
            .isAfter(PracticeDate.parse('2026-09-30')),
        true,
      );
      for (final invalid in [
        '2026-02-29',
        '2026-04-31',
        '2026-13-01',
        '2026-00-10',
        '2026-1-01',
        '1999-12-31',
        '2026-10-01T00:00:00Z',
      ]) {
        expect(
          () => PracticeDate.parse(invalid),
          throwsA(isA<JournalFailure>()),
        );
      }
    },
  );

  test('runtime produces lowercase UUID v4 identities and UTC timestamps', () {
    const ids = UuidJournalIdentifiers();
    final generated = List.generate(100, (_) => ids.newId());
    expect(generated.every(JournalId.isValid), true);
    expect(generated.toSet(), hasLength(100));
    expect(JournalId.isValid('preview-1'), false);
    expect(const DeviceJournalClock().utcNow().isUtc, true);
    expect(
      const JournalFailure(JournalFailureCode.storage).toString(),
      'JournalFailure(storage)',
    );
  });
}
