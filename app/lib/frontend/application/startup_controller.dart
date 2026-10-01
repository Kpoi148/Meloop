import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/layout/meloop_art.dart';
import 'practice_session_provider.dart';

class PreviewInstrumentProfile {
  const PreviewInstrumentProfile({
    required this.id,
    required this.instrument,
    this.name,
    this.savedSessionCount = 0,
    this.customInstrumentName,
  });

  final String id;
  final MeloopInstrument instrument;
  final String? name;
  final int savedSessionCount;
  final String? customInstrumentName;
}

class PreviewPracticeDraft {
  const PreviewPracticeDraft({
    required this.profileId,
    this.title = '',
    this.accumulatedSeconds = 0,
    this.isRunning = false,
    this.wasRecovered = false,
    this.sessionId,
    this.startedAt,
  });

  final String profileId;
  final String title;
  final int accumulatedSeconds;
  final bool isRunning;
  final bool wasRecovered;
  final String? sessionId;
  final DateTime? startedAt;

  PreviewPracticeDraft copyWith({
    String? title,
    int? accumulatedSeconds,
    bool? isRunning,
    bool? wasRecovered,
  }) => PreviewPracticeDraft(
    profileId: profileId,
    title: title ?? this.title,
    accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    isRunning: isRunning ?? this.isRunning,
    wasRecovered: wasRecovered ?? this.wasRecovered,
    sessionId: sessionId,
    startedAt: startedAt,
  );
}

