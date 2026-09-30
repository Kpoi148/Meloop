import '../application/instrument_profile_service.dart';

/// Temporary, memory-only data for the interactive FE preview.
/// The production app must provide the local backend service instead.
class ProfilePreviewService implements InstrumentProfileService {
  final List<InstrumentProfile> _profiles = [];
  final Map<String, String> _createdRequests = {};
  String? _selectedId;
  bool isPro = false;
  int _nextId = 1;

  ProfileDirectory get _directory => ProfileDirectory(
    profiles: List.unmodifiable(_profiles),
    selectedProfileId: _selectedId,
    isPro: isPro,
  );

  InstrumentProfile _find(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) return profile;
    }
    throw const ProfileServiceException(ProfileServiceError.missingProfile);
  }

  String _key(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void _validateName(String name, {String? exceptId}) {
    if (name.trim().isEmpty || name.trim().runes.length > 50) {
      throw const ProfileServiceException(ProfileServiceError.invalidInput);
    }
    if (_profiles.any(
      (profile) => profile.id != exceptId && _key(profile.name) == _key(name),
    )) {
      throw const ProfileServiceException(ProfileServiceError.duplicateName);
    }
  }

  @override
  Future<ProfileDirectory> load() async => _directory;

  @override
  Future<ProfileDirectory> create({
    required String requestId,
    required String name,
    required InstrumentType instrumentType,
    required String customType,
  }) async {
    final previousId = _createdRequests[requestId];
    if (previousId != null) {
      _selectedId = previousId;
      return _directory;
    }
    if (!isPro && _profiles.length >= 3) {
      throw const ProfileServiceException(ProfileServiceError.freeLimit);
    }
    _validateName(name);
    if (instrumentType == InstrumentType.other &&
        (customType.trim().isEmpty || customType.trim().runes.length > 40)) {
      throw const ProfileServiceException(ProfileServiceError.invalidInput);
    }
    final profile = InstrumentProfile(
      id: 'preview-${_nextId++}',
      name: name.trim(),
      instrumentType: instrumentType,
      customType: instrumentType == InstrumentType.other
          ? customType.trim()
          : '',
    );
    _profiles.add(profile);
    _createdRequests[requestId] = profile.id;
    _selectedId = profile.id;
    return _directory;
  }

  @override
  Future<ProfileDirectory> rename({
    required String profileId,
    required String name,
  }) async {
    final original = _find(profileId);
    _validateName(name, exceptId: profileId);
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    _profiles[index] = InstrumentProfile(
      id: original.id,
      name: name.trim(),
      instrumentType: original.instrumentType,
      customType: original.customType,
      savedSessionCount: original.savedSessionCount,
      recordingCount: original.recordingCount,
    );
    return _directory;
  }

  @override
  Future<ProfileDirectory> select(String profileId) async {
    _find(profileId);
    _selectedId = profileId;
    return _directory;
  }

  @override
  Future<ProfileDeletionImpact> deletionImpact(String profileId) async {
    final profile = _find(profileId);
    return ProfileDeletionImpact(
      savedSessionCount: profile.savedSessionCount,
      recordingCount: profile.recordingCount,
    );
  }

  @override
  Future<ProfileDirectory> delete(String profileId) async {
    _find(profileId);
    _profiles.removeWhere((profile) => profile.id == profileId);
    if (_selectedId == profileId) {
      _selectedId = _profiles.isEmpty ? null : _profiles.first.id;
    }
    return _directory;
  }
}
