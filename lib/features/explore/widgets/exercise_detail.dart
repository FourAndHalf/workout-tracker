import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/tag_pill.dart';
import '../../../data/models/library_model.dart';
import '../explore_providers.dart';

/// Photos, the one-line cue, numbered steps and the muscles an exercise
/// trains: everything a lifter needs before the first rep.
class ExerciseDetailBody extends ConsumerWidget {
  final LibraryExercise exercise;
  const ExerciseDetailBody({super.key, required this.exercise});

  Future<void> _openVideos(BuildContext context) async {
    final opened = await launchUrl(
      exercise.videoUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open YouTube.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final library = ref.watch(libraryProvider).value;
    String label(String id) => library?.muscle(id)?.name ?? id;
    final images = exercise.imageAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < images.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.asset(
                            images[i],
                            fit: BoxFit.cover,
                            semanticLabel:
                                '${exercise.name}, ${i == 0 ? 'start' : 'finish'} position',
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: colors.surface,
                              child: Icon(
                                LucideIcons600.image,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i == 0 ? 'START' : 'FINISH',
                        style: AppText.labelUppercase.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        if (exercise.cue.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.infoContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons600.lightbulb, size: 16, color: colors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.cue,
                    key: const Key('exerciseCue'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (exercise.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final entry in exercise.steps.asMap().entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${entry.key + 1}.',
                      style: AppText.metricTable.copyWith(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (exercise.primary.isNotEmpty || exercise.secondary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in exercise.primary)
                TagPill(label(id), color: colors.primary),
              for (final id in exercise.secondary)
                TagPill(label(id), color: colors.textMuted),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Dark: main muscles · grey: assisting',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('watchFormVideos'),
            icon: const Icon(LucideIcons600.playCircle, size: 18),
            label: const Text('Watch form videos'),
            onPressed: () => _openVideos(context),
          ),
        ),
      ],
    );
  }
}

/// Opens [exerciseId] from the library in a bottom sheet. Does nothing when
/// the exercise is not in the library.
Future<void> showExerciseDetailSheet(
  BuildContext context,
  String exerciseId,
) async {
  final library = await ProviderScope.containerOf(context)
      .read(libraryProvider.future);
  final exercise = library.exercises[exerciseId];
  if (exercise == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${exercise.equipment} · ${_titleCase(exercise.level)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          ExerciseDetailBody(exercise: exercise),
        ],
      ),
    ),
  );
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// One recommended exercise in the muscle library: the name, equipment and
/// prescription up front, with the photos and steps behind a tap.
class RecommendationCard extends StatefulWidget {
  final LibraryExercise exercise;

  /// Null when the card shows a search result rather than a pick.
  final Recommendation? pick;
  final bool starred;
  final bool initiallyExpanded;

  const RecommendationCard({
    super.key,
    required this.exercise,
    this.pick,
    this.starred = false,
    this.initiallyExpanded = false,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pick = widget.pick;
    final exercise = widget.exercise;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(exercise.name, style: textTheme.titleMedium),
                              if (widget.starred)
                                TagPill('Start here', color: colors.success),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                exercise.equipment,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              if (pick != null)
                                Text(
                                  pick.prescription,
                                  style: AppText.metricTable.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              if (pick != null)
                                TagPill(
                                  pick.primary ? 'Primary' : 'Assists',
                                  color: pick.primary
                                      ? colors.primary
                                      : colors.textMuted,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _open
                          ? LucideIcons600.chevronUp
                          : LucideIcons600.chevronDown,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ExerciseDetailBody(exercise: exercise),
              ),
          ],
        ),
      ),
    );
  }
}
