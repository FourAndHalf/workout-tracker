import 'dart:typed_data';

import 'package:fitness_tracker/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class FakeDriveBackupFilesApi extends Mock implements DriveBackupFilesApi {}

void main() {
  late MockGoogleSignIn googleSignIn;
  late FakeDriveBackupFilesApi filesApi;

  setUp(() {
    googleSignIn = MockGoogleSignIn();
    filesApi = FakeDriveBackupFilesApi();
  });

  group('sign-in state', () {
    setUp(() {
      when(() => googleSignIn.initialize()).thenAnswer((_) async {});
    });

    test('isSignedIn is true when lightweight authentication returns an account', () async {
      when(() => googleSignIn.attemptLightweightAuthentication())
          .thenAnswer((_) async => MockGoogleSignInAccount());
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      expect(await service.isSignedIn(), isTrue);
    });

    test('isSignedIn is false when no account can be restored', () async {
      when(() => googleSignIn.attemptLightweightAuthentication())
          .thenAnswer((_) async => null);
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      expect(await service.isSignedIn(), isFalse);
      verify(() => googleSignIn.attemptLightweightAuthentication()).called(1);
    });

    test('signIn throws when the user cancels the picker', () async {
      when(() => googleSignIn.authenticate(scopeHint: any(named: 'scopeHint')))
          .thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      expect(
        () => service.signIn(),
        throwsA(isA<GoogleDriveSignInCancelledException>()),
      );
    });

    test('signIn completes when an account is returned', () async {
      when(() => googleSignIn.authenticate(scopeHint: any(named: 'scopeHint')))
          .thenAnswer((_) async => MockGoogleSignInAccount());
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      await service.signIn();
      verify(() => googleSignIn.authenticate(scopeHint: any(named: 'scopeHint')))
          .called(1);
    });

    test('signOut delegates to GoogleSignIn', () async {
      when(() => googleSignIn.signOut()).thenAnswer((_) async {});
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      await service.signOut();
      verify(() => googleSignIn.signOut()).called(1);
    });

    test('throws GoogleDriveNotSignedInException when no account is available', () async {
      when(() => googleSignIn.attemptLightweightAuthentication())
          .thenAnswer((_) async => null);
      final service = GoogleDriveBackupService(googleSignIn: googleSignIn);

      expect(
        () => service.uploadBackup('backup.ftbackup', Uint8List(0)),
        throwsA(isA<GoogleDriveNotSignedInException>()),
      );
    });
  });

  group('backup operations delegate to the files API', () {
    late GoogleDriveBackupService service;

    setUp(() {
      service = GoogleDriveBackupService(
        googleSignIn: googleSignIn,
        filesApiForTesting: filesApi,
      );
    });

    test('uploadBackup passes the file name and bytes through', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final created = drive.File()..id = 'file-1';
      when(() => filesApi.upload('backup.ftbackup', bytes)).thenAnswer((_) async => created);

      final result = await service.uploadBackup('backup.ftbackup', bytes);

      expect(result.id, 'file-1');
      verify(() => filesApi.upload('backup.ftbackup', bytes)).called(1);
    });

    test('listBackups returns whatever the files API reports', () async {
      final files = [drive.File()..id = 'a', drive.File()..id = 'b'];
      when(() => filesApi.list()).thenAnswer((_) async => files);

      final result = await service.listBackups();

      expect(result.map((f) => f.id), ['a', 'b']);
    });

    test('downloadBackup returns the downloaded bytes', () async {
      final bytes = Uint8List.fromList([9, 9, 9]);
      when(() => filesApi.download('file-1')).thenAnswer((_) async => bytes);

      final result = await service.downloadBackup('file-1');

      expect(result, bytes);
    });

    test('deleteBackup delegates to the files API', () async {
      when(() => filesApi.delete('file-1')).thenAnswer((_) async {});

      await service.deleteBackup('file-1');

      verify(() => filesApi.delete('file-1')).called(1);
    });
  });
}
