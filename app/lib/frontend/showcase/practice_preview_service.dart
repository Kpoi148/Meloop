import 'dart:async';
import 'dart:math';

import '../../shared/practice/practice_session_service.dart';
import '../../shared/practice/session_form_values.dart';
import '../application/startup_controller.dart';

/// Memory-only FE adapter. Never writes to the production journal database.
/// Timing uses one monotonic clock, including while tool screens are open.
class PracticePreviewService implements PracticeSessionService {
  factory PracticePreviewService.fromSnapshot(
    StartupSnapshot snapshot, {
    required SessionFormSave onSave,
  }) {
    final draft = snapshot.draft;
    return PracticePreviewService(
      onSave: onSave,
      initialDraft: draft == null
          ? null
          : PracticeSessionDraft(
              id: draft.sessionId ?? _uuid(),
              profileId: draft.profileId,
              title: draft.title,
              startedAt: draft.startedAt ?? DateTime.now(),
              elapsed: Duration(seconds: draft.accumulatedSeconds),
            ),
    );
  }

  PracticePreviewService({
    required this.onSave,
    PracticeSessionDraft? initialDraft,
    DateTime Function()? now,
    String Function()? newId,
    Stopwatch? clock,
    this.refreshInterval = const Duration(seconds: 1),
  }) : _now = now ?? DateTime.now,
       _newId = newId ?? _uuid,
       _clock = clock ?? Stopwatch(),
       _current = PracticeSessionState(
         draft: initialDraft?.copyWith(
           phase: PracticeSessionPhase.paused,
           wasRecovered: true,
         ),
       );

  final SessionFormSave onSave;
  final DateTime Function() _now;
  final String Function() _newId;
  final Duration refreshInterval;
  final Stopwatch _clock;
  final _changes = StreamController<PracticeSessionState>.broadcast(sync: true);
  final Map<String, Future<SavedPracticeSession>> _pendingSaves = {};
  Duration _accumulated = Duration.zero;
  Timer? _refresh;
  PracticeSessionState _current;

  @override
  PracticeSessionState get current => _current;
  @override
  Stream<PracticeSessionState> get changes => _changes.stream;

  void _emit(
    PracticeSessionDraft? draft, {
    List<SavedPracticeSession>? sessions,
  }) {
    _current = PracticeSessionState(
      draft: draft,
      sessions: sessions ?? _current.sessions,
    );
    if (!_changes.isClosed) _changes.add(_current);
  }

  void _startClock() {
    _accumulated = current.draft!.elapsed;
    _clock.reset();
    _clock.start();
    _refresh?.cancel();
    _refresh = Timer.periodic(refreshInterval, (_) {
      final draft = current.draft;
      if (draft?.isRunning == true) {
        _emit(draft!.copyWith(elapsed: _accumulated + _clock.elapsed));
      }
    });
  }

  PracticeSessionDraft _stopClock(PracticeSessionPhase phase) {
    final draft = current.draft;
    if (draft == null) throw StateError('No unfinished practice session');
    _clock.stop();
    _refresh?.cancel();
    _refresh = null;
    return draft.copyWith(
      elapsed: draft.isRunning ? _accumulated + _clock.elapsed : draft.elapsed,
      phase: phase,
      wasRecovered: false,
    );
  }

  @override
  Future<PracticeSessionDraft> start({
    required String profileId,
    required String title,
  }) async {
    // Recheck here even if setup was opened before another draft was created.
    if (current.draft case final draft?) return draft;
    if (title.trim().isEmpty) throw ArgumentError('Practice title is required');
    final draft = PracticeSessionDraft(
      id: _newId(),
      profileId: profileId,
      title: title.trim(),
      startedAt: _now(),
      phase: PracticeSessionPhase.running,
    );
    _emit(draft);
    _startClock();
    return draft;
  }

  @override
  Future<void> pause() async {
    if (current.draft?.isRunning != true) return;
    _emit(_stopClock(PracticeSessionPhase.paused));
  }

  @override
  Future<void> resume() async {
    final draft = current.draft;
    if (draft == null || draft.phase != PracticeSessionPhase.paused) return;
    _emit(
      draft.copyWith(phase: PracticeSessionPhase.running, wasRecovered: false),
    );
    _startClock();
  }

  @override
  Future<PracticeSessionDraft> finish() async {
    final draft = _stopClock(PracticeSessionPhase.review);
    _emit(draft);
    return draft;
  }

  @override
  Future<void> leaveReview() async {
    if (current.draft?.phase == PracticeSessionPhase.review) {
      _emit(current.draft!.copyWith(phase: PracticeSessionPhase.paused));
    }
  }

  @override
  Future<void> rename(String title) async {
    if (title.trim().isEmpty) throw ArgumentError('Practice title is required');
    if (current.draft case final draft?) {
      _emit(draft.copyWith(title: title.trim()));
    }
  }

  @override
  Future<void> discard() async {
    if (_pendingSaves.isNotEmpty) {
      throw StateError('Practice save is in progress');
    }
    _clock.stop();
    _refresh?.cancel();
    _refresh = null;
    _emit(null);
  }

  @override
  Future<SavedPracticeSession> save(String draftId, SessionFormValues values) {
    for (final session in current.sessions) {
      if (session.id == draftId) return Future.value(session);
    }
    if (_pendingSaves[draftId] case final pending?) return pending;
    final draft = current.draft;
    if (draft?.id != draftId || draft?.phase != PracticeSessionPhase.review) {
      return Future.error(StateError('Practice is not ready for review'));
    }
    final operation = Future<SavedPracticeSession>.microtask(
      () => _save(draft!, values),
    );
    _pendingSaves[draftId] = operation;
    return operation;
  }

  Future<SavedPracticeSession> _save(
    PracticeSessionDraft draft,
    SessionFormValues values,
  ) async {
    try {
      if (values.title.trim().isEmpty ||
          values.durationSeconds < PracticeSessionLimits.minDurationSeconds ||
          values.durationSeconds > PracticeSessionLimits.maxDurationSeconds) {
        throw ArgumentError('Invalid practice review');
      }
      await onSave(values);
      final saved = SavedPracticeSession(
        id: draft.id,
        profileId: draft.profileId,
        values: values,
      );
      _emit(null, sessions: List.unmodifiable([...current.sessions, saved]));
      return saved;
    } finally {
      _pendingSaves.remove(draft.id);
    }
  }

  void dispose() {
    _refresh?.cancel();
    _clock.stop();
    unawaited(_changes.close());
  }

  static String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
