import 'journal_models.dart';
import 'practice_review_service.dart';

abstract interface class PracticeSessionUpdateService {
  Future<PracticeSession> update({
    required String profileId,
    required String sessionId,
    required PracticeReviewValues values,
  });
}
