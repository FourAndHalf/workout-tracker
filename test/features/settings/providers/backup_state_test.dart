import 'package:fitness_tracker/data/repositories/backup_repository.dart';
import 'package:fitness_tracker/features/settings/providers/backup_state.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late MockBackupRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockBackupRepository();
    container = ProviderContainer(
      overrides: [
        backupRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('backupNow moves from idle to success when already signed in', () async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => true);
    when(() => repository.createBackup()).thenAnswer((_) async {});

    expect(
      container.read(backupOperationProvider).status,
      BackupOperationStatus.idle,
    );

    await container.read(backupOperationProvider.notifier).backupNow();

    expect(
      container.read(backupOperationProvider).status,
      BackupOperationStatus.success,
    );
    verifyNever(() => repository.signIn());
  });

  test('backupNow signs in first when not already signed in', () async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => false);
    when(() => repository.signIn()).thenAnswer((_) async {});
    when(() => repository.createBackup()).thenAnswer((_) async {});

    await container.read(backupOperationProvider.notifier).backupNow();

    verify(() => repository.signIn()).called(1);
    expect(
      container.read(backupOperationProvider).status,
      BackupOperationStatus.success,
    );
  });

  test('backupNow surfaces an error state when the repository throws', () async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => true);
    when(() => repository.createBackup()).thenThrow(Exception('upload failed'));

    await container.read(backupOperationProvider.notifier).backupNow();

    final state = container.read(backupOperationProvider);
    expect(state.status, BackupOperationStatus.error);
    expect(state.errorMessage, contains('upload failed'));
  });
}
