import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
      final savedPath = await _copyToAppStorage(picked);
      await ref
          .read(nutritionRepositoryProvider)
          .addFoodPhoto(filePath: savedPath, mealLabel: mealLabel);
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

  Future<String> _copyToAppStorage(XFile picked) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDirectory = Directory(path.join(directory.path, 'food_photos'));
    await photosDirectory.create(recursive: true);

    final extension = path.extension(picked.path).isEmpty
        ? '.jpg'
        : path.extension(picked.path);
    final filename = 'meal_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File(path.join(photosDirectory.path, filename));
    await File(picked.path).copy(destination.path);
    return destination.path;
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(todayFoodPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: RefreshIndicator(
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
    );
  }
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
