import 'dart:typed_data';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

class GoogleDriveSignInCancelledException implements Exception {
  @override
  String toString() => 'GoogleDriveSignInCancelledException';
}

class GoogleDriveNotSignedInException implements Exception {
  @override
  String toString() => 'GoogleDriveNotSignedInException';
}

/// The subset of the Drive `files` API this app needs, scoped to backups
/// stored in the hidden `appDataFolder`. Kept as an interface so the real
/// `googleapis`-backed implementation can be swapped for a test double.
abstract class DriveBackupFilesApi {
  Future<drive.File> upload(String fileName, Uint8List bytes);
  Future<List<drive.File>> list();
  Future<Uint8List> download(String fileId);
  Future<void> delete(String fileId);
}

/// Thin wrapper over the generated `drive.DriveApi`, kept as its own class
/// so its request/response wiring can be exercised directly in tests
/// (against a mocked [http.Client]) without touching Google Sign-In.
class GoogleDriveFilesApi implements DriveBackupFilesApi {
  final drive.DriveApi _api;

  GoogleDriveFilesApi(this._api);

  @override
  Future<drive.File> upload(String fileName, Uint8List bytes) {
    final metadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];
    return _api.files.create(
      metadata,
      uploadMedia: commons.Media(Stream.value(bytes), bytes.length),
    );
  }

  @override
  Future<List<drive.File>> list() async {
    final result = await _api.files.list(
      spaces: 'appDataFolder',
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,createdTime,size)',
    );
    return result.files ?? const [];
  }

  @override
  Future<Uint8List> download(String fileId) async {
    final media = await _api.files.get(
      fileId,
      downloadOptions: commons.DownloadOptions.fullMedia,
    ) as commons.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  @override
  Future<void> delete(String fileId) => _api.files.delete(fileId);
}

/// Google Sign-In + Drive access for storing/retrieving app backups in the
/// user's hidden `appDataFolder`. Has no knowledge of what a backup contains.
class GoogleDriveBackupService {
  final GoogleSignIn _googleSignIn;
  final DriveBackupFilesApi? _filesApiOverride;
  Future<void>? _initialization;
  GoogleSignInAccount? _account;

  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
    DriveBackupFilesApi? filesApiForTesting,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _filesApiOverride = filesApiForTesting;

  Future<void> _ensureInitialized() =>
      _initialization ??= _googleSignIn.initialize();

  Future<GoogleSignInAccount?> _restoreAccount() async {
    if (_account != null) return _account;
    await _ensureInitialized();
    return _account = await _googleSignIn.attemptLightweightAuthentication();
  }

  Future<bool> isSignedIn() async => await _restoreAccount() != null;

  Future<void> signIn() async {
    await _ensureInitialized();
    try {
      _account = await _googleSignIn.authenticate(
        scopeHint: const [driveAppDataScope],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleDriveSignInCancelledException();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    _account = null;
    await _googleSignIn.signOut();
  }

  Future<drive.File> uploadBackup(String fileName, Uint8List bytes) async {
    final api = await _filesApi();
    return api.upload(fileName, bytes);
  }

  Future<List<drive.File>> listBackups() async {
    final api = await _filesApi();
    return api.list();
  }

  Future<Uint8List> downloadBackup(String fileId) async {
    final api = await _filesApi();
    return api.download(fileId);
  }

  Future<void> deleteBackup(String fileId) async {
    final api = await _filesApi();
    await api.delete(fileId);
  }

  Future<DriveBackupFilesApi> _filesApi() async {
    if (_filesApiOverride != null) return _filesApiOverride;
    final account = await _restoreAccount();
    if (account == null) throw GoogleDriveNotSignedInException();
    const scopes = [driveAppDataScope];
    final authorization =
        await account.authorizationClient.authorizationForScopes(scopes) ??
        await account.authorizationClient.authorizeScopes(scopes);
    return GoogleDriveFilesApi(
      drive.DriveApi(authorization.authClient(scopes: scopes)),
    );
  }
}
