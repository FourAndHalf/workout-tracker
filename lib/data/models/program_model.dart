/// Hard sets per week for one muscle group in a training split.
class WeeklySets {
  /// Sets where the muscle is the main driver.
  final int direct;

  /// Sets where it only assists (pressing for triceps, rows for biceps).
  final int indirect;

  /// Hard-set equivalent: direct plus a share of the indirect sets.
  final double effective;

  const WeeklySets({
    required this.direct,
    required this.indirect,
    required this.effective,
  });

  factory WeeklySets.fromJson(Map<String, dynamic> json) => WeeklySets(
    direct: json['direct'] as int? ?? 0,
    indirect: json['indirect'] as int? ?? 0,
    effective: (json['effective'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'direct': direct,
    'indirect': indirect,
    'effective': effective,
  };
}

class ProgramModel {
  final int schemaVersion;
  final String programId;
  final String programName;
  final String? sourceNote;

  /// `split` for the gym/home splits browsed from Explore; null for the
  /// original tracks.
  final String? category;

  /// `gym` or `home` for splits.
  final String? setting;
  final String? level;
  final int? daysPerWeek;
  final String? schedule;
  final String? description;

  /// Weekly hard sets per muscle-group id, for splits.
  final Map<String, WeeklySets> weeklySets;
  final Map<String, String>? logModes;
  final Map<String, String>? blockTypes;
  final List<WeekModel> weeks;
  final BonusDayModel? bonusDay;
  final List<String> openItems;

  ProgramModel({
    required this.schemaVersion,
    required this.programId,
    required this.programName,
    this.sourceNote,
    this.category,
    this.setting,
    this.level,
    this.daysPerWeek,
    this.schedule,
    this.description,
    this.weeklySets = const {},
    this.logModes,
    this.blockTypes,
    required this.weeks,
    this.bonusDay,
    this.openItems = const [],
  });

  bool get isSplit => category == 'split';

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      sourceNote: json['sourceNote'] as String?,
      category: json['category'] as String?,
      setting: json['setting'] as String?,
      level: json['level'] as String?,
      daysPerWeek: json['daysPerWeek'] as int?,
      schedule: json['schedule'] as String?,
      description: json['description'] as String?,
      weeklySets:
          (json['weeklySets'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, WeeklySets.fromJson(v as Map<String, dynamic>)),
          ) ??
          const {},
      logModes: (json['logModes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      blockTypes: (json['blockTypes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      weeks:
          (json['weeks'] as List<dynamic>?)
              ?.map((w) => WeekModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      bonusDay: json['bonusDay'] == null
          ? null
          : BonusDayModel.fromJson(json['bonusDay'] as Map<String, dynamic>),
      openItems:
          (json['openItems'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'programId': programId,
      'programName': programName,
      'sourceNote': sourceNote,
      'category': category,
      'setting': setting,
      'level': level,
      'daysPerWeek': daysPerWeek,
      'schedule': schedule,
      'description': description,
      'weeklySets': weeklySets.map((k, v) => MapEntry(k, v.toJson())),
      'logModes': logModes,
      'blockTypes': blockTypes,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'bonusDay': bonusDay?.toJson(),
      'openItems': openItems,
    };
  }
}

class BonusDayModel {
  final String id;
  final String title;
  final DayModel day;

  const BonusDayModel({
    required this.id,
    required this.title,
    required this.day,
  });

  factory BonusDayModel.fromJson(Map<String, dynamic> json) {
    return BonusDayModel(
      id: json['id'] as String,
      title: json['title'] as String,
      day: DayModel.fromJson(json['day'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'day': day.toJson(),
  };
}

class WeekModel {
  final int number;
  final String id;
  final String title;

  /// What the week is for, shown under the week title.
  final String? focus;
  final String? instructions;
  final List<DayModel> days;

  WeekModel({
    required this.number,
    required this.id,
    required this.title,
    this.focus,
    this.instructions,
    required this.days,
  });

  /// Days with work to do; rest days are never started or logged.
  List<DayModel> get trainingDays =>
      days.where((day) => !day.isRestDay).toList();

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      number: json['number'] as int,
      id: json['id'] as String,
      title: json['title'] as String,
      focus: json['focus'] as String?,
      instructions: json['instructions'] as String?,
      days:
          (json['days'] as List<dynamic>?)
              ?.map((d) => DayModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'id': id,
      'title': title,
      'focus': focus,
      'instructions': instructions,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}

class DayModel {
  final String id;
  final String name;
  final int order;

  /// Session category from the track file (strength, endurance, rest, ...).
  final String? type;
  final String? instructions;

  /// Authored session length; preferred over the per-set estimate.
  final int? estimatedDurationSeconds;

  /// Muscle-group ids the session mainly trains (splits only).
  final List<String> muscles;
  final bool? needsReview;
  final String? reviewNote;
  final List<BlockModel> blocks;

  DayModel({
    required this.id,
    required this.name,
    required this.order,
    this.type,
    this.instructions,
    this.estimatedDurationSeconds,
    this.muscles = const [],
    this.needsReview,
    this.reviewNote,
    required this.blocks,
  });

  /// A day marked `type: "rest"` in the track file. It has nothing to log
  /// and never blocks week progression.
  bool get isRestDay => type == 'rest';

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      type: json['type'] as String?,
      instructions: json['instructions'] as String?,
      estimatedDurationSeconds: json['estimatedDurationSeconds'] as int?,
      muscles:
          (json['muscles'] as List<dynamic>?)
              ?.map((m) => m.toString())
              .toList() ??
          const [],
      needsReview: json['needsReview'] as bool?,
      reviewNote: json['reviewNote'] as String?,
      blocks:
          (json['blocks'] as List<dynamic>?)
              ?.map((b) => BlockModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'type': type,
      'instructions': instructions,
      'estimatedDurationSeconds': estimatedDurationSeconds,
      'muscles': muscles,
      'needsReview': needsReview,
      'reviewNote': reviewNote,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }
}

class BlockModel {
  final String id;
  final String name;
  final String type; // straight, superset, triSet, giantSet, dropSet, restPause
  final int targetSets;
  final String? instructions;
  final int? dropsPerSet;

  /// Rest after each set (or round) in this block; 0 means move straight on.
  /// Null falls back to [defaultRestSeconds].
  final int? restSeconds;
  final bool? needsReview;
  final String? reviewNote;
  final List<ExerciseModel> exercises;

  static const defaultRestSeconds = 60;

  BlockModel({
    required this.id,
    required this.name,
    required this.type,
    required this.targetSets,
    this.instructions,
    this.dropsPerSet,
    this.restSeconds,
    this.needsReview,
    this.reviewNote,
    required this.exercises,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      targetSets: json['targetSets'] as int? ?? 1,
      instructions: json['instructions'] as String?,
      dropsPerSet: json['dropsPerSet'] as int?,
      restSeconds: json['restSeconds'] as int?,
      needsReview: json['needsReview'] as bool?,
      reviewNote: json['reviewNote'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'targetSets': targetSets,
      'instructions': instructions,
      'dropsPerSet': dropsPerSet,
      'restSeconds': restSeconds,
      'needsReview': needsReview,
      'reviewNote': reviewNote,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

class ExerciseModel {
  final String id;
  final int order;
  final String name;
  final String? prescription;
  final bool prescriptionComplete;
  final int targetSets;
  final List<int?>? repScheme;
  final int? repTarget;
  final String? repUnit;
  // weightReps, repsOnly, time, distance, cumulative, failure
  final String logMode;

  /// Target distance per set for `distance` exercises (runs, intervals).
  final double? distanceMeters;

  /// How to perform the movement, shown under the prescription.
  final String? instructions;

  /// `each` when the prescription applies per side.
  final String? side;

  /// Id of the matching Explore library entry, which has photos and steps.
  final String? libraryId;
  final String? videoUrl;
  final bool? needsReview;
  final String? reviewNote;

  ExerciseModel({
    required this.id,
    required this.order,
    required this.name,
    this.prescription,
    this.prescriptionComplete = true,
    required this.targetSets,
    this.repScheme,
    this.repTarget,
    this.repUnit,
    required this.logMode,
    this.distanceMeters,
    this.instructions,
    this.side,
    this.libraryId,
    this.videoUrl,
    this.needsReview,
    this.reviewNote,
  });

  Uri get exerciseVideoUri {
    final configuredUrl = videoUrl?.trim();
    final parsedUrl = configuredUrl == null || configuredUrl.isEmpty
        ? null
        : Uri.tryParse(configuredUrl);

    return parsedUrl ??
        Uri.https('www.youtube.com', '/results', {
          'search_query': '$name exercise tutorial shorts',
        });
  }

  /// Accepts the simpler track format too: `logMode: "reps"`, a single
  /// `reps`/`targetReps` per set, and `durationSeconds` for timed holds.
  /// `distance` exercises take their target from `distanceMeters`.
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final targetSets = json['targetSets'] as int? ?? 1;
    var repScheme = json['repScheme'] is int
        ? [json['repScheme'] as int]
        : (json['repScheme'] as List<dynamic>?)?.map((r) => r as int?).toList();
    var repUnit = json['repUnit'] as String?;
    final reps = (json['targetReps'] ?? json['reps']) as int?;
    final duration = json['durationSeconds'] as int?;
    if (repScheme == null && reps != null) {
      repScheme = List.filled(targetSets, reps);
    } else if (repScheme == null && duration != null) {
      repScheme = [duration];
      repUnit ??= 'sec';
    }
    final logMode = json['logMode'] as String? ?? 'weightReps';

    return ExerciseModel(
      id: json['id'] as String,
      order: json['order'] as int,
      name: json['name'] as String,
      prescription: json['prescription'] as String?,
      prescriptionComplete: json['prescriptionComplete'] as bool? ?? true,
      targetSets: targetSets,
      repScheme: repScheme,
      repTarget: json['repTarget'] as int?,
      repUnit: repUnit,
      logMode: logMode == 'reps' ? 'repsOnly' : logMode,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      instructions: json['instructions'] as String?,
      side: json['side'] as String?,
      libraryId: json['libraryId'] as String?,
      videoUrl: json['videoUrl'] as String?,
      needsReview: json['needsReview'] as bool?,
      reviewNote: json['reviewNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'name': name,
      'prescription': prescription,
      'prescriptionComplete': prescriptionComplete,
      'targetSets': targetSets,
      'repScheme': repScheme,
      'repTarget': repTarget,
      'repUnit': repUnit,
      'logMode': logMode,
      'distanceMeters': distanceMeters,
      'instructions': instructions,
      'side': side,
      'libraryId': libraryId,
      'videoUrl': videoUrl,
      'needsReview': needsReview,
      'reviewNote': reviewNote,
    };
  }
}
