import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/ledger.dart';
import '../../core/widgets/sliding_segmented_control.dart';
import '../../data/models/library_model.dart';
import 'explore_providers.dart';
import 'splits_view.dart';
import 'widgets/body_figure.dart';
import 'widgets/exercise_detail.dart';

enum _ExploreTab { muscles, splits }

/// Browse muscles and the best exercises for each part of them, or pick a
/// complete gym or home training split.
class ExploreScreen extends ConsumerStatefulWidget {
  /// Opens on the splits list instead of the muscle library.
  final bool startOnSplits;
  const ExploreScreen({super.key, this.startOnSplits = false});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late _ExploreTab _tab = widget.startOnSplits
      ? _ExploreTab.splits
      : _ExploreTab.muscles;

  @override
  void didUpdateWidget(ExploreScreen old) {
    super.didUpdateWidget(old);
    if (widget.startOnSplits && !old.startOnSplits) {
      _tab = _ExploreTab.splits;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DayAppBar(title: 'Explore'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _tab.index.toDouble()),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              builder: (context, position, _) => SlidingSegmentedControl(
                labels: const ['Muscles', 'Splits'],
                position: position,
                onSelected: (i) => setState(() => _tab = _ExploreTab.values[i]),
              ),
            ),
          ),
          Expanded(
            child: _tab == _ExploreTab.muscles
                ? const MuscleLibraryView()
                : const SplitsView(),
          ),
        ],
      ),
    );
  }
}

/// The gym / home switch shared by the muscle library and the splits list.
class SettingToggle extends ConsumerWidget {
  const SettingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(exploreSettingProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: setting.index.toDouble()),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          builder: (context, position, _) => SlidingSegmentedControl(
            labels: [for (final s in TrainSetting.values) s.label],
            position: position,
            onSelected: (i) {
              HapticFeedback.selectionClick();
              ref.read(exploreSettingProvider.notifier).state =
                  TrainSetting.values[i];
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          setting == TrainSetting.gym
              ? 'Barbells, cables and machines, plus dumbbells.'
              : 'Bodyweight, dumbbells, resistance bands and a pull-up bar. '
                    'A bench or sturdy chair helps.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.colors.textMuted),
        ),
      ],
    );
  }
}

class MuscleLibraryView extends ConsumerStatefulWidget {
  const MuscleLibraryView({super.key});

  @override
  ConsumerState<MuscleLibraryView> createState() => _MuscleLibraryViewState();
}

class _MuscleLibraryViewState extends ConsumerState<MuscleLibraryView> {
  final _search = TextEditingController();
  String? _forcedView;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _selectMuscle(LibraryModel library, String id) {
    HapticFeedback.selectionClick();
    ref.read(exploreMuscleProvider.notifier).state = id;
    ref.read(exploreRegionProvider.notifier).state = null;
    setState(() => _forcedView = null);
  }

  void _selectRegion(String muscleId, String? regionId) {
    HapticFeedback.selectionClick();
    ref.read(exploreRegionProvider.notifier).state = regionId;
    // Flip the figure to the side where this part is visible.
    setState(() => _forcedView = null);
  }

