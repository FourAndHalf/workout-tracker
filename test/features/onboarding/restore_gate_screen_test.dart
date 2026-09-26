import 'package:fitness_tracker/data/repositories/backup_repository.dart';
import 'package:fitness_tracker/features/onboarding/restore_gate_screen.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late MockBackupRepository repository;
  late bool doneCalled;

  setUp(() {
    repository = MockBackupRepository();
    doneCalled = false;
    when(() => repository.markFirstLaunchRestoreCheckComplete())
        .thenAnswer((_) async {});
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        backupRepositoryProvider.overrideWith((ref) async => repository),
      ],
      child: MaterialApp(
        home: RestoreGateScreen(onDone: () => doneCalled = true),
      ),
    );
  }

  testWidgets('skip completes the gate without checking Drive', (tester) async {
    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Skip — Start Fresh'));
    await tester.pumpAndSettle();

    expect(doneCalled, isTrue);
    verify(() => repository.markFirstLaunchRestoreCheckComplete()).called(1);
    verifyNever(() => repository.listBackups());
  });

  testWidgets('finds a backup and restores it on confirmation', (tester) async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => true);
    when(() => repository.listBackups()).thenAnswer(
      (_) async => [
        BackupInfo(id: 'b1', name: 'backup_1', createdAt: DateTime(2026, 1, 1)),
      ],
    );
    when(() => repository.restoreBackup('b1')).thenAnswer((_) async {});

    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Sign in & Check for Backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Restore this backup'), findsOneWidget);
    await tester.tap(find.text('Restore this backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => repository.restoreBackup('b1')).called(1);
    expect(doneCalled, isTrue);
  });

  testWidgets('proceeds automatically when no backup exists', (tester) async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => true);
    when(() => repository.listBackups())
        .thenAnswer((_) async => <BackupInfo>[]);

    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Sign in & Check for Backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(doneCalled, isTrue);
    verifyNever(() => repository.restoreBackup(any()));
  });

  testWidgets('shows an error with a retry option when sign-in fails', (
    tester,
  ) async {
    when(() => repository.isSignedIn()).thenAnswer((_) async => false);
    when(() => repository.signIn()).thenThrow(Exception('cancelled'));

    await tester.pumpWidget(buildScreen());

    await tester.tap(find.text('Sign in & Check for Backup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(doneCalled, isFalse);
  });
}
