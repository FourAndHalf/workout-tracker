import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/backup_repository.dart';
import 'package:fitness_tracker/data/repositories/progress_repository.dart';
import 'package:fitness_tracker/data/repositories/supplement_repository.dart';
import 'package:fitness_tracker/services/backup_archive_service.dart';
import 'package:fitness_tracker/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBackupArchiveService extends Mock implements BackupArchiveService {}

class MockGoogleDriveBackupService extends Mock implements GoogleDriveBackupService {}

void main() {
  setUpAll(() async {
    registerFallbackValue(Directory.systemTemp);
    registerFallbackValue(File(''));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(AppDatabase(NativeDatabase.memory()));
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(await SharedPreferences.getInstance());
  });

  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;
  late SharedPreferences preferences;
  late ProgressRepository progressRepository;
  late SupplementRepository supplementRepository;
  late MockBackupArchiveService archiveService;
  late MockGoogleDriveBackupService driveService;
  late BackupRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_repository_test_');
    dbFile = File('${tempDir.path}/fitness_tracker.sqlite');
    db = AppDatabase(NativeDatabase(dbFile));

    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    progressRepository = ProgressRepository(preferences);
    supplementRepository = SupplementRepository(preferences);

    archiveService = MockBackupArchiveService();
    driveService = MockGoogleDriveBackupService();

    repository = BackupRepository(
      database: db,
      databaseFile: dbFile,
      preferences: preferences,
      progressRepository: progressRepository,
      supplementRepository: supplementRepository,
      archiveService: archiveService,
      driveService: driveService,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('createBackup', () {
    test('collects photo paths and uploads the built archive', () async {
      await db.into(db.foodPhotos).insert(
        FoodPhotosCompanion.insert(filePath: 'food1.jpg'),
      );
      await progressRepository.saveCheckIn(
        ProgressCheckIn(
          date: DateTime(2026, 1, 1),
          weightKg: 80,
          fatPercent: 15,
          photoPath: 'progress1.jpg',
        ),
      );
      await supplementRepository.saveSupplement(
        const SupplementItem(id: 's1', name: 'Creatine', photoPath: 'supp1.jpg'),
      );

      final builtBytes = Uint8List.fromList([1, 2, 3]);
      when(
        () => archiveService.buildArchive(
          database: any(named: 'database'),
          databaseFile: any(named: 'databaseFile'),
          preferences: any(named: 'preferences'),
          photoPaths: any(named: 'photoPaths'),
        ),
      ).thenAnswer((_) async => builtBytes);
      when(
        () => driveService.uploadBackup(any(), any()),
      ).thenAnswer((_) async => drive.File()..id = 'uploaded');

      await repository.createBackup();

      final captured = verify(
        () => archiveService.buildArchive(
          database: db,
          databaseFile: dbFile,
          preferences: preferences,
          photoPaths: captureAny(named: 'photoPaths'),
        ),
      ).captured;
      expect(captured.single, ['food1.jpg', 'progress1.jpg', 'supp1.jpg']);

      final uploadCall = verify(
        () => driveService.uploadBackup(captureAny(), captureAny()),
      ).captured;
      expect(uploadCall[0], matches(RegExp(r'^backup_.*\.ftbackup$')));
      expect(uploadCall[1], builtBytes);
    });
  });

  group('restoreBackup', () {
    Future<ExtractedBackup> stubExtractedBackup({
      required String newDbContent,
      required String photoOriginalPath,
      required String photoContent,
    }) async {
      final sourceDir = await Directory(
        '${tempDir.path}/staged_source',
      ).create(recursive: true);
      final stagedDb = File('${sourceDir.path}/db.sqlite');
      await stagedDb.writeAsString(newDbContent);
      final stagedPhoto = File('${sourceDir.path}/photo.jpg');
      await stagedPhoto.writeAsString(photoContent);

      return ExtractedBackup(
        manifest: BackupManifest(
          schemaVersion: db.schemaVersion,
          createdAt: DateTime.now(),
          photoPaths: const {},
        ),
        databaseFile: stagedDb,
        preferences: const {'foo': 'bar', 'count': 5},
        photos: [
          PhotoRestoreEntry(originalPath: photoOriginalPath, stagedFile: stagedPhoto),
        ],
      );
    }

    test('replaces the database, preferences, and photo files', () async {
      await dbFile.writeAsString('ORIGINAL DB CONTENT');
      await preferences.setString('old', 'value');
      final photoPath = '${tempDir.path}/photos/pic1.jpg';

      when(() => driveService.downloadBackup(any())).thenAnswer((_) async => Uint8List(0));
      when(
        () => archiveService.extractArchive(any(), stagingDir: any(named: 'stagingDir')),
      ).thenAnswer(
        (_) => stubExtractedBackup(
          newDbContent: 'NEW DB CONTENT',
          photoOriginalPath: photoPath,
          photoContent: 'photo-bytes',
        ),
      );

      await repository.restoreBackup('backup-1');

      expect(await dbFile.readAsString(), 'NEW DB CONTENT');
      expect(preferences.getString('foo'), 'bar');
      expect(preferences.getInt('count'), 5);
      expect(preferences.containsKey('old'), isFalse);
      expect(await File(photoPath).readAsString(), 'photo-bytes');
      expect(await File('${dbFile.path}.bak').exists(), isFalse);
      expect(await Directory('${tempDir.path}/.restore_staging').exists(), isFalse);
    });

    test('rolls back the database file if a later restore step fails', () async {
      await dbFile.writeAsString('ORIGINAL DB CONTENT');
      // A photo whose staged file doesn't exist forces the photo-copy step
      // to throw after the database has already been swapped.
      final missingStagedPhoto = File('${tempDir.path}/does_not_exist.jpg');

      when(() => driveService.downloadBackup(any())).thenAnswer((_) async => Uint8List(0));
      when(
        () => archiveService.extractArchive(any(), stagingDir: any(named: 'stagingDir')),
      ).thenAnswer((_) async {
        final sourceDir = await Directory(
          '${tempDir.path}/staged_source',
        ).create(recursive: true);
        final stagedDb = File('${sourceDir.path}/db.sqlite');
        await stagedDb.writeAsString('NEW DB CONTENT');
        return ExtractedBackup(
          manifest: BackupManifest(
            schemaVersion: db.schemaVersion,
            createdAt: DateTime.now(),
            photoPaths: const {},
          ),
          databaseFile: stagedDb,
          preferences: const {},
          photos: [
            PhotoRestoreEntry(
              originalPath: '${tempDir.path}/pic.jpg',
              stagedFile: missingStagedPhoto,
            ),
          ],
        );
      });

      await expectLater(
        () => repository.restoreBackup('backup-1'),
        throwsA(anything),
      );

      expect(await dbFile.readAsString(), 'ORIGINAL DB CONTENT');
      expect(await File('${dbFile.path}.bak').exists(), isFalse);
      expect(await Directory('${tempDir.path}/.restore_staging').exists(), isFalse);
    });
  });

  group('first-launch restore check flag', () {
    test('is false until explicitly marked complete', () async {
      expect(repository.hasCompletedFirstLaunchRestoreCheck, isFalse);

      await repository.markFirstLaunchRestoreCheckComplete();

      expect(repository.hasCompletedFirstLaunchRestoreCheck, isTrue);
    });
  });
}
