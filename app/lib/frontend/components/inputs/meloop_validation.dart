/// Presentation validation only. The domain must validate before committing.
abstract final class MeloopValidation {
  static final _singleLineControls = RegExp(r'[\x00-\x1F\x7F]');
  static final _noteControls = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  static String? singleLine(
    String? value, {
    required String label,
    required int maxLength,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Vui lòng nhập ${label.toLowerCase()}.';
    if (_singleLineControls.hasMatch(value ?? '')) {
      return '$label không được có xuống dòng hoặc ký tự điều khiển.';
    }
    if (text.runes.length > maxLength) return '$label tối đa $maxLength ký tự.';
    return null;
  }

  static String? title(String? value) =>
      singleLine(value, label: 'Tên buổi luyện', maxLength: 100);
  static String? profileName(String? value) =>
      singleLine(value, label: 'Tên hồ sơ', maxLength: 50);
  static String? customInstrument(String? value) =>
      singleLine(value, label: 'Tên nhạc cụ', maxLength: 40);
  static String? note(String? value) {
    if (_noteControls.hasMatch(value ?? '')) {
      return 'Ghi chú có ký tự điều khiển không hợp lệ.';
    }
    if ((value ?? '').runes.length > 2000) return 'Ghi chú tối đa 2.000 ký tự.';
    return null;
  }

  static String? integer(
    String? value, {
    required String label,
    required int min,
    required int max,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Vui lòng nhập ${label.toLowerCase()}.';
    if (!RegExp(r'^\d+$').hasMatch(text)) return '$label phải là số nguyên.';
    final number = int.tryParse(text);
    if (number == null || number < min || number > max) {
      return '$label phải từ $min đến $max.';
    }
    return null;
  }
}
