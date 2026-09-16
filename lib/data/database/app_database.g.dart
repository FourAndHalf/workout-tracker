// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProgramsTable extends Programs with TableInfo<$ProgramsTable, Program> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNoteMeta = const VerificationMeta(
    'sourceNote',
  );
  @override
  late final GeneratedColumn<String> sourceNote = GeneratedColumn<String>(
    'source_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceNote,
    jsonData,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Program> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_note')) {
      context.handle(
        _sourceNoteMeta,
        sourceNote.isAcceptableOrUnknown(data['source_note']!, _sourceNoteMeta),
      );
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Program map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Program(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_note'],
      ),
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class Program extends DataClass implements Insertable<Program> {
  final String id;
  final String name;
  final String? sourceNote;
  final String jsonData;
  final DateTime createdAt;
  const Program({
    required this.id,
    required this.name,
    this.sourceNote,
    required this.jsonData,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sourceNote != null) {
      map['source_note'] = Variable<String>(sourceNote);
    }
    map['json_data'] = Variable<String>(jsonData);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      sourceNote: sourceNote == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceNote),
      jsonData: Value(jsonData),
      createdAt: Value(createdAt),
    );
  }

  factory Program.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Program(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceNote: serializer.fromJson<String?>(json['sourceNote']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sourceNote': serializer.toJson<String?>(sourceNote),
      'jsonData': serializer.toJson<String>(jsonData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Program copyWith({
    String? id,
    String? name,
    Value<String?> sourceNote = const Value.absent(),
    String? jsonData,
    DateTime? createdAt,
  }) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceNote: sourceNote.present ? sourceNote.value : this.sourceNote,
    jsonData: jsonData ?? this.jsonData,
    createdAt: createdAt ?? this.createdAt,
  );
  Program copyWithCompanion(ProgramsCompanion data) {
    return Program(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceNote: data.sourceNote.present
          ? data.sourceNote.value
          : this.sourceNote,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Program(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('jsonData: $jsonData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sourceNote, jsonData, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Program &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceNote == this.sourceNote &&
          other.jsonData == this.jsonData &&
          other.createdAt == this.createdAt);
}

class ProgramsCompanion extends UpdateCompanion<Program> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sourceNote;
  final Value<String> jsonData;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceNote = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required String name,
    this.sourceNote = const Value.absent(),
    required String jsonData,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       jsonData = Value(jsonData);
  static Insertable<Program> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceNote,
    Expression<String>? jsonData,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceNote != null) 'source_note': sourceNote,
      if (jsonData != null) 'json_data': jsonData,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? sourceNote,
    Value<String>? jsonData,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceNote: sourceNote ?? this.sourceNote,
      jsonData: jsonData ?? this.jsonData,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceNote.present) {
      map['source_note'] = Variable<String>(sourceNote.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceNote: $sourceNote, ')
          ..write('jsonData: $jsonData, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekIdMeta = const VerificationMeta('weekId');
  @override
  late final GeneratedColumn<String> weekId = GeneratedColumn<String>(
    'week_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<String> dayId = GeneratedColumn<String>(
    'day_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNameMeta = const VerificationMeta(
    'dayName',
  );
  @override
  late final GeneratedColumn<String> dayName = GeneratedColumn<String>(
    'day_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    programId,
    weekId,
    dayId,
    dayName,
    startedAt,
    finishedAt,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('week_id')) {
      context.handle(
        _weekIdMeta,
        weekId.isAcceptableOrUnknown(data['week_id']!, _weekIdMeta),
      );
    } else if (isInserting) {
      context.missing(_weekIdMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
        _dayIdMeta,
        dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('day_name')) {
      context.handle(
        _dayNameMeta,
        dayName.isAcceptableOrUnknown(data['day_name']!, _dayNameMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      )!,
      weekId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_id'],
      )!,
      dayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_id'],
      )!,
      dayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final String programId;
  final String weekId;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? notes;
  const WorkoutSession({
    required this.id,
    required this.programId,
    required this.weekId,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    this.finishedAt,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<String>(programId);
    map['week_id'] = Variable<String>(weekId);
    map['day_id'] = Variable<String>(dayId);
    map['day_name'] = Variable<String>(dayName);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      programId: Value(programId),
      weekId: Value(weekId),
      dayId: Value(dayId),
      dayName: Value(dayName),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<String>(json['programId']),
      weekId: serializer.fromJson<String>(json['weekId']),
      dayId: serializer.fromJson<String>(json['dayId']),
      dayName: serializer.fromJson<String>(json['dayName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<String>(programId),
      'weekId': serializer.toJson<String>(weekId),
      'dayId': serializer.toJson<String>(dayId),
      'dayName': serializer.toJson<String>(dayName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  WorkoutSession copyWith({
    int? id,
    String? programId,
    String? weekId,
    String? dayId,
    String? dayName,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => WorkoutSession(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    weekId: weekId ?? this.weekId,
    dayId: dayId ?? this.dayId,
    dayName: dayName ?? this.dayName,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    notes: notes.present ? notes.value : this.notes,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      weekId: data.weekId.present ? data.weekId.value : this.weekId,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      dayName: data.dayName.present ? data.dayName.value : this.dayName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('weekId: $weekId, ')
          ..write('dayId: $dayId, ')
          ..write('dayName: $dayName, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    programId,
    weekId,
    dayId,
    dayName,
    startedAt,
    finishedAt,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.weekId == this.weekId &&
          other.dayId == this.dayId &&
          other.dayName == this.dayName &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.notes == this.notes);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<String> programId;
  final Value<String> weekId;
  final Value<String> dayId;
  final Value<String> dayName;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String?> notes;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.weekId = const Value.absent(),
    this.dayId = const Value.absent(),
    this.dayName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String programId,
    required String weekId,
    required String dayId,
    required String dayName,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.notes = const Value.absent(),
  }) : programId = Value(programId),
       weekId = Value(weekId),
       dayId = Value(dayId),
       dayName = Value(dayName);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<String>? programId,
    Expression<String>? weekId,
    Expression<String>? dayId,
    Expression<String>? dayName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (weekId != null) 'week_id': weekId,
      if (dayId != null) 'day_id': dayId,
      if (dayName != null) 'day_name': dayName,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (notes != null) 'notes': notes,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? programId,
    Value<String>? weekId,
    Value<String>? dayId,
    Value<String>? dayName,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String?>? notes,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      weekId: weekId ?? this.weekId,
      dayId: dayId ?? this.dayId,
      dayName: dayName ?? this.dayName,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (weekId.present) {
      map['week_id'] = Variable<String>(weekId.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<String>(dayId.value);
    }
    if (dayName.present) {
      map['day_name'] = Variable<String>(dayName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('weekId: $weekId, ')
          ..write('dayId: $dayId, ')
          ..write('dayName: $dayName, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $ExerciseLogsTable extends ExerciseLogs
    with TableInfo<$ExerciseLogsTable, ExerciseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta(
    'exerciseName',
  );
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockTypeMeta = const VerificationMeta(
    'blockType',
  );
  @override
  late final GeneratedColumn<String> blockType = GeneratedColumn<String>(
    'block_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logModeMeta = const VerificationMeta(
    'logMode',
  );
  @override
  late final GeneratedColumn<String> logMode = GeneratedColumn<String>(
    'log_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hitFailureMeta = const VerificationMeta(
    'hitFailure',
  );
  @override
  late final GeneratedColumn<bool> hitFailure = GeneratedColumn<bool>(
    'hit_failure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hit_failure" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    blockId,
    exerciseId,
    exerciseName,
    blockType,
    logMode,
    setNumber,
    weight,
    reps,
    targetReps,
    hitFailure,
    durationSeconds,
    notes,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    } else if (isInserting) {
      context.missing(_blockIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_name')) {
      context.handle(
        _exerciseNameMeta,
        exerciseName.isAcceptableOrUnknown(
          data['exercise_name']!,
          _exerciseNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('block_type')) {
      context.handle(
        _blockTypeMeta,
        blockType.isAcceptableOrUnknown(data['block_type']!, _blockTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_blockTypeMeta);
    }
    if (data.containsKey('log_mode')) {
      context.handle(
        _logModeMeta,
        logMode.isAcceptableOrUnknown(data['log_mode']!, _logModeMeta),
      );
    } else if (isInserting) {
      context.missing(_logModeMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    if (data.containsKey('hit_failure')) {
      context.handle(
        _hitFailureMeta,
        hitFailure.isAcceptableOrUnknown(data['hit_failure']!, _hitFailureMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_name'],
      )!,
      blockType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_type'],
      )!,
      logMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_mode'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      ),
      hitFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hit_failure'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $ExerciseLogsTable createAlias(String alias) {
    return $ExerciseLogsTable(attachedDatabase, alias);
  }
}

class ExerciseLog extends DataClass implements Insertable<ExerciseLog> {
  final int id;
  final int sessionId;
  final String blockId;
  final String exerciseId;
  final String exerciseName;
  final String blockType;
  final String logMode;
  final int setNumber;
  final double? weight;
  final int? reps;
  final int? targetReps;
  final bool hitFailure;
  final int? durationSeconds;
  final String? notes;
  final DateTime loggedAt;
  const ExerciseLog({
    required this.id,
    required this.sessionId,
    required this.blockId,
    required this.exerciseId,
    required this.exerciseName,
    required this.blockType,
    required this.logMode,
    required this.setNumber,
    this.weight,
    this.reps,
    this.targetReps,
    required this.hitFailure,
    this.durationSeconds,
    this.notes,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['block_id'] = Variable<String>(blockId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['exercise_name'] = Variable<String>(exerciseName);
    map['block_type'] = Variable<String>(blockType);
    map['log_mode'] = Variable<String>(logMode);
    map['set_number'] = Variable<int>(setNumber);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<int>(targetReps);
    }
    map['hit_failure'] = Variable<bool>(hitFailure);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  ExerciseLogsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseLogsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      blockId: Value(blockId),
      exerciseId: Value(exerciseId),
      exerciseName: Value(exerciseName),
      blockType: Value(blockType),
      logMode: Value(logMode),
      setNumber: Value(setNumber),
      weight: weight == null && nullToAbsent
          ? const Value.absent()
          : Value(weight),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
      hitFailure: Value(hitFailure),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      loggedAt: Value(loggedAt),
    );
  }

  factory ExerciseLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseLog(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      blockId: serializer.fromJson<String>(json['blockId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      blockType: serializer.fromJson<String>(json['blockType']),
      logMode: serializer.fromJson<String>(json['logMode']),
      setNumber: serializer.fromJson<int>(json['setNumber']),
      weight: serializer.fromJson<double?>(json['weight']),
      reps: serializer.fromJson<int?>(json['reps']),
      targetReps: serializer.fromJson<int?>(json['targetReps']),
      hitFailure: serializer.fromJson<bool>(json['hitFailure']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      notes: serializer.fromJson<String?>(json['notes']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'blockId': serializer.toJson<String>(blockId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'blockType': serializer.toJson<String>(blockType),
      'logMode': serializer.toJson<String>(logMode),
      'setNumber': serializer.toJson<int>(setNumber),
      'weight': serializer.toJson<double?>(weight),
      'reps': serializer.toJson<int?>(reps),
      'targetReps': serializer.toJson<int?>(targetReps),
      'hitFailure': serializer.toJson<bool>(hitFailure),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'notes': serializer.toJson<String?>(notes),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  ExerciseLog copyWith({
    int? id,
    int? sessionId,
    String? blockId,
    String? exerciseId,
    String? exerciseName,
    String? blockType,
    String? logMode,
    int? setNumber,
    Value<double?> weight = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<int?> targetReps = const Value.absent(),
    bool? hitFailure,
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? loggedAt,
  }) => ExerciseLog(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    blockId: blockId ?? this.blockId,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    blockType: blockType ?? this.blockType,
    logMode: logMode ?? this.logMode,
    setNumber: setNumber ?? this.setNumber,
    weight: weight.present ? weight.value : this.weight,
    reps: reps.present ? reps.value : this.reps,
    targetReps: targetReps.present ? targetReps.value : this.targetReps,
    hitFailure: hitFailure ?? this.hitFailure,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    notes: notes.present ? notes.value : this.notes,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  ExerciseLog copyWithCompanion(ExerciseLogsCompanion data) {
    return ExerciseLog(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseName: data.exerciseName.present
          ? data.exerciseName.value
          : this.exerciseName,
      blockType: data.blockType.present ? data.blockType.value : this.blockType,
      logMode: data.logMode.present ? data.logMode.value : this.logMode,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      weight: data.weight.present ? data.weight.value : this.weight,
      reps: data.reps.present ? data.reps.value : this.reps,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
      hitFailure: data.hitFailure.present
          ? data.hitFailure.value
          : this.hitFailure,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      notes: data.notes.present ? data.notes.value : this.notes,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLog(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('blockId: $blockId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('blockType: $blockType, ')
          ..write('logMode: $logMode, ')
          ..write('setNumber: $setNumber, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('targetReps: $targetReps, ')
          ..write('hitFailure: $hitFailure, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('notes: $notes, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    blockId,
    exerciseId,
    exerciseName,
    blockType,
    logMode,
    setNumber,
    weight,
    reps,
    targetReps,
    hitFailure,
    durationSeconds,
    notes,
    loggedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseLog &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.blockId == this.blockId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.blockType == this.blockType &&
          other.logMode == this.logMode &&
          other.setNumber == this.setNumber &&
          other.weight == this.weight &&
          other.reps == this.reps &&
          other.targetReps == this.targetReps &&
          other.hitFailure == this.hitFailure &&
          other.durationSeconds == this.durationSeconds &&
          other.notes == this.notes &&
          other.loggedAt == this.loggedAt);
}

class ExerciseLogsCompanion extends UpdateCompanion<ExerciseLog> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> blockId;
  final Value<String> exerciseId;
  final Value<String> exerciseName;
  final Value<String> blockType;
  final Value<String> logMode;
  final Value<int> setNumber;
  final Value<double?> weight;
  final Value<int?> reps;
  final Value<int?> targetReps;
  final Value<bool> hitFailure;
  final Value<int?> durationSeconds;
  final Value<String?> notes;
  final Value<DateTime> loggedAt;
  const ExerciseLogsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.blockType = const Value.absent(),
    this.logMode = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.hitFailure = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  ExerciseLogsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String blockId,
    required String exerciseId,
    required String exerciseName,
    required String blockType,
    required String logMode,
    required int setNumber,
    this.weight = const Value.absent(),
    this.reps = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.hitFailure = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.notes = const Value.absent(),
    this.loggedAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       blockId = Value(blockId),
       exerciseId = Value(exerciseId),
       exerciseName = Value(exerciseName),
       blockType = Value(blockType),
       logMode = Value(logMode),
       setNumber = Value(setNumber);
  static Insertable<ExerciseLog> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? blockId,
    Expression<String>? exerciseId,
    Expression<String>? exerciseName,
    Expression<String>? blockType,
    Expression<String>? logMode,
    Expression<int>? setNumber,
    Expression<double>? weight,
    Expression<int>? reps,
    Expression<int>? targetReps,
    Expression<bool>? hitFailure,
    Expression<int>? durationSeconds,
    Expression<String>? notes,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (blockId != null) 'block_id': blockId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (blockType != null) 'block_type': blockType,
      if (logMode != null) 'log_mode': logMode,
      if (setNumber != null) 'set_number': setNumber,
      if (weight != null) 'weight': weight,
      if (reps != null) 'reps': reps,
      if (targetReps != null) 'target_reps': targetReps,
      if (hitFailure != null) 'hit_failure': hitFailure,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (notes != null) 'notes': notes,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  ExerciseLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? blockId,
    Value<String>? exerciseId,
    Value<String>? exerciseName,
    Value<String>? blockType,
    Value<String>? logMode,
    Value<int>? setNumber,
    Value<double?>? weight,
    Value<int?>? reps,
    Value<int?>? targetReps,
    Value<bool>? hitFailure,
    Value<int?>? durationSeconds,
    Value<String?>? notes,
    Value<DateTime>? loggedAt,
  }) {
    return ExerciseLogsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      blockId: blockId ?? this.blockId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      blockType: blockType ?? this.blockType,
      logMode: logMode ?? this.logMode,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      hitFailure: hitFailure ?? this.hitFailure,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (blockType.present) {
      map['block_type'] = Variable<String>(blockType.value);
    }
    if (logMode.present) {
      map['log_mode'] = Variable<String>(logMode.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (hitFailure.present) {
      map['hit_failure'] = Variable<bool>(hitFailure.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLogsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('blockId: $blockId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('blockType: $blockType, ')
          ..write('logMode: $logMode, ')
          ..write('setNumber: $setNumber, ')
          ..write('weight: $weight, ')
          ..write('reps: $reps, ')
          ..write('targetReps: $targetReps, ')
          ..write('hitFailure: $hitFailure, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('notes: $notes, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $FoodPhotosTable extends FoodPhotos
    with TableInfo<$FoodPhotosTable, FoodPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<Uint8List> thumbnail = GeneratedColumn<Uint8List>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _mealLabelMeta = const VerificationMeta(
    'mealLabel',
  );
  @override
  late final GeneratedColumn<String> mealLabel = GeneratedColumn<String>(
    'meal_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    thumbnail,
    capturedAt,
    mealLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    if (data.containsKey('meal_label')) {
      context.handle(
        _mealLabelMeta,
        mealLabel.isAcceptableOrUnknown(data['meal_label']!, _mealLabelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}thumbnail'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      mealLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_label'],
      ),
    );
  }

  @override
  $FoodPhotosTable createAlias(String alias) {
    return $FoodPhotosTable(attachedDatabase, alias);
  }
}

class FoodPhoto extends DataClass implements Insertable<FoodPhoto> {
  final int id;
  final String filePath;
  final Uint8List? thumbnail;
  final DateTime capturedAt;
  final String? mealLabel;
  const FoodPhoto({
    required this.id,
    required this.filePath,
    this.thumbnail,
    required this.capturedAt,
    this.mealLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || mealLabel != null) {
      map['meal_label'] = Variable<String>(mealLabel);
    }
    return map;
  }

  FoodPhotosCompanion toCompanion(bool nullToAbsent) {
    return FoodPhotosCompanion(
      id: Value(id),
      filePath: Value(filePath),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      capturedAt: Value(capturedAt),
      mealLabel: mealLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(mealLabel),
    );
  }

  factory FoodPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodPhoto(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      thumbnail: serializer.fromJson<Uint8List?>(json['thumbnail']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      mealLabel: serializer.fromJson<String?>(json['mealLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'thumbnail': serializer.toJson<Uint8List?>(thumbnail),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'mealLabel': serializer.toJson<String?>(mealLabel),
    };
  }

  FoodPhoto copyWith({
    int? id,
    String? filePath,
    Value<Uint8List?> thumbnail = const Value.absent(),
    DateTime? capturedAt,
    Value<String?> mealLabel = const Value.absent(),
  }) => FoodPhoto(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    capturedAt: capturedAt ?? this.capturedAt,
    mealLabel: mealLabel.present ? mealLabel.value : this.mealLabel,
  );
  FoodPhoto copyWithCompanion(FoodPhotosCompanion data) {
    return FoodPhoto(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      mealLabel: data.mealLabel.present ? data.mealLabel.value : this.mealLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodPhoto(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('mealLabel: $mealLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    $driftBlobEquality.hash(thumbnail),
    capturedAt,
    mealLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPhoto &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          $driftBlobEquality.equals(other.thumbnail, this.thumbnail) &&
          other.capturedAt == this.capturedAt &&
          other.mealLabel == this.mealLabel);
}

class FoodPhotosCompanion extends UpdateCompanion<FoodPhoto> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<Uint8List?> thumbnail;
  final Value<DateTime> capturedAt;
  final Value<String?> mealLabel;
  const FoodPhotosCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.mealLabel = const Value.absent(),
  });
  FoodPhotosCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    this.thumbnail = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.mealLabel = const Value.absent(),
  }) : filePath = Value(filePath);
  static Insertable<FoodPhoto> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<Uint8List>? thumbnail,
    Expression<DateTime>? capturedAt,
    Expression<String>? mealLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (mealLabel != null) 'meal_label': mealLabel,
    });
  }

  FoodPhotosCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<Uint8List?>? thumbnail,
    Value<DateTime>? capturedAt,
    Value<String?>? mealLabel,
  }) {
    return FoodPhotosCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      thumbnail: thumbnail ?? this.thumbnail,
      capturedAt: capturedAt ?? this.capturedAt,
      mealLabel: mealLabel ?? this.mealLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (mealLabel.present) {
      map['meal_label'] = Variable<String>(mealLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodPhotosCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('mealLabel: $mealLabel')
          ..write(')'))
        .toString();
  }
}

class $DailyNutritionTable extends DailyNutrition
    with TableInfo<$DailyNutritionTable, DailyNutritionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNutritionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _analysisJsonMeta = const VerificationMeta(
    'analysisJson',
  );
  @override
  late final GeneratedColumn<String> analysisJson = GeneratedColumn<String>(
    'analysis_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCaloriesMeta = const VerificationMeta(
    'totalCalories',
  );
  @override
  late final GeneratedColumn<double> totalCalories = GeneratedColumn<double>(
    'total_calories',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _analyzedAtMeta = const VerificationMeta(
    'analyzedAt',
  );
  @override
  late final GeneratedColumn<DateTime> analyzedAt = GeneratedColumn<DateTime>(
    'analyzed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    analysisJson,
    totalCalories,
    proteinG,
    carbsG,
    fatG,
    analyzedAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_nutrition';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNutritionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('analysis_json')) {
      context.handle(
        _analysisJsonMeta,
        analysisJson.isAcceptableOrUnknown(
          data['analysis_json']!,
          _analysisJsonMeta,
        ),
      );
    }
    if (data.containsKey('total_calories')) {
      context.handle(
        _totalCaloriesMeta,
        totalCalories.isAcceptableOrUnknown(
          data['total_calories']!,
          _totalCaloriesMeta,
        ),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('analyzed_at')) {
      context.handle(
        _analyzedAtMeta,
        analyzedAt.isAcceptableOrUnknown(data['analyzed_at']!, _analyzedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyNutritionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNutritionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      analysisJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}analysis_json'],
      ),
      totalCalories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_calories'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      analyzedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}analyzed_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $DailyNutritionTable createAlias(String alias) {
    return $DailyNutritionTable(attachedDatabase, alias);
  }
}

class DailyNutritionData extends DataClass
    implements Insertable<DailyNutritionData> {
  final int id;
  final String date;
  final String? analysisJson;
  final double? totalCalories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final DateTime? analyzedAt;
  final String status;
  const DailyNutritionData({
    required this.id,
    required this.date,
    this.analysisJson,
    this.totalCalories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.analyzedAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || analysisJson != null) {
      map['analysis_json'] = Variable<String>(analysisJson);
    }
    if (!nullToAbsent || totalCalories != null) {
      map['total_calories'] = Variable<double>(totalCalories);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbsG != null) {
      map['carbs_g'] = Variable<double>(carbsG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || analyzedAt != null) {
      map['analyzed_at'] = Variable<DateTime>(analyzedAt);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  DailyNutritionCompanion toCompanion(bool nullToAbsent) {
    return DailyNutritionCompanion(
      id: Value(id),
      date: Value(date),
      analysisJson: analysisJson == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisJson),
      totalCalories: totalCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCalories),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbsG: carbsG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      analyzedAt: analyzedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(analyzedAt),
      status: Value(status),
    );
  }

  factory DailyNutritionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNutritionData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      analysisJson: serializer.fromJson<String?>(json['analysisJson']),
      totalCalories: serializer.fromJson<double?>(json['totalCalories']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbsG: serializer.fromJson<double?>(json['carbsG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      analyzedAt: serializer.fromJson<DateTime?>(json['analyzedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'analysisJson': serializer.toJson<String?>(analysisJson),
      'totalCalories': serializer.toJson<double?>(totalCalories),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbsG': serializer.toJson<double?>(carbsG),
      'fatG': serializer.toJson<double?>(fatG),
      'analyzedAt': serializer.toJson<DateTime?>(analyzedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  DailyNutritionData copyWith({
    int? id,
    String? date,
    Value<String?> analysisJson = const Value.absent(),
    Value<double?> totalCalories = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> carbsG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    Value<DateTime?> analyzedAt = const Value.absent(),
    String? status,
  }) => DailyNutritionData(
    id: id ?? this.id,
    date: date ?? this.date,
    analysisJson: analysisJson.present ? analysisJson.value : this.analysisJson,
    totalCalories: totalCalories.present
        ? totalCalories.value
        : this.totalCalories,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    carbsG: carbsG.present ? carbsG.value : this.carbsG,
    fatG: fatG.present ? fatG.value : this.fatG,
    analyzedAt: analyzedAt.present ? analyzedAt.value : this.analyzedAt,
    status: status ?? this.status,
  );
  DailyNutritionData copyWithCompanion(DailyNutritionCompanion data) {
    return DailyNutritionData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      analysisJson: data.analysisJson.present
          ? data.analysisJson.value
          : this.analysisJson,
      totalCalories: data.totalCalories.present
          ? data.totalCalories.value
          : this.totalCalories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      analyzedAt: data.analyzedAt.present
          ? data.analyzedAt.value
          : this.analyzedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    analysisJson,
    totalCalories,
    proteinG,
    carbsG,
    fatG,
    analyzedAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNutritionData &&
          other.id == this.id &&
          other.date == this.date &&
          other.analysisJson == this.analysisJson &&
          other.totalCalories == this.totalCalories &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.analyzedAt == this.analyzedAt &&
          other.status == this.status);
}

class DailyNutritionCompanion extends UpdateCompanion<DailyNutritionData> {
  final Value<int> id;
  final Value<String> date;
  final Value<String?> analysisJson;
  final Value<double?> totalCalories;
  final Value<double?> proteinG;
  final Value<double?> carbsG;
  final Value<double?> fatG;
  final Value<DateTime?> analyzedAt;
  final Value<String> status;
  const DailyNutritionCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.analysisJson = const Value.absent(),
    this.totalCalories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.analyzedAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  DailyNutritionCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.analysisJson = const Value.absent(),
    this.totalCalories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.analyzedAt = const Value.absent(),
    this.status = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DailyNutritionData> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? analysisJson,
    Expression<double>? totalCalories,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<DateTime>? analyzedAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (analysisJson != null) 'analysis_json': analysisJson,
      if (totalCalories != null) 'total_calories': totalCalories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (analyzedAt != null) 'analyzed_at': analyzedAt,
      if (status != null) 'status': status,
    });
  }

  DailyNutritionCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String?>? analysisJson,
    Value<double?>? totalCalories,
    Value<double?>? proteinG,
    Value<double?>? carbsG,
    Value<double?>? fatG,
    Value<DateTime?>? analyzedAt,
    Value<String>? status,
  }) {
    return DailyNutritionCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      analysisJson: analysisJson ?? this.analysisJson,
      totalCalories: totalCalories ?? this.totalCalories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (analysisJson.present) {
      map['analysis_json'] = Variable<String>(analysisJson.value);
    }
    if (totalCalories.present) {
      map['total_calories'] = Variable<double>(totalCalories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (analyzedAt.present) {
      map['analyzed_at'] = Variable<DateTime>(analyzedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('analyzedAt: $analyzedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $DailyNutritionPhotosTable extends DailyNutritionPhotos
    with TableInfo<$DailyNutritionPhotosTable, DailyNutritionPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyNutritionPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dailyNutritionIdMeta = const VerificationMeta(
    'dailyNutritionId',
  );
  @override
  late final GeneratedColumn<int> dailyNutritionId = GeneratedColumn<int>(
    'daily_nutrition_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodPhotoIdMeta = const VerificationMeta(
    'foodPhotoId',
  );
  @override
  late final GeneratedColumn<int> foodPhotoId = GeneratedColumn<int>(
    'food_photo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dailyNutritionId, foodPhotoId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_nutrition_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyNutritionPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('daily_nutrition_id')) {
      context.handle(
        _dailyNutritionIdMeta,
        dailyNutritionId.isAcceptableOrUnknown(
          data['daily_nutrition_id']!,
          _dailyNutritionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyNutritionIdMeta);
    }
    if (data.containsKey('food_photo_id')) {
      context.handle(
        _foodPhotoIdMeta,
        foodPhotoId.isAcceptableOrUnknown(
          data['food_photo_id']!,
          _foodPhotoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foodPhotoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyNutritionPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyNutritionPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyNutritionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_nutrition_id'],
      )!,
      foodPhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_photo_id'],
      )!,
    );
  }

  @override
  $DailyNutritionPhotosTable createAlias(String alias) {
    return $DailyNutritionPhotosTable(attachedDatabase, alias);
  }
}

class DailyNutritionPhoto extends DataClass
    implements Insertable<DailyNutritionPhoto> {
  final int id;
  final int dailyNutritionId;
  final int foodPhotoId;
  const DailyNutritionPhoto({
    required this.id,
    required this.dailyNutritionId,
    required this.foodPhotoId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['daily_nutrition_id'] = Variable<int>(dailyNutritionId);
    map['food_photo_id'] = Variable<int>(foodPhotoId);
    return map;
  }

  DailyNutritionPhotosCompanion toCompanion(bool nullToAbsent) {
    return DailyNutritionPhotosCompanion(
      id: Value(id),
      dailyNutritionId: Value(dailyNutritionId),
      foodPhotoId: Value(foodPhotoId),
    );
  }

  factory DailyNutritionPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyNutritionPhoto(
      id: serializer.fromJson<int>(json['id']),
      dailyNutritionId: serializer.fromJson<int>(json['dailyNutritionId']),
      foodPhotoId: serializer.fromJson<int>(json['foodPhotoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyNutritionId': serializer.toJson<int>(dailyNutritionId),
      'foodPhotoId': serializer.toJson<int>(foodPhotoId),
    };
  }

  DailyNutritionPhoto copyWith({
    int? id,
    int? dailyNutritionId,
    int? foodPhotoId,
  }) => DailyNutritionPhoto(
    id: id ?? this.id,
    dailyNutritionId: dailyNutritionId ?? this.dailyNutritionId,
    foodPhotoId: foodPhotoId ?? this.foodPhotoId,
  );
  DailyNutritionPhoto copyWithCompanion(DailyNutritionPhotosCompanion data) {
    return DailyNutritionPhoto(
      id: data.id.present ? data.id.value : this.id,
      dailyNutritionId: data.dailyNutritionId.present
          ? data.dailyNutritionId.value
          : this.dailyNutritionId,
      foodPhotoId: data.foodPhotoId.present
          ? data.foodPhotoId.value
          : this.foodPhotoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionPhoto(')
          ..write('id: $id, ')
          ..write('dailyNutritionId: $dailyNutritionId, ')
          ..write('foodPhotoId: $foodPhotoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dailyNutritionId, foodPhotoId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyNutritionPhoto &&
          other.id == this.id &&
          other.dailyNutritionId == this.dailyNutritionId &&
          other.foodPhotoId == this.foodPhotoId);
}

class DailyNutritionPhotosCompanion
    extends UpdateCompanion<DailyNutritionPhoto> {
  final Value<int> id;
  final Value<int> dailyNutritionId;
  final Value<int> foodPhotoId;
  const DailyNutritionPhotosCompanion({
    this.id = const Value.absent(),
    this.dailyNutritionId = const Value.absent(),
    this.foodPhotoId = const Value.absent(),
  });
  DailyNutritionPhotosCompanion.insert({
    this.id = const Value.absent(),
    required int dailyNutritionId,
    required int foodPhotoId,
  }) : dailyNutritionId = Value(dailyNutritionId),
       foodPhotoId = Value(foodPhotoId);
  static Insertable<DailyNutritionPhoto> custom({
    Expression<int>? id,
    Expression<int>? dailyNutritionId,
    Expression<int>? foodPhotoId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyNutritionId != null) 'daily_nutrition_id': dailyNutritionId,
      if (foodPhotoId != null) 'food_photo_id': foodPhotoId,
    });
  }

  DailyNutritionPhotosCompanion copyWith({
    Value<int>? id,
    Value<int>? dailyNutritionId,
    Value<int>? foodPhotoId,
  }) {
    return DailyNutritionPhotosCompanion(
      id: id ?? this.id,
      dailyNutritionId: dailyNutritionId ?? this.dailyNutritionId,
      foodPhotoId: foodPhotoId ?? this.foodPhotoId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyNutritionId.present) {
      map['daily_nutrition_id'] = Variable<int>(dailyNutritionId.value);
    }
    if (foodPhotoId.present) {
      map['food_photo_id'] = Variable<int>(foodPhotoId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyNutritionPhotosCompanion(')
          ..write('id: $id, ')
          ..write('dailyNutritionId: $dailyNutritionId, ')
          ..write('foodPhotoId: $foodPhotoId')
          ..write(')'))
        .toString();
  }
}

class $SupplementIntakesTable extends SupplementIntakes
    with TableInfo<$SupplementIntakesTable, SupplementIntake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupplementIntakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplementMeta = const VerificationMeta(
    'supplement',
  );
  @override
  late final GeneratedColumn<String> supplement = GeneratedColumn<String>(
    'supplement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, supplement, takenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplement_intakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplementIntake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('supplement')) {
      context.handle(
        _supplementMeta,
        supplement.isAcceptableOrUnknown(data['supplement']!, _supplementMeta),
      );
    } else if (isInserting) {
      context.missing(_supplementMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SupplementIntake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplementIntake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      supplement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplement'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $SupplementIntakesTable createAlias(String alias) {
    return $SupplementIntakesTable(attachedDatabase, alias);
  }
}

class SupplementIntake extends DataClass
    implements Insertable<SupplementIntake> {
  final int id;
  final String date;
  final String supplement;
  final DateTime takenAt;
  const SupplementIntake({
    required this.id,
    required this.date,
    required this.supplement,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    map['supplement'] = Variable<String>(supplement);
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  SupplementIntakesCompanion toCompanion(bool nullToAbsent) {
    return SupplementIntakesCompanion(
      id: Value(id),
      date: Value(date),
      supplement: Value(supplement),
      takenAt: Value(takenAt),
    );
  }

  factory SupplementIntake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplementIntake(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      supplement: serializer.fromJson<String>(json['supplement']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'supplement': serializer.toJson<String>(supplement),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  SupplementIntake copyWith({
    int? id,
    String? date,
    String? supplement,
    DateTime? takenAt,
  }) => SupplementIntake(
    id: id ?? this.id,
    date: date ?? this.date,
    supplement: supplement ?? this.supplement,
    takenAt: takenAt ?? this.takenAt,
  );
  SupplementIntake copyWithCompanion(SupplementIntakesCompanion data) {
    return SupplementIntake(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      supplement: data.supplement.present
          ? data.supplement.value
          : this.supplement,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplementIntake(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('supplement: $supplement, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, supplement, takenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplementIntake &&
          other.id == this.id &&
          other.date == this.date &&
          other.supplement == this.supplement &&
          other.takenAt == this.takenAt);
}

class SupplementIntakesCompanion extends UpdateCompanion<SupplementIntake> {
  final Value<int> id;
  final Value<String> date;
  final Value<String> supplement;
  final Value<DateTime> takenAt;
  const SupplementIntakesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.supplement = const Value.absent(),
    this.takenAt = const Value.absent(),
  });
  SupplementIntakesCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    required String supplement,
    this.takenAt = const Value.absent(),
  }) : date = Value(date),
       supplement = Value(supplement);
  static Insertable<SupplementIntake> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? supplement,
    Expression<DateTime>? takenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (supplement != null) 'supplement': supplement,
      if (takenAt != null) 'taken_at': takenAt,
    });
  }

  SupplementIntakesCompanion copyWith({
    Value<int>? id,
    Value<String>? date,
    Value<String>? supplement,
    Value<DateTime>? takenAt,
  }) {
    return SupplementIntakesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      supplement: supplement ?? this.supplement,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (supplement.present) {
      map['supplement'] = Variable<String>(supplement.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplementIntakesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('supplement: $supplement, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }
}

class $MealPlansTable extends MealPlans
    with TableInfo<$MealPlansTable, MealPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealNameMeta = const VerificationMeta(
    'mealName',
  );
  @override
  late final GeneratedColumn<String> mealName = GeneratedColumn<String>(
    'meal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ingredientsMeta = const VerificationMeta(
    'ingredients',
  );
  @override
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
    'ingredients',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayOfWeek,
    mealName,
    ingredients,
    calories,
    proteinG,
    carbsG,
    fatG,
    videoUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('meal_name')) {
      context.handle(
        _mealNameMeta,
        mealName.isAcceptableOrUnknown(data['meal_name']!, _mealNameMeta),
      );
    } else if (isInserting) {
      context.missing(_mealNameMeta);
    }
    if (data.containsKey('ingredients')) {
      context.handle(
        _ingredientsMeta,
        ingredients.isAcceptableOrUnknown(
          data['ingredients']!,
          _ingredientsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientsMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      mealName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_name'],
      )!,
      ingredients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
    );
  }

  @override
  $MealPlansTable createAlias(String alias) {
    return $MealPlansTable(attachedDatabase, alias);
  }
}

class MealPlan extends DataClass implements Insertable<MealPlan> {
  final int id;
  final int dayOfWeek;
  final String mealName;
  final String ingredients;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? videoUrl;
  const MealPlan({
    required this.id,
    required this.dayOfWeek,
    required this.mealName,
    required this.ingredients,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.videoUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['meal_name'] = Variable<String>(mealName);
    map['ingredients'] = Variable<String>(ingredients);
    map['calories'] = Variable<double>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    return map;
  }

  MealPlansCompanion toCompanion(bool nullToAbsent) {
    return MealPlansCompanion(
      id: Value(id),
      dayOfWeek: Value(dayOfWeek),
      mealName: Value(mealName),
      ingredients: Value(ingredients),
      calories: Value(calories),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
    );
  }

  factory MealPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealPlan(
      id: serializer.fromJson<int>(json['id']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      mealName: serializer.fromJson<String>(json['mealName']),
      ingredients: serializer.fromJson<String>(json['ingredients']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'mealName': serializer.toJson<String>(mealName),
      'ingredients': serializer.toJson<String>(ingredients),
      'calories': serializer.toJson<double>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'videoUrl': serializer.toJson<String?>(videoUrl),
    };
  }

  MealPlan copyWith({
    int? id,
    int? dayOfWeek,
    String? mealName,
    String? ingredients,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    Value<String?> videoUrl = const Value.absent(),
  }) => MealPlan(
    id: id ?? this.id,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    mealName: mealName ?? this.mealName,
    ingredients: ingredients ?? this.ingredients,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
  );
  MealPlan copyWithCompanion(MealPlansCompanion data) {
    return MealPlan(
      id: data.id.present ? data.id.value : this.id,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      mealName: data.mealName.present ? data.mealName.value : this.mealName,
      ingredients: data.ingredients.present
          ? data.ingredients.value
          : this.ingredients,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealPlan(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('mealName: $mealName, ')
          ..write('ingredients: $ingredients, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('videoUrl: $videoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayOfWeek,
    mealName,
    ingredients,
    calories,
    proteinG,
    carbsG,
    fatG,
    videoUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealPlan &&
          other.id == this.id &&
          other.dayOfWeek == this.dayOfWeek &&
          other.mealName == this.mealName &&
          other.ingredients == this.ingredients &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.videoUrl == this.videoUrl);
}

class MealPlansCompanion extends UpdateCompanion<MealPlan> {
  final Value<int> id;
  final Value<int> dayOfWeek;
  final Value<String> mealName;
  final Value<String> ingredients;
  final Value<double> calories;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<String?> videoUrl;
  const MealPlansCompanion({
    this.id = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.mealName = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.videoUrl = const Value.absent(),
  });
  MealPlansCompanion.insert({
    this.id = const Value.absent(),
    required int dayOfWeek,
    required String mealName,
    required String ingredients,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    this.videoUrl = const Value.absent(),
  }) : dayOfWeek = Value(dayOfWeek),
       mealName = Value(mealName),
       ingredients = Value(ingredients),
       calories = Value(calories),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG);
  static Insertable<MealPlan> custom({
    Expression<int>? id,
    Expression<int>? dayOfWeek,
    Expression<String>? mealName,
    Expression<String>? ingredients,
    Expression<double>? calories,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? videoUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (mealName != null) 'meal_name': mealName,
      if (ingredients != null) 'ingredients': ingredients,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (videoUrl != null) 'video_url': videoUrl,
    });
  }

  MealPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? dayOfWeek,
    Value<String>? mealName,
    Value<String>? ingredients,
    Value<double>? calories,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<String?>? videoUrl,
  }) {
    return MealPlansCompanion(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealName: mealName ?? this.mealName,
      ingredients: ingredients ?? this.ingredients,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (mealName.present) {
      map['meal_name'] = Variable<String>(mealName.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealPlansCompanion(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('mealName: $mealName, ')
          ..write('ingredients: $ingredients, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('videoUrl: $videoUrl')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $ExerciseLogsTable exerciseLogs = $ExerciseLogsTable(this);
  late final $FoodPhotosTable foodPhotos = $FoodPhotosTable(this);
  late final $DailyNutritionTable dailyNutrition = $DailyNutritionTable(this);
  late final $DailyNutritionPhotosTable dailyNutritionPhotos =
      $DailyNutritionPhotosTable(this);
  late final $SupplementIntakesTable supplementIntakes =
      $SupplementIntakesTable(this);
  late final $MealPlansTable mealPlans = $MealPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    programs,
    workoutSessions,
    exerciseLogs,
    foodPhotos,
    dailyNutrition,
    dailyNutritionPhotos,
    supplementIntakes,
    mealPlans,
  ];
}

typedef $$ProgramsTableCreateCompanionBuilder = ProgramsCompanion Function({
  required String id,
  required String name,
  Value<String?> sourceNote,
  required String jsonData,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ProgramsTableUpdateCompanionBuilder = ProgramsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> sourceNote,
  Value<String> jsonData,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceNote => $composableBuilder(
    column: $table.sourceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          Program,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (Program, BaseReferences<_$AppDatabase, $ProgramsTable, Program>),
          Program,
          PrefetchHooks Function()
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sourceNote = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                name: name,
                sourceNote: sourceNote,
                jsonData: jsonData,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> sourceNote = const Value.absent(),
                required String jsonData,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                name: name,
                sourceNote: sourceNote,
                jsonData: jsonData,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgramsTable, Program>(table),
                  BaseReferences<_$AppDatabase, $ProgramsTable, Program>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      Program,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (Program, BaseReferences<_$AppDatabase, $ProgramsTable, Program>),
      Program,
      PrefetchHooks Function()
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      required String programId,
      required String weekId,
      required String dayId,
      required String dayName,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<int> id,
      Value<String> programId,
      Value<String> weekId,
      Value<String> dayId,
      Value<String> dayName,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<String?> notes,
    });

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekId => $composableBuilder(
    column: $table.weekId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayName => $composableBuilder(
    column: $table.dayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekId => $composableBuilder(
    column: $table.weekId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayId => $composableBuilder(
    column: $table.dayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayName => $composableBuilder(
    column: $table.dayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<String> get weekId =>
      $composableBuilder(column: $table.weekId, builder: (column) => column);

  GeneratedColumn<String> get dayId =>
      $composableBuilder(column: $table.dayId, builder: (column) => column);

  GeneratedColumn<String> get dayName =>
      $composableBuilder(column: $table.dayName, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (
            WorkoutSession,
            BaseReferences<
              _$AppDatabase,
              $WorkoutSessionsTable,
              WorkoutSession
            >,
          ),
          WorkoutSession,
          PrefetchHooks Function()
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> programId = const Value.absent(),
                Value<String> weekId = const Value.absent(),
                Value<String> dayId = const Value.absent(),
                Value<String> dayName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                programId: programId,
                weekId: weekId,
                dayId: dayId,
                dayName: dayName,
                startedAt: startedAt,
                finishedAt: finishedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String programId,
                required String weekId,
                required String dayId,
                required String dayName,
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                programId: programId,
                weekId: weekId,
                dayId: dayId,
                dayName: dayName,
                startedAt: startedAt,
                finishedAt: finishedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSessionsTable, WorkoutSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkoutSessionsTable,
                    WorkoutSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (
        WorkoutSession,
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession>,
      ),
      WorkoutSession,
      PrefetchHooks Function()
    >;
typedef $$ExerciseLogsTableCreateCompanionBuilder =
    ExerciseLogsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String blockId,
      required String exerciseId,
      required String exerciseName,
      required String blockType,
      required String logMode,
      required int setNumber,
      Value<double?> weight,
      Value<int?> reps,
      Value<int?> targetReps,
      Value<bool> hitFailure,
      Value<int?> durationSeconds,
      Value<String?> notes,
      Value<DateTime> loggedAt,
    });
typedef $$ExerciseLogsTableUpdateCompanionBuilder =
    ExerciseLogsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> blockId,
      Value<String> exerciseId,
      Value<String> exerciseName,
      Value<String> blockType,
      Value<String> logMode,
      Value<int> setNumber,
      Value<double?> weight,
      Value<int?> reps,
      Value<int?> targetReps,
      Value<bool> hitFailure,
      Value<int?> durationSeconds,
      Value<String?> notes,
      Value<DateTime> loggedAt,
    });

class $$ExerciseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockType => $composableBuilder(
    column: $table.blockType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logMode => $composableBuilder(
    column: $table.logMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hitFailure => $composableBuilder(
    column: $table.hitFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockType => $composableBuilder(
    column: $table.blockType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logMode => $composableBuilder(
    column: $table.logMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hitFailure => $composableBuilder(
    column: $table.hitFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseName => $composableBuilder(
    column: $table.exerciseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blockType =>
      $composableBuilder(column: $table.blockType, builder: (column) => column);

  GeneratedColumn<String> get logMode =>
      $composableBuilder(column: $table.logMode, builder: (column) => column);

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hitFailure => $composableBuilder(
    column: $table.hitFailure,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$ExerciseLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseLogsTable,
          ExerciseLog,
          $$ExerciseLogsTableFilterComposer,
          $$ExerciseLogsTableOrderingComposer,
          $$ExerciseLogsTableAnnotationComposer,
          $$ExerciseLogsTableCreateCompanionBuilder,
          $$ExerciseLogsTableUpdateCompanionBuilder,
          (
            ExerciseLog,
            BaseReferences<_$AppDatabase, $ExerciseLogsTable, ExerciseLog>,
          ),
          ExerciseLog,
          PrefetchHooks Function()
        > {
  $$ExerciseLogsTableTableManager(_$AppDatabase db, $ExerciseLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> blockId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<String> blockType = const Value.absent(),
                Value<String> logMode = const Value.absent(),
                Value<int> setNumber = const Value.absent(),
                Value<double?> weight = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<bool> hitFailure = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => ExerciseLogsCompanion(
                id: id,
                sessionId: sessionId,
                blockId: blockId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                blockType: blockType,
                logMode: logMode,
                setNumber: setNumber,
                weight: weight,
                reps: reps,
                targetReps: targetReps,
                hitFailure: hitFailure,
                durationSeconds: durationSeconds,
                notes: notes,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String blockId,
                required String exerciseId,
                required String exerciseName,
                required String blockType,
                required String logMode,
                required int setNumber,
                Value<double?> weight = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<bool> hitFailure = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => ExerciseLogsCompanion.insert(
                id: id,
                sessionId: sessionId,
                blockId: blockId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                blockType: blockType,
                logMode: logMode,
                setNumber: setNumber,
                weight: weight,
                reps: reps,
                targetReps: targetReps,
                hitFailure: hitFailure,
                durationSeconds: durationSeconds,
                notes: notes,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseLogsTable, ExerciseLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseLogsTable,
                    ExerciseLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseLogsTable,
      ExerciseLog,
      $$ExerciseLogsTableFilterComposer,
      $$ExerciseLogsTableOrderingComposer,
      $$ExerciseLogsTableAnnotationComposer,
      $$ExerciseLogsTableCreateCompanionBuilder,
      $$ExerciseLogsTableUpdateCompanionBuilder,
      (
        ExerciseLog,
        BaseReferences<_$AppDatabase, $ExerciseLogsTable, ExerciseLog>,
      ),
      ExerciseLog,
      PrefetchHooks Function()
    >;
typedef $$FoodPhotosTableCreateCompanionBuilder = FoodPhotosCompanion Function({
  Value<int> id,
  required String filePath,
  Value<Uint8List?> thumbnail,
  Value<DateTime> capturedAt,
  Value<String?> mealLabel,
});
typedef $$FoodPhotosTableUpdateCompanionBuilder = FoodPhotosCompanion Function({
  Value<int> id,
  Value<String> filePath,
  Value<Uint8List?> thumbnail,
  Value<DateTime> capturedAt,
  Value<String?> mealLabel,
});

class $$FoodPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $FoodPhotosTable> {
  $$FoodPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealLabel => $composableBuilder(
    column: $table.mealLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodPhotosTable> {
  $$FoodPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealLabel => $composableBuilder(
    column: $table.mealLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodPhotosTable> {
  $$FoodPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<Uint8List> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mealLabel =>
      $composableBuilder(column: $table.mealLabel, builder: (column) => column);
}

class $$FoodPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodPhotosTable,
          FoodPhoto,
          $$FoodPhotosTableFilterComposer,
          $$FoodPhotosTableOrderingComposer,
          $$FoodPhotosTableAnnotationComposer,
          $$FoodPhotosTableCreateCompanionBuilder,
          $$FoodPhotosTableUpdateCompanionBuilder,
          (
            FoodPhoto,
            BaseReferences<_$AppDatabase, $FoodPhotosTable, FoodPhoto>,
          ),
          FoodPhoto,
          PrefetchHooks Function()
        > {
  $$FoodPhotosTableTableManager(_$AppDatabase db, $FoodPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<Uint8List?> thumbnail = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> mealLabel = const Value.absent(),
              }) => FoodPhotosCompanion(
                id: id,
                filePath: filePath,
                thumbnail: thumbnail,
                capturedAt: capturedAt,
                mealLabel: mealLabel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                Value<Uint8List?> thumbnail = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> mealLabel = const Value.absent(),
              }) => FoodPhotosCompanion.insert(
                id: id,
                filePath: filePath,
                thumbnail: thumbnail,
                capturedAt: capturedAt,
                mealLabel: mealLabel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodPhotosTable, FoodPhoto>(table),
                  BaseReferences<_$AppDatabase, $FoodPhotosTable, FoodPhoto>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodPhotosTable,
      FoodPhoto,
      $$FoodPhotosTableFilterComposer,
      $$FoodPhotosTableOrderingComposer,
      $$FoodPhotosTableAnnotationComposer,
      $$FoodPhotosTableCreateCompanionBuilder,
      $$FoodPhotosTableUpdateCompanionBuilder,
      (FoodPhoto, BaseReferences<_$AppDatabase, $FoodPhotosTable, FoodPhoto>),
      FoodPhoto,
      PrefetchHooks Function()
    >;
typedef $$DailyNutritionTableCreateCompanionBuilder =
    DailyNutritionCompanion Function({
      Value<int> id,
      required String date,
      Value<String?> analysisJson,
      Value<double?> totalCalories,
      Value<double?> proteinG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<DateTime?> analyzedAt,
      Value<String> status,
    });
typedef $$DailyNutritionTableUpdateCompanionBuilder =
    DailyNutritionCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String?> analysisJson,
      Value<double?> totalCalories,
      Value<double?> proteinG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<DateTime?> analyzedAt,
      Value<String> status,
    });

class $$DailyNutritionTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNutritionTable> {
  $$DailyNutritionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCalories => $composableBuilder(
    column: $table.totalCalories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyNutritionTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNutritionTable> {
  $$DailyNutritionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCalories => $composableBuilder(
    column: $table.totalCalories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyNutritionTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNutritionTable> {
  $$DailyNutritionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get analysisJson => $composableBuilder(
    column: $table.analysisJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCalories => $composableBuilder(
    column: $table.totalCalories,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<DateTime> get analyzedAt => $composableBuilder(
    column: $table.analyzedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$DailyNutritionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNutritionTable,
          DailyNutritionData,
          $$DailyNutritionTableFilterComposer,
          $$DailyNutritionTableOrderingComposer,
          $$DailyNutritionTableAnnotationComposer,
          $$DailyNutritionTableCreateCompanionBuilder,
          $$DailyNutritionTableUpdateCompanionBuilder,
          (
            DailyNutritionData,
            BaseReferences<
              _$AppDatabase,
              $DailyNutritionTable,
              DailyNutritionData
            >,
          ),
          DailyNutritionData,
          PrefetchHooks Function()
        > {
  $$DailyNutritionTableTableManager(
    _$AppDatabase db,
    $DailyNutritionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNutritionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNutritionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyNutritionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> analysisJson = const Value.absent(),
                Value<double?> totalCalories = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<DateTime?> analyzedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DailyNutritionCompanion(
                id: id,
                date: date,
                analysisJson: analysisJson,
                totalCalories: totalCalories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                analyzedAt: analyzedAt,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                Value<String?> analysisJson = const Value.absent(),
                Value<double?> totalCalories = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<DateTime?> analyzedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => DailyNutritionCompanion.insert(
                id: id,
                date: date,
                analysisJson: analysisJson,
                totalCalories: totalCalories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                analyzedAt: analyzedAt,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyNutritionTable, DailyNutritionData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyNutritionTable,
                    DailyNutritionData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyNutritionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNutritionTable,
      DailyNutritionData,
      $$DailyNutritionTableFilterComposer,
      $$DailyNutritionTableOrderingComposer,
      $$DailyNutritionTableAnnotationComposer,
      $$DailyNutritionTableCreateCompanionBuilder,
      $$DailyNutritionTableUpdateCompanionBuilder,
      (
        DailyNutritionData,
        BaseReferences<_$AppDatabase, $DailyNutritionTable, DailyNutritionData>,
      ),
      DailyNutritionData,
      PrefetchHooks Function()
    >;
typedef $$DailyNutritionPhotosTableCreateCompanionBuilder =
    DailyNutritionPhotosCompanion Function({
      Value<int> id,
      required int dailyNutritionId,
      required int foodPhotoId,
    });
typedef $$DailyNutritionPhotosTableUpdateCompanionBuilder =
    DailyNutritionPhotosCompanion Function({
      Value<int> id,
      Value<int> dailyNutritionId,
      Value<int> foodPhotoId,
    });

class $$DailyNutritionPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $DailyNutritionPhotosTable> {
  $$DailyNutritionPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyNutritionId => $composableBuilder(
    column: $table.dailyNutritionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodPhotoId => $composableBuilder(
    column: $table.foodPhotoId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyNutritionPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyNutritionPhotosTable> {
  $$DailyNutritionPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyNutritionId => $composableBuilder(
    column: $table.dailyNutritionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodPhotoId => $composableBuilder(
    column: $table.foodPhotoId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyNutritionPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyNutritionPhotosTable> {
  $$DailyNutritionPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dailyNutritionId => $composableBuilder(
    column: $table.dailyNutritionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get foodPhotoId => $composableBuilder(
    column: $table.foodPhotoId,
    builder: (column) => column,
  );
}

class $$DailyNutritionPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyNutritionPhotosTable,
          DailyNutritionPhoto,
          $$DailyNutritionPhotosTableFilterComposer,
          $$DailyNutritionPhotosTableOrderingComposer,
          $$DailyNutritionPhotosTableAnnotationComposer,
          $$DailyNutritionPhotosTableCreateCompanionBuilder,
          $$DailyNutritionPhotosTableUpdateCompanionBuilder,
          (
            DailyNutritionPhoto,
            BaseReferences<
              _$AppDatabase,
              $DailyNutritionPhotosTable,
              DailyNutritionPhoto
            >,
          ),
          DailyNutritionPhoto,
          PrefetchHooks Function()
        > {
  $$DailyNutritionPhotosTableTableManager(
    _$AppDatabase db,
    $DailyNutritionPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyNutritionPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyNutritionPhotosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyNutritionPhotosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyNutritionId = const Value.absent(),
                Value<int> foodPhotoId = const Value.absent(),
              }) => DailyNutritionPhotosCompanion(
                id: id,
                dailyNutritionId: dailyNutritionId,
                foodPhotoId: foodPhotoId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dailyNutritionId,
                required int foodPhotoId,
              }) => DailyNutritionPhotosCompanion.insert(
                id: id,
                dailyNutritionId: dailyNutritionId,
                foodPhotoId: foodPhotoId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyNutritionPhotosTable, DailyNutritionPhoto>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyNutritionPhotosTable,
                    DailyNutritionPhoto
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyNutritionPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyNutritionPhotosTable,
      DailyNutritionPhoto,
      $$DailyNutritionPhotosTableFilterComposer,
      $$DailyNutritionPhotosTableOrderingComposer,
      $$DailyNutritionPhotosTableAnnotationComposer,
      $$DailyNutritionPhotosTableCreateCompanionBuilder,
      $$DailyNutritionPhotosTableUpdateCompanionBuilder,
      (
        DailyNutritionPhoto,
        BaseReferences<
          _$AppDatabase,
          $DailyNutritionPhotosTable,
          DailyNutritionPhoto
        >,
      ),
      DailyNutritionPhoto,
      PrefetchHooks Function()
    >;
typedef $$SupplementIntakesTableCreateCompanionBuilder =
    SupplementIntakesCompanion Function({
      Value<int> id,
      required String date,
      required String supplement,
      Value<DateTime> takenAt,
    });
typedef $$SupplementIntakesTableUpdateCompanionBuilder =
    SupplementIntakesCompanion Function({
      Value<int> id,
      Value<String> date,
      Value<String> supplement,
      Value<DateTime> takenAt,
    });

class $$SupplementIntakesTableFilterComposer
    extends Composer<_$AppDatabase, $SupplementIntakesTable> {
  $$SupplementIntakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplement => $composableBuilder(
    column: $table.supplement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SupplementIntakesTableOrderingComposer
    extends Composer<_$AppDatabase, $SupplementIntakesTable> {
  $$SupplementIntakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplement => $composableBuilder(
    column: $table.supplement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SupplementIntakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupplementIntakesTable> {
  $$SupplementIntakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get supplement => $composableBuilder(
    column: $table.supplement,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);
}

class $$SupplementIntakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SupplementIntakesTable,
          SupplementIntake,
          $$SupplementIntakesTableFilterComposer,
          $$SupplementIntakesTableOrderingComposer,
          $$SupplementIntakesTableAnnotationComposer,
          $$SupplementIntakesTableCreateCompanionBuilder,
          $$SupplementIntakesTableUpdateCompanionBuilder,
          (
            SupplementIntake,
            BaseReferences<
              _$AppDatabase,
              $SupplementIntakesTable,
              SupplementIntake
            >,
          ),
          SupplementIntake,
          PrefetchHooks Function()
        > {
  $$SupplementIntakesTableTableManager(
    _$AppDatabase db,
    $SupplementIntakesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupplementIntakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SupplementIntakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupplementIntakesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> supplement = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => SupplementIntakesCompanion(
                id: id,
                date: date,
                supplement: supplement,
                takenAt: takenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String date,
                required String supplement,
                Value<DateTime> takenAt = const Value.absent(),
              }) => SupplementIntakesCompanion.insert(
                id: id,
                date: date,
                supplement: supplement,
                takenAt: takenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SupplementIntakesTable, SupplementIntake>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SupplementIntakesTable,
                    SupplementIntake
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SupplementIntakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SupplementIntakesTable,
      SupplementIntake,
      $$SupplementIntakesTableFilterComposer,
      $$SupplementIntakesTableOrderingComposer,
      $$SupplementIntakesTableAnnotationComposer,
      $$SupplementIntakesTableCreateCompanionBuilder,
      $$SupplementIntakesTableUpdateCompanionBuilder,
      (
        SupplementIntake,
        BaseReferences<
          _$AppDatabase,
          $SupplementIntakesTable,
          SupplementIntake
        >,
      ),
      SupplementIntake,
      PrefetchHooks Function()
    >;
typedef $$MealPlansTableCreateCompanionBuilder = MealPlansCompanion Function({
  Value<int> id,
  required int dayOfWeek,
  required String mealName,
  required String ingredients,
  required double calories,
  required double proteinG,
  required double carbsG,
  required double fatG,
  Value<String?> videoUrl,
});
typedef $$MealPlansTableUpdateCompanionBuilder = MealPlansCompanion Function({
  Value<int> id,
  Value<int> dayOfWeek,
  Value<String> mealName,
  Value<String> ingredients,
  Value<double> calories,
  Value<double> proteinG,
  Value<double> carbsG,
  Value<double> fatG,
  Value<String?> videoUrl,
});

class $$MealPlansTableFilterComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealName => $composableBuilder(
    column: $table.mealName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealPlansTable> {
  $$MealPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get mealName =>
      $composableBuilder(column: $table.mealName, builder: (column) => column);

  GeneratedColumn<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);
}

class $$MealPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealPlansTable,
          MealPlan,
          $$MealPlansTableFilterComposer,
          $$MealPlansTableOrderingComposer,
          $$MealPlansTableAnnotationComposer,
          $$MealPlansTableCreateCompanionBuilder,
          $$MealPlansTableUpdateCompanionBuilder,
          (MealPlan, BaseReferences<_$AppDatabase, $MealPlansTable, MealPlan>),
          MealPlan,
          PrefetchHooks Function()
        > {
  $$MealPlansTableTableManager(_$AppDatabase db, $MealPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> mealName = const Value.absent(),
                Value<String> ingredients = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
              }) => MealPlansCompanion(
                id: id,
                dayOfWeek: dayOfWeek,
                mealName: mealName,
                ingredients: ingredients,
                calories: calories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                videoUrl: videoUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayOfWeek,
                required String mealName,
                required String ingredients,
                required double calories,
                required double proteinG,
                required double carbsG,
                required double fatG,
                Value<String?> videoUrl = const Value.absent(),
              }) => MealPlansCompanion.insert(
                id: id,
                dayOfWeek: dayOfWeek,
                mealName: mealName,
                ingredients: ingredients,
                calories: calories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                videoUrl: videoUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealPlansTable, MealPlan>(table),
                  BaseReferences<_$AppDatabase, $MealPlansTable, MealPlan>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealPlansTable,
      MealPlan,
      $$MealPlansTableFilterComposer,
      $$MealPlansTableOrderingComposer,
      $$MealPlansTableAnnotationComposer,
      $$MealPlansTableCreateCompanionBuilder,
      $$MealPlansTableUpdateCompanionBuilder,
      (MealPlan, BaseReferences<_$AppDatabase, $MealPlansTable, MealPlan>),
      MealPlan,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$ExerciseLogsTableTableManager get exerciseLogs =>
      $$ExerciseLogsTableTableManager(_db, _db.exerciseLogs);
  $$FoodPhotosTableTableManager get foodPhotos =>
      $$FoodPhotosTableTableManager(_db, _db.foodPhotos);
  $$DailyNutritionTableTableManager get dailyNutrition =>
      $$DailyNutritionTableTableManager(_db, _db.dailyNutrition);
  $$DailyNutritionPhotosTableTableManager get dailyNutritionPhotos =>
      $$DailyNutritionPhotosTableTableManager(_db, _db.dailyNutritionPhotos);
  $$SupplementIntakesTableTableManager get supplementIntakes =>
      $$SupplementIntakesTableTableManager(_db, _db.supplementIntakes);
  $$MealPlansTableTableManager get mealPlans =>
      $$MealPlansTableTableManager(_db, _db.mealPlans);
}
