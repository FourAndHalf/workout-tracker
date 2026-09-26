import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';

class BackupManifest {
  final int schemaVersion;
  final DateTime createdAt;

  /// Maps each photo's zip entry name to the absolute on-disk path it was
  /// read from, so a restore can write it back to that exact same path
  /// (app-private storage paths are stable for a given package on Android).
  final Map<String, String> photoPaths;

  const BackupManifest({
    required this.schemaVersion,
    required this.createdAt,
    required this.photoPaths,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'photoPaths': photoPaths,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    schemaVersion: json['schemaVersion'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    photoPaths:
        (json['photoPaths'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as String),
        ) ??
        const {},
  );
}

/// A photo file, extracted into the staging directory, paired with the
/// absolute path it should be restored to.
class PhotoRestoreEntry {
  final String originalPath;
  final File stagedFile;

  const PhotoRestoreEntry({
    required this.originalPath,
    required this.stagedFile,
  });
}

/// The result of extracting a backup archive into a staging directory.
class ExtractedBackup {
  final BackupManifest manifest;
  final File databaseFile;
  final Map<String, Object?> preferences;
  final List<PhotoRestoreEntry> photos;

  const ExtractedBackup({
    required this.manifest,
    required this.databaseFile,
    required this.preferences,
    required this.photos,
  });
}

class BackupArchiveException implements Exception {
  final String message;

  BackupArchiveException(this.message);

  @override
  String toString() => 'BackupArchiveException: $message';
}

/// Builds and reads the single zip archive used for Google Drive backups.
/// Has no knowledge of Drive or of the app's repositories — it only knows
/// how to turn a database file + preferences + photo files into a zip, and
/// back again into a staging directory.
class BackupArchiveService {
  static const String manifestEntry = 'manifest.json';
  static const String databaseEntry = 'database/fitness_tracker.sqlite';
  static const String preferencesEntry = 'preferences/shared_preferences.json';
  static const String photosDir = 'photos';

  Future<Uint8List> buildArchive({
    required AppDatabase database,
    required File databaseFile,
    required SharedPreferences preferences,
    required List<String> photoPaths,
  }) async {
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

    final archive = Archive();
    final manifestPhotoPaths = <String, String>{};

    var index = 0;
    for (final path in photoPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final entryName = '$photosDir/$index';
      _addBytes(archive, entryName, await file.readAsBytes());
      manifestPhotoPaths[entryName] = path;
      index++;
    }

    final manifest = BackupManifest(
      schemaVersion: database.schemaVersion,
      createdAt: DateTime.now().toUtc(),
      photoPaths: manifestPhotoPaths,
    );
    _addBytes(
      archive,
      manifestEntry,
      utf8.encode(jsonEncode(manifest.toJson())),
    );

    final dbBytes = await databaseFile.readAsBytes();
    _addBytes(archive, databaseEntry, dbBytes);

    final prefsMap = <String, Object?>{
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
    _addBytes(archive, preferencesEntry, utf8.encode(jsonEncode(prefsMap)));

    final zipBytes = ZipEncoder().encodeBytes(archive);
    return Uint8List.fromList(zipBytes);
  }

  Future<ExtractedBackup> extractArchive(
    Uint8List archiveBytes, {
    required Directory stagingDir,
  }) async {
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    final manifestFile = archive.findFile(manifestEntry);
    if (manifestFile == null) {
      throw BackupArchiveException('Backup archive is missing $manifestEntry');
    }
    final manifest = BackupManifest.fromJson(
      jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>,
    );

    final dbArchiveFile = archive.findFile(databaseEntry);
    if (dbArchiveFile == null) {
      throw BackupArchiveException('Backup archive is missing $databaseEntry');
    }
    final databaseFile = File('${stagingDir.path}/$databaseEntry');
    await databaseFile.parent.create(recursive: true);
    await databaseFile.writeAsBytes(dbArchiveFile.content);

    final preferences = <String, Object?>{};
    final prefsArchiveFile = archive.findFile(preferencesEntry);
    if (prefsArchiveFile != null) {
      preferences.addAll(
        jsonDecode(utf8.decode(prefsArchiveFile.content))
            as Map<String, dynamic>,
      );
    }

    final photos = <PhotoRestoreEntry>[];
    for (final entry in manifest.photoPaths.entries) {
      final archiveFile = archive.findFile(entry.key);
      if (archiveFile == null) continue;
      final stagedFile = File('${stagingDir.path}/${entry.key}');
      await stagedFile.parent.create(recursive: true);
      await stagedFile.writeAsBytes(archiveFile.content);
      photos.add(
        PhotoRestoreEntry(originalPath: entry.value, stagedFile: stagedFile),
      );
    }

    return ExtractedBackup(
      manifest: manifest,
      databaseFile: databaseFile,
      preferences: preferences,
      photos: photos,
    );
  }

  void _addBytes(Archive archive, String name, List<int> bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
}