class StartupSnapshot {
  const StartupSnapshot({
    this.profiles = const [],
    this.selectedProfileId,
    this.draft,
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final PreviewPracticeDraft? draft;

  static const empty = StartupSnapshot();
  static const oneProfile = StartupSnapshot(
    profiles: [
      PreviewInstrumentProfile(
        id: 'guitar-preview',
        instrument: MeloopInstrument.guitar,
        savedSessionCount: 5,
      ),
    ],
    selectedProfileId: 'guitar-preview',
  );
  static const manyProfiles = StartupSnapshot(
    profiles: [
      PreviewInstrumentProfile(
        id: 'guitar-preview',
        instrument: MeloopInstrument.guitar,
        savedSessionCount: 5,
      ),
      PreviewInstrumentProfile(
        id: 'piano-preview',
        instrument: MeloopInstrument.piano,
      ),
    ],
    selectedProfileId: 'guitar-preview',
  );
  static const recoveredDraft = StartupSnapshot(
    profiles: [
      PreviewInstrumentProfile(
        id: 'guitar-preview',
        instrument: MeloopInstrument.guitar,
        savedSessionCount: 5,
      ),
    ],
    selectedProfileId: 'guitar-preview',
    draft: PreviewPracticeDraft(
      profileId: 'guitar-preview',
      accumulatedSeconds: 754,
      isRunning: true,
    ),
  );
}

enum StartupDestination { welcome, profilePicker, main, recoveredTimer }

class MeloopShellState {
  const MeloopShellState({
    required this.profiles,
    required this.selectedProfileId,
    required this.draft,
    required this.destination,
    this.selectedTab = 0,
    this.requiresProfileSelection = false,
    this.sessions = const [],
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final PreviewPracticeDraft? draft;
  final StartupDestination destination;
  final int selectedTab;
  final bool requiresProfileSelection;
  final List<SavedPracticeSession> sessions;

  PreviewInstrumentProfile? get selectedProfile {
    for (final profile in profiles) {
      if (profile.id == selectedProfileId) return profile;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  MeloopShellState copyWith({
    List<PreviewInstrumentProfile>? profiles,
    String? selectedProfileId,
    bool clearSelectedProfile = false,
    PreviewPracticeDraft? draft,
    bool clearDraft = false,
    StartupDestination? destination,
    int? selectedTab,
    bool? requiresProfileSelection,
    List<SavedPracticeSession>? sessions,
  }) => MeloopShellState(
    profiles: profiles ?? this.profiles,
    selectedProfileId: clearSelectedProfile
        ? null
        : selectedProfileId ?? this.selectedProfileId,
    draft: clearDraft ? null : draft ?? this.draft,
    destination: destination ?? this.destination,
    selectedTab: selectedTab ?? this.selectedTab,
    requiresProfileSelection:
        requiresProfileSelection ?? this.requiresProfileSelection,
    sessions: sessions ?? this.sessions,
  );
}

final startupSnapshotProvider = Provider<StartupSnapshot>(
  (ref) => StartupSnapshot.oneProfile,
);

final meloopShellControllerProvider =
    NotifierProvider<MeloopShellController, MeloopShellState>(
      MeloopShellController.new,
    );

class MeloopShellController extends Notifier<MeloopShellState> {
  @override
  MeloopShellState build() {
    final initial = _fromSnapshot(ref.read(startupSnapshotProvider));
    final service = ref.read(practiceSessionServiceProvider);
    if (service == null) return initial;
    final subscription = service.changes.listen((value) {
      if (ref.mounted) state = _withPractice(state, value);
    });
    ref.onDispose(subscription.cancel);
    return _withPractice(initial, service.current);
  }

  MeloopShellState _withPractice(
    MeloopShellState shell,
    PracticeSessionState value,
  ) {
    final draft = value.draft;
    return shell.copyWith(
      selectedProfileId: shell.profiles.any((p) => p.id == draft?.profileId)
          ? draft?.profileId
          : null,
      clearDraft: draft == null,
      draft: draft == null
          ? null
          : PreviewPracticeDraft(
              sessionId: draft.id,
              profileId: draft.profileId,
              title: draft.title,
              startedAt: draft.startedAt,
              accumulatedSeconds: draft.elapsed.inSeconds,
              isRunning: draft.isRunning,
              wasRecovered: draft.wasRecovered,
            ),
      sessions: value.sessions,
    );
  }

  PracticeSessionService get _practice =>
      ref.read(practiceSessionServiceProvider) ??
      (throw StateError('Practice session service has not been configured'));

  MeloopShellState _fromSnapshot(StartupSnapshot snapshot) {
    final profiles = List<PreviewInstrumentProfile>.unmodifiable(
      snapshot.profiles,
    );
    final ids = profiles.map((profile) => profile.id).toSet();
    final draft = ids.contains(snapshot.draft?.profileId)
        ? snapshot.draft!.copyWith(isRunning: false, wasRecovered: true)
        : null;
    final selectedId = ids.contains(draft?.profileId)
        ? draft!.profileId
        : ids.contains(snapshot.selectedProfileId)
        ? snapshot.selectedProfileId
        : profiles.firstOrNull?.id;
    final destination = draft != null
        ? StartupDestination.recoveredTimer
        : profiles.isEmpty
        ? StartupDestination.welcome
        : profiles.length == 1
        ? StartupDestination.main
        : StartupDestination.profilePicker;
    return MeloopShellState(
      profiles: profiles,
      selectedProfileId: selectedId,
      draft: draft,
      destination: destination,
      requiresProfileSelection: destination == StartupDestination.profilePicker,
    );
  }

  void reload(StartupSnapshot snapshot) => state = _fromSnapshot(snapshot);

  void selectTab(int index) {
    if (index < 0 || index > 3) return;
    state = state.copyWith(
      selectedTab: index,
      destination: StartupDestination.main,
      requiresProfileSelection: false,
    );
  }

  void showProfilePicker() {
    if (state.profiles.isEmpty) return;
    state = state.copyWith(
      destination: StartupDestination.profilePicker,
      requiresProfileSelection: false,
    );
  }

  void showMain() {
    if (state.profiles.isEmpty) return;
    state = state.copyWith(
      destination: StartupDestination.main,
      requiresProfileSelection: false,
    );
  }

  void showTimer() {
    if (state.draft == null) return;
    state = state.copyWith(destination: StartupDestination.recoveredTimer);
  }

  bool selectProfile(String id) {
    if (!state.profiles.any((profile) => profile.id == id)) return false;
    final draft = state.draft;
    if (draft != null && draft.profileId != id) return false;
    state = state.copyWith(
      selectedProfileId: id,
      selectedTab: 0,
      destination: StartupDestination.main,
      requiresProfileSelection: false,
    );
    return true;
  }

  void addProfile({
    required String name,
    required MeloopInstrument instrument,
  }) {
    final profile = PreviewInstrumentProfile(
      id: 'preview-${state.profiles.length + 1}',
      name: name,
      instrument: instrument,
    );
    state = state.copyWith(
      profiles: List.unmodifiable([...state.profiles, profile]),
      selectedProfileId: profile.id,
      selectedTab: 0,
      destination: StartupDestination.main,
      requiresProfileSelection: false,
    );
  }

  Future<void> startDraft(String title) async {
    final profile = state.selectedProfile;
    if (profile == null) return;
    await _practice.start(profileId: profile.id, title: title);
    if (ref.mounted) showTimer();
  }

  Future<void> pauseDraft() => _practice.pause();

  Future<void> discardDraft() async {
    await _practice.discard();
    if (ref.mounted) selectTab(1);
  }
}
