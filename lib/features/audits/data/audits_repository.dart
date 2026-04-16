import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;

import '../domain/visit_with_company.dart';
import '../../auth/presentation/auth_controller.dart';

final auditsRepositoryProvider = Provider<AuditsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AuditsRepository(db);
});

final visitsWithCompanyProvider =
    StreamProvider.autoDispose<List<VisitWithCompany>>((ref) {
      final auth = ref.watch(authControllerProvider);

      if (!auth.isAuthenticated) {
        return Stream.value([]);
      }

      final repo = ref.watch(auditsRepositoryProvider);

      return repo.watchVisitsWithCompanies(inspectorName: null);
    });

class AuditsRepository {
  AuditsRepository(this._db);

  final AppDatabase _db;

  Future<void> saveChecklistResponsesForUecs({
    required List<String> uecIds,
    required String itemCode,
    required Conformita conformita,
    required int? livelloKo,
    required int? punteggioUec,
    required int? punteggioOperatore,
    required String rilievoNc,
    required String azioneCorrettiva,
    required String note,
  }) async {
    for (final uecId in uecIds) {
      // Se è un ID operatore virtuale, assicuriamoci che esista nel DB
      if (uecId.startsWith('OP-')) {
        await _db.upsertUec(
          id: uecId,
          visitId: uecId.replaceFirst('OP-', ''),
          coltura: 'OPERATORE',
          descrizione: 'Attribuito all\'intera Azienda/OA',
          nAggregato: '',
          note: '',
        );
      }

      await _db.upsertResponse(
        uecId: uecId,
        itemCode: itemCode,
        conformita: conformita,
        livelloKo: livelloKo,
        punteggioUec: punteggioUec,
        punteggioOperatore: punteggioOperatore,
        rilievoNc: rilievoNc,
        azioneCorrettiva: azioneCorrettiva,
        note: note,
      );
    }
  }

  Future<void> deleteChecklistResponses({
    required List<String> uecIds,
    required String itemCode,
  }) async {
    for (final uecId in uecIds) {
      await _db.deleteResponse(uecId, itemCode);
    }
  }

  Future<void> clearAllVisitChecklistResponses(String visitId) async {
    await _db.deleteAllResponsesByVisit(visitId);
  }

  Stream<List<Visit>> watchMyVisits() {
    return _db.watchVisits();
  }

