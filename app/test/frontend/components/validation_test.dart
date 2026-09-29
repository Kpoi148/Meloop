import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/components/inputs/meloop_validation.dart';

void main() {
  test('Vietnamese names and Unicode code point limits follow the SRS', () {
    expect(MeloopValidation.title('  Luyện gam Đô  '), isNull);
    expect(MeloopValidation.title('   '), isNotNull);
    expect(MeloopValidation.title('A\nB'), isNotNull);
    expect(MeloopValidation.profileName('🎵' * 50), isNull);
    expect(MeloopValidation.profileName('🎵' * 51), isNotNull);
    expect(MeloopValidation.title('a' * 101), isNotNull);
    expect(MeloopValidation.customInstrument('a' * 41), isNotNull);
    expect(MeloopValidation.note(''), isNull);
    expect(MeloopValidation.note('Dòng một\nDòng hai'), isNull);
    expect(MeloopValidation.note('a' * 2001), isNotNull);
    expect(MeloopValidation.note('\x00'), isNotNull);
  });
  test('numeric fields reject fractions, signs and out-of-range input without rounding', () {
    String? validate(String v) =>
        MeloopValidation.integer(v, label: 'BPM', min: 40, max: 240);
    for (final v in ['40', '80', '240']) {
      expect(validate(v), isNull);
    }
    for (final v in ['', '0', '39', '241', '80.5', '-40', '1e2', 'abc']) {
      expect(validate(v), isNotNull, reason: v);
    }
  });
}
