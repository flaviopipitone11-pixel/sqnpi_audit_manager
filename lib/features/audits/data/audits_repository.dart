import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      return repo.watchVisitsWithCompanies(inspectorEmail: auth.username);
    });

class AuditsRepository {
  AuditsRepository(this._db);

  final AppDatabase _db;
  final _supabase = Supabase.instance.client;

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

  Stream<Map<String, int>> watchNcCountsByInspector() {
    final query = _db.select(_db.checklistResponses).join([
      innerJoin(
        _db.visitUecs,
        _db.visitUecs.id.equalsExp(_db.checklistResponses.uecId),
      ),
      innerJoin(_db.visits, _db.visits.id.equalsExp(_db.visitUecs.visitId)),
    ]);

    query.where(_db.checklistResponses.conformita.equals(Conformita.ko.index));

    return query.watch().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        final inspector = row.readTable(_db.visits).inspectorName;
        if (inspector.isNotEmpty) {
          counts[inspector] = (counts[inspector] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  Stream<List<VisitWithCompany>> watchVisitsWithCompanies({
    String? inspectorEmail,
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

    if (inspectorEmail != null && inspectorEmail.isNotEmpty) {
      query.where(
        _db.visits.inspectorEmail.equals(inspectorEmail.toLowerCase()),
      );
    }

    query.orderBy([OrderingTerm.desc(_db.visits.scheduledAt)]);

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

  /// SINCRONIZZAZIONE REALE CON SUPABASE
  Future<void> syncWithCloud(String email) async {
    try {
      // 1. PULL: Scarichiamo le visite dal Cloud
      final cloudVisits = await _supabase
          .from('visits')
          .select('*, visit_companies(*)')
          .eq('inspector_email', email);

      for (final v in cloudVisits) {
        // Salvataggio Visita Locale
        await _db.upsertVisit(
          id: v['id'],
          scheduledAt: DateTime.parse(v['scheduled_at']),
          scheduledUntil: v['scheduled_until'] != null
              ? DateTime.parse(v['scheduled_until'])
              : null,
          companyName: v['company_name'],
          crop: v['crop'] ?? 'Varie',
          status: VisitStatus.values[v['status'] ?? 0],
          visitType: v['visit_type'] ?? 'ACA',
          inspectorName: v['inspector_name'] ?? '',
          inspectorEmail: v['inspector_email'] ?? email,
        );

        // Salvataggio Azienda Locale (se presente nel cloud)
        final c = v['visit_companies'];
        if (c != null) {
          await _db.upsertCompany(
            visitId: v['id'],
            ragioneSociale: c['ragione_sociale'],
            cuaa: c['cuaa'],
            partitaIva: c['partita_iva'],
            indirizzo: c['indirizzo'],
            cap: c['cap'] ?? '',
            comune: c['comune'],
            provincia: c['provincia'],
            sedeOperativaIndirizzo: c['sede_operativa_indirizzo'],
            sedeOperativaCap: c['sede_operativa_cap'] ?? '',
            sedeOperativaComune: c['sede_operativa_comune'],
            sedeOperativaProvincia: c['sede_operativa_provincia'],
            latitude: c['latitude']?.toDouble(),
            longitude: c['longitude']?.toDouble(),
            submissionNumber: c['submission_number'] ?? '',
            sqnpiProtocol: c['sqnpi_protocol'] ?? '',
            sqnpiSubmissionDate: c['sqnpi_submission_date'] != null
                ? DateTime.parse(c['sqnpi_submission_date'])
                : null,
          );
        }
      }

      // 2. PUSH: Inviamo le visite locali create dall'utente (che non sono nel cloud)
      // Per semplicità facciamo un upsert di tutte le visite locali dell'utente
      final localVisits = await _db.watchVisitsByEmail(email).first;
      for (final v in localVisits) {
        // Invio Visita
        await _supabase.from('visits').upsert({
          'id': v.id,
          'scheduled_at': v.scheduledAt.toIso8601String(),
          'scheduled_until': v.scheduledUntil?.toIso8601String(),
          'company_name': v.companyName,
          'crop': v.crop,
          'status': v.status,
          'visit_type': v.visitType,
          'inspector_name': v.inspectorName,
          'inspector_email': v.inspectorEmail,
        });

        // Invio Dettagli Azienda
        final companyRow = await (_db.select(
          _db.visitCompanies,
        )..where((t) => t.visitId.equals(v.id))).getSingleOrNull();
        if (companyRow != null) {
          await _supabase.from('visit_companies').upsert({
            'visit_id': companyRow.visitId,
            'ragione_sociale': companyRow.ragioneSociale,
            'cuaa': companyRow.cuaa,
            'partita_iva': companyRow.partitaIva,
            'indirizzo': companyRow.indirizzo,
            'cap': companyRow.cap,
            'comune': companyRow.comune,
            'provincia': companyRow.provincia,
            'sede_operativa_indirizzo': companyRow.sedeOperativaIndirizzo,
            'sede_operativa_cap': companyRow.sedeOperativaCap,
            'sede_operativa_comune': companyRow.sedeOperativaComune,
            'sede_operativa_provincia': companyRow.sedeOperativaProvincia,
            'latitude': companyRow.latitude,
            'longitude': companyRow.longitude,
            'submission_number': companyRow.submissionNumber,
            'sqnpi_protocol': companyRow.sqnpiProtocol,
            'sqnpi_submission_date': companyRow.sqnpiSubmissionDate
                ?.toIso8601String(),
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
