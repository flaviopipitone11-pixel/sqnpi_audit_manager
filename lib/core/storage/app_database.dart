import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/visit_outcome.dart';

part 'app_database.g.dart';

/// Stato della visita (salvato come int in DB)
enum VisitStatus { daIniziare, inCorso, chiusaDaSincronizzare, sincronizzata }

/// Conformità item checklist (salvato come int in DB)
enum Conformita { ok, na, ko }

/// -------------------------
/// TABELLE
/// -------------------------

class Visits extends Table {
  TextColumn get id => text()();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get companyName => text()();
  TextColumn get crop => text()();
  IntColumn get status => integer()();
  TextColumn get visitType => text().withDefault(const Constant('ACA'))(); // ACA, MARCHIO, CAMPIONAMENTO
  IntColumn get durationHours => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class VisitCompanies extends Table {
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get ragioneSociale => text().withDefault(const Constant(''))();
  TextColumn get cuaa => text().withDefault(const Constant(''))();
  TextColumn get partitaIva => text().withDefault(const Constant(''))();

  TextColumn get indirizzo => text().withDefault(const Constant(''))();
  TextColumn get cap => text().withDefault(const Constant(''))();
  TextColumn get comune => text().withDefault(const Constant(''))();
  TextColumn get provincia => text().withDefault(const Constant(''))();

  TextColumn get referente => text().withDefault(const Constant(''))();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  // M904 rev. 08 - Nuovi campi compliance
  BoolColumn get isNewOperator =>
      boolean().withDefault(const Constant(false))();
  TextColumn get processingType =>
      text().withDefault(const Constant('proprio'))(); // 'proprio' o 'terzista'
  TextColumn get thirdPartyCertNumber =>
      text().withDefault(const Constant(''))();
  BoolColumn get siVerification =>
      boolean().withDefault(const Constant(false))();

  // M904 rev. 08 - Nuovi campi aggiuntivi
  TextColumn get latitudeText => text().withDefault(const Constant(''))();
  TextColumn get longitudeText => text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteAddress =>
      text().withDefault(const Constant(''))();
  TextColumn get peakPeriodFrom => text().withDefault(const Constant(''))();
  TextColumn get peakPeriodTo => text().withDefault(const Constant(''))();
  BoolColumn get isJointVisit => boolean().withDefault(const Constant(false))();
  TextColumn get jointVisitDetails => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {visitId};
}

class VisitUecs extends Table {
  TextColumn get id => text()();
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get coltura => text().withDefault(const Constant(''))();
  TextColumn get descrizione => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class VisitLots extends Table {
  TextColumn get id => text()();
  TextColumn get uecId => text().customConstraint(
    'NOT NULL REFERENCES visit_uecs(id) ON DELETE CASCADE',
  )();

  TextColumn get codice => text().withDefault(const Constant(''))();
  TextColumn get quantita => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Template checklist importata dall’Excel (una riga = un requisito)
class ChecklistItems extends Table {
  /// Codice requisito: es. 0.1, 1.10, 3.2.1 ecc
  TextColumn get code => text()();

  /// "Fase" = gerarchia serializzata, es: "03 - Impegni... > Difesa..."
  TextColumn get fase => text().withDefault(const Constant(''))();

  TextColumn get obbligo => text().withDefault(const Constant(''))();
  TextColumn get indicatorType => text().withDefault(const Constant(''))();
  TextColumn get deroghe => text().withDefault(const Constant(''))();
  TextColumn get noteNorma => text().withDefault(const Constant(''))();

  TextColumn get tipologiaControllo => text().withDefault(const Constant(''))();
  TextColumn get frequenzaSingolo => text().withDefault(const Constant(''))();
  TextColumn get frequenzaAssociato => text().withDefault(const Constant(''))();

  TextColumn get gravitaUecText => text().withDefault(const Constant(''))();
  TextColumn get esclusioneUecText => text().withDefault(const Constant(''))();
  TextColumn get gravitaOperatoreText =>
      text().withDefault(const Constant(''))();
  TextColumn get esclusioneOperatoreText =>
      text().withDefault(const Constant(''))();
  TextColumn get esclusioneLottoText =>
      text().withDefault(const Constant(''))();
  BoolColumn get hasEsclusioneLotto =>
      boolean().withDefault(const Constant(false))();
  TextColumn get colGText => text().withDefault(const Constant(''))();
  TextColumn get disposizioniRegionali =>
      text().withDefault(const Constant(''))();

  /// Ordinamento globale per mantenere l’ordine dell’Excel
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

/// Allegati fotografici associati a una visita
class VisitAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  /// Percorso assoluto del file immagine sul filesystem locale
  TextColumn get filePath => text()();

  /// Didascalia opzionale
  TextColumn get caption => text().withDefault(const Constant(''))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Collegamento opzionale a una UEC
  TextColumn get uecId => text().nullable().customConstraint(
    'NULL REFERENCES visit_uecs(id) ON DELETE SET NULL',
  )();

  /// Collegamento opzionale a un requisito della checklist
  TextColumn get checklistCode => text().nullable().customConstraint(
    'NULL REFERENCES checklist_items(code) ON DELETE SET NULL',
  )();

  /// Coordinate geografiche catturate (M904)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Risposte checklist per UEC (una riga per itemCode per UEC)
class ChecklistResponses extends Table {
  TextColumn get id => text()(); // RESP-<uecId>-<itemCode>

  TextColumn get uecId => text().customConstraint(
    'NOT NULL REFERENCES visit_uecs(id) ON DELETE CASCADE',
  )();

  TextColumn get itemCode => text().customConstraint(
    'NOT NULL REFERENCES checklist_items(code) ON DELETE RESTRICT',
  )();

  IntColumn get conformita => integer()(); // Conformita.index
  IntColumn get livelloKo => integer().nullable()(); // 1/2/3 se KO

  IntColumn get punteggioUec => integer().nullable()();
  IntColumn get punteggioOperatore => integer().nullable()();

  TextColumn get rilievoNc => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {uecId, itemCode},
  ];
}

/// Firme apposte al termine della visita
class VisitSignatures extends Table {
  TextColumn get id => text()(); // SIG-<visitId>-<type>
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  /// Tipo di firma: 'inspector', 'representative', etc.
  TextColumn get signatureType => text()();

  /// Percorso del file immagine della firma
  TextColumn get filePath => text()();

  /// Nome di chi firma (se representative)
  TextColumn get signerName => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// M904 rev. 08 - Bilancio di Massa
class MassBalanceRecords extends Table {
  TextColumn get id => text()(); // MB-<visitId>
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get substances =>
      text().withDefault(const Constant(''))(); // JSON lista sostanze attive
  RealColumn get purchased => real().withDefault(const Constant(0))();
  RealColumn get used => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get discrepancy => real().withDefault(const Constant(0))();
  TextColumn get referenceDocuments => text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// M904 rev. 08 - Chiusura e Sanzioni
class VisitClosings extends Table {
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get correctiveActions => text().withDefault(const Constant(''))();
  DateTimeColumn get resolutionDeadline => dateTime().nullable()(); // max 7gg
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {visitId};
}

/// -------------------------
/// CONNESSIONE DB
/// -------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final dbFolder = Directory(p.join(dir.path, 'sqnpi_audit_manager'));
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    final file = File(p.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// M904 rev. 08 - Campionamento
class VisitSamples extends Table {
  TextColumn get id => text()(); // SMP-<visitId>-<index>
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get sampleCode => text().withDefault(const Constant(''))();
  TextColumn get matrixType => text().withDefault(const Constant(''))();
  TextColumn get sealNumber => text().withDefault(const Constant(''))();

  /// Foto del verbale di prelievo
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// -------------------------
/// DATABASE
/// -------------------------

@DriftDatabase(
  tables: [
    Visits,
    VisitCompanies,
    VisitUecs,
    VisitLots,
    ChecklistItems,
    ChecklistResponses,
    VisitAttachments,
    VisitSignatures,
    MassBalanceRecords,
    VisitClosings,
    VisitSamples,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  Future<int> countUnsyncedResponses() async {
    final query = selectOnly(checklistResponses)
      ..addColumns([checklistResponses.id.count()])
      ..where(checklistResponses.isSynced.equals(false));
    final result = await query
        .map((row) => row.read(checklistResponses.id.count()))
        .getSingle();
    return result ?? 0;
  }

  Future<int> countUnsyncedAttachments() async {
    final query = selectOnly(visitAttachments)
      ..addColumns([visitAttachments.id.count()])
      ..where(visitAttachments.isSynced.equals(false));
    final result = await query
        .map((row) => row.read(visitAttachments.id.count()))
        .getSingle();
    return result ?? 0;
  }

  Future<int> countUnsyncedSignatures() async {
    final query = selectOnly(visitSignatures)
      ..addColumns([visitSignatures.id.count()])
      ..where(visitSignatures.isSynced.equals(false));
    final result = await query
        .map((row) => row.read(visitSignatures.id.count()))
        .getSingle();
    return result ?? 0;
  }

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(visitCompanies);
      if (from < 3) {
        await m.createTable(visitUecs);
        await m.createTable(visitLots);
      }
      if (from < 4) {
        await m.createTable(checklistItems);
        await m.createTable(checklistResponses);
      }
      if (from < 5) {
        await m.createTable(visitAttachments);
      }
      if (from < 6) {
        await m.addColumn(visitAttachments, visitAttachments.uecId);
        await m.addColumn(visitAttachments, visitAttachments.checklistCode);
      }
      if (from < 7) {
        await m.addColumn(visitCompanies, visitCompanies.latitude);
        await m.addColumn(visitCompanies, visitCompanies.longitude);
      }
      if (from < 8) {
        await m.addColumn(checklistResponses, checklistResponses.isSynced);
        await m.addColumn(visitAttachments, visitAttachments.isSynced);
        await m.addColumn(visitCompanies, visitCompanies.isSynced);
      }
      if (from < 9) {
        await m.createTable(visitSignatures);
      }
      if (from < 10) {
        await m.addColumn(checklistItems, checklistItems.esclusioneLottoText);
        await m.addColumn(checklistItems, checklistItems.hasEsclusioneLotto);
        // Forza l'aggiornamento a non-null per i record esistenti per evitare il crash del mapper di Drift
        await customStatement(
          "UPDATE checklist_items SET esclusione_lotto_text = '' WHERE esclusione_lotto_text IS NULL;",
        );
        await customStatement(
          "UPDATE checklist_items SET has_esclusione_lotto = 0 WHERE has_esclusione_lotto IS NULL;",
        );
      }
      if (from < 11) {
        await m.addColumn(checklistItems, checklistItems.colGText);
      }
      if (from < 12) {
        // M904 rev. 08 updates
        await m.addColumn(visitCompanies, visitCompanies.isNewOperator);
        await m.addColumn(visitCompanies, visitCompanies.processingType);
        await m.addColumn(visitCompanies, visitCompanies.thirdPartyCertNumber);
        await m.addColumn(visitCompanies, visitCompanies.siVerification);

        await m.createTable(massBalanceRecords);
        await m.createTable(visitClosings);
      }
      if (from < 13) {
        await m.addColumn(visitAttachments, visitAttachments.latitude);
        await m.addColumn(visitAttachments, visitAttachments.longitude);
      }
      if (from < 14) {
        await m.addColumn(visitCompanies, visitCompanies.latitudeText);
        await m.addColumn(visitCompanies, visitCompanies.longitudeText);
        await m.addColumn(
          visitCompanies,
          visitCompanies.manipulationSiteAddress,
        );
        await m.addColumn(visitCompanies, visitCompanies.peakPeriodFrom);
        await m.addColumn(visitCompanies, visitCompanies.peakPeriodTo);
        await m.addColumn(visitCompanies, visitCompanies.isJointVisit);
        await m.addColumn(visitCompanies, visitCompanies.jointVisitDetails);
      }
        if (from < 15) {
          await m.addColumn(visits, visits.visitType);
          await m.addColumn(visitUecs, visitUecs.latitude);
          await m.addColumn(visitUecs, visitUecs.longitude);
          await m.addColumn(visitUecs, visitUecs.photoPath);
        }
        if (from < 16) {
          await m.createTable(visitSamples);
        }
        if (from < 17) {
          await m.addColumn(visits, visits.durationHours);
          await customStatement(
            "UPDATE visits SET duration_hours = 0 WHERE duration_hours IS NULL;",
          );
        }
        if (from < 18) {
          await m.addColumn(checklistItems, checklistItems.indicatorType);
          // Forza re-import pulendo i requisiti se non ci sono risposte
          final rowResp = await customSelect(
            'SELECT COUNT(*) AS c FROM checklist_responses LIMIT 1',
          ).getSingle();
          final respCount = rowResp.read<int>('c');
          if (respCount == 0) {
            await customStatement('DELETE FROM checklist_items');
          }
        }
      },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Elimina fisicamente il file del database
  Future<void> deleteDatabaseFile() async {
    await close();
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'sqnpi_audit_manager', 'app.sqlite'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// -------------------------
  /// VISITE
  /// -------------------------

  Stream<List<Visit>> watchVisits() {
    return (select(
      visits,
    )..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)])).watch();
  }

  Stream<Visit?> watchVisitById(String id) {
    return (select(visits)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> upsertVisit({
    required String id,
    required DateTime scheduledAt,
    required String companyName,
    required String crop,
    required VisitStatus status,
    String visitType = 'ACA',
    int durationHours = 0,
  }) async {
    await into(visits).insertOnConflictUpdate(
      VisitsCompanion.insert(
        id: id,
        scheduledAt: scheduledAt,
        companyName: companyName,
        crop: crop,
        status: status.index,
        visitType: Value(visitType),
        durationHours: Value(durationHours),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// -------------------------
  /// ANAGRAFICA
  /// -------------------------

  Stream<VisitCompany?> watchCompanyByVisitId(String visitId) {
    return (select(
      visitCompanies,
    )..where((t) => t.visitId.equals(visitId))).watchSingleOrNull();
  }

  Future<void> upsertCompany({
    required String visitId,
    required String ragioneSociale,
    required String cuaa,
    required String partitaIva,
    required String indirizzo,
    required String cap,
    required String comune,
    required String provincia,
    required String referente,
    required String telefono,
    required String email,
    required double? latitude,
    required double? longitude,
    bool isNewOperator = false,
    String processingType = 'proprio',
    String thirdPartyCertNumber = '',
    bool siVerification = false,
    String latitudeText = '',
    String longitudeText = '',
    String manipulationSiteAddress = '',
    String peakPeriodFrom = '',
    String peakPeriodTo = '',
    bool isJointVisit = false,
    String jointVisitDetails = '',
  }) async {
    await into(visitCompanies).insertOnConflictUpdate(
      VisitCompaniesCompanion(
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
        latitude: Value(latitude),
        longitude: Value(longitude),
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
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// -------------------------
  /// M904 COMPLIANCE: BILANCIO E CHIUSURA
  /// -------------------------

  Stream<MassBalanceRecord?> watchMassBalanceByVisitId(String visitId) {
    return (select(massBalanceRecords)..where((t) => t.visitId.equals(visitId)))
        .watchSingleOrNull();
  }

  Future<void> upsertMassBalance({
    required String visitId,
    required String substances,
    required double purchased,
    required double used,
    required double stock,
    required double discrepancy,
    required String referenceDocuments,
  }) async {
    final id = 'MB-$visitId';
    await into(massBalanceRecords).insertOnConflictUpdate(
      MassBalanceRecordsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        substances: Value(substances),
        purchased: Value(purchased),
        used: Value(used),
        stock: Value(stock),
        discrepancy: Value(discrepancy),
        referenceDocuments: Value(referenceDocuments),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<VisitClosing?> watchClosingByVisitId(String visitId) {
    return (select(visitClosings)..where((t) => t.visitId.equals(visitId)))
        .watchSingleOrNull();
  }

  Future<void> upsertClosing({
    required String visitId,
    required String correctiveActions,
    required DateTime? resolutionDeadline,
    required bool isClosed,
  }) async {
    await into(visitClosings).insertOnConflictUpdate(
      VisitClosingsCompanion(
        visitId: Value(visitId),
        correctiveActions: Value(correctiveActions),
        resolutionDeadline: Value(resolutionDeadline),
        isClosed: Value(isClosed),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Sync visit status
    final newStatus = isClosed
        ? VisitStatus.chiusaDaSincronizzare
        : VisitStatus.inCorso;
    await (update(visits)..where((t) => t.id.equals(visitId))).write(
      VisitsCompanion(status: Value(newStatus.index)),
    );
  }

  /// -------------------------
  /// UEC / LOTTI
  /// -------------------------

  Stream<List<VisitUec>> watchUecsByVisitId(String visitId) {
    return (select(visitUecs)..where((t) => t.visitId.equals(visitId))).watch();
  }

  Future<void> upsertUec({
    required String id,
    required String visitId,
    required String coltura,
    required String descrizione,
    required String note,
    double? latitude,
    double? longitude,
    String? photoPath,
  }) async {
    await into(visitUecs).insertOnConflictUpdate(
      VisitUecsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        coltura: Value(coltura),
        descrizione: Value(descrizione),
        note: Value(note),
        latitude: Value(latitude),
        longitude: Value(longitude),
        photoPath: Value(photoPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteUec(String uecId) async {
    return (delete(visitUecs)..where((t) => t.id.equals(uecId))).go();
  }

  Stream<List<VisitLot>> watchLotsByUecId(String uecId) {
    return (select(visitLots)..where((t) => t.uecId.equals(uecId))).watch();
  }

  Future<void> upsertLot({
    required String id,
    required String uecId,
    required String codice,
    required String quantita,
    required String note,
  }) async {
    await into(visitLots).insertOnConflictUpdate(
      VisitLotsCompanion(
        id: Value(id),
        uecId: Value(uecId),
        codice: Value(codice),
        quantita: Value(quantita),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteLot(String lotId) async {
    return (delete(visitLots)..where((t) => t.id.equals(lotId))).go();
  }

  Stream<List<VisitLot>> watchLotsByVisitId(String visitId) {
    final query = select(visitLots).join([
      innerJoin(visitUecs, visitUecs.id.equalsExp(visitLots.uecId)),
    ]);
    query.where(visitUecs.visitId.equals(visitId));
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(visitLots)).toList());
  }

  /// -------------------------
  /// CHECKLIST IMPORT (Excel -> checklist_items)
  /// -------------------------

  Future<void> ensureChecklistImportedFromAsset() async {
    try {
      // Verifichiamo il numero di record in modo grezzo (SQL puro) per evitare ogni mapping di Drift
      // che potrebbe fallire se le colonne appena aggiunte in migrazione sono ancora NULL o se il file è corrotto.
      final rowCount = await customSelect(
        'SELECT COUNT(*) AS c FROM checklist_items',
      ).getSingle();
      final count = rowCount.read<int>('c');

      if (count > 0) {
        // Se abbiamo dati, controlliamo se sono del nuovo formato (senza HAS_ESCLUSIONE_LOTTO a true)
        // Usiamo di nuovo SQL puro per evitare il mapper
        // Force re-import if we are at version 18 to ensure all new columns are full
        final rowCheck = await customSelect(
          'SELECT COUNT(*) AS c FROM checklist_items WHERE indicator_type != "" LIMIT 10',
        ).getSingle();
        final dataCount = rowCheck.read<int>('c');

        if (dataCount > 5) {
           // Se abbiamo già abbastanza dati nuovi, allora okay, evitiamo il re-import ad ogni avvio
           // ma se ne abbiamo pochi (es. 0 o solo i primi), rifacciamo.
           // Per sicurezza, in questa fase di sviluppo, lo lasciamo procedere se non siamo sicuri.
           // return; 
        }

        // Se siamo qui, i dati sono vecchi. Svuotiamo e re-importiamo se possibile.
        final rowResp = await customSelect(
          'SELECT COUNT(*) AS c FROM checklist_responses LIMIT 1',
        ).getSingle();
        final respCount = rowResp.read<int>('c');

        if (respCount == 0) {
          await customStatement('DELETE FROM checklist_items');
        } else {
          // Se ci sono risposte, facciamo comunque l'import (insertOrReplace)
          // ma evitiamo di cancellare tutto.
        }
      }

      final bd = await rootBundle.load(
        'assets/checklists/CHECKLIST AGGIORNATA.xlsx',
      );
      final bytes = bd.buffer.asUint8List();

      // Offload intensive synchronous Excel parsing to a background isolate
      final result = await compute(_parseExcelInBackground, bytes);

      final itemsList = result['items'] as List<Map<String, dynamic>>;
      final skipped = result['skipped'] as int;
      final sheetName = result['sheetName'] as String;

      int imported = 0;

      await batch((b) async {
        for (final item in itemsList) {
          imported++;
          b.insert(
            checklistItems,
            ChecklistItemsCompanion(
              code: Value(item['code'] as String),
              fase: Value(item['fase'] as String),
              obbligo: Value(item['obbligo'] as String),
              deroghe: Value(item['deroghe'] as String),
              noteNorma: Value(item['noteNorma'] as String),
              tipologiaControllo: Value(item['tipologiaControllo'] as String),
              frequenzaSingolo: Value(item['frequenzaSingolo'] as String),
              frequenzaAssociato: Value(item['frequenzaAssociato'] as String),
              gravitaUecText: Value(item['gravitaUecText'] as String),
              esclusioneUecText: Value(item['esclusioneUecText'] as String),
              gravitaOperatoreText: Value(
                item['gravitaOperatoreText'] as String,
              ),
              esclusioneOperatoreText: Value(
                item['esclusioneOperatoreText'] as String,
              ),
              disposizioniRegionali: Value(
                item['disposizioniRegionali'] as String,
              ),
              esclusioneLottoText: Value(item['esclusioneLottoText'] as String),
              hasEsclusioneLotto: Value(item['hasEsclusioneLotto'] as bool),
              indicatorType: Value(item['indicatorType'] as String),
              sortOrder: Value(item['sortOrder'] as int),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      debugPrint(
        '[SQNPI IMPORT] raw sheet="$sheetName" imported=$imported skipped=$skipped',
      );

      if (imported == 0) {
        throw Exception(
          'Import checklist completato ma nessun requisito è stato inserito. Struttura excel non riconosciuta.',
        );
      }
    } catch (e) {
      if (e.toString().contains('disk I/O error') ||
          e.toString().contains('no column named')) {
        throw Exception('SCHEMA_CORRUPTED');
      }
      rethrow;
    }
  }

  /// Forza un "reset" del template e reimporta dall’asset Excel.
  Stream<int> watchNcCountByVisitId(String visitId) {
    final query = select(checklistResponses).join([
      innerJoin(visitUecs, visitUecs.id.equalsExp(checklistResponses.uecId)),
    ]);
    query.where(
      visitUecs.visitId.equals(visitId) &
          checklistResponses.conformita.equals(2),
    );

    return query.watch().map((rows) => rows.length);
  }

  Future<void> resetChecklistAndReimport() async {
    try {
      await transaction(() async {
        await customStatement('DELETE FROM checklist_responses');
        await customStatement('DELETE FROM checklist_items');
      });
      await ensureChecklistImportedFromAsset();
    } catch (e) {
      // Se il file è bloccato da un disk I/O error o corrotto, triggers hard reset.
      debugPrint('Reset parziale fallito: $e');
      if (e.toString().contains('disk I/O error') ||
          e.toString().contains('SCHEMA_CORRUPTED') ||
          e.toString().contains('no column named')) {
        throw Exception('SCHEMA_CORRUPTED');
      }
      rethrow;
    }
  }

  /// -------------------------
  /// CHECKLIST QUERY
  /// -------------------------

  Stream<List<ChecklistItem>> watchChecklistItemsByFase(String fase) {
    return (select(checklistItems)
          ..where((t) => t.fase.equals(fase))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Elenco fasi/categorie in ordine Excel (MIN(sort_order)).
  Stream<List<String>> watchFasi() {
    final sql = '''
SELECT DISTINCT TRIM(fase) AS fase_trimmed, MIN(sort_order) AS min_sort
FROM checklist_items
WHERE fase_trimmed <> ''
GROUP BY fase_trimmed
ORDER BY min_sort ASC
''';

    return customSelect(sql, readsFrom: {checklistItems}).watch().map((rows) {
      return rows.map((r) => r.read<String>('fase_trimmed')).toList();
    });
  }

  Stream<ChecklistResponse?> watchResponse(String uecId, String itemCode) {
    return (select(checklistResponses)
          ..where((t) => t.uecId.equals(uecId) & t.itemCode.equals(itemCode)))
        .watchSingleOrNull();
  }

  Future<void> upsertResponse({
    required String uecId,
    required String itemCode,
    required Conformita conformita,
    required int? livelloKo,
    required int? punteggioUec,
    required int? punteggioOperatore,
    required String rilievoNc,
    required String note,
  }) async {
    final id = 'RESP-$uecId-$itemCode';
    await into(checklistResponses).insertOnConflictUpdate(
      ChecklistResponsesCompanion(
        id: Value(id),
        uecId: Value(uecId),
        itemCode: Value(itemCode),
        conformita: Value(conformita.index),
        livelloKo: Value(livelloKo),
        punteggioUec: Value(punteggioUec),
        punteggioOperatore: Value(punteggioOperatore),
        rilievoNc: Value(rilievoNc),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<ChecklistResponse>> watchResponsesByVisitId(String visitId) {
    final query = select(checklistResponses).join([
      innerJoin(
        visitUecs,
        visitUecs.id.equalsExp(checklistResponses.uecId),
      ),
    ])..where(visitUecs.visitId.equals(visitId));

    return query.watch().map((rows) => rows.map((r) => r.readTable(checklistResponses)).toList());
  }

  Stream<List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>>
  watchNonConformitaByVisit(String visitId) {
    final query =
        select(checklistResponses).join([
          innerJoin(
            checklistItems,
            checklistItems.code.equalsExp(checklistResponses.itemCode),
          ),
          innerJoin(
            visitUecs,
            visitUecs.id.equalsExp(checklistResponses.uecId),
          ),
        ])..where(
          visitUecs.visitId.equals(visitId) &
              checklistResponses.conformita.equals(Conformita.ko.index),
        );

    return query.watch().map((rows) {
      return rows.map((row) {
        return (
          response: row.readTable(checklistResponses),
          item: row.readTable(checklistItems),
          uec: row.readTable(visitUecs),
        );
      }).toList();
    });
  }

  /// -------------------------
  /// SCORE: UEC (somma punteggioUec)
  /// -------------------------
  Stream<int> watchSumPunteggioUec(String uecId) {
    final sumExp = checklistResponses.punteggioUec.sum();
    final q = selectOnly(checklistResponses)
      ..addColumns([sumExp])
      ..where(checklistResponses.uecId.equals(uecId));
    return q.watch().map((rows) => rows.first.read(sumExp) ?? 0);
  }

  /// -------------------------
  /// SCORE: OPERATORE (somma punteggioOperatore su tutta la visita)
  /// -------------------------
  Stream<int> watchSumPunteggioOperatoreByVisit(String visitId) {
    final sumExp = checklistResponses.punteggioOperatore.sum();

    final query = selectOnly(checklistResponses)
      ..addColumns([sumExp])
      ..join([
        innerJoin(visitUecs, visitUecs.id.equalsExp(checklistResponses.uecId)),
      ])
      ..where(visitUecs.visitId.equals(visitId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return 0;
      return rows.first.read(sumExp) ?? 0;
    });
  }

  /// -------------------------
  /// OUTCOME VISITA (esito + riepilogo punteggi)
  /// -------------------------
  Stream<VisitOutcomeSummary> watchVisitOutcomeSummary(String visitId) {
    final sql =
        '''
WITH per_uec AS (
  SELECT
    r.uec_id AS uec_id,
    COALESCE(SUM(r.punteggio_uec), 0) AS sum_uec,
    COALESCE(SUM(r.punteggio_operatore), 0) AS sum_op
  FROM checklist_responses r
  INNER JOIN visit_uecs u ON u.id = r.uec_id
  WHERE u.visit_id = ?
  GROUP BY r.uec_id
)
SELECT
  COALESCE(SUM(sum_op), 0) AS sum_operatore_tot,
  COALESCE(MAX(sum_uec), 0) AS max_sum_uec,
  COALESCE(SUM(CASE WHEN sum_uec >= ${VisitOutcomeSummary.sogliaUec} THEN 1 ELSE 0 END), 0) AS uec_over_soglia
FROM per_uec;
''';

    return customSelect(
      sql,
      variables: [Variable<String>(visitId)],
      readsFrom: {checklistResponses, visitUecs},
    ).watch().map((rows) {
      if (rows.isEmpty) {
        return VisitOutcomeSummary.fromRaw(
          sumOperatoreTotale: 0,
          maxSommaUec: 0,
          uecOverSoglia: 0,
        );
      }

      final row = rows.single;

      final sumOperatoreTotale = row.read<int>('sum_operatore_tot');
      final maxSommaUec = row.read<int>('max_sum_uec');
      final uecOverSoglia = row.read<int>('uec_over_soglia');

      return VisitOutcomeSummary.fromRaw(
        sumOperatoreTotale: sumOperatoreTotale,
        maxSommaUec: maxSommaUec,
        uecOverSoglia: uecOverSoglia,
      );
    });
  }

  /// -------------------------
  /// ALLEGATI
  /// -------------------------

  Stream<List<VisitAttachment>> watchAttachmentsByVisitId(String visitId) {
    return (select(visitAttachments)
          ..where((t) => t.visitId.equals(visitId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> insertAttachment({
    required String visitId,
    required String filePath,
    String caption = '',
    String? uecId,
    String? checklistCode,
    double? latitude,
    double? longitude,
  }) async {
    final id = 'ATT-$visitId-${DateTime.now().microsecondsSinceEpoch}';
    await into(visitAttachments).insert(
      VisitAttachmentsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        filePath: Value(filePath),
        caption: Value(caption),
        uecId: Value(uecId),
        checklistCode: Value(checklistCode),
        latitude: Value(latitude),
        longitude: Value(longitude),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteAttachment(String id) async {
    return (delete(visitAttachments)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<VisitAttachment>> watchAttachmentsLinkedToUec(String uecId) {
    return (select(visitAttachments)
          ..where((t) => t.uecId.equals(uecId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<VisitAttachment>> watchAttachmentsLinkedToChecklist(String code) {
    return (select(visitAttachments)
          ..where((t) => t.checklistCode.equals(code))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchAttachmentsCountByChecklistCode(String code) {
    return (select(
      visitAttachments,
    )..where((t) => t.checklistCode.equals(code))).watch().map((l) => l.length);
  }

  Future<void> updateAttachmentLinks({
    required String id,
    String? uecId,
    String? checklistCode,
  }) {
    return (update(visitAttachments)..where((t) => t.id.equals(id))).write(
      VisitAttachmentsCompanion(
        uecId: Value(uecId),
        checklistCode: Value(checklistCode),
      ),
    );
  }

  /// -------------------------
  /// FIRME
  /// -------------------------

  Stream<List<VisitSignature>> watchSignaturesByVisitId(String visitId) {
    return (select(
      visitSignatures,
    )..where((t) => t.visitId.equals(visitId))).watch();
  }

  Future<void> insertSignature({
    required String visitId,
    required String signatureType,
    required String filePath,
    String? signerName,
  }) async {
    final id = 'SIG-$visitId-$signatureType';
    await into(visitSignatures).insertOnConflictUpdate(
      VisitSignaturesCompanion(
        id: Value(id),
        visitId: Value(visitId),
        signatureType: Value(signatureType),
        filePath: Value(filePath),
        signerName: Value(signerName),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteSignature(String id) async {
    return (delete(visitSignatures)..where((t) => t.id.equals(id))).go();
  }

  /// -------------------------
  /// SEED DEV
  /// -------------------------
  Future<void> seedIfEmpty() async {
    // Il database parte vuoto perché le visite andranno sincronizzate dal portale.
  }

  /// -------------------------
  /// CAMPIONAMENTO
  /// -------------------------

  Stream<List<VisitSample>> watchSamplesByVisitId(String visitId) {
    return (select(visitSamples)..where((t) => t.visitId.equals(visitId)))
        .watch();
  }

  Future<void> upsertSample({
    required String id,
    required String visitId,
    required String sampleCode,
    required String matrixType,
    required String sealNumber,
    String? photoPath,
  }) async {
    await into(visitSamples).insertOnConflictUpdate(
      VisitSamplesCompanion.insert(
        id: id,
        visitId: visitId,
        sampleCode: Value(sampleCode),
        matrixType: Value(matrixType),
        sealNumber: Value(sealNumber),
        photoPath: Value(photoPath),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> deleteSample(String id) async {
    return (delete(visitSamples)..where((t) => t.id.equals(id))).go();
  }
}

/// Label UI per stato visita
String visitStatusLabel(int statusIndex) {
  final s = VisitStatus.values[statusIndex];
  switch (s) {
    case VisitStatus.daIniziare:
      return 'Da iniziare';
    case VisitStatus.inCorso:
      return 'In corso';
    case VisitStatus.chiusaDaSincronizzare:
      return 'Chiusa (da sync)';
    case VisitStatus.sincronizzata:
      return 'Sincronizzata';
  }
}

// =========================================================================
// ISOLATE: EXCEL PARSING FUNCTIONS (Top-level)
// =========================================================================

/// Eseguita in un thread separato (background isolate) per non bloccare
/// la UI durante il massiccio decoding e mapping dell'Excel.
Map<String, dynamic> _parseExcelInBackground(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  final itemsMap = <String, Map<String, dynamic>>{};
  int totalSkipped = 0;
  int sortFallback = 0;
  String lastProcessedSheet = '';

  // Regex più permissiva: cerca una sequenza numerica (codice) ovunque nella stringa
  final codeRegex = RegExp(r'\d+(\.\d+)*');

  for (final sheet in excel.tables.values) {
    lastProcessedSheet = sheet.sheetName;
    final rows = sheet.rows;

    for (int r = 0; r < rows.length; r++) {
      final rowCells = rows[r];
      if (rowCells.isEmpty) continue;

      String rawCode = _cellString(rowCells, 0).trim();
      final col1 = _cellString(rowCells, 1).trim();
      final col2 = _cellString(rowCells, 2).trim();
      final col3 = _cellString(rowCells, 3).trim();
      final col4 = _cellString(rowCells, 4).trim();

      if (rawCode.isEmpty &&
          col1.isEmpty &&
          col2.isEmpty &&
          col3.isEmpty &&
          col4.isEmpty) {
        continue;
      }

      // Estraiamo il primo codice numerico trovato nella stringa rawCode
      final codeMatch = codeRegex.firstMatch(rawCode);
      if (codeMatch == null) {
        totalSkipped++;
        continue;
      }

      String code = codeMatch.group(0)!;
      String extraTextFromColA = rawCode.replaceFirst(code, '').trim();
      if (extraTextFromColA.startsWith('.') ||
          extraTextFromColA.startsWith('-')) {
        extraTextFromColA = extraTextFromColA.substring(1).trim();
      }

      // Determinazione della FASE basata sul CODICE
      String phaseName = 'ALTRO';
      final cleanCodeForParse = code.replaceAll(',', '.');
      final firstPart = cleanCodeForParse.split('.')[0];
      final majorPart = int.tryParse(firstPart);

      if (majorPart == 0) {
        phaseName = '0. VALUTAZIONE COMPLESSIVA E BILANCIO DI MASSA';
      } else if (majorPart == 1) {
        phaseName = '1. FASE DI COLTIVAZIONE E REGISTRI';
      } else if (majorPart != null && majorPart >= 2 && majorPart <= 14) {
        phaseName = 'TECNICHE AGRONOMICHE (ACA/MARCHIO)';
      } else if (majorPart != null && majorPart >= 15 && majorPart <= 17) {
        phaseName = 'POST-RACCOLTA E MARCHIO (MARCHIO)';
      } else {
        phaseName = 'ALTRE SEZIONI';
      }

      String obbligo = col2; // Col C - Descrizione completa
      String indicatorType = col4; // Col E - CI / CD

      if (obbligo.isEmpty) {
        // Fallback: cerca in ordine di probabilità
        if (extraTextFromColA.isNotEmpty) {
          obbligo = extraTextFromColA;
        } else if (col1.isNotEmpty) {
          obbligo = col1; // Col B
        } else if (col3.isNotEmpty) {
          obbligo = col3; // Col D
        }
      }

      if (obbligo.isEmpty) obbligo = 'Requisito $code';

      // Chiave per la mappa: se è un sub-item (es. 15.1), usiamo solo il codice.
      // Se è un header principale (es. 15), includiamo parte della descrizione nella chiave
      // per non sovrascrivere header diversi che hanno lo stesso codice numerico.
      final isMajorHeader = !code.contains('.');
      final mapKey = isMajorHeader
          ? '${code}_${obbligo.trim().toLowerCase()}'
          : code;

      final existing = itemsMap[mapKey];
      if (existing != null) {
        final existingObbligo = existing['obbligo'] as String;
        if (obbligo.isNotEmpty && obbligo != existingObbligo && !obbligo.startsWith('Requisito')) {
          if (existingObbligo.startsWith('Requisito')) {
            obbligo = obbligo;
          } else {
            obbligo = '$existingObbligo $obbligo';
          }
        } else {
          obbligo = existingObbligo.isNotEmpty ? existingObbligo : obbligo;
        }
        if (indicatorType.isEmpty) indicatorType = (existing['indicatorType'] as String?) ?? '';
      }

      final deroghe = _cellString(rowCells, 5).trim();
      final noteNorma = col3; // Colonna D per note
      final colGText = _cellString(rowCells, 6).trim();
      final tipologiaControllo = _cellString(rowCells, 7).trim();
      final frequenzaSingolo = _cellString(rowCells, 8).trim();
      final frequenzaAssociato = _cellString(rowCells, 9).trim();
      final gravitaUecText = _cellString(rowCells, 10).trim();
      final esclusioneUecText = _cellString(rowCells, 11).trim();
      final gravitaOperatoreText = _cellString(rowCells, 12).trim();
      final esclusioneOperatoreText = _cellString(rowCells, 13).trim();
      final disposizioniRegionali = _cellString(rowCells, 14).trim();

      final hasEsclusioneLotto = esclusioneUecText.isNotEmpty;
      final sortOrder = ++sortFallback;

      String dbCode = code;
      // PK uniqueness check
      int suffix = 1;
      while (itemsMap.values.any(
        (e) => e['code'] == dbCode && e['obbligo'] != obbligo,
      )) {
        dbCode = '${code}_D$suffix';
        suffix++;
      }

      itemsMap[mapKey] = {
        'code': dbCode,
        'fase': phaseName,
        'obbligo': obbligo.trim(),
        'indicatorType': indicatorType.trim(),
        'deroghe': deroghe.isNotEmpty ? deroghe : (existing?['deroghe'] ?? ''),
        'noteNorma': noteNorma.isNotEmpty ? noteNorma : (existing?['noteNorma'] ?? ''),
        'colGText': colGText.isNotEmpty ? colGText : (existing?['colGText'] ?? ''),
        'tipologiaControllo': tipologiaControllo.isNotEmpty ? tipologiaControllo : (existing?['tipologiaControllo'] ?? ''),
        'frequenzaSingolo': frequenzaSingolo.isNotEmpty ? frequenzaSingolo : (existing?['frequenzaSingolo'] ?? ''),
        'frequenzaAssociato': frequenzaAssociato.isNotEmpty ? frequenzaAssociato : (existing?['frequenzaAssociato'] ?? ''),
        'gravitaUecText': gravitaUecText.isNotEmpty ? gravitaUecText : (existing?['gravitaUecText'] ?? ''),
        'esclusioneUecText': esclusioneUecText.isNotEmpty ? esclusioneUecText : (existing?['esclusioneUecText'] ?? ''),
        'gravitaOperatoreText': gravitaOperatoreText.isNotEmpty ? gravitaOperatoreText : (existing?['gravitaOperatoreText'] ?? ''),
        'esclusioneOperatoreText': esclusioneOperatoreText.isNotEmpty ? esclusioneOperatoreText : (existing?['esclusioneOperatoreText'] ?? ''),
        'disposizioniRegionali': disposizioniRegionali.isNotEmpty ? disposizioniRegionali : (existing?['disposizioniRegionali'] ?? ''),
        'esclusioneLottoText': esclusioneUecText.isNotEmpty ? esclusioneUecText : (existing?['esclusioneLottoText'] ?? ''),
        'hasEsclusioneLotto': (existing?['hasEsclusioneLotto'] as bool? ?? false) || hasEsclusioneLotto,
        'sortOrder': existing?['sortOrder'] ?? sortOrder,
      };
    }
  }

  return {
    'items': itemsMap.values.toList(),
    'skipped': totalSkipped,
    'sheetName': lastProcessedSheet,
  };
}

/// Legge una cella Excel e la converte in stringa "pulita".
String _cellString(List<dynamic> row, int idx) {
  if (idx < 0 || idx >= row.length) return '';

  final cell = row[idx];
  if (cell == null) return '';

  dynamic raw;
  try {
    raw = (cell as dynamic).value;
  } catch (_) {
    raw = cell;
  }

  if (raw == null) return '';

  if (raw is double) {
    if (raw == raw.toInt()) {
      return raw.toInt().toString();
    }
    return raw.toString();
  }
  return raw.toString();
}
