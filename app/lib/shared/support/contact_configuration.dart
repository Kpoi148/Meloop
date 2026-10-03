/// Published contact details are supplied by the release owner, never by users.
class ContactConfiguration {
  const ContactConfiguration({
    this.privacyUrlVi = '',
    this.privacyUrlEn = '',
    this.supportEmail = '',
  });

  final String privacyUrlVi;
  final String privacyUrlEn;
  final String supportEmail;

  Uri? privacyUri(String languageCode) {
    final value = languageCode == 'vi' ? privacyUrlVi : privacyUrlEn;
    final uri = Uri.tryParse(value);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty &&
            !value.contains(RegExp(r'\s'))
        ? uri
        : null;
  }

  String? get emailAddress =>
      RegExp(
        r'^[a-zA-Z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+$',
      ).hasMatch(supportEmail)
      ? supportEmail
      : null;

  bool get isReadyForRelease =>
      privacyUri('vi') != null &&
      privacyUri('en') != null &&
      emailAddress != null;
}
