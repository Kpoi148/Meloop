import 'journal_models.dart';
import 'practice_review_service.dart';

abstract interface class PracticeSessionUpdateService {
  /// Update only the saved row belonging to this profile. Ownership, measured
  /// time, creation metadata and recording links remain unchanged.
  Future<PracticeSession> update({
    required String profileId,
    required String sessionId,
    required PracticeReviewValues values,
  });
}
