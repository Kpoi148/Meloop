String formatPracticeDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final hours = seconds ~/ Duration.secondsPerHour;
  final minutes =
      seconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute;
  final remainder = seconds % Duration.secondsPerMinute;
  final core =
      '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  return hours == 0 ? core : '${hours.toString().padLeft(2, '0')}:$core';
}
