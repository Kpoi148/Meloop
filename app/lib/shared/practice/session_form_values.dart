/// Values submitted during review. Persistence models remain service-owned.
class SessionFormValues {
  const SessionFormValues({
    required this.title,
    required this.date,
    required this.durationSeconds,
    required this.practiced,
    required this.difficulty,
    required this.next,
    this.mood,
    this.focus,
  });

  final String title, practiced, difficulty, next;
  final DateTime date;
  final int durationSeconds;
  final int? mood, focus;
}

typedef SessionFormSave = Future<void> Function(SessionFormValues values);

abstract final class PracticeSessionLimits {
  static const minDurationSeconds = 1;
  static const maxDurationSeconds = 24 * 60 * 60;
}
