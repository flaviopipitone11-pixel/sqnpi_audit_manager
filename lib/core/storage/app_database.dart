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
  TextColumn get visitType => text().withDefault(
    const Constant('ACA'),
  )(); // ACA, MARCHIO, CAMPIONAMENTO
  IntColumn get durationHours => integer().withDefault(const Constant(0))();
  IntColumn get plannedDurationHours =>
      integer().withDefault(const Constant(0))();
  TextColumn get durationJustification =>
      text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime()();

  /// Nome dell'ispettore che esegue la visita
  TextColumn get inspectorName => text().withDefault(const Constant(''))();

  /// Nome dell'eventuale affiancatore
  TextColumn get companionName => text().withDefault(const Constant(''))();

  /// Nome del rappresentante aziendale o delegato
  TextColumn get representativeName => text().withDefault(const Constant(''))();

  /// Altri operatori presenti
  TextColumn get otherOperators => text().withDefault(const Constant(''))();

  /// Elenco persone contattate
  TextColumn get contactedPersons => text().withDefault(const Constant(''))();

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

  // Sede Operativa
  TextColumn get sedeOperativaIndirizzo =>
      text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaCap => text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaComune =>
      text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaProvincia =>
      text().withDefault(const Constant(''))();

  TextColumn get referente => text().withDefault(const Constant(''))();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get pec => text().withDefault(const Constant(''))();
  TextColumn get submissionNumber => text().withDefault(const Constant(''))();

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
  TextColumn get manipulationSiteCap =>
      text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteComune =>
      text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteProvincia =>
      text().withDefault(const Constant(''))();
  TextColumn get peakPeriodFrom => text().withDefault(const Constant(''))();
  TextColumn get peakPeriodTo => text().withDefault(const Constant(''))();
  BoolColumn get isJointVisit => boolean().withDefault(const Constant(false))();
  TextColumn get jointVisitDetails => text().withDefault(const Constant(''))();

  // Marchio details (M904)
  TextColumn get marchioNature => text().withDefault(const Constant(''))();
  TextColumn get marchioProcesses => text().withDefault(const Constant(''))();
  BoolColumn get marchioLabelDraft =>
      boolean().withDefault(const Constant(false))();
  TextColumn get previousOdcName => text().withDefault(const Constant(''))();
  TextColumn get previousOdcOutcomes =>
      text().withDefault(const Constant(''))();

  // SQNPI details
  DateTimeColumn get sqnpiSubmissionDate => dateTime().nullable()();
  TextColumn get sqnpiProtocol => text().withDefault(const Constant(''))();

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
  TextColumn get nAggregato => text().withDefault(const Constant(''))();
  TextColumn get sqnpiConsistency => text().withDefault(const Constant(''))();
  TextColumn get sqnpiCompliance => text().withDefault(const Constant(''))();
  BoolColumn get isTraceable => boolean().withDefault(const Constant(false))();
  BoolColumn get hasClaims => boolean().withDefault(const Constant(false))();
  BoolColumn get isFieldProcessVerified =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get hasSampling => boolean().withDefault(const Constant(false))();
  TextColumn get samplingLotId => text().nullable()();

  TextColumn get foundProduct => text().nullable()();
  TextColumn get fieldProcessDetails => text().nullable()();

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

  /// Categoria allegato (es. 'reference', 'viewed', 'general')
  TextColumn get category => text().withDefault(const Constant('general'))();

  /// Sottotipo specifico (es. 'DISCIPLINARE', 'REGISTRO_SQNPI', 'ALTRO')
  TextColumn get attachmentType => text().withDefault(const Constant(''))();

  /// Valore extra (es. Regione/Anno per il disciplinare)
  TextColumn get extraValue => text().withDefault(const Constant(''))();

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

  /// Nome di chi firma (se representative o delegate)
  TextColumn get signerName => text().nullable()();

  /// Percorso del documento d'identità di chi firma (se delegato o representative)
  TextColumn get identityDocPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// M904 rev. 08 - Gestione NC Anni Precedenti
class VisitPreviousNcManagements extends Table {
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  /// Esito verifica NC anni precedenti (0: N/A, 1: Favorevole, 2: Non Favorevole)
  IntColumn get prevNcResults => integer().withDefault(const Constant(0))();

  /// Requisiti ancora KO
  TextColumn get prevNcRequirementsStillKO =>
      text().withDefault(const Constant(''))();

  /// Coerenza azioni correttive (0: N/A, 1: Coerente, 2: Non Coerente)
  IntColumn get prevCorrectiveActionsCoherent =>
      integer().withDefault(const Constant(0))();

  /// Dettagli azioni correttive
  TextColumn get prevCorrectiveActionsDetails =>
      text().withDefault(const Constant(''))();

  /// Data in cui l'OdC ha rilasciato la certificazione
  TextColumn get prevOrgCertifiedDate =>
      text().withDefault(const Constant(''))();

  /// Data comunicazione sanzione OdC
  TextColumn get prevOrgSanctionedDate =>
      text().withDefault(const Constant(''))();

  /// Eventuali sanzioni Bios
  TextColumn get biosSanctionDetails =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {visitId};
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

  TextColumn get verifiedProducts => text().nullable()();
  TextColumn get ingressData => text().nullable()();
  TextColumn get ingressDocs => text().nullable()();
  TextColumn get egressData => text().nullable()();
  TextColumn get egressDocs => text().nullable()();
  TextColumn get comment => text().nullable()();

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

