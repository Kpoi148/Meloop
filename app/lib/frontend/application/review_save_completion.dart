import '../practice_sessions/practice_session.dart';
import 'session_form_values.dart';

/// Keeps the committed result while retrying only post-save work.
class ReviewSaveCompletion {
  ReviewSaveCompletion({required this.save, required this.complete});

  final Future<PracticeSession> Function(SessionFormValues) save;
  final Future<void> Function() complete;
  PracticeSession? _saved;
  bool _completed = false;
  bool _submitting = false;

  PracticeSession? get saved => _saved;
  bool get isSubmitting => _submitting;

  Future<void> submit(SessionFormValues values) async {
    _submitting = true;
    try {
      _saved ??= await save(values);
      if (!_completed) {
        await complete();
        _completed = true;
      }
    } finally {
      _submitting = false;
    }
  }
}
