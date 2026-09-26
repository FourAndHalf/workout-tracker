import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../../services/backup_archive_service.dart';
import '../../services/google_drive_backup_service.dart';
import 'progress_repository.dart';
import 'supplement_repository.dart';

class BackupInfo {
  final String id;
  final String name;
  final DateTime? createdAt;
  final int? sizeBytes;

  const BackupInfo({
    required this.id,
    required this.name,
    this.createdAt,
    this.sizeBytes,
  });
}

/// Orchestrates the archive and Drive services to create and restore full
/// app backups. Restoring is a full overwrite: local data and photos are
/// replaced with what's in the selected backup.
class BackupRepository {
  static const String firstLaunchRestoreCheckKey =
      'backup_first_launch_restore_check_done';

  final AppDatabase database;
  final File databaseFile;
  final SharedPreferences preferences;
  final ProgressRepository progressRepository;
  final SupplementRepository supplementRepository;
  final BackupArchiveService archiveService;
  final GoogleDriveBackupService driveService;

  BackupRepository({
    required this.database,
    required this.databaseFile,
    required this.preferences,
    required this.progressRepository,
    required this.supplementRepository,
    required this.archiveService,
    required this.driveService,
  });

  Future<bool> isSignedIn() => driveService.isSignedIn();

  Future<void> signIn() => driveService.signIn();

  Future<void> signOut() => driveService.signOut();

  bool get hasCompletedFirstLaunchRestoreCheck =>
      preferences.getBool(firstLaunchRestoreCheckKey) ?? false;

  Future<void> markFirstLaunchRestoreCheckComplete() =>
      preferences.setBool(firstLaunchRestoreCheckKey, true);

  Future<void> createBackup() async {
    final photoPaths = await _collectPhotoPaths();
    final bytes = await archiveService.buildArchive(
      database: database,
      databaseFile: databaseFile,
      preferences: preferences,
      photoPaths: photoPaths,
    );
    final fileName =
        'backup_${DateTime.now().toUtc().toIso8601String()}.ftbackup';
    await driveService.uploadBackup(fileName, bytes);
  }

  Future<List<BackupInfo>> listBackups() async {
    final files = await driveService.listBackups();
    return files
        .where((file) => file.id != null)
        .map(
          (file) => BackupInfo(
            id: file.id!,
            name: file.name ?? file.id!,
            createdAt: file.createdTime,
            sizeBytes: file.size == null ? null : int.tryParse(file.size!),
          ),
        )
        .toList();
  }

  Future<void> restoreBackup(String backupId) async {
    final bytes = await driveService.downloadBackup(backupId);

    final stagingDir = await Directory(
      '${databaseFile.parent.path}/.restore_staging',
    ).create(recursive: true);
    final dbBackupFile = File('${databaseFile.path}.bak');
    var databaseSwapped = false;

    try {
      final extracted = await archiveService.extractArchive(
        bytes,
        stagingDir: stagingDir,
      );

      await database.close();

      if (await databaseFile.exists()) {
        await databaseFile.copy(dbBackupFile.path);
      }
      await _replaceFile(extracted.databaseFile, databaseFile);
      databaseSwapped = true;

      await preferences.clear();
      for (final entry in extracted.preferences.entries) {
        await _restorePreferenceEntry(entry.key, entry.value);
      }

      for (final photo in extracted.photos) {
        final target = File(photo.originalPath);
        await target.parent.create(recursive: true);
        await _replaceFile(photo.stagedFile, target);
      }

      if (await dbBackupFile.exists()) {
        await dbBackupFile.delete();
      }
    } catch (_) {
      if (databaseSwapped && await dbBackupFile.exists()) {
        await _replaceFile(dbBackupFile, databaseFile);
      }
      rethrow;
    } finally {
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
    }
  }

  Future<List<String>> _collectPhotoPaths() async {
    final paths = <String>[];

    final foodPhotos = await database.select(database.foodPhotos).get();
    paths.addAll(foodPhotos.map((photo) => photo.filePath));

    final checkIns = await progressRepository.getCheckIns();
    paths.addAll(
      checkIns.map((checkIn) => checkIn.photoPath).whereType<String>(),
    );

    final supplements = await supplementRepository.getSupplements();
    paths.addAll(
      supplements.map((supplement) => supplement.photoPath).whereType<String>(),
    );

    return paths;
  }

  Future<void> _restorePreferenceEntry(String key, Object? value) async {
    if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else if (value is String) {
      await preferences.setString(key, value);
    } else if (value is List) {
      await preferences.setStringList(key, value.cast<String>());
    }
  }

  /// Copies [source] over [destination] and removes [source], tolerating
  /// the case where a plain rename isn't possible (e.g. across filesystems).
  Future<void> _replaceFile(File source, File destination) async {
    try {
      await source.rename(destination.path);
    } on FileSystemException {
      await destination.writeAsBytes(await source.readAsBytes());
      await source.delete();
    }
  }
}
