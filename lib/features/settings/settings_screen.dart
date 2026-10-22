import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ledger.dart';
import '../../main.dart';
import '../../services/flux_widget_service.dart';
import '../home/flux_widget_providers.dart';
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

  Future<void> _editDailyBurn(int current) async {
    final controller = TextEditingController(text: '$current');
    final saved = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daily calorie burn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'kcal per day',
            helperText: 'Your maintenance burn, before workouts',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(dailyBurnPreferenceKey, saved);
    ref.invalidate(dailyBurnKcalProvider);
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
                    icon: const Icon(LucideIcons600.camera),
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
                    icon: const Icon(LucideIcons600.images),
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
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded to Google Drive')),
        );
      } else if (next.status == BackupOperationStatus.error &&
          previous?.status != BackupOperationStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${next.errorMessage}')),
        );
      }
    });
    final backupState = ref.watch(backupOperationProvider);

    final dailyBurn =
        ref.watch(dailyBurnKcalProvider).value ?? defaultDailyBurnKcal;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _SectionLabel('Appearance'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).setMode(selection.first),
            ),
          ),
          const _SectionLabel('Data'),
          _Group(
            children: [
              _SettingsRow(
                icon: LucideIcons600.cloudUpload,
                busy: backupState.isInProgress,
                title: 'Back up to Google Drive',
                subtitle: _backupStatusLabel(backupState),
                onTap: backupState.isInProgress
                    ? null
                    : () => ref
                          .read(backupOperationProvider.notifier)
                          .backupNow(),
              ),
            ],
          ),
          const _SectionLabel('Widgets'),
          _Group(
            children: [
              _SettingsRow(
                icon: LucideIcons600.flame,
                title: 'Daily calorie burn',
                subtitle: '$dailyBurn kcal · used by the Kinetic Flux widgets',
                onTap: () => _editDailyBurn(dailyBurn),
              ),
            ],
          ),
          const _SectionLabel('Nutrition'),
          _Group(
            children: [
              _SettingsRow(
                icon: LucideIcons600.shoppingCart,
                title: 'Weekly shopping list',
                onTap: _loadingNutritionSettings
                    ? null
                    : () => _toggleShoppingList(!_shoppingListEnabled),
                trailing: Switch(
                  value: _shoppingListEnabled,
                  onChanged: _loadingNutritionSettings
                      ? null
                      : _toggleShoppingList,
                ),
              ),
              ref
                  .watch(supplementRepositoryProvider)
                  .when(
                    loading: () => const _SettingsRow(
                      icon: LucideIcons600.pill,
                      title: 'Loading supplements...',
                    ),
                    error: (_, _) => const _SettingsRow(
                      icon: LucideIcons600.pill,
                      title: 'Supplements unavailable',
                    ),
                    data: (repository) {
                      _supplements ??= repository.getSupplements();
                      return FutureBuilder<List<SupplementItem>>(
                        future: _supplements,
                        builder: (context, snapshot) {
                          final supplements =
                              snapshot.data ?? const <SupplementItem>[];
                          return Column(
                            children: [
                              _SettingsRow(
                                icon: LucideIcons600.pill,
                                title: 'Supplements',
                                subtitle: supplements.isEmpty
                                    ? 'No supplements added yet'
                                    : '${supplements.length} tracked daily',
                                onTap: () => _addSupplement(repository),
                                trailing: IconButton(
                                  icon: const Icon(LucideIcons600.plus),
                                  tooltip: 'Add supplement',
                                  onPressed: () => _addSupplement(repository),
                                ),
                              ),
                              for (final supplement in supplements)
                                _SettingsRow(
                                  leading: supplement.photoPath == null
                                      ? null
                                      : ClipOval(
                                          child: Image.file(
                                            File(supplement.photoPath!),
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                  icon: LucideIcons600.pill,
                                  title: supplement.name,
                                  trailing: IconButton(
                                    icon: const Icon(LucideIcons600.x),
                                    tooltip: 'Remove supplement',
                                    onPressed: () async {
                                      await repository.deleteSupplement(
                                        supplement.id,
                                      );
                                      if (mounted) {
                                        setState(
                                          () => _supplements = repository
                                              .getSupplements(),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
            ],
          ),
          const _SectionLabel('Danger zone'),
          _Group(
            children: [
              _SettingsRow(
                icon: LucideIcons600.trash2,
                destructive: true,
                title: 'Delete saved data',
                subtitle: 'Clear workout and nutrition history',
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.colors.textSecondary),
    ),
  );
}

/// A list group: one module with hairline dividers inset past the icon.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(indent: 48, color: context.colors.divider),
          children[i],
        ],
      ],
    ),
  );
}

/// A 56px navigation row: 36px icon chip, label, optional subtitle and
/// trailing control.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool busy;
  final bool destructive;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.busy = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final tint = destructive ? colors.error : colors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              busy
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : leading ?? IconChip(icon, color: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: tint,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(LucideIcons600.chevronRight, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
