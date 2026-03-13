// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropMeta = const VerificationMeta('crop');
  @override
  late final GeneratedColumn<String> crop = GeneratedColumn<String>(
    'crop',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitTypeMeta = const VerificationMeta(
    'visitType',
  );
  @override
  late final GeneratedColumn<String> visitType = GeneratedColumn<String>(
    'visit_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACA'),
  );
  static const VerificationMeta _durationHoursMeta = const VerificationMeta(
    'durationHours',
  );
  @override
  late final GeneratedColumn<int> durationHours = GeneratedColumn<int>(
    'duration_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _plannedDurationHoursMeta =
      const VerificationMeta('plannedDurationHours');
  @override
  late final GeneratedColumn<int> plannedDurationHours = GeneratedColumn<int>(
    'planned_duration_hours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationJustificationMeta =
      const VerificationMeta('durationJustification');
  @override
  late final GeneratedColumn<String> durationJustification =
      GeneratedColumn<String>(
        'duration_justification',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inspectorNameMeta = const VerificationMeta(
    'inspectorName',
  );
  @override
  late final GeneratedColumn<String> inspectorName = GeneratedColumn<String>(
    'inspector_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _companionNameMeta = const VerificationMeta(
    'companionName',
  );
  @override
  late final GeneratedColumn<String> companionName = GeneratedColumn<String>(
    'companion_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _representativeNameMeta =
      const VerificationMeta('representativeName');
  @override
  late final GeneratedColumn<String> representativeName =
      GeneratedColumn<String>(
        'representative_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduledAt,
    companyName,
    crop,
    status,
    visitType,
    durationHours,
    plannedDurationHours,
    durationJustification,
    updatedAt,
    inspectorName,
    companionName,
    representativeName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_companyNameMeta);
    }
    if (data.containsKey('crop')) {
      context.handle(
        _cropMeta,
        crop.isAcceptableOrUnknown(data['crop']!, _cropMeta),
      );
    } else if (isInserting) {
      context.missing(_cropMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('visit_type')) {
      context.handle(
        _visitTypeMeta,
        visitType.isAcceptableOrUnknown(data['visit_type']!, _visitTypeMeta),
      );
    }
    if (data.containsKey('duration_hours')) {
      context.handle(
        _durationHoursMeta,
        durationHours.isAcceptableOrUnknown(
          data['duration_hours']!,
          _durationHoursMeta,
        ),
      );
    }
    if (data.containsKey('planned_duration_hours')) {
      context.handle(
        _plannedDurationHoursMeta,
        plannedDurationHours.isAcceptableOrUnknown(
          data['planned_duration_hours']!,
          _plannedDurationHoursMeta,
        ),
      );
    }
    if (data.containsKey('duration_justification')) {
      context.handle(
        _durationJustificationMeta,
        durationJustification.isAcceptableOrUnknown(
          data['duration_justification']!,
          _durationJustificationMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('inspector_name')) {
      context.handle(
        _inspectorNameMeta,
        inspectorName.isAcceptableOrUnknown(
          data['inspector_name']!,
          _inspectorNameMeta,
        ),
      );
    }
    if (data.containsKey('companion_name')) {
      context.handle(
        _companionNameMeta,
        companionName.isAcceptableOrUnknown(
          data['companion_name']!,
          _companionNameMeta,
        ),
      );
    }
    if (data.containsKey('representative_name')) {
      context.handle(
        _representativeNameMeta,
        representativeName.isAcceptableOrUnknown(
          data['representative_name']!,
          _representativeNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      )!,
      crop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      visitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_type'],
      )!,
      durationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_hours'],
      )!,
      plannedDurationHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_duration_hours'],
      )!,
      durationJustification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration_justification'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      inspectorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inspector_name'],
      )!,
      companionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companion_name'],
      )!,
      representativeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}representative_name'],
      )!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final String id;
  final DateTime scheduledAt;
  final String companyName;
  final String crop;
  final int status;
  final String visitType;
  final int durationHours;
  final int plannedDurationHours;
  final String durationJustification;
  final DateTime updatedAt;

  /// Nome dell'ispettore che esegue la visita
  final String inspectorName;

  /// Nome dell'eventuale affiancatore
  final String companionName;

  /// Nome del rappresentante aziendale o delegato
  final String representativeName;
  const Visit({
    required this.id,
    required this.scheduledAt,
    required this.companyName,
    required this.crop,
    required this.status,
    required this.visitType,
    required this.durationHours,
    required this.plannedDurationHours,
    required this.durationJustification,
    required this.updatedAt,
    required this.inspectorName,
    required this.companionName,
    required this.representativeName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['company_name'] = Variable<String>(companyName);
    map['crop'] = Variable<String>(crop);
    map['status'] = Variable<int>(status);
    map['visit_type'] = Variable<String>(visitType);
    map['duration_hours'] = Variable<int>(durationHours);
    map['planned_duration_hours'] = Variable<int>(plannedDurationHours);
    map['duration_justification'] = Variable<String>(durationJustification);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['inspector_name'] = Variable<String>(inspectorName);
    map['companion_name'] = Variable<String>(companionName);
    map['representative_name'] = Variable<String>(representativeName);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      scheduledAt: Value(scheduledAt),
      companyName: Value(companyName),
      crop: Value(crop),
      status: Value(status),
      visitType: Value(visitType),
      durationHours: Value(durationHours),
      plannedDurationHours: Value(plannedDurationHours),
      durationJustification: Value(durationJustification),
      updatedAt: Value(updatedAt),
      inspectorName: Value(inspectorName),
      companionName: Value(companionName),
      representativeName: Value(representativeName),
    );
  }

  factory Visit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<String>(json['id']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      companyName: serializer.fromJson<String>(json['companyName']),
      crop: serializer.fromJson<String>(json['crop']),
      status: serializer.fromJson<int>(json['status']),
      visitType: serializer.fromJson<String>(json['visitType']),
      durationHours: serializer.fromJson<int>(json['durationHours']),
      plannedDurationHours: serializer.fromJson<int>(
        json['plannedDurationHours'],
      ),
      durationJustification: serializer.fromJson<String>(
        json['durationJustification'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      inspectorName: serializer.fromJson<String>(json['inspectorName']),
      companionName: serializer.fromJson<String>(json['companionName']),
      representativeName: serializer.fromJson<String>(
        json['representativeName'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'companyName': serializer.toJson<String>(companyName),
      'crop': serializer.toJson<String>(crop),
      'status': serializer.toJson<int>(status),
      'visitType': serializer.toJson<String>(visitType),
      'durationHours': serializer.toJson<int>(durationHours),
      'plannedDurationHours': serializer.toJson<int>(plannedDurationHours),
      'durationJustification': serializer.toJson<String>(durationJustification),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'inspectorName': serializer.toJson<String>(inspectorName),
      'companionName': serializer.toJson<String>(companionName),
      'representativeName': serializer.toJson<String>(representativeName),
    };
  }

  Visit copyWith({
    String? id,
    DateTime? scheduledAt,
    String? companyName,
    String? crop,
    int? status,
    String? visitType,
    int? durationHours,
    int? plannedDurationHours,
    String? durationJustification,
    DateTime? updatedAt,
    String? inspectorName,
    String? companionName,
    String? representativeName,
  }) => Visit(
    id: id ?? this.id,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    companyName: companyName ?? this.companyName,
    crop: crop ?? this.crop,
    status: status ?? this.status,
    visitType: visitType ?? this.visitType,
    durationHours: durationHours ?? this.durationHours,
    plannedDurationHours: plannedDurationHours ?? this.plannedDurationHours,
    durationJustification: durationJustification ?? this.durationJustification,
    updatedAt: updatedAt ?? this.updatedAt,
    inspectorName: inspectorName ?? this.inspectorName,
    companionName: companionName ?? this.companionName,
    representativeName: representativeName ?? this.representativeName,
  );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      crop: data.crop.present ? data.crop.value : this.crop,
      status: data.status.present ? data.status.value : this.status,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      durationHours: data.durationHours.present
          ? data.durationHours.value
          : this.durationHours,
      plannedDurationHours: data.plannedDurationHours.present
          ? data.plannedDurationHours.value
          : this.plannedDurationHours,
      durationJustification: data.durationJustification.present
          ? data.durationJustification.value
          : this.durationJustification,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      inspectorName: data.inspectorName.present
          ? data.inspectorName.value
          : this.inspectorName,
      companionName: data.companionName.present
          ? data.companionName.value
          : this.companionName,
      representativeName: data.representativeName.present
          ? data.representativeName.value
          : this.representativeName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('companyName: $companyName, ')
          ..write('crop: $crop, ')
          ..write('status: $status, ')
          ..write('visitType: $visitType, ')
          ..write('durationHours: $durationHours, ')
          ..write('plannedDurationHours: $plannedDurationHours, ')
          ..write('durationJustification: $durationJustification, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('inspectorName: $inspectorName, ')
          ..write('companionName: $companionName, ')
          ..write('representativeName: $representativeName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduledAt,
    companyName,
    crop,
    status,
    visitType,
    durationHours,
    plannedDurationHours,
    durationJustification,
    updatedAt,
    inspectorName,
    companionName,
    representativeName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.scheduledAt == this.scheduledAt &&
          other.companyName == this.companyName &&
          other.crop == this.crop &&
          other.status == this.status &&
          other.visitType == this.visitType &&
          other.durationHours == this.durationHours &&
          other.plannedDurationHours == this.plannedDurationHours &&
          other.durationJustification == this.durationJustification &&
          other.updatedAt == this.updatedAt &&
          other.inspectorName == this.inspectorName &&
          other.companionName == this.companionName &&
          other.representativeName == this.representativeName);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<String> id;
  final Value<DateTime> scheduledAt;
  final Value<String> companyName;
  final Value<String> crop;
  final Value<int> status;
  final Value<String> visitType;
  final Value<int> durationHours;
  final Value<int> plannedDurationHours;
  final Value<String> durationJustification;
  final Value<DateTime> updatedAt;
  final Value<String> inspectorName;
  final Value<String> companionName;
  final Value<String> representativeName;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.companyName = const Value.absent(),
    this.crop = const Value.absent(),
    this.status = const Value.absent(),
    this.visitType = const Value.absent(),
    this.durationHours = const Value.absent(),
    this.plannedDurationHours = const Value.absent(),
    this.durationJustification = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.inspectorName = const Value.absent(),
    this.companionName = const Value.absent(),
    this.representativeName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required DateTime scheduledAt,
    required String companyName,
    required String crop,
    required int status,
    this.visitType = const Value.absent(),
    this.durationHours = const Value.absent(),
    this.plannedDurationHours = const Value.absent(),
    this.durationJustification = const Value.absent(),
    required DateTime updatedAt,
    this.inspectorName = const Value.absent(),
    this.companionName = const Value.absent(),
    this.representativeName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scheduledAt = Value(scheduledAt),
       companyName = Value(companyName),
       crop = Value(crop),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<Visit> custom({
    Expression<String>? id,
    Expression<DateTime>? scheduledAt,
    Expression<String>? companyName,
    Expression<String>? crop,
    Expression<int>? status,
    Expression<String>? visitType,
    Expression<int>? durationHours,
    Expression<int>? plannedDurationHours,
    Expression<String>? durationJustification,
    Expression<DateTime>? updatedAt,
    Expression<String>? inspectorName,
    Expression<String>? companionName,
    Expression<String>? representativeName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (companyName != null) 'company_name': companyName,
      if (crop != null) 'crop': crop,
      if (status != null) 'status': status,
      if (visitType != null) 'visit_type': visitType,
      if (durationHours != null) 'duration_hours': durationHours,
      if (plannedDurationHours != null)
        'planned_duration_hours': plannedDurationHours,
      if (durationJustification != null)
        'duration_justification': durationJustification,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (inspectorName != null) 'inspector_name': inspectorName,
      if (companionName != null) 'companion_name': companionName,
      if (representativeName != null) 'representative_name': representativeName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? scheduledAt,
    Value<String>? companyName,
    Value<String>? crop,
    Value<int>? status,
    Value<String>? visitType,
    Value<int>? durationHours,
    Value<int>? plannedDurationHours,
    Value<String>? durationJustification,
    Value<DateTime>? updatedAt,
    Value<String>? inspectorName,
    Value<String>? companionName,
    Value<String>? representativeName,
    Value<int>? rowid,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      companyName: companyName ?? this.companyName,
      crop: crop ?? this.crop,
      status: status ?? this.status,
      visitType: visitType ?? this.visitType,
      durationHours: durationHours ?? this.durationHours,
      plannedDurationHours: plannedDurationHours ?? this.plannedDurationHours,
      durationJustification:
          durationJustification ?? this.durationJustification,
      updatedAt: updatedAt ?? this.updatedAt,
      inspectorName: inspectorName ?? this.inspectorName,
      companionName: companionName ?? this.companionName,
      representativeName: representativeName ?? this.representativeName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (crop.present) {
      map['crop'] = Variable<String>(crop.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (visitType.present) {
      map['visit_type'] = Variable<String>(visitType.value);
    }
    if (durationHours.present) {
      map['duration_hours'] = Variable<int>(durationHours.value);
    }
    if (plannedDurationHours.present) {
      map['planned_duration_hours'] = Variable<int>(plannedDurationHours.value);
    }
    if (durationJustification.present) {
      map['duration_justification'] = Variable<String>(
        durationJustification.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (inspectorName.present) {
      map['inspector_name'] = Variable<String>(inspectorName.value);
    }
    if (companionName.present) {
      map['companion_name'] = Variable<String>(companionName.value);
    }
    if (representativeName.present) {
      map['representative_name'] = Variable<String>(representativeName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('companyName: $companyName, ')
          ..write('crop: $crop, ')
          ..write('status: $status, ')
          ..write('visitType: $visitType, ')
          ..write('durationHours: $durationHours, ')
          ..write('plannedDurationHours: $plannedDurationHours, ')
          ..write('durationJustification: $durationJustification, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('inspectorName: $inspectorName, ')
          ..write('companionName: $companionName, ')
          ..write('representativeName: $representativeName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitCompaniesTable extends VisitCompanies
    with TableInfo<$VisitCompaniesTable, VisitCompany> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitCompaniesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _ragioneSocialeMeta = const VerificationMeta(
    'ragioneSociale',
  );
  @override
  late final GeneratedColumn<String> ragioneSociale = GeneratedColumn<String>(
    'ragione_sociale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cuaaMeta = const VerificationMeta('cuaa');
  @override
  late final GeneratedColumn<String> cuaa = GeneratedColumn<String>(
    'cuaa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partitaIvaMeta = const VerificationMeta(
    'partitaIva',
  );
  @override
  late final GeneratedColumn<String> partitaIva = GeneratedColumn<String>(
    'partita_iva',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _indirizzoMeta = const VerificationMeta(
    'indirizzo',
  );
  @override
  late final GeneratedColumn<String> indirizzo = GeneratedColumn<String>(
    'indirizzo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _capMeta = const VerificationMeta('cap');
  @override
  late final GeneratedColumn<String> cap = GeneratedColumn<String>(
    'cap',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _comuneMeta = const VerificationMeta('comune');
  @override
  late final GeneratedColumn<String> comune = GeneratedColumn<String>(
    'comune',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _provinciaMeta = const VerificationMeta(
    'provincia',
  );
  @override
  late final GeneratedColumn<String> provincia = GeneratedColumn<String>(
    'provincia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _referenteMeta = const VerificationMeta(
    'referente',
  );
  @override
  late final GeneratedColumn<String> referente = GeneratedColumn<String>(
    'referente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pecMeta = const VerificationMeta('pec');
  @override
  late final GeneratedColumn<String> pec = GeneratedColumn<String>(
    'pec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _submissionNumberMeta = const VerificationMeta(
    'submissionNumber',
  );
  @override
  late final GeneratedColumn<String> submissionNumber = GeneratedColumn<String>(
    'submission_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isNewOperatorMeta = const VerificationMeta(
    'isNewOperator',
  );
  @override
  late final GeneratedColumn<bool> isNewOperator = GeneratedColumn<bool>(
    'is_new_operator',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_new_operator" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _processingTypeMeta = const VerificationMeta(
    'processingType',
  );
  @override
  late final GeneratedColumn<String> processingType = GeneratedColumn<String>(
    'processing_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('proprio'),
  );
  static const VerificationMeta _thirdPartyCertNumberMeta =
      const VerificationMeta('thirdPartyCertNumber');
  @override
  late final GeneratedColumn<String> thirdPartyCertNumber =
      GeneratedColumn<String>(
        'third_party_cert_number',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _siVerificationMeta = const VerificationMeta(
    'siVerification',
  );
  @override
  late final GeneratedColumn<bool> siVerification = GeneratedColumn<bool>(
    'si_verification',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("si_verification" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _latitudeTextMeta = const VerificationMeta(
    'latitudeText',
  );
  @override
  late final GeneratedColumn<String> latitudeText = GeneratedColumn<String>(
    'latitude_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _longitudeTextMeta = const VerificationMeta(
    'longitudeText',
  );
  @override
  late final GeneratedColumn<String> longitudeText = GeneratedColumn<String>(
    'longitude_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _manipulationSiteAddressMeta =
      const VerificationMeta('manipulationSiteAddress');
  @override
  late final GeneratedColumn<String> manipulationSiteAddress =
      GeneratedColumn<String>(
        'manipulation_site_address',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _peakPeriodFromMeta = const VerificationMeta(
    'peakPeriodFrom',
  );
  @override
  late final GeneratedColumn<String> peakPeriodFrom = GeneratedColumn<String>(
    'peak_period_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _peakPeriodToMeta = const VerificationMeta(
    'peakPeriodTo',
  );
  @override
  late final GeneratedColumn<String> peakPeriodTo = GeneratedColumn<String>(
    'peak_period_to',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isJointVisitMeta = const VerificationMeta(
    'isJointVisit',
  );
  @override
  late final GeneratedColumn<bool> isJointVisit = GeneratedColumn<bool>(
    'is_joint_visit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_joint_visit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _jointVisitDetailsMeta = const VerificationMeta(
    'jointVisitDetails',
  );
  @override
  late final GeneratedColumn<String> jointVisitDetails =
      GeneratedColumn<String>(
        'joint_visit_details',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _marchioNatureMeta = const VerificationMeta(
    'marchioNature',
  );
  @override
  late final GeneratedColumn<String> marchioNature = GeneratedColumn<String>(
    'marchio_nature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _marchioProcessesMeta = const VerificationMeta(
    'marchioProcesses',
  );
  @override
  late final GeneratedColumn<String> marchioProcesses = GeneratedColumn<String>(
    'marchio_processes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _marchioLabelDraftMeta = const VerificationMeta(
    'marchioLabelDraft',
  );
  @override
  late final GeneratedColumn<bool> marchioLabelDraft = GeneratedColumn<bool>(
    'marchio_label_draft',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("marchio_label_draft" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    visitId,
    ragioneSociale,
    cuaa,
    partitaIva,
    indirizzo,
    cap,
    comune,
    provincia,
    referente,
    telefono,
    email,
    pec,
    submissionNumber,
    updatedAt,
    latitude,
    longitude,
    isSynced,
    isNewOperator,
    processingType,
    thirdPartyCertNumber,
    siVerification,
    latitudeText,
    longitudeText,
    manipulationSiteAddress,
    peakPeriodFrom,
    peakPeriodTo,
    isJointVisit,
    jointVisitDetails,
    marchioNature,
    marchioProcesses,
    marchioLabelDraft,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitCompany> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('ragione_sociale')) {
      context.handle(
        _ragioneSocialeMeta,
        ragioneSociale.isAcceptableOrUnknown(
          data['ragione_sociale']!,
          _ragioneSocialeMeta,
        ),
      );
    }
    if (data.containsKey('cuaa')) {
      context.handle(
        _cuaaMeta,
        cuaa.isAcceptableOrUnknown(data['cuaa']!, _cuaaMeta),
      );
    }
    if (data.containsKey('partita_iva')) {
      context.handle(
        _partitaIvaMeta,
        partitaIva.isAcceptableOrUnknown(data['partita_iva']!, _partitaIvaMeta),
      );
    }
    if (data.containsKey('indirizzo')) {
      context.handle(
        _indirizzoMeta,
        indirizzo.isAcceptableOrUnknown(data['indirizzo']!, _indirizzoMeta),
      );
    }
    if (data.containsKey('cap')) {
      context.handle(
        _capMeta,
        cap.isAcceptableOrUnknown(data['cap']!, _capMeta),
      );
    }
    if (data.containsKey('comune')) {
      context.handle(
        _comuneMeta,
        comune.isAcceptableOrUnknown(data['comune']!, _comuneMeta),
      );
    }
    if (data.containsKey('provincia')) {
      context.handle(
        _provinciaMeta,
        provincia.isAcceptableOrUnknown(data['provincia']!, _provinciaMeta),
      );
    }
    if (data.containsKey('referente')) {
      context.handle(
        _referenteMeta,
        referente.isAcceptableOrUnknown(data['referente']!, _referenteMeta),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('pec')) {
      context.handle(
        _pecMeta,
        pec.isAcceptableOrUnknown(data['pec']!, _pecMeta),
      );
    }
    if (data.containsKey('submission_number')) {
      context.handle(
        _submissionNumberMeta,
        submissionNumber.isAcceptableOrUnknown(
          data['submission_number']!,
          _submissionNumberMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_new_operator')) {
      context.handle(
        _isNewOperatorMeta,
        isNewOperator.isAcceptableOrUnknown(
          data['is_new_operator']!,
          _isNewOperatorMeta,
        ),
      );
    }
    if (data.containsKey('processing_type')) {
      context.handle(
        _processingTypeMeta,
        processingType.isAcceptableOrUnknown(
          data['processing_type']!,
          _processingTypeMeta,
        ),
      );
    }
    if (data.containsKey('third_party_cert_number')) {
      context.handle(
        _thirdPartyCertNumberMeta,
        thirdPartyCertNumber.isAcceptableOrUnknown(
          data['third_party_cert_number']!,
          _thirdPartyCertNumberMeta,
        ),
      );
    }
    if (data.containsKey('si_verification')) {
      context.handle(
        _siVerificationMeta,
        siVerification.isAcceptableOrUnknown(
          data['si_verification']!,
          _siVerificationMeta,
        ),
      );
    }
    if (data.containsKey('latitude_text')) {
      context.handle(
        _latitudeTextMeta,
        latitudeText.isAcceptableOrUnknown(
          data['latitude_text']!,
          _latitudeTextMeta,
        ),
      );
    }
    if (data.containsKey('longitude_text')) {
      context.handle(
        _longitudeTextMeta,
        longitudeText.isAcceptableOrUnknown(
          data['longitude_text']!,
          _longitudeTextMeta,
        ),
      );
    }
    if (data.containsKey('manipulation_site_address')) {
      context.handle(
        _manipulationSiteAddressMeta,
        manipulationSiteAddress.isAcceptableOrUnknown(
          data['manipulation_site_address']!,
          _manipulationSiteAddressMeta,
        ),
      );
    }
    if (data.containsKey('peak_period_from')) {
      context.handle(
        _peakPeriodFromMeta,
        peakPeriodFrom.isAcceptableOrUnknown(
          data['peak_period_from']!,
          _peakPeriodFromMeta,
        ),
      );
    }
    if (data.containsKey('peak_period_to')) {
      context.handle(
        _peakPeriodToMeta,
        peakPeriodTo.isAcceptableOrUnknown(
          data['peak_period_to']!,
          _peakPeriodToMeta,
        ),
      );
    }
    if (data.containsKey('is_joint_visit')) {
      context.handle(
        _isJointVisitMeta,
        isJointVisit.isAcceptableOrUnknown(
          data['is_joint_visit']!,
          _isJointVisitMeta,
        ),
      );
    }
    if (data.containsKey('joint_visit_details')) {
      context.handle(
        _jointVisitDetailsMeta,
        jointVisitDetails.isAcceptableOrUnknown(
          data['joint_visit_details']!,
          _jointVisitDetailsMeta,
        ),
      );
    }
    if (data.containsKey('marchio_nature')) {
      context.handle(
        _marchioNatureMeta,
        marchioNature.isAcceptableOrUnknown(
          data['marchio_nature']!,
          _marchioNatureMeta,
        ),
      );
    }
    if (data.containsKey('marchio_processes')) {
      context.handle(
        _marchioProcessesMeta,
        marchioProcesses.isAcceptableOrUnknown(
          data['marchio_processes']!,
          _marchioProcessesMeta,
        ),
      );
    }
    if (data.containsKey('marchio_label_draft')) {
      context.handle(
        _marchioLabelDraftMeta,
        marchioLabelDraft.isAcceptableOrUnknown(
          data['marchio_label_draft']!,
          _marchioLabelDraftMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId};
  @override
  VisitCompany map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitCompany(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      ragioneSociale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ragione_sociale'],
      )!,
      cuaa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuaa'],
      )!,
      partitaIva: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partita_iva'],
      )!,
      indirizzo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}indirizzo'],
      )!,
      cap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cap'],
      )!,
      comune: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comune'],
      )!,
      provincia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provincia'],
      )!,
      referente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referente'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      pec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pec'],
      )!,
      submissionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submission_number'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isNewOperator: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_new_operator'],
      )!,
      processingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_type'],
      )!,
      thirdPartyCertNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}third_party_cert_number'],
      )!,
      siVerification: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}si_verification'],
      )!,
      latitudeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latitude_text'],
      )!,
      longitudeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}longitude_text'],
      )!,
      manipulationSiteAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manipulation_site_address'],
      )!,
      peakPeriodFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peak_period_from'],
      )!,
      peakPeriodTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peak_period_to'],
      )!,
      isJointVisit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_joint_visit'],
      )!,
      jointVisitDetails: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joint_visit_details'],
      )!,
      marchioNature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marchio_nature'],
      )!,
      marchioProcesses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marchio_processes'],
      )!,
      marchioLabelDraft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}marchio_label_draft'],
      )!,
    );
  }

  @override
  $VisitCompaniesTable createAlias(String alias) {
    return $VisitCompaniesTable(attachedDatabase, alias);
  }
}

class VisitCompany extends DataClass implements Insertable<VisitCompany> {
  final String visitId;
  final String ragioneSociale;
  final String cuaa;
  final String partitaIva;
  final String indirizzo;
  final String cap;
  final String comune;
  final String provincia;
  final String referente;
  final String telefono;
  final String email;
  final String pec;
  final String submissionNumber;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final bool isSynced;
  final bool isNewOperator;
  final String processingType;
  final String thirdPartyCertNumber;
  final bool siVerification;
  final String latitudeText;
  final String longitudeText;
  final String manipulationSiteAddress;
  final String peakPeriodFrom;
  final String peakPeriodTo;
  final bool isJointVisit;
  final String jointVisitDetails;
  final String marchioNature;
  final String marchioProcesses;
  final bool marchioLabelDraft;
  const VisitCompany({
    required this.visitId,
    required this.ragioneSociale,
    required this.cuaa,
    required this.partitaIva,
    required this.indirizzo,
    required this.cap,
    required this.comune,
    required this.provincia,
    required this.referente,
    required this.telefono,
    required this.email,
    required this.pec,
    required this.submissionNumber,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    required this.isSynced,
    required this.isNewOperator,
    required this.processingType,
    required this.thirdPartyCertNumber,
    required this.siVerification,
    required this.latitudeText,
    required this.longitudeText,
    required this.manipulationSiteAddress,
    required this.peakPeriodFrom,
    required this.peakPeriodTo,
    required this.isJointVisit,
    required this.jointVisitDetails,
    required this.marchioNature,
    required this.marchioProcesses,
    required this.marchioLabelDraft,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['ragione_sociale'] = Variable<String>(ragioneSociale);
    map['cuaa'] = Variable<String>(cuaa);
    map['partita_iva'] = Variable<String>(partitaIva);
    map['indirizzo'] = Variable<String>(indirizzo);
    map['cap'] = Variable<String>(cap);
    map['comune'] = Variable<String>(comune);
    map['provincia'] = Variable<String>(provincia);
    map['referente'] = Variable<String>(referente);
    map['telefono'] = Variable<String>(telefono);
    map['email'] = Variable<String>(email);
    map['pec'] = Variable<String>(pec);
    map['submission_number'] = Variable<String>(submissionNumber);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_new_operator'] = Variable<bool>(isNewOperator);
    map['processing_type'] = Variable<String>(processingType);
    map['third_party_cert_number'] = Variable<String>(thirdPartyCertNumber);
    map['si_verification'] = Variable<bool>(siVerification);
    map['latitude_text'] = Variable<String>(latitudeText);
    map['longitude_text'] = Variable<String>(longitudeText);
    map['manipulation_site_address'] = Variable<String>(
      manipulationSiteAddress,
    );
    map['peak_period_from'] = Variable<String>(peakPeriodFrom);
    map['peak_period_to'] = Variable<String>(peakPeriodTo);
    map['is_joint_visit'] = Variable<bool>(isJointVisit);
    map['joint_visit_details'] = Variable<String>(jointVisitDetails);
    map['marchio_nature'] = Variable<String>(marchioNature);
    map['marchio_processes'] = Variable<String>(marchioProcesses);
    map['marchio_label_draft'] = Variable<bool>(marchioLabelDraft);
    return map;
  }

  VisitCompaniesCompanion toCompanion(bool nullToAbsent) {
    return VisitCompaniesCompanion(
      visitId: Value(visitId),
      ragioneSociale: Value(ragioneSociale),
      cuaa: Value(cuaa),
      partitaIva: Value(partitaIva),
      indirizzo: Value(indirizzo),
      cap: Value(cap),
      comune: Value(comune),
      provincia: Value(provincia),
      referente: Value(referente),
      telefono: Value(telefono),
      email: Value(email),
      pec: Value(pec),
      submissionNumber: Value(submissionNumber),
      updatedAt: Value(updatedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isSynced: Value(isSynced),
      isNewOperator: Value(isNewOperator),
      processingType: Value(processingType),
      thirdPartyCertNumber: Value(thirdPartyCertNumber),
      siVerification: Value(siVerification),
      latitudeText: Value(latitudeText),
      longitudeText: Value(longitudeText),
      manipulationSiteAddress: Value(manipulationSiteAddress),
      peakPeriodFrom: Value(peakPeriodFrom),
      peakPeriodTo: Value(peakPeriodTo),
      isJointVisit: Value(isJointVisit),
      jointVisitDetails: Value(jointVisitDetails),
      marchioNature: Value(marchioNature),
      marchioProcesses: Value(marchioProcesses),
      marchioLabelDraft: Value(marchioLabelDraft),
    );
  }

  factory VisitCompany.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitCompany(
      visitId: serializer.fromJson<String>(json['visitId']),
      ragioneSociale: serializer.fromJson<String>(json['ragioneSociale']),
      cuaa: serializer.fromJson<String>(json['cuaa']),
      partitaIva: serializer.fromJson<String>(json['partitaIva']),
      indirizzo: serializer.fromJson<String>(json['indirizzo']),
      cap: serializer.fromJson<String>(json['cap']),
      comune: serializer.fromJson<String>(json['comune']),
      provincia: serializer.fromJson<String>(json['provincia']),
      referente: serializer.fromJson<String>(json['referente']),
      telefono: serializer.fromJson<String>(json['telefono']),
      email: serializer.fromJson<String>(json['email']),
      pec: serializer.fromJson<String>(json['pec']),
      submissionNumber: serializer.fromJson<String>(json['submissionNumber']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isNewOperator: serializer.fromJson<bool>(json['isNewOperator']),
      processingType: serializer.fromJson<String>(json['processingType']),
      thirdPartyCertNumber: serializer.fromJson<String>(
        json['thirdPartyCertNumber'],
      ),
      siVerification: serializer.fromJson<bool>(json['siVerification']),
      latitudeText: serializer.fromJson<String>(json['latitudeText']),
      longitudeText: serializer.fromJson<String>(json['longitudeText']),
      manipulationSiteAddress: serializer.fromJson<String>(
        json['manipulationSiteAddress'],
      ),
      peakPeriodFrom: serializer.fromJson<String>(json['peakPeriodFrom']),
      peakPeriodTo: serializer.fromJson<String>(json['peakPeriodTo']),
      isJointVisit: serializer.fromJson<bool>(json['isJointVisit']),
      jointVisitDetails: serializer.fromJson<String>(json['jointVisitDetails']),
      marchioNature: serializer.fromJson<String>(json['marchioNature']),
      marchioProcesses: serializer.fromJson<String>(json['marchioProcesses']),
      marchioLabelDraft: serializer.fromJson<bool>(json['marchioLabelDraft']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visitId': serializer.toJson<String>(visitId),
      'ragioneSociale': serializer.toJson<String>(ragioneSociale),
      'cuaa': serializer.toJson<String>(cuaa),
      'partitaIva': serializer.toJson<String>(partitaIva),
      'indirizzo': serializer.toJson<String>(indirizzo),
      'cap': serializer.toJson<String>(cap),
      'comune': serializer.toJson<String>(comune),
      'provincia': serializer.toJson<String>(provincia),
      'referente': serializer.toJson<String>(referente),
      'telefono': serializer.toJson<String>(telefono),
      'email': serializer.toJson<String>(email),
      'pec': serializer.toJson<String>(pec),
      'submissionNumber': serializer.toJson<String>(submissionNumber),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isNewOperator': serializer.toJson<bool>(isNewOperator),
      'processingType': serializer.toJson<String>(processingType),
      'thirdPartyCertNumber': serializer.toJson<String>(thirdPartyCertNumber),
      'siVerification': serializer.toJson<bool>(siVerification),
      'latitudeText': serializer.toJson<String>(latitudeText),
      'longitudeText': serializer.toJson<String>(longitudeText),
      'manipulationSiteAddress': serializer.toJson<String>(
        manipulationSiteAddress,
      ),
      'peakPeriodFrom': serializer.toJson<String>(peakPeriodFrom),
      'peakPeriodTo': serializer.toJson<String>(peakPeriodTo),
      'isJointVisit': serializer.toJson<bool>(isJointVisit),
      'jointVisitDetails': serializer.toJson<String>(jointVisitDetails),
      'marchioNature': serializer.toJson<String>(marchioNature),
      'marchioProcesses': serializer.toJson<String>(marchioProcesses),
      'marchioLabelDraft': serializer.toJson<bool>(marchioLabelDraft),
    };
  }

  VisitCompany copyWith({
    String? visitId,
    String? ragioneSociale,
    String? cuaa,
    String? partitaIva,
    String? indirizzo,
    String? cap,
    String? comune,
    String? provincia,
    String? referente,
    String? telefono,
    String? email,
    String? pec,
    String? submissionNumber,
    DateTime? updatedAt,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    bool? isSynced,
    bool? isNewOperator,
    String? processingType,
    String? thirdPartyCertNumber,
    bool? siVerification,
    String? latitudeText,
    String? longitudeText,
    String? manipulationSiteAddress,
    String? peakPeriodFrom,
    String? peakPeriodTo,
    bool? isJointVisit,
    String? jointVisitDetails,
    String? marchioNature,
    String? marchioProcesses,
    bool? marchioLabelDraft,
  }) => VisitCompany(
    visitId: visitId ?? this.visitId,
    ragioneSociale: ragioneSociale ?? this.ragioneSociale,
    cuaa: cuaa ?? this.cuaa,
    partitaIva: partitaIva ?? this.partitaIva,
    indirizzo: indirizzo ?? this.indirizzo,
    cap: cap ?? this.cap,
    comune: comune ?? this.comune,
    provincia: provincia ?? this.provincia,
    referente: referente ?? this.referente,
    telefono: telefono ?? this.telefono,
    email: email ?? this.email,
    pec: pec ?? this.pec,
    submissionNumber: submissionNumber ?? this.submissionNumber,
    updatedAt: updatedAt ?? this.updatedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    isSynced: isSynced ?? this.isSynced,
    isNewOperator: isNewOperator ?? this.isNewOperator,
    processingType: processingType ?? this.processingType,
    thirdPartyCertNumber: thirdPartyCertNumber ?? this.thirdPartyCertNumber,
    siVerification: siVerification ?? this.siVerification,
    latitudeText: latitudeText ?? this.latitudeText,
    longitudeText: longitudeText ?? this.longitudeText,
    manipulationSiteAddress:
        manipulationSiteAddress ?? this.manipulationSiteAddress,
    peakPeriodFrom: peakPeriodFrom ?? this.peakPeriodFrom,
    peakPeriodTo: peakPeriodTo ?? this.peakPeriodTo,
    isJointVisit: isJointVisit ?? this.isJointVisit,
    jointVisitDetails: jointVisitDetails ?? this.jointVisitDetails,
    marchioNature: marchioNature ?? this.marchioNature,
    marchioProcesses: marchioProcesses ?? this.marchioProcesses,
    marchioLabelDraft: marchioLabelDraft ?? this.marchioLabelDraft,
  );
  VisitCompany copyWithCompanion(VisitCompaniesCompanion data) {
    return VisitCompany(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      ragioneSociale: data.ragioneSociale.present
          ? data.ragioneSociale.value
          : this.ragioneSociale,
      cuaa: data.cuaa.present ? data.cuaa.value : this.cuaa,
      partitaIva: data.partitaIva.present
          ? data.partitaIva.value
          : this.partitaIva,
      indirizzo: data.indirizzo.present ? data.indirizzo.value : this.indirizzo,
      cap: data.cap.present ? data.cap.value : this.cap,
      comune: data.comune.present ? data.comune.value : this.comune,
      provincia: data.provincia.present ? data.provincia.value : this.provincia,
      referente: data.referente.present ? data.referente.value : this.referente,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      email: data.email.present ? data.email.value : this.email,
      pec: data.pec.present ? data.pec.value : this.pec,
      submissionNumber: data.submissionNumber.present
          ? data.submissionNumber.value
          : this.submissionNumber,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isNewOperator: data.isNewOperator.present
          ? data.isNewOperator.value
          : this.isNewOperator,
      processingType: data.processingType.present
          ? data.processingType.value
          : this.processingType,
      thirdPartyCertNumber: data.thirdPartyCertNumber.present
          ? data.thirdPartyCertNumber.value
          : this.thirdPartyCertNumber,
      siVerification: data.siVerification.present
          ? data.siVerification.value
          : this.siVerification,
      latitudeText: data.latitudeText.present
          ? data.latitudeText.value
          : this.latitudeText,
      longitudeText: data.longitudeText.present
          ? data.longitudeText.value
          : this.longitudeText,
      manipulationSiteAddress: data.manipulationSiteAddress.present
          ? data.manipulationSiteAddress.value
          : this.manipulationSiteAddress,
      peakPeriodFrom: data.peakPeriodFrom.present
          ? data.peakPeriodFrom.value
          : this.peakPeriodFrom,
      peakPeriodTo: data.peakPeriodTo.present
          ? data.peakPeriodTo.value
          : this.peakPeriodTo,
      isJointVisit: data.isJointVisit.present
          ? data.isJointVisit.value
          : this.isJointVisit,
      jointVisitDetails: data.jointVisitDetails.present
          ? data.jointVisitDetails.value
          : this.jointVisitDetails,
      marchioNature: data.marchioNature.present
          ? data.marchioNature.value
          : this.marchioNature,
      marchioProcesses: data.marchioProcesses.present
          ? data.marchioProcesses.value
          : this.marchioProcesses,
      marchioLabelDraft: data.marchioLabelDraft.present
          ? data.marchioLabelDraft.value
          : this.marchioLabelDraft,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitCompany(')
          ..write('visitId: $visitId, ')
          ..write('ragioneSociale: $ragioneSociale, ')
          ..write('cuaa: $cuaa, ')
          ..write('partitaIva: $partitaIva, ')
          ..write('indirizzo: $indirizzo, ')
          ..write('cap: $cap, ')
          ..write('comune: $comune, ')
          ..write('provincia: $provincia, ')
          ..write('referente: $referente, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('pec: $pec, ')
          ..write('submissionNumber: $submissionNumber, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isSynced: $isSynced, ')
          ..write('isNewOperator: $isNewOperator, ')
          ..write('processingType: $processingType, ')
          ..write('thirdPartyCertNumber: $thirdPartyCertNumber, ')
          ..write('siVerification: $siVerification, ')
          ..write('latitudeText: $latitudeText, ')
          ..write('longitudeText: $longitudeText, ')
          ..write('manipulationSiteAddress: $manipulationSiteAddress, ')
          ..write('peakPeriodFrom: $peakPeriodFrom, ')
          ..write('peakPeriodTo: $peakPeriodTo, ')
          ..write('isJointVisit: $isJointVisit, ')
          ..write('jointVisitDetails: $jointVisitDetails, ')
          ..write('marchioNature: $marchioNature, ')
          ..write('marchioProcesses: $marchioProcesses, ')
          ..write('marchioLabelDraft: $marchioLabelDraft')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    visitId,
    ragioneSociale,
    cuaa,
    partitaIva,
    indirizzo,
    cap,
    comune,
    provincia,
    referente,
    telefono,
    email,
    pec,
    submissionNumber,
    updatedAt,
    latitude,
    longitude,
    isSynced,
    isNewOperator,
    processingType,
    thirdPartyCertNumber,
    siVerification,
    latitudeText,
    longitudeText,
    manipulationSiteAddress,
    peakPeriodFrom,
    peakPeriodTo,
    isJointVisit,
    jointVisitDetails,
    marchioNature,
    marchioProcesses,
    marchioLabelDraft,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitCompany &&
          other.visitId == this.visitId &&
          other.ragioneSociale == this.ragioneSociale &&
          other.cuaa == this.cuaa &&
          other.partitaIva == this.partitaIva &&
          other.indirizzo == this.indirizzo &&
          other.cap == this.cap &&
          other.comune == this.comune &&
          other.provincia == this.provincia &&
          other.referente == this.referente &&
          other.telefono == this.telefono &&
          other.email == this.email &&
          other.pec == this.pec &&
          other.submissionNumber == this.submissionNumber &&
          other.updatedAt == this.updatedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isSynced == this.isSynced &&
          other.isNewOperator == this.isNewOperator &&
          other.processingType == this.processingType &&
          other.thirdPartyCertNumber == this.thirdPartyCertNumber &&
          other.siVerification == this.siVerification &&
          other.latitudeText == this.latitudeText &&
          other.longitudeText == this.longitudeText &&
          other.manipulationSiteAddress == this.manipulationSiteAddress &&
          other.peakPeriodFrom == this.peakPeriodFrom &&
          other.peakPeriodTo == this.peakPeriodTo &&
          other.isJointVisit == this.isJointVisit &&
          other.jointVisitDetails == this.jointVisitDetails &&
          other.marchioNature == this.marchioNature &&
          other.marchioProcesses == this.marchioProcesses &&
          other.marchioLabelDraft == this.marchioLabelDraft);
}

class VisitCompaniesCompanion extends UpdateCompanion<VisitCompany> {
  final Value<String> visitId;
  final Value<String> ragioneSociale;
  final Value<String> cuaa;
  final Value<String> partitaIva;
  final Value<String> indirizzo;
  final Value<String> cap;
  final Value<String> comune;
  final Value<String> provincia;
  final Value<String> referente;
  final Value<String> telefono;
  final Value<String> email;
  final Value<String> pec;
  final Value<String> submissionNumber;
  final Value<DateTime> updatedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isSynced;
  final Value<bool> isNewOperator;
  final Value<String> processingType;
  final Value<String> thirdPartyCertNumber;
  final Value<bool> siVerification;
  final Value<String> latitudeText;
  final Value<String> longitudeText;
  final Value<String> manipulationSiteAddress;
  final Value<String> peakPeriodFrom;
  final Value<String> peakPeriodTo;
  final Value<bool> isJointVisit;
  final Value<String> jointVisitDetails;
  final Value<String> marchioNature;
  final Value<String> marchioProcesses;
  final Value<bool> marchioLabelDraft;
  final Value<int> rowid;
  const VisitCompaniesCompanion({
    this.visitId = const Value.absent(),
    this.ragioneSociale = const Value.absent(),
    this.cuaa = const Value.absent(),
    this.partitaIva = const Value.absent(),
    this.indirizzo = const Value.absent(),
    this.cap = const Value.absent(),
    this.comune = const Value.absent(),
    this.provincia = const Value.absent(),
    this.referente = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.pec = const Value.absent(),
    this.submissionNumber = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isNewOperator = const Value.absent(),
    this.processingType = const Value.absent(),
    this.thirdPartyCertNumber = const Value.absent(),
    this.siVerification = const Value.absent(),
    this.latitudeText = const Value.absent(),
    this.longitudeText = const Value.absent(),
    this.manipulationSiteAddress = const Value.absent(),
    this.peakPeriodFrom = const Value.absent(),
    this.peakPeriodTo = const Value.absent(),
    this.isJointVisit = const Value.absent(),
    this.jointVisitDetails = const Value.absent(),
    this.marchioNature = const Value.absent(),
    this.marchioProcesses = const Value.absent(),
    this.marchioLabelDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitCompaniesCompanion.insert({
    required String visitId,
    this.ragioneSociale = const Value.absent(),
    this.cuaa = const Value.absent(),
    this.partitaIva = const Value.absent(),
    this.indirizzo = const Value.absent(),
    this.cap = const Value.absent(),
    this.comune = const Value.absent(),
    this.provincia = const Value.absent(),
    this.referente = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.pec = const Value.absent(),
    this.submissionNumber = const Value.absent(),
    required DateTime updatedAt,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isNewOperator = const Value.absent(),
    this.processingType = const Value.absent(),
    this.thirdPartyCertNumber = const Value.absent(),
    this.siVerification = const Value.absent(),
    this.latitudeText = const Value.absent(),
    this.longitudeText = const Value.absent(),
    this.manipulationSiteAddress = const Value.absent(),
    this.peakPeriodFrom = const Value.absent(),
    this.peakPeriodTo = const Value.absent(),
    this.isJointVisit = const Value.absent(),
    this.jointVisitDetails = const Value.absent(),
    this.marchioNature = const Value.absent(),
    this.marchioProcesses = const Value.absent(),
    this.marchioLabelDraft = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       updatedAt = Value(updatedAt);
  static Insertable<VisitCompany> custom({
    Expression<String>? visitId,
    Expression<String>? ragioneSociale,
    Expression<String>? cuaa,
    Expression<String>? partitaIva,
    Expression<String>? indirizzo,
    Expression<String>? cap,
    Expression<String>? comune,
    Expression<String>? provincia,
    Expression<String>? referente,
    Expression<String>? telefono,
    Expression<String>? email,
    Expression<String>? pec,
    Expression<String>? submissionNumber,
    Expression<DateTime>? updatedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isSynced,
    Expression<bool>? isNewOperator,
    Expression<String>? processingType,
    Expression<String>? thirdPartyCertNumber,
    Expression<bool>? siVerification,
    Expression<String>? latitudeText,
    Expression<String>? longitudeText,
    Expression<String>? manipulationSiteAddress,
    Expression<String>? peakPeriodFrom,
    Expression<String>? peakPeriodTo,
    Expression<bool>? isJointVisit,
    Expression<String>? jointVisitDetails,
    Expression<String>? marchioNature,
    Expression<String>? marchioProcesses,
    Expression<bool>? marchioLabelDraft,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (ragioneSociale != null) 'ragione_sociale': ragioneSociale,
      if (cuaa != null) 'cuaa': cuaa,
      if (partitaIva != null) 'partita_iva': partitaIva,
      if (indirizzo != null) 'indirizzo': indirizzo,
      if (cap != null) 'cap': cap,
      if (comune != null) 'comune': comune,
      if (provincia != null) 'provincia': provincia,
      if (referente != null) 'referente': referente,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (pec != null) 'pec': pec,
      if (submissionNumber != null) 'submission_number': submissionNumber,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isSynced != null) 'is_synced': isSynced,
      if (isNewOperator != null) 'is_new_operator': isNewOperator,
      if (processingType != null) 'processing_type': processingType,
      if (thirdPartyCertNumber != null)
        'third_party_cert_number': thirdPartyCertNumber,
      if (siVerification != null) 'si_verification': siVerification,
      if (latitudeText != null) 'latitude_text': latitudeText,
      if (longitudeText != null) 'longitude_text': longitudeText,
      if (manipulationSiteAddress != null)
        'manipulation_site_address': manipulationSiteAddress,
      if (peakPeriodFrom != null) 'peak_period_from': peakPeriodFrom,
      if (peakPeriodTo != null) 'peak_period_to': peakPeriodTo,
      if (isJointVisit != null) 'is_joint_visit': isJointVisit,
      if (jointVisitDetails != null) 'joint_visit_details': jointVisitDetails,
      if (marchioNature != null) 'marchio_nature': marchioNature,
      if (marchioProcesses != null) 'marchio_processes': marchioProcesses,
      if (marchioLabelDraft != null) 'marchio_label_draft': marchioLabelDraft,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitCompaniesCompanion copyWith({
    Value<String>? visitId,
    Value<String>? ragioneSociale,
    Value<String>? cuaa,
    Value<String>? partitaIva,
    Value<String>? indirizzo,
    Value<String>? cap,
    Value<String>? comune,
    Value<String>? provincia,
    Value<String>? referente,
    Value<String>? telefono,
    Value<String>? email,
    Value<String>? pec,
    Value<String>? submissionNumber,
    Value<DateTime>? updatedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<bool>? isSynced,
    Value<bool>? isNewOperator,
    Value<String>? processingType,
    Value<String>? thirdPartyCertNumber,
    Value<bool>? siVerification,
    Value<String>? latitudeText,
    Value<String>? longitudeText,
    Value<String>? manipulationSiteAddress,
    Value<String>? peakPeriodFrom,
    Value<String>? peakPeriodTo,
    Value<bool>? isJointVisit,
    Value<String>? jointVisitDetails,
    Value<String>? marchioNature,
    Value<String>? marchioProcesses,
    Value<bool>? marchioLabelDraft,
    Value<int>? rowid,
  }) {
    return VisitCompaniesCompanion(
      visitId: visitId ?? this.visitId,
      ragioneSociale: ragioneSociale ?? this.ragioneSociale,
      cuaa: cuaa ?? this.cuaa,
      partitaIva: partitaIva ?? this.partitaIva,
      indirizzo: indirizzo ?? this.indirizzo,
      cap: cap ?? this.cap,
      comune: comune ?? this.comune,
      provincia: provincia ?? this.provincia,
      referente: referente ?? this.referente,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      pec: pec ?? this.pec,
      submissionNumber: submissionNumber ?? this.submissionNumber,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSynced: isSynced ?? this.isSynced,
      isNewOperator: isNewOperator ?? this.isNewOperator,
      processingType: processingType ?? this.processingType,
      thirdPartyCertNumber: thirdPartyCertNumber ?? this.thirdPartyCertNumber,
      siVerification: siVerification ?? this.siVerification,
      latitudeText: latitudeText ?? this.latitudeText,
      longitudeText: longitudeText ?? this.longitudeText,
      manipulationSiteAddress:
          manipulationSiteAddress ?? this.manipulationSiteAddress,
      peakPeriodFrom: peakPeriodFrom ?? this.peakPeriodFrom,
      peakPeriodTo: peakPeriodTo ?? this.peakPeriodTo,
      isJointVisit: isJointVisit ?? this.isJointVisit,
      jointVisitDetails: jointVisitDetails ?? this.jointVisitDetails,
      marchioNature: marchioNature ?? this.marchioNature,
      marchioProcesses: marchioProcesses ?? this.marchioProcesses,
      marchioLabelDraft: marchioLabelDraft ?? this.marchioLabelDraft,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (ragioneSociale.present) {
      map['ragione_sociale'] = Variable<String>(ragioneSociale.value);
    }
    if (cuaa.present) {
      map['cuaa'] = Variable<String>(cuaa.value);
    }
    if (partitaIva.present) {
      map['partita_iva'] = Variable<String>(partitaIva.value);
    }
    if (indirizzo.present) {
      map['indirizzo'] = Variable<String>(indirizzo.value);
    }
    if (cap.present) {
      map['cap'] = Variable<String>(cap.value);
    }
    if (comune.present) {
      map['comune'] = Variable<String>(comune.value);
    }
    if (provincia.present) {
      map['provincia'] = Variable<String>(provincia.value);
    }
    if (referente.present) {
      map['referente'] = Variable<String>(referente.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (pec.present) {
      map['pec'] = Variable<String>(pec.value);
    }
    if (submissionNumber.present) {
      map['submission_number'] = Variable<String>(submissionNumber.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isNewOperator.present) {
      map['is_new_operator'] = Variable<bool>(isNewOperator.value);
    }
    if (processingType.present) {
      map['processing_type'] = Variable<String>(processingType.value);
    }
    if (thirdPartyCertNumber.present) {
      map['third_party_cert_number'] = Variable<String>(
        thirdPartyCertNumber.value,
      );
    }
    if (siVerification.present) {
      map['si_verification'] = Variable<bool>(siVerification.value);
    }
    if (latitudeText.present) {
      map['latitude_text'] = Variable<String>(latitudeText.value);
    }
    if (longitudeText.present) {
      map['longitude_text'] = Variable<String>(longitudeText.value);
    }
    if (manipulationSiteAddress.present) {
      map['manipulation_site_address'] = Variable<String>(
        manipulationSiteAddress.value,
      );
    }
    if (peakPeriodFrom.present) {
      map['peak_period_from'] = Variable<String>(peakPeriodFrom.value);
    }
    if (peakPeriodTo.present) {
      map['peak_period_to'] = Variable<String>(peakPeriodTo.value);
    }
    if (isJointVisit.present) {
      map['is_joint_visit'] = Variable<bool>(isJointVisit.value);
    }
    if (jointVisitDetails.present) {
      map['joint_visit_details'] = Variable<String>(jointVisitDetails.value);
    }
    if (marchioNature.present) {
      map['marchio_nature'] = Variable<String>(marchioNature.value);
    }
    if (marchioProcesses.present) {
      map['marchio_processes'] = Variable<String>(marchioProcesses.value);
    }
    if (marchioLabelDraft.present) {
      map['marchio_label_draft'] = Variable<bool>(marchioLabelDraft.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitCompaniesCompanion(')
          ..write('visitId: $visitId, ')
          ..write('ragioneSociale: $ragioneSociale, ')
          ..write('cuaa: $cuaa, ')
          ..write('partitaIva: $partitaIva, ')
          ..write('indirizzo: $indirizzo, ')
          ..write('cap: $cap, ')
          ..write('comune: $comune, ')
          ..write('provincia: $provincia, ')
          ..write('referente: $referente, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('pec: $pec, ')
          ..write('submissionNumber: $submissionNumber, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isSynced: $isSynced, ')
          ..write('isNewOperator: $isNewOperator, ')
          ..write('processingType: $processingType, ')
          ..write('thirdPartyCertNumber: $thirdPartyCertNumber, ')
          ..write('siVerification: $siVerification, ')
          ..write('latitudeText: $latitudeText, ')
          ..write('longitudeText: $longitudeText, ')
          ..write('manipulationSiteAddress: $manipulationSiteAddress, ')
          ..write('peakPeriodFrom: $peakPeriodFrom, ')
          ..write('peakPeriodTo: $peakPeriodTo, ')
          ..write('isJointVisit: $isJointVisit, ')
          ..write('jointVisitDetails: $jointVisitDetails, ')
          ..write('marchioNature: $marchioNature, ')
          ..write('marchioProcesses: $marchioProcesses, ')
          ..write('marchioLabelDraft: $marchioLabelDraft, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitUecsTable extends VisitUecs
    with TableInfo<$VisitUecsTable, VisitUec> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitUecsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _colturaMeta = const VerificationMeta(
    'coltura',
  );
  @override
  late final GeneratedColumn<String> coltura = GeneratedColumn<String>(
    'coltura',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descrizioneMeta = const VerificationMeta(
    'descrizione',
  );
  @override
  late final GeneratedColumn<String> descrizione = GeneratedColumn<String>(
    'descrizione',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    coltura,
    descrizione,
    note,
    latitude,
    longitude,
    photoPath,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_uecs';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitUec> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('coltura')) {
      context.handle(
        _colturaMeta,
        coltura.isAcceptableOrUnknown(data['coltura']!, _colturaMeta),
      );
    }
    if (data.containsKey('descrizione')) {
      context.handle(
        _descrizioneMeta,
        descrizione.isAcceptableOrUnknown(
          data['descrizione']!,
          _descrizioneMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitUec map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitUec(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      coltura: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coltura'],
      )!,
      descrizione: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descrizione'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VisitUecsTable createAlias(String alias) {
    return $VisitUecsTable(attachedDatabase, alias);
  }
}

class VisitUec extends DataClass implements Insertable<VisitUec> {
  final String id;
  final String visitId;
  final String coltura;
  final String descrizione;
  final String note;
  final double? latitude;
  final double? longitude;
  final String? photoPath;
  final DateTime updatedAt;
  const VisitUec({
    required this.id,
    required this.visitId,
    required this.coltura,
    required this.descrizione,
    required this.note,
    this.latitude,
    this.longitude,
    this.photoPath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['coltura'] = Variable<String>(coltura);
    map['descrizione'] = Variable<String>(descrizione);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitUecsCompanion toCompanion(bool nullToAbsent) {
    return VisitUecsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      coltura: Value(coltura),
      descrizione: Value(descrizione),
      note: Value(note),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory VisitUec.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitUec(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      coltura: serializer.fromJson<String>(json['coltura']),
      descrizione: serializer.fromJson<String>(json['descrizione']),
      note: serializer.fromJson<String>(json['note']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'coltura': serializer.toJson<String>(coltura),
      'descrizione': serializer.toJson<String>(descrizione),
      'note': serializer.toJson<String>(note),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'photoPath': serializer.toJson<String?>(photoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VisitUec copyWith({
    String? id,
    String? visitId,
    String? coltura,
    String? descrizione,
    String? note,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? updatedAt,
  }) => VisitUec(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    coltura: coltura ?? this.coltura,
    descrizione: descrizione ?? this.descrizione,
    note: note ?? this.note,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VisitUec copyWithCompanion(VisitUecsCompanion data) {
    return VisitUec(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      coltura: data.coltura.present ? data.coltura.value : this.coltura,
      descrizione: data.descrizione.present
          ? data.descrizione.value
          : this.descrizione,
      note: data.note.present ? data.note.value : this.note,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitUec(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('coltura: $coltura, ')
          ..write('descrizione: $descrizione, ')
          ..write('note: $note, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    coltura,
    descrizione,
    note,
    latitude,
    longitude,
    photoPath,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitUec &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.coltura == this.coltura &&
          other.descrizione == this.descrizione &&
          other.note == this.note &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.photoPath == this.photoPath &&
          other.updatedAt == this.updatedAt);
}

class VisitUecsCompanion extends UpdateCompanion<VisitUec> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> coltura;
  final Value<String> descrizione;
  final Value<String> note;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> photoPath;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitUecsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.coltura = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.note = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitUecsCompanion.insert({
    required String id,
    required String visitId,
    this.coltura = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.note = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       updatedAt = Value(updatedAt);
  static Insertable<VisitUec> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? coltura,
    Expression<String>? descrizione,
    Expression<String>? note,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? photoPath,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (coltura != null) 'coltura': coltura,
      if (descrizione != null) 'descrizione': descrizione,
      if (note != null) 'note': note,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoPath != null) 'photo_path': photoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitUecsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? coltura,
    Value<String>? descrizione,
    Value<String>? note,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? photoPath,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitUecsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      coltura: coltura ?? this.coltura,
      descrizione: descrizione ?? this.descrizione,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoPath: photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (coltura.present) {
      map['coltura'] = Variable<String>(coltura.value);
    }
    if (descrizione.present) {
      map['descrizione'] = Variable<String>(descrizione.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitUecsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('coltura: $coltura, ')
          ..write('descrizione: $descrizione, ')
          ..write('note: $note, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitLotsTable extends VisitLots
    with TableInfo<$VisitLotsTable, VisitLot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitLotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uecIdMeta = const VerificationMeta('uecId');
  @override
  late final GeneratedColumn<String> uecId = GeneratedColumn<String>(
    'uec_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visit_uecs(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _codiceMeta = const VerificationMeta('codice');
  @override
  late final GeneratedColumn<String> codice = GeneratedColumn<String>(
    'codice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantitaMeta = const VerificationMeta(
    'quantita',
  );
  @override
  late final GeneratedColumn<String> quantita = GeneratedColumn<String>(
    'quantita',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uecId,
    codice,
    quantita,
    note,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_lots';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitLot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uec_id')) {
      context.handle(
        _uecIdMeta,
        uecId.isAcceptableOrUnknown(data['uec_id']!, _uecIdMeta),
      );
    } else if (isInserting) {
      context.missing(_uecIdMeta);
    }
    if (data.containsKey('codice')) {
      context.handle(
        _codiceMeta,
        codice.isAcceptableOrUnknown(data['codice']!, _codiceMeta),
      );
    }
    if (data.containsKey('quantita')) {
      context.handle(
        _quantitaMeta,
        quantita.isAcceptableOrUnknown(data['quantita']!, _quantitaMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitLot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitLot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      uecId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uec_id'],
      )!,
      codice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codice'],
      )!,
      quantita: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantita'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VisitLotsTable createAlias(String alias) {
    return $VisitLotsTable(attachedDatabase, alias);
  }
}

class VisitLot extends DataClass implements Insertable<VisitLot> {
  final String id;
  final String uecId;
  final String codice;
  final String quantita;
  final String note;
  final DateTime updatedAt;
  const VisitLot({
    required this.id,
    required this.uecId,
    required this.codice,
    required this.quantita,
    required this.note,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['uec_id'] = Variable<String>(uecId);
    map['codice'] = Variable<String>(codice);
    map['quantita'] = Variable<String>(quantita);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitLotsCompanion toCompanion(bool nullToAbsent) {
    return VisitLotsCompanion(
      id: Value(id),
      uecId: Value(uecId),
      codice: Value(codice),
      quantita: Value(quantita),
      note: Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory VisitLot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitLot(
      id: serializer.fromJson<String>(json['id']),
      uecId: serializer.fromJson<String>(json['uecId']),
      codice: serializer.fromJson<String>(json['codice']),
      quantita: serializer.fromJson<String>(json['quantita']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'uecId': serializer.toJson<String>(uecId),
      'codice': serializer.toJson<String>(codice),
      'quantita': serializer.toJson<String>(quantita),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VisitLot copyWith({
    String? id,
    String? uecId,
    String? codice,
    String? quantita,
    String? note,
    DateTime? updatedAt,
  }) => VisitLot(
    id: id ?? this.id,
    uecId: uecId ?? this.uecId,
    codice: codice ?? this.codice,
    quantita: quantita ?? this.quantita,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VisitLot copyWithCompanion(VisitLotsCompanion data) {
    return VisitLot(
      id: data.id.present ? data.id.value : this.id,
      uecId: data.uecId.present ? data.uecId.value : this.uecId,
      codice: data.codice.present ? data.codice.value : this.codice,
      quantita: data.quantita.present ? data.quantita.value : this.quantita,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitLot(')
          ..write('id: $id, ')
          ..write('uecId: $uecId, ')
          ..write('codice: $codice, ')
          ..write('quantita: $quantita, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uecId, codice, quantita, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitLot &&
          other.id == this.id &&
          other.uecId == this.uecId &&
          other.codice == this.codice &&
          other.quantita == this.quantita &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class VisitLotsCompanion extends UpdateCompanion<VisitLot> {
  final Value<String> id;
  final Value<String> uecId;
  final Value<String> codice;
  final Value<String> quantita;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitLotsCompanion({
    this.id = const Value.absent(),
    this.uecId = const Value.absent(),
    this.codice = const Value.absent(),
    this.quantita = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitLotsCompanion.insert({
    required String id,
    required String uecId,
    this.codice = const Value.absent(),
    this.quantita = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       uecId = Value(uecId),
       updatedAt = Value(updatedAt);
  static Insertable<VisitLot> custom({
    Expression<String>? id,
    Expression<String>? uecId,
    Expression<String>? codice,
    Expression<String>? quantita,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uecId != null) 'uec_id': uecId,
      if (codice != null) 'codice': codice,
      if (quantita != null) 'quantita': quantita,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitLotsCompanion copyWith({
    Value<String>? id,
    Value<String>? uecId,
    Value<String>? codice,
    Value<String>? quantita,
    Value<String>? note,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitLotsCompanion(
      id: id ?? this.id,
      uecId: uecId ?? this.uecId,
      codice: codice ?? this.codice,
      quantita: quantita ?? this.quantita,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (uecId.present) {
      map['uec_id'] = Variable<String>(uecId.value);
    }
    if (codice.present) {
      map['codice'] = Variable<String>(codice.value);
    }
    if (quantita.present) {
      map['quantita'] = Variable<String>(quantita.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitLotsCompanion(')
          ..write('id: $id, ')
          ..write('uecId: $uecId, ')
          ..write('codice: $codice, ')
          ..write('quantita: $quantita, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faseMeta = const VerificationMeta('fase');
  @override
  late final GeneratedColumn<String> fase = GeneratedColumn<String>(
    'fase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _obbligoMeta = const VerificationMeta(
    'obbligo',
  );
  @override
  late final GeneratedColumn<String> obbligo = GeneratedColumn<String>(
    'obbligo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _indicatorTypeMeta = const VerificationMeta(
    'indicatorType',
  );
  @override
  late final GeneratedColumn<String> indicatorType = GeneratedColumn<String>(
    'indicator_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _derogheMeta = const VerificationMeta(
    'deroghe',
  );
  @override
  late final GeneratedColumn<String> deroghe = GeneratedColumn<String>(
    'deroghe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteNormaMeta = const VerificationMeta(
    'noteNorma',
  );
  @override
  late final GeneratedColumn<String> noteNorma = GeneratedColumn<String>(
    'note_norma',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tipologiaControlloMeta =
      const VerificationMeta('tipologiaControllo');
  @override
  late final GeneratedColumn<String> tipologiaControllo =
      GeneratedColumn<String>(
        'tipologia_controllo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _frequenzaSingoloMeta = const VerificationMeta(
    'frequenzaSingolo',
  );
  @override
  late final GeneratedColumn<String> frequenzaSingolo = GeneratedColumn<String>(
    'frequenza_singolo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _frequenzaAssociatoMeta =
      const VerificationMeta('frequenzaAssociato');
  @override
  late final GeneratedColumn<String> frequenzaAssociato =
      GeneratedColumn<String>(
        'frequenza_associato',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _gravitaUecTextMeta = const VerificationMeta(
    'gravitaUecText',
  );
  @override
  late final GeneratedColumn<String> gravitaUecText = GeneratedColumn<String>(
    'gravita_uec_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _esclusioneUecTextMeta = const VerificationMeta(
    'esclusioneUecText',
  );
  @override
  late final GeneratedColumn<String> esclusioneUecText =
      GeneratedColumn<String>(
        'esclusione_uec_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _gravitaOperatoreTextMeta =
      const VerificationMeta('gravitaOperatoreText');
  @override
  late final GeneratedColumn<String> gravitaOperatoreText =
      GeneratedColumn<String>(
        'gravita_operatore_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _esclusioneOperatoreTextMeta =
      const VerificationMeta('esclusioneOperatoreText');
  @override
  late final GeneratedColumn<String> esclusioneOperatoreText =
      GeneratedColumn<String>(
        'esclusione_operatore_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _esclusioneLottoTextMeta =
      const VerificationMeta('esclusioneLottoText');
  @override
  late final GeneratedColumn<String> esclusioneLottoText =
      GeneratedColumn<String>(
        'esclusione_lotto_text',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _hasEsclusioneLottoMeta =
      const VerificationMeta('hasEsclusioneLotto');
  @override
  late final GeneratedColumn<bool> hasEsclusioneLotto = GeneratedColumn<bool>(
    'has_esclusione_lotto',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_esclusione_lotto" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colGTextMeta = const VerificationMeta(
    'colGText',
  );
  @override
  late final GeneratedColumn<String> colGText = GeneratedColumn<String>(
    'col_g_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _disposizioniRegionaliMeta =
      const VerificationMeta('disposizioniRegionali');
  @override
  late final GeneratedColumn<String> disposizioniRegionali =
      GeneratedColumn<String>(
        'disposizioni_regionali',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    fase,
    obbligo,
    indicatorType,
    deroghe,
    noteNorma,
    tipologiaControllo,
    frequenzaSingolo,
    frequenzaAssociato,
    gravitaUecText,
    esclusioneUecText,
    gravitaOperatoreText,
    esclusioneOperatoreText,
    esclusioneLottoText,
    hasEsclusioneLotto,
    colGText,
    disposizioniRegionali,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('fase')) {
      context.handle(
        _faseMeta,
        fase.isAcceptableOrUnknown(data['fase']!, _faseMeta),
      );
    }
    if (data.containsKey('obbligo')) {
      context.handle(
        _obbligoMeta,
        obbligo.isAcceptableOrUnknown(data['obbligo']!, _obbligoMeta),
      );
    }
    if (data.containsKey('indicator_type')) {
      context.handle(
        _indicatorTypeMeta,
        indicatorType.isAcceptableOrUnknown(
          data['indicator_type']!,
          _indicatorTypeMeta,
        ),
      );
    }
    if (data.containsKey('deroghe')) {
      context.handle(
        _derogheMeta,
        deroghe.isAcceptableOrUnknown(data['deroghe']!, _derogheMeta),
      );
    }
    if (data.containsKey('note_norma')) {
      context.handle(
        _noteNormaMeta,
        noteNorma.isAcceptableOrUnknown(data['note_norma']!, _noteNormaMeta),
      );
    }
    if (data.containsKey('tipologia_controllo')) {
      context.handle(
        _tipologiaControlloMeta,
        tipologiaControllo.isAcceptableOrUnknown(
          data['tipologia_controllo']!,
          _tipologiaControlloMeta,
        ),
      );
    }
    if (data.containsKey('frequenza_singolo')) {
      context.handle(
        _frequenzaSingoloMeta,
        frequenzaSingolo.isAcceptableOrUnknown(
          data['frequenza_singolo']!,
          _frequenzaSingoloMeta,
        ),
      );
    }
    if (data.containsKey('frequenza_associato')) {
      context.handle(
        _frequenzaAssociatoMeta,
        frequenzaAssociato.isAcceptableOrUnknown(
          data['frequenza_associato']!,
          _frequenzaAssociatoMeta,
        ),
      );
    }
    if (data.containsKey('gravita_uec_text')) {
      context.handle(
        _gravitaUecTextMeta,
        gravitaUecText.isAcceptableOrUnknown(
          data['gravita_uec_text']!,
          _gravitaUecTextMeta,
        ),
      );
    }
    if (data.containsKey('esclusione_uec_text')) {
      context.handle(
        _esclusioneUecTextMeta,
        esclusioneUecText.isAcceptableOrUnknown(
          data['esclusione_uec_text']!,
          _esclusioneUecTextMeta,
        ),
      );
    }
    if (data.containsKey('gravita_operatore_text')) {
      context.handle(
        _gravitaOperatoreTextMeta,
        gravitaOperatoreText.isAcceptableOrUnknown(
          data['gravita_operatore_text']!,
          _gravitaOperatoreTextMeta,
        ),
      );
    }
    if (data.containsKey('esclusione_operatore_text')) {
      context.handle(
        _esclusioneOperatoreTextMeta,
        esclusioneOperatoreText.isAcceptableOrUnknown(
          data['esclusione_operatore_text']!,
          _esclusioneOperatoreTextMeta,
        ),
      );
    }
    if (data.containsKey('esclusione_lotto_text')) {
      context.handle(
        _esclusioneLottoTextMeta,
        esclusioneLottoText.isAcceptableOrUnknown(
          data['esclusione_lotto_text']!,
          _esclusioneLottoTextMeta,
        ),
      );
    }
    if (data.containsKey('has_esclusione_lotto')) {
      context.handle(
        _hasEsclusioneLottoMeta,
        hasEsclusioneLotto.isAcceptableOrUnknown(
          data['has_esclusione_lotto']!,
          _hasEsclusioneLottoMeta,
        ),
      );
    }
    if (data.containsKey('col_g_text')) {
      context.handle(
        _colGTextMeta,
        colGText.isAcceptableOrUnknown(data['col_g_text']!, _colGTextMeta),
      );
    }
    if (data.containsKey('disposizioni_regionali')) {
      context.handle(
        _disposizioniRegionaliMeta,
        disposizioniRegionali.isAcceptableOrUnknown(
          data['disposizioni_regionali']!,
          _disposizioniRegionaliMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      fase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fase'],
      )!,
      obbligo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obbligo'],
      )!,
      indicatorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}indicator_type'],
      )!,
      deroghe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deroghe'],
      )!,
      noteNorma: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_norma'],
      )!,
      tipologiaControllo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipologia_controllo'],
      )!,
      frequenzaSingolo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequenza_singolo'],
      )!,
      frequenzaAssociato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequenza_associato'],
      )!,
      gravitaUecText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gravita_uec_text'],
      )!,
      esclusioneUecText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esclusione_uec_text'],
      )!,
      gravitaOperatoreText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gravita_operatore_text'],
      )!,
      esclusioneOperatoreText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esclusione_operatore_text'],
      )!,
      esclusioneLottoText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}esclusione_lotto_text'],
      )!,
      hasEsclusioneLotto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_esclusione_lotto'],
      )!,
      colGText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}col_g_text'],
      )!,
      disposizioniRegionali: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disposizioni_regionali'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  /// Codice requisito: es. 0.1, 1.10, 3.2.1 ecc
  final String code;

  /// "Fase" = gerarchia serializzata, es: "03 - Impegni... > Difesa..."
  final String fase;
  final String obbligo;
  final String indicatorType;
  final String deroghe;
  final String noteNorma;
  final String tipologiaControllo;
  final String frequenzaSingolo;
  final String frequenzaAssociato;
  final String gravitaUecText;
  final String esclusioneUecText;
  final String gravitaOperatoreText;
  final String esclusioneOperatoreText;
  final String esclusioneLottoText;
  final bool hasEsclusioneLotto;
  final String colGText;
  final String disposizioniRegionali;

  /// Ordinamento globale per mantenere l’ordine dell’Excel
  final int sortOrder;
  const ChecklistItem({
    required this.code,
    required this.fase,
    required this.obbligo,
    required this.indicatorType,
    required this.deroghe,
    required this.noteNorma,
    required this.tipologiaControllo,
    required this.frequenzaSingolo,
    required this.frequenzaAssociato,
    required this.gravitaUecText,
    required this.esclusioneUecText,
    required this.gravitaOperatoreText,
    required this.esclusioneOperatoreText,
    required this.esclusioneLottoText,
    required this.hasEsclusioneLotto,
    required this.colGText,
    required this.disposizioniRegionali,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['fase'] = Variable<String>(fase);
    map['obbligo'] = Variable<String>(obbligo);
    map['indicator_type'] = Variable<String>(indicatorType);
    map['deroghe'] = Variable<String>(deroghe);
    map['note_norma'] = Variable<String>(noteNorma);
    map['tipologia_controllo'] = Variable<String>(tipologiaControllo);
    map['frequenza_singolo'] = Variable<String>(frequenzaSingolo);
    map['frequenza_associato'] = Variable<String>(frequenzaAssociato);
    map['gravita_uec_text'] = Variable<String>(gravitaUecText);
    map['esclusione_uec_text'] = Variable<String>(esclusioneUecText);
    map['gravita_operatore_text'] = Variable<String>(gravitaOperatoreText);
    map['esclusione_operatore_text'] = Variable<String>(
      esclusioneOperatoreText,
    );
    map['esclusione_lotto_text'] = Variable<String>(esclusioneLottoText);
    map['has_esclusione_lotto'] = Variable<bool>(hasEsclusioneLotto);
    map['col_g_text'] = Variable<String>(colGText);
    map['disposizioni_regionali'] = Variable<String>(disposizioniRegionali);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      code: Value(code),
      fase: Value(fase),
      obbligo: Value(obbligo),
      indicatorType: Value(indicatorType),
      deroghe: Value(deroghe),
      noteNorma: Value(noteNorma),
      tipologiaControllo: Value(tipologiaControllo),
      frequenzaSingolo: Value(frequenzaSingolo),
      frequenzaAssociato: Value(frequenzaAssociato),
      gravitaUecText: Value(gravitaUecText),
      esclusioneUecText: Value(esclusioneUecText),
      gravitaOperatoreText: Value(gravitaOperatoreText),
      esclusioneOperatoreText: Value(esclusioneOperatoreText),
      esclusioneLottoText: Value(esclusioneLottoText),
      hasEsclusioneLotto: Value(hasEsclusioneLotto),
      colGText: Value(colGText),
      disposizioniRegionali: Value(disposizioniRegionali),
      sortOrder: Value(sortOrder),
    );
  }

  factory ChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      code: serializer.fromJson<String>(json['code']),
      fase: serializer.fromJson<String>(json['fase']),
      obbligo: serializer.fromJson<String>(json['obbligo']),
      indicatorType: serializer.fromJson<String>(json['indicatorType']),
      deroghe: serializer.fromJson<String>(json['deroghe']),
      noteNorma: serializer.fromJson<String>(json['noteNorma']),
      tipologiaControllo: serializer.fromJson<String>(
        json['tipologiaControllo'],
      ),
      frequenzaSingolo: serializer.fromJson<String>(json['frequenzaSingolo']),
      frequenzaAssociato: serializer.fromJson<String>(
        json['frequenzaAssociato'],
      ),
      gravitaUecText: serializer.fromJson<String>(json['gravitaUecText']),
      esclusioneUecText: serializer.fromJson<String>(json['esclusioneUecText']),
      gravitaOperatoreText: serializer.fromJson<String>(
        json['gravitaOperatoreText'],
      ),
      esclusioneOperatoreText: serializer.fromJson<String>(
        json['esclusioneOperatoreText'],
      ),
      esclusioneLottoText: serializer.fromJson<String>(
        json['esclusioneLottoText'],
      ),
      hasEsclusioneLotto: serializer.fromJson<bool>(json['hasEsclusioneLotto']),
      colGText: serializer.fromJson<String>(json['colGText']),
      disposizioniRegionali: serializer.fromJson<String>(
        json['disposizioniRegionali'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'fase': serializer.toJson<String>(fase),
      'obbligo': serializer.toJson<String>(obbligo),
      'indicatorType': serializer.toJson<String>(indicatorType),
      'deroghe': serializer.toJson<String>(deroghe),
      'noteNorma': serializer.toJson<String>(noteNorma),
      'tipologiaControllo': serializer.toJson<String>(tipologiaControllo),
      'frequenzaSingolo': serializer.toJson<String>(frequenzaSingolo),
      'frequenzaAssociato': serializer.toJson<String>(frequenzaAssociato),
      'gravitaUecText': serializer.toJson<String>(gravitaUecText),
      'esclusioneUecText': serializer.toJson<String>(esclusioneUecText),
      'gravitaOperatoreText': serializer.toJson<String>(gravitaOperatoreText),
      'esclusioneOperatoreText': serializer.toJson<String>(
        esclusioneOperatoreText,
      ),
      'esclusioneLottoText': serializer.toJson<String>(esclusioneLottoText),
      'hasEsclusioneLotto': serializer.toJson<bool>(hasEsclusioneLotto),
      'colGText': serializer.toJson<String>(colGText),
      'disposizioniRegionali': serializer.toJson<String>(disposizioniRegionali),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ChecklistItem copyWith({
    String? code,
    String? fase,
    String? obbligo,
    String? indicatorType,
    String? deroghe,
    String? noteNorma,
    String? tipologiaControllo,
    String? frequenzaSingolo,
    String? frequenzaAssociato,
    String? gravitaUecText,
    String? esclusioneUecText,
    String? gravitaOperatoreText,
    String? esclusioneOperatoreText,
    String? esclusioneLottoText,
    bool? hasEsclusioneLotto,
    String? colGText,
    String? disposizioniRegionali,
    int? sortOrder,
  }) => ChecklistItem(
    code: code ?? this.code,
    fase: fase ?? this.fase,
    obbligo: obbligo ?? this.obbligo,
    indicatorType: indicatorType ?? this.indicatorType,
    deroghe: deroghe ?? this.deroghe,
    noteNorma: noteNorma ?? this.noteNorma,
    tipologiaControllo: tipologiaControllo ?? this.tipologiaControllo,
    frequenzaSingolo: frequenzaSingolo ?? this.frequenzaSingolo,
    frequenzaAssociato: frequenzaAssociato ?? this.frequenzaAssociato,
    gravitaUecText: gravitaUecText ?? this.gravitaUecText,
    esclusioneUecText: esclusioneUecText ?? this.esclusioneUecText,
    gravitaOperatoreText: gravitaOperatoreText ?? this.gravitaOperatoreText,
    esclusioneOperatoreText:
        esclusioneOperatoreText ?? this.esclusioneOperatoreText,
    esclusioneLottoText: esclusioneLottoText ?? this.esclusioneLottoText,
    hasEsclusioneLotto: hasEsclusioneLotto ?? this.hasEsclusioneLotto,
    colGText: colGText ?? this.colGText,
    disposizioniRegionali: disposizioniRegionali ?? this.disposizioniRegionali,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      code: data.code.present ? data.code.value : this.code,
      fase: data.fase.present ? data.fase.value : this.fase,
      obbligo: data.obbligo.present ? data.obbligo.value : this.obbligo,
      indicatorType: data.indicatorType.present
          ? data.indicatorType.value
          : this.indicatorType,
      deroghe: data.deroghe.present ? data.deroghe.value : this.deroghe,
      noteNorma: data.noteNorma.present ? data.noteNorma.value : this.noteNorma,
      tipologiaControllo: data.tipologiaControllo.present
          ? data.tipologiaControllo.value
          : this.tipologiaControllo,
      frequenzaSingolo: data.frequenzaSingolo.present
          ? data.frequenzaSingolo.value
          : this.frequenzaSingolo,
      frequenzaAssociato: data.frequenzaAssociato.present
          ? data.frequenzaAssociato.value
          : this.frequenzaAssociato,
      gravitaUecText: data.gravitaUecText.present
          ? data.gravitaUecText.value
          : this.gravitaUecText,
      esclusioneUecText: data.esclusioneUecText.present
          ? data.esclusioneUecText.value
          : this.esclusioneUecText,
      gravitaOperatoreText: data.gravitaOperatoreText.present
          ? data.gravitaOperatoreText.value
          : this.gravitaOperatoreText,
      esclusioneOperatoreText: data.esclusioneOperatoreText.present
          ? data.esclusioneOperatoreText.value
          : this.esclusioneOperatoreText,
      esclusioneLottoText: data.esclusioneLottoText.present
          ? data.esclusioneLottoText.value
          : this.esclusioneLottoText,
      hasEsclusioneLotto: data.hasEsclusioneLotto.present
          ? data.hasEsclusioneLotto.value
          : this.hasEsclusioneLotto,
      colGText: data.colGText.present ? data.colGText.value : this.colGText,
      disposizioniRegionali: data.disposizioniRegionali.present
          ? data.disposizioniRegionali.value
          : this.disposizioniRegionali,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('code: $code, ')
          ..write('fase: $fase, ')
          ..write('obbligo: $obbligo, ')
          ..write('indicatorType: $indicatorType, ')
          ..write('deroghe: $deroghe, ')
          ..write('noteNorma: $noteNorma, ')
          ..write('tipologiaControllo: $tipologiaControllo, ')
          ..write('frequenzaSingolo: $frequenzaSingolo, ')
          ..write('frequenzaAssociato: $frequenzaAssociato, ')
          ..write('gravitaUecText: $gravitaUecText, ')
          ..write('esclusioneUecText: $esclusioneUecText, ')
          ..write('gravitaOperatoreText: $gravitaOperatoreText, ')
          ..write('esclusioneOperatoreText: $esclusioneOperatoreText, ')
          ..write('esclusioneLottoText: $esclusioneLottoText, ')
          ..write('hasEsclusioneLotto: $hasEsclusioneLotto, ')
          ..write('colGText: $colGText, ')
          ..write('disposizioniRegionali: $disposizioniRegionali, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    code,
    fase,
    obbligo,
    indicatorType,
    deroghe,
    noteNorma,
    tipologiaControllo,
    frequenzaSingolo,
    frequenzaAssociato,
    gravitaUecText,
    esclusioneUecText,
    gravitaOperatoreText,
    esclusioneOperatoreText,
    esclusioneLottoText,
    hasEsclusioneLotto,
    colGText,
    disposizioniRegionali,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.code == this.code &&
          other.fase == this.fase &&
          other.obbligo == this.obbligo &&
          other.indicatorType == this.indicatorType &&
          other.deroghe == this.deroghe &&
          other.noteNorma == this.noteNorma &&
          other.tipologiaControllo == this.tipologiaControllo &&
          other.frequenzaSingolo == this.frequenzaSingolo &&
          other.frequenzaAssociato == this.frequenzaAssociato &&
          other.gravitaUecText == this.gravitaUecText &&
          other.esclusioneUecText == this.esclusioneUecText &&
          other.gravitaOperatoreText == this.gravitaOperatoreText &&
          other.esclusioneOperatoreText == this.esclusioneOperatoreText &&
          other.esclusioneLottoText == this.esclusioneLottoText &&
          other.hasEsclusioneLotto == this.hasEsclusioneLotto &&
          other.colGText == this.colGText &&
          other.disposizioniRegionali == this.disposizioniRegionali &&
          other.sortOrder == this.sortOrder);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<String> code;
  final Value<String> fase;
  final Value<String> obbligo;
  final Value<String> indicatorType;
  final Value<String> deroghe;
  final Value<String> noteNorma;
  final Value<String> tipologiaControllo;
  final Value<String> frequenzaSingolo;
  final Value<String> frequenzaAssociato;
  final Value<String> gravitaUecText;
  final Value<String> esclusioneUecText;
  final Value<String> gravitaOperatoreText;
  final Value<String> esclusioneOperatoreText;
  final Value<String> esclusioneLottoText;
  final Value<bool> hasEsclusioneLotto;
  final Value<String> colGText;
  final Value<String> disposizioniRegionali;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ChecklistItemsCompanion({
    this.code = const Value.absent(),
    this.fase = const Value.absent(),
    this.obbligo = const Value.absent(),
    this.indicatorType = const Value.absent(),
    this.deroghe = const Value.absent(),
    this.noteNorma = const Value.absent(),
    this.tipologiaControllo = const Value.absent(),
    this.frequenzaSingolo = const Value.absent(),
    this.frequenzaAssociato = const Value.absent(),
    this.gravitaUecText = const Value.absent(),
    this.esclusioneUecText = const Value.absent(),
    this.gravitaOperatoreText = const Value.absent(),
    this.esclusioneOperatoreText = const Value.absent(),
    this.esclusioneLottoText = const Value.absent(),
    this.hasEsclusioneLotto = const Value.absent(),
    this.colGText = const Value.absent(),
    this.disposizioniRegionali = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    required String code,
    this.fase = const Value.absent(),
    this.obbligo = const Value.absent(),
    this.indicatorType = const Value.absent(),
    this.deroghe = const Value.absent(),
    this.noteNorma = const Value.absent(),
    this.tipologiaControllo = const Value.absent(),
    this.frequenzaSingolo = const Value.absent(),
    this.frequenzaAssociato = const Value.absent(),
    this.gravitaUecText = const Value.absent(),
    this.esclusioneUecText = const Value.absent(),
    this.gravitaOperatoreText = const Value.absent(),
    this.esclusioneOperatoreText = const Value.absent(),
    this.esclusioneLottoText = const Value.absent(),
    this.hasEsclusioneLotto = const Value.absent(),
    this.colGText = const Value.absent(),
    this.disposizioniRegionali = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       sortOrder = Value(sortOrder);
  static Insertable<ChecklistItem> custom({
    Expression<String>? code,
    Expression<String>? fase,
    Expression<String>? obbligo,
    Expression<String>? indicatorType,
    Expression<String>? deroghe,
    Expression<String>? noteNorma,
    Expression<String>? tipologiaControllo,
    Expression<String>? frequenzaSingolo,
    Expression<String>? frequenzaAssociato,
    Expression<String>? gravitaUecText,
    Expression<String>? esclusioneUecText,
    Expression<String>? gravitaOperatoreText,
    Expression<String>? esclusioneOperatoreText,
    Expression<String>? esclusioneLottoText,
    Expression<bool>? hasEsclusioneLotto,
    Expression<String>? colGText,
    Expression<String>? disposizioniRegionali,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (fase != null) 'fase': fase,
      if (obbligo != null) 'obbligo': obbligo,
      if (indicatorType != null) 'indicator_type': indicatorType,
      if (deroghe != null) 'deroghe': deroghe,
      if (noteNorma != null) 'note_norma': noteNorma,
      if (tipologiaControllo != null) 'tipologia_controllo': tipologiaControllo,
      if (frequenzaSingolo != null) 'frequenza_singolo': frequenzaSingolo,
      if (frequenzaAssociato != null) 'frequenza_associato': frequenzaAssociato,
      if (gravitaUecText != null) 'gravita_uec_text': gravitaUecText,
      if (esclusioneUecText != null) 'esclusione_uec_text': esclusioneUecText,
      if (gravitaOperatoreText != null)
        'gravita_operatore_text': gravitaOperatoreText,
      if (esclusioneOperatoreText != null)
        'esclusione_operatore_text': esclusioneOperatoreText,
      if (esclusioneLottoText != null)
        'esclusione_lotto_text': esclusioneLottoText,
      if (hasEsclusioneLotto != null)
        'has_esclusione_lotto': hasEsclusioneLotto,
      if (colGText != null) 'col_g_text': colGText,
      if (disposizioniRegionali != null)
        'disposizioni_regionali': disposizioniRegionali,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<String>? code,
    Value<String>? fase,
    Value<String>? obbligo,
    Value<String>? indicatorType,
    Value<String>? deroghe,
    Value<String>? noteNorma,
    Value<String>? tipologiaControllo,
    Value<String>? frequenzaSingolo,
    Value<String>? frequenzaAssociato,
    Value<String>? gravitaUecText,
    Value<String>? esclusioneUecText,
    Value<String>? gravitaOperatoreText,
    Value<String>? esclusioneOperatoreText,
    Value<String>? esclusioneLottoText,
    Value<bool>? hasEsclusioneLotto,
    Value<String>? colGText,
    Value<String>? disposizioniRegionali,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ChecklistItemsCompanion(
      code: code ?? this.code,
      fase: fase ?? this.fase,
      obbligo: obbligo ?? this.obbligo,
      indicatorType: indicatorType ?? this.indicatorType,
      deroghe: deroghe ?? this.deroghe,
      noteNorma: noteNorma ?? this.noteNorma,
      tipologiaControllo: tipologiaControllo ?? this.tipologiaControllo,
      frequenzaSingolo: frequenzaSingolo ?? this.frequenzaSingolo,
      frequenzaAssociato: frequenzaAssociato ?? this.frequenzaAssociato,
      gravitaUecText: gravitaUecText ?? this.gravitaUecText,
      esclusioneUecText: esclusioneUecText ?? this.esclusioneUecText,
      gravitaOperatoreText: gravitaOperatoreText ?? this.gravitaOperatoreText,
      esclusioneOperatoreText:
          esclusioneOperatoreText ?? this.esclusioneOperatoreText,
      esclusioneLottoText: esclusioneLottoText ?? this.esclusioneLottoText,
      hasEsclusioneLotto: hasEsclusioneLotto ?? this.hasEsclusioneLotto,
      colGText: colGText ?? this.colGText,
      disposizioniRegionali:
          disposizioniRegionali ?? this.disposizioniRegionali,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (fase.present) {
      map['fase'] = Variable<String>(fase.value);
    }
    if (obbligo.present) {
      map['obbligo'] = Variable<String>(obbligo.value);
    }
    if (indicatorType.present) {
      map['indicator_type'] = Variable<String>(indicatorType.value);
    }
    if (deroghe.present) {
      map['deroghe'] = Variable<String>(deroghe.value);
    }
    if (noteNorma.present) {
      map['note_norma'] = Variable<String>(noteNorma.value);
    }
    if (tipologiaControllo.present) {
      map['tipologia_controllo'] = Variable<String>(tipologiaControllo.value);
    }
    if (frequenzaSingolo.present) {
      map['frequenza_singolo'] = Variable<String>(frequenzaSingolo.value);
    }
    if (frequenzaAssociato.present) {
      map['frequenza_associato'] = Variable<String>(frequenzaAssociato.value);
    }
    if (gravitaUecText.present) {
      map['gravita_uec_text'] = Variable<String>(gravitaUecText.value);
    }
    if (esclusioneUecText.present) {
      map['esclusione_uec_text'] = Variable<String>(esclusioneUecText.value);
    }
    if (gravitaOperatoreText.present) {
      map['gravita_operatore_text'] = Variable<String>(
        gravitaOperatoreText.value,
      );
    }
    if (esclusioneOperatoreText.present) {
      map['esclusione_operatore_text'] = Variable<String>(
        esclusioneOperatoreText.value,
      );
    }
    if (esclusioneLottoText.present) {
      map['esclusione_lotto_text'] = Variable<String>(
        esclusioneLottoText.value,
      );
    }
    if (hasEsclusioneLotto.present) {
      map['has_esclusione_lotto'] = Variable<bool>(hasEsclusioneLotto.value);
    }
    if (colGText.present) {
      map['col_g_text'] = Variable<String>(colGText.value);
    }
    if (disposizioniRegionali.present) {
      map['disposizioni_regionali'] = Variable<String>(
        disposizioniRegionali.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('code: $code, ')
          ..write('fase: $fase, ')
          ..write('obbligo: $obbligo, ')
          ..write('indicatorType: $indicatorType, ')
          ..write('deroghe: $deroghe, ')
          ..write('noteNorma: $noteNorma, ')
          ..write('tipologiaControllo: $tipologiaControllo, ')
          ..write('frequenzaSingolo: $frequenzaSingolo, ')
          ..write('frequenzaAssociato: $frequenzaAssociato, ')
          ..write('gravitaUecText: $gravitaUecText, ')
          ..write('esclusioneUecText: $esclusioneUecText, ')
          ..write('gravitaOperatoreText: $gravitaOperatoreText, ')
          ..write('esclusioneOperatoreText: $esclusioneOperatoreText, ')
          ..write('esclusioneLottoText: $esclusioneLottoText, ')
          ..write('hasEsclusioneLotto: $hasEsclusioneLotto, ')
          ..write('colGText: $colGText, ')
          ..write('disposizioniRegionali: $disposizioniRegionali, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistResponsesTable extends ChecklistResponses
    with TableInfo<$ChecklistResponsesTable, ChecklistResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uecIdMeta = const VerificationMeta('uecId');
  @override
  late final GeneratedColumn<String> uecId = GeneratedColumn<String>(
    'uec_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visit_uecs(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES checklist_items(code) ON DELETE RESTRICT',
  );
  static const VerificationMeta _conformitaMeta = const VerificationMeta(
    'conformita',
  );
  @override
  late final GeneratedColumn<int> conformita = GeneratedColumn<int>(
    'conformita',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _livelloKoMeta = const VerificationMeta(
    'livelloKo',
  );
  @override
  late final GeneratedColumn<int> livelloKo = GeneratedColumn<int>(
    'livello_ko',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _punteggioUecMeta = const VerificationMeta(
    'punteggioUec',
  );
  @override
  late final GeneratedColumn<int> punteggioUec = GeneratedColumn<int>(
    'punteggio_uec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _punteggioOperatoreMeta =
      const VerificationMeta('punteggioOperatore');
  @override
  late final GeneratedColumn<int> punteggioOperatore = GeneratedColumn<int>(
    'punteggio_operatore',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rilievoNcMeta = const VerificationMeta(
    'rilievoNc',
  );
  @override
  late final GeneratedColumn<String> rilievoNc = GeneratedColumn<String>(
    'rilievo_nc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uecId,
    itemCode,
    conformita,
    livelloKo,
    punteggioUec,
    punteggioOperatore,
    rilievoNc,
    note,
    updatedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('uec_id')) {
      context.handle(
        _uecIdMeta,
        uecId.isAcceptableOrUnknown(data['uec_id']!, _uecIdMeta),
      );
    } else if (isInserting) {
      context.missing(_uecIdMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('conformita')) {
      context.handle(
        _conformitaMeta,
        conformita.isAcceptableOrUnknown(data['conformita']!, _conformitaMeta),
      );
    } else if (isInserting) {
      context.missing(_conformitaMeta);
    }
    if (data.containsKey('livello_ko')) {
      context.handle(
        _livelloKoMeta,
        livelloKo.isAcceptableOrUnknown(data['livello_ko']!, _livelloKoMeta),
      );
    }
    if (data.containsKey('punteggio_uec')) {
      context.handle(
        _punteggioUecMeta,
        punteggioUec.isAcceptableOrUnknown(
          data['punteggio_uec']!,
          _punteggioUecMeta,
        ),
      );
    }
    if (data.containsKey('punteggio_operatore')) {
      context.handle(
        _punteggioOperatoreMeta,
        punteggioOperatore.isAcceptableOrUnknown(
          data['punteggio_operatore']!,
          _punteggioOperatoreMeta,
        ),
      );
    }
    if (data.containsKey('rilievo_nc')) {
      context.handle(
        _rilievoNcMeta,
        rilievoNc.isAcceptableOrUnknown(data['rilievo_nc']!, _rilievoNcMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {uecId, itemCode},
  ];
  @override
  ChecklistResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistResponse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      uecId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uec_id'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      conformita: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}conformita'],
      )!,
      livelloKo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}livello_ko'],
      ),
      punteggioUec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}punteggio_uec'],
      ),
      punteggioOperatore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}punteggio_operatore'],
      ),
      rilievoNc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rilievo_nc'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $ChecklistResponsesTable createAlias(String alias) {
    return $ChecklistResponsesTable(attachedDatabase, alias);
  }
}

class ChecklistResponse extends DataClass
    implements Insertable<ChecklistResponse> {
  final String id;
  final String uecId;
  final String itemCode;
  final int conformita;
  final int? livelloKo;
  final int? punteggioUec;
  final int? punteggioOperatore;
  final String rilievoNc;
  final String note;
  final DateTime updatedAt;
  final bool isSynced;
  const ChecklistResponse({
    required this.id,
    required this.uecId,
    required this.itemCode,
    required this.conformita,
    this.livelloKo,
    this.punteggioUec,
    this.punteggioOperatore,
    required this.rilievoNc,
    required this.note,
    required this.updatedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['uec_id'] = Variable<String>(uecId);
    map['item_code'] = Variable<String>(itemCode);
    map['conformita'] = Variable<int>(conformita);
    if (!nullToAbsent || livelloKo != null) {
      map['livello_ko'] = Variable<int>(livelloKo);
    }
    if (!nullToAbsent || punteggioUec != null) {
      map['punteggio_uec'] = Variable<int>(punteggioUec);
    }
    if (!nullToAbsent || punteggioOperatore != null) {
      map['punteggio_operatore'] = Variable<int>(punteggioOperatore);
    }
    map['rilievo_nc'] = Variable<String>(rilievoNc);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ChecklistResponsesCompanion toCompanion(bool nullToAbsent) {
    return ChecklistResponsesCompanion(
      id: Value(id),
      uecId: Value(uecId),
      itemCode: Value(itemCode),
      conformita: Value(conformita),
      livelloKo: livelloKo == null && nullToAbsent
          ? const Value.absent()
          : Value(livelloKo),
      punteggioUec: punteggioUec == null && nullToAbsent
          ? const Value.absent()
          : Value(punteggioUec),
      punteggioOperatore: punteggioOperatore == null && nullToAbsent
          ? const Value.absent()
          : Value(punteggioOperatore),
      rilievoNc: Value(rilievoNc),
      note: Value(note),
      updatedAt: Value(updatedAt),
      isSynced: Value(isSynced),
    );
  }

  factory ChecklistResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistResponse(
      id: serializer.fromJson<String>(json['id']),
      uecId: serializer.fromJson<String>(json['uecId']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      conformita: serializer.fromJson<int>(json['conformita']),
      livelloKo: serializer.fromJson<int?>(json['livelloKo']),
      punteggioUec: serializer.fromJson<int?>(json['punteggioUec']),
      punteggioOperatore: serializer.fromJson<int?>(json['punteggioOperatore']),
      rilievoNc: serializer.fromJson<String>(json['rilievoNc']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'uecId': serializer.toJson<String>(uecId),
      'itemCode': serializer.toJson<String>(itemCode),
      'conformita': serializer.toJson<int>(conformita),
      'livelloKo': serializer.toJson<int?>(livelloKo),
      'punteggioUec': serializer.toJson<int?>(punteggioUec),
      'punteggioOperatore': serializer.toJson<int?>(punteggioOperatore),
      'rilievoNc': serializer.toJson<String>(rilievoNc),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ChecklistResponse copyWith({
    String? id,
    String? uecId,
    String? itemCode,
    int? conformita,
    Value<int?> livelloKo = const Value.absent(),
    Value<int?> punteggioUec = const Value.absent(),
    Value<int?> punteggioOperatore = const Value.absent(),
    String? rilievoNc,
    String? note,
    DateTime? updatedAt,
    bool? isSynced,
  }) => ChecklistResponse(
    id: id ?? this.id,
    uecId: uecId ?? this.uecId,
    itemCode: itemCode ?? this.itemCode,
    conformita: conformita ?? this.conformita,
    livelloKo: livelloKo.present ? livelloKo.value : this.livelloKo,
    punteggioUec: punteggioUec.present ? punteggioUec.value : this.punteggioUec,
    punteggioOperatore: punteggioOperatore.present
        ? punteggioOperatore.value
        : this.punteggioOperatore,
    rilievoNc: rilievoNc ?? this.rilievoNc,
    note: note ?? this.note,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  ChecklistResponse copyWithCompanion(ChecklistResponsesCompanion data) {
    return ChecklistResponse(
      id: data.id.present ? data.id.value : this.id,
      uecId: data.uecId.present ? data.uecId.value : this.uecId,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      conformita: data.conformita.present
          ? data.conformita.value
          : this.conformita,
      livelloKo: data.livelloKo.present ? data.livelloKo.value : this.livelloKo,
      punteggioUec: data.punteggioUec.present
          ? data.punteggioUec.value
          : this.punteggioUec,
      punteggioOperatore: data.punteggioOperatore.present
          ? data.punteggioOperatore.value
          : this.punteggioOperatore,
      rilievoNc: data.rilievoNc.present ? data.rilievoNc.value : this.rilievoNc,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistResponse(')
          ..write('id: $id, ')
          ..write('uecId: $uecId, ')
          ..write('itemCode: $itemCode, ')
          ..write('conformita: $conformita, ')
          ..write('livelloKo: $livelloKo, ')
          ..write('punteggioUec: $punteggioUec, ')
          ..write('punteggioOperatore: $punteggioOperatore, ')
          ..write('rilievoNc: $rilievoNc, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uecId,
    itemCode,
    conformita,
    livelloKo,
    punteggioUec,
    punteggioOperatore,
    rilievoNc,
    note,
    updatedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistResponse &&
          other.id == this.id &&
          other.uecId == this.uecId &&
          other.itemCode == this.itemCode &&
          other.conformita == this.conformita &&
          other.livelloKo == this.livelloKo &&
          other.punteggioUec == this.punteggioUec &&
          other.punteggioOperatore == this.punteggioOperatore &&
          other.rilievoNc == this.rilievoNc &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced);
}

class ChecklistResponsesCompanion extends UpdateCompanion<ChecklistResponse> {
  final Value<String> id;
  final Value<String> uecId;
  final Value<String> itemCode;
  final Value<int> conformita;
  final Value<int?> livelloKo;
  final Value<int?> punteggioUec;
  final Value<int?> punteggioOperatore;
  final Value<String> rilievoNc;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ChecklistResponsesCompanion({
    this.id = const Value.absent(),
    this.uecId = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.conformita = const Value.absent(),
    this.livelloKo = const Value.absent(),
    this.punteggioUec = const Value.absent(),
    this.punteggioOperatore = const Value.absent(),
    this.rilievoNc = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistResponsesCompanion.insert({
    required String id,
    required String uecId,
    required String itemCode,
    required int conformita,
    this.livelloKo = const Value.absent(),
    this.punteggioUec = const Value.absent(),
    this.punteggioOperatore = const Value.absent(),
    this.rilievoNc = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime updatedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       uecId = Value(uecId),
       itemCode = Value(itemCode),
       conformita = Value(conformita),
       updatedAt = Value(updatedAt);
  static Insertable<ChecklistResponse> custom({
    Expression<String>? id,
    Expression<String>? uecId,
    Expression<String>? itemCode,
    Expression<int>? conformita,
    Expression<int>? livelloKo,
    Expression<int>? punteggioUec,
    Expression<int>? punteggioOperatore,
    Expression<String>? rilievoNc,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uecId != null) 'uec_id': uecId,
      if (itemCode != null) 'item_code': itemCode,
      if (conformita != null) 'conformita': conformita,
      if (livelloKo != null) 'livello_ko': livelloKo,
      if (punteggioUec != null) 'punteggio_uec': punteggioUec,
      if (punteggioOperatore != null) 'punteggio_operatore': punteggioOperatore,
      if (rilievoNc != null) 'rilievo_nc': rilievoNc,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistResponsesCompanion copyWith({
    Value<String>? id,
    Value<String>? uecId,
    Value<String>? itemCode,
    Value<int>? conformita,
    Value<int?>? livelloKo,
    Value<int?>? punteggioUec,
    Value<int?>? punteggioOperatore,
    Value<String>? rilievoNc,
    Value<String>? note,
    Value<DateTime>? updatedAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ChecklistResponsesCompanion(
      id: id ?? this.id,
      uecId: uecId ?? this.uecId,
      itemCode: itemCode ?? this.itemCode,
      conformita: conformita ?? this.conformita,
      livelloKo: livelloKo ?? this.livelloKo,
      punteggioUec: punteggioUec ?? this.punteggioUec,
      punteggioOperatore: punteggioOperatore ?? this.punteggioOperatore,
      rilievoNc: rilievoNc ?? this.rilievoNc,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (uecId.present) {
      map['uec_id'] = Variable<String>(uecId.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (conformita.present) {
      map['conformita'] = Variable<int>(conformita.value);
    }
    if (livelloKo.present) {
      map['livello_ko'] = Variable<int>(livelloKo.value);
    }
    if (punteggioUec.present) {
      map['punteggio_uec'] = Variable<int>(punteggioUec.value);
    }
    if (punteggioOperatore.present) {
      map['punteggio_operatore'] = Variable<int>(punteggioOperatore.value);
    }
    if (rilievoNc.present) {
      map['rilievo_nc'] = Variable<String>(rilievoNc.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistResponsesCompanion(')
          ..write('id: $id, ')
          ..write('uecId: $uecId, ')
          ..write('itemCode: $itemCode, ')
          ..write('conformita: $conformita, ')
          ..write('livelloKo: $livelloKo, ')
          ..write('punteggioUec: $punteggioUec, ')
          ..write('punteggioOperatore: $punteggioOperatore, ')
          ..write('rilievoNc: $rilievoNc, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitAttachmentsTable extends VisitAttachments
    with TableInfo<$VisitAttachmentsTable, VisitAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
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
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _uecIdMeta = const VerificationMeta('uecId');
  @override
  late final GeneratedColumn<String> uecId = GeneratedColumn<String>(
    'uec_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES visit_uecs(id) ON DELETE SET NULL',
  );
  static const VerificationMeta _checklistCodeMeta = const VerificationMeta(
    'checklistCode',
  );
  @override
  late final GeneratedColumn<String> checklistCode = GeneratedColumn<String>(
    'checklist_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NULL REFERENCES checklist_items(code) ON DELETE SET NULL',
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    filePath,
    caption,
    isSynced,
    uecId,
    checklistCode,
    latitude,
    longitude,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('uec_id')) {
      context.handle(
        _uecIdMeta,
        uecId.isAcceptableOrUnknown(data['uec_id']!, _uecIdMeta),
      );
    }
    if (data.containsKey('checklist_code')) {
      context.handle(
        _checklistCodeMeta,
        checklistCode.isAcceptableOrUnknown(
          data['checklist_code']!,
          _checklistCodeMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      uecId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uec_id'],
      ),
      checklistCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_code'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VisitAttachmentsTable createAlias(String alias) {
    return $VisitAttachmentsTable(attachedDatabase, alias);
  }
}

class VisitAttachment extends DataClass implements Insertable<VisitAttachment> {
  final String id;
  final String visitId;

  /// Percorso assoluto del file immagine sul filesystem locale
  final String filePath;

  /// Didascalia opzionale
  final String caption;
  final bool isSynced;

  /// Collegamento opzionale a una UEC
  final String? uecId;

  /// Collegamento opzionale a un requisito della checklist
  final String? checklistCode;

  /// Coordinate geografiche catturate (M904)
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  const VisitAttachment({
    required this.id,
    required this.visitId,
    required this.filePath,
    required this.caption,
    required this.isSynced,
    this.uecId,
    this.checklistCode,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['file_path'] = Variable<String>(filePath);
    map['caption'] = Variable<String>(caption);
    map['is_synced'] = Variable<bool>(isSynced);
    if (!nullToAbsent || uecId != null) {
      map['uec_id'] = Variable<String>(uecId);
    }
    if (!nullToAbsent || checklistCode != null) {
      map['checklist_code'] = Variable<String>(checklistCode);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VisitAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return VisitAttachmentsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      filePath: Value(filePath),
      caption: Value(caption),
      isSynced: Value(isSynced),
      uecId: uecId == null && nullToAbsent
          ? const Value.absent()
          : Value(uecId),
      checklistCode: checklistCode == null && nullToAbsent
          ? const Value.absent()
          : Value(checklistCode),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: Value(createdAt),
    );
  }

  factory VisitAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitAttachment(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      caption: serializer.fromJson<String>(json['caption']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      uecId: serializer.fromJson<String?>(json['uecId']),
      checklistCode: serializer.fromJson<String?>(json['checklistCode']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'filePath': serializer.toJson<String>(filePath),
      'caption': serializer.toJson<String>(caption),
      'isSynced': serializer.toJson<bool>(isSynced),
      'uecId': serializer.toJson<String?>(uecId),
      'checklistCode': serializer.toJson<String?>(checklistCode),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VisitAttachment copyWith({
    String? id,
    String? visitId,
    String? filePath,
    String? caption,
    bool? isSynced,
    Value<String?> uecId = const Value.absent(),
    Value<String?> checklistCode = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? createdAt,
  }) => VisitAttachment(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    filePath: filePath ?? this.filePath,
    caption: caption ?? this.caption,
    isSynced: isSynced ?? this.isSynced,
    uecId: uecId.present ? uecId.value : this.uecId,
    checklistCode: checklistCode.present
        ? checklistCode.value
        : this.checklistCode,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt ?? this.createdAt,
  );
  VisitAttachment copyWithCompanion(VisitAttachmentsCompanion data) {
    return VisitAttachment(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      uecId: data.uecId.present ? data.uecId.value : this.uecId,
      checklistCode: data.checklistCode.present
          ? data.checklistCode.value
          : this.checklistCode,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitAttachment(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('filePath: $filePath, ')
          ..write('caption: $caption, ')
          ..write('isSynced: $isSynced, ')
          ..write('uecId: $uecId, ')
          ..write('checklistCode: $checklistCode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    filePath,
    caption,
    isSynced,
    uecId,
    checklistCode,
    latitude,
    longitude,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitAttachment &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.filePath == this.filePath &&
          other.caption == this.caption &&
          other.isSynced == this.isSynced &&
          other.uecId == this.uecId &&
          other.checklistCode == this.checklistCode &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt);
}

class VisitAttachmentsCompanion extends UpdateCompanion<VisitAttachment> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> filePath;
  final Value<String> caption;
  final Value<bool> isSynced;
  final Value<String?> uecId;
  final Value<String?> checklistCode;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VisitAttachmentsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.uecId = const Value.absent(),
    this.checklistCode = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitAttachmentsCompanion.insert({
    required String id,
    required String visitId,
    required String filePath,
    this.caption = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.uecId = const Value.absent(),
    this.checklistCode = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<VisitAttachment> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? filePath,
    Expression<String>? caption,
    Expression<bool>? isSynced,
    Expression<String>? uecId,
    Expression<String>? checklistCode,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (filePath != null) 'file_path': filePath,
      if (caption != null) 'caption': caption,
      if (isSynced != null) 'is_synced': isSynced,
      if (uecId != null) 'uec_id': uecId,
      if (checklistCode != null) 'checklist_code': checklistCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? filePath,
    Value<String>? caption,
    Value<bool>? isSynced,
    Value<String?>? uecId,
    Value<String?>? checklistCode,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VisitAttachmentsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      caption: caption ?? this.caption,
      isSynced: isSynced ?? this.isSynced,
      uecId: uecId ?? this.uecId,
      checklistCode: checklistCode ?? this.checklistCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (uecId.present) {
      map['uec_id'] = Variable<String>(uecId.value);
    }
    if (checklistCode.present) {
      map['checklist_code'] = Variable<String>(checklistCode.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
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
    return (StringBuffer('VisitAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('filePath: $filePath, ')
          ..write('caption: $caption, ')
          ..write('isSynced: $isSynced, ')
          ..write('uecId: $uecId, ')
          ..write('checklistCode: $checklistCode, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitSignaturesTable extends VisitSignatures
    with TableInfo<$VisitSignaturesTable, VisitSignature> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitSignaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _signatureTypeMeta = const VerificationMeta(
    'signatureType',
  );
  @override
  late final GeneratedColumn<String> signatureType = GeneratedColumn<String>(
    'signature_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _signerNameMeta = const VerificationMeta(
    'signerName',
  );
  @override
  late final GeneratedColumn<String> signerName = GeneratedColumn<String>(
    'signer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identityDocPathMeta = const VerificationMeta(
    'identityDocPath',
  );
  @override
  late final GeneratedColumn<String> identityDocPath = GeneratedColumn<String>(
    'identity_doc_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    signatureType,
    filePath,
    signerName,
    identityDocPath,
    createdAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_signatures';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitSignature> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('signature_type')) {
      context.handle(
        _signatureTypeMeta,
        signatureType.isAcceptableOrUnknown(
          data['signature_type']!,
          _signatureTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signatureTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('signer_name')) {
      context.handle(
        _signerNameMeta,
        signerName.isAcceptableOrUnknown(data['signer_name']!, _signerNameMeta),
      );
    }
    if (data.containsKey('identity_doc_path')) {
      context.handle(
        _identityDocPathMeta,
        identityDocPath.isAcceptableOrUnknown(
          data['identity_doc_path']!,
          _identityDocPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitSignature map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitSignature(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      signatureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      signerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signer_name'],
      ),
      identityDocPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_doc_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $VisitSignaturesTable createAlias(String alias) {
    return $VisitSignaturesTable(attachedDatabase, alias);
  }
}

class VisitSignature extends DataClass implements Insertable<VisitSignature> {
  final String id;
  final String visitId;

  /// Tipo di firma: 'inspector', 'representative', etc.
  final String signatureType;

  /// Percorso del file immagine della firma
  final String filePath;

  /// Nome di chi firma (se representative o delegate)
  final String? signerName;

  /// Percorso del documento d'identità di chi firma (se delegato o representative)
  final String? identityDocPath;
  final DateTime createdAt;
  final bool isSynced;
  const VisitSignature({
    required this.id,
    required this.visitId,
    required this.signatureType,
    required this.filePath,
    this.signerName,
    this.identityDocPath,
    required this.createdAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['signature_type'] = Variable<String>(signatureType);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || signerName != null) {
      map['signer_name'] = Variable<String>(signerName);
    }
    if (!nullToAbsent || identityDocPath != null) {
      map['identity_doc_path'] = Variable<String>(identityDocPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  VisitSignaturesCompanion toCompanion(bool nullToAbsent) {
    return VisitSignaturesCompanion(
      id: Value(id),
      visitId: Value(visitId),
      signatureType: Value(signatureType),
      filePath: Value(filePath),
      signerName: signerName == null && nullToAbsent
          ? const Value.absent()
          : Value(signerName),
      identityDocPath: identityDocPath == null && nullToAbsent
          ? const Value.absent()
          : Value(identityDocPath),
      createdAt: Value(createdAt),
      isSynced: Value(isSynced),
    );
  }

  factory VisitSignature.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitSignature(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      signatureType: serializer.fromJson<String>(json['signatureType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      signerName: serializer.fromJson<String?>(json['signerName']),
      identityDocPath: serializer.fromJson<String?>(json['identityDocPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'signatureType': serializer.toJson<String>(signatureType),
      'filePath': serializer.toJson<String>(filePath),
      'signerName': serializer.toJson<String?>(signerName),
      'identityDocPath': serializer.toJson<String?>(identityDocPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  VisitSignature copyWith({
    String? id,
    String? visitId,
    String? signatureType,
    String? filePath,
    Value<String?> signerName = const Value.absent(),
    Value<String?> identityDocPath = const Value.absent(),
    DateTime? createdAt,
    bool? isSynced,
  }) => VisitSignature(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    signatureType: signatureType ?? this.signatureType,
    filePath: filePath ?? this.filePath,
    signerName: signerName.present ? signerName.value : this.signerName,
    identityDocPath: identityDocPath.present
        ? identityDocPath.value
        : this.identityDocPath,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
  );
  VisitSignature copyWithCompanion(VisitSignaturesCompanion data) {
    return VisitSignature(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      signatureType: data.signatureType.present
          ? data.signatureType.value
          : this.signatureType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      signerName: data.signerName.present
          ? data.signerName.value
          : this.signerName,
      identityDocPath: data.identityDocPath.present
          ? data.identityDocPath.value
          : this.identityDocPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitSignature(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('signatureType: $signatureType, ')
          ..write('filePath: $filePath, ')
          ..write('signerName: $signerName, ')
          ..write('identityDocPath: $identityDocPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    signatureType,
    filePath,
    signerName,
    identityDocPath,
    createdAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitSignature &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.signatureType == this.signatureType &&
          other.filePath == this.filePath &&
          other.signerName == this.signerName &&
          other.identityDocPath == this.identityDocPath &&
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class VisitSignaturesCompanion extends UpdateCompanion<VisitSignature> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> signatureType;
  final Value<String> filePath;
  final Value<String?> signerName;
  final Value<String?> identityDocPath;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const VisitSignaturesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.signatureType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.signerName = const Value.absent(),
    this.identityDocPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitSignaturesCompanion.insert({
    required String id,
    required String visitId,
    required String signatureType,
    required String filePath,
    this.signerName = const Value.absent(),
    this.identityDocPath = const Value.absent(),
    required DateTime createdAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       signatureType = Value(signatureType),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<VisitSignature> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? signatureType,
    Expression<String>? filePath,
    Expression<String>? signerName,
    Expression<String>? identityDocPath,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (signatureType != null) 'signature_type': signatureType,
      if (filePath != null) 'file_path': filePath,
      if (signerName != null) 'signer_name': signerName,
      if (identityDocPath != null) 'identity_doc_path': identityDocPath,
      if (createdAt != null) 'created_at': createdAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitSignaturesCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? signatureType,
    Value<String>? filePath,
    Value<String?>? signerName,
    Value<String?>? identityDocPath,
    Value<DateTime>? createdAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return VisitSignaturesCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      signatureType: signatureType ?? this.signatureType,
      filePath: filePath ?? this.filePath,
      signerName: signerName ?? this.signerName,
      identityDocPath: identityDocPath ?? this.identityDocPath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (signatureType.present) {
      map['signature_type'] = Variable<String>(signatureType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (signerName.present) {
      map['signer_name'] = Variable<String>(signerName.value);
    }
    if (identityDocPath.present) {
      map['identity_doc_path'] = Variable<String>(identityDocPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitSignaturesCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('signatureType: $signatureType, ')
          ..write('filePath: $filePath, ')
          ..write('signerName: $signerName, ')
          ..write('identityDocPath: $identityDocPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MassBalanceRecordsTable extends MassBalanceRecords
    with TableInfo<$MassBalanceRecordsTable, MassBalanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MassBalanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _substancesMeta = const VerificationMeta(
    'substances',
  );
  @override
  late final GeneratedColumn<String> substances = GeneratedColumn<String>(
    'substances',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purchasedMeta = const VerificationMeta(
    'purchased',
  );
  @override
  late final GeneratedColumn<double> purchased = GeneratedColumn<double>(
    'purchased',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<double> used = GeneratedColumn<double>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<double> stock = GeneratedColumn<double>(
    'stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discrepancyMeta = const VerificationMeta(
    'discrepancy',
  );
  @override
  late final GeneratedColumn<double> discrepancy = GeneratedColumn<double>(
    'discrepancy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _referenceDocumentsMeta =
      const VerificationMeta('referenceDocuments');
  @override
  late final GeneratedColumn<String> referenceDocuments =
      GeneratedColumn<String>(
        'reference_documents',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    substances,
    purchased,
    used,
    stock,
    discrepancy,
    referenceDocuments,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mass_balance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MassBalanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('substances')) {
      context.handle(
        _substancesMeta,
        substances.isAcceptableOrUnknown(data['substances']!, _substancesMeta),
      );
    }
    if (data.containsKey('purchased')) {
      context.handle(
        _purchasedMeta,
        purchased.isAcceptableOrUnknown(data['purchased']!, _purchasedMeta),
      );
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    }
    if (data.containsKey('discrepancy')) {
      context.handle(
        _discrepancyMeta,
        discrepancy.isAcceptableOrUnknown(
          data['discrepancy']!,
          _discrepancyMeta,
        ),
      );
    }
    if (data.containsKey('reference_documents')) {
      context.handle(
        _referenceDocumentsMeta,
        referenceDocuments.isAcceptableOrUnknown(
          data['reference_documents']!,
          _referenceDocumentsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MassBalanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MassBalanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      substances: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substances'],
      )!,
      purchased: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchased'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}used'],
      )!,
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock'],
      )!,
      discrepancy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discrepancy'],
      )!,
      referenceDocuments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_documents'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MassBalanceRecordsTable createAlias(String alias) {
    return $MassBalanceRecordsTable(attachedDatabase, alias);
  }
}

class MassBalanceRecord extends DataClass
    implements Insertable<MassBalanceRecord> {
  final String id;
  final String visitId;
  final String substances;
  final double purchased;
  final double used;
  final double stock;
  final double discrepancy;
  final String referenceDocuments;
  final DateTime updatedAt;
  const MassBalanceRecord({
    required this.id,
    required this.visitId,
    required this.substances,
    required this.purchased,
    required this.used,
    required this.stock,
    required this.discrepancy,
    required this.referenceDocuments,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['substances'] = Variable<String>(substances);
    map['purchased'] = Variable<double>(purchased);
    map['used'] = Variable<double>(used);
    map['stock'] = Variable<double>(stock);
    map['discrepancy'] = Variable<double>(discrepancy);
    map['reference_documents'] = Variable<String>(referenceDocuments);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MassBalanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return MassBalanceRecordsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      substances: Value(substances),
      purchased: Value(purchased),
      used: Value(used),
      stock: Value(stock),
      discrepancy: Value(discrepancy),
      referenceDocuments: Value(referenceDocuments),
      updatedAt: Value(updatedAt),
    );
  }

  factory MassBalanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MassBalanceRecord(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      substances: serializer.fromJson<String>(json['substances']),
      purchased: serializer.fromJson<double>(json['purchased']),
      used: serializer.fromJson<double>(json['used']),
      stock: serializer.fromJson<double>(json['stock']),
      discrepancy: serializer.fromJson<double>(json['discrepancy']),
      referenceDocuments: serializer.fromJson<String>(
        json['referenceDocuments'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'substances': serializer.toJson<String>(substances),
      'purchased': serializer.toJson<double>(purchased),
      'used': serializer.toJson<double>(used),
      'stock': serializer.toJson<double>(stock),
      'discrepancy': serializer.toJson<double>(discrepancy),
      'referenceDocuments': serializer.toJson<String>(referenceDocuments),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MassBalanceRecord copyWith({
    String? id,
    String? visitId,
    String? substances,
    double? purchased,
    double? used,
    double? stock,
    double? discrepancy,
    String? referenceDocuments,
    DateTime? updatedAt,
  }) => MassBalanceRecord(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    substances: substances ?? this.substances,
    purchased: purchased ?? this.purchased,
    used: used ?? this.used,
    stock: stock ?? this.stock,
    discrepancy: discrepancy ?? this.discrepancy,
    referenceDocuments: referenceDocuments ?? this.referenceDocuments,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MassBalanceRecord copyWithCompanion(MassBalanceRecordsCompanion data) {
    return MassBalanceRecord(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      substances: data.substances.present
          ? data.substances.value
          : this.substances,
      purchased: data.purchased.present ? data.purchased.value : this.purchased,
      used: data.used.present ? data.used.value : this.used,
      stock: data.stock.present ? data.stock.value : this.stock,
      discrepancy: data.discrepancy.present
          ? data.discrepancy.value
          : this.discrepancy,
      referenceDocuments: data.referenceDocuments.present
          ? data.referenceDocuments.value
          : this.referenceDocuments,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MassBalanceRecord(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('substances: $substances, ')
          ..write('purchased: $purchased, ')
          ..write('used: $used, ')
          ..write('stock: $stock, ')
          ..write('discrepancy: $discrepancy, ')
          ..write('referenceDocuments: $referenceDocuments, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    substances,
    purchased,
    used,
    stock,
    discrepancy,
    referenceDocuments,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MassBalanceRecord &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.substances == this.substances &&
          other.purchased == this.purchased &&
          other.used == this.used &&
          other.stock == this.stock &&
          other.discrepancy == this.discrepancy &&
          other.referenceDocuments == this.referenceDocuments &&
          other.updatedAt == this.updatedAt);
}

class MassBalanceRecordsCompanion extends UpdateCompanion<MassBalanceRecord> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> substances;
  final Value<double> purchased;
  final Value<double> used;
  final Value<double> stock;
  final Value<double> discrepancy;
  final Value<String> referenceDocuments;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MassBalanceRecordsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.substances = const Value.absent(),
    this.purchased = const Value.absent(),
    this.used = const Value.absent(),
    this.stock = const Value.absent(),
    this.discrepancy = const Value.absent(),
    this.referenceDocuments = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MassBalanceRecordsCompanion.insert({
    required String id,
    required String visitId,
    this.substances = const Value.absent(),
    this.purchased = const Value.absent(),
    this.used = const Value.absent(),
    this.stock = const Value.absent(),
    this.discrepancy = const Value.absent(),
    this.referenceDocuments = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       updatedAt = Value(updatedAt);
  static Insertable<MassBalanceRecord> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? substances,
    Expression<double>? purchased,
    Expression<double>? used,
    Expression<double>? stock,
    Expression<double>? discrepancy,
    Expression<String>? referenceDocuments,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (substances != null) 'substances': substances,
      if (purchased != null) 'purchased': purchased,
      if (used != null) 'used': used,
      if (stock != null) 'stock': stock,
      if (discrepancy != null) 'discrepancy': discrepancy,
      if (referenceDocuments != null) 'reference_documents': referenceDocuments,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MassBalanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? substances,
    Value<double>? purchased,
    Value<double>? used,
    Value<double>? stock,
    Value<double>? discrepancy,
    Value<String>? referenceDocuments,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MassBalanceRecordsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      substances: substances ?? this.substances,
      purchased: purchased ?? this.purchased,
      used: used ?? this.used,
      stock: stock ?? this.stock,
      discrepancy: discrepancy ?? this.discrepancy,
      referenceDocuments: referenceDocuments ?? this.referenceDocuments,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (substances.present) {
      map['substances'] = Variable<String>(substances.value);
    }
    if (purchased.present) {
      map['purchased'] = Variable<double>(purchased.value);
    }
    if (used.present) {
      map['used'] = Variable<double>(used.value);
    }
    if (stock.present) {
      map['stock'] = Variable<double>(stock.value);
    }
    if (discrepancy.present) {
      map['discrepancy'] = Variable<double>(discrepancy.value);
    }
    if (referenceDocuments.present) {
      map['reference_documents'] = Variable<String>(referenceDocuments.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MassBalanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('substances: $substances, ')
          ..write('purchased: $purchased, ')
          ..write('used: $used, ')
          ..write('stock: $stock, ')
          ..write('discrepancy: $discrepancy, ')
          ..write('referenceDocuments: $referenceDocuments, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitClosingsTable extends VisitClosings
    with TableInfo<$VisitClosingsTable, VisitClosing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitClosingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _correctiveActionsMeta = const VerificationMeta(
    'correctiveActions',
  );
  @override
  late final GeneratedColumn<String> correctiveActions =
      GeneratedColumn<String>(
        'corrective_actions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _resolutionDeadlineMeta =
      const VerificationMeta('resolutionDeadline');
  @override
  late final GeneratedColumn<DateTime> resolutionDeadline =
      GeneratedColumn<DateTime>(
        'resolution_deadline',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    visitId,
    correctiveActions,
    resolutionDeadline,
    isClosed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_closings';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitClosing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('corrective_actions')) {
      context.handle(
        _correctiveActionsMeta,
        correctiveActions.isAcceptableOrUnknown(
          data['corrective_actions']!,
          _correctiveActionsMeta,
        ),
      );
    }
    if (data.containsKey('resolution_deadline')) {
      context.handle(
        _resolutionDeadlineMeta,
        resolutionDeadline.isAcceptableOrUnknown(
          data['resolution_deadline']!,
          _resolutionDeadlineMeta,
        ),
      );
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {visitId};
  @override
  VisitClosing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitClosing(
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      correctiveActions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrective_actions'],
      )!,
      resolutionDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolution_deadline'],
      ),
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VisitClosingsTable createAlias(String alias) {
    return $VisitClosingsTable(attachedDatabase, alias);
  }
}

class VisitClosing extends DataClass implements Insertable<VisitClosing> {
  final String visitId;
  final String correctiveActions;
  final DateTime? resolutionDeadline;
  final bool isClosed;
  final DateTime updatedAt;
  const VisitClosing({
    required this.visitId,
    required this.correctiveActions,
    this.resolutionDeadline,
    required this.isClosed,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['visit_id'] = Variable<String>(visitId);
    map['corrective_actions'] = Variable<String>(correctiveActions);
    if (!nullToAbsent || resolutionDeadline != null) {
      map['resolution_deadline'] = Variable<DateTime>(resolutionDeadline);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitClosingsCompanion toCompanion(bool nullToAbsent) {
    return VisitClosingsCompanion(
      visitId: Value(visitId),
      correctiveActions: Value(correctiveActions),
      resolutionDeadline: resolutionDeadline == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionDeadline),
      isClosed: Value(isClosed),
      updatedAt: Value(updatedAt),
    );
  }

  factory VisitClosing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitClosing(
      visitId: serializer.fromJson<String>(json['visitId']),
      correctiveActions: serializer.fromJson<String>(json['correctiveActions']),
      resolutionDeadline: serializer.fromJson<DateTime?>(
        json['resolutionDeadline'],
      ),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'visitId': serializer.toJson<String>(visitId),
      'correctiveActions': serializer.toJson<String>(correctiveActions),
      'resolutionDeadline': serializer.toJson<DateTime?>(resolutionDeadline),
      'isClosed': serializer.toJson<bool>(isClosed),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VisitClosing copyWith({
    String? visitId,
    String? correctiveActions,
    Value<DateTime?> resolutionDeadline = const Value.absent(),
    bool? isClosed,
    DateTime? updatedAt,
  }) => VisitClosing(
    visitId: visitId ?? this.visitId,
    correctiveActions: correctiveActions ?? this.correctiveActions,
    resolutionDeadline: resolutionDeadline.present
        ? resolutionDeadline.value
        : this.resolutionDeadline,
    isClosed: isClosed ?? this.isClosed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VisitClosing copyWithCompanion(VisitClosingsCompanion data) {
    return VisitClosing(
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      correctiveActions: data.correctiveActions.present
          ? data.correctiveActions.value
          : this.correctiveActions,
      resolutionDeadline: data.resolutionDeadline.present
          ? data.resolutionDeadline.value
          : this.resolutionDeadline,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitClosing(')
          ..write('visitId: $visitId, ')
          ..write('correctiveActions: $correctiveActions, ')
          ..write('resolutionDeadline: $resolutionDeadline, ')
          ..write('isClosed: $isClosed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    visitId,
    correctiveActions,
    resolutionDeadline,
    isClosed,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitClosing &&
          other.visitId == this.visitId &&
          other.correctiveActions == this.correctiveActions &&
          other.resolutionDeadline == this.resolutionDeadline &&
          other.isClosed == this.isClosed &&
          other.updatedAt == this.updatedAt);
}

class VisitClosingsCompanion extends UpdateCompanion<VisitClosing> {
  final Value<String> visitId;
  final Value<String> correctiveActions;
  final Value<DateTime?> resolutionDeadline;
  final Value<bool> isClosed;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitClosingsCompanion({
    this.visitId = const Value.absent(),
    this.correctiveActions = const Value.absent(),
    this.resolutionDeadline = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitClosingsCompanion.insert({
    required String visitId,
    this.correctiveActions = const Value.absent(),
    this.resolutionDeadline = const Value.absent(),
    this.isClosed = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : visitId = Value(visitId),
       updatedAt = Value(updatedAt);
  static Insertable<VisitClosing> custom({
    Expression<String>? visitId,
    Expression<String>? correctiveActions,
    Expression<DateTime>? resolutionDeadline,
    Expression<bool>? isClosed,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (visitId != null) 'visit_id': visitId,
      if (correctiveActions != null) 'corrective_actions': correctiveActions,
      if (resolutionDeadline != null) 'resolution_deadline': resolutionDeadline,
      if (isClosed != null) 'is_closed': isClosed,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitClosingsCompanion copyWith({
    Value<String>? visitId,
    Value<String>? correctiveActions,
    Value<DateTime?>? resolutionDeadline,
    Value<bool>? isClosed,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitClosingsCompanion(
      visitId: visitId ?? this.visitId,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      resolutionDeadline: resolutionDeadline ?? this.resolutionDeadline,
      isClosed: isClosed ?? this.isClosed,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (correctiveActions.present) {
      map['corrective_actions'] = Variable<String>(correctiveActions.value);
    }
    if (resolutionDeadline.present) {
      map['resolution_deadline'] = Variable<DateTime>(resolutionDeadline.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitClosingsCompanion(')
          ..write('visitId: $visitId, ')
          ..write('correctiveActions: $correctiveActions, ')
          ..write('resolutionDeadline: $resolutionDeadline, ')
          ..write('isClosed: $isClosed, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitSamplesTable extends VisitSamples
    with TableInfo<$VisitSamplesTable, VisitSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _sampleCodeMeta = const VerificationMeta(
    'sampleCode',
  );
  @override
  late final GeneratedColumn<String> sampleCode = GeneratedColumn<String>(
    'sample_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _matrixTypeMeta = const VerificationMeta(
    'matrixType',
  );
  @override
  late final GeneratedColumn<String> matrixType = GeneratedColumn<String>(
    'matrix_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sealNumberMeta = const VerificationMeta(
    'sealNumber',
  );
  @override
  late final GeneratedColumn<String> sealNumber = GeneratedColumn<String>(
    'seal_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    sampleCode,
    matrixType,
    sealNumber,
    photoPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('sample_code')) {
      context.handle(
        _sampleCodeMeta,
        sampleCode.isAcceptableOrUnknown(data['sample_code']!, _sampleCodeMeta),
      );
    }
    if (data.containsKey('matrix_type')) {
      context.handle(
        _matrixTypeMeta,
        matrixType.isAcceptableOrUnknown(data['matrix_type']!, _matrixTypeMeta),
      );
    }
    if (data.containsKey('seal_number')) {
      context.handle(
        _sealNumberMeta,
        sealNumber.isAcceptableOrUnknown(data['seal_number']!, _sealNumberMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitSample(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      sampleCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sample_code'],
      )!,
      matrixType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matrix_type'],
      )!,
      sealNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seal_number'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VisitSamplesTable createAlias(String alias) {
    return $VisitSamplesTable(attachedDatabase, alias);
  }
}

class VisitSample extends DataClass implements Insertable<VisitSample> {
  final String id;
  final String visitId;
  final String sampleCode;
  final String matrixType;
  final String sealNumber;

  /// Foto del verbale di prelievo
  final String? photoPath;
  final DateTime createdAt;
  const VisitSample({
    required this.id,
    required this.visitId,
    required this.sampleCode,
    required this.matrixType,
    required this.sealNumber,
    this.photoPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['sample_code'] = Variable<String>(sampleCode);
    map['matrix_type'] = Variable<String>(matrixType);
    map['seal_number'] = Variable<String>(sealNumber);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VisitSamplesCompanion toCompanion(bool nullToAbsent) {
    return VisitSamplesCompanion(
      id: Value(id),
      visitId: Value(visitId),
      sampleCode: Value(sampleCode),
      matrixType: Value(matrixType),
      sealNumber: Value(sealNumber),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
    );
  }

  factory VisitSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitSample(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      sampleCode: serializer.fromJson<String>(json['sampleCode']),
      matrixType: serializer.fromJson<String>(json['matrixType']),
      sealNumber: serializer.fromJson<String>(json['sealNumber']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'sampleCode': serializer.toJson<String>(sampleCode),
      'matrixType': serializer.toJson<String>(matrixType),
      'sealNumber': serializer.toJson<String>(sealNumber),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VisitSample copyWith({
    String? id,
    String? visitId,
    String? sampleCode,
    String? matrixType,
    String? sealNumber,
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
  }) => VisitSample(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    sampleCode: sampleCode ?? this.sampleCode,
    matrixType: matrixType ?? this.matrixType,
    sealNumber: sealNumber ?? this.sealNumber,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
  );
  VisitSample copyWithCompanion(VisitSamplesCompanion data) {
    return VisitSample(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      sampleCode: data.sampleCode.present
          ? data.sampleCode.value
          : this.sampleCode,
      matrixType: data.matrixType.present
          ? data.matrixType.value
          : this.matrixType,
      sealNumber: data.sealNumber.present
          ? data.sealNumber.value
          : this.sealNumber,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitSample(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('sampleCode: $sampleCode, ')
          ..write('matrixType: $matrixType, ')
          ..write('sealNumber: $sealNumber, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    visitId,
    sampleCode,
    matrixType,
    sealNumber,
    photoPath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitSample &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.sampleCode == this.sampleCode &&
          other.matrixType == this.matrixType &&
          other.sealNumber == this.sealNumber &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt);
}

class VisitSamplesCompanion extends UpdateCompanion<VisitSample> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> sampleCode;
  final Value<String> matrixType;
  final Value<String> sealNumber;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VisitSamplesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.sampleCode = const Value.absent(),
    this.matrixType = const Value.absent(),
    this.sealNumber = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitSamplesCompanion.insert({
    required String id,
    required String visitId,
    this.sampleCode = const Value.absent(),
    this.matrixType = const Value.absent(),
    this.sealNumber = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       createdAt = Value(createdAt);
  static Insertable<VisitSample> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? sampleCode,
    Expression<String>? matrixType,
    Expression<String>? sealNumber,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (sampleCode != null) 'sample_code': sampleCode,
      if (matrixType != null) 'matrix_type': matrixType,
      if (sealNumber != null) 'seal_number': sealNumber,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitSamplesCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? sampleCode,
    Value<String>? matrixType,
    Value<String>? sealNumber,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VisitSamplesCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      sampleCode: sampleCode ?? this.sampleCode,
      matrixType: matrixType ?? this.matrixType,
      sealNumber: sealNumber ?? this.sealNumber,
      photoPath: photoPath ?? this.photoPath,
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
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (sampleCode.present) {
      map['sample_code'] = Variable<String>(sampleCode.value);
    }
    if (matrixType.present) {
      map['matrix_type'] = Variable<String>(matrixType.value);
    }
    if (sealNumber.present) {
      map['seal_number'] = Variable<String>(sealNumber.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
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
    return (StringBuffer('VisitSamplesCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('sampleCode: $sampleCode, ')
          ..write('matrixType: $matrixType, ')
          ..write('sealNumber: $sealNumber, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MassBalanceDocumentsTable extends MassBalanceDocuments
    with TableInfo<$MassBalanceDocumentsTable, MassBalanceDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MassBalanceDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitIdMeta = const VerificationMeta(
    'visitId',
  );
  @override
  late final GeneratedColumn<String> visitId = GeneratedColumn<String>(
    'visit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    visitId,
    docType,
    filePath,
    fileName,
    caption,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mass_balance_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<MassBalanceDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('visit_id')) {
      context.handle(
        _visitIdMeta,
        visitId.isAcceptableOrUnknown(data['visit_id']!, _visitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_visitIdMeta);
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MassBalanceDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MassBalanceDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      visitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_id'],
      )!,
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MassBalanceDocumentsTable createAlias(String alias) {
    return $MassBalanceDocumentsTable(attachedDatabase, alias);
  }
}

class MassBalanceDocument extends DataClass
    implements Insertable<MassBalanceDocument> {
  final String id;
  final String visitId;

  /// Tipo documento: 'entrata' (fatture acquisto) o 'uscita' (quaderno campagna, DDT)
  final String docType;

  /// Percorso file sul filesystem
  final String filePath;

  /// Nome originale del file
  final String fileName;

  /// Descrizione / didascalia opzionale
  final String caption;
  final DateTime createdAt;
  const MassBalanceDocument({
    required this.id,
    required this.visitId,
    required this.docType,
    required this.filePath,
    required this.fileName,
    required this.caption,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['visit_id'] = Variable<String>(visitId);
    map['doc_type'] = Variable<String>(docType);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['caption'] = Variable<String>(caption);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MassBalanceDocumentsCompanion toCompanion(bool nullToAbsent) {
    return MassBalanceDocumentsCompanion(
      id: Value(id),
      visitId: Value(visitId),
      docType: Value(docType),
      filePath: Value(filePath),
      fileName: Value(fileName),
      caption: Value(caption),
      createdAt: Value(createdAt),
    );
  }

  factory MassBalanceDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MassBalanceDocument(
      id: serializer.fromJson<String>(json['id']),
      visitId: serializer.fromJson<String>(json['visitId']),
      docType: serializer.fromJson<String>(json['docType']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      caption: serializer.fromJson<String>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'visitId': serializer.toJson<String>(visitId),
      'docType': serializer.toJson<String>(docType),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'caption': serializer.toJson<String>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MassBalanceDocument copyWith({
    String? id,
    String? visitId,
    String? docType,
    String? filePath,
    String? fileName,
    String? caption,
    DateTime? createdAt,
  }) => MassBalanceDocument(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    docType: docType ?? this.docType,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    caption: caption ?? this.caption,
    createdAt: createdAt ?? this.createdAt,
  );
  MassBalanceDocument copyWithCompanion(MassBalanceDocumentsCompanion data) {
    return MassBalanceDocument(
      id: data.id.present ? data.id.value : this.id,
      visitId: data.visitId.present ? data.visitId.value : this.visitId,
      docType: data.docType.present ? data.docType.value : this.docType,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MassBalanceDocument(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('docType: $docType, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, visitId, docType, filePath, fileName, caption, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MassBalanceDocument &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.docType == this.docType &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt);
}

class MassBalanceDocumentsCompanion
    extends UpdateCompanion<MassBalanceDocument> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> docType;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String> caption;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MassBalanceDocumentsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.docType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MassBalanceDocumentsCompanion.insert({
    required String id,
    required String visitId,
    required String docType,
    required String filePath,
    this.fileName = const Value.absent(),
    this.caption = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       visitId = Value(visitId),
       docType = Value(docType),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<MassBalanceDocument> custom({
    Expression<String>? id,
    Expression<String>? visitId,
    Expression<String>? docType,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (docType != null) 'doc_type': docType,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MassBalanceDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? visitId,
    Value<String>? docType,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<String>? caption,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MassBalanceDocumentsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      docType: docType ?? this.docType,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      caption: caption ?? this.caption,
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
    if (visitId.present) {
      map['visit_id'] = Variable<String>(visitId.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
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
    return (StringBuffer('MassBalanceDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('visitId: $visitId, ')
          ..write('docType: $docType, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectorsTable extends Inspectors
    with TableInfo<$InspectorsTable, Inspector> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fullName,
    email,
    phone,
    region,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspectors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Inspector> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Inspector map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Inspector(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InspectorsTable createAlias(String alias) {
    return $InspectorsTable(attachedDatabase, alias);
  }
}

class Inspector extends DataClass implements Insertable<Inspector> {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String region;
  final bool isActive;
  final DateTime createdAt;
  const Inspector({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.region,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['region'] = Variable<String>(region);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InspectorsCompanion toCompanion(bool nullToAbsent) {
    return InspectorsCompanion(
      id: Value(id),
      fullName: Value(fullName),
      email: Value(email),
      phone: Value(phone),
      region: Value(region),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory Inspector.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Inspector(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      region: serializer.fromJson<String>(json['region']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'region': serializer.toJson<String>(region),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Inspector copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? region,
    bool? isActive,
    DateTime? createdAt,
  }) => Inspector(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    region: region ?? this.region,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  Inspector copyWithCompanion(InspectorsCompanion data) {
    return Inspector(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      region: data.region.present ? data.region.value : this.region,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Inspector(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('region: $region, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fullName, email, phone, region, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Inspector &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.region == this.region &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class InspectorsCompanion extends UpdateCompanion<Inspector> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> region;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const InspectorsCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.region = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectorsCompanion.insert({
    required String id,
    this.fullName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.region = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<Inspector> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? region,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (region != null) 'region': region,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectorsCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? region,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return InspectorsCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      isActive: isActive ?? this.isActive,
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
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('InspectorsCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('region: $region, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityLogsTable extends ActivityLogs
    with TableInfo<$ActivityLogsTable, ActivityLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    action,
    description,
    actor,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ActivityLogsTable createAlias(String alias) {
    return $ActivityLogsTable(attachedDatabase, alias);
  }
}

class ActivityLog extends DataClass implements Insertable<ActivityLog> {
  final int id;
  final String action;
  final String description;
  final String actor;
  final DateTime createdAt;
  const ActivityLog({
    required this.id,
    required this.action,
    required this.description,
    required this.actor,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['description'] = Variable<String>(description);
    map['actor'] = Variable<String>(actor);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ActivityLogsCompanion toCompanion(bool nullToAbsent) {
    return ActivityLogsCompanion(
      id: Value(id),
      action: Value(action),
      description: Value(description),
      actor: Value(actor),
      createdAt: Value(createdAt),
    );
  }

  factory ActivityLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityLog(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      description: serializer.fromJson<String>(json['description']),
      actor: serializer.fromJson<String>(json['actor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'description': serializer.toJson<String>(description),
      'actor': serializer.toJson<String>(actor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ActivityLog copyWith({
    int? id,
    String? action,
    String? description,
    String? actor,
    DateTime? createdAt,
  }) => ActivityLog(
    id: id ?? this.id,
    action: action ?? this.action,
    description: description ?? this.description,
    actor: actor ?? this.actor,
    createdAt: createdAt ?? this.createdAt,
  );
  ActivityLog copyWithCompanion(ActivityLogsCompanion data) {
    return ActivityLog(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      description: data.description.present
          ? data.description.value
          : this.description,
      actor: data.actor.present ? data.actor.value : this.actor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLog(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('description: $description, ')
          ..write('actor: $actor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, description, actor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityLog &&
          other.id == this.id &&
          other.action == this.action &&
          other.description == this.description &&
          other.actor == this.actor &&
          other.createdAt == this.createdAt);
}

class ActivityLogsCompanion extends UpdateCompanion<ActivityLog> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> description;
  final Value<String> actor;
  final Value<DateTime> createdAt;
  const ActivityLogsCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.description = const Value.absent(),
    this.actor = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ActivityLogsCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String description,
    required String actor,
    required DateTime createdAt,
  }) : action = Value(action),
       description = Value(description),
       actor = Value(actor),
       createdAt = Value(createdAt);
  static Insertable<ActivityLog> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? description,
    Expression<String>? actor,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (description != null) 'description': description,
      if (actor != null) 'actor': actor,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ActivityLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? action,
    Value<String>? description,
    Value<String>? actor,
    Value<DateTime>? createdAt,
  }) {
    return ActivityLogsCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      description: description ?? this.description,
      actor: actor ?? this.actor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLogsCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('description: $description, ')
          ..write('actor: $actor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MasterCompaniesTable extends MasterCompanies
    with TableInfo<$MasterCompaniesTable, MasterCompany> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasterCompaniesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cuaaMeta = const VerificationMeta('cuaa');
  @override
  late final GeneratedColumn<String> cuaa = GeneratedColumn<String>(
    'cuaa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ragioneSocialeMeta = const VerificationMeta(
    'ragioneSociale',
  );
  @override
  late final GeneratedColumn<String> ragioneSociale = GeneratedColumn<String>(
    'ragione_sociale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partitaIvaMeta = const VerificationMeta(
    'partitaIva',
  );
  @override
  late final GeneratedColumn<String> partitaIva = GeneratedColumn<String>(
    'partita_iva',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _indirizzoMeta = const VerificationMeta(
    'indirizzo',
  );
  @override
  late final GeneratedColumn<String> indirizzo = GeneratedColumn<String>(
    'indirizzo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _capMeta = const VerificationMeta('cap');
  @override
  late final GeneratedColumn<String> cap = GeneratedColumn<String>(
    'cap',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _comuneMeta = const VerificationMeta('comune');
  @override
  late final GeneratedColumn<String> comune = GeneratedColumn<String>(
    'comune',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _provinciaMeta = const VerificationMeta(
    'provincia',
  );
  @override
  late final GeneratedColumn<String> provincia = GeneratedColumn<String>(
    'provincia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _referenteMeta = const VerificationMeta(
    'referente',
  );
  @override
  late final GeneratedColumn<String> referente = GeneratedColumn<String>(
    'referente',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pecMeta = const VerificationMeta('pec');
  @override
  late final GeneratedColumn<String> pec = GeneratedColumn<String>(
    'pec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cuaa,
    ragioneSociale,
    partitaIva,
    indirizzo,
    cap,
    comune,
    provincia,
    referente,
    telefono,
    email,
    pec,
    latitude,
    longitude,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'master_companies';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasterCompany> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cuaa')) {
      context.handle(
        _cuaaMeta,
        cuaa.isAcceptableOrUnknown(data['cuaa']!, _cuaaMeta),
      );
    } else if (isInserting) {
      context.missing(_cuaaMeta);
    }
    if (data.containsKey('ragione_sociale')) {
      context.handle(
        _ragioneSocialeMeta,
        ragioneSociale.isAcceptableOrUnknown(
          data['ragione_sociale']!,
          _ragioneSocialeMeta,
        ),
      );
    }
    if (data.containsKey('partita_iva')) {
      context.handle(
        _partitaIvaMeta,
        partitaIva.isAcceptableOrUnknown(data['partita_iva']!, _partitaIvaMeta),
      );
    }
    if (data.containsKey('indirizzo')) {
      context.handle(
        _indirizzoMeta,
        indirizzo.isAcceptableOrUnknown(data['indirizzo']!, _indirizzoMeta),
      );
    }
    if (data.containsKey('cap')) {
      context.handle(
        _capMeta,
        cap.isAcceptableOrUnknown(data['cap']!, _capMeta),
      );
    }
    if (data.containsKey('comune')) {
      context.handle(
        _comuneMeta,
        comune.isAcceptableOrUnknown(data['comune']!, _comuneMeta),
      );
    }
    if (data.containsKey('provincia')) {
      context.handle(
        _provinciaMeta,
        provincia.isAcceptableOrUnknown(data['provincia']!, _provinciaMeta),
      );
    }
    if (data.containsKey('referente')) {
      context.handle(
        _referenteMeta,
        referente.isAcceptableOrUnknown(data['referente']!, _referenteMeta),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('pec')) {
      context.handle(
        _pecMeta,
        pec.isAcceptableOrUnknown(data['pec']!, _pecMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cuaa};
  @override
  MasterCompany map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasterCompany(
      cuaa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cuaa'],
      )!,
      ragioneSociale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ragione_sociale'],
      )!,
      partitaIva: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partita_iva'],
      )!,
      indirizzo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}indirizzo'],
      )!,
      cap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cap'],
      )!,
      comune: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comune'],
      )!,
      provincia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provincia'],
      )!,
      referente: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referente'],
      )!,
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      pec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pec'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MasterCompaniesTable createAlias(String alias) {
    return $MasterCompaniesTable(attachedDatabase, alias);
  }
}

class MasterCompany extends DataClass implements Insertable<MasterCompany> {
  final String cuaa;
  final String ragioneSociale;
  final String partitaIva;
  final String indirizzo;
  final String cap;
  final String comune;
  final String provincia;
  final String referente;
  final String telefono;
  final String email;
  final String pec;
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;
  const MasterCompany({
    required this.cuaa,
    required this.ragioneSociale,
    required this.partitaIva,
    required this.indirizzo,
    required this.cap,
    required this.comune,
    required this.provincia,
    required this.referente,
    required this.telefono,
    required this.email,
    required this.pec,
    this.latitude,
    this.longitude,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cuaa'] = Variable<String>(cuaa);
    map['ragione_sociale'] = Variable<String>(ragioneSociale);
    map['partita_iva'] = Variable<String>(partitaIva);
    map['indirizzo'] = Variable<String>(indirizzo);
    map['cap'] = Variable<String>(cap);
    map['comune'] = Variable<String>(comune);
    map['provincia'] = Variable<String>(provincia);
    map['referente'] = Variable<String>(referente);
    map['telefono'] = Variable<String>(telefono);
    map['email'] = Variable<String>(email);
    map['pec'] = Variable<String>(pec);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MasterCompaniesCompanion toCompanion(bool nullToAbsent) {
    return MasterCompaniesCompanion(
      cuaa: Value(cuaa),
      ragioneSociale: Value(ragioneSociale),
      partitaIva: Value(partitaIva),
      indirizzo: Value(indirizzo),
      cap: Value(cap),
      comune: Value(comune),
      provincia: Value(provincia),
      referente: Value(referente),
      telefono: Value(telefono),
      email: Value(email),
      pec: Value(pec),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      updatedAt: Value(updatedAt),
    );
  }

  factory MasterCompany.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasterCompany(
      cuaa: serializer.fromJson<String>(json['cuaa']),
      ragioneSociale: serializer.fromJson<String>(json['ragioneSociale']),
      partitaIva: serializer.fromJson<String>(json['partitaIva']),
      indirizzo: serializer.fromJson<String>(json['indirizzo']),
      cap: serializer.fromJson<String>(json['cap']),
      comune: serializer.fromJson<String>(json['comune']),
      provincia: serializer.fromJson<String>(json['provincia']),
      referente: serializer.fromJson<String>(json['referente']),
      telefono: serializer.fromJson<String>(json['telefono']),
      email: serializer.fromJson<String>(json['email']),
      pec: serializer.fromJson<String>(json['pec']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cuaa': serializer.toJson<String>(cuaa),
      'ragioneSociale': serializer.toJson<String>(ragioneSociale),
      'partitaIva': serializer.toJson<String>(partitaIva),
      'indirizzo': serializer.toJson<String>(indirizzo),
      'cap': serializer.toJson<String>(cap),
      'comune': serializer.toJson<String>(comune),
      'provincia': serializer.toJson<String>(provincia),
      'referente': serializer.toJson<String>(referente),
      'telefono': serializer.toJson<String>(telefono),
      'email': serializer.toJson<String>(email),
      'pec': serializer.toJson<String>(pec),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MasterCompany copyWith({
    String? cuaa,
    String? ragioneSociale,
    String? partitaIva,
    String? indirizzo,
    String? cap,
    String? comune,
    String? provincia,
    String? referente,
    String? telefono,
    String? email,
    String? pec,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? updatedAt,
  }) => MasterCompany(
    cuaa: cuaa ?? this.cuaa,
    ragioneSociale: ragioneSociale ?? this.ragioneSociale,
    partitaIva: partitaIva ?? this.partitaIva,
    indirizzo: indirizzo ?? this.indirizzo,
    cap: cap ?? this.cap,
    comune: comune ?? this.comune,
    provincia: provincia ?? this.provincia,
    referente: referente ?? this.referente,
    telefono: telefono ?? this.telefono,
    email: email ?? this.email,
    pec: pec ?? this.pec,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MasterCompany copyWithCompanion(MasterCompaniesCompanion data) {
    return MasterCompany(
      cuaa: data.cuaa.present ? data.cuaa.value : this.cuaa,
      ragioneSociale: data.ragioneSociale.present
          ? data.ragioneSociale.value
          : this.ragioneSociale,
      partitaIva: data.partitaIva.present
          ? data.partitaIva.value
          : this.partitaIva,
      indirizzo: data.indirizzo.present ? data.indirizzo.value : this.indirizzo,
      cap: data.cap.present ? data.cap.value : this.cap,
      comune: data.comune.present ? data.comune.value : this.comune,
      provincia: data.provincia.present ? data.provincia.value : this.provincia,
      referente: data.referente.present ? data.referente.value : this.referente,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      email: data.email.present ? data.email.value : this.email,
      pec: data.pec.present ? data.pec.value : this.pec,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasterCompany(')
          ..write('cuaa: $cuaa, ')
          ..write('ragioneSociale: $ragioneSociale, ')
          ..write('partitaIva: $partitaIva, ')
          ..write('indirizzo: $indirizzo, ')
          ..write('cap: $cap, ')
          ..write('comune: $comune, ')
          ..write('provincia: $provincia, ')
          ..write('referente: $referente, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('pec: $pec, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cuaa,
    ragioneSociale,
    partitaIva,
    indirizzo,
    cap,
    comune,
    provincia,
    referente,
    telefono,
    email,
    pec,
    latitude,
    longitude,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasterCompany &&
          other.cuaa == this.cuaa &&
          other.ragioneSociale == this.ragioneSociale &&
          other.partitaIva == this.partitaIva &&
          other.indirizzo == this.indirizzo &&
          other.cap == this.cap &&
          other.comune == this.comune &&
          other.provincia == this.provincia &&
          other.referente == this.referente &&
          other.telefono == this.telefono &&
          other.email == this.email &&
          other.pec == this.pec &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.updatedAt == this.updatedAt);
}

class MasterCompaniesCompanion extends UpdateCompanion<MasterCompany> {
  final Value<String> cuaa;
  final Value<String> ragioneSociale;
  final Value<String> partitaIva;
  final Value<String> indirizzo;
  final Value<String> cap;
  final Value<String> comune;
  final Value<String> provincia;
  final Value<String> referente;
  final Value<String> telefono;
  final Value<String> email;
  final Value<String> pec;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MasterCompaniesCompanion({
    this.cuaa = const Value.absent(),
    this.ragioneSociale = const Value.absent(),
    this.partitaIva = const Value.absent(),
    this.indirizzo = const Value.absent(),
    this.cap = const Value.absent(),
    this.comune = const Value.absent(),
    this.provincia = const Value.absent(),
    this.referente = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.pec = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasterCompaniesCompanion.insert({
    required String cuaa,
    this.ragioneSociale = const Value.absent(),
    this.partitaIva = const Value.absent(),
    this.indirizzo = const Value.absent(),
    this.cap = const Value.absent(),
    this.comune = const Value.absent(),
    this.provincia = const Value.absent(),
    this.referente = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.pec = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cuaa = Value(cuaa),
       updatedAt = Value(updatedAt);
  static Insertable<MasterCompany> custom({
    Expression<String>? cuaa,
    Expression<String>? ragioneSociale,
    Expression<String>? partitaIva,
    Expression<String>? indirizzo,
    Expression<String>? cap,
    Expression<String>? comune,
    Expression<String>? provincia,
    Expression<String>? referente,
    Expression<String>? telefono,
    Expression<String>? email,
    Expression<String>? pec,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cuaa != null) 'cuaa': cuaa,
      if (ragioneSociale != null) 'ragione_sociale': ragioneSociale,
      if (partitaIva != null) 'partita_iva': partitaIva,
      if (indirizzo != null) 'indirizzo': indirizzo,
      if (cap != null) 'cap': cap,
      if (comune != null) 'comune': comune,
      if (provincia != null) 'provincia': provincia,
      if (referente != null) 'referente': referente,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (pec != null) 'pec': pec,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasterCompaniesCompanion copyWith({
    Value<String>? cuaa,
    Value<String>? ragioneSociale,
    Value<String>? partitaIva,
    Value<String>? indirizzo,
    Value<String>? cap,
    Value<String>? comune,
    Value<String>? provincia,
    Value<String>? referente,
    Value<String>? telefono,
    Value<String>? email,
    Value<String>? pec,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MasterCompaniesCompanion(
      cuaa: cuaa ?? this.cuaa,
      ragioneSociale: ragioneSociale ?? this.ragioneSociale,
      partitaIva: partitaIva ?? this.partitaIva,
      indirizzo: indirizzo ?? this.indirizzo,
      cap: cap ?? this.cap,
      comune: comune ?? this.comune,
      provincia: provincia ?? this.provincia,
      referente: referente ?? this.referente,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      pec: pec ?? this.pec,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cuaa.present) {
      map['cuaa'] = Variable<String>(cuaa.value);
    }
    if (ragioneSociale.present) {
      map['ragione_sociale'] = Variable<String>(ragioneSociale.value);
    }
    if (partitaIva.present) {
      map['partita_iva'] = Variable<String>(partitaIva.value);
    }
    if (indirizzo.present) {
      map['indirizzo'] = Variable<String>(indirizzo.value);
    }
    if (cap.present) {
      map['cap'] = Variable<String>(cap.value);
    }
    if (comune.present) {
      map['comune'] = Variable<String>(comune.value);
    }
    if (provincia.present) {
      map['provincia'] = Variable<String>(provincia.value);
    }
    if (referente.present) {
      map['referente'] = Variable<String>(referente.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (pec.present) {
      map['pec'] = Variable<String>(pec.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasterCompaniesCompanion(')
          ..write('cuaa: $cuaa, ')
          ..write('ragioneSociale: $ragioneSociale, ')
          ..write('partitaIva: $partitaIva, ')
          ..write('indirizzo: $indirizzo, ')
          ..write('cap: $cap, ')
          ..write('comune: $comune, ')
          ..write('provincia: $provincia, ')
          ..write('referente: $referente, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('pec: $pec, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $VisitCompaniesTable visitCompanies = $VisitCompaniesTable(this);
  late final $VisitUecsTable visitUecs = $VisitUecsTable(this);
  late final $VisitLotsTable visitLots = $VisitLotsTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $ChecklistResponsesTable checklistResponses =
      $ChecklistResponsesTable(this);
  late final $VisitAttachmentsTable visitAttachments = $VisitAttachmentsTable(
    this,
  );
  late final $VisitSignaturesTable visitSignatures = $VisitSignaturesTable(
    this,
  );
  late final $MassBalanceRecordsTable massBalanceRecords =
      $MassBalanceRecordsTable(this);
  late final $VisitClosingsTable visitClosings = $VisitClosingsTable(this);
  late final $VisitSamplesTable visitSamples = $VisitSamplesTable(this);
  late final $MassBalanceDocumentsTable massBalanceDocuments =
      $MassBalanceDocumentsTable(this);
  late final $InspectorsTable inspectors = $InspectorsTable(this);
  late final $ActivityLogsTable activityLogs = $ActivityLogsTable(this);
  late final $MasterCompaniesTable masterCompanies = $MasterCompaniesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    visits,
    visitCompanies,
    visitUecs,
    visitLots,
    checklistItems,
    checklistResponses,
    visitAttachments,
    visitSignatures,
    massBalanceRecords,
    visitClosings,
    visitSamples,
    massBalanceDocuments,
    inspectors,
    activityLogs,
    masterCompanies,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_companies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_uecs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_uecs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_lots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_uecs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('checklist_responses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_attachments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visit_uecs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_attachments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'checklist_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_attachments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_signatures', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mass_balance_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_closings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visit_samples', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mass_balance_documents', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      required String id,
      required DateTime scheduledAt,
      required String companyName,
      required String crop,
      required int status,
      Value<String> visitType,
      Value<int> durationHours,
      Value<int> plannedDurationHours,
      Value<String> durationJustification,
      required DateTime updatedAt,
      Value<String> inspectorName,
      Value<String> companionName,
      Value<String> representativeName,
      Value<int> rowid,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<String> id,
      Value<DateTime> scheduledAt,
      Value<String> companyName,
      Value<String> crop,
      Value<int> status,
      Value<String> visitType,
      Value<int> durationHours,
      Value<int> plannedDurationHours,
      Value<String> durationJustification,
      Value<DateTime> updatedAt,
      Value<String> inspectorName,
      Value<String> companionName,
      Value<String> representativeName,
      Value<int> rowid,
    });

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, Visit> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VisitCompaniesTable, List<VisitCompany>>
  _visitCompaniesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitCompanies,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitCompanies.visitId),
  );

  $$VisitCompaniesTableProcessedTableManager get visitCompaniesRefs {
    final manager = $$VisitCompaniesTableTableManager(
      $_db,
      $_db.visitCompanies,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitCompaniesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitUecsTable, List<VisitUec>>
  _visitUecsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitUecs,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitUecs.visitId),
  );

  $$VisitUecsTableProcessedTableManager get visitUecsRefs {
    final manager = $$VisitUecsTableTableManager(
      $_db,
      $_db.visitUecs,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitUecsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitAttachmentsTable, List<VisitAttachment>>
  _visitAttachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitAttachments,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitAttachments.visitId),
  );

  $$VisitAttachmentsTableProcessedTableManager get visitAttachmentsRefs {
    final manager = $$VisitAttachmentsTableTableManager(
      $_db,
      $_db.visitAttachments,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _visitAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitSignaturesTable, List<VisitSignature>>
  _visitSignaturesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitSignatures,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitSignatures.visitId),
  );

  $$VisitSignaturesTableProcessedTableManager get visitSignaturesRefs {
    final manager = $$VisitSignaturesTableTableManager(
      $_db,
      $_db.visitSignatures,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _visitSignaturesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MassBalanceRecordsTable, List<MassBalanceRecord>>
  _massBalanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.massBalanceRecords,
        aliasName: $_aliasNameGenerator(
          db.visits.id,
          db.massBalanceRecords.visitId,
        ),
      );

  $$MassBalanceRecordsTableProcessedTableManager get massBalanceRecordsRefs {
    final manager = $$MassBalanceRecordsTableTableManager(
      $_db,
      $_db.massBalanceRecords,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _massBalanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitClosingsTable, List<VisitClosing>>
  _visitClosingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitClosings,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitClosings.visitId),
  );

  $$VisitClosingsTableProcessedTableManager get visitClosingsRefs {
    final manager = $$VisitClosingsTableTableManager(
      $_db,
      $_db.visitClosings,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitClosingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitSamplesTable, List<VisitSample>>
  _visitSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitSamples,
    aliasName: $_aliasNameGenerator(db.visits.id, db.visitSamples.visitId),
  );

  $$VisitSamplesTableProcessedTableManager get visitSamplesRefs {
    final manager = $$VisitSamplesTableTableManager(
      $_db,
      $_db.visitSamples,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MassBalanceDocumentsTable,
    List<MassBalanceDocument>
  >
  _massBalanceDocumentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.massBalanceDocuments,
        aliasName: $_aliasNameGenerator(
          db.visits.id,
          db.massBalanceDocuments.visitId,
        ),
      );

  $$MassBalanceDocumentsTableProcessedTableManager
  get massBalanceDocumentsRefs {
    final manager = $$MassBalanceDocumentsTableTableManager(
      $_db,
      $_db.massBalanceDocuments,
    ).filter((f) => f.visitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _massBalanceDocumentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
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

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedDurationHours => $composableBuilder(
    column: $table.plannedDurationHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get durationJustification => $composableBuilder(
    column: $table.durationJustification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inspectorName => $composableBuilder(
    column: $table.inspectorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionName => $composableBuilder(
    column: $table.companionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get representativeName => $composableBuilder(
    column: $table.representativeName,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> visitCompaniesRefs(
    Expression<bool> Function($$VisitCompaniesTableFilterComposer f) f,
  ) {
    final $$VisitCompaniesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitCompanies,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitCompaniesTableFilterComposer(
            $db: $db,
            $table: $db.visitCompanies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitUecsRefs(
    Expression<bool> Function($$VisitUecsTableFilterComposer f) f,
  ) {
    final $$VisitUecsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableFilterComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitAttachmentsRefs(
    Expression<bool> Function($$VisitAttachmentsTableFilterComposer f) f,
  ) {
    final $$VisitAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitSignaturesRefs(
    Expression<bool> Function($$VisitSignaturesTableFilterComposer f) f,
  ) {
    final $$VisitSignaturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSignatures,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSignaturesTableFilterComposer(
            $db: $db,
            $table: $db.visitSignatures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> massBalanceRecordsRefs(
    Expression<bool> Function($$MassBalanceRecordsTableFilterComposer f) f,
  ) {
    final $$MassBalanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.massBalanceRecords,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MassBalanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.massBalanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitClosingsRefs(
    Expression<bool> Function($$VisitClosingsTableFilterComposer f) f,
  ) {
    final $$VisitClosingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitClosings,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitClosingsTableFilterComposer(
            $db: $db,
            $table: $db.visitClosings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitSamplesRefs(
    Expression<bool> Function($$VisitSamplesTableFilterComposer f) f,
  ) {
    final $$VisitSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSamples,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSamplesTableFilterComposer(
            $db: $db,
            $table: $db.visitSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> massBalanceDocumentsRefs(
    Expression<bool> Function($$MassBalanceDocumentsTableFilterComposer f) f,
  ) {
    final $$MassBalanceDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.massBalanceDocuments,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MassBalanceDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.massBalanceDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crop => $composableBuilder(
    column: $table.crop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedDurationHours => $composableBuilder(
    column: $table.plannedDurationHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get durationJustification => $composableBuilder(
    column: $table.durationJustification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inspectorName => $composableBuilder(
    column: $table.inspectorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionName => $composableBuilder(
    column: $table.companionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get representativeName => $composableBuilder(
    column: $table.representativeName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crop =>
      $composableBuilder(column: $table.crop, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get visitType =>
      $composableBuilder(column: $table.visitType, builder: (column) => column);

  GeneratedColumn<int> get durationHours => $composableBuilder(
    column: $table.durationHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedDurationHours => $composableBuilder(
    column: $table.plannedDurationHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get durationJustification => $composableBuilder(
    column: $table.durationJustification,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get inspectorName => $composableBuilder(
    column: $table.inspectorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companionName => $composableBuilder(
    column: $table.companionName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get representativeName => $composableBuilder(
    column: $table.representativeName,
    builder: (column) => column,
  );

  Expression<T> visitCompaniesRefs<T extends Object>(
    Expression<T> Function($$VisitCompaniesTableAnnotationComposer a) f,
  ) {
    final $$VisitCompaniesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitCompanies,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitCompaniesTableAnnotationComposer(
            $db: $db,
            $table: $db.visitCompanies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitUecsRefs<T extends Object>(
    Expression<T> Function($$VisitUecsTableAnnotationComposer a) f,
  ) {
    final $$VisitUecsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitAttachmentsRefs<T extends Object>(
    Expression<T> Function($$VisitAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$VisitAttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitSignaturesRefs<T extends Object>(
    Expression<T> Function($$VisitSignaturesTableAnnotationComposer a) f,
  ) {
    final $$VisitSignaturesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSignatures,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSignaturesTableAnnotationComposer(
            $db: $db,
            $table: $db.visitSignatures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> massBalanceRecordsRefs<T extends Object>(
    Expression<T> Function($$MassBalanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$MassBalanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.massBalanceRecords,
          getReferencedColumn: (t) => t.visitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MassBalanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.massBalanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> visitClosingsRefs<T extends Object>(
    Expression<T> Function($$VisitClosingsTableAnnotationComposer a) f,
  ) {
    final $$VisitClosingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitClosings,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitClosingsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitClosings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitSamplesRefs<T extends Object>(
    Expression<T> Function($$VisitSamplesTableAnnotationComposer a) f,
  ) {
    final $$VisitSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSamples,
      getReferencedColumn: (t) => t.visitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.visitSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> massBalanceDocumentsRefs<T extends Object>(
    Expression<T> Function($$MassBalanceDocumentsTableAnnotationComposer a) f,
  ) {
    final $$MassBalanceDocumentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.massBalanceDocuments,
          getReferencedColumn: (t) => t.visitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MassBalanceDocumentsTableAnnotationComposer(
                $db: $db,
                $table: $db.massBalanceDocuments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          Visit,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (Visit, $$VisitsTableReferences),
          Visit,
          PrefetchHooks Function({
            bool visitCompaniesRefs,
            bool visitUecsRefs,
            bool visitAttachmentsRefs,
            bool visitSignaturesRefs,
            bool massBalanceRecordsRefs,
            bool visitClosingsRefs,
            bool visitSamplesRefs,
            bool massBalanceDocumentsRefs,
          })
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<String> companyName = const Value.absent(),
                Value<String> crop = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> visitType = const Value.absent(),
                Value<int> durationHours = const Value.absent(),
                Value<int> plannedDurationHours = const Value.absent(),
                Value<String> durationJustification = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> inspectorName = const Value.absent(),
                Value<String> companionName = const Value.absent(),
                Value<String> representativeName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                scheduledAt: scheduledAt,
                companyName: companyName,
                crop: crop,
                status: status,
                visitType: visitType,
                durationHours: durationHours,
                plannedDurationHours: plannedDurationHours,
                durationJustification: durationJustification,
                updatedAt: updatedAt,
                inspectorName: inspectorName,
                companionName: companionName,
                representativeName: representativeName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime scheduledAt,
                required String companyName,
                required String crop,
                required int status,
                Value<String> visitType = const Value.absent(),
                Value<int> durationHours = const Value.absent(),
                Value<int> plannedDurationHours = const Value.absent(),
                Value<String> durationJustification = const Value.absent(),
                required DateTime updatedAt,
                Value<String> inspectorName = const Value.absent(),
                Value<String> companionName = const Value.absent(),
                Value<String> representativeName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                scheduledAt: scheduledAt,
                companyName: companyName,
                crop: crop,
                status: status,
                visitType: visitType,
                durationHours: durationHours,
                plannedDurationHours: plannedDurationHours,
                durationJustification: durationJustification,
                updatedAt: updatedAt,
                inspectorName: inspectorName,
                companionName: companionName,
                representativeName: representativeName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$VisitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                visitCompaniesRefs = false,
                visitUecsRefs = false,
                visitAttachmentsRefs = false,
                visitSignaturesRefs = false,
                massBalanceRecordsRefs = false,
                visitClosingsRefs = false,
                visitSamplesRefs = false,
                massBalanceDocumentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (visitCompaniesRefs) db.visitCompanies,
                    if (visitUecsRefs) db.visitUecs,
                    if (visitAttachmentsRefs) db.visitAttachments,
                    if (visitSignaturesRefs) db.visitSignatures,
                    if (massBalanceRecordsRefs) db.massBalanceRecords,
                    if (visitClosingsRefs) db.visitClosings,
                    if (visitSamplesRefs) db.visitSamples,
                    if (massBalanceDocumentsRefs) db.massBalanceDocuments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (visitCompaniesRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitCompany
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitCompaniesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitCompaniesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitUecsRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitUec
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitUecsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitUecsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitAttachmentsRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitSignaturesRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitSignature
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitSignaturesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitSignaturesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (massBalanceRecordsRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          MassBalanceRecord
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._massBalanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).massBalanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitClosingsRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitClosing
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitClosingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitClosingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitSamplesRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          VisitSample
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._visitSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (massBalanceDocumentsRefs)
                        await $_getPrefetchedData<
                          Visit,
                          $VisitsTable,
                          MassBalanceDocument
                        >(
                          currentTable: table,
                          referencedTable: $$VisitsTableReferences
                              ._massBalanceDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitsTableReferences(
                                db,
                                table,
                                p0,
                              ).massBalanceDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.visitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      Visit,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (Visit, $$VisitsTableReferences),
      Visit,
      PrefetchHooks Function({
        bool visitCompaniesRefs,
        bool visitUecsRefs,
        bool visitAttachmentsRefs,
        bool visitSignaturesRefs,
        bool massBalanceRecordsRefs,
        bool visitClosingsRefs,
        bool visitSamplesRefs,
        bool massBalanceDocumentsRefs,
      })
    >;
typedef $$VisitCompaniesTableCreateCompanionBuilder =
    VisitCompaniesCompanion Function({
      required String visitId,
      Value<String> ragioneSociale,
      Value<String> cuaa,
      Value<String> partitaIva,
      Value<String> indirizzo,
      Value<String> cap,
      Value<String> comune,
      Value<String> provincia,
      Value<String> referente,
      Value<String> telefono,
      Value<String> email,
      Value<String> pec,
      Value<String> submissionNumber,
      required DateTime updatedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isSynced,
      Value<bool> isNewOperator,
      Value<String> processingType,
      Value<String> thirdPartyCertNumber,
      Value<bool> siVerification,
      Value<String> latitudeText,
      Value<String> longitudeText,
      Value<String> manipulationSiteAddress,
      Value<String> peakPeriodFrom,
      Value<String> peakPeriodTo,
      Value<bool> isJointVisit,
      Value<String> jointVisitDetails,
      Value<String> marchioNature,
      Value<String> marchioProcesses,
      Value<bool> marchioLabelDraft,
      Value<int> rowid,
    });
typedef $$VisitCompaniesTableUpdateCompanionBuilder =
    VisitCompaniesCompanion Function({
      Value<String> visitId,
      Value<String> ragioneSociale,
      Value<String> cuaa,
      Value<String> partitaIva,
      Value<String> indirizzo,
      Value<String> cap,
      Value<String> comune,
      Value<String> provincia,
      Value<String> referente,
      Value<String> telefono,
      Value<String> email,
      Value<String> pec,
      Value<String> submissionNumber,
      Value<DateTime> updatedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isSynced,
      Value<bool> isNewOperator,
      Value<String> processingType,
      Value<String> thirdPartyCertNumber,
      Value<bool> siVerification,
      Value<String> latitudeText,
      Value<String> longitudeText,
      Value<String> manipulationSiteAddress,
      Value<String> peakPeriodFrom,
      Value<String> peakPeriodTo,
      Value<bool> isJointVisit,
      Value<String> jointVisitDetails,
      Value<String> marchioNature,
      Value<String> marchioProcesses,
      Value<bool> marchioLabelDraft,
      Value<int> rowid,
    });

final class $$VisitCompaniesTableReferences
    extends BaseReferences<_$AppDatabase, $VisitCompaniesTable, VisitCompany> {
  $$VisitCompaniesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitCompanies.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitCompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitCompaniesTable> {
  $$VisitCompaniesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cuaa => $composableBuilder(
    column: $table.cuaa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indirizzo => $composableBuilder(
    column: $table.indirizzo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cap => $composableBuilder(
    column: $table.cap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comune => $composableBuilder(
    column: $table.comune,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provincia => $composableBuilder(
    column: $table.provincia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referente => $composableBuilder(
    column: $table.referente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pec => $composableBuilder(
    column: $table.pec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submissionNumber => $composableBuilder(
    column: $table.submissionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNewOperator => $composableBuilder(
    column: $table.isNewOperator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingType => $composableBuilder(
    column: $table.processingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thirdPartyCertNumber => $composableBuilder(
    column: $table.thirdPartyCertNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get siVerification => $composableBuilder(
    column: $table.siVerification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latitudeText => $composableBuilder(
    column: $table.latitudeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get longitudeText => $composableBuilder(
    column: $table.longitudeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manipulationSiteAddress => $composableBuilder(
    column: $table.manipulationSiteAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peakPeriodFrom => $composableBuilder(
    column: $table.peakPeriodFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peakPeriodTo => $composableBuilder(
    column: $table.peakPeriodTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isJointVisit => $composableBuilder(
    column: $table.isJointVisit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jointVisitDetails => $composableBuilder(
    column: $table.jointVisitDetails,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marchioNature => $composableBuilder(
    column: $table.marchioNature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marchioProcesses => $composableBuilder(
    column: $table.marchioProcesses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get marchioLabelDraft => $composableBuilder(
    column: $table.marchioLabelDraft,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitCompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitCompaniesTable> {
  $$VisitCompaniesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cuaa => $composableBuilder(
    column: $table.cuaa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indirizzo => $composableBuilder(
    column: $table.indirizzo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cap => $composableBuilder(
    column: $table.cap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comune => $composableBuilder(
    column: $table.comune,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provincia => $composableBuilder(
    column: $table.provincia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referente => $composableBuilder(
    column: $table.referente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pec => $composableBuilder(
    column: $table.pec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submissionNumber => $composableBuilder(
    column: $table.submissionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNewOperator => $composableBuilder(
    column: $table.isNewOperator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingType => $composableBuilder(
    column: $table.processingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thirdPartyCertNumber => $composableBuilder(
    column: $table.thirdPartyCertNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get siVerification => $composableBuilder(
    column: $table.siVerification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latitudeText => $composableBuilder(
    column: $table.latitudeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get longitudeText => $composableBuilder(
    column: $table.longitudeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manipulationSiteAddress => $composableBuilder(
    column: $table.manipulationSiteAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peakPeriodFrom => $composableBuilder(
    column: $table.peakPeriodFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peakPeriodTo => $composableBuilder(
    column: $table.peakPeriodTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isJointVisit => $composableBuilder(
    column: $table.isJointVisit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jointVisitDetails => $composableBuilder(
    column: $table.jointVisitDetails,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marchioNature => $composableBuilder(
    column: $table.marchioNature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marchioProcesses => $composableBuilder(
    column: $table.marchioProcesses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get marchioLabelDraft => $composableBuilder(
    column: $table.marchioLabelDraft,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitCompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitCompaniesTable> {
  $$VisitCompaniesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cuaa =>
      $composableBuilder(column: $table.cuaa, builder: (column) => column);

  GeneratedColumn<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indirizzo =>
      $composableBuilder(column: $table.indirizzo, builder: (column) => column);

  GeneratedColumn<String> get cap =>
      $composableBuilder(column: $table.cap, builder: (column) => column);

  GeneratedColumn<String> get comune =>
      $composableBuilder(column: $table.comune, builder: (column) => column);

  GeneratedColumn<String> get provincia =>
      $composableBuilder(column: $table.provincia, builder: (column) => column);

  GeneratedColumn<String> get referente =>
      $composableBuilder(column: $table.referente, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get pec =>
      $composableBuilder(column: $table.pec, builder: (column) => column);

  GeneratedColumn<String> get submissionNumber => $composableBuilder(
    column: $table.submissionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isNewOperator => $composableBuilder(
    column: $table.isNewOperator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processingType => $composableBuilder(
    column: $table.processingType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thirdPartyCertNumber => $composableBuilder(
    column: $table.thirdPartyCertNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get siVerification => $composableBuilder(
    column: $table.siVerification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latitudeText => $composableBuilder(
    column: $table.latitudeText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get longitudeText => $composableBuilder(
    column: $table.longitudeText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manipulationSiteAddress => $composableBuilder(
    column: $table.manipulationSiteAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peakPeriodFrom => $composableBuilder(
    column: $table.peakPeriodFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peakPeriodTo => $composableBuilder(
    column: $table.peakPeriodTo,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isJointVisit => $composableBuilder(
    column: $table.isJointVisit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jointVisitDetails => $composableBuilder(
    column: $table.jointVisitDetails,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marchioNature => $composableBuilder(
    column: $table.marchioNature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marchioProcesses => $composableBuilder(
    column: $table.marchioProcesses,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get marchioLabelDraft => $composableBuilder(
    column: $table.marchioLabelDraft,
    builder: (column) => column,
  );

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitCompaniesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitCompaniesTable,
          VisitCompany,
          $$VisitCompaniesTableFilterComposer,
          $$VisitCompaniesTableOrderingComposer,
          $$VisitCompaniesTableAnnotationComposer,
          $$VisitCompaniesTableCreateCompanionBuilder,
          $$VisitCompaniesTableUpdateCompanionBuilder,
          (VisitCompany, $$VisitCompaniesTableReferences),
          VisitCompany,
          PrefetchHooks Function({bool visitId})
        > {
  $$VisitCompaniesTableTableManager(
    _$AppDatabase db,
    $VisitCompaniesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitCompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitCompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitCompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<String> ragioneSociale = const Value.absent(),
                Value<String> cuaa = const Value.absent(),
                Value<String> partitaIva = const Value.absent(),
                Value<String> indirizzo = const Value.absent(),
                Value<String> cap = const Value.absent(),
                Value<String> comune = const Value.absent(),
                Value<String> provincia = const Value.absent(),
                Value<String> referente = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> pec = const Value.absent(),
                Value<String> submissionNumber = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isNewOperator = const Value.absent(),
                Value<String> processingType = const Value.absent(),
                Value<String> thirdPartyCertNumber = const Value.absent(),
                Value<bool> siVerification = const Value.absent(),
                Value<String> latitudeText = const Value.absent(),
                Value<String> longitudeText = const Value.absent(),
                Value<String> manipulationSiteAddress = const Value.absent(),
                Value<String> peakPeriodFrom = const Value.absent(),
                Value<String> peakPeriodTo = const Value.absent(),
                Value<bool> isJointVisit = const Value.absent(),
                Value<String> jointVisitDetails = const Value.absent(),
                Value<String> marchioNature = const Value.absent(),
                Value<String> marchioProcesses = const Value.absent(),
                Value<bool> marchioLabelDraft = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitCompaniesCompanion(
                visitId: visitId,
                ragioneSociale: ragioneSociale,
                cuaa: cuaa,
                partitaIva: partitaIva,
                indirizzo: indirizzo,
                cap: cap,
                comune: comune,
                provincia: provincia,
                referente: referente,
                telefono: telefono,
                email: email,
                pec: pec,
                submissionNumber: submissionNumber,
                updatedAt: updatedAt,
                latitude: latitude,
                longitude: longitude,
                isSynced: isSynced,
                isNewOperator: isNewOperator,
                processingType: processingType,
                thirdPartyCertNumber: thirdPartyCertNumber,
                siVerification: siVerification,
                latitudeText: latitudeText,
                longitudeText: longitudeText,
                manipulationSiteAddress: manipulationSiteAddress,
                peakPeriodFrom: peakPeriodFrom,
                peakPeriodTo: peakPeriodTo,
                isJointVisit: isJointVisit,
                jointVisitDetails: jointVisitDetails,
                marchioNature: marchioNature,
                marchioProcesses: marchioProcesses,
                marchioLabelDraft: marchioLabelDraft,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                Value<String> ragioneSociale = const Value.absent(),
                Value<String> cuaa = const Value.absent(),
                Value<String> partitaIva = const Value.absent(),
                Value<String> indirizzo = const Value.absent(),
                Value<String> cap = const Value.absent(),
                Value<String> comune = const Value.absent(),
                Value<String> provincia = const Value.absent(),
                Value<String> referente = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> pec = const Value.absent(),
                Value<String> submissionNumber = const Value.absent(),
                required DateTime updatedAt,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isNewOperator = const Value.absent(),
                Value<String> processingType = const Value.absent(),
                Value<String> thirdPartyCertNumber = const Value.absent(),
                Value<bool> siVerification = const Value.absent(),
                Value<String> latitudeText = const Value.absent(),
                Value<String> longitudeText = const Value.absent(),
                Value<String> manipulationSiteAddress = const Value.absent(),
                Value<String> peakPeriodFrom = const Value.absent(),
                Value<String> peakPeriodTo = const Value.absent(),
                Value<bool> isJointVisit = const Value.absent(),
                Value<String> jointVisitDetails = const Value.absent(),
                Value<String> marchioNature = const Value.absent(),
                Value<String> marchioProcesses = const Value.absent(),
                Value<bool> marchioLabelDraft = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitCompaniesCompanion.insert(
                visitId: visitId,
                ragioneSociale: ragioneSociale,
                cuaa: cuaa,
                partitaIva: partitaIva,
                indirizzo: indirizzo,
                cap: cap,
                comune: comune,
                provincia: provincia,
                referente: referente,
                telefono: telefono,
                email: email,
                pec: pec,
                submissionNumber: submissionNumber,
                updatedAt: updatedAt,
                latitude: latitude,
                longitude: longitude,
                isSynced: isSynced,
                isNewOperator: isNewOperator,
                processingType: processingType,
                thirdPartyCertNumber: thirdPartyCertNumber,
                siVerification: siVerification,
                latitudeText: latitudeText,
                longitudeText: longitudeText,
                manipulationSiteAddress: manipulationSiteAddress,
                peakPeriodFrom: peakPeriodFrom,
                peakPeriodTo: peakPeriodTo,
                isJointVisit: isJointVisit,
                jointVisitDetails: jointVisitDetails,
                marchioNature: marchioNature,
                marchioProcesses: marchioProcesses,
                marchioLabelDraft: marchioLabelDraft,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitCompaniesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable: $$VisitCompaniesTableReferences
                                    ._visitIdTable(db),
                                referencedColumn:
                                    $$VisitCompaniesTableReferences
                                        ._visitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitCompaniesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitCompaniesTable,
      VisitCompany,
      $$VisitCompaniesTableFilterComposer,
      $$VisitCompaniesTableOrderingComposer,
      $$VisitCompaniesTableAnnotationComposer,
      $$VisitCompaniesTableCreateCompanionBuilder,
      $$VisitCompaniesTableUpdateCompanionBuilder,
      (VisitCompany, $$VisitCompaniesTableReferences),
      VisitCompany,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$VisitUecsTableCreateCompanionBuilder =
    VisitUecsCompanion Function({
      required String id,
      required String visitId,
      Value<String> coltura,
      Value<String> descrizione,
      Value<String> note,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> photoPath,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VisitUecsTableUpdateCompanionBuilder =
    VisitUecsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> coltura,
      Value<String> descrizione,
      Value<String> note,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> photoPath,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VisitUecsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitUecsTable, VisitUec> {
  $$VisitUecsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitUecs.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VisitLotsTable, List<VisitLot>>
  _visitLotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitLots,
    aliasName: $_aliasNameGenerator(db.visitUecs.id, db.visitLots.uecId),
  );

  $$VisitLotsTableProcessedTableManager get visitLotsRefs {
    final manager = $$VisitLotsTableTableManager(
      $_db,
      $_db.visitLots,
    ).filter((f) => f.uecId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitLotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChecklistResponsesTable, List<ChecklistResponse>>
  _checklistResponsesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.checklistResponses,
        aliasName: $_aliasNameGenerator(
          db.visitUecs.id,
          db.checklistResponses.uecId,
        ),
      );

  $$ChecklistResponsesTableProcessedTableManager get checklistResponsesRefs {
    final manager = $$ChecklistResponsesTableTableManager(
      $_db,
      $_db.checklistResponses,
    ).filter((f) => f.uecId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _checklistResponsesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitAttachmentsTable, List<VisitAttachment>>
  _visitAttachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitAttachments,
    aliasName: $_aliasNameGenerator(db.visitUecs.id, db.visitAttachments.uecId),
  );

  $$VisitAttachmentsTableProcessedTableManager get visitAttachmentsRefs {
    final manager = $$VisitAttachmentsTableTableManager(
      $_db,
      $_db.visitAttachments,
    ).filter((f) => f.uecId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _visitAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VisitUecsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitUecsTable> {
  $$VisitUecsTableFilterComposer({
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

  ColumnFilters<String> get coltura => $composableBuilder(
    column: $table.coltura,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> visitLotsRefs(
    Expression<bool> Function($$VisitLotsTableFilterComposer f) f,
  ) {
    final $$VisitLotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitLots,
      getReferencedColumn: (t) => t.uecId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitLotsTableFilterComposer(
            $db: $db,
            $table: $db.visitLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> checklistResponsesRefs(
    Expression<bool> Function($$ChecklistResponsesTableFilterComposer f) f,
  ) {
    final $$ChecklistResponsesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.checklistResponses,
      getReferencedColumn: (t) => t.uecId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistResponsesTableFilterComposer(
            $db: $db,
            $table: $db.checklistResponses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitAttachmentsRefs(
    Expression<bool> Function($$VisitAttachmentsTableFilterComposer f) f,
  ) {
    final $$VisitAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.uecId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitUecsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitUecsTable> {
  $$VisitUecsTableOrderingComposer({
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

  ColumnOrderings<String> get coltura => $composableBuilder(
    column: $table.coltura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitUecsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitUecsTable> {
  $$VisitUecsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get coltura =>
      $composableBuilder(column: $table.coltura, builder: (column) => column);

  GeneratedColumn<String> get descrizione => $composableBuilder(
    column: $table.descrizione,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> visitLotsRefs<T extends Object>(
    Expression<T> Function($$VisitLotsTableAnnotationComposer a) f,
  ) {
    final $$VisitLotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitLots,
      getReferencedColumn: (t) => t.uecId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitLotsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitLots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> checklistResponsesRefs<T extends Object>(
    Expression<T> Function($$ChecklistResponsesTableAnnotationComposer a) f,
  ) {
    final $$ChecklistResponsesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.checklistResponses,
          getReferencedColumn: (t) => t.uecId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChecklistResponsesTableAnnotationComposer(
                $db: $db,
                $table: $db.checklistResponses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> visitAttachmentsRefs<T extends Object>(
    Expression<T> Function($$VisitAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$VisitAttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.uecId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VisitUecsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitUecsTable,
          VisitUec,
          $$VisitUecsTableFilterComposer,
          $$VisitUecsTableOrderingComposer,
          $$VisitUecsTableAnnotationComposer,
          $$VisitUecsTableCreateCompanionBuilder,
          $$VisitUecsTableUpdateCompanionBuilder,
          (VisitUec, $$VisitUecsTableReferences),
          VisitUec,
          PrefetchHooks Function({
            bool visitId,
            bool visitLotsRefs,
            bool checklistResponsesRefs,
            bool visitAttachmentsRefs,
          })
        > {
  $$VisitUecsTableTableManager(_$AppDatabase db, $VisitUecsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitUecsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitUecsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitUecsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> coltura = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitUecsCompanion(
                id: id,
                visitId: visitId,
                coltura: coltura,
                descrizione: descrizione,
                note: note,
                latitude: latitude,
                longitude: longitude,
                photoPath: photoPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                Value<String> coltura = const Value.absent(),
                Value<String> descrizione = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitUecsCompanion.insert(
                id: id,
                visitId: visitId,
                coltura: coltura,
                descrizione: descrizione,
                note: note,
                latitude: latitude,
                longitude: longitude,
                photoPath: photoPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitUecsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                visitId = false,
                visitLotsRefs = false,
                checklistResponsesRefs = false,
                visitAttachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (visitLotsRefs) db.visitLots,
                    if (checklistResponsesRefs) db.checklistResponses,
                    if (visitAttachmentsRefs) db.visitAttachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (visitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visitId,
                                    referencedTable: $$VisitUecsTableReferences
                                        ._visitIdTable(db),
                                    referencedColumn: $$VisitUecsTableReferences
                                        ._visitIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (visitLotsRefs)
                        await $_getPrefetchedData<
                          VisitUec,
                          $VisitUecsTable,
                          VisitLot
                        >(
                          currentTable: table,
                          referencedTable: $$VisitUecsTableReferences
                              ._visitLotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitUecsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitLotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.uecId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (checklistResponsesRefs)
                        await $_getPrefetchedData<
                          VisitUec,
                          $VisitUecsTable,
                          ChecklistResponse
                        >(
                          currentTable: table,
                          referencedTable: $$VisitUecsTableReferences
                              ._checklistResponsesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitUecsTableReferences(
                                db,
                                table,
                                p0,
                              ).checklistResponsesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.uecId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitAttachmentsRefs)
                        await $_getPrefetchedData<
                          VisitUec,
                          $VisitUecsTable,
                          VisitAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$VisitUecsTableReferences
                              ._visitAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VisitUecsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.uecId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VisitUecsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitUecsTable,
      VisitUec,
      $$VisitUecsTableFilterComposer,
      $$VisitUecsTableOrderingComposer,
      $$VisitUecsTableAnnotationComposer,
      $$VisitUecsTableCreateCompanionBuilder,
      $$VisitUecsTableUpdateCompanionBuilder,
      (VisitUec, $$VisitUecsTableReferences),
      VisitUec,
      PrefetchHooks Function({
        bool visitId,
        bool visitLotsRefs,
        bool checklistResponsesRefs,
        bool visitAttachmentsRefs,
      })
    >;
typedef $$VisitLotsTableCreateCompanionBuilder =
    VisitLotsCompanion Function({
      required String id,
      required String uecId,
      Value<String> codice,
      Value<String> quantita,
      Value<String> note,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VisitLotsTableUpdateCompanionBuilder =
    VisitLotsCompanion Function({
      Value<String> id,
      Value<String> uecId,
      Value<String> codice,
      Value<String> quantita,
      Value<String> note,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VisitLotsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitLotsTable, VisitLot> {
  $$VisitLotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitUecsTable _uecIdTable(_$AppDatabase db) => db.visitUecs
      .createAlias($_aliasNameGenerator(db.visitLots.uecId, db.visitUecs.id));

  $$VisitUecsTableProcessedTableManager get uecId {
    final $_column = $_itemColumn<String>('uec_id')!;

    final manager = $$VisitUecsTableTableManager(
      $_db,
      $_db.visitUecs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_uecIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitLotsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitLotsTable> {
  $$VisitLotsTableFilterComposer({
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

  ColumnFilters<String> get codice => $composableBuilder(
    column: $table.codice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantita => $composableBuilder(
    column: $table.quantita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitUecsTableFilterComposer get uecId {
    final $$VisitUecsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableFilterComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitLotsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitLotsTable> {
  $$VisitLotsTableOrderingComposer({
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

  ColumnOrderings<String> get codice => $composableBuilder(
    column: $table.codice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantita => $composableBuilder(
    column: $table.quantita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitUecsTableOrderingComposer get uecId {
    final $$VisitUecsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableOrderingComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitLotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitLotsTable> {
  $$VisitLotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get codice =>
      $composableBuilder(column: $table.codice, builder: (column) => column);

  GeneratedColumn<String> get quantita =>
      $composableBuilder(column: $table.quantita, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VisitUecsTableAnnotationComposer get uecId {
    final $$VisitUecsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitLotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitLotsTable,
          VisitLot,
          $$VisitLotsTableFilterComposer,
          $$VisitLotsTableOrderingComposer,
          $$VisitLotsTableAnnotationComposer,
          $$VisitLotsTableCreateCompanionBuilder,
          $$VisitLotsTableUpdateCompanionBuilder,
          (VisitLot, $$VisitLotsTableReferences),
          VisitLot,
          PrefetchHooks Function({bool uecId})
        > {
  $$VisitLotsTableTableManager(_$AppDatabase db, $VisitLotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitLotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitLotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitLotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> uecId = const Value.absent(),
                Value<String> codice = const Value.absent(),
                Value<String> quantita = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitLotsCompanion(
                id: id,
                uecId: uecId,
                codice: codice,
                quantita: quantita,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String uecId,
                Value<String> codice = const Value.absent(),
                Value<String> quantita = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitLotsCompanion.insert(
                id: id,
                uecId: uecId,
                codice: codice,
                quantita: quantita,
                note: note,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitLotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({uecId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (uecId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.uecId,
                                referencedTable: $$VisitLotsTableReferences
                                    ._uecIdTable(db),
                                referencedColumn: $$VisitLotsTableReferences
                                    ._uecIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitLotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitLotsTable,
      VisitLot,
      $$VisitLotsTableFilterComposer,
      $$VisitLotsTableOrderingComposer,
      $$VisitLotsTableAnnotationComposer,
      $$VisitLotsTableCreateCompanionBuilder,
      $$VisitLotsTableUpdateCompanionBuilder,
      (VisitLot, $$VisitLotsTableReferences),
      VisitLot,
      PrefetchHooks Function({bool uecId})
    >;
typedef $$ChecklistItemsTableCreateCompanionBuilder =
    ChecklistItemsCompanion Function({
      required String code,
      Value<String> fase,
      Value<String> obbligo,
      Value<String> indicatorType,
      Value<String> deroghe,
      Value<String> noteNorma,
      Value<String> tipologiaControllo,
      Value<String> frequenzaSingolo,
      Value<String> frequenzaAssociato,
      Value<String> gravitaUecText,
      Value<String> esclusioneUecText,
      Value<String> gravitaOperatoreText,
      Value<String> esclusioneOperatoreText,
      Value<String> esclusioneLottoText,
      Value<bool> hasEsclusioneLotto,
      Value<String> colGText,
      Value<String> disposizioniRegionali,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$ChecklistItemsTableUpdateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<String> code,
      Value<String> fase,
      Value<String> obbligo,
      Value<String> indicatorType,
      Value<String> deroghe,
      Value<String> noteNorma,
      Value<String> tipologiaControllo,
      Value<String> frequenzaSingolo,
      Value<String> frequenzaAssociato,
      Value<String> gravitaUecText,
      Value<String> esclusioneUecText,
      Value<String> gravitaOperatoreText,
      Value<String> esclusioneOperatoreText,
      Value<String> esclusioneLottoText,
      Value<bool> hasEsclusioneLotto,
      Value<String> colGText,
      Value<String> disposizioniRegionali,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$ChecklistItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem> {
  $$ChecklistItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ChecklistResponsesTable, List<ChecklistResponse>>
  _checklistResponsesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.checklistResponses,
        aliasName: $_aliasNameGenerator(
          db.checklistItems.code,
          db.checklistResponses.itemCode,
        ),
      );

  $$ChecklistResponsesTableProcessedTableManager get checklistResponsesRefs {
    final manager = $$ChecklistResponsesTableTableManager(
      $_db,
      $_db.checklistResponses,
    ).filter((f) => f.itemCode.code.sqlEquals($_itemColumn<String>('code')!));

    final cache = $_typedResult.readTableOrNull(
      _checklistResponsesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitAttachmentsTable, List<VisitAttachment>>
  _visitAttachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitAttachments,
    aliasName: $_aliasNameGenerator(
      db.checklistItems.code,
      db.visitAttachments.checklistCode,
    ),
  );

  $$VisitAttachmentsTableProcessedTableManager get visitAttachmentsRefs {
    final manager =
        $$VisitAttachmentsTableTableManager($_db, $_db.visitAttachments).filter(
          (f) => f.checklistCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _visitAttachmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fase => $composableBuilder(
    column: $table.fase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obbligo => $composableBuilder(
    column: $table.obbligo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indicatorType => $composableBuilder(
    column: $table.indicatorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deroghe => $composableBuilder(
    column: $table.deroghe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteNorma => $composableBuilder(
    column: $table.noteNorma,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipologiaControllo => $composableBuilder(
    column: $table.tipologiaControllo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequenzaSingolo => $composableBuilder(
    column: $table.frequenzaSingolo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequenzaAssociato => $composableBuilder(
    column: $table.frequenzaAssociato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gravitaUecText => $composableBuilder(
    column: $table.gravitaUecText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esclusioneUecText => $composableBuilder(
    column: $table.esclusioneUecText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gravitaOperatoreText => $composableBuilder(
    column: $table.gravitaOperatoreText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esclusioneOperatoreText => $composableBuilder(
    column: $table.esclusioneOperatoreText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get esclusioneLottoText => $composableBuilder(
    column: $table.esclusioneLottoText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasEsclusioneLotto => $composableBuilder(
    column: $table.hasEsclusioneLotto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colGText => $composableBuilder(
    column: $table.colGText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disposizioniRegionali => $composableBuilder(
    column: $table.disposizioniRegionali,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> checklistResponsesRefs(
    Expression<bool> Function($$ChecklistResponsesTableFilterComposer f) f,
  ) {
    final $$ChecklistResponsesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.checklistResponses,
      getReferencedColumn: (t) => t.itemCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistResponsesTableFilterComposer(
            $db: $db,
            $table: $db.checklistResponses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitAttachmentsRefs(
    Expression<bool> Function($$VisitAttachmentsTableFilterComposer f) f,
  ) {
    final $$VisitAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.checklistCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fase => $composableBuilder(
    column: $table.fase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obbligo => $composableBuilder(
    column: $table.obbligo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indicatorType => $composableBuilder(
    column: $table.indicatorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deroghe => $composableBuilder(
    column: $table.deroghe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteNorma => $composableBuilder(
    column: $table.noteNorma,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipologiaControllo => $composableBuilder(
    column: $table.tipologiaControllo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequenzaSingolo => $composableBuilder(
    column: $table.frequenzaSingolo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequenzaAssociato => $composableBuilder(
    column: $table.frequenzaAssociato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gravitaUecText => $composableBuilder(
    column: $table.gravitaUecText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esclusioneUecText => $composableBuilder(
    column: $table.esclusioneUecText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gravitaOperatoreText => $composableBuilder(
    column: $table.gravitaOperatoreText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esclusioneOperatoreText => $composableBuilder(
    column: $table.esclusioneOperatoreText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get esclusioneLottoText => $composableBuilder(
    column: $table.esclusioneLottoText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasEsclusioneLotto => $composableBuilder(
    column: $table.hasEsclusioneLotto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colGText => $composableBuilder(
    column: $table.colGText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disposizioniRegionali => $composableBuilder(
    column: $table.disposizioniRegionali,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get fase =>
      $composableBuilder(column: $table.fase, builder: (column) => column);

  GeneratedColumn<String> get obbligo =>
      $composableBuilder(column: $table.obbligo, builder: (column) => column);

  GeneratedColumn<String> get indicatorType => $composableBuilder(
    column: $table.indicatorType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deroghe =>
      $composableBuilder(column: $table.deroghe, builder: (column) => column);

  GeneratedColumn<String> get noteNorma =>
      $composableBuilder(column: $table.noteNorma, builder: (column) => column);

  GeneratedColumn<String> get tipologiaControllo => $composableBuilder(
    column: $table.tipologiaControllo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequenzaSingolo => $composableBuilder(
    column: $table.frequenzaSingolo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequenzaAssociato => $composableBuilder(
    column: $table.frequenzaAssociato,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gravitaUecText => $composableBuilder(
    column: $table.gravitaUecText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get esclusioneUecText => $composableBuilder(
    column: $table.esclusioneUecText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gravitaOperatoreText => $composableBuilder(
    column: $table.gravitaOperatoreText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get esclusioneOperatoreText => $composableBuilder(
    column: $table.esclusioneOperatoreText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get esclusioneLottoText => $composableBuilder(
    column: $table.esclusioneLottoText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasEsclusioneLotto => $composableBuilder(
    column: $table.hasEsclusioneLotto,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colGText =>
      $composableBuilder(column: $table.colGText, builder: (column) => column);

  GeneratedColumn<String> get disposizioniRegionali => $composableBuilder(
    column: $table.disposizioniRegionali,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> checklistResponsesRefs<T extends Object>(
    Expression<T> Function($$ChecklistResponsesTableAnnotationComposer a) f,
  ) {
    final $$ChecklistResponsesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.code,
          referencedTable: $db.checklistResponses,
          getReferencedColumn: (t) => t.itemCode,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChecklistResponsesTableAnnotationComposer(
                $db: $db,
                $table: $db.checklistResponses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> visitAttachmentsRefs<T extends Object>(
    Expression<T> Function($$VisitAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$VisitAttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.visitAttachments,
      getReferencedColumn: (t) => t.checklistCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitAttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistItemsTable,
          ChecklistItem,
          $$ChecklistItemsTableFilterComposer,
          $$ChecklistItemsTableOrderingComposer,
          $$ChecklistItemsTableAnnotationComposer,
          $$ChecklistItemsTableCreateCompanionBuilder,
          $$ChecklistItemsTableUpdateCompanionBuilder,
          (ChecklistItem, $$ChecklistItemsTableReferences),
          ChecklistItem,
          PrefetchHooks Function({
            bool checklistResponsesRefs,
            bool visitAttachmentsRefs,
          })
        > {
  $$ChecklistItemsTableTableManager(
    _$AppDatabase db,
    $ChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> fase = const Value.absent(),
                Value<String> obbligo = const Value.absent(),
                Value<String> indicatorType = const Value.absent(),
                Value<String> deroghe = const Value.absent(),
                Value<String> noteNorma = const Value.absent(),
                Value<String> tipologiaControllo = const Value.absent(),
                Value<String> frequenzaSingolo = const Value.absent(),
                Value<String> frequenzaAssociato = const Value.absent(),
                Value<String> gravitaUecText = const Value.absent(),
                Value<String> esclusioneUecText = const Value.absent(),
                Value<String> gravitaOperatoreText = const Value.absent(),
                Value<String> esclusioneOperatoreText = const Value.absent(),
                Value<String> esclusioneLottoText = const Value.absent(),
                Value<bool> hasEsclusioneLotto = const Value.absent(),
                Value<String> colGText = const Value.absent(),
                Value<String> disposizioniRegionali = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion(
                code: code,
                fase: fase,
                obbligo: obbligo,
                indicatorType: indicatorType,
                deroghe: deroghe,
                noteNorma: noteNorma,
                tipologiaControllo: tipologiaControllo,
                frequenzaSingolo: frequenzaSingolo,
                frequenzaAssociato: frequenzaAssociato,
                gravitaUecText: gravitaUecText,
                esclusioneUecText: esclusioneUecText,
                gravitaOperatoreText: gravitaOperatoreText,
                esclusioneOperatoreText: esclusioneOperatoreText,
                esclusioneLottoText: esclusioneLottoText,
                hasEsclusioneLotto: hasEsclusioneLotto,
                colGText: colGText,
                disposizioniRegionali: disposizioniRegionali,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                Value<String> fase = const Value.absent(),
                Value<String> obbligo = const Value.absent(),
                Value<String> indicatorType = const Value.absent(),
                Value<String> deroghe = const Value.absent(),
                Value<String> noteNorma = const Value.absent(),
                Value<String> tipologiaControllo = const Value.absent(),
                Value<String> frequenzaSingolo = const Value.absent(),
                Value<String> frequenzaAssociato = const Value.absent(),
                Value<String> gravitaUecText = const Value.absent(),
                Value<String> esclusioneUecText = const Value.absent(),
                Value<String> gravitaOperatoreText = const Value.absent(),
                Value<String> esclusioneOperatoreText = const Value.absent(),
                Value<String> esclusioneLottoText = const Value.absent(),
                Value<bool> hasEsclusioneLotto = const Value.absent(),
                Value<String> colGText = const Value.absent(),
                Value<String> disposizioniRegionali = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion.insert(
                code: code,
                fase: fase,
                obbligo: obbligo,
                indicatorType: indicatorType,
                deroghe: deroghe,
                noteNorma: noteNorma,
                tipologiaControllo: tipologiaControllo,
                frequenzaSingolo: frequenzaSingolo,
                frequenzaAssociato: frequenzaAssociato,
                gravitaUecText: gravitaUecText,
                esclusioneUecText: esclusioneUecText,
                gravitaOperatoreText: gravitaOperatoreText,
                esclusioneOperatoreText: esclusioneOperatoreText,
                esclusioneLottoText: esclusioneLottoText,
                hasEsclusioneLotto: hasEsclusioneLotto,
                colGText: colGText,
                disposizioniRegionali: disposizioniRegionali,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChecklistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({checklistResponsesRefs = false, visitAttachmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (checklistResponsesRefs) db.checklistResponses,
                    if (visitAttachmentsRefs) db.visitAttachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (checklistResponsesRefs)
                        await $_getPrefetchedData<
                          ChecklistItem,
                          $ChecklistItemsTable,
                          ChecklistResponse
                        >(
                          currentTable: table,
                          referencedTable: $$ChecklistItemsTableReferences
                              ._checklistResponsesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChecklistItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).checklistResponsesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (visitAttachmentsRefs)
                        await $_getPrefetchedData<
                          ChecklistItem,
                          $ChecklistItemsTable,
                          VisitAttachment
                        >(
                          currentTable: table,
                          referencedTable: $$ChecklistItemsTableReferences
                              ._visitAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChecklistItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).visitAttachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.checklistCode == item.code,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistItemsTable,
      ChecklistItem,
      $$ChecklistItemsTableFilterComposer,
      $$ChecklistItemsTableOrderingComposer,
      $$ChecklistItemsTableAnnotationComposer,
      $$ChecklistItemsTableCreateCompanionBuilder,
      $$ChecklistItemsTableUpdateCompanionBuilder,
      (ChecklistItem, $$ChecklistItemsTableReferences),
      ChecklistItem,
      PrefetchHooks Function({
        bool checklistResponsesRefs,
        bool visitAttachmentsRefs,
      })
    >;
typedef $$ChecklistResponsesTableCreateCompanionBuilder =
    ChecklistResponsesCompanion Function({
      required String id,
      required String uecId,
      required String itemCode,
      required int conformita,
      Value<int?> livelloKo,
      Value<int?> punteggioUec,
      Value<int?> punteggioOperatore,
      Value<String> rilievoNc,
      Value<String> note,
      required DateTime updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ChecklistResponsesTableUpdateCompanionBuilder =
    ChecklistResponsesCompanion Function({
      Value<String> id,
      Value<String> uecId,
      Value<String> itemCode,
      Value<int> conformita,
      Value<int?> livelloKo,
      Value<int?> punteggioUec,
      Value<int?> punteggioOperatore,
      Value<String> rilievoNc,
      Value<String> note,
      Value<DateTime> updatedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

final class $$ChecklistResponsesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ChecklistResponsesTable,
          ChecklistResponse
        > {
  $$ChecklistResponsesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitUecsTable _uecIdTable(_$AppDatabase db) =>
      db.visitUecs.createAlias(
        $_aliasNameGenerator(db.checklistResponses.uecId, db.visitUecs.id),
      );

  $$VisitUecsTableProcessedTableManager get uecId {
    final $_column = $_itemColumn<String>('uec_id')!;

    final manager = $$VisitUecsTableTableManager(
      $_db,
      $_db.visitUecs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_uecIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChecklistItemsTable _itemCodeTable(_$AppDatabase db) =>
      db.checklistItems.createAlias(
        $_aliasNameGenerator(
          db.checklistResponses.itemCode,
          db.checklistItems.code,
        ),
      );

  $$ChecklistItemsTableProcessedTableManager get itemCode {
    final $_column = $_itemColumn<String>('item_code')!;

    final manager = $$ChecklistItemsTableTableManager(
      $_db,
      $_db.checklistItems,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChecklistResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistResponsesTable> {
  $$ChecklistResponsesTableFilterComposer({
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

  ColumnFilters<int> get conformita => $composableBuilder(
    column: $table.conformita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get livelloKo => $composableBuilder(
    column: $table.livelloKo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get punteggioUec => $composableBuilder(
    column: $table.punteggioUec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get punteggioOperatore => $composableBuilder(
    column: $table.punteggioOperatore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rilievoNc => $composableBuilder(
    column: $table.rilievoNc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitUecsTableFilterComposer get uecId {
    final $$VisitUecsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableFilterComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableFilterComposer get itemCode {
    final $$ChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableFilterComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistResponsesTable> {
  $$ChecklistResponsesTableOrderingComposer({
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

  ColumnOrderings<int> get conformita => $composableBuilder(
    column: $table.conformita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get livelloKo => $composableBuilder(
    column: $table.livelloKo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get punteggioUec => $composableBuilder(
    column: $table.punteggioUec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get punteggioOperatore => $composableBuilder(
    column: $table.punteggioOperatore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rilievoNc => $composableBuilder(
    column: $table.rilievoNc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitUecsTableOrderingComposer get uecId {
    final $$VisitUecsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableOrderingComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableOrderingComposer get itemCode {
    final $$ChecklistItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableOrderingComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistResponsesTable> {
  $$ChecklistResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get conformita => $composableBuilder(
    column: $table.conformita,
    builder: (column) => column,
  );

  GeneratedColumn<int> get livelloKo =>
      $composableBuilder(column: $table.livelloKo, builder: (column) => column);

  GeneratedColumn<int> get punteggioUec => $composableBuilder(
    column: $table.punteggioUec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get punteggioOperatore => $composableBuilder(
    column: $table.punteggioOperatore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rilievoNc =>
      $composableBuilder(column: $table.rilievoNc, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$VisitUecsTableAnnotationComposer get uecId {
    final $$VisitUecsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableAnnotationComposer get itemCode {
    final $$ChecklistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChecklistResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistResponsesTable,
          ChecklistResponse,
          $$ChecklistResponsesTableFilterComposer,
          $$ChecklistResponsesTableOrderingComposer,
          $$ChecklistResponsesTableAnnotationComposer,
          $$ChecklistResponsesTableCreateCompanionBuilder,
          $$ChecklistResponsesTableUpdateCompanionBuilder,
          (ChecklistResponse, $$ChecklistResponsesTableReferences),
          ChecklistResponse,
          PrefetchHooks Function({bool uecId, bool itemCode})
        > {
  $$ChecklistResponsesTableTableManager(
    _$AppDatabase db,
    $ChecklistResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> uecId = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<int> conformita = const Value.absent(),
                Value<int?> livelloKo = const Value.absent(),
                Value<int?> punteggioUec = const Value.absent(),
                Value<int?> punteggioOperatore = const Value.absent(),
                Value<String> rilievoNc = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistResponsesCompanion(
                id: id,
                uecId: uecId,
                itemCode: itemCode,
                conformita: conformita,
                livelloKo: livelloKo,
                punteggioUec: punteggioUec,
                punteggioOperatore: punteggioOperatore,
                rilievoNc: rilievoNc,
                note: note,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String uecId,
                required String itemCode,
                required int conformita,
                Value<int?> livelloKo = const Value.absent(),
                Value<int?> punteggioUec = const Value.absent(),
                Value<int?> punteggioOperatore = const Value.absent(),
                Value<String> rilievoNc = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistResponsesCompanion.insert(
                id: id,
                uecId: uecId,
                itemCode: itemCode,
                conformita: conformita,
                livelloKo: livelloKo,
                punteggioUec: punteggioUec,
                punteggioOperatore: punteggioOperatore,
                rilievoNc: rilievoNc,
                note: note,
                updatedAt: updatedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChecklistResponsesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({uecId = false, itemCode = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (uecId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.uecId,
                                referencedTable:
                                    $$ChecklistResponsesTableReferences
                                        ._uecIdTable(db),
                                referencedColumn:
                                    $$ChecklistResponsesTableReferences
                                        ._uecIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemCode) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemCode,
                                referencedTable:
                                    $$ChecklistResponsesTableReferences
                                        ._itemCodeTable(db),
                                referencedColumn:
                                    $$ChecklistResponsesTableReferences
                                        ._itemCodeTable(db)
                                        .code,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChecklistResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistResponsesTable,
      ChecklistResponse,
      $$ChecklistResponsesTableFilterComposer,
      $$ChecklistResponsesTableOrderingComposer,
      $$ChecklistResponsesTableAnnotationComposer,
      $$ChecklistResponsesTableCreateCompanionBuilder,
      $$ChecklistResponsesTableUpdateCompanionBuilder,
      (ChecklistResponse, $$ChecklistResponsesTableReferences),
      ChecklistResponse,
      PrefetchHooks Function({bool uecId, bool itemCode})
    >;
typedef $$VisitAttachmentsTableCreateCompanionBuilder =
    VisitAttachmentsCompanion Function({
      required String id,
      required String visitId,
      required String filePath,
      Value<String> caption,
      Value<bool> isSynced,
      Value<String?> uecId,
      Value<String?> checklistCode,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VisitAttachmentsTableUpdateCompanionBuilder =
    VisitAttachmentsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> filePath,
      Value<String> caption,
      Value<bool> isSynced,
      Value<String?> uecId,
      Value<String?> checklistCode,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$VisitAttachmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $VisitAttachmentsTable, VisitAttachment> {
  $$VisitAttachmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitAttachments.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisitUecsTable _uecIdTable(_$AppDatabase db) =>
      db.visitUecs.createAlias(
        $_aliasNameGenerator(db.visitAttachments.uecId, db.visitUecs.id),
      );

  $$VisitUecsTableProcessedTableManager? get uecId {
    final $_column = $_itemColumn<String>('uec_id');
    if ($_column == null) return null;
    final manager = $$VisitUecsTableTableManager(
      $_db,
      $_db.visitUecs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_uecIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChecklistItemsTable _checklistCodeTable(_$AppDatabase db) =>
      db.checklistItems.createAlias(
        $_aliasNameGenerator(
          db.visitAttachments.checklistCode,
          db.checklistItems.code,
        ),
      );

  $$ChecklistItemsTableProcessedTableManager? get checklistCode {
    final $_column = $_itemColumn<String>('checklist_code');
    if ($_column == null) return null;
    final manager = $$ChecklistItemsTableTableManager(
      $_db,
      $_db.checklistItems,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_checklistCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitAttachmentsTable> {
  $$VisitAttachmentsTableFilterComposer({
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

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitUecsTableFilterComposer get uecId {
    final $$VisitUecsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableFilterComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableFilterComposer get checklistCode {
    final $$ChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableFilterComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitAttachmentsTable> {
  $$VisitAttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitUecsTableOrderingComposer get uecId {
    final $$VisitUecsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableOrderingComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableOrderingComposer get checklistCode {
    final $$ChecklistItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableOrderingComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitAttachmentsTable> {
  $$VisitAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitUecsTableAnnotationComposer get uecId {
    final $$VisitUecsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uecId,
      referencedTable: $db.visitUecs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitUecsTableAnnotationComposer(
            $db: $db,
            $table: $db.visitUecs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChecklistItemsTableAnnotationComposer get checklistCode {
    final $$ChecklistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.checklistCode,
      referencedTable: $db.checklistItems,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChecklistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.checklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitAttachmentsTable,
          VisitAttachment,
          $$VisitAttachmentsTableFilterComposer,
          $$VisitAttachmentsTableOrderingComposer,
          $$VisitAttachmentsTableAnnotationComposer,
          $$VisitAttachmentsTableCreateCompanionBuilder,
          $$VisitAttachmentsTableUpdateCompanionBuilder,
          (VisitAttachment, $$VisitAttachmentsTableReferences),
          VisitAttachment,
          PrefetchHooks Function({bool visitId, bool uecId, bool checklistCode})
        > {
  $$VisitAttachmentsTableTableManager(
    _$AppDatabase db,
    $VisitAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> uecId = const Value.absent(),
                Value<String?> checklistCode = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitAttachmentsCompanion(
                id: id,
                visitId: visitId,
                filePath: filePath,
                caption: caption,
                isSynced: isSynced,
                uecId: uecId,
                checklistCode: checklistCode,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String filePath,
                Value<String> caption = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String?> uecId = const Value.absent(),
                Value<String?> checklistCode = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitAttachmentsCompanion.insert(
                id: id,
                visitId: visitId,
                filePath: filePath,
                caption: caption,
                isSynced: isSynced,
                uecId: uecId,
                checklistCode: checklistCode,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({visitId = false, uecId = false, checklistCode = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (visitId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.visitId,
                                    referencedTable:
                                        $$VisitAttachmentsTableReferences
                                            ._visitIdTable(db),
                                    referencedColumn:
                                        $$VisitAttachmentsTableReferences
                                            ._visitIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (uecId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.uecId,
                                    referencedTable:
                                        $$VisitAttachmentsTableReferences
                                            ._uecIdTable(db),
                                    referencedColumn:
                                        $$VisitAttachmentsTableReferences
                                            ._uecIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (checklistCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.checklistCode,
                                    referencedTable:
                                        $$VisitAttachmentsTableReferences
                                            ._checklistCodeTable(db),
                                    referencedColumn:
                                        $$VisitAttachmentsTableReferences
                                            ._checklistCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$VisitAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitAttachmentsTable,
      VisitAttachment,
      $$VisitAttachmentsTableFilterComposer,
      $$VisitAttachmentsTableOrderingComposer,
      $$VisitAttachmentsTableAnnotationComposer,
      $$VisitAttachmentsTableCreateCompanionBuilder,
      $$VisitAttachmentsTableUpdateCompanionBuilder,
      (VisitAttachment, $$VisitAttachmentsTableReferences),
      VisitAttachment,
      PrefetchHooks Function({bool visitId, bool uecId, bool checklistCode})
    >;
typedef $$VisitSignaturesTableCreateCompanionBuilder =
    VisitSignaturesCompanion Function({
      required String id,
      required String visitId,
      required String signatureType,
      required String filePath,
      Value<String?> signerName,
      Value<String?> identityDocPath,
      required DateTime createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$VisitSignaturesTableUpdateCompanionBuilder =
    VisitSignaturesCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> signatureType,
      Value<String> filePath,
      Value<String?> signerName,
      Value<String?> identityDocPath,
      Value<DateTime> createdAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

final class $$VisitSignaturesTableReferences
    extends
        BaseReferences<_$AppDatabase, $VisitSignaturesTable, VisitSignature> {
  $$VisitSignaturesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitSignatures.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitSignaturesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitSignaturesTable> {
  $$VisitSignaturesTableFilterComposer({
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

  ColumnFilters<String> get signatureType => $composableBuilder(
    column: $table.signatureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signerName => $composableBuilder(
    column: $table.signerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityDocPath => $composableBuilder(
    column: $table.identityDocPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSignaturesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitSignaturesTable> {
  $$VisitSignaturesTableOrderingComposer({
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

  ColumnOrderings<String> get signatureType => $composableBuilder(
    column: $table.signatureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signerName => $composableBuilder(
    column: $table.signerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityDocPath => $composableBuilder(
    column: $table.identityDocPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSignaturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitSignaturesTable> {
  $$VisitSignaturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get signatureType => $composableBuilder(
    column: $table.signatureType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get signerName => $composableBuilder(
    column: $table.signerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identityDocPath => $composableBuilder(
    column: $table.identityDocPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSignaturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitSignaturesTable,
          VisitSignature,
          $$VisitSignaturesTableFilterComposer,
          $$VisitSignaturesTableOrderingComposer,
          $$VisitSignaturesTableAnnotationComposer,
          $$VisitSignaturesTableCreateCompanionBuilder,
          $$VisitSignaturesTableUpdateCompanionBuilder,
          (VisitSignature, $$VisitSignaturesTableReferences),
          VisitSignature,
          PrefetchHooks Function({bool visitId})
        > {
  $$VisitSignaturesTableTableManager(
    _$AppDatabase db,
    $VisitSignaturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitSignaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitSignaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitSignaturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> signatureType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> signerName = const Value.absent(),
                Value<String?> identityDocPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSignaturesCompanion(
                id: id,
                visitId: visitId,
                signatureType: signatureType,
                filePath: filePath,
                signerName: signerName,
                identityDocPath: identityDocPath,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String signatureType,
                required String filePath,
                Value<String?> signerName = const Value.absent(),
                Value<String?> identityDocPath = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSignaturesCompanion.insert(
                id: id,
                visitId: visitId,
                signatureType: signatureType,
                filePath: filePath,
                signerName: signerName,
                identityDocPath: identityDocPath,
                createdAt: createdAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitSignaturesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable:
                                    $$VisitSignaturesTableReferences
                                        ._visitIdTable(db),
                                referencedColumn:
                                    $$VisitSignaturesTableReferences
                                        ._visitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitSignaturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitSignaturesTable,
      VisitSignature,
      $$VisitSignaturesTableFilterComposer,
      $$VisitSignaturesTableOrderingComposer,
      $$VisitSignaturesTableAnnotationComposer,
      $$VisitSignaturesTableCreateCompanionBuilder,
      $$VisitSignaturesTableUpdateCompanionBuilder,
      (VisitSignature, $$VisitSignaturesTableReferences),
      VisitSignature,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$MassBalanceRecordsTableCreateCompanionBuilder =
    MassBalanceRecordsCompanion Function({
      required String id,
      required String visitId,
      Value<String> substances,
      Value<double> purchased,
      Value<double> used,
      Value<double> stock,
      Value<double> discrepancy,
      Value<String> referenceDocuments,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MassBalanceRecordsTableUpdateCompanionBuilder =
    MassBalanceRecordsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> substances,
      Value<double> purchased,
      Value<double> used,
      Value<double> stock,
      Value<double> discrepancy,
      Value<String> referenceDocuments,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$MassBalanceRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MassBalanceRecordsTable,
          MassBalanceRecord
        > {
  $$MassBalanceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.massBalanceRecords.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MassBalanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MassBalanceRecordsTable> {
  $$MassBalanceRecordsTableFilterComposer({
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

  ColumnFilters<String> get substances => $composableBuilder(
    column: $table.substances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchased => $composableBuilder(
    column: $table.purchased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discrepancy => $composableBuilder(
    column: $table.discrepancy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceDocuments => $composableBuilder(
    column: $table.referenceDocuments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MassBalanceRecordsTable> {
  $$MassBalanceRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get substances => $composableBuilder(
    column: $table.substances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchased => $composableBuilder(
    column: $table.purchased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discrepancy => $composableBuilder(
    column: $table.discrepancy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceDocuments => $composableBuilder(
    column: $table.referenceDocuments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MassBalanceRecordsTable> {
  $$MassBalanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get substances => $composableBuilder(
    column: $table.substances,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchased =>
      $composableBuilder(column: $table.purchased, builder: (column) => column);

  GeneratedColumn<double> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);

  GeneratedColumn<double> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<double> get discrepancy => $composableBuilder(
    column: $table.discrepancy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceDocuments => $composableBuilder(
    column: $table.referenceDocuments,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MassBalanceRecordsTable,
          MassBalanceRecord,
          $$MassBalanceRecordsTableFilterComposer,
          $$MassBalanceRecordsTableOrderingComposer,
          $$MassBalanceRecordsTableAnnotationComposer,
          $$MassBalanceRecordsTableCreateCompanionBuilder,
          $$MassBalanceRecordsTableUpdateCompanionBuilder,
          (MassBalanceRecord, $$MassBalanceRecordsTableReferences),
          MassBalanceRecord,
          PrefetchHooks Function({bool visitId})
        > {
  $$MassBalanceRecordsTableTableManager(
    _$AppDatabase db,
    $MassBalanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MassBalanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MassBalanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MassBalanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> substances = const Value.absent(),
                Value<double> purchased = const Value.absent(),
                Value<double> used = const Value.absent(),
                Value<double> stock = const Value.absent(),
                Value<double> discrepancy = const Value.absent(),
                Value<String> referenceDocuments = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MassBalanceRecordsCompanion(
                id: id,
                visitId: visitId,
                substances: substances,
                purchased: purchased,
                used: used,
                stock: stock,
                discrepancy: discrepancy,
                referenceDocuments: referenceDocuments,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                Value<String> substances = const Value.absent(),
                Value<double> purchased = const Value.absent(),
                Value<double> used = const Value.absent(),
                Value<double> stock = const Value.absent(),
                Value<double> discrepancy = const Value.absent(),
                Value<String> referenceDocuments = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MassBalanceRecordsCompanion.insert(
                id: id,
                visitId: visitId,
                substances: substances,
                purchased: purchased,
                used: used,
                stock: stock,
                discrepancy: discrepancy,
                referenceDocuments: referenceDocuments,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MassBalanceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable:
                                    $$MassBalanceRecordsTableReferences
                                        ._visitIdTable(db),
                                referencedColumn:
                                    $$MassBalanceRecordsTableReferences
                                        ._visitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MassBalanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MassBalanceRecordsTable,
      MassBalanceRecord,
      $$MassBalanceRecordsTableFilterComposer,
      $$MassBalanceRecordsTableOrderingComposer,
      $$MassBalanceRecordsTableAnnotationComposer,
      $$MassBalanceRecordsTableCreateCompanionBuilder,
      $$MassBalanceRecordsTableUpdateCompanionBuilder,
      (MassBalanceRecord, $$MassBalanceRecordsTableReferences),
      MassBalanceRecord,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$VisitClosingsTableCreateCompanionBuilder =
    VisitClosingsCompanion Function({
      required String visitId,
      Value<String> correctiveActions,
      Value<DateTime?> resolutionDeadline,
      Value<bool> isClosed,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VisitClosingsTableUpdateCompanionBuilder =
    VisitClosingsCompanion Function({
      Value<String> visitId,
      Value<String> correctiveActions,
      Value<DateTime?> resolutionDeadline,
      Value<bool> isClosed,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VisitClosingsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitClosingsTable, VisitClosing> {
  $$VisitClosingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitClosings.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitClosingsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitClosingsTable> {
  $$VisitClosingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get correctiveActions => $composableBuilder(
    column: $table.correctiveActions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolutionDeadline => $composableBuilder(
    column: $table.resolutionDeadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitClosingsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitClosingsTable> {
  $$VisitClosingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get correctiveActions => $composableBuilder(
    column: $table.correctiveActions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolutionDeadline => $composableBuilder(
    column: $table.resolutionDeadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitClosingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitClosingsTable> {
  $$VisitClosingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get correctiveActions => $composableBuilder(
    column: $table.correctiveActions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolutionDeadline => $composableBuilder(
    column: $table.resolutionDeadline,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitClosingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitClosingsTable,
          VisitClosing,
          $$VisitClosingsTableFilterComposer,
          $$VisitClosingsTableOrderingComposer,
          $$VisitClosingsTableAnnotationComposer,
          $$VisitClosingsTableCreateCompanionBuilder,
          $$VisitClosingsTableUpdateCompanionBuilder,
          (VisitClosing, $$VisitClosingsTableReferences),
          VisitClosing,
          PrefetchHooks Function({bool visitId})
        > {
  $$VisitClosingsTableTableManager(_$AppDatabase db, $VisitClosingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitClosingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitClosingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitClosingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> visitId = const Value.absent(),
                Value<String> correctiveActions = const Value.absent(),
                Value<DateTime?> resolutionDeadline = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitClosingsCompanion(
                visitId: visitId,
                correctiveActions: correctiveActions,
                resolutionDeadline: resolutionDeadline,
                isClosed: isClosed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String visitId,
                Value<String> correctiveActions = const Value.absent(),
                Value<DateTime?> resolutionDeadline = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitClosingsCompanion.insert(
                visitId: visitId,
                correctiveActions: correctiveActions,
                resolutionDeadline: resolutionDeadline,
                isClosed: isClosed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitClosingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable: $$VisitClosingsTableReferences
                                    ._visitIdTable(db),
                                referencedColumn: $$VisitClosingsTableReferences
                                    ._visitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitClosingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitClosingsTable,
      VisitClosing,
      $$VisitClosingsTableFilterComposer,
      $$VisitClosingsTableOrderingComposer,
      $$VisitClosingsTableAnnotationComposer,
      $$VisitClosingsTableCreateCompanionBuilder,
      $$VisitClosingsTableUpdateCompanionBuilder,
      (VisitClosing, $$VisitClosingsTableReferences),
      VisitClosing,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$VisitSamplesTableCreateCompanionBuilder =
    VisitSamplesCompanion Function({
      required String id,
      required String visitId,
      Value<String> sampleCode,
      Value<String> matrixType,
      Value<String> sealNumber,
      Value<String?> photoPath,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VisitSamplesTableUpdateCompanionBuilder =
    VisitSamplesCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> sampleCode,
      Value<String> matrixType,
      Value<String> sealNumber,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$VisitSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $VisitSamplesTable, VisitSample> {
  $$VisitSamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.visitSamples.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitSamplesTable> {
  $$VisitSamplesTableFilterComposer({
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

  ColumnFilters<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sealNumber => $composableBuilder(
    column: $table.sealNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitSamplesTable> {
  $$VisitSamplesTableOrderingComposer({
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

  ColumnOrderings<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sealNumber => $composableBuilder(
    column: $table.sealNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitSamplesTable> {
  $$VisitSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sampleCode => $composableBuilder(
    column: $table.sampleCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sealNumber => $composableBuilder(
    column: $table.sealNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitSamplesTable,
          VisitSample,
          $$VisitSamplesTableFilterComposer,
          $$VisitSamplesTableOrderingComposer,
          $$VisitSamplesTableAnnotationComposer,
          $$VisitSamplesTableCreateCompanionBuilder,
          $$VisitSamplesTableUpdateCompanionBuilder,
          (VisitSample, $$VisitSamplesTableReferences),
          VisitSample,
          PrefetchHooks Function({bool visitId})
        > {
  $$VisitSamplesTableTableManager(_$AppDatabase db, $VisitSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> sampleCode = const Value.absent(),
                Value<String> matrixType = const Value.absent(),
                Value<String> sealNumber = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSamplesCompanion(
                id: id,
                visitId: visitId,
                sampleCode: sampleCode,
                matrixType: matrixType,
                sealNumber: sealNumber,
                photoPath: photoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                Value<String> sampleCode = const Value.absent(),
                Value<String> matrixType = const Value.absent(),
                Value<String> sealNumber = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitSamplesCompanion.insert(
                id: id,
                visitId: visitId,
                sampleCode: sampleCode,
                matrixType: matrixType,
                sealNumber: sealNumber,
                photoPath: photoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable: $$VisitSamplesTableReferences
                                    ._visitIdTable(db),
                                referencedColumn: $$VisitSamplesTableReferences
                                    ._visitIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitSamplesTable,
      VisitSample,
      $$VisitSamplesTableFilterComposer,
      $$VisitSamplesTableOrderingComposer,
      $$VisitSamplesTableAnnotationComposer,
      $$VisitSamplesTableCreateCompanionBuilder,
      $$VisitSamplesTableUpdateCompanionBuilder,
      (VisitSample, $$VisitSamplesTableReferences),
      VisitSample,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$MassBalanceDocumentsTableCreateCompanionBuilder =
    MassBalanceDocumentsCompanion Function({
      required String id,
      required String visitId,
      required String docType,
      required String filePath,
      Value<String> fileName,
      Value<String> caption,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MassBalanceDocumentsTableUpdateCompanionBuilder =
    MassBalanceDocumentsCompanion Function({
      Value<String> id,
      Value<String> visitId,
      Value<String> docType,
      Value<String> filePath,
      Value<String> fileName,
      Value<String> caption,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MassBalanceDocumentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MassBalanceDocumentsTable,
          MassBalanceDocument
        > {
  $$MassBalanceDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VisitsTable _visitIdTable(_$AppDatabase db) => db.visits.createAlias(
    $_aliasNameGenerator(db.massBalanceDocuments.visitId, db.visits.id),
  );

  $$VisitsTableProcessedTableManager get visitId {
    final $_column = $_itemColumn<String>('visit_id')!;

    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_visitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MassBalanceDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $MassBalanceDocumentsTable> {
  $$MassBalanceDocumentsTableFilterComposer({
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

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VisitsTableFilterComposer get visitId {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MassBalanceDocumentsTable> {
  $$MassBalanceDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VisitsTableOrderingComposer get visitId {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MassBalanceDocumentsTable> {
  $$MassBalanceDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VisitsTableAnnotationComposer get visitId {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.visitId,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MassBalanceDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MassBalanceDocumentsTable,
          MassBalanceDocument,
          $$MassBalanceDocumentsTableFilterComposer,
          $$MassBalanceDocumentsTableOrderingComposer,
          $$MassBalanceDocumentsTableAnnotationComposer,
          $$MassBalanceDocumentsTableCreateCompanionBuilder,
          $$MassBalanceDocumentsTableUpdateCompanionBuilder,
          (MassBalanceDocument, $$MassBalanceDocumentsTableReferences),
          MassBalanceDocument,
          PrefetchHooks Function({bool visitId})
        > {
  $$MassBalanceDocumentsTableTableManager(
    _$AppDatabase db,
    $MassBalanceDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MassBalanceDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MassBalanceDocumentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MassBalanceDocumentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> visitId = const Value.absent(),
                Value<String> docType = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MassBalanceDocumentsCompanion(
                id: id,
                visitId: visitId,
                docType: docType,
                filePath: filePath,
                fileName: fileName,
                caption: caption,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String visitId,
                required String docType,
                required String filePath,
                Value<String> fileName = const Value.absent(),
                Value<String> caption = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MassBalanceDocumentsCompanion.insert(
                id: id,
                visitId: visitId,
                docType: docType,
                filePath: filePath,
                fileName: fileName,
                caption: caption,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MassBalanceDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (visitId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.visitId,
                                referencedTable:
                                    $$MassBalanceDocumentsTableReferences
                                        ._visitIdTable(db),
                                referencedColumn:
                                    $$MassBalanceDocumentsTableReferences
                                        ._visitIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MassBalanceDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MassBalanceDocumentsTable,
      MassBalanceDocument,
      $$MassBalanceDocumentsTableFilterComposer,
      $$MassBalanceDocumentsTableOrderingComposer,
      $$MassBalanceDocumentsTableAnnotationComposer,
      $$MassBalanceDocumentsTableCreateCompanionBuilder,
      $$MassBalanceDocumentsTableUpdateCompanionBuilder,
      (MassBalanceDocument, $$MassBalanceDocumentsTableReferences),
      MassBalanceDocument,
      PrefetchHooks Function({bool visitId})
    >;
typedef $$InspectorsTableCreateCompanionBuilder =
    InspectorsCompanion Function({
      required String id,
      Value<String> fullName,
      Value<String> email,
      Value<String> phone,
      Value<String> region,
      Value<bool> isActive,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$InspectorsTableUpdateCompanionBuilder =
    InspectorsCompanion Function({
      Value<String> id,
      Value<String> fullName,
      Value<String> email,
      Value<String> phone,
      Value<String> region,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$InspectorsTableFilterComposer
    extends Composer<_$AppDatabase, $InspectorsTable> {
  $$InspectorsTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InspectorsTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectorsTable> {
  $$InspectorsTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InspectorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectorsTable> {
  $$InspectorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InspectorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InspectorsTable,
          Inspector,
          $$InspectorsTableFilterComposer,
          $$InspectorsTableOrderingComposer,
          $$InspectorsTableAnnotationComposer,
          $$InspectorsTableCreateCompanionBuilder,
          $$InspectorsTableUpdateCompanionBuilder,
          (
            Inspector,
            BaseReferences<_$AppDatabase, $InspectorsTable, Inspector>,
          ),
          Inspector,
          PrefetchHooks Function()
        > {
  $$InspectorsTableTableManager(_$AppDatabase db, $InspectorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspectorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspectorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InspectorsCompanion(
                id: id,
                fullName: fullName,
                email: email,
                phone: phone,
                region: region,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> fullName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => InspectorsCompanion.insert(
                id: id,
                fullName: fullName,
                email: email,
                phone: phone,
                region: region,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InspectorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InspectorsTable,
      Inspector,
      $$InspectorsTableFilterComposer,
      $$InspectorsTableOrderingComposer,
      $$InspectorsTableAnnotationComposer,
      $$InspectorsTableCreateCompanionBuilder,
      $$InspectorsTableUpdateCompanionBuilder,
      (Inspector, BaseReferences<_$AppDatabase, $InspectorsTable, Inspector>),
      Inspector,
      PrefetchHooks Function()
    >;
typedef $$ActivityLogsTableCreateCompanionBuilder =
    ActivityLogsCompanion Function({
      Value<int> id,
      required String action,
      required String description,
      required String actor,
      required DateTime createdAt,
    });
typedef $$ActivityLogsTableUpdateCompanionBuilder =
    ActivityLogsCompanion Function({
      Value<int> id,
      Value<String> action,
      Value<String> description,
      Value<String> actor,
      Value<DateTime> createdAt,
    });

class $$ActivityLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableFilterComposer({
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

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableOrderingComposer({
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

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityLogsTable> {
  $$ActivityLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ActivityLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityLogsTable,
          ActivityLog,
          $$ActivityLogsTableFilterComposer,
          $$ActivityLogsTableOrderingComposer,
          $$ActivityLogsTableAnnotationComposer,
          $$ActivityLogsTableCreateCompanionBuilder,
          $$ActivityLogsTableUpdateCompanionBuilder,
          (
            ActivityLog,
            BaseReferences<_$AppDatabase, $ActivityLogsTable, ActivityLog>,
          ),
          ActivityLog,
          PrefetchHooks Function()
        > {
  $$ActivityLogsTableTableManager(_$AppDatabase db, $ActivityLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ActivityLogsCompanion(
                id: id,
                action: action,
                description: description,
                actor: actor,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String action,
                required String description,
                required String actor,
                required DateTime createdAt,
              }) => ActivityLogsCompanion.insert(
                id: id,
                action: action,
                description: description,
                actor: actor,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityLogsTable,
      ActivityLog,
      $$ActivityLogsTableFilterComposer,
      $$ActivityLogsTableOrderingComposer,
      $$ActivityLogsTableAnnotationComposer,
      $$ActivityLogsTableCreateCompanionBuilder,
      $$ActivityLogsTableUpdateCompanionBuilder,
      (
        ActivityLog,
        BaseReferences<_$AppDatabase, $ActivityLogsTable, ActivityLog>,
      ),
      ActivityLog,
      PrefetchHooks Function()
    >;
typedef $$MasterCompaniesTableCreateCompanionBuilder =
    MasterCompaniesCompanion Function({
      required String cuaa,
      Value<String> ragioneSociale,
      Value<String> partitaIva,
      Value<String> indirizzo,
      Value<String> cap,
      Value<String> comune,
      Value<String> provincia,
      Value<String> referente,
      Value<String> telefono,
      Value<String> email,
      Value<String> pec,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MasterCompaniesTableUpdateCompanionBuilder =
    MasterCompaniesCompanion Function({
      Value<String> cuaa,
      Value<String> ragioneSociale,
      Value<String> partitaIva,
      Value<String> indirizzo,
      Value<String> cap,
      Value<String> comune,
      Value<String> provincia,
      Value<String> referente,
      Value<String> telefono,
      Value<String> email,
      Value<String> pec,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MasterCompaniesTableFilterComposer
    extends Composer<_$AppDatabase, $MasterCompaniesTable> {
  $$MasterCompaniesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cuaa => $composableBuilder(
    column: $table.cuaa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indirizzo => $composableBuilder(
    column: $table.indirizzo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cap => $composableBuilder(
    column: $table.cap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comune => $composableBuilder(
    column: $table.comune,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provincia => $composableBuilder(
    column: $table.provincia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referente => $composableBuilder(
    column: $table.referente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pec => $composableBuilder(
    column: $table.pec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasterCompaniesTableOrderingComposer
    extends Composer<_$AppDatabase, $MasterCompaniesTable> {
  $$MasterCompaniesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cuaa => $composableBuilder(
    column: $table.cuaa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indirizzo => $composableBuilder(
    column: $table.indirizzo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cap => $composableBuilder(
    column: $table.cap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comune => $composableBuilder(
    column: $table.comune,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provincia => $composableBuilder(
    column: $table.provincia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referente => $composableBuilder(
    column: $table.referente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pec => $composableBuilder(
    column: $table.pec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasterCompaniesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MasterCompaniesTable> {
  $$MasterCompaniesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cuaa =>
      $composableBuilder(column: $table.cuaa, builder: (column) => column);

  GeneratedColumn<String> get ragioneSociale => $composableBuilder(
    column: $table.ragioneSociale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partitaIva => $composableBuilder(
    column: $table.partitaIva,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indirizzo =>
      $composableBuilder(column: $table.indirizzo, builder: (column) => column);

  GeneratedColumn<String> get cap =>
      $composableBuilder(column: $table.cap, builder: (column) => column);

  GeneratedColumn<String> get comune =>
      $composableBuilder(column: $table.comune, builder: (column) => column);

  GeneratedColumn<String> get provincia =>
      $composableBuilder(column: $table.provincia, builder: (column) => column);

  GeneratedColumn<String> get referente =>
      $composableBuilder(column: $table.referente, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get pec =>
      $composableBuilder(column: $table.pec, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MasterCompaniesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MasterCompaniesTable,
          MasterCompany,
          $$MasterCompaniesTableFilterComposer,
          $$MasterCompaniesTableOrderingComposer,
          $$MasterCompaniesTableAnnotationComposer,
          $$MasterCompaniesTableCreateCompanionBuilder,
          $$MasterCompaniesTableUpdateCompanionBuilder,
          (
            MasterCompany,
            BaseReferences<_$AppDatabase, $MasterCompaniesTable, MasterCompany>,
          ),
          MasterCompany,
          PrefetchHooks Function()
        > {
  $$MasterCompaniesTableTableManager(
    _$AppDatabase db,
    $MasterCompaniesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasterCompaniesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasterCompaniesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasterCompaniesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cuaa = const Value.absent(),
                Value<String> ragioneSociale = const Value.absent(),
                Value<String> partitaIva = const Value.absent(),
                Value<String> indirizzo = const Value.absent(),
                Value<String> cap = const Value.absent(),
                Value<String> comune = const Value.absent(),
                Value<String> provincia = const Value.absent(),
                Value<String> referente = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> pec = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasterCompaniesCompanion(
                cuaa: cuaa,
                ragioneSociale: ragioneSociale,
                partitaIva: partitaIva,
                indirizzo: indirizzo,
                cap: cap,
                comune: comune,
                provincia: provincia,
                referente: referente,
                telefono: telefono,
                email: email,
                pec: pec,
                latitude: latitude,
                longitude: longitude,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cuaa,
                Value<String> ragioneSociale = const Value.absent(),
                Value<String> partitaIva = const Value.absent(),
                Value<String> indirizzo = const Value.absent(),
                Value<String> cap = const Value.absent(),
                Value<String> comune = const Value.absent(),
                Value<String> provincia = const Value.absent(),
                Value<String> referente = const Value.absent(),
                Value<String> telefono = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> pec = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MasterCompaniesCompanion.insert(
                cuaa: cuaa,
                ragioneSociale: ragioneSociale,
                partitaIva: partitaIva,
                indirizzo: indirizzo,
                cap: cap,
                comune: comune,
                provincia: provincia,
                referente: referente,
                telefono: telefono,
                email: email,
                pec: pec,
                latitude: latitude,
                longitude: longitude,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasterCompaniesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MasterCompaniesTable,
      MasterCompany,
      $$MasterCompaniesTableFilterComposer,
      $$MasterCompaniesTableOrderingComposer,
      $$MasterCompaniesTableAnnotationComposer,
      $$MasterCompaniesTableCreateCompanionBuilder,
      $$MasterCompaniesTableUpdateCompanionBuilder,
      (
        MasterCompany,
        BaseReferences<_$AppDatabase, $MasterCompaniesTable, MasterCompany>,
      ),
      MasterCompany,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$VisitCompaniesTableTableManager get visitCompanies =>
      $$VisitCompaniesTableTableManager(_db, _db.visitCompanies);
  $$VisitUecsTableTableManager get visitUecs =>
      $$VisitUecsTableTableManager(_db, _db.visitUecs);
  $$VisitLotsTableTableManager get visitLots =>
      $$VisitLotsTableTableManager(_db, _db.visitLots);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$ChecklistResponsesTableTableManager get checklistResponses =>
      $$ChecklistResponsesTableTableManager(_db, _db.checklistResponses);
  $$VisitAttachmentsTableTableManager get visitAttachments =>
      $$VisitAttachmentsTableTableManager(_db, _db.visitAttachments);
  $$VisitSignaturesTableTableManager get visitSignatures =>
      $$VisitSignaturesTableTableManager(_db, _db.visitSignatures);
  $$MassBalanceRecordsTableTableManager get massBalanceRecords =>
      $$MassBalanceRecordsTableTableManager(_db, _db.massBalanceRecords);
  $$VisitClosingsTableTableManager get visitClosings =>
      $$VisitClosingsTableTableManager(_db, _db.visitClosings);
  $$VisitSamplesTableTableManager get visitSamples =>
      $$VisitSamplesTableTableManager(_db, _db.visitSamples);
  $$MassBalanceDocumentsTableTableManager get massBalanceDocuments =>
      $$MassBalanceDocumentsTableTableManager(_db, _db.massBalanceDocuments);
  $$InspectorsTableTableManager get inspectors =>
      $$InspectorsTableTableManager(_db, _db.inspectors);
  $$ActivityLogsTableTableManager get activityLogs =>
      $$ActivityLogsTableTableManager(_db, _db.activityLogs);
  $$MasterCompaniesTableTableManager get masterCompanies =>
      $$MasterCompaniesTableTableManager(_db, _db.masterCompanies);
}
