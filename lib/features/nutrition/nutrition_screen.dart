import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ledger.dart';
import '../../core/widgets/sliding_segmented_control.dart';
import '../../data/database/app_database.dart';
import '../../main.dart';
import '../../core/widgets/accent.dart';

final todayFoodPhotosProvider = FutureProvider.autoDispose<List<FoodPhoto>>((
  ref,
) {
  final repository = ref.watch(nutritionRepositoryProvider);
  final now = DateTime.now();
  return repository.getPhotosForDate(DateTime(now.year, now.month, now.day));
});

final todaySupplementStatusProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) {
  final repository = ref.watch(nutritionRepositoryProvider);
  return repository.getTakenSupplements(DateTime.now());
});

final mealPlansProvider = FutureProvider.autoDispose<List<MealPlan>>((
  ref,
) async {
  final repository = ref.watch(nutritionRepositoryProvider);
  await repository.ensureDefaultKeralaMealPlan();
  return repository.getMealPlans();
});

const shoppingListEnabledKey = 'nutrition_shopping_list_enabled';

final shoppingListEnabledProvider = FutureProvider<bool>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(shoppingListEnabledKey) ?? true;
});

/// The meal most likely being logged at [now], offered first when labelling.
String suggestedMealLabel(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return 'Breakfast';
  if (hour >= 11 && hour < 16) return 'Lunch';
  if (hour >= 18 && hour < 23) return 'Dinner';
  return 'Snack';
}

class NutritionScreen extends ConsumerStatefulWidget {
  /// Opens the camera on arrival (used by the launcher widget deep link).
  final bool autoCapture;

