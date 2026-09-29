/// Frontend form values. Map these to backend models at the app boundary.
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
