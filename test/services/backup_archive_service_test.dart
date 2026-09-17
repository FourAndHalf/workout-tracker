import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/services/backup_archive_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;
  late BackupArchiveService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_archive_test_');
    dbFile = File('${tempDir.path}/fitness_tracker.sqlite');
    db = AppDatabase(NativeDatabase(dbFile));
    service = BackupArchiveService();

    await db.into(db.programs).insert(
      ProgramsCompanion.insert(
        id: 'ffts-4week',
        name: 'Four Week Split',
        jsonData: '{"weeks":[]}',
      ),
    );

    SharedPreferences.setMockInitialValues({
      'weekly_progress_check_ins': ['{"date":"2026-01-01T00:00:00.000"}'],
      'nutrition_shopping_list_enabled': true,
      'some_count': 3,
    });
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('round-trips database, preferences, and photo files', () async {
    final foodPhoto = File('${tempDir.path}/food1.jpg');
    await foodPhoto.writeAsBytes([1, 2, 3, 4]);
    final progressPhoto = File('${tempDir.path}/progress1.png');
    await progressPhoto.writeAsBytes([5, 6, 7]);

    final preferences = await SharedPreferences.getInstance();

    final zipBytes = await service.buildArchive(
      database: db,
      databaseFile: dbFile,
      preferences: preferences,
      photoFiles: [
        BackupPhotoFile(category: 'food', absolutePath: foodPhoto.path),
        BackupPhotoFile(category: 'progress', absolutePath: progressPhoto.path),
      ],
    );

    final stagingDir = await Directory.systemTemp.createTemp('backup_extract_test_');
    addTearDown(() => stagingDir.delete(recursive: true));

    final extracted = await service.extractArchive(zipBytes, stagingDir: stagingDir);

    expect(extracted.manifest.schemaVersion, db.schemaVersion);

    final originalDbBytes = await dbFile.readAsBytes();
    final extractedDbBytes = await extracted.databaseFile.readAsBytes();
    expect(extractedDbBytes, originalDbBytes);

    expect(extracted.preferences['nutrition_shopping_list_enabled'], true);
    expect(extracted.preferences['some_count'], 3);
    expect(
      extracted.preferences['weekly_progress_check_ins'],
      ['{"date":"2026-01-01T00:00:00.000"}'],
    );

    expect(extracted.photosByCategory['food'], hasLength(1));
    expect(
      await extracted.photosByCategory['food']!.single.readAsBytes(),
      [1, 2, 3, 4],
    );
    expect(extracted.photosByCategory['progress'], hasLength(1));
    expect(
      await extracted.photosByCategory['progress']!.single.readAsBytes(),
      [5, 6, 7],
    );
  });

  test('skips photo files that no longer exist on disk', () async {
    final preferences = await SharedPreferences.getInstance();

    final zipBytes = await service.buildArchive(
      database: db,
      databaseFile: dbFile,
      preferences: preferences,
      photoFiles: [
        BackupPhotoFile(
          category: 'food',
          absolutePath: '${tempDir.path}/does_not_exist.jpg',
        ),
      ],
    );

    final stagingDir = await Directory.systemTemp.createTemp('backup_extract_test_');
    addTearDown(() => stagingDir.delete(recursive: true));

    final extracted = await service.extractArchive(zipBytes, stagingDir: stagingDir);
    expect(extracted.photosByCategory['food'], isNull);
  });

  test('throws when the archive is missing a manifest', () async {
    final stagingDir = await Directory.systemTemp.createTemp('backup_extract_test_');
    addTearDown(() => stagingDir.delete(recursive: true));

    expect(
      () => service.extractArchive(
        emptyZipBytes(),
        stagingDir: stagingDir,
      ),
      throwsA(isA<BackupArchiveException>()),
    );
  });
}

/// A minimal valid (but empty) zip archive, used to exercise the
/// missing-manifest error path without depending on internal encoder details.
Uint8List emptyZipBytes() {
  // A well-formed empty ZIP file: just the end-of-central-directory record.
  return base64.decode('UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA==');
}