  const NutritionScreen({super.key, this.autoCapture = false});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoCapture) _scheduleAutoCapture();
  }

  @override
  void didUpdateWidget(NutritionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoCapture && !oldWidget.autoCapture) _scheduleAutoCapture();
  }

  void _scheduleAutoCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Clear the query so tapping the widget again re-triggers the capture.
      GoRouter.of(context).go('/nutrition');
      _choosePhoto(ImageSource.camera);
    });
  }

  Future<void> _choosePhoto(ImageSource source) async {
    if (_isSaving) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1800,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image picker: $error')),
        );
      }
      return;
    }
    if (picked == null || !mounted) return;

    final mealLabel = await _pickMealLabel();
    if (!mounted) return;

    setState(() => _isSaving = true);
    try {
      final savedPhoto = await _copyToAppStorage(picked);
      await ref
          .read(nutritionRepositoryProvider)
          .addFoodPhoto(
            filePath: savedPhoto.filePath,
            thumbnail: savedPhoto.thumbnail,
            mealLabel: mealLabel,
          );
      ref.invalidate(todayFoodPhotosProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Food photo added')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save photo: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _pickMealLabel() {
    final suggested = suggestedMealLabel(DateTime.now());
    final labels = [
      suggested,
      ...['Breakfast', 'Lunch', 'Dinner', 'Snack'].where((l) => l != suggested),
    ];
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        final textTheme = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Label this meal', style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'So you can find the photo later',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final label in labels)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: IconChip(
                      LucideIcons600.utensils,
                      color: label == suggested ? colors.textPrimary : null,
                    ),
                    title: Text(label),
                    trailing: label == suggested
                        ? StatusBadge(
                            'Suggested',
                            foreground: colors.onPrimary,
                            background: colors.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, label),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconChip(LucideIcons600.pencil),
                  title: const Text('Custom label'),
                  onTap: () async {
                    final custom = await _askCustomLabel(context);
                    if (context.mounted && custom != null) {
                      Navigator.pop(context, custom);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconChip(LucideIcons600.minusCircle),
                  title: const Text('Skip label'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _askCustomLabel(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Post-workout shake',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((value) => (value == null || value.isEmpty) ? null : value);
  }

  Future<_SavedPhoto> _copyToAppStorage(XFile picked) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDirectory = Directory(path.join(directory.path, 'food_photos'));
    await photosDirectory.create(recursive: true);

    final extension = path.extension(picked.path).isEmpty
        ? '.jpg'
        : path.extension(picked.path);
    final filename = 'meal_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File(path.join(photosDirectory.path, filename));
    final bytes = await picked.readAsBytes();
    await destination.writeAsBytes(bytes);

    final decoded = img.decodeImage(bytes);
    final thumbnail = decoded == null
        ? null
        : Uint8List.fromList(
            img.encodeJpg(img.copyResize(decoded, width: 320), quality: 78),
          );
    return _SavedPhoto(filePath: destination.path, thumbnail: thumbnail);
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(todayFoodPhotosProvider);
    final shoppingListEnabled =
        ref.watch(shoppingListEnabledProvider).value ?? true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: DayAppBar(
          title: 'Nutrition',
          actions: [
            if (shoppingListEnabled)
              RoundIconButton(
                tooltip: 'Shopping list',
                icon: LucideIcons600.shoppingCart,
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.85,
                    child: const _ShoppingListTab(),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Builder(
                builder: (context) {
                  final controller = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: controller.animation!,
                    builder: (context, _) => SlidingSegmentedControl(
                      labels: const ['Daily log', 'Meal plan'],
                      position: controller.animation!.value,
                      onSelected: controller.animateTo,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(todayFoodPhotosProvider.future),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _PhotoActionTile(
                                icon: LucideIcons600.camera,
                                label: 'Snap Meal',
                                caption: 'Use the camera',
                                primary: true,
                                onTap: () => _choosePhoto(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PhotoActionTile(
                                icon: LucideIcons600.images,
                                label: 'Upload Photo',
                                caption: 'Pick from gallery',
                                onTap: () => _choosePhoto(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                        if (_isSaving) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: 24),
                        ModuleHeader(
                          "Today's meals",
                          subtitle: '${photos.value?.length ?? 0} meals logged',
                        ),
                        const SizedBox(height: 12),
                        photos.when(
                          loading: () => const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) =>
                              _EmptyPhotos(message: 'Unable to load photos'),
                          data: (items) => items.isEmpty
                              ? const _EmptyPhotos(
                                  message: 'No meals logged today',
                                )
                              : _PhotoGrid(photos: items),
                        ),
                      ],
                    ),
                  ),
                  const _MealPlanTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingListTab extends ConsumerStatefulWidget {
  const _ShoppingListTab();

  @override
  ConsumerState<_ShoppingListTab> createState() => _ShoppingListTabState();
}

class _ShoppingListTabState extends ConsumerState<_ShoppingListTab> {
  static const _checkedKeyPrefix = 'weekly_shopping_list_checked_';
  static const _itemsKeyPrefix = 'weekly_shopping_list_items_';
  Set<String> _checkedItems = <String>{};
  List<String>? _customItems;

  String get _weekKey {
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  String get _checkedKey => '$_checkedKeyPrefix$_weekKey';
  String get _itemsKey => '$_itemsKeyPrefix$_weekKey';

  @override
  void initState() {
    super.initState();
    _loadCheckedItems();
    _loadCustomItems();
  }

  Future<void> _loadCheckedItems() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _checkedItems = preferences.getStringList(_checkedKey)?.toSet() ?? {};
    });
  }

  Future<void> _loadCustomItems() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = preferences.getStringList(_itemsKey);
    if (saved != null) setState(() => _customItems = saved);
  }

  Future<void> _saveCustomItems(List<String> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_itemsKey, items);
  }

  Future<void> _toggleItem(String item, bool checked) async {
    setState(() {
      if (checked) {
        _checkedItems.add(item);
      } else {
        _checkedItems.remove(item);
      }
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_checkedKey, _checkedItems.toList());
  }

  Future<void> _openBlinkit(String item) async {
    final uri = Uri.https('blinkit.com', '/s/', {'q': item});
    if (await launchUrl(uri, mode: LaunchMode.externalApplication) ||
        !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Unable to open Blinkit.')));
  }

  Future<void> _editItem(String current, {bool adding = false}) async {
    final controller = TextEditingController(text: adding ? '' : current);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adding ? 'Add shopping item' : 'Update shopping item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ingredient'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty || !mounted) return;
    final items = List<String>.from(_customItems ?? const [])
      ..removeWhere((item) => item == current);
    if (!items.contains(value)) items.add(value);
    items.sort();
    setState(() => _customItems = items);
    await _saveCustomItems(items);
  }

  Future<void> _removeItem(String item) async {
    final items = List<String>.from(_customItems ?? const [])
      ..removeWhere((value) => value == item);
    setState(() {
      _customItems = items;
      _checkedItems.remove(item);
    });
    await _saveCustomItems(items);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_checkedKey, _checkedItems.toList());
  }

  List<String> _shoppingItems(List<MealPlan> meals) {
    final items = <String>{};
    for (final meal in meals) {
      for (final ingredient in meal.ingredients.split(',')) {
        items.addAll(_shoppingIngredientsFor(ingredient));
      }
    }
    return items.toList()..sort();
  }

  List<String> _shoppingIngredientsFor(String value) {
    final item = value.trim().toLowerCase();
    if (item.isEmpty) return const [];
    if (item.contains('puttu') ||
        item.contains('appam') ||
        item.contains('idiyappam') ||
        item.contains('dosa')) {
      return const ['Rice flour'];
    }
    if (item.contains('chapati')) return const ['Wheat flour'];
    if (item.contains('matta rice') || item.contains('rice kanji'))
      return const ['Matta rice'];
    if (item == 'rice') return const ['Rice'];
    if (item.contains('rava') || item.contains('upma'))
      return const ['Semolina'];
    if (item.contains('chickpea')) return const ['Chickpeas'];
    if (item.contains('cherupayar') || item.contains('green gram'))
      return const ['Green gram'];
    if (item.contains('parippu') || item.contains('sambar'))
      return const ['Toor dal'];
    if (item.contains('chicken')) return const ['Chicken'];
    if (item.contains('karimeen') ||
        item.contains('meen') ||
        item.contains('fish') ||
        item.contains('sardine'))
      return const ['Fish'];
    if (item.contains('prawn')) return const ['Prawns'];
    if (item.contains('beef')) return const ['Beef'];
    if (item.contains('egg')) return const ['Eggs'];
    if (item.contains('coconut')) return const ['Coconut'];
    if (item.contains('cabbage')) return const ['Cabbage'];
    if (item.contains('carrot')) return const ['Carrots'];
    if (item.contains('beetroot')) return const ['Beetroot'];
    if (item.contains('cucumber')) return const ['Cucumber'];
    if (item.contains('banana')) return const ['Bananas'];
    if (item.contains('papaya')) return const ['Papaya'];
    if (item.contains('pineapple')) return const ['Pineapple'];
    if (item.contains('watermelon')) return const ['Watermelon'];
    if (item.contains('orange')) return const ['Oranges'];
    if (item.contains('guava')) return const ['Guava'];
    if (item.contains('apple')) return const ['Apples'];
    if (item.contains('peanuts')) return const ['Peanuts'];
    if (item.contains('cashew')) return const ['Cashews'];
    if (item.contains('almond')) return const ['Almonds'];
    if (item.contains('walnut')) return const ['Walnuts'];
    if (item.contains('pumpkin seed')) return const ['Pumpkin seeds'];
    if (item.contains('protein powder')) return const ['Protein powder'];
    if (item.contains('curd') || item.contains('buttermilk'))
      return const ['Curd'];
    if (item.contains('milk')) return const ['Milk'];
    if (item.contains('tea')) return const ['Tea'];
    if (item.contains('tapioca') || item == 'kappa') return const ['Tapioca'];
    if (item.contains('corn')) return const ['Corn'];
    if (item.contains('roasted gram')) return const ['Roasted gram'];
    if (item.contains('curry leaves')) return const ['Curry leaves'];
    if (item.contains('pickle')) return const ['Pickle'];
    if (item.contains('avial') ||
        item.contains('thoran') ||
        item.contains('olan') ||
        item.contains('kurma') ||
        item.contains('salad'))
      return const ['Mixed vegetables'];
    if (item.contains('moru')) return const ['Curd'];
    if (item.contains('cinnamon')) return const ['Cinnamon'];
    return [value.trim()];
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(mealPlansProvider);
    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Unable to load shopping list: $error')),
      data: (meals) {
        final items = _customItems ?? _shoppingItems(meals);
        final remaining = items
            .where((item) => !_checkedItems.contains(item))
            .length;
        final colors = context.colors;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ModuleHeader(
              'Shopping list',
              subtitle: 'This week’s ingredients · $remaining left',
              trailing: RoundIconButton(
                tooltip: 'Add item',
                icon: LucideIcons600.plus,
                size: 40,
                onPressed: () {
                  _customItems ??= List<String>.from(items);
                  _editItem('', adding: true);
                },
              ),
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (items.length - remaining) / items.length,
                  minHeight: 4,
                ),
              ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No ingredients this week')),
              ),
            for (final item in items)
              _ShoppingRow(
                item: item,
                checked: _checkedItems.contains(item),
                // The whole row ticks the item off; shopping is a separate,
                // explicit action.
                onToggle: () =>
                    _toggleItem(item, !_checkedItems.contains(item)),
                onBuy: () => _openBlinkit(item),
                onEdit: () {
                  _customItems ??= List<String>.from(items);
                  _editItem(item);
                },
                onRemove: () {
                  _customItems ??= List<String>.from(items);
                  _removeItem(item);
                },
              ),
          ],
        );
      },
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  final String item;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onBuy;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ShoppingRow({
    required this.item,
    required this.checked,
    required this.onToggle,
    required this.onBuy,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      key: const ValueKey('shopping-row'),
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: checked ? colors.primary : colors.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? Icon(
                      LucideIcons600.check,
                      size: 14,
                      color: colors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? colors.textMuted : colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Buy on Blinkit',
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons600.externalLink, size: 18),
              onPressed: onBuy,
            ),
            IconButton(
              tooltip: 'Edit item',
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons600.pencil, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Remove item',
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons600.x, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

const mealPlanDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class _MealPlanTab extends ConsumerStatefulWidget {
  const _MealPlanTab();

  @override
  ConsumerState<_MealPlanTab> createState() => _MealPlanTabState();
}

class _MealPlanTabState extends ConsumerState<_MealPlanTab> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
  }

  Future<void> _editMeal(
    BuildContext context,
    WidgetRef ref, {
    MealPlan? meal,
  }) async {
    final draft = await showDialog<_MealPlanDraft>(
      context: context,
      builder: (_) => _MealPlanEditor(meal: meal, initialDay: _selectedDay),
    );
    if (draft == null) return;

    final repository = ref.read(nutritionRepositoryProvider);
    if (meal == null) {
      await repository.addMealPlan(
        dayOfWeek: draft.dayOfWeek,
        mealName: draft.mealName,
        ingredients: draft.ingredients,
        calories: draft.calories,
        proteinG: draft.proteinG,
        carbsG: draft.carbsG,
        fatG: draft.fatG,
        videoUrl: draft.videoUrl,
      );
    } else {
      await repository.updateMealPlan(
        id: meal.id,
        dayOfWeek: draft.dayOfWeek,
        mealName: draft.mealName,
        ingredients: draft.ingredients,
        calories: draft.calories,
        proteinG: draft.proteinG,
        carbsG: draft.carbsG,
        fatG: draft.fatG,
        videoUrl: draft.videoUrl,
      );
    }
    ref.invalidate(mealPlansProvider);
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(mealPlansProvider);
    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Unable to load meal plan: $error')),
      data: (meals) {
        final dayMeals = meals
            .where((meal) => meal.dayOfWeek == _selectedDay)
            .toList();
        final colors = context.colors;
        double sum(double Function(MealPlan) f) =>
            dayMeals.fold(0, (total, meal) => total + f(meal));
        final protein = sum((m) => m.proteinG);
        final carbs = sum((m) => m.carbsG);
        final fat = sum((m) => m.fatG);
        final macroTotal = protein + carbs + fat;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _WeekDayStrip(
              selected: _selectedDay,
              today: DateTime.now().weekday,
              onSelected: (day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'DAILY PLANNED TARGET',
                        style: AppText.labelUppercase.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${dayMeals.length} ${dayMeals.length == 1 ? 'meal' : 'meals'}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: sum((m) => m.calories).toStringAsFixed(0),
                      style: AppText.metricHero,
                      children: [
                        TextSpan(
                          text: ' kcal',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (macroTotal > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            _MacroSegment(protein, _macroTone(colors, 0)),
                            _MacroSegment(carbs, _macroTone(colors, 1)),
                            _MacroSegment(fat, _macroTone(colors, 2)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroStat(
                          'Protein',
                          protein,
                          _macroTone(colors, 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroStat(
                          'Carbs',
                          carbs,
                          _macroTone(colors, 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroStat('Fat', fat, _macroTone(colors, 2)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planned Meals (${mealPlanDayNames[_selectedDay - 1]})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Tap a meal to edit it',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(LucideIcons600.plus, size: 18),
                  label: const Text('Add Meal'),
                  onPressed: () => _editMeal(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dayMeals.isEmpty)
              AppCard(
                flat: true,
                color: colors.surface,
                child: Text(
                  'Nothing planned for ${mealPlanDayNames[_selectedDay - 1]} yet.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
              ),
            ...dayMeals.indexed.map(
              (entry) => _MealPlanCard(
                meal: entry.$2,
                index: entry.$1 + 1,
                dayName: mealPlanDayNames[entry.$2.dayOfWeek - 1],
                onEdit: () => _editMeal(context, ref, meal: entry.$2),
                onDelete: () async {
                  await ref
                      .read(nutritionRepositoryProvider)
                      .deleteMealPlan(entry.$2.id);
                  ref.invalidate(mealPlansProvider);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Macros are categories, not meaning: tone steps from charcoal to light.
Color _macroTone(AppColors colors, int index) =>
    Color.lerp(colors.primary, colors.track, index / 2)!;

class _WeekDayStrip extends StatelessWidget {
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final int selected;
  final int today;
  final ValueChanged<int> onSelected;

  const _WeekDayStrip({
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          for (var day = 1; day <= 7; day++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(day),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: day == selected
                        ? colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _letters[day - 1],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: day == selected
                              ? colors.onPrimary
                              : colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: day == today
                              ? (day == selected
                                    ? colors.onPrimary
                                    : colors.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroSegment extends StatelessWidget {
  final double grams;
  final Color color;

  const _MacroSegment(this.grams, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    flex: (grams * 10).round().clamp(1, 1 << 30),
    child: ColoredBox(color: color),
  );
}

class _MacroStat extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroStat(this.label, this.grams, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${grams.toStringAsFixed(0)}g', style: AppText.metricCard),
      ],
    ),
  );
}

class _MacroPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroPill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    ),
  );
}

class _MealPlanCard extends StatelessWidget {
  final MealPlan meal;
  final int index;
  final String dayName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealPlanCard({
    required this.meal,
    required this.index,
    required this.dayName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ingredients = meal.ingredients
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Meal $index \u00B7 $dayName',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (action) {
                      if (action == 'edit') {
                        onEdit();
                      }
                      if (action == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(meal.mealName, style: Theme.of(context).textTheme.titleLarge),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in ingredients)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: colors.divider, height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${meal.calories.toStringAsFixed(0)} kcal',
                  style: AppText.metricTable,
                ),
                _MacroPill(
                  'P ${meal.proteinG.toStringAsFixed(0)}g',
                  _macroTone(colors, 0),
                ),
                _MacroPill(
                  'C ${meal.carbsG.toStringAsFixed(0)}g',
                  _macroTone(colors, 1),
                ),
                _MacroPill(
                  'F ${meal.fatG.toStringAsFixed(0)}g',
                  _macroTone(colors, 2),
                ),
                if (meal.videoUrl != null && meal.videoUrl!.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(LucideIcons600.play, size: 18),
                    label: const Text('Video'),
                    onPressed: () => launchUrl(
                      Uri.parse(meal.videoUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPlanDraft {
  final int dayOfWeek;
  final String mealName;
  final String ingredients;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? videoUrl;

  const _MealPlanDraft({
    required this.dayOfWeek,
    required this.mealName,
    required this.ingredients,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.videoUrl,
  });
}

class _MealPlanEditor extends StatefulWidget {
  final MealPlan? meal;

  /// New meals default to the day being viewed.
  final int initialDay;

  const _MealPlanEditor({this.meal, this.initialDay = 1});

  @override
  State<_MealPlanEditor> createState() => _MealPlanEditorState();
}

class _MealPlanEditorState extends State<_MealPlanEditor> {
  late final TextEditingController _name;
  late final TextEditingController _ingredients;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _video;
  late int _day;
  late bool _showVideo;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _showVideo = meal?.videoUrl?.isNotEmpty ?? false;
    _day = meal?.dayOfWeek ?? widget.initialDay;
    _name = TextEditingController(text: meal?.mealName ?? '');
    _ingredients = TextEditingController(text: meal?.ingredients ?? '');
    _calories = TextEditingController(text: meal?.calories.toString() ?? '');
    _protein = TextEditingController(text: meal?.proteinG.toString() ?? '');
    _carbs = TextEditingController(text: meal?.carbsG.toString() ?? '');
    _fat = TextEditingController(text: meal?.fatG.toString() ?? '');
    _video = TextEditingController(text: meal?.videoUrl ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _ingredients,
      _calories,
      _protein,
      _carbs,
      _fat,
      _video,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final ingredients = _ingredients.text.trim();
    final calories = double.tryParse(_calories.text);
    final protein = double.tryParse(_protein.text);
    final carbs = double.tryParse(_carbs.text);
    final fat = double.tryParse(_fat.text);
    if (name.isEmpty ||
        ingredients.isEmpty ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fat == null) {
      return;
    }
    Navigator.pop(
      context,
      _MealPlanDraft(
        dayOfWeek: _day,
        mealName: name,
        ingredients: ingredients,
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        videoUrl: _video.text.trim().isEmpty ? null : _video.text.trim(),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String label) =>
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.meal == null ? 'Add meal' : 'Edit meal'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Meal name'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: List.generate(
              7,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(mealPlanDayNames[index]),
              ),
            ),
            onChanged: (value) => setState(() => _day = value ?? 1),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ingredients,
            decoration: const InputDecoration(
              labelText: 'Ingredients',
              hintText: 'Comma separated',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          Text(
            'Nutrition',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _macroField(_calories, 'kcal'),
              const SizedBox(width: 6),
              _macroField(_protein, 'Protein'),
              const SizedBox(width: 6),
              _macroField(_carbs, 'Carbs'),
              const SizedBox(width: 6),
              _macroField(_fat, 'Fat'),
            ],
          ),
          const SizedBox(height: 8),
          if (_showVideo)
            TextField(
              controller: _video,
              decoration: const InputDecoration(labelText: 'Cooking video URL'),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _showVideo = true),
              icon: const Icon(LucideIcons600.plus, size: 18),
              label: const Text('Add cooking video'),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _PhotoActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final bool primary;
  final VoidCallback onTap;

  const _PhotoActionTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The camera tile is the screen's main action, so it takes the coral fill.
    final ink = primary ? colors.onAccent : colors.textPrimary;
    return AppCard(
      onTap: onTap,
      gradient: primary ? accentGradient(colors) : null,
      borderColor: primary ? Colors.transparent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary
                  ? colors.onAccent.withValues(alpha: 0.14)
                  : colors.raised,
              border: primary ? null : Border.all(color: colors.border),
            ),
            child: Icon(icon, color: ink, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: ink),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: primary
                  ? colors.onAccent.withValues(alpha: 0.8)
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPhoto {
  final String filePath;
  final Uint8List? thumbnail;

  const _SavedPhoto({required this.filePath, required this.thumbnail});
}

class _PhotoGrid extends StatelessWidget {
  final List<FoodPhoto> photos;

  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: photos.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
    ),
    itemBuilder: (context, index) {
      final photo = photos[index];
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: context.colors.card,
                child: Icon(LucideIcons600.imageOff),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xB31C1C1E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Text(
                    photo.mealLabel ?? 'Meal',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF2F2F3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _EmptyPhotos extends StatelessWidget {
  final String message;

  const _EmptyPhotos({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    height: 140,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons600.utensils,
          color: context.colors.textSecondary,
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.colors.textSecondary),
        ),
      ],
    ),
  );
}