  Stream<List<VisitWithCompany>> watchVisitsWithCompanies({
    String? inspectorName,
  }) {
    final query = _db.select(_db.visits).join([
      leftOuterJoin(
        _db.visitCompanies,
        _db.visitCompanies.visitId.equalsExp(_db.visits.id),
      ),
      leftOuterJoin(
        _db.masterCompanies,
        _db.masterCompanies.cuaa.equalsExp(_db.visitCompanies.cuaa),
      ),
    ]);

    if (inspectorName != null && inspectorName.isNotEmpty) {
      query.where(_db.visits.inspectorName.equals(inspectorName));
    }

    query.orderBy([OrderingTerm.asc(_db.visits.scheduledAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final visit = row.readTable(_db.visits);
        final company = row.readTableOrNull(_db.visitCompanies);
        final master = row.readTableOrNull(_db.masterCompanies);

        final baseCompany =
            company ??
            VisitCompany(
              visitId: visit.id,
              updatedAt: DateTime.now(),
              ragioneSociale: '',
              cuaa: '',
              partitaIva: '',
              indirizzo: '',
              cap: '',
              comune: '',
              provincia: '',
              isSynced: true,
              isNewOperator: false,
              processingType: 'proprio',
              siVerification: false,
              latitudeText: '',
              longitudeText: '',
              manipulationSiteAddress: '',
              peakPeriodFrom: '',
              peakPeriodTo: '',
              isJointVisit: false,
              jointVisitDetails: '',
              referente: '',
              telefono: '',
              email: '',
              pec: '',
              submissionNumber: '',
              thirdPartyCertNumber: '',
              marchioNature: '',
              marchioProcesses: '',
              marchioLabelDraft: false,
              previousOdcName: '',
              previousOdcOutcomes: '',
              sqnpiSubmissionDate: null,
              sqnpiProtocol: '',
              sedeOperativaIndirizzo: '',
              sedeOperativaCap: '',
              sedeOperativaComune: '',
              sedeOperativaProvincia: '',
              manipulationSiteCap: '',
              manipulationSiteComune: '',
              manipulationSiteProvincia: '',
            );

        // Fallback per le coordinate se mancano nel snapshot della visita
        final effectiveLat = baseCompany.latitude ?? master?.latitude;
        final effectiveLng = baseCompany.longitude ?? master?.longitude;

        return VisitWithCompany(
          visit: visit,
          company: baseCompany.copyWith(
            latitude: Value(effectiveLat),
            longitude: Value(effectiveLng),
          ),
        );
      }).toList();
    });
  }

  Future<void> simulateApiSync() async {
    // Ritardo per simulare download dalla rete
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();

    // Mock Visit 1
    await _db.upsertVisit(
      id: 'VIS-9001',
      scheduledAt: DateTime(now.year, now.month, now.day + 1, 9, 0),
      companyName: 'Azienda Agricola Rossi',
      crop: 'Vite',
      status: VisitStatus.daIniziare,
      plannedDurationHours: 8,
      contactedPersons: '',
    );
    await _db.upsertCompany(
      visitId: 'VIS-9001',
      ragioneSociale: 'Azienda Agricola Rossi S.R.L.',
      cuaa: 'RSSMRA80A01H501X',
      partitaIva: '01234567890',
      indirizzo: 'Via delle Cantine, 10',
      cap: '53024',
      comune: 'Montalcino',
      provincia: 'SI',
      latitude: 43.0581,
      longitude: 11.4896,
      referente: 'Mario Rossi',
      telefono: '3331234567',
      email: 'info@rossiagricola.it',
      pec: 'info@pec.rossiagricola.it',
      sedeOperativaIndirizzo: 'Via delle Cantine, 10',
      sedeOperativaCap: '53024',
      sedeOperativaComune: 'Montalcino',
      sedeOperativaProvincia: 'SI',
      isNewOperator: true, // Mock: Nuovo operatore
      processingType: 'proprio',
      siVerification: true,
      submissionNumber: 'D-2024-00123',
      sqnpiSubmissionDate: DateTime(2024, 3, 15),
      sqnpiProtocol: 'P-2024-0001',
      manipulationSiteAddress: 'Via della Lavorazione, 22',
      manipulationSiteCap: '53024',
      manipulationSiteComune: 'Montalcino',
      manipulationSiteProvincia: 'SI',
    );
    await _db
        .into(_db.masterCompanies)
        .insertOnConflictUpdate(
          MasterCompaniesCompanion.insert(
            cuaa: 'RSSMRA80A01H501X',
            ragioneSociale: Value('Azienda Agricola Rossi S.R.L.'),
            indirizzo: const Value('Via delle Cantine, 10'),
            comune: const Value('Montalcino'),
            provincia: const Value('SI'),
            latitude: const Value(43.0581),
            longitude: const Value(11.4896),
            updatedAt: DateTime.now(),
          ),
        );
    await _db.upsertUec(
      id: 'UEC-9001-A',
      visitId: 'VIS-9001',
      coltura: 'Vite',
      descrizione: 'Vigneto Nord',
      nAggregato: '',
      note: '',
    );
    await _db.upsertUec(
      id: 'UEC-9001-B',
      visitId: 'VIS-9001',
      coltura: 'Vite',
      descrizione: 'Vigneto Sud',
      nAggregato: '',
      note: '',
    );

    // Mock Visit 2
    await _db.upsertVisit(
      id: 'VIS-9002',
      scheduledAt: DateTime(now.year, now.month, now.day + 2, 10, 30),
      companyName: 'Tenuta San Guido',
      crop: 'Olivo',
      status: VisitStatus.inCorso,
      plannedDurationHours: 12,
      durationHours: 10,
      contactedPersons: '',
    );
    await _db.upsertCompany(
      visitId: 'VIS-9002',
      ragioneSociale: 'Tenuta San Guido S.P.A.',
      cuaa: 'TNTSGD80A01H501Y',
      partitaIva: '09876543210',
      indirizzo: 'Loc. Le Capanne, 27',
      cap: '57022',
      comune: 'Castagneto Carducci',
      provincia: 'LI',
      latitude: 43.1611,
      longitude: 10.6111,
      referente: 'Guido Alberto',
      telefono: '3337654321',
      email: 'audit@tenutasanguido.it',
      pec: 'pec@pec.tenutasanguido.it',
      sedeOperativaIndirizzo: 'Loc. Bolgheri Nord, 5',
      sedeOperativaCap: '57022',
      sedeOperativaComune: 'Castagneto Carducci',
      sedeOperativaProvincia: 'LI',
      isNewOperator: false,
      processingType: 'terzista', // Mock: Terzista
      thirdPartyCertNumber: 'SQNPI-2024-TZ-77',
      siVerification: true,
      submissionNumber: 'D-2024-00456',
      sqnpiSubmissionDate: DateTime(2024, 3, 16),
      sqnpiProtocol: 'P-2024-0042',
    );
    await _db
        .into(_db.masterCompanies)
        .insertOnConflictUpdate(
          MasterCompaniesCompanion.insert(
            cuaa: 'TNTSGD80A01H501Y',
            ragioneSociale: Value('Tenuta San Guido S.P.A.'),
            indirizzo: const Value('Loc. Le Capanne, 27'),
            comune: const Value('Castagneto Carducci'),
            provincia: const Value('LI'),
            latitude: const Value(43.1611),
            longitude: const Value(10.6111),
            updatedAt: DateTime.now(),
          ),
        );
    await _db.upsertUec(
      id: 'UEC-9002-A',
      visitId: 'VIS-9002',
      coltura: 'Olivo',
      descrizione: 'Oliveto Storico',
      nAggregato: '',
      note: '',
    );

    // Mock Visit 3
    await _db.upsertVisit(
      id: 'VIS-9003',
      scheduledAt: DateTime(now.year, now.month, now.day - 1, 14, 0),
      companyName: 'Fattoria Il Palagio',
      crop: 'Melo',
      status: VisitStatus.chiusaDaSincronizzare,
      plannedDurationHours: 6,
      durationHours: 6,
      contactedPersons: '',
    );
    await _db.upsertCompany(
      visitId: 'VIS-9003',
      ragioneSociale: 'Fattoria Il Palagio',
      cuaa: 'FTTPLG80A01H501Z',
      partitaIva: '11223344556',
      indirizzo: 'Via S. Alessandro, 42',
      cap: '50063',
      comune: 'Figline e Incisa Valdarno',
      provincia: 'FI',
      latitude: 43.6211,
      longitude: 11.4691,
      referente: 'Antonio Silva',
      telefono: '3331122334',
      email: 'contatti@ilpalagio.it',
      pec: 'amministrazione@pec.ilpalagio.it',
      sedeOperativaIndirizzo: 'Località Il Palagio, 1',
      sedeOperativaCap: '50063',
      sedeOperativaComune: 'Figline e Incisa Valdarno',
      sedeOperativaProvincia: 'FI',
      submissionNumber: 'D-2024-00789',
      sqnpiSubmissionDate: DateTime(2024, 3, 17),
      sqnpiProtocol: 'P-2024-0099',
    );
    await _db
        .into(_db.masterCompanies)
        .insertOnConflictUpdate(
          MasterCompaniesCompanion.insert(
            cuaa: 'FTTPLG80A01H501Z',
            ragioneSociale: Value('Fattoria Il Palagio'),
            indirizzo: const Value('Via S. Alessandro, 42'),
            comune: const Value('Figline e Incisa Valdarno'),
            provincia: const Value('FI'),
            latitude: const Value(43.6211),
            longitude: const Value(11.4691),
            updatedAt: DateTime.now(),
          ),
        );
    await _db.upsertUec(
      id: 'UEC-9003-A',
      visitId: 'VIS-9003',
      coltura: 'Melo',
      descrizione: 'Meleto Valle',
      nAggregato: '',
      note: '',
    );
  }
}
