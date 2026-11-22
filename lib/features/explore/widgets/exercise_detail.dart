import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/library_model.dart';
import '../explore_providers.dart';
import 'explore_style.dart';

/// Photos, the form cue, numbered steps and the muscles an exercise trains:
/// everything a lifter needs before the first rep.
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
    final tokens = ExploreTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final library = ref.watch(libraryProvider).value;
    String label(String id) => library?.muscle(id)?.name ?? id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (exercise.cue.isNotEmpty)
          Text(
            exercise.cue,
            key: const Key('exerciseCue'),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        if (exercise.imageAssets.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PhotoViewer(exercise: exercise),
        ],
        if (exercise.steps.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final entry in exercise.steps.asMap().entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${entry.key + 1}.',
                      style: AppText.metricTable.copyWith(
                        fontSize: 13,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (exercise.primary.isNotEmpty || exercise.secondary.isNotEmpty) ...[
          const SizedBox(height: 12),
          const MicroLabel('Works', size: 10),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in exercise.primary)
                _MuscleTag(label(id), strong: true),
              for (final id in exercise.secondary) _MuscleTag(label(id)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('watchFormVideos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              backgroundColor: tokens.accentContainer,
              side: BorderSide(color: tokens.accent.withValues(alpha: 0.6)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: Icon(
              LucideIcons600.squarePlay,
              size: 18,
              color: tokens.accent,
            ),
            label: const Text('Watch form videos'),
            onPressed: () => _openVideos(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Photos and steps: free-exercise-db, public domain',
          style: textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MuscleTag extends StatelessWidget {
  final String label;
  final bool strong;
  const _MuscleTag(this.label, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = ExploreTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: strong ? tokens.accentContainer : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: strong ? colors.textPrimary : colors.textSecondary,
        ),
      ),
    );
  }
}

/// The start and finish photos; tap to flip between them.
class _PhotoViewer extends StatefulWidget {
  final LibraryExercise exercise;
  const _PhotoViewer({required this.exercise});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final images = widget.exercise.imageAssets;
    final labels = const ['Start', 'Finish'];
    return GestureDetector(
      onTap: images.length < 2
          ? null
          : () => setState(() => _index = (_index + 1) % images.length),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Image.asset(
                  images[_index],
                  key: ValueKey(images[_index]),
                  fit: BoxFit.cover,
                  semanticLabel:
                      '${widget.exercise.name}, ${labels[_index].toLowerCase()} position',
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: colors.surface,
                    child: Icon(LucideIcons600.image, color: colors.textMuted),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Row(
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: i == _index ? 0.72 : 0.35,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: MicroLabel(
                          labels[i],
                          size: 10,
                          color: Colors.white.withValues(
                            alpha: i == _index ? 1 : 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          MicroLabel('${exercise.equipment} · ${exercise.level}'),
          const SizedBox(height: 6),
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          ExerciseDetailBody(exercise: exercise),
        ],
      ),
    ),
  );
}

/// One recommended exercise: a thumbnail, the name, equipment, prescription
/// and how directly it trains the muscle, with photos and steps behind a tap.
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
    final tokens = ExploreTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final pick = widget.pick;
    final exercise = widget.exercise;
    final accentBorder = widget.starred || _open;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: _open
              ? tokens.accentContainer.withValues(alpha: 0.5)
              : colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: accentBorder
                ? tokens.accent.withValues(alpha: _open ? 0.55 : 0.4)
                : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exercise.imageAssets.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        child: SizedBox(
                          width: 84,
                          height: 64,
                          child: Image.asset(
                            exercise.imageAssets.first,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) =>
                                ColoredBox(color: colors.surface),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          if (widget.starred) ...[
                            const SizedBox(height: 6),
                            const OutlinePill('Top pick'),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  exercise.equipment,
                                  style: textTheme.bodySmall,
                                ),
                              ),
                              if (pick != null)
                                Text(
                                  pick.prescription,
                                  style: AppText.metricTable.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          if (pick != null) ...[
                            const SizedBox(height: 10),
                            FocusMeter(primary: pick.primary),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        LucideIcons600.chevronDown,
                        size: 20,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ExerciseDetailBody(exercise: exercise),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
