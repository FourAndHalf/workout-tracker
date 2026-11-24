// Renders the Explore screens to PNGs for visual review, in dark and light.
//
//   flutter test tool/screens/render_screens_test.dart
//
// Images land in build/screens/. The run also fails on any layout overflow
// or exception, so it doubles as a smoke test of the real screens with real
// fonts, icons and photos. Compare the images with docs/CHANGES.md §5.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/theme/theme_mode_provider.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/library_model.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:fitness_tracker/features/explore/explore_providers.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _out = 'build/screens';

final _library = LibraryModel.fromJson(
  jsonDecode(File('assets/library/library.json').readAsStringSync())
      as Map<String, dynamic>,
);

ProgramModel _program(String id) {
  final path =
      ProgramRepository.bundledProgramAssets[id] ??
      ProgramRepository.bundledSplitAssets[id] ??
      ProgramRepository.bundledProgramAssets[ProgramRepository
          .defaultProgramId]!;
  return ProgramModel.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

/// Root folder of a package from .dart_tool/package_config.json.
String? _packageRoot(String name) {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
  for (final p in json['packages'] as List<dynamic>) {
    if (p['name'] == name) {
      final uri = Uri.parse(p['rootUri'] as String);
      return uri.isAbsolute
          ? uri.toFilePath()
          : File('.dart_tool/${uri.path}').absolute.path;
    }
  }
  return null;
}

Future<void> _font(String family, List<String> paths) async {
  final files = paths.map(File.new).where((f) => f.existsSync()).toList();
  if (files.isEmpty) return;
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  // flutter_tester lives in <flutter>/bin/cache/artifacts/engine/<arch>/.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
  await _font('Roboto', ['$artifacts/material_fonts/Roboto-Regular.ttf']);
  await _font('MaterialIcons', [
    '$artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
  await _font('JetBrains Mono', [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-SemiBold.ttf',
  ]);
  final lucide = _packageRoot('lucide_icons_flutter');
  if (lucide != null) {
    for (final w in ['400', '600']) {
      await _font('packages/lucide_icons_flutter/Lucide$w', [
        '$lucide/assets/build_font/LucideVariable-w$w.ttf',
      ]);
    }
  }
}

void main() {
  setUp(() => appRouter.go('/'));

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('Explore screens render cleanly in ${mode.name} mode', (
      tester,
    ) async {
      // This file is a test that lives in tool/ so it stays out of the suite.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(_loadFonts);
      Directory(_out).createSync(recursive: true);
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final boundary = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              initialThemeModeProvider.overrideWithValue(mode),
              libraryProvider.overrideWith((ref) async => _library),
              exploreSplitsProvider.overrideWith(
                (ref) async => [
                  for (final id in ProgramRepository.bundledSplitAssets.keys)
                    _program(id),
                ],
              ),
              availableProgramsProvider.overrideWith(
                (ref) async => [
                  for (final id in ProgramRepository.bundledProgramAssets.keys)
                    _program(id),
                ],
              ),
              currentProgramProvider.overrideWith(
                (ref) async => _program(ref.watch(selectedProgramIdProvider)),
              ),
            ],
            child: const FitnessTrackerApp(),
          ),
        ),
      );

      Future<void> settle() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        // Give Image.asset a moment to decode the real photos.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
      }

      Future<void> shot(String name) async {
        await settle();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/${mode.name}_$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await settle();
      }

      await settle();
      await tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Explore'),
        ),
      );
      await tap(find.byKey(const ValueKey('muscle-shoulders')));
      await tap(find.byKey(const ValueKey('region-side-delts')));
      await shot('1_shoulders');

      await tap(find.byKey(const ValueKey('muscle-glutes')));
      await shot('2_glutes_back');

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -560));
      await settle();
      await tap(find.text(_library.exercises['Barbell_Hip_Thrust']!.name));
      await shot('3_card_open');

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tap(find.text('Splits'));
      await shot('4_splits');

      await tap(find.byKey(const ValueKey('split-split-gym-ul-4')));
      await shot('5_split_detail');
      await tap(find.text('Upper A'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await shot('6_split_volume');

      expect(Directory(_out).listSync().length, greaterThanOrEqualTo(6));
    });
  }
}
