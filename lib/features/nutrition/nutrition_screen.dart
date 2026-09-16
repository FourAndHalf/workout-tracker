import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../main.dart';

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
  var plans = await repository.getMealPlans();
  if (plans.isEmpty) {
    await repository.addMealPlan(
      dayOfWeek: 1,
      mealName: 'Chicken quinoa bowl',
      ingredients:
          'Chicken breast, quinoa, spinach, tomato, avocado, olive oil',
      calories: 620,
      proteinG: 48,
      carbsG: 55,
      fatG: 22,
      videoUrl: 'https://www.youtube.com/results?search_query=chicken+quinoa+bowl+recipe+shorts',
    );
    plans = await repository.getMealPlans();
  }
  return plans;
});

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

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
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Meal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Add a label to find this photo later'),
            ),
            ...['Breakfast', 'Lunch', 'Dinner', 'Snack'].map(
              (label) => ListTile(
                leading: const Icon(Icons.restaurant_outlined),
                title: Text(label),
                onTap: () => Navigator.pop(context, label),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Skip label'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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
    final supplements = ref.watch(todaySupplementStatusProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nutrition'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily log'),
              Tab(text: 'Meal plan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(todayFoodPhotosProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Capture meals as you go',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoActionTile(
                          icon: Icons.camera_alt_outlined,
                          label: 'Take photo',
                          onTap: () => _choosePhoto(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PhotoActionTile(
                          icon: Icons.photo_library_outlined,
                          label: 'Choose from gallery',
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
                  const Text(
                    'Daily reminders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  supplements.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) =>
                        const Text('Unable to load reminders'),
                    data: (taken) => _SupplementChecklist(
                      taken: taken,
                      onChanged: (supplement, value) async {
                        await ref
                            .read(nutritionRepositoryProvider)
                            .setSupplementTaken(
                              date: DateTime.now(),
                              supplement: supplement,
                              taken: value,
                            );
                        ref.invalidate(todaySupplementStatusProvider);
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Meal photos',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  photos.when(
                    loading: () => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) =>
                        _EmptyPhotos(message: 'Unable to load photos'),
                    data: (items) => items.isEmpty
                        ? const _EmptyPhotos(message: 'No meals logged today')
                        : _PhotoGrid(photos: items),
                  ),
                ],
              ),
            ),
            const _MealPlanTab(),
          ],
        ),
      ),
    );
  }
}

class _MealPlanTab extends ConsumerWidget {
  const _MealPlanTab();

  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Future<void> _editMeal(
    BuildContext context,
    WidgetRef ref, {
    MealPlan? meal,
  }) async {
    final draft = await showDialog<_MealPlanDraft>(
      context: context,
      builder: (_) => _MealPlanEditor(meal: meal),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(mealPlansProvider);
    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Unable to load meal plan: $error')),
      data: (meals) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly meals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plan ingredients and nutrition in advance',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Add meal',
                icon: const Icon(Icons.add),
                onPressed: () => _editMeal(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...meals.map(
            (meal) => _MealPlanCard(
              meal: meal,
              dayName: dayNames[meal.dayOfWeek - 1],
              onEdit: () => _editMeal(context, ref, meal: meal),
              onDelete: () async {
                await ref
                    .read(nutritionRepositoryProvider)
                    .deleteMealPlan(meal.id);
                ref.invalidate(mealPlansProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final MealPlan meal;
  final String dayName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealPlanCard({
    required this.meal,
    required this.dayName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients = meal.ingredients
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal.mealName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
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
              ],
            ),
            Text(
              dayName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ingredients.join('  •  '),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('${meal.calories.toStringAsFixed(0)} kcal'),
                Text('P ${meal.proteinG.toStringAsFixed(0)}g'),
                Text('C ${meal.carbsG.toStringAsFixed(0)}g'),
                Text('F ${meal.fatG.toStringAsFixed(0)}g'),
              ],
            ),
            if (meal.videoUrl != null && meal.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Cooking video'),
                onPressed: () => launchUrl(
                  Uri.parse(meal.videoUrl!),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
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

  const _MealPlanEditor({this.meal});

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

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _day = meal?.dayOfWeek ?? 1;
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

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.meal == null ? 'Add meal' : 'Edit meal'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: List.generate(
              7,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(_MealPlanTab.dayNames[index]),
              ),
            ),
            onChanged: (value) => setState(() => _day = value ?? 1),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Meal name'),
          ),
          TextField(
            controller: _ingredients,
            decoration: const InputDecoration(
              labelText: 'Ingredients (comma separated)',
            ),
            maxLines: 2,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'kcal'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein g'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _carbs,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs g'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fat g'),
                ),
              ),
            ],
          ),
          TextField(
            controller: _video,
            decoration: const InputDecoration(
              labelText: 'Cooking video URL (optional)',
            ),
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
  final VoidCallback onTap;

  const _PhotoActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
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
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: AppColors.card,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
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
                      fontWeight: FontWeight.bold,
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

class _SupplementChecklist extends StatelessWidget {
  static const supplements = ['Protein powder', 'Cod liver oil capsule'];

  final Set<String> taken;
  final Future<void> Function(String supplement, bool value) onChanged;

  const _SupplementChecklist({required this.taken, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: supplements
          .map(
            (supplement) => Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: taken.contains(supplement),
                onChanged: (value) {
                  if (value != null) onChanged(supplement, value);
                },
                title: Text(supplement),
                subtitle: Text(
                  taken.contains(supplement) ? 'Taken today' : 'Not logged yet',
                ),
                secondary: Icon(
                  supplement == 'Protein powder'
                      ? Icons.local_drink_outlined
                      : Icons.medication_outlined,
                  color: AppColors.primary,
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _EmptyPhotos extends StatelessWidget {
  final String message;

  const _EmptyPhotos({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}
