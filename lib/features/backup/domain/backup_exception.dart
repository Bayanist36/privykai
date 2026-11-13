/// User-facing failure of the backup export/import flow.
///
/// The message is already Russian and safe to show in a snackbar; the app
/// never exposes stack traces or file paths to the user.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
