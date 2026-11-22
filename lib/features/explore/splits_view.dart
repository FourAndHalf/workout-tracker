import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ledger.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/library_model.dart';
import '../../data/models/program_model.dart';
import '../program/program_providers.dart';
import 'explore_providers.dart';
import 'explore_screen.dart' show SettingToggle;

/// Colour for a split's level pill.
Color levelColor(BuildContext context, String? level) {
  final colors = context.colors;
  switch (level) {
    case 'Beginner':
      return colors.success;
    case 'Advanced':
      return colors.warning;
    default:
      return colors.info;
  }
}

/// Gym or home training splits to browse, filtered by how many days a week
/// you can train.
class SplitsView extends ConsumerStatefulWidget {
  const SplitsView({super.key});

  @override
  ConsumerState<SplitsView> createState() => _SplitsViewState();
}

class _SplitsViewState extends ConsumerState<SplitsView> {
  /// null = any; otherwise the minimum days per week to show up to.
  int? _days;

  @override
  Widget build(BuildContext context) {
    final setting = ref.watch(exploreSettingProvider);
    final splitsAsync = ref.watch(exploreSplitsProvider);
    final selectedId = ref.watch(selectedProgramIdProvider);
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return splitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Could not load splits: $err')),
      data: (all) {
        final forSetting = [
          for (final p in all)
            if (p.setting == setting.name) p,
        ]..sort((a, b) => (a.daysPerWeek ?? 0).compareTo(b.daysPerWeek ?? 0));
        final dayOptions = {
          for (final p in forSetting) p.daysPerWeek ?? 0,
        }.toList()..sort();
        final shown = [
          for (final p in forSetting)
            if (_days == null || p.daysPerWeek == _days) p,
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SettingToggle(),
            const SizedBox(height: 16),
            ModuleHeader(
              'Training splits',
              subtitle: 'Four-week blocks you can start in one tap. Each trains every muscle about twice a week.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _dayChip(context, 'Any days', null),
                  for (final d in dayOptions) _dayChip(context, '$d days', d),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Text(
                'No splits match.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              )
            else
              for (final p in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SplitCard(
                    program: p,
                    isCurrent: p.programId == selectedId,
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _dayChip(BuildContext context, String label, int? days) {
    final colors = context.colors;
    final selected = _days == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: ValueKey('days-${days ?? 'any'}'),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onPrimary : colors.textPrimary,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _days = days),
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  final ProgramModel program;
  final bool isCurrent;
  const _SplitCard({required this.program, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final days = program.weeks.first.days;
    return AppCard(
      key: ValueKey('split-${program.programId}'),
      onTap: () => context.push('/explore/split/${program.programId}'),
      padding: const EdgeInsets.all(16),
      borderColor: isCurrent ? colors.primary : null,
      borderWidth: isCurrent ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(program.programName, style: textTheme.titleMedium),
              ),
              if (isCurrent)
                StatusBadge(
                  'Current',
                  icon: LucideIcons600.check,
                  foreground: colors.success,
                  background: colors.successContainer,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TagPill(
                program.level ?? '',
                color: levelColor(context, program.level),
              ),
              Text(
                '${program.daysPerWeek} days a week · ${program.schedule}',
                style: AppText.metricTable.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            program.description ?? '',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in days)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(d.name, style: textTheme.labelMedium),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Names a muscle-group id using the library, falling back to the id.
String muscleLabel(LibraryModel? library, String id) =>
    library?.muscle(id)?.name ?? id;
