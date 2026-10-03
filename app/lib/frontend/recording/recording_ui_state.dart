enum RecordingPhase { ready, recording, review }

enum RecordingMicrophone { permissionRequired, ready, denied, unavailable }

enum RecordingIssue {
  microphoneDenied,
  microphoneUnavailable,
  storageFull,
  audioBusy,
  startFailed,
  saveFailed,
  interrupted,
  durationLimit,
  fileLimit,
}

/// Presentation data supplied by the quota source; widgets own no Free rules.
class RecordingQuota {
  const RecordingQuota({
    required this.maximumDuration,
    required this.maximumFiles,
    required this.savedFiles,
    required this.isPro,
  });

  final Duration maximumDuration;
  final int? maximumFiles;
  final int savedFiles;
  final bool isPro;

  bool get full => maximumFiles != null && savedFiles >= maximumFiles!;

  RecordingQuota withSavedFiles(int count) => RecordingQuota(
    maximumDuration: maximumDuration,
    maximumFiles: maximumFiles,
    savedFiles: count,
    isPro: isPro,
  );
}

class RecordingUiState {
  const RecordingUiState({
    required this.quota,
    this.phase = RecordingPhase.ready,
    this.microphone = RecordingMicrophone.permissionRequired,
    this.elapsed = Duration.zero,
    this.playbackPosition = Duration.zero,
    this.playing = false,
    this.keptTakes = 0,
    this.issue,
  });

  final RecordingQuota quota;
  final RecordingPhase phase;
  final RecordingMicrophone microphone;
  final Duration elapsed, playbackPosition;
  final bool playing;
  final int keptTakes;
  final RecordingIssue? issue;

  RecordingUiState copyWith({
    RecordingQuota? quota,
    RecordingPhase? phase,
    RecordingMicrophone? microphone,
    Duration? elapsed,
    Duration? playbackPosition,
    bool? playing,
    int? keptTakes,
    RecordingIssue? issue,
  }) => RecordingUiState(
    quota: quota ?? this.quota,
    phase: phase ?? this.phase,
    microphone: microphone ?? this.microphone,
    elapsed: elapsed ?? this.elapsed,
    playbackPosition: playbackPosition ?? this.playbackPosition,
    playing: playing ?? this.playing,
    keptTakes: keptTakes ?? this.keptTakes,
    issue: issue,
  );
}
