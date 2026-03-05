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
  int get schemaVersion => 9;

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
    },
  );

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
  }) async {
    await into(visits).insertOnConflictUpdate(
      VisitsCompanion.insert(
        id: id,
        scheduledAt: scheduledAt,
        companyName: companyName,
        crop: crop,
        status: status.index,
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
        updatedAt: Value(DateTime.now()),
      ),
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
  }) async {
    await into(visitUecs).insertOnConflictUpdate(
      VisitUecsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        coltura: Value(coltura),
        descrizione: Value(descrizione),
        note: Value(note),
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

  /// -------------------------
  /// CHECKLIST IMPORT (Excel -> checklist_items)
  /// -------------------------

  /// Importa l’Excel normalizzato solo se checklist_items è vuota.
  ///
  /// File: assets/checklists/sqnpi_normalized_2025.xlsx
  /// Foglio: normalized_2025
  ///
  /// Colonne (0-based):
  /// 0 sort_order
  /// 1 macro_code
  /// 2 macro_title
  /// 3 sub_title
  /// 4 code
  /// 5 obbligo
  ///
  /// Nota importante: NON usiamo sheet.maxRows (bug/instabilità in alcune versioni di package:excel).
  Future<void> ensureChecklistImportedFromAsset() async {
    final countExp = checklistItems.code.count();
    final q = selectOnly(checklistItems)..addColumns([countExp]);
    final row = await q.getSingleOrNull();
    final count = row?.read(countExp) ?? 0;
    if (count > 0) return;

    final bd = await rootBundle.load('assets/checklists/cl_sqnpi_2025.xlsx');
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
            gravitaOperatoreText: Value(item['gravitaOperatoreText'] as String),
            esclusioneOperatoreText: Value(
              item['esclusioneOperatoreText'] as String,
            ),
            disposizioniRegionali: Value(
              item['disposizioniRegionali'] as String,
            ),
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
  }

  /// Forza un "reset" del template e reimporta dall’asset Excel.
  Future<void> resetChecklistAndReimport() async {
    await transaction(() async {
      await delete(checklistResponses).go();
      await delete(checklistItems).go();
    });

    await ensureChecklistImportedFromAsset();
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
SELECT fase, MIN(sort_order) AS min_sort
FROM checklist_items
WHERE TRIM(fase) <> ''
GROUP BY fase
ORDER BY min_sort ASC
''';

    return customSelect(sql, readsFrom: {checklistItems}).watch().map((rows) {
      return rows
          .map((r) => r.read<String>('fase').trim())
          .where((f) => f.isNotEmpty)
          .toList();
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

  Sheet? sheet;
  if (excel.sheets.containsKey('2023')) {
    sheet = excel.sheets['2023'];
  } else if (excel.sheets.isNotEmpty) {
    sheet = excel.sheets.values.first;
  }

  if (sheet == null) {
    throw Exception('Nessun foglio trovato Excel.');
  }

  final rows = sheet.rows; // <-- SAFE
  int skipped = 0;
  int sortFallback = 0;

  String currentMacroFase = 'Generico'; // Fallback
  final itemsList = <Map<String, dynamic>>[];

  // Data starts roughly at row 3 (0-indexed). Title parsing needs to scan the rows.
  for (int r = 2; r < rows.length; r++) {
    final rowCells = rows[r];

    // Skip entirely empty rows
    if (rowCells.every(
      (cell) => cell?.value == null || cell!.value.toString().trim().isEmpty,
    )) {
      continue;
    }

    final code = _cellString(rowCells, 0).trim();
    final macroTitle = _cellString(rowCells, 1).trim();
    final obbligo = _cellString(rowCells, 4).trim();

    // Se non c'è obbligo, è un titolo di categoria (es: "VALUTAZIONE COMPLESSIVA...")
    if (obbligo.isEmpty) {
      if (macroTitle.isNotEmpty || code.isNotEmpty) {
        // Store this title as the current macro block.
        final titleStr = macroTitle.isNotEmpty ? macroTitle : code;
        final prefix = code.isNotEmpty ? code : "";
        if (prefix.isNotEmpty && prefix != titleStr) {
          currentMacroFase = '$prefix - $titleStr';
        } else {
          currentMacroFase = titleStr;
        }
      }
      skipped++;
      continue; // Not a checklist item
    }

    final deroghe = _cellString(rowCells, 5).trim();
    final noteNorma = _cellString(rowCells, 6).trim();
    final tipologiaControllo = _cellString(rowCells, 7).trim();
    final frequenzaSingolo = _cellString(rowCells, 8).trim();
    final frequenzaAssociato = _cellString(rowCells, 9).trim();
    final gravitaUecText = _cellString(rowCells, 10).trim();
    final esclusioneUecText = _cellString(rowCells, 11).trim();
    final gravitaOperatoreText = _cellString(rowCells, 12).trim();
    final esclusioneOperatoreText = _cellString(rowCells, 13).trim();
    final disposizioniRegionali = _cellString(rowCells, 14).trim();

    final sortOrder = ++sortFallback;

    itemsList.add({
      'code': code,
      'fase': currentMacroFase,
      'obbligo': obbligo,
      'deroghe': deroghe,
      'noteNorma': noteNorma,
      'tipologiaControllo': tipologiaControllo,
      'frequenzaSingolo': frequenzaSingolo,
      'frequenzaAssociato': frequenzaAssociato,
      'gravitaUecText': gravitaUecText,
      'esclusioneUecText': esclusioneUecText,
      'gravitaOperatoreText': gravitaOperatoreText,
      'esclusioneOperatoreText': esclusioneOperatoreText,
      'disposizioniRegionali': disposizioniRegionali,
      'sortOrder': sortOrder,
    });
  }

  return {'items': itemsList, 'skipped': skipped, 'sheetName': sheet.sheetName};
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
