import '../theme/tokens/tempo_tokens.dart';

/// Proportions from Tempo's privacy/support compositions.
abstract final class ContactTokens {
  static const privacyArtSize = 300.0;
  static const privacyArtHeight = 270.0;
  static const supportArtSize = 143.0;
  static const supportIntroHeight = 174.0;
  static const supportHeadingFraction = .58;
  static const supportHeadingSize = 29.0;
  static const supportArtRight = -17.0;
  static const supportArtTop = 37.0;
  static const expansionPadding = 17.0;
  static final sectionTitle = TempoType.title.copyWith(fontSize: 17);
  static final sectionBody = TempoType.body.copyWith(
    fontSize: 14,
    height: 1.8,
    color: TempoColors.muted,
  );
}
