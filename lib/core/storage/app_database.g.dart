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
    scheduledAt,
    companyName,
    crop,
    status,
    updatedAt,
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
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
  final DateTime updatedAt;
  const Visit({
    required this.id,
    required this.scheduledAt,
    required this.companyName,
    required this.crop,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['company_name'] = Variable<String>(companyName);
    map['crop'] = Variable<String>(crop);
    map['status'] = Variable<int>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      scheduledAt: Value(scheduledAt),
      companyName: Value(companyName),
      crop: Value(crop),
      status: Value(status),
      updatedAt: Value(updatedAt),
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
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
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
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Visit copyWith({
    String? id,
    DateTime? scheduledAt,
    String? companyName,
    String? crop,
    int? status,
    DateTime? updatedAt,
  }) => Visit(
    id: id ?? this.id,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    companyName: companyName ?? this.companyName,
    crop: crop ?? this.crop,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
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
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scheduledAt, companyName, crop, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.scheduledAt == this.scheduledAt &&
          other.companyName == this.companyName &&
          other.crop == this.crop &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<String> id;
  final Value<DateTime> scheduledAt;
  final Value<String> companyName;
  final Value<String> crop;
  final Value<int> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.companyName = const Value.absent(),
    this.crop = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitsCompanion.insert({
    required String id,
    required DateTime scheduledAt,
    required String companyName,
    required String crop,
    required int status,
    required DateTime updatedAt,
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
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (companyName != null) 'company_name': companyName,
      if (crop != null) 'crop': crop,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? scheduledAt,
    Value<String>? companyName,
    Value<String>? crop,
    Value<int>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      companyName: companyName ?? this.companyName,
      crop: crop ?? this.crop,
      status: status ?? this.status,
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
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('companyName: $companyName, ')
          ..write('crop: $crop, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
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
    updatedAt,
    latitude,
    longitude,
    isSynced,
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
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final bool isSynced;
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
    required this.updatedAt,
    this.latitude,
    this.longitude,
    required this.isSynced,
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
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['is_synced'] = Variable<bool>(isSynced);
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
      updatedAt: Value(updatedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      isSynced: Value(isSynced),
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
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
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
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'isSynced': serializer.toJson<bool>(isSynced),
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
    DateTime? updatedAt,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    bool? isSynced,
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
    updatedAt: updatedAt ?? this.updatedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    isSynced: isSynced ?? this.isSynced,
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
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    updatedAt,
    latitude,
    longitude,
    isSynced,
  );
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
          other.updatedAt == this.updatedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.isSynced == this.isSynced);
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
  final Value<DateTime> updatedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<bool> isSynced;
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
    this.updatedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isSynced = const Value.absent(),
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
    required DateTime updatedAt,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.isSynced = const Value.absent(),
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
    Expression<DateTime>? updatedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<bool>? isSynced,
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
      if (updatedAt != null) 'updated_at': updatedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isSynced != null) 'is_synced': isSynced,
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
    Value<DateTime>? updatedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<bool>? isSynced,
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
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSynced: isSynced ?? this.isSynced,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('isSynced: $isSynced, ')
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
  final DateTime updatedAt;
  const VisitUec({
    required this.id,
    required this.visitId,
    required this.coltura,
    required this.descrizione,
    required this.note,
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
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VisitUec copyWith({
    String? id,
    String? visitId,
    String? coltura,
    String? descrizione,
    String? note,
    DateTime? updatedAt,
  }) => VisitUec(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    coltura: coltura ?? this.coltura,
    descrizione: descrizione ?? this.descrizione,
    note: note ?? this.note,
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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, visitId, coltura, descrizione, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitUec &&
          other.id == this.id &&
          other.visitId == this.visitId &&
          other.coltura == this.coltura &&
          other.descrizione == this.descrizione &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class VisitUecsCompanion extends UpdateCompanion<VisitUec> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> coltura;
  final Value<String> descrizione;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VisitUecsCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.coltura = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitUecsCompanion.insert({
    required String id,
    required String visitId,
    this.coltura = const Value.absent(),
    this.descrizione = const Value.absent(),
    this.note = const Value.absent(),
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
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (visitId != null) 'visit_id': visitId,
      if (coltura != null) 'coltura': coltura,
      if (descrizione != null) 'descrizione': descrizione,
      if (note != null) 'note': note,
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
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VisitUecsCompanion(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      coltura: coltura ?? this.coltura,
      descrizione: descrizione ?? this.descrizione,
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
  final DateTime createdAt;
  const VisitAttachment({
    required this.id,
    required this.visitId,
    required this.filePath,
    required this.caption,
    required this.isSynced,
    this.uecId,
    this.checklistCode,
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

  /// Nome di chi firma (se representative)
  final String? signerName;
  final DateTime createdAt;
  final bool isSynced;
  const VisitSignature({
    required this.id,
    required this.visitId,
    required this.signatureType,
    required this.filePath,
    this.signerName,
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
    DateTime? createdAt,
    bool? isSynced,
  }) => VisitSignature(
    id: id ?? this.id,
    visitId: visitId ?? this.visitId,
    signatureType: signatureType ?? this.signatureType,
    filePath: filePath ?? this.filePath,
    signerName: signerName.present ? signerName.value : this.signerName,
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
          other.createdAt == this.createdAt &&
          other.isSynced == this.isSynced);
}

class VisitSignaturesCompanion extends UpdateCompanion<VisitSignature> {
  final Value<String> id;
  final Value<String> visitId;
  final Value<String> signatureType;
  final Value<String> filePath;
  final Value<String?> signerName;
  final Value<DateTime> createdAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const VisitSignaturesCompanion({
    this.id = const Value.absent(),
    this.visitId = const Value.absent(),
    this.signatureType = const Value.absent(),
    this.filePath = const Value.absent(),
    this.signerName = const Value.absent(),
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
          ..write('createdAt: $createdAt, ')
          ..write('isSynced: $isSynced, ')
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
  ]);
}

typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      required String id,
      required DateTime scheduledAt,
      required String companyName,
      required String crop,
      required int status,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<String> id,
      Value<DateTime> scheduledAt,
      Value<String> companyName,
      Value<String> crop,
      Value<int> status,
      Value<DateTime> updatedAt,
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                scheduledAt: scheduledAt,
                companyName: companyName,
                crop: crop,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime scheduledAt,
                required String companyName,
                required String crop,
                required int status,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                scheduledAt: scheduledAt,
                companyName: companyName,
                crop: crop,
                status: status,
                updatedAt: updatedAt,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (visitCompaniesRefs) db.visitCompanies,
                    if (visitUecsRefs) db.visitUecs,
                    if (visitAttachmentsRefs) db.visitAttachments,
                    if (visitSignaturesRefs) db.visitSignatures,
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
      required DateTime updatedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isSynced,
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
      Value<DateTime> updatedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<bool> isSynced,
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
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
                updatedAt: updatedAt,
                latitude: latitude,
                longitude: longitude,
                isSynced: isSynced,
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
                required DateTime updatedAt,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
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
                updatedAt: updatedAt,
                latitude: latitude,
                longitude: longitude,
                isSynced: isSynced,
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
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitUecsCompanion(
                id: id,
                visitId: visitId,
                coltura: coltura,
                descrizione: descrizione,
                note: note,
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
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VisitUecsCompanion.insert(
                id: id,
                visitId: visitId,
                coltura: coltura,
                descrizione: descrizione,
                note: note,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSignaturesCompanion(
                id: id,
                visitId: visitId,
                signatureType: signatureType,
                filePath: filePath,
                signerName: signerName,
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
                required DateTime createdAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSignaturesCompanion.insert(
                id: id,
                visitId: visitId,
                signatureType: signatureType,
                filePath: filePath,
                signerName: signerName,
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
}
