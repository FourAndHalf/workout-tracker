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
import '../../services/flux_widget_service.dart';
import '../program/program_providers.dart';
import '../workout/providers/active_workout_session_notifier.dart';
import 'explore_providers.dart';
import 'splits_view.dart';
import 'widgets/exercise_detail.dart';

/// One training split: what each day trains, the exercises, how many hard
/// sets each muscle gets in a week, and a button to start it.
class SplitDetailScreen extends ConsumerWidget {
  final String programId;
  const SplitDetailScreen({super.key, required this.programId});

  void _use(BuildContext context, WidgetRef ref, ProgramModel program) {
    if (ref.read(activeWorkoutSessionProvider) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish your active workout before switching.'),
        ),
      );
      return;
    }
    ref.read(selectedProgramIdProvider.notifier).select(program.programId);
    context.go('/programs');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitsAsync = ref.watch(exploreSplitsProvider);
    final library = ref.watch(libraryProvider).value;
    final selectedId = ref.watch(selectedProgramIdProvider);

    return Scaffold(
      appBar: AppBar(),
      body: splitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Could not load the split: $err')),
        data: (all) {
          final matches = all.where((p) => p.programId == programId);
          if (matches.isEmpty) {
            return const Center(child: Text('Split not found.'));
          }
          final program = matches.first;
          return _content(context, ref, program, library, selectedId);
        },
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    ProgramModel program,
    LibraryModel? library,
    String selectedId,
  ) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isCurrent = program.programId == selectedId;
    final week = program.weeks.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(program.programName, style: textTheme.headlineSmall),
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
            TagPill(program.setting ?? '', color: colors.textSecondary),
            Text(
              '${program.daysPerWeek} days a week · ${program.schedule}',
              style: AppText.metricTable.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          program.description ?? '',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          key: const Key('useSplit'),
          icon: Icon(isCurrent ? LucideIcons600.check : LucideIcons600.play),
          label: Text(isCurrent ? 'Current split' : 'Use this split'),
          onPressed: isCurrent ? null : () => _use(context, ref, program),
        ),
        const SizedBox(height: 24),
        const ModuleHeader(
          'Your week',
          subtitle: 'Tap a day to see its exercises. Tap an exercise for photos and steps.',
        ),
        const SizedBox(height: 12),
        for (final day in week.days) _DayCard(day: day, library: library),
        const SizedBox(height: 12),
        _WeeklySetsCard(program: program, library: library),
        const SizedBox(height: 16),
        _BlockCard(program: program),
      ],
    );
  }
}

class _DayCard extends ConsumerWidget {
  final DayModel day;
  final LibraryModel? library;
  const _DayCard({required this.day, required this.library});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final exercises = [for (final b in day.blocks) ...b.exercises];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('day-${day.id}'),
            tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
              ),
              child: Text('${day.order}', style: AppText.metricTable),
            ),
            title: Text(day.name, style: textTheme.titleMedium),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${exercises.length} exercises · ~${estimateWorkoutMinutes(day)} min',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  for (final m in day.muscles)
                    TagPill(muscleLabel(library, m), color: colors.primary),
                ],
              ),
            ),
            children: [
              for (final block in day.blocks) ...[
                if (block.type == 'superset')
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      'SUPERSET',
                      style: AppText.labelUppercase.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                for (final e in block.exercises)
                  InkWell(
                    key: ValueKey('ex-${e.id}'),
                    onTap: e.libraryId == null
                        ? null
                        : () => showExerciseDetailSheet(context, e.libraryId!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(e.name, style: textTheme.bodyMedium),
                          ),
                          Text(
                            e.prescription ?? '',
                            style: AppText.metricTable.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (e.libraryId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                LucideIcons600.info,
                                size: 16,
                                color: colors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hard sets per muscle per week against the 10-20 range the volume
/// research supports. The dark bar is direct sets, the light bar assisting
/// sets (pressing for triceps, rows for biceps), counted at half.
class _WeeklySetsCard extends StatelessWidget {
  final ProgramModel program;
  final LibraryModel? library;
  const _WeeklySetsCard({required this.program, required this.library});

  static const _max = 30.0;
  static const _lo = 10.0;
  static const _hi = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final order = [
      for (final m in library?.muscles ?? const <MuscleGroup>[]) m.id,
    ];
    final entries = program.weeklySets.entries.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a.key);
        final bi = order.indexOf(b.key);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
    final untrained = [
      for (final id in order)
        if (!program.weeklySets.containsKey(id) &&
            !const {'hips', 'traps', 'forearms', 'lower-back'}.contains(id))
          muscleLabel(library, id),
    ];

    return AppCard(
      key: const Key('weeklySets'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleHeader(
            'Weekly sets per muscle',
            subtitle: 'About 10 to 20 hard sets a week builds muscle well',
          ),
          const SizedBox(height: 14),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      muscleLabel(library, entry.key),
                      style: textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 14,
                      child: CustomPaint(
                        painter: _SetsBarPainter(
                          direct: entry.value.direct.toDouble(),
                          effective: entry.value.effective,
                          track: colors.surface,
                          band: colors.success.withValues(alpha: 0.16),
                          direct_: colors.primary,
                          helper: colors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _fmt(entry.value.effective),
                      textAlign: TextAlign.right,
                      style: AppText.metricTable.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'The green band is 10 to 20 sets. Light bars are assisting sets, counted at half.',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (untrained.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Not trained: ${untrained.join(', ')}.',
              key: const Key('untrained'),
              style: textTheme.bodySmall?.copyWith(color: colors.warning),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _SetsBarPainter extends CustomPainter {
  final double direct;
  final double effective;
  final Color track;
  final Color band;
  // ignore: non_constant_identifier_names
  final Color direct_;
  final Color helper;

  _SetsBarPainter({
    required this.direct,
    required this.effective,
    required this.track,
    required this.band,
    required this.direct_,
    required this.helper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double x(double v) => (v / _WeeklySetsCard._max).clamp(0, 1) * size.width;
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        x(_WeeklySetsCard._lo),
        0,
        x(_WeeklySetsCard._hi),
        size.height,
      ),
      Paint()..color = band,
    );
    if (effective > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 2, x(effective), size.height - 4),
          radius,
        ),
        Paint()..color = helper,
      );
    }
    if (direct > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 2, x(direct.clamp(0, effective)), size.height - 4),
          radius,
        ),
        Paint()..color = direct_,
      );
    }
  }

  @override
  bool shouldRepaint(_SetsBarPainter old) =>
      old.direct != direct || old.effective != effective;
}

/// The four weeks of the block and what each asks of you.
class _BlockCard extends StatelessWidget {
  final ProgramModel program;
  const _BlockCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleHeader(
            'The four-week block',
            subtitle:
                'Same exercises each week. Progress with reps, then weight.',
          ),
          const SizedBox(height: 12),
          for (final week in program.weeks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${week.number}',
                      style: AppText.metricTable.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(week.title, style: textTheme.titleSmall),
                        if (week.focus != null)
                          Text(
                            week.focus!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
