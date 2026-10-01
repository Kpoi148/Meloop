import 'dart:convert';

import '../application/instrument_profile_service.dart';
import 'profile_preview_storage.dart';

/// Temporary profile service for the interactive FE preview.
/// The production app must provide the local backend service instead.
class ProfilePreviewService implements InstrumentProfileService {
  ProfilePreviewService({this.storage});

  final ProfilePreviewStorage? storage;
  final List<InstrumentProfile> _profiles = [];
  final Map<String, String> _createdRequests = {};
  String? _selectedId;
  bool isPro = false;
  int _nextId = 1;
  bool _loaded = false;
  Future<void> _operation = Future<void>.value();

  Future<T> _run<T>(Future<T> Function() action, {bool initialize = true}) {
    final result = _operation.then((_) async {
      if (initialize && !_loaded) {
        try {
          final snapshot = await storage?.read();
          if (snapshot != null) _restore(snapshot);
          _loaded = true;
        } catch (_) {
          throw const ProfileServiceException(ProfileServiceError.storage);
        }
      }
      return action();
    });
    // Keep later operations usable after a failed load or write.
    _operation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  String _snapshot() => jsonEncode({
    'version': 1,
    'selectedId': _selectedId,
    'isPro': isPro,
    'nextId': _nextId,
    'createdRequests': _createdRequests,
    'profiles': [
      for (final profile in _profiles)
        {
          'id': profile.id,
          'name': profile.name,
          'instrumentType': profile.instrumentType.name,
          'customType': profile.customType,
          'savedSessionCount': profile.savedSessionCount,
          'recordingCount': profile.recordingCount,
        },
    ],
  });

  void _restore(String snapshot) {
    final state = jsonDecode(snapshot) as Map<String, dynamic>;
    if (state['version'] != 1) {
      throw const FormatException('Unsupported UI data');
    }
    final profiles = [
      for (final value in state['profiles'] as List<dynamic>)
        InstrumentProfile(
          id: value['id'] as String,
          name: value['name'] as String,
          instrumentType: InstrumentType.values.byName(
            value['instrumentType'] as String,
          ),
          customType: value['customType'] as String,
          savedSessionCount: value['savedSessionCount'] as int,
          recordingCount: value['recordingCount'] as int,
        ),
    ];
    final requests = Map<String, String>.from(state['createdRequests'] as Map);
    final selectedId = state['selectedId'] as String?;
    final nextId = state['nextId'] as int;
    final pro = state['isPro'] as bool;
    if (nextId < 1 ||
        profiles.map((p) => p.id).toSet().length != profiles.length) {
      throw const FormatException('Invalid UI data');
    }
    _profiles
      ..clear()
      ..addAll(profiles);
    _createdRequests
      ..clear()
      ..addAll(requests);
    _selectedId = profiles.any((profile) => profile.id == selectedId)
        ? selectedId
        : null;
    _nextId = nextId;
    isPro = pro;
  }

  Future<ProfileDirectory> _commit(void Function() change) async {
    final previous = _snapshot();
    try {
      change();
      await storage?.write(_snapshot());
      return _directory;
    } catch (error) {
      _restore(previous);
      if (error is ProfileServiceException) rethrow;
      throw const ProfileServiceException(ProfileServiceError.storage);
    }
  }

  Future<ProfileDirectory> reset() => _run(() async {
    final directory = await _commit(() {
      _profiles.clear();
      _createdRequests.clear();
      _selectedId = null;
      _nextId = 1;
      isPro = false;
    });
    _loaded = true;
    return directory;
  }, initialize: false);

  /// Enables the Tempo UI simulation; this is not a store purchase.
  Future<ProfileDirectory> enableProPreview() => _run(() async {
    if (isPro) return _directory;
    return _commit(() => isPro = true);
  });

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
  Future<ProfileDirectory> load() => _run(() async => _directory);

  @override
  Future<ProfileDirectory> create({
    required String requestId,
    required String name,
    required InstrumentType instrumentType,
    required String customType,
  }) => _run(
    () => _commit(() {
      final previousId = _createdRequests[requestId];
      if (previousId != null) {
        _find(previousId);
        _selectedId = previousId;
        return;
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
    }),
  );

  @override
  Future<ProfileDirectory> rename({
    required String profileId,
    required String name,
  }) => _run(
    () => _commit(() {
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
    }),
  );

  @override
  Future<ProfileDirectory> select(String profileId) => _run(
    () => _commit(() {
      _find(profileId);
      _selectedId = profileId;
    }),
  );

  @override
  Future<ProfileDeletionImpact> deletionImpact(String profileId) =>
      _run(() async {
        final profile = _find(profileId);
        return ProfileDeletionImpact(
          savedSessionCount: profile.savedSessionCount,
          recordingCount: profile.recordingCount,
        );
      });

  @override
  Future<ProfileDirectory> delete(String profileId) => _run(
    () => _commit(() {
      _find(profileId);
      _profiles.removeWhere((profile) => profile.id == profileId);
      _createdRequests.removeWhere((_, id) => id == profileId);
      if (_selectedId == profileId) {
        _selectedId = _profiles.isEmpty ? null : _profiles.first.id;
      }
    }),
  );
}
