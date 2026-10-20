import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/ledger.dart';
import '../../data/repositories/backup_repository.dart';
import '../../main.dart';

enum _RestoreGateStep { intro, checking, foundBackup, restoring, error }

/// Shown once, on the very first launch of a fresh install, offering to
/// restore the most recent Google Drive backup before the normal app opens.
class RestoreGateScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const RestoreGateScreen({super.key, required this.onDone});

  @override
  ConsumerState<RestoreGateScreen> createState() => _RestoreGateScreenState();
}

class _RestoreGateScreenState extends ConsumerState<RestoreGateScreen> {
  _RestoreGateStep _step = _RestoreGateStep.intro;
  BackupInfo? _latestBackup;
  String? _errorMessage;

  Future<void> _checkForBackup() async {
    setState(() => _step = _RestoreGateStep.checking);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      if (!await repository.isSignedIn()) {
        await repository.signIn();
      }
      final backups = await repository.listBackups();
      if (backups.isEmpty) {
        await _finish();
        return;
      }
      setState(() {
        _latestBackup = backups.first;
        _step = _RestoreGateStep.foundBackup;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _step = _RestoreGateStep.error;
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _step = _RestoreGateStep.restoring);
    try {
      final repository = await ref.read(backupRepositoryProvider.future);
      await repository.restoreBackup(_latestBackup!.id);
      await _finish();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _step = _RestoreGateStep.error;
      });
    }
  }

  Future<void> _finish() async {
    final repository = await ref.read(backupRepositoryProvider.future);
    await repository.markFirstLaunchRestoreCheckComplete();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case _RestoreGateStep.intro:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconChip(Icons.cloud_download_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Restore your data?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'If you\'ve backed up your fitness data to Google Drive before, '
              'you can restore it now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _checkForBackup,
              child: const Text('Sign in & Check for Backup'),
            ),
            TextButton(
              onPressed: _finish,
              child: const Text('Skip — Start Fresh'),
            ),
          ],
        );
      case _RestoreGateStep.checking:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking Google Drive for backups...'),
          ],
        );
      case _RestoreGateStep.foundBackup:
        final backup = _latestBackup!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconChip(Icons.cloud_done_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              backup.createdAt == null
                  ? 'A backup was found on Google Drive.'
                  : 'A backup from ${shortDateLabel(backup.createdAt!)} ${backup.createdAt!.year} was found on Google Drive.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _restore,
              child: const Text('Restore this backup'),
            ),
            TextButton(
              onPressed: _finish,
              child: const Text('Skip — Start Fresh'),
            ),
          ],
        );
      case _RestoreGateStep.restoring:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring your data...'),
          ],
        );
      case _RestoreGateStep.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconChip(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              'Something went wrong: $_errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _checkForBackup,
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: _finish,
              child: const Text('Skip — Start Fresh'),
            ),
          ],
        );
    }
  }
}
