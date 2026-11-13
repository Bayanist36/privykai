import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:habit_tracker/features/backup/domain/backup_exception.dart';

/// Platform file operations for the JSON backup.
///
/// Kept behind a small interface-like class so the validation logic stays
/// testable without plugins and every platform failure becomes one clear
/// Russian message.
class BackupFileGateway {
  const BackupFileGateway();

  /// Lets the user pick a `.json` file and returns its UTF-8 contents.
  ///
  /// Returns `null` when the picker was dismissed.
  Future<String?> pickJsonText() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Файл резервной копии',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (file == null) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes);
    } on BackupException {
      rethrow;
    } catch (error) {
      throw const BackupException(
        'Не удалось прочитать выбранный файл. Попробуйте другой.',
      );
    }
  }

  /// Writes [json] to a cache file and returns its path for sharing.
  Future<String> writeTemporary(String json, {DateTime? now}) async {
    try {
      final directory = await getTemporaryDirectory();
      final date = now ?? DateTime.now();
      final stamp =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final file = File(
        '${directory.path}${Platform.pathSeparator}'
        'pryvykai-backup-$stamp.json',
      );
      await file.writeAsString(json, flush: true);
      return file.path;
    } catch (error) {
      throw const BackupException('Не удалось сохранить файл резервной копии.');
    }
  }

  /// Opens the system share sheet for the exported file.
  Future<void> share(String path) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(path, mimeType: 'application/json')],
          subject: 'Резервная копия «Привыкай»',
          text:
              'Привычки, история отметок и настройки из приложения «Привыкай».',
        ),
      );
    } catch (error) {
      throw const BackupException('Не удалось поделиться файлом.');
    }
  }
}
