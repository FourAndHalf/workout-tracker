class ProgramModel {
  final int schemaVersion;
  final String programId;
  final String programName;
  final String? sourceNote;
  final Map<String, String>? logModes;
  final Map<String, String>? blockTypes;
  final List<WeekModel> weeks;

  ProgramModel({
    required this.schemaVersion,
    required this.programId,
    required this.programName,
    this.sourceNote,
    this.logModes,
    this.blockTypes,
    required this.weeks,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      programId: json['programId'] as String,
      programName: json['programName'] as String,
      sourceNote: json['sourceNote'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'programId': programId,
      'programName': programName,
      'sourceNote': sourceNote,
      'logModes': logModes,
      'blockTypes': blockTypes,
      'weeks': weeks.map((w) => w.toJson()).toList(),
    };
  }
}

class WeekModel {
  final int number;
  final String id;
  final String title;
  final List<DayModel> days;

  WeekModel({
    required this.number,
    required this.id,
    required this.title,
    required this.days,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      number: json['number'] as int,
      id: json['id'] as String,
      title: json['title'] as String,
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
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}

class DayModel {
  final String id;
  final String name;
  final int order;
  final bool? needsReview;
  final String? reviewNote;
  final List<BlockModel> blocks;

  DayModel({
    required this.id,
    required this.name,
    required this.order,
    this.needsReview,
    this.reviewNote,
    required this.blocks,
  });

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
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
  final bool? needsReview;
  final String? reviewNote;
  final List<ExerciseModel> exercises;

  BlockModel({
    required this.id,
    required this.name,
    required this.type,
    required this.targetSets,
    this.instructions,
    this.dropsPerSet,
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
  final List<int>? repScheme;
  final int? repTarget;
  final String? repUnit;
  final String logMode; // weightReps, repsOnly, time, cumulative, failure
  final String? videoUrl;

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
    this.videoUrl,
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

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      order: json['order'] as int,
      name: json['name'] as String,
      prescription: json['prescription'] as String?,
      prescriptionComplete: json['prescriptionComplete'] as bool? ?? true,
      targetSets: json['targetSets'] as int? ?? 1,
      repScheme: (json['repScheme'] as List<dynamic>?)
          ?.map((r) => r as int)
          .toList(),
      repTarget: json['repTarget'] as int?,
      repUnit: json['repUnit'] as String?,
      logMode: json['logMode'] as String? ?? 'weightReps',
      videoUrl: json['videoUrl'] as String?,
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
      'videoUrl': videoUrl,
    };
  }
}
