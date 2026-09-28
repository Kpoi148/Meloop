import 'package:flutter_test/flutter_test.dart';
import 'package:meloop/frontend/components/meloop_ui.dart';

void main() {
  test('theme matches final fidelity cascade and packaged typeface', () {
    final theme = MeloopTheme.light;
    expect(theme.scaffoldBackgroundColor.toARGB32(), 0xFFFDFBF4);
    expect(theme.colorScheme.primary.toARGB32(), 0xFF004651);
    expect(theme.colorScheme.secondary.toARGB32(), 0xFFFFCC43);
    expect(theme.textTheme.bodyLarge!.fontFamily, TempoType.fontFamily);
    expect(theme.textTheme.labelLarge!.fontSize, 20);
    expect(theme.inputDecorationTheme.filled, isTrue);
  });
}
