import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal/third_party_licenses.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/sliding_segmented_control.dart';
import '../../data/models/library_model.dart';
import 'explore_providers.dart';
import 'splits_view.dart';
import 'widgets/body_figure.dart';
import 'widgets/exercise_detail.dart';
import 'widgets/explore_style.dart';

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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _tab == _ExploreTab.muscles
                  ? const MuscleLibraryView(key: ValueKey('muscles'))
                  : const SplitsView(key: ValueKey('splits')),
            ),
          ),
        ],
      ),
    );
  }
}

/// The GYM | HOME switch shared by the muscle library and the splits list.
class SettingToggle extends ConsumerWidget {
  const SettingToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(exploreSettingProvider);
    return CompactToggle(
      labels: [for (final s in TrainSetting.values) s.label],
      index: setting.index,
      onChanged: (i) {
        HapticFeedback.selectionClick();
        ref.read(exploreSettingProvider.notifier).state =
            TrainSetting.values[i];
      },
    );
  }
}

/// What "home" assumes you own.
const homeEquipment =
    'Home picks use bodyweight, dumbbells, resistance bands and a pull-up bar. A bench or sturdy chair helps.';

class MuscleLibraryView extends ConsumerStatefulWidget {
  const MuscleLibraryView({super.key});

  @override
  ConsumerState<MuscleLibraryView> createState() => _MuscleLibraryViewState();
}

class _MuscleLibraryViewState extends ConsumerState<MuscleLibraryView> {
  final _search = TextEditingController();
  bool _aboutOpen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// One key per muscle chip so a selection made on the figure can scroll
  /// its chip into view.
  final _chipKeys = <String, GlobalKey>{};

  void _selectMuscle(String id) {
    HapticFeedback.selectionClick();
    ref.read(exploreMuscleProvider.notifier).state = id;
    ref.read(exploreRegionProvider.notifier).state = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chipKeys[id]?.currentContext;
      if (chip != null && chip.mounted) {
        Scrollable.ensureVisible(
          chip,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _selectRegion(String regionId) {
    HapticFeedback.selectionClick();
    ref.read(exploreRegionProvider.notifier).state = regionId;
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(libraryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Could not load the library: $err')),
          data: (library) => _body(context, library),
        );
  }

  Widget _body(BuildContext context, LibraryModel library) {
    final colors = context.colors;
    final tokens = ExploreTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final setting = ref.watch(exploreSettingProvider);
    final muscle =
        library.muscle(ref.watch(exploreMuscleProvider)) ??
        library.muscles.first;
    // A part is always selected; the first one by default.
    final region =
        muscle.region(ref.watch(exploreRegionProvider)) ?? muscle.regions.first;
    final view =
        BodyFigure.viewFor(muscle.id, region.id) ??
        (muscle.view == 'back' ? 'back' : 'front');
    final query = _search.text.trim();
    final picks = region.picks(setting);
    final index = library.muscles.indexOf(muscle) + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      children: [
        SizedBox(
          height: 46,
          child: TextField(
            key: const Key('exerciseSearch'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        ),
        const SizedBox(height: 14),
        if (query.isNotEmpty)
          ..._searchResults(library, query)
        else ...[
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final m in library.muscles)
                    Padding(
                      key: _chipKeys.putIfAbsent(m.id, GlobalKey.new),
                      padding: const EdgeInsets.only(right: 8),
                      child: AccentChip(
                        key: ValueKey('muscle-${m.id}'),
                        label: m.name,
                        selected: m.id == muscle.id,
                        onTap: () => _selectMuscle(m.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 44,
                child: BodyFigure(
                  muscleId: muscle.id,
                  regionId: region.id,
                  view: view,
                  onSelectMuscle: _selectMuscle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 56,
                child: SmoothSwap(
                  swapKey: muscle.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      MicroLabel(
                        '${index.toString().padLeft(2, '0')} / '
                        '${library.muscles.length} · ${muscle.latin}',
                        size: 10,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        muscle.name,
                        key: const Key('muscleTitle'),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final r in muscle.regions)
                        _RegionRow(
                          key: ValueKey('region-${r.id}'),
                          label: r.name,
                          side: BodyFigure.viewFor(muscle.id, r.id) ?? 'front',
                          selected: r.id == region.id,
                          onTap: () => _selectRegion(r.id),
                        ),
                      const SizedBox(height: 6),
                      Divider(color: colors.border, height: 20),
                      InkWell(
                        key: const Key('aboutToggle'),
                        onTap: () => setState(() => _aboutOpen = !_aboutOpen),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${region.latin.isEmpty ? muscle.latin : region.latin}  ${_aboutOpen ? '−' : '+'}',
                            style: AppText.metricTable.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: tokens.accentText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _aboutOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _AboutPanel(muscle: muscle, region: region),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MicroLabel(
                      '${picks.length} ${picks.length == 1 ? 'pick' : 'picks'} · ${setting.label}',
                    ),
                  ],
                ),
              ),
              const SettingToggle(),
            ],
          ),
          if (setting == TrainSetting.home) ...[
            const SizedBox(height: 10),
            Text(
              homeEquipment,
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          SmoothSwap(
            swapKey: '${muscle.id}/${region.id}/${setting.name}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (picks.isEmpty)
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
                          '${muscle.id}-${region.id}-${setting.name}-${entry.value.exerciseId}',
                        ),
                        exercise: library.exercises[entry.value.exerciseId]!,
                        pick: entry.value,
                        starred: entry.key == 0,
                      ),
              ],
            ),
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
      Text(
        '${results.length} ${results.length == 1 ? 'result' : 'results'}',
        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      MicroLabel('for "$query"'),
      const SizedBox(height: 16),
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

/// One part of the muscle: its name and which side of the body shows it.
class _RegionRow extends StatelessWidget {
  final String label;
  final String side;
  final bool selected;
  final VoidCallback onTap;

  const _RegionRow({
    super.key,
    required this.label,
    required this.side,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = ExploreTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? tokens.accentContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? tokens.accent.withValues(alpha: 0.7)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                MicroLabel(
                  side,
                  size: 9,
                  color: selected ? tokens.accentText : colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The muscle in a sentence and why the picks for this part were chosen.
class _AboutPanel extends StatelessWidget {
  final MuscleGroup muscle;
  final MuscleRegion region;
  const _AboutPanel({required this.muscle, required this.region});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
      height: 1.45,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroLabel(muscle.name, size: 10),
          const SizedBox(height: 6),
          Text(muscle.summary, style: body),
          if (region.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            MicroLabel('Why these picks · ${region.name}', size: 10),
            const SizedBox(height: 6),
            Text(region.note, key: const Key('regionNote'), style: body),
          ],
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
    final tokens = ExploreTokens.of(context);
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textMuted, height: 1.45);
    // Its own Material so the tile's ripple isn't hidden by a coloured
    // ancestor (Flutter asserts on this).
    return Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('sources'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: colors.textMuted,
          collapsedIconColor: colors.textMuted,
          trailing: const Icon(LucideIcons600.chevronDown, size: 18),
          title: const MicroLabel('How these picks were chosen'),
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
                  Text(anatomyCredit, style: small),
                  const SizedBox(height: 8),
                  for (final r in library.references)
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse(r.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          r.title,
                          style: small?.copyWith(
                            color: tokens.accentText,
                            decoration: TextDecoration.underline,
                            decorationColor: tokens.accentText.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