  // M904 rev. 08 - Nuovi campi riepilogo
  IntColumn get cap5Adherence =>
      integer().withDefault(const Constant(0))(); // 0: N/A, 1: Sì tutte, 2: No
  TextColumn get cap5SpecificCrops => text().withDefault(const Constant(''))();
  IntColumn get commitmentToRectify =>
      integer().withDefault(const Constant(0))(); // 0: N/A, 1: Sì, 2: No
  TextColumn get inspectionMethods =>
      text().withDefault(const Constant('[]'))(); // JSON list
  IntColumn get representativePresent =>
      integer().withDefault(const Constant(0))(); // 0: N/A, 1: Sì, 2: No
  BoolColumn get isOutcomeFormalized =>
      boolean().withDefault(const Constant(false))();
  TextColumn get verificationNotes => text().withDefault(const Constant(''))();

  // Final Evaluation (M904 Rev. 08 - Official Document)
  IntColumn get finalOutcome => integer().withDefault(
    const Constant(0),
  )(); // 0: N/A, 1: Conforme, 2: Proposta provvedimento
  TextColumn get provisionDetail => text().withDefault(const Constant(''))();
  TextColumn get representativeReservations =>
      text().withDefault(const Constant(''))();

  // Legacy Final Evaluation fields (kept for migration compatibility)
  IntColumn get finalRecommendation =>
      integer().withDefault(const Constant(0))();
  TextColumn get inspectorFinalComment =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {visitId};
}

/// M904 rev. 08 - Anagrafica Ispettori
class Inspectors extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get region => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class MasterCompanies extends Table {
  TextColumn get cuaa => text()();
  TextColumn get ragioneSociale => text().withDefault(const Constant(''))();
  TextColumn get partitaIva => text().withDefault(const Constant(''))();
  TextColumn get indirizzo => text().withDefault(const Constant(''))();
  TextColumn get cap => text().withDefault(const Constant(''))();
  TextColumn get comune => text().withDefault(const Constant(''))();
  TextColumn get provincia => text().withDefault(const Constant(''))();

  // Sede Operativa
  TextColumn get sedeOperativaIndirizzo =>
      text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaCap => text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaComune =>
      text().withDefault(const Constant(''))();
  TextColumn get sedeOperativaProvincia =>
      text().withDefault(const Constant(''))();

  // Sede di Manipolazione
  TextColumn get manipulationSiteAddress =>
      text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteCap =>
      text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteComune =>
      text().withDefault(const Constant(''))();
  TextColumn get manipulationSiteProvincia =>
      text().withDefault(const Constant(''))();

  TextColumn get referente => text().withDefault(const Constant(''))();
  TextColumn get telefono => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get pec => text().withDefault(const Constant(''))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cuaa};
}

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // e.g., 'IMPORT_EXCEL', 'ADD_INSPECTOR'
  TextColumn get description => text()();
  TextColumn get actor => text()(); // 'Admin'
  DateTimeColumn get createdAt => dateTime()();
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

  /// Nuovi campi M904 Rev. 08
  TextColumn get producerName => text().withDefault(const Constant(''))();
  TextColumn get producerCode => text().withDefault(const Constant(''))();
  TextColumn get lotNumberGeoref => text().withDefault(const Constant(''))();
  DateTimeColumn get inspectionDate => dateTime().nullable()();
  TextColumn get inspectorName => text().withDefault(const Constant(''))();
  TextColumn get inspectorCode => text().withDefault(const Constant(''))();

  /// Elenco percorsi foto (separati da virgola) - Minimo 3 per prelievo
  TextColumn get photoPaths => text().withDefault(const Constant(''))();

  /// Percorso del verbale di prelievo (legacy)
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Documenti giustificativi del Bilancio di Massa
class MassBalanceDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  /// Tipo documento: 'entrata' (fatture acquisto) o 'uscita' (quaderno campagna, DDT)
  TextColumn get docType => text()(); // 'entrata' | 'uscita'

  /// Percorso file sul filesystem
  TextColumn get filePath => text()();

  /// Nome originale del file
  TextColumn get fileName => text().withDefault(const Constant(''))();

  /// Descrizione / didascalia opzionale
  TextColumn get caption => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// M904 rev. 08 - Fase di Post Raccolta
class PostHarvestRecords extends Table {
  TextColumn get id => text()(); // PH-<visitId>
  TextColumn get visitId => text().customConstraint(
    'NOT NULL REFERENCES visits(id) ON DELETE CASCADE',
  )();

  TextColumn get phases =>
      text().withDefault(const Constant('[]'))(); // JSON lista di fasi

  // Bilancio di massa
  TextColumn get mbVerifiedProducts => text().withDefault(const Constant(''))();
  TextColumn get mbInputData => text().withDefault(const Constant(''))();
  TextColumn get mbInputDocs => text().withDefault(const Constant(''))();
  TextColumn get mbOutputData => text().withDefault(const Constant(''))();
  TextColumn get mbOutputDocs => text().withDefault(const Constant(''))();
  TextColumn get mbComment => text().withDefault(const Constant(''))();
  TextColumn get mbBalances =>
      text().withDefault(const Constant('[]'))(); // JSON lista bilanci post-harvest

  // Rintracciabilità
  TextColumn get traceabilityVerifiedProducts =>
      text().withDefault(const Constant(''))();

