import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../home/home_providers.dart';
import '../nutrition/nutrition_screen.dart';
import '../../data/repositories/supplement_repository.dart';
import 'providers/backup_state.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _shoppingListEnabled = true;
  bool _loadingNutritionSettings = true;
  Future<List<SupplementItem>>? _supplements;

  @override
  void initState() {
    super.initState();
    _loadNutritionSettings();
  }

  Future<void> _loadNutritionSettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _shoppingListEnabled =
            preferences.getBool(shoppingListEnabledKey) ?? true;
        _loadingNutritionSettings = false;
      });
    }
  }

  Future<void> _toggleShoppingList(bool enabled) async {
    setState(() => _shoppingListEnabled = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(shoppingListEnabledKey, enabled);
    ref.invalidate(shoppingListEnabledProvider);
  }

  Future<void> _addSupplement(SupplementRepository repository) async {
    final nameController = TextEditingController();
    XFile? photo;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add supplement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Supplement name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Take photo',
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                      );
                      if (picked != null) setDialogState(() => photo = picked);
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Choose from gallery',
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) setDialogState(() => photo = picked);
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              if (photo != null)
                Text(
                  path.basename(photo!.path),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await repository.saveSupplement(
                  SupplementItem(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    photoPath: photo?.path,
                  ),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted)
      setState(() => _supplements = repository.getSupplements());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final period = await showDialog<Duration>(
      context: context,
      builder: (context) {
        var selected = const Duration(days: 1);
        const options = <MapEntry<String, Duration>>[
          MapEntry('Last 1 hour', Duration(hours: 1)),
          MapEntry('Last 1 day', Duration(days: 1)),
          MapEntry('Last 2 days', Duration(days: 2)),
          MapEntry('Last 1 week', Duration(days: 7)),
        ];
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Delete saved data'),
            content: DropdownButtonFormField<Duration>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Time range'),
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(option.key),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setDialogState(() => selected = value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
    if (period == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text(
          'Delete data from the last ${_periodLabel(period)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final since = DateTime.now().subtract(period);
    await ref.read(nutritionRepositoryProvider).clearUserDataSince(since);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(todayFoodPhotosProvider);
    ref.invalidate(todaySupplementStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved user data deleted')));
    }
  }

  String _backupStatusLabel(BackupOperationState state) {
    switch (state.status) {
      case BackupOperationStatus.signingIn:
        return 'Signing in to Google...';
      case BackupOperationStatus.backingUp:
        return 'Backing up...';
      case BackupOperationStatus.success:
        return 'Backup complete';
      case BackupOperationStatus.error:
        return 'Backup failed — tap to retry';
      case BackupOperationStatus.idle:
        return 'Save all your data to Google Drive';
    }
  }

  String _periodLabel(Duration duration) {
    if (duration.inHours == 1) return '1 hour';
    if (duration.inDays == 1) return '1 day';
    if (duration.inDays == 2) return '2 days';
    return '1 week';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupOperationProvider, (previous, next) {
      if (next.status == BackupOperationStatus.success &&
          previous?.status != BackupOperationStatus.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup uploaded to Google Drive')));
      } else if (next.status == BackupOperationStatus.error &&
          previous?.status != BackupOperationStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${next.errorMessage}')),
        );
      }
    });
    final backupState = ref.watch(backupOperationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: backupState.isInProgress
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              title: const Text('Back up to Google Drive'),
              subtitle: Text(_backupStatusLabel(backupState)),
              onTap: backupState.isInProgress
                  ? null
                  : () => ref.read(backupOperationProvider.notifier).backupNow(),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nutrition',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile.adaptive(
              secondary: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Weekly shopping list'),
              value: _shoppingListEnabled,
              onChanged: _loadingNutritionSettings ? null : _toggleShoppingList,
            ),
          ),
          const SizedBox(height: 8),
          ref
              .watch(supplementRepositoryProvider)
              .when(
                loading: () => const Card(
                  child: ListTile(title: Text('Loading supplements...')),
                ),
                error: (_, _) => const Card(
                  child: ListTile(title: Text('Supplements unavailable')),
                ),
                data: (repository) {
                  _supplements ??= repository.getSupplements();
                  return FutureBuilder<List<SupplementItem>>(
                    future: _supplements,
                    builder: (context, snapshot) {
                      final supplements =
                          snapshot.data ?? const <SupplementItem>[];
                      return Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.medication_outlined),
                              title: const Text('Supplements'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'Add supplement',
                                onPressed: () => _addSupplement(repository),
                              ),
                            ),
                            if (supplements.isEmpty)
                              const ListTile(
                                title: Text('No supplements added yet'),
                              ),
                            ...supplements.map(
                              (supplement) => ListTile(
                                leading: supplement.photoPath == null
                                    ? const Icon(Icons.medication_outlined)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          File(supplement.photoPath!),
                                          width: 42,
                                          height: 42,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                title: Text(supplement.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Remove supplement',
                                  onPressed: () async {
                                    await repository.deleteSupplement(
                                      supplement.id,
                                    );
                                    if (mounted)
                                      setState(
                                        () => _supplements = repository
                                            .getSupplements(),
                                      );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete saved data'),
              subtitle: const Text('Clear workout and nutrition history'),
              onTap: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }
}
