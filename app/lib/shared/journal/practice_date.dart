import 'journal_failure.dart';

/// A calendar date, independent of timezone conversion and daylight saving.
class PracticeDate implements Comparable<PracticeDate> {
  PracticeDate._(this.value);
  final String value;
  static const earliest = '2000-01-01';
  static final _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  factory PracticeDate.parse(String value) {
    if (!_pattern.hasMatch(value) || value.compareTo(earliest) < 0) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    final parts = value.split('-').map(int.parse).toList();
    final date = DateTime.utc(parts[0], parts[1], parts[2]);
    if (date.year != parts[0] ||
        date.month != parts[1] ||
        date.day != parts[2]) {
      throw const JournalFailure(JournalFailureCode.invalidInput);
    }
    return PracticeDate._(value);
  }

  /// Caller supplies device-local time (or an injected local clock).
  factory PracticeDate.fromLocal(DateTime date) => PracticeDate.parse(
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}',
  );

  bool isAfter(PracticeDate other) => compareTo(other) > 0;
  @override
  int compareTo(PracticeDate other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) =>
      other is PracticeDate && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}