  DateTimeColumn get updatedAt => dateTime()();

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
    MassBalanceDocuments,
    Inspectors,
    ActivityLogs,
    MasterCompanies,
    VisitPreviousNcManagements,
    PostHarvestRecords,
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
  int get schemaVersion => 46;

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
      if (from < 19) {
        // Aggiunta delle colonne per la gestione durata programmata e giustificativo.
        // In fase di sviluppo, queste colonne potrebbero già esistere se il database
        // è stato creato dopo l'aggiunta delle colonne alla classe Visits ma prima del bump di schemaVersion.
        try {
          await m.addColumn(visits, visits.plannedDurationHours);
        } catch (_) {}
        try {
          await m.addColumn(visits, visits.durationJustification);
        } catch (_) {}
        try {
          await m.addColumn(visits, visits.updatedAt);
        } catch (_) {}

        // Forza l'aggiornamento per evitare null check errors nel mapper di Drift
        await customStatement(
          "UPDATE visits SET planned_duration_hours = COALESCE(duration_hours, 0) WHERE planned_duration_hours IS NULL;",
        );
        await customStatement(
          "UPDATE visits SET duration_justification = '' WHERE duration_justification IS NULL;",
        );
        await customStatement(
          "UPDATE visits SET updated_at = '${DateTime.now().toIso8601String()}' WHERE updated_at IS NULL;",
        );
      }
      if (from < 20) {
        try {
          await m.addColumn(visitCompanies, visitCompanies.submissionNumber);
        } catch (_) {}
        await customStatement(
          "UPDATE visit_companies SET submission_number = '' WHERE submission_number IS NULL;",
        );
      }
      if (from < 21) {
        await m.createTable(massBalanceDocuments);
      }
      if (from < 22) {
        try {
          await m.addColumn(visits, visits.inspectorName);
        } catch (_) {}
        try {
          await m.addColumn(visits, visits.companionName);
        } catch (_) {}
        try {
          await m.addColumn(visits, visits.representativeName);
        } catch (_) {}
        await customStatement(
          "UPDATE visits SET inspector_name = '' WHERE inspector_name IS NULL;",
        );
        await customStatement(
          "UPDATE visits SET companion_name = '' WHERE companion_name IS NULL;",
        );
        await customStatement(
          "UPDATE visits SET representative_name = '' WHERE representative_name IS NULL;",
        );
      }
      if (from < 23) {
        try {
          await m.addColumn(visitSignatures, visitSignatures.identityDocPath);
        } catch (_) {}
      }
      if (from < 24) {
        await m.createTable(inspectors);
      }
      if (from < 25) {
        await m.createTable(activityLogs);
      }
      if (from < 26) {
        await m.addColumn(inspectors, inspectors.region);
      }
      if (from < 27) {
        await m.createTable(masterCompanies);
      }
      if (from < 28) {
        try {
          await m.addColumn(visitCompanies, visitCompanies.pec);
        } catch (_) {}
        try {
          await m.addColumn(masterCompanies, masterCompanies.pec);
        } catch (_) {}
        await customStatement(
          "UPDATE master_companies SET pec = '' WHERE master_companies.pec IS NULL;",
        );
      }
      if (from < 29) {
        try {
          await m.addColumn(visitCompanies, visitCompanies.marchioNature);
          await m.addColumn(visitCompanies, visitCompanies.marchioProcesses);
          await m.addColumn(visitCompanies, visitCompanies.marchioLabelDraft);
        } catch (_) {}
        await customStatement(
          "UPDATE visit_companies SET marchio_nature = '' WHERE marchio_nature IS NULL;",
        );
        await customStatement(
          "UPDATE visit_companies SET marchio_processes = '' WHERE marchio_processes IS NULL;",
        );
        await customStatement(
          "UPDATE visit_companies SET marchio_label_draft = 0 WHERE marchio_label_draft IS NULL;",
        );
      }
      if (from < 30) {
        try {
          await m.addColumn(visits, visits.otherOperators);
        } catch (_) {}
        await customStatement(
          "UPDATE visits SET other_operators = '' WHERE other_operators IS NULL;",
        );
      }
      if (from < 31) {
        try {
          await m.addColumn(visitCompanies, visitCompanies.previousOdcName);
          await m.addColumn(visitCompanies, visitCompanies.previousOdcOutcomes);
        } catch (_) {}
        await customStatement(
          "UPDATE visit_companies SET previous_odc_outcomes = '' WHERE previous_odc_outcomes IS NULL;",
        );
      }
      if (from < 32) {
        try {
          await m.addColumn(visits, visits.contactedPersons);
        } catch (_) {}
        await customStatement(
          "UPDATE visits SET contacted_persons = '' WHERE contacted_persons IS NULL;",
        );
      }
      if (from < 33) {
        await m.addColumn(visitAttachments, visitAttachments.category);
        await m.addColumn(visitAttachments, visitAttachments.attachmentType);
        await m.addColumn(visitAttachments, visitAttachments.extraValue);

        await customStatement(
          "UPDATE visit_attachments SET category = 'general' WHERE category IS NULL;",
        );
        await customStatement(
          "UPDATE visit_attachments SET attachment_type = '' WHERE attachment_type IS NULL;",
        );
        await customStatement(
          "UPDATE visit_attachments SET extra_value = '' WHERE extra_value IS NULL;",
        );
      }
      if (from < 34) {
        await m.addColumn(visitUecs, visitUecs.nAggregato);
      }
      if (from < 35) {
        await m.addColumn(visitSamples, visitSamples.producerName);
        await m.addColumn(visitSamples, visitSamples.producerCode);
        await m.addColumn(visitSamples, visitSamples.lotNumberGeoref);
        await m.addColumn(visitSamples, visitSamples.inspectionDate);
        await m.addColumn(visitSamples, visitSamples.inspectorName);
        await m.addColumn(visitSamples, visitSamples.inspectorCode);
        await m.addColumn(visitSamples, visitSamples.photoPaths);
      }
      if (from < 36) {
        await m.addColumn(visitUecs, visitUecs.sqnpiConsistency);
        await m.addColumn(visitUecs, visitUecs.sqnpiCompliance);
        await m.addColumn(visitUecs, visitUecs.isTraceable);
        await m.addColumn(visitUecs, visitUecs.hasClaims);
        await m.addColumn(visitUecs, visitUecs.isFieldProcessVerified);
        await m.addColumn(visitUecs, visitUecs.hasSampling);
        await m.addColumn(visitUecs, visitUecs.samplingLotId);

        await customStatement(
          "UPDATE visit_uecs SET sqnpi_consistency = '' WHERE sqnpi_consistency IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET sqnpi_compliance = '' WHERE sqnpi_compliance IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET is_traceable = 0 WHERE is_traceable IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET has_claims = 0 WHERE has_claims IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET is_field_process_verified = 0 WHERE is_field_process_verified IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET has_sampling = 0 WHERE has_sampling IS NULL;",
        );
      }
      if (from < 37) {
        await m.addColumn(visitCompanies, visitCompanies.sqnpiSubmissionDate);
        await m.addColumn(visitCompanies, visitCompanies.sqnpiProtocol);

        await customStatement(
          "UPDATE visit_companies SET sqnpi_protocol = '' WHERE sqnpi_protocol IS NULL;",
        );
      }
      if (from < 38) {
        // No structural changes, but we now allow empty filePath in app logic.
      }
      if (from < 39) {
        await m.createTable(visitPreviousNcManagements);
      }
      if (from < 40) {
        await m.addColumn(
          visitCompanies,
          visitCompanies.sedeOperativaIndirizzo,
        );
        await m.addColumn(visitCompanies, visitCompanies.sedeOperativaCap);
        await m.addColumn(visitCompanies, visitCompanies.sedeOperativaComune);
        await m.addColumn(
          visitCompanies,
          visitCompanies.sedeOperativaProvincia,
        );

        await m.addColumn(
          masterCompanies,
          masterCompanies.sedeOperativaIndirizzo,
        );
        await m.addColumn(masterCompanies, masterCompanies.sedeOperativaCap);
        await m.addColumn(masterCompanies, masterCompanies.sedeOperativaComune);
        await m.addColumn(
          masterCompanies,
          masterCompanies.sedeOperativaProvincia,
        );
      }
      if (from < 41) {
        await m.addColumn(visitCompanies, visitCompanies.manipulationSiteCap);
        await m.addColumn(
          visitCompanies,
          visitCompanies.manipulationSiteComune,
        );
        await m.addColumn(
          visitCompanies,
          visitCompanies.manipulationSiteProvincia,
        );

        await m.addColumn(
          masterCompanies,
          masterCompanies.manipulationSiteAddress,
        );
        await m.addColumn(masterCompanies, masterCompanies.manipulationSiteCap);
        await m.addColumn(
          masterCompanies,
          masterCompanies.manipulationSiteComune,
        );
        await m.addColumn(
          masterCompanies,
          masterCompanies.manipulationSiteProvincia,
        );
      }
      if (from < 42) {
        await m.createTable(postHarvestRecords);
      }
      if (from < 43) {
        await m.addColumn(visitClosings, visitClosings.cap5Adherence);
        await m.addColumn(visitClosings, visitClosings.cap5SpecificCrops);
        await m.addColumn(visitClosings, visitClosings.commitmentToRectify);
        await m.addColumn(visitClosings, visitClosings.inspectionMethods);
        await m.addColumn(visitClosings, visitClosings.representativePresent);
        await m.addColumn(visitClosings, visitClosings.isOutcomeFormalized);
        await m.addColumn(visitClosings, visitClosings.verificationNotes);
      }
      if (from < 44) {
        await m.addColumn(visitClosings, visitClosings.finalRecommendation);
        await m.addColumn(visitClosings, visitClosings.inspectorFinalComment);
      }
      if (from < 45) {
        await m.addColumn(visitClosings, visitClosings.finalOutcome);
        await m.addColumn(visitClosings, visitClosings.provisionDetail);
        await m.addColumn(
          visitClosings,
          visitClosings.representativeReservations,
        );
      }
      if (from < 46) {
        // Missing columns in visit_uecs added after v36 but omitted from onUpgrade
        try {
          await m.addColumn(visitUecs, visitUecs.foundProduct);
        } catch (_) {}
        try {
          await m.addColumn(visitUecs, visitUecs.fieldProcessDetails);
        } catch (_) {}

        // Missing column in post_harvest_records added after v42
        try {
          await m.addColumn(postHarvestRecords, postHarvestRecords.mbBalances);
        } catch (_) {}

        // Ensure non-null defaults for new columns to avoid mapper crashes
        await customStatement(
          "UPDATE visit_uecs SET found_product = '' WHERE found_product IS NULL;",
        );
        await customStatement(
          "UPDATE visit_uecs SET field_process_details = '' WHERE field_process_details IS NULL;",
        );
        await customStatement(
          "UPDATE post_harvest_records SET mb_balances = '[]' WHERE mb_balances IS NULL;",
        );
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

  Stream<List<Visit>> watchVisitsByCuaa(String cuaa) {
    final query = select(visits).join([
      innerJoin(visitCompanies, visitCompanies.visitId.equalsExp(visits.id)),
    ]);
    query.where(visitCompanies.cuaa.equals(cuaa));
    query.orderBy([OrderingTerm.desc(visits.scheduledAt)]);

    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(visits)).toList(),
    );
  }

  Future<void> upsertVisit({
    required String id,
    required DateTime scheduledAt,
    required String companyName,
    required String crop,
    required VisitStatus status,
    String visitType = 'ACA',
    int durationHours = 0,
    int plannedDurationHours = 0,
    String durationJustification = '',
    String inspectorName = '',
    String companionName = '',
    String representativeName = '',
    String otherOperators = '',
    String contactedPersons = '',
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
        plannedDurationHours: Value(plannedDurationHours),
        durationJustification: Value(durationJustification),
        inspectorName: Value(inspectorName),
        companionName: Value(companionName),
        representativeName: Value(representativeName),
        otherOperators: Value(otherOperators),
        contactedPersons: Value(contactedPersons),
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
    double? latitude,
    double? longitude,
    String? latitudeText,
    String? longitudeText,
    String? manipulationSiteAddress,
    String? peakPeriodFrom,
    String? peakPeriodTo,
    bool? isJointVisit,
    String? jointVisitDetails,
    bool? isNewOperator,
    String? processingType,
    String? thirdPartyCertNumber,
    bool? siVerification,
    String? submissionNumber,
    String? marchioNature,
    String? marchioProcesses,
    bool? marchioLabelDraft,
    String? previousOdcName,
    String? previousOdcOutcomes,
    DateTime? sqnpiSubmissionDate,
    String? sqnpiProtocol,
    String? sedeOperativaIndirizzo,
    String? sedeOperativaCap,
    String? sedeOperativaComune,
    String? sedeOperativaProvincia,
    String? manipulationSiteCap,
    String? manipulationSiteComune,
    String? manipulationSiteProvincia,
  }) async {
    await into(visitCompanies).insertOnConflictUpdate(
      VisitCompaniesCompanion.insert(
        visitId: visitId,
        ragioneSociale: Value.absentIfNull(ragioneSociale),
        cuaa: Value.absentIfNull(cuaa),
        partitaIva: Value.absentIfNull(partitaIva),
        indirizzo: Value.absentIfNull(indirizzo),
        cap: Value.absentIfNull(cap),
        comune: Value.absentIfNull(comune),
        provincia: Value.absentIfNull(provincia),
        referente: Value.absentIfNull(referente),
        telefono: Value.absentIfNull(telefono),
        email: Value.absentIfNull(email),
        pec: Value.absentIfNull(pec),
        latitude: Value.absentIfNull(latitude),
        longitude: Value.absentIfNull(longitude),
        latitudeText: Value.absentIfNull(latitudeText),
        longitudeText: Value.absentIfNull(longitudeText),
        manipulationSiteAddress: Value.absentIfNull(manipulationSiteAddress),
        sqnpiSubmissionDate: Value.absentIfNull(sqnpiSubmissionDate),
        sqnpiProtocol: Value.absentIfNull(sqnpiProtocol),
        peakPeriodFrom: Value.absentIfNull(peakPeriodFrom),
        peakPeriodTo: Value.absentIfNull(peakPeriodTo),
        isJointVisit: Value.absentIfNull(isJointVisit),
        jointVisitDetails: Value.absentIfNull(jointVisitDetails),
        isNewOperator: Value.absentIfNull(isNewOperator),
        processingType: Value.absentIfNull(processingType),
        thirdPartyCertNumber: Value.absentIfNull(thirdPartyCertNumber),
        siVerification: Value.absentIfNull(siVerification),
        submissionNumber: Value.absentIfNull(submissionNumber),
        marchioNature: Value.absentIfNull(marchioNature),
        marchioProcesses: Value.absentIfNull(marchioProcesses),
        marchioLabelDraft: Value.absentIfNull(marchioLabelDraft),
        previousOdcName: Value.absentIfNull(previousOdcName),
        previousOdcOutcomes: Value.absentIfNull(previousOdcOutcomes),
        sedeOperativaIndirizzo: Value.absentIfNull(sedeOperativaIndirizzo),
        sedeOperativaCap: Value.absentIfNull(sedeOperativaCap),
        sedeOperativaComune: Value.absentIfNull(sedeOperativaComune),
        sedeOperativaProvincia: Value.absentIfNull(sedeOperativaProvincia),
        manipulationSiteCap: Value.absentIfNull(manipulationSiteCap),
        manipulationSiteComune: Value.absentIfNull(manipulationSiteComune),
        manipulationSiteProvincia: Value.absentIfNull(
          manipulationSiteProvincia,
        ),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> upsertMasterCompany({
    required String cuaa,
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
    String? sedeOperativaIndirizzo,
    String? sedeOperativaCap,
    String? sedeOperativaComune,
    String? sedeOperativaProvincia,
    String? manipulationSiteAddress,
    String? manipulationSiteCap,
    String? manipulationSiteComune,
    String? manipulationSiteProvincia,
  }) async {
    await into(masterCompanies).insertOnConflictUpdate(
      MasterCompaniesCompanion.insert(
        cuaa: cuaa,
        ragioneSociale: Value.absentIfNull(ragioneSociale),
        partitaIva: Value.absentIfNull(partitaIva),
        indirizzo: Value.absentIfNull(indirizzo),
        cap: Value.absentIfNull(cap),
        comune: Value.absentIfNull(comune),
        provincia: Value.absentIfNull(provincia),
        referente: Value.absentIfNull(referente),
        telefono: Value.absentIfNull(telefono),
        email: Value.absentIfNull(email),
        pec: Value.absentIfNull(pec),
        sedeOperativaIndirizzo: Value.absentIfNull(sedeOperativaIndirizzo),
        sedeOperativaCap: Value.absentIfNull(sedeOperativaCap),
        sedeOperativaComune: Value.absentIfNull(sedeOperativaComune),
        sedeOperativaProvincia: Value.absentIfNull(sedeOperativaProvincia),
        manipulationSiteAddress: Value.absentIfNull(manipulationSiteAddress),
        manipulationSiteCap: Value.absentIfNull(manipulationSiteCap),
        manipulationSiteComune: Value.absentIfNull(manipulationSiteComune),
        manipulationSiteProvincia: Value.absentIfNull(
          manipulationSiteProvincia,
        ),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// -------------------------
  /// M904 COMPLIANCE: BILANCIO E CHIUSURA
  /// -------------------------

  Stream<MassBalanceRecord?> watchMassBalanceByVisitId(String visitId) {
    return (select(
      massBalanceRecords,
    )..where((t) => t.visitId.equals(visitId))).watchSingleOrNull();
  }

  Stream<List<MassBalanceRecord>> watchMassBalancesByVisitId(String visitId) {
    return (select(massBalanceRecords)
          ..where((t) => t.visitId.equals(visitId))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .watch();
  }

  Future<void> upsertMassBalance({
    String? id,
    required String visitId,
    String? substances,
    double? purchased,
    double? used,
    double? stock,
    double? discrepancy,
    String? referenceDocuments,
    String? verifiedProducts,
    String? ingressData,
    String? ingressDocs,
    String? egressData,
    String? egressDocs,
    String? comment,
  }) async {
    final effectiveId =
        id ?? 'MB-$visitId-${DateTime.now().millisecondsSinceEpoch}';
    await into(massBalanceRecords).insertOnConflictUpdate(
      MassBalanceRecordsCompanion(
        id: Value(effectiveId),
        visitId: Value(visitId),
        substances: Value.absentIfNull(substances),
        purchased: Value.absentIfNull(purchased),
        used: Value.absentIfNull(used),
        stock: Value.absentIfNull(stock),
        discrepancy: Value.absentIfNull(discrepancy),
        referenceDocuments: Value.absentIfNull(referenceDocuments),
        verifiedProducts: Value.absentIfNull(verifiedProducts),
        ingressData: Value.absentIfNull(ingressData),
        ingressDocs: Value.absentIfNull(ingressDocs),
        egressData: Value.absentIfNull(egressData),
        egressDocs: Value.absentIfNull(egressDocs),
        comment: Value.absentIfNull(comment),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteMassBalance(String id) async {
    await (delete(massBalanceRecords)..where((t) => t.id.equals(id))).go();
  }

  /// ---- DOCUMENTI GIUSTIFICATIVI BILANCIO DI MASSA ----

  Stream<List<MassBalanceDocument>> watchMassBalanceDocsByVisitId(
    String visitId,
  ) {
    return (select(massBalanceDocuments)
          ..where((t) => t.visitId.equals(visitId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<MassBalanceDocument>> watchMassBalanceDocsByType(
    String visitId,
    String docType,
  ) {
    return (select(massBalanceDocuments)
          ..where((t) => t.visitId.equals(visitId) & t.docType.equals(docType))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> insertMassBalanceDoc({
    required String visitId,
    required String docType,
    required String filePath,
    required String fileName,
    String caption = '',
  }) async {
    final id = 'MBD-$visitId-${DateTime.now().microsecondsSinceEpoch}';
    await into(massBalanceDocuments).insert(
      MassBalanceDocumentsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        docType: Value(docType),
        filePath: Value(filePath),
        fileName: Value(fileName),
        caption: Value(caption),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteMassBalanceDoc(String id) async {
    return (delete(massBalanceDocuments)..where((t) => t.id.equals(id))).go();
  }

  Stream<VisitClosing?> watchClosingByVisitId(String visitId) {
    return (select(
      visitClosings,
    )..where((t) => t.visitId.equals(visitId))).watchSingleOrNull();
  }

  Future<void> upsertClosing({
    required String visitId,
    required String correctiveActions,
    required DateTime? resolutionDeadline,
    required bool isClosed,
    int? cap5Adherence,
    String? cap5SpecificCrops,
    int? commitmentToRectify,
    String? inspectionMethods,
    int? representativePresent,
    bool? isOutcomeFormalized,
    String? verificationNotes,
    int? finalRecommendation,
    String? inspectorFinalComment,
    int? finalOutcome,
    String? provisionDetail,
    String? representativeReservations,
  }) async {
    await into(visitClosings).insertOnConflictUpdate(
      VisitClosingsCompanion(
        visitId: Value(visitId),
        correctiveActions: Value(correctiveActions),
        resolutionDeadline: Value(resolutionDeadline),
        isClosed: Value(isClosed),
        cap5Adherence: Value.absentIfNull(cap5Adherence),
        cap5SpecificCrops: Value.absentIfNull(cap5SpecificCrops),
        commitmentToRectify: Value.absentIfNull(commitmentToRectify),
        inspectionMethods: Value.absentIfNull(inspectionMethods),
        representativePresent: Value.absentIfNull(representativePresent),
        isOutcomeFormalized: Value.absentIfNull(isOutcomeFormalized),
        verificationNotes: Value.absentIfNull(verificationNotes),
        finalRecommendation: Value.absentIfNull(finalRecommendation),
        inspectorFinalComment: Value.absentIfNull(inspectorFinalComment),
        finalOutcome: Value.absentIfNull(finalOutcome),
        provisionDetail: Value.absentIfNull(provisionDetail),
        representativeReservations: Value.absentIfNull(
          representativeReservations,
        ),
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
  /// COLTURA e UEC
  /// -------------------------

  Stream<List<VisitUec>> watchUecsByVisitId(String visitId) {
    return (select(visitUecs)..where((t) => t.visitId.equals(visitId))).watch();
  }

  Future<void> upsertUec({
    required String id,
    required String visitId,
    required String coltura,
    required String descrizione,
    required String nAggregato,
    required String note,
    double? latitude,
    double? longitude,
    String? photoPath,
    String? sqnpiConsistency,
    String? sqnpiCompliance,
    bool? isTraceable,
    bool? hasClaims,
    bool? isFieldProcessVerified,
    bool? hasSampling,
    String? samplingLotId,
    String? foundProduct,
    String? fieldProcessDetails,
  }) async {
    await into(visitUecs).insertOnConflictUpdate(
      VisitUecsCompanion(
        id: Value(id),
        visitId: Value(visitId),
        coltura: Value(coltura),
        descrizione: Value(descrizione),
        nAggregato: Value(nAggregato),
        note: Value(note),
        latitude: Value(latitude),
        longitude: Value(longitude),
        photoPath: Value(photoPath),
        sqnpiConsistency: Value.absentIfNull(sqnpiConsistency),
        sqnpiCompliance: Value.absentIfNull(sqnpiCompliance),
        isTraceable: Value.absentIfNull(isTraceable),
        hasClaims: Value.absentIfNull(hasClaims),
        isFieldProcessVerified: Value.absentIfNull(isFieldProcessVerified),
        hasSampling: Value.absentIfNull(hasSampling),
        samplingLotId: Value.absentIfNull(samplingLotId),
        foundProduct: Value.absentIfNull(foundProduct),
        fieldProcessDetails: Value.absentIfNull(fieldProcessDetails),
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
    final query = select(
      visitLots,
    ).join([innerJoin(visitUecs, visitUecs.id.equalsExp(visitLots.uecId))]);
    query.where(visitUecs.visitId.equals(visitId));
    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(visitLots)).toList(),
    );
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

  Future<void> deleteResponse(String uecId, String itemCode) async {
    final id = 'RESP-$uecId-$itemCode';
    await (delete(checklistResponses)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteAllResponsesByVisit(String visitId) async {
    await transaction(() async {
      final query = selectOnly(visitUecs)
        ..addColumns([visitUecs.id])
        ..where(visitUecs.visitId.equals(visitId));
      final rows = await query.get();
      final ids = rows.map((r) => r.read(visitUecs.id)!).toList();

      if (ids.isNotEmpty) {
        await (delete(
          checklistResponses,
        )..where((t) => t.uecId.isIn(ids))).go();
      }
    });
  }

  Stream<List<ChecklistResponse>> watchResponsesByVisitId(String visitId) {
    final query = select(checklistResponses).join([
      innerJoin(visitUecs, visitUecs.id.equalsExp(checklistResponses.uecId)),
    ])..where(visitUecs.visitId.equals(visitId));

    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(checklistResponses)).toList(),
    );
  }

  Stream<List<ChecklistResponse>> watchResponsesByUecId(String uecId) {
    return (select(
      checklistResponses,
    )..where((t) => t.uecId.equals(uecId))).watch();
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

  Stream<List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>>
  watchAllChecklistResponsesForVisit(String visitId) {
    final query = select(checklistResponses).join([
      innerJoin(
        checklistItems,
        checklistItems.code.equalsExp(checklistResponses.itemCode),
      ),
      innerJoin(visitUecs, visitUecs.id.equalsExp(checklistResponses.uecId)),
    ])..where(visitUecs.visitId.equals(visitId));

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

  Stream<List<ChecklistResponse>> watchResponsesByVisitAndItem(
    String visitId,
    String itemCode,
  ) {
    final query =
        select(checklistResponses).join([
            innerJoin(
              visitUecs,
              visitUecs.id.equalsExp(checklistResponses.uecId),
            ),
          ])
          ..where(visitUecs.visitId.equals(visitId))
          ..where(checklistResponses.itemCode.equals(itemCode));

    return query.watch().map(
      (rows) => rows.map((r) => r.readTable(checklistResponses)).toList(),
    );
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

      final row = rows.first;

      final sumOperatoreTotale = row.read<int?>('sum_operatore_tot') ?? 0;
      final maxSommaUec = row.read<int?>('max_sum_uec') ?? 0;
      final uecOverSoglia = row.read<int?>('uec_over_soglia') ?? 0;

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
    String filePath = '',
    String caption = '',
    String? uecId,
    String? checklistCode,
    double? latitude,
    double? longitude,
    String category = 'general',
    String attachmentType = '',
    String extraValue = '',
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
        category: Value(category),
        attachmentType: Value(attachmentType),
        extraValue: Value(extraValue),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteAttachment(String id) async {
    return (delete(visitAttachments)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateAttachmentExtra({
    required String id,
    required String extraValue,
  }) async {
    return (update(visitAttachments)..where((t) => t.id.equals(id))).write(
      VisitAttachmentsCompanion(extraValue: Value(extraValue)),
    );
  }

  Future<int> updateAttachmentFile({
    required String id,
    required String filePath,
  }) async {
    return (update(visitAttachments)..where((t) => t.id.equals(id))).write(
      VisitAttachmentsCompanion(filePath: Value(filePath)),
    );
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
    String? identityDocPath,
  }) async {
    final id = 'SIG-$visitId-$signatureType';
    await into(visitSignatures).insertOnConflictUpdate(
      VisitSignaturesCompanion(
        id: Value(id),
        visitId: Value(visitId),
        signatureType: Value(signatureType),
        filePath: Value(filePath),
        signerName: Value(signerName),
        identityDocPath: Value(identityDocPath),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateSignatureIdentityDoc(
    String signatureId,
    String? docPath,
  ) async {
    await (update(visitSignatures)..where((t) => t.id.equals(signatureId)))
        .write(VisitSignaturesCompanion(identityDocPath: Value(docPath)));
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
    return (select(
      visitSamples,
    )..where((t) => t.visitId.equals(visitId))).watch();
  }

  Future<void> upsertSample({
    required String id,
    required String visitId,
    String sampleCode = '',
    String matrixType = '',
    String sealNumber = '',
    String producerName = '',
    String producerCode = '',
    String lotNumberGeoref = '',
    DateTime? inspectionDate,
    String inspectorName = '',
    String inspectorCode = '',
    String photoPaths = '',
    String? photoPath,
  }) async {
    await into(visitSamples).insertOnConflictUpdate(
      VisitSamplesCompanion.insert(
        id: id,
        visitId: visitId,
        sampleCode: Value(sampleCode),
        matrixType: Value(matrixType),
        sealNumber: Value(sealNumber),
        producerName: Value(producerName),
        producerCode: Value(producerCode),
        lotNumberGeoref: Value(lotNumberGeoref),
        inspectionDate: Value(inspectionDate),
        inspectorName: Value(inspectorName),
        inspectorCode: Value(inspectorCode),
        photoPaths: Value(photoPaths),
        photoPath: Value(photoPath),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> deleteSample(String id) async {
    return (delete(visitSamples)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Gestione NC Anni Precedenti
  // ---------------------------------------------------------------------------

  Stream<VisitPreviousNcManagement?> watchPreviousNcManagementByVisitId(
    String visitId,
  ) {
    return (select(
      visitPreviousNcManagements,
    )..where((t) => t.visitId.equals(visitId))).watchSingleOrNull();
  }

  Future<void> upsertPreviousNcManagement({
    required String visitId,
    required int prevNcResults,
    required String prevNcRequirementsStillKO,
    required int prevCorrectiveActionsCoherent,
    required String prevCorrectiveActionsDetails,
    required String prevOrgCertifiedDate,
    required String prevOrgSanctionedDate,
    required String biosSanctionDetails,
  }) async {
    await into(visitPreviousNcManagements).insertOnConflictUpdate(
      VisitPreviousNcManagementsCompanion.insert(
        visitId: visitId,
        prevNcResults: Value(prevNcResults),
        prevNcRequirementsStillKO: Value(prevNcRequirementsStillKO),
        prevCorrectiveActionsCoherent: Value(prevCorrectiveActionsCoherent),
        prevCorrectiveActionsDetails: Value(prevCorrectiveActionsDetails),
        prevOrgCertifiedDate: Value(prevOrgCertifiedDate),
        prevOrgSanctionedDate: Value(prevOrgSanctionedDate),
        biosSanctionDetails: Value(biosSanctionDetails),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Stream<PostHarvestRecord?> watchPostHarvestByVisitId(String visitId) {
    return (select(
      postHarvestRecords,
    )..where((t) => t.visitId.equals(visitId))).watchSingleOrNull();
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
        if (obbligo.isNotEmpty &&
            obbligo != existingObbligo &&
            !obbligo.startsWith('Requisito')) {
          if (existingObbligo.startsWith('Requisito')) {
            obbligo = obbligo;
          } else {
            obbligo = '$existingObbligo $obbligo';
          }
        } else {
          obbligo = existingObbligo.isNotEmpty ? existingObbligo : obbligo;
        }
        if (indicatorType.isEmpty) {
          indicatorType = (existing['indicatorType'] as String?) ?? '';
        }
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
        'noteNorma': noteNorma.isNotEmpty
            ? noteNorma
            : (existing?['noteNorma'] ?? ''),
        'colGText': colGText.isNotEmpty
            ? colGText
            : (existing?['colGText'] ?? ''),
        'tipologiaControllo': tipologiaControllo.isNotEmpty
            ? tipologiaControllo
            : (existing?['tipologiaControllo'] ?? ''),
        'frequenzaSingolo': frequenzaSingolo.isNotEmpty
            ? frequenzaSingolo
            : (existing?['frequenzaSingolo'] ?? ''),
        'frequenzaAssociato': frequenzaAssociato.isNotEmpty
            ? frequenzaAssociato
            : (existing?['frequenzaAssociato'] ?? ''),
        'gravitaUecText': gravitaUecText.isNotEmpty
            ? gravitaUecText
            : (existing?['gravitaUecText'] ?? ''),
        'esclusioneUecText': esclusioneUecText.isNotEmpty
            ? esclusioneUecText
            : (existing?['esclusioneUecText'] ?? ''),
        'gravitaOperatoreText': gravitaOperatoreText.isNotEmpty
            ? gravitaOperatoreText
            : (existing?['gravitaOperatoreText'] ?? ''),
        'esclusioneOperatoreText': esclusioneOperatoreText.isNotEmpty
            ? esclusioneOperatoreText
            : (existing?['esclusioneOperatoreText'] ?? ''),
        'disposizioniRegionali': disposizioniRegionali.isNotEmpty
            ? disposizioniRegionali
            : (existing?['disposizioniRegionali'] ?? ''),
        'esclusioneLottoText': esclusioneUecText.isNotEmpty
            ? esclusioneUecText
            : (existing?['esclusioneLottoText'] ?? ''),
        'hasEsclusioneLotto':
            (existing?['hasEsclusioneLotto'] as bool? ?? false) ||
            hasEsclusioneLotto,
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
