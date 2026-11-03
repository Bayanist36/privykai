/// Static product metadata shown in Settings.
///
/// `version` mirrors `pubspec.yaml`; there is no runtime package-info plugin in
/// the MVP, so the two values are kept in sync manually before a release.
abstract final class AppInfo {
  /// Confirmed product name for the launcher and the RuStore card (SUK-6).
  static const String name = 'Привыкай';
  static const String tagline = 'Трекер привычек';
  static const String version = '1.0.0';
  static const String company = 'Sukhanov labs';
  static const String copyright = 'Sukhanov labs · 2026';

  /// Public privacy policy URL required by the RuStore card.
  ///
  /// SUK-15 (marketing) supplies the final URL. Until then the value stays
  /// empty and the app keeps the built-in offline policy screen; it never
  /// opens the network or asks for `INTERNET` (BUG-08).
  static const String privacyPolicyUrl = '';

  static bool get hasPrivacyPolicyUrl => privacyPolicyUrl.isNotEmpty;
}
