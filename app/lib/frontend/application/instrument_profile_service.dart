import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/profiles/instrument_profile_service.dart';
export '../../shared/profiles/instrument_profile_service.dart';

final instrumentProfileServiceProvider = Provider<InstrumentProfileService>(
  (ref) =>
      throw StateError('Instrument profile service has not been configured.'),
);

extension InstrumentTypeLabel on InstrumentType {
  String get label => switch (this) {
    InstrumentType.guitar => 'Guitar',
    InstrumentType.piano => 'Piano',
    InstrumentType.ukulele => 'Ukulele',
    InstrumentType.violin => 'Violin',
    InstrumentType.flute => 'Sáo',
    InstrumentType.drums => 'Bộ gõ',
    InstrumentType.other => 'Khác',
  };
}

extension InstrumentProfileLabel on InstrumentProfile {
  String get instrumentLabel => instrumentType == InstrumentType.other
      ? customType
      : instrumentType.label;
}
