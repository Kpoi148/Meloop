import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/journal/journal_text.dart';

import '../components/layout/meloop_art.dart';

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
    this.instrumentName,
    this.isReview = false,
    this.sessionId,
  });

  final String profileId;
  final String title;
  final int accumulatedSeconds;
  final bool isRunning;
  final bool wasRecovered;
  final String? instrumentName;
  final bool isReview;
  final String? sessionId;

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
    instrumentName: instrumentName,
    isReview: isReview,
    sessionId: sessionId,
  );
}

class StartupSnapshot {
  const StartupSnapshot({
    this.profiles = const [],
    this.selectedProfileId,
    this.draft,
    this.recoverDraftOnEntry = true,
    this.hasChosenProfile = false,
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final PreviewPracticeDraft? draft;
  final bool recoverDraftOnEntry;
  final bool hasChosenProfile;

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
  });

  final List<PreviewInstrumentProfile> profiles;
  final String? selectedProfileId;
  final PreviewPracticeDraft? draft;
  final StartupDestination destination;
  final int selectedTab;
  final bool requiresProfileSelection;

  PreviewPracticeDraft? get selectedDraft =>
      draft?.profileId == selectedProfile?.id ? draft : null;

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
  MeloopShellState build() => _fromSnapshot(ref.read(startupSnapshotProvider));

  MeloopShellState _fromSnapshot(StartupSnapshot snapshot) {
    final profiles = List<PreviewInstrumentProfile>.unmodifiable(
      snapshot.profiles,
    );
    final ids = profiles.map((profile) => profile.id).toSet();
    final draft = ids.contains(snapshot.draft?.profileId)
        ? snapshot.draft!.copyWith(isRunning: false, wasRecovered: true)
        : null;
    final selectedId = ids.contains(snapshot.selectedProfileId)
        ? snapshot.selectedProfileId
        : profiles.firstOrNull?.id;
    final destination =
        draft != null &&
            draft.profileId == selectedId &&
            snapshot.recoverDraftOnEntry
        ? StartupDestination.recoveredTimer
        : profiles.isEmpty
        ? StartupDestination.welcome
        : profiles.length == 1 || snapshot.hasChosenProfile
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
    if (state.selectedDraft == null) return;
    state = state.copyWith(destination: StartupDestination.recoveredTimer);
  }

  bool selectProfile(String id) {
    if (!state.profiles.any((profile) => profile.id == id)) return false;
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

  void startDraft(String title) {
    final profile = state.selectedProfile;
    if (profile == null || state.draft != null) return;
    state = state.copyWith(
      draft: PreviewPracticeDraft(
        profileId: profile.id,
        title: title,
        isRunning: true,
      ),
      destination: StartupDestination.recoveredTimer,
    );
  }

  void openStoredDraft(PreviewPracticeDraft draft) {
    if (state.selectedProfile?.id != draft.profileId) {
      throw StateError('Draft does not belong to the selected profile.');
    }
    state = state.copyWith(
      draft: draft,
      destination: StartupDestination.recoveredTimer,
    );
  }

  void checkpointDraft({required int seconds, required bool isRunning}) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(
        accumulatedSeconds: seconds.clamp(
          0,
          PracticeRules.maximumDuration.inSeconds,
        ),
        isRunning: isRunning,
        wasRecovered: false,
      ),
    );
  }

  void finishDraft() {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(draft: draft.copyWith(isRunning: false));
  }

  void renameDraft(String sessionId, String title) {
    if (state.draft?.sessionId != sessionId) return;
    state = state.copyWith(draft: state.draft!.copyWith(title: title));
  }

  void refreshSavedSessionCounts(Map<String, int> counts) {
    if (!ref.mounted) return;
    state = state.copyWith(
      profiles: List.unmodifiable([
        for (final profile in state.profiles)
          PreviewInstrumentProfile(
            id: profile.id,
            name: profile.name,
            instrument: profile.instrument,
            customInstrumentName: profile.customInstrumentName,
            savedSessionCount: counts[profile.id] ?? profile.savedSessionCount,
          ),
      ]),
    );
  }

  void completeDraft({String? sessionId}) {
    if (!ref.mounted ||
        (sessionId != null && state.draft?.sessionId != sessionId)) {
      return;
    }
    state = state.copyWith(
      clearDraft: true,
      selectedTab: 0,
      destination: StartupDestination.main,
    );
  }
}
