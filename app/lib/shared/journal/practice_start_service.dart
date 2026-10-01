import 'journal_models.dart';

abstract interface class PracticeStartService {
  /// The request ID is retained across retries. An existing unfinished session
  /// wins globally, preserving its original identity, title and instrument.
  Future<PracticeDraft> start({
    required String requestId,
    required String profileId,
    required String title,
  });
}