  String _viewFor(MuscleGroup muscle, String? regionId) {
    if (_forcedView != null) return _forcedView!;
    final view = BodyFigure.viewFor(muscle.id, regionId);
    if (view != null) return view;
    return muscle.view == 'back' ? 'back' : 'front';
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryProvider);
    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) =>
          Center(child: Text('Could not load the library: $err')),
      data: (library) => _body(context, library),
    );
  }

  Widget _body(BuildContext context, LibraryModel library) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final setting = ref.watch(exploreSettingProvider);
    final muscleId = ref.watch(exploreMuscleProvider);
    final regionId = ref.watch(exploreRegionProvider);
    final muscle = library.muscle(muscleId) ?? library.muscles.first;
    final region = muscle.region(regionId);
    final view = _viewFor(muscle, regionId);
    final query = _search.text.trim();

    final picks = region?.picks(setting) ?? muscle.overview(setting);
    final empty = picks.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        TextField(
          key: const Key('exerciseSearch'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search ${library.exercises.length} exercises',
            prefixIcon: const Icon(LucideIcons600.search, size: 18),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(LucideIcons600.x, size: 18),
                    onPressed: () => setState(_search.clear),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (query.isNotEmpty)
          ..._searchResults(library, query)
        else ...[
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: library.muscles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = library.muscles[i];
                final selected = m.id == muscle.id;
                return ChoiceChip(
                  key: ValueKey('muscle-${m.id}'),
                  label: Text(
                    m.name,
                    style: TextStyle(
                      color: selected ? colors.onPrimary : colors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => _selectMuscle(library, m.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 128,
                      child: BodyFigure(
                        muscleId: muscle.id,
                        regionId: regionId,
                        view: view,
                        onSelectMuscle: (id) => _selectMuscle(library, id),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${library.muscles.indexOf(muscle) + 1} / ${library.muscles.length}',
                            style: AppText.metricTable.copyWith(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            muscle.name,
                            key: const Key('muscleTitle'),
                            style: textTheme.headlineSmall,
                          ),
                          Text(
                            region?.latin.isNotEmpty == true
                                ? region!.latin
                                : muscle.latin,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            muscle.summary,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final side in const ['front', 'back'])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    key: ValueKey('view-$side'),
                                    label: Text(
                                      side == 'front' ? 'Front' : 'Back',
                                      style: TextStyle(
                                        color: view == side
                                            ? colors.onPrimary
                                            : colors.textPrimary,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    selected: view == side,
                                    showCheckmark: false,
                                    onSelected: (_) =>
                                        setState(() => _forcedView = side),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('region-all'),
                      label: Text(
                        'All',
                        style: TextStyle(
                          color: region == null
                              ? colors.onPrimary
                              : colors.textPrimary,
                        ),
                      ),
                      selected: region == null,
                      showCheckmark: false,
                      onSelected: (_) => _selectRegion(muscle.id, null),
                    ),
                    for (final r in muscle.regions)
                      ChoiceChip(
                        key: ValueKey('region-${r.id}'),
                        label: Text(
                          r.name,
                          style: TextStyle(
                            color: r.id == regionId
                                ? colors.onPrimary
                                : colors.textPrimary,
                          ),
                        ),
                        selected: r.id == regionId,
                        showCheckmark: false,
                        onSelected: (_) => _selectRegion(muscle.id, r.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SettingToggle(),
          const SizedBox(height: 16),
          ModuleHeader(
            'Recommended',
            subtitle:
                '${picks.length} ${picks.length == 1 ? 'pick' : 'picks'} · '
                '${setting.label.toLowerCase()} · tap one for photos and steps',
          ),
          if (region != null && region.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WhyNote(text: region.note),
          ],
          const SizedBox(height: 12),
          if (empty)
            Text(
              'No ${setting.label.toLowerCase()} picks for this part yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final entry in picks.asMap().entries)
              if (library.exercises[entry.value.exerciseId] != null)
                RecommendationCard(
                  key: ValueKey(
                    '${muscle.id}-${regionId ?? 'all'}-${setting.name}-${entry.value.exerciseId}',
                  ),
                  exercise: library.exercises[entry.value.exerciseId]!,
                  pick: entry.value,
                  starred: entry.key == 0,
                ),
          const SizedBox(height: 8),
          _SourcesCard(library: library),
        ],
      ],
    );
  }

  List<Widget> _searchResults(LibraryModel library, String query) {
    final results = library.search(query);
    final textTheme = Theme.of(context).textTheme;
    return [
      ModuleHeader(
        '${results.length} ${results.length == 1 ? 'result' : 'results'}',
        subtitle: 'for "$query"',
      ),
      const SizedBox(height: 12),
      if (results.isEmpty)
        Text(
          'Nothing matches. Try a movement, like "curl", or equipment, like "band".',
          style: textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        )
      else
        for (final e in results.take(40)) RecommendationCard(exercise: e),
    ];
  }
}

class _WhyNote extends StatelessWidget {
  final String text;
  const _WhyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons600.flaskConical,
            size: 16,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              key: const Key('regionNote'),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourcesCard extends StatelessWidget {
  final LibraryModel library;
  const _SourcesCard({required this.library});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textMuted, height: 1.4);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('sources'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'How these picks were chosen',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(library.picksCredit, style: small),
                const SizedBox(height: 8),
                Text(library.photoCredit, style: small),
                const SizedBox(height: 8),
                for (final r in library.references)
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(r.url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        r.title,
                        style: small?.copyWith(
                          color: colors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
