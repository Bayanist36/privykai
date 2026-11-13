/// Static product metadata shown in Settings.
///
/// `version` mirrors `pubspec.yaml`; there is no runtime package-info plugin in
/// the MVP, so the two values are kept in sync manually before a release.
abstract final class AppInfo {
  /// Confirmed product name for the launcher and the RuStore card (SUK-6).
  static const String name = 'Привыкай';
  static const String tagline = 'Трекер привычек';
  static const String version = '1.1.1';
  static const String company = 'Sukhanov labs';
  static const String copyright = 'Sukhanov labs · 2026';

  /// Edition of the public privacy policy mirrored by the built-in screen.
  static const String privacyPolicyEdition = '1.1';

  /// Public privacy policy URL required by the RuStore card.
  ///
  /// The built-in screen only shows this address as selectable text; it never
  /// opens the network and the app has no `INTERNET` permission (BUG-08).
  static const String privacyPolicyUrl =
      'https://Bayanist36.github.io/privykai-privacy/privykai-privacy.html';

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty;
}
