import 'package:flutter/foundation.dart';
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

      // Se è admin, non filtriamo per email (mostriamo tutto)
      return repo.watchVisitsWithCompanies(
        inspectorEmail: auth.isAdmin ? null : auth.username,
      );
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
  Future<void> syncWithCloud(String email, {bool isAdmin = false}) async {
    try {
      final dbEmail = email.toLowerCase();

      // 1. PUSH: Inviamo le visite locali al Cloud
      // Gli ispettori inviano i loro aggiornamenti, l'admin non spinge dati (RLS impedisce l'upsert).
      final localVisits = await _db.watchVisits().first;

      if (!isAdmin) {
        final pushVisits = await _db.watchVisitsByEmail(dbEmail).first;

        for (final v in pushVisits) {
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
            'updated_at': DateTime.now().toIso8601String(),
          });

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
      }

      // 2. PULL: Scarichiamo dal Cloud
      var query = _supabase.from('visits').select('*, visit_companies(*)');

      // Se NON è admin, filtriamo per email
      if (!isAdmin) {
        query = query.eq('inspector_email', dbEmail);
      }

      final cloudVisits = await query;

      for (final v in cloudVisits) {
        final visitId = v['id'] as String;
        final localVisit = localVisits
            .where((lv) => lv.id == visitId)
            .firstOrNull;

        // Se la visita esiste già ed è in uno stato più avanzato (chiusa o sincronizzata),
        // non sovrascriviamo lo stato con quello del cloud (che potrebbe essere obsoleto)
        final cloudStatus = v['status'] ?? 0;
        final effectiveStatus =
            (localVisit != null && localVisit.status > cloudStatus)
            ? VisitStatus.values[localVisit.status]
            : VisitStatus.values[cloudStatus];

        // Salvataggio Visita Locale
        await _db.upsertVisit(
          id: visitId,
          scheduledAt: DateTime.parse(v['scheduled_at']),
          scheduledUntil: v['scheduled_until'] != null
              ? DateTime.parse(v['scheduled_until'])
              : null,
          companyName: v['company_name'],
          crop: v['crop'] ?? 'Varie',
          status: effectiveStatus,
          visitType: v['visit_type'] ?? 'ACA',
          inspectorName: v['inspector_name']?.toString().isNotEmpty == true
              ? v['inspector_name']
              : localVisit?.inspectorName,
          inspectorEmail: v['inspector_email'] ?? email,
        );

        // Salvataggio Azienda Locale
        final c = v['visit_companies'];
        if (c != null) {
          await _db.upsertCompany(
            visitId: visitId,
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

      // 3. PULL: Broadcast Messages
      await _syncBroadcastMessages(dbEmail);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncBroadcastMessages(String userEmail) async {
    try {
      final response = await _supabase
          .from('broadcast_messages')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      final List<dynamic> data = response;
      if (data.isEmpty) return;

      for (final json in data) {
        final targetEmails = json['target_emails'] as String?;
        bool shouldSave = true;

        if (targetEmails != null && targetEmails.isNotEmpty) {
          final emailsList = targetEmails
              .split(',')
              .map((e) => e.trim().toLowerCase())
              .toList();
          if (!emailsList.contains(userEmail.toLowerCase())) {
            shouldSave = false;
          }
        }

        if (shouldSave) {
          await _db
              .into(_db.broadcastMessages)
              .insertOnConflictUpdate(
                BroadcastMessagesCompanion.insert(
                  id: json['id'] as String,
                  title: json['title'] as String,
                  message: json['message'] as String,
                  createdAt: DateTime.parse(json['created_at'] as String),
                  severity: Value(json['severity'] as String? ?? 'info'),
                  targetEmails: Value(targetEmails),
                ),
              );
        }
      }
    } catch (e) {
      debugPrint('Errore durante la sincronizzazione broadcast: $e');
    }
  }

  /// Carica una singola visita sul Cloud
  Future<void> pushVisitToCloud(String visitId) async {
    try {
      final v = await (_db.select(
        _db.visits,
      )..where((t) => t.id.equals(visitId))).getSingleOrNull();
      if (v == null) return;

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
        'updated_at': DateTime.now().toIso8601String(),
      });

      final companyRow = await (_db.select(
        _db.visitCompanies,
      )..where((t) => t.visitId.equals(visitId))).getSingleOrNull();
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
    } catch (e) {
      debugPrint('Errore durante il push della visita: $e');
    }
  }
}
