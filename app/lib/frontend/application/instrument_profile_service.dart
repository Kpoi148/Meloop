import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frontend port. The app layer adapts Khanh's local profile service to this
/// contract; widgets never open SQLite or infer a successful write.
final instrumentProfileServiceProvider = Provider<InstrumentProfileService>(
  (ref) =>
      throw StateError('Instrument profile service has not been configured.'),
);

enum InstrumentType { guitar, piano, ukulele, violin, flute, drums, other }

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

class InstrumentProfile {
  const InstrumentProfile({
    required this.id,
    required this.name,
    required this.instrumentType,
    this.customType = '',
    this.savedSessionCount = 0,
    this.recordingCount = 0,
  });

  final String id;
  final String name;
  final InstrumentType instrumentType;
  final String customType;
  final int savedSessionCount;
  final int recordingCount;

  String get instrumentLabel => instrumentType == InstrumentType.other
      ? customType
      : instrumentType.label;
}

class ProfileDirectory {
  const ProfileDirectory({
    required this.profiles,
    required this.selectedProfileId,
    required this.isPro,
  });

  final List<InstrumentProfile> profiles;
  final String? selectedProfileId;
  final bool isPro;

  InstrumentProfile? get selectedProfile {
    for (final profile in profiles) {
      if (profile.id == selectedProfileId) return profile;
    }
    return null;
  }

  InstrumentProfile? byId(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  bool get canCreate => isPro || profiles.length < 3;
}

class ProfileDeletionImpact {
  const ProfileDeletionImpact({
    required this.savedSessionCount,
    required this.recordingCount,
  });

  final int savedSessionCount;
  final int recordingCount;
}

enum ProfileServiceError {
  duplicateName,
  freeLimit,
  missingProfile,
  unfinishedSession,
  invalidInput,
  storage,
  unknown,
}

class ProfileServiceException implements Exception {
  const ProfileServiceException(this.code);
  final ProfileServiceError code;
}

/// Each mutation returns a fresh committed directory. The backend owns name
/// normalization, limits, transactions, IDs, session ownership and file cleanup.
abstract interface class InstrumentProfileService {
  Future<ProfileDirectory> load();

  Future<ProfileDirectory> create({
    required String requestId,
    required String name,
    required InstrumentType instrumentType,
    required String customType,
  });

  Future<ProfileDirectory> rename({
    required String profileId,
    required String name,
  });

  Future<ProfileDirectory> select(String profileId);

  Future<ProfileDeletionImpact> deletionImpact(String profileId);

  Future<ProfileDirectory> delete(String profileId);
}
