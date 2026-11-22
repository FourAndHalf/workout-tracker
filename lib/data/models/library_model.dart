/// The Explore library: muscle groups, the parts of each muscle, and the
/// exercises recommended for them at the gym or at home.
library;

enum TrainSetting {
  gym('Gym'),
  home('Home');

  final String label;
  const TrainSetting(this.label);
}

class LibraryModel {
  final String photoCredit;
  final String picksCredit;
  final List<LibraryReference> references;
  final List<MuscleGroup> muscles;
  final Map<String, LibraryExercise> exercises;

  const LibraryModel({
    required this.photoCredit,
    required this.picksCredit,
    required this.references,
    required this.muscles,
    required this.exercises,
  });

  factory LibraryModel.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>? ?? const {};
    final exercises = (json['exercises'] as Map<String, dynamic>).map(
      (id, value) => MapEntry(
        id,
        LibraryExercise.fromJson(id, value as Map<String, dynamic>),
      ),
    );
    return LibraryModel(
      photoCredit: credits['photos'] as String? ?? '',
      picksCredit: credits['picks'] as String? ?? '',
      references: [
        for (final r in json['references'] as List<dynamic>? ?? const [])
          LibraryReference(
            (r as Map<String, dynamic>)['title'] as String,
            r['url'] as String,
          ),
      ],
      muscles: [
        for (final m in json['muscles'] as List<dynamic>)
          MuscleGroup.fromJson(m as Map<String, dynamic>),
      ],
      exercises: exercises,
    );
  }

  MuscleGroup? muscle(String id) {
    for (final m in muscles) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Exercises whose name contains every word of [query].
  List<LibraryExercise> search(String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    return [
      for (final e in exercises.values)
        if (words.every(
          (w) =>
              e.name.toLowerCase().contains(w) ||
              e.equipment.toLowerCase().contains(w),
        ))
          e,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }
}

class LibraryReference {
  final String title;
  final String url;
  const LibraryReference(this.title, this.url);
}

class MuscleGroup {
  final String id;
  final String name;
  final String latin;

  /// `front`, `back` or `both`: which side of the body figure shows it.
  final String view;
  final String summary;
  final List<MuscleRegion> regions;

  const MuscleGroup({
    required this.id,
    required this.name,
    required this.latin,
    required this.view,
    required this.summary,
    required this.regions,
  });

  factory MuscleGroup.fromJson(Map<String, dynamic> json) => MuscleGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    latin: json['latin'] as String,
    view: json['view'] as String? ?? 'front',
    summary: json['summary'] as String? ?? '',
    regions: [
      for (final r in json['regions'] as List<dynamic>)
        MuscleRegion.fromJson(r as Map<String, dynamic>),
    ],
  );

  MuscleRegion? region(String? id) {
    if (id == null) return null;
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// The best picks across every part of the muscle: each part's first pick,
  /// then each part's second, and so on, without repeats.
  List<Recommendation> overview(TrainSetting setting, {int limit = 6}) {
    final lists = [for (final r in regions) r.picks(setting)];
    final seen = <String>{};
    final out = <Recommendation>[];
    for (var rank = 0; out.length < limit; rank++) {
      var any = false;
      for (final list in lists) {
        if (rank >= list.length) continue;
        any = true;
        if (seen.add(list[rank].exerciseId)) out.add(list[rank]);
        if (out.length == limit) break;
      }
      if (!any) break;
    }
    return out;
  }
}

class MuscleRegion {
  final String id;
  final String name;
  final String latin;
  final String note;
  final List<Recommendation> gym;
  final List<Recommendation> home;

  const MuscleRegion({
    required this.id,
    required this.name,
    required this.latin,
    required this.note,
    required this.gym,
    required this.home,
  });

  factory MuscleRegion.fromJson(Map<String, dynamic> json) {
    List<Recommendation> picks(String key) => [
      for (final p in json[key] as List<dynamic>? ?? const [])
        Recommendation.fromJson(p as Map<String, dynamic>),
    ];
    return MuscleRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      latin: json['latin'] as String? ?? '',
      note: json['note'] as String? ?? '',
      gym: picks('gym'),
      home: picks('home'),
    );
  }

  List<Recommendation> picks(TrainSetting setting) =>
      setting == TrainSetting.gym ? gym : home;
}

class Recommendation {
  final String exerciseId;
  final int sets;
  final String reps;

  /// True when this exercise is the main driver of the muscle part; false
  /// when it only assists.
  final bool primary;

  const Recommendation({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.primary,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
    exerciseId: json['exercise'] as String,
    sets: json['sets'] as int,
    reps: json['reps'] as String,
    primary: json['focus'] == 'primary',
  );

  String get prescription => '$sets × $reps';
}

class LibraryExercise {
  final String id;
  final String name;
  final String equipment;
  final String level;
  final String mechanic;

  /// Muscle-group ids it mainly trains / helps train.
  final List<String> primary;
  final List<String> secondary;
  final String cue;
  final List<String> steps;
  final List<String> images;

  /// Held for time (planks) rather than counted in reps.
  final bool timed;

  const LibraryExercise({
    required this.id,
    required this.name,
    required this.equipment,
    required this.level,
    required this.mechanic,
    required this.primary,
    required this.secondary,
    required this.cue,
    required this.steps,
    required this.images,
    required this.timed,
  });

  factory LibraryExercise.fromJson(String id, Map<String, dynamic> json) {
    List<String> strings(String key) => [
      for (final v in json[key] as List<dynamic>? ?? const []) v.toString(),
    ];
    return LibraryExercise(
      id: id,
      name: json['name'] as String,
      equipment: json['equipment'] as String? ?? '',
      level: json['level'] as String? ?? '',
      mechanic: json['mechanic'] as String? ?? '',
      primary: strings('primary'),
      secondary: strings('secondary'),
      cue: json['cue'] as String? ?? '',
      steps: strings('steps'),
      images: strings('images'),
      timed: json['timed'] as bool? ?? false,
    );
  }

  List<String> get imageAssets => [
    for (final file in images) 'assets/library/img/$file',
  ];

  Uri get videoUri => Uri.https('www.youtube.com', '/results', {
    'search_query': '$name exercise form',
  });
}
