import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';

/// A photo file to embed in a backup archive, grouped by category so it can
/// be restored into the right on-disk location later.
class BackupPhotoFile {
  final String category;
  final String absolutePath;

  const BackupPhotoFile({required this.category, required this.absolutePath});
}

class BackupManifest {
  final int schemaVersion;
  final DateTime createdAt;

  const BackupManifest({required this.schemaVersion, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    schemaVersion: json['schemaVersion'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// The result of extracting a backup archive into a staging directory.
class ExtractedBackup {
  final BackupManifest manifest;
  final File databaseFile;
  final Map<String, Object?> preferences;
  final Map<String, List<File>> photosByCategory;

  const ExtractedBackup({
    required this.manifest,
    required this.databaseFile,
    required this.preferences,
    required this.photosByCategory,
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
    required List<BackupPhotoFile> photoFiles,
  }) async {
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

    final archive = Archive();

    final manifest = BackupManifest(
      schemaVersion: database.schemaVersion,
      createdAt: DateTime.now().toUtc(),
    );
    _addBytes(archive, manifestEntry, utf8.encode(jsonEncode(manifest.toJson())));

    final dbBytes = await databaseFile.readAsBytes();
    _addBytes(archive, databaseEntry, dbBytes);

    final prefsMap = <String, Object?>{
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
    _addBytes(archive, preferencesEntry, utf8.encode(jsonEncode(prefsMap)));

    for (final photo in photoFiles) {
      final file = File(photo.absolutePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final entryName = '$photosDir/${photo.category}/${p.basename(photo.absolutePath)}';
      _addBytes(archive, entryName, bytes);
    }

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
    final databaseFile = File(p.join(stagingDir.path, databaseEntry));
    await databaseFile.parent.create(recursive: true);
    await databaseFile.writeAsBytes(dbArchiveFile.content);

    final preferences = <String, Object?>{};
    final prefsArchiveFile = archive.findFile(preferencesEntry);
    if (prefsArchiveFile != null) {
      preferences.addAll(
        jsonDecode(utf8.decode(prefsArchiveFile.content)) as Map<String, dynamic>,
      );
    }

    final photosByCategory = <String, List<File>>{};
    for (final entry in archive.files) {
      if (!entry.name.startsWith('$photosDir/')) continue;
      final segments = entry.name.split('/');
      if (segments.length < 3) continue;
      final category = segments[1];
      final outFile = File(p.join(stagingDir.path, entry.name));
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content);
      photosByCategory.putIfAbsent(category, () => []).add(outFile);
    }

    return ExtractedBackup(
      manifest: manifest,
      databaseFile: databaseFile,
      preferences: preferences,
      photosByCategory: photosByCategory,
    );
  }

  void _addBytes(Archive archive, String name, List<int> bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
}
