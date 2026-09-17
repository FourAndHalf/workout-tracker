import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';

enum BackupOperationStatus { idle, signingIn, backingUp, success, error }

class BackupOperationState {
  final BackupOperationStatus status;
  final String? errorMessage;

  const BackupOperationState({
    this.status = BackupOperationStatus.idle,
    this.errorMessage,
  });

  bool get isInProgress =>
      status == BackupOperationStatus.signingIn ||
      status == BackupOperationStatus.backingUp;
}

class BackupOperationNotifier extends StateNotifier<BackupOperationState> {
  final Ref ref;

  BackupOperationNotifier(this.ref) : super(const BackupOperationState());

  Future<void> backupNow() async {
    state = const BackupOperationState(status: BackupOperationStatus.signingIn);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      if (!await repository.isSignedIn()) {
        await repository.signIn();
      }

      state = const BackupOperationState(status: BackupOperationStatus.backingUp);
      await repository.createBackup();

      state = const BackupOperationState(status: BackupOperationStatus.success);
    } catch (e) {
      state = BackupOperationState(
        status: BackupOperationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final backupOperationProvider =
    StateNotifierProvider<BackupOperationNotifier, BackupOperationState>(
  (ref) => BackupOperationNotifier(ref),
);
