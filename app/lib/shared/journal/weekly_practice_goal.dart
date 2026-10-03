/// Read-only settings for a profile's Monday–Sunday practice goal.
class WeeklyPracticeGoal {
  WeeklyPracticeGoal({required this.enabled, required this.targetDays}) {
    if (targetDays < 1 || targetDays > DateTime.daysPerWeek) {
      throw const FormatException('Invalid weekly goal target');
    }
  }
  final bool enabled;
  final int targetDays;
}

abstract interface class WeeklyPracticeGoalReader {
  /// A missing row is unconfigured, never an implicit enabled goal.
  Future<WeeklyPracticeGoal?> read(String profileId);
}
