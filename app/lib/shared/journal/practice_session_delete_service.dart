/// Deletes a saved journal entry from history and statistics while retaining
/// its recordings. Unfinished sessions and foreign-profile IDs are rejected.
abstract interface class PracticeSessionDeleteService {
  /// Idempotent: retrying a committed deletion has no further effect.
  Future<void> delete({required String profileId, required String sessionId});
}
