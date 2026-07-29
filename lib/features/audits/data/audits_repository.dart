import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqnpi_audit_manager/core/storage/app_database.dart';
import 'package:sqnpi_audit_manager/core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/visit_with_company.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:sqnpi_audit_manager/features/admin/application/activity_logger.dart';

final auditsRepositoryProvider = Provider<AuditsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(activityLoggerProvider);
  return AuditsRepository(db, logger);
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
  AuditsRepository(this._db, this._logger);

  final AppDatabase _db;
  final ActivityLogger _logger;
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

  Future<void> deleteAllUecs(String visitId) async {
    await _db.deleteAllUecsByVisitId(visitId);
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
  Future<List<String>> syncWithCloud(
    String email, {
    bool isAdmin = false,
    String? inspectorCode,
  }) async {
    final List<String> logs = [];
    try {
      final dbEmail = email.toLowerCase();
      logs.add('🚀 Avvio sincronizzazione per $dbEmail');

      // 1. PUSH: Inviamo le visite locali al Cloud
      debugPrint(
        'Sync: Filtering visits for email: $dbEmail (isAdmin: $isAdmin)',
      );

      final pushVisits = isAdmin
          ? await _db.select(_db.visits).get()
          : await (_db.select(
              _db.visits,
            )..where((t) => t.inspectorEmail.equals(dbEmail))).get();

      logs.add('📤 Invio ${pushVisits.length} visite al Cloud...');
      debugPrint('Sync: Found ${pushVisits.length} visits to push.');

      for (final v in pushVisits) {
        try {
          debugPrint('Sync: Pushing visit ${v.id} (${v.companyName})...');
          await pushVisitToCloud(v.id);
          logs.add('   ✅ Visita ${v.companyName} inviata');
        } catch (e) {
          debugPrint('Sync: Push failed for ${v.id}: $e');
          logs.add('   ⚠️ Push fallito per visita ${v.companyName}: $e');
        }
      }

      // 2. PULL: Scarichiamo dal Cloud tramite API Biosfera
      logs.add('📥 Scaricamento nuovi dati dal Cloud (API Biosfera)...');

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'biosfera_jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token JWT non trovato. Effettuare nuovamente il login.',
        );
      }

      String? effectiveInspectorCode = inspectorCode;
      if (effectiveInspectorCode == null || effectiveInspectorCode.isEmpty) {
        try {
          final userDataStr = await storage.read(key: 'biosfera_user_data');
          if (userDataStr != null) {
            final userData = jsonDecode(userDataStr);
            effectiveInspectorCode = userData['inspectorCode'];
          }
        } catch (_) {}
      }

      var urlStr = 'https://biosfera2.certbios.it/api-jwt/list-audits';
      if (effectiveInspectorCode != null && effectiveInspectorCode.isNotEmpty) {
        urlStr += '?cod_isp=$effectiveInspectorCode';
      }
      final url = Uri.parse(urlStr);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        throw Exception(
          'Sessione Biosfera scaduta (Token JWT scaduto). Clicca su "Disconnetti" in basso a sinistra e fai di nuovo il Login per rinnovarla.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Errore API: ${response.statusCode} - ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded['success'] != true) {
        throw Exception("L'API ha restituito success=false");
      }

      final cloudVisits = decoded['data'] as List<dynamic>? ?? [];
      logs.add('   ☁️ ${cloudVisits.length} visite trovate nel Cloud');

      for (final v in cloudVisits) {
        final visitId = v['id'] as String;
        try {
          final localVisit = await _db.getVisitById(visitId);
          final cloudUpdatedAt = v['updated_at'] != null
              ? DateTime.parse(v['updated_at'])
              : DateTime.now();

          debugPrint(
            '   -> Visita $visitId: Cloud=$cloudUpdatedAt, Local=${localVisit?.updatedAt}',
          );

          final shouldUpdateVisit =
              localVisit == null ||
              isAdmin ||
              cloudUpdatedAt.isAfter(localVisit.updatedAt) ||
              !localVisit.updatedAt.isAtSameMomentAs(cloudUpdatedAt);

          if (shouldUpdateVisit) {
            final rawStatus =
                (v['status'] ?? v['stato_visita'] as num?)?.toInt() ?? 0;
            final effectiveStatus = rawStatus < VisitStatus.values.length
                ? VisitStatus.values[rawStatus]
                : VisitStatus.daIniziare;

            final cloudScheduledAt = v['scheduled_at'] != null
                ? DateTime.tryParse(v['scheduled_at'].toString())
                : null;
            final cloudScheduledUntil = v['scheduled_until'] != null
                ? DateTime.tryParse(v['scheduled_until'].toString())
                : null;

            final effectiveScheduledAt = localVisit != null
                ? localVisit.scheduledAt
                : (cloudScheduledAt ?? DateTime.now());

            final effectiveScheduledUntil = localVisit != null
                ? (localVisit.scheduledUntil ?? cloudScheduledUntil)
                : cloudScheduledUntil;

            await _db.upsertVisit(
              id: visitId,
              scheduledAt: effectiveScheduledAt,
              scheduledUntil: effectiveScheduledUntil,
              companyName:
                  v['company_name'] ?? v['ragione_sociale'] ?? 'Sconosciuta',
              crop: v['crop'] ?? v['coltura'] ?? v['specie'] ?? 'Varie',
              status: effectiveStatus,
              visitType: v['visit_type'] ?? 'ACA',
              inspectorName: v['inspector_name']?.toString().isNotEmpty == true
                  ? v['inspector_name']
                  : localVisit?.inspectorName,
              inspectorEmail: v['inspector_email'] ?? email,
              durationHours: (v['duration_hours'] as num?)?.toInt() ?? 0,
              plannedDurationHours: (v['planned_duration_hours'] as num?)
                  ?.toInt(),
              durationJustification: v['duration_justification'] ?? '',
              lastInspectionDate: v['last_inspection_date'] != null
                  ? DateTime.tryParse(v['last_inspection_date'].toString())
                  : null,
              companionName: v['companion_name'] ?? '',
              representativeName: v['representative_name'] ?? '',
              otherOperators: v['other_operators'] ?? '',
              contactedPersons: v['contacted_persons'] ?? '',
              isRepresentativeDelegate:
                  v['is_representative_delegate'] ?? false,
              representativeDelegateDetails:
                  v['representative_delegate_details'] ?? '',
              usesM202ManualSignature: v['uses_m202_manual_signature'] ?? false,
              updatedAt: cloudUpdatedAt,
            );

            final cRaw = v['visit_companies'];
            final c = (cRaw is List && cRaw.isNotEmpty)
                ? cRaw.first
                : (cRaw is Map
                      ? cRaw
                      : v); // Fallback to v if no visit_companies array
            if (c != null) {
              final existingComp = await (_db.select(
                _db.visitCompanies,
              )..where((tbl) => tbl.visitId.equals(visitId))).getSingleOrNull();

              final String? extSedeIndirizzo = c['sede_operativa_indirizzo']
                  ?.toString();
              final String? extSedeCap = c['sede_operativa_cap']?.toString();
              final String? extSedeComune = c['sede_operativa_comune']
                  ?.toString();
              final String? extSedeProvincia = c['sede_operativa_provincia']
                  ?.toString();

              await _db.upsertCompany(
                visitId: visitId,
                ragioneSociale:
                    c['ragione_sociale'] ??
                    c['company_name'] ??
                    existingComp?.ragioneSociale ??
                    '',
                cuaa: c['cuaa'] ?? existingComp?.cuaa ?? '',
                partitaIva: c['partita_iva'] ?? existingComp?.partitaIva ?? '',
                indirizzo: c['indirizzo'] ?? existingComp?.indirizzo ?? '',
                cap: c['cap'] ?? existingComp?.cap ?? '',
                comune: c['comune'] ?? existingComp?.comune ?? '',
                provincia:
                    c['provincia'] ??
                    c['prov'] ??
                    existingComp?.provincia ??
                    '',
                sedeOperativaIndirizzo:
                    (extSedeIndirizzo != null && extSedeIndirizzo.isNotEmpty)
                    ? extSedeIndirizzo
                    : existingComp?.sedeOperativaIndirizzo,
                sedeOperativaCap: (extSedeCap != null && extSedeCap.isNotEmpty)
                    ? extSedeCap
                    : existingComp?.sedeOperativaCap,
                sedeOperativaComune:
                    (extSedeComune != null && extSedeComune.isNotEmpty)
                    ? extSedeComune
                    : existingComp?.sedeOperativaComune,
                sedeOperativaProvincia:
                    (extSedeProvincia != null && extSedeProvincia.isNotEmpty)
                    ? extSedeProvincia
                    : existingComp?.sedeOperativaProvincia,
                latitude:
                    (c['latitude'] as num?)?.toDouble() ??
                    existingComp?.latitude,
                longitude:
                    (c['longitude'] as num?)?.toDouble() ??
                    existingComp?.longitude,
                referente: c['referente'] ?? existingComp?.referente ?? '',
                telefono: c['telefono'] ?? existingComp?.telefono ?? '',
                email: c['email'] ?? existingComp?.email ?? '',
                pec: c['pec'] ?? c['email_pec'] ?? existingComp?.pec ?? '',
                submissionNumber:
                    c['submission_number'] ??
                    existingComp?.submissionNumber ??
                    '',
                sqnpiProtocol:
                    c['sqnpi_protocol'] ?? existingComp?.sqnpiProtocol ?? '',
                sqnpiSubmissionDate: c['sqnpi_submission_date'] != null
                    ? DateTime.tryParse(c['sqnpi_submission_date'].toString())
                    : existingComp?.sqnpiSubmissionDate,
                isNewOperator:
                    c['is_new_operator'] ??
                    existingComp?.isNewOperator ??
                    false,
                processingType:
                    c['processing_type'] ??
                    existingComp?.processingType ??
                    'proprio',
                thirdPartyCertNumber:
                    c['third_party_cert_number'] ??
                    existingComp?.thirdPartyCertNumber ??
                    '',
                siVerification:
                    c['si_verification'] ??
                    existingComp?.siVerification ??
                    false,
                manipulationSiteAddress:
                    c['manipulation_site_address'] ??
                    existingComp?.manipulationSiteAddress ??
                    '',
                manipulationSiteCap:
                    c['manipulation_site_cap'] ??
                    existingComp?.manipulationSiteCap ??
                    '',
                manipulationSiteComune:
                    c['manipulation_site_comune'] ??
                    existingComp?.manipulationSiteComune ??
                    '',
                manipulationSiteProvincia:
                    c['manipulation_site_provincia'] ??
                    existingComp?.manipulationSiteProvincia ??
                    '',
                peakPeriodFrom:
                    c['peak_period_from'] ?? existingComp?.peakPeriodFrom ?? '',
                peakPeriodTo:
                    c['peak_period_to'] ?? existingComp?.peakPeriodTo ?? '',
                isJointVisit: c['is_joint_visit'] ?? false,
                jointVisitDetails: c['joint_visit_details'] ?? '',
                marchioNature: c['marchio_nature'] ?? '',
                marchioProcesses: c['marchio_processes'] ?? '',
                marchioLabelDraft: c['marchio_label_draft'] ?? false,
                previousOdcName: c['previous_odc_name'] ?? '',
                previousOdcOutcomes: c['previous_odc_outcomes'] ?? '',
              );
            }
            debugPrint('   -> Visita $visitId dati base salvati.');
          }

          // SEMPRE pullare i dettagli profondi
          await _pullVisitDetailsFromCloud(visitId);

          // Scarica il dettaglio dell'incarico dall'API Biosfera download-assignment
          await _fetchAndSaveAssignmentDetailsFromBiosfera(
            visitId: visitId,
            token: token,
          );

          // Riallinea il timestamp locale a quello del cloud.
          await _db.setVisitUpdatedAt(visitId, cloudUpdatedAt);
          logs.add('   ✅ ${v['company_name'] ?? 'Sconosciuta'}: sincronizzata');
        } catch (e) {
          logs.add('   ❌ Errore sincronizzazione visita $visitId: $e');
        }
      }

      try {
        await _syncBroadcastMessages(dbEmail);
      } catch (e) {
        logs.add('   ⚠️ Avvisi non sincronizzati: $e');
      }

      logs.add('🏁 Sincronizzazione completata');

      // Log attività per aggiornare la dashboard
      await _logger.log(
        action: 'CLOUD_SYNC_SUCCESS',
        description: 'Sincronizzazione Cloud completata con successo.',
        actor: email,
      );

      return logs;
    } catch (e) {
      logs.add('❌ ERRORE GLOBALE SYNC: $e');

      // Log errore per la dashboard
      await _logger.log(
        action: 'CLOUD_SYNC_ERROR',
        description: 'Errore durante la sincronizzazione Cloud: $e',
        actor: email,
      );

      return logs;
    }
  }

  Future<void> _fetchAndSaveAssignmentDetailsFromBiosfera({
    required String visitId,
    required String token,
  }) async {
    try {
      final downloadUrl = Uri.parse(
        'https://biosfera2.certbios.it/api-jwt/download-assignment?id=$visitId',
      );
      final response = await http.get(
        downloadUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'] as Map<String, dynamic>;
          debugPrint('   ✅ Biosfera download-assignment OK per $visitId');

          final companyName = data['company_name'] ?? data['ragione_sociale'];
          final plannedDuration = int.tryParse(
            data['planned_duration_hours']?.toString() ?? '',
          );
          final lastInspDate = data['last_inspection_date'] != null
              ? DateTime.tryParse(data['last_inspection_date'].toString())
              : null;

          final localVisit = await _db.getVisitById(visitId);
          if (localVisit != null) {
            final effectiveStatus =
                localVisit.status < VisitStatus.values.length
                ? VisitStatus.values[localVisit.status]
                : VisitStatus.daIniziare;

            await _db.upsertVisit(
              id: localVisit.id,
              scheduledAt: localVisit.scheduledAt,
              scheduledUntil: localVisit.scheduledUntil,
              companyName:
                  (companyName != null && companyName.toString().isNotEmpty)
                  ? companyName.toString()
                  : localVisit.companyName,
              crop: localVisit.crop,
              status: effectiveStatus,
              visitType: localVisit.visitType,
              inspectorName: localVisit.inspectorName,
              inspectorEmail: localVisit.inspectorEmail,
              durationHours: localVisit.durationHours,
              plannedDurationHours:
                  plannedDuration ?? localVisit.plannedDurationHours,
              durationJustification: localVisit.durationJustification,
              lastInspectionDate: lastInspDate ?? localVisit.lastInspectionDate,
              companionName: localVisit.companionName,
              representativeName: localVisit.representativeName,
              otherOperators: localVisit.otherOperators,
              contactedPersons: localVisit.contactedPersons,
              isRepresentativeDelegate: localVisit.isRepresentativeDelegate,
              representativeDelegateDetails:
                  localVisit.representativeDelegateDetails,
              usesM202ManualSignature: localVisit.usesM202ManualSignature,
              updatedAt: localVisit.updatedAt,
            );
          }

          final c = data['visit_companies'];
          if (c != null && c is Map<String, dynamic>) {
            final existingComp = await (_db.select(
              _db.visitCompanies,
            )..where((tbl) => tbl.visitId.equals(visitId))).getSingleOrNull();

            await _db.upsertCompany(
              visitId: visitId,
              ragioneSociale:
                  c['ragione_sociale'] ??
                  c['company_name'] ??
                  existingComp?.ragioneSociale ??
                  '',
              cuaa: c['cuaa'] ?? existingComp?.cuaa ?? '',
              partitaIva: c['partita_iva'] ?? existingComp?.partitaIva ?? '',
              indirizzo: c['indirizzo'] ?? existingComp?.indirizzo ?? '',
              cap: c['cap'] ?? existingComp?.cap ?? '',
              comune: c['comune'] ?? existingComp?.comune ?? '',
              provincia:
                  c['provincia'] ?? c['prov'] ?? existingComp?.provincia ?? '',
              sedeOperativaIndirizzo:
                  existingComp?.sedeOperativaIndirizzo ?? '',
              sedeOperativaCap: existingComp?.sedeOperativaCap ?? '',
              sedeOperativaComune: existingComp?.sedeOperativaComune ?? '',
              sedeOperativaProvincia:
                  existingComp?.sedeOperativaProvincia ?? '',
              latitude: existingComp?.latitude,
              longitude: existingComp?.longitude,
              referente: existingComp?.referente ?? '',
              telefono: existingComp?.telefono ?? '',
              email: c['email'] ?? existingComp?.email ?? '',
              pec: c['pec'] ?? c['email_pec'] ?? existingComp?.pec ?? '',
              submissionNumber:
                  c['submission_number'] ??
                  c['submission_numer'] ??
                  existingComp?.submissionNumber ??
                  '',
              sqnpiProtocol:
                  c['sqnpi_protocol'] ?? existingComp?.sqnpiProtocol ?? '',
              sqnpiSubmissionDate: c['sqnpi_submission_date'] != null
                  ? DateTime.tryParse(c['sqnpi_submission_date'].toString())
                  : existingComp?.sqnpiSubmissionDate,
              isNewOperator: existingComp?.isNewOperator ?? false,
              processingType: existingComp?.processingType ?? 'proprio',
              thirdPartyCertNumber: existingComp?.thirdPartyCertNumber ?? '',
              siVerification: existingComp?.siVerification ?? false,
              manipulationSiteAddress:
                  existingComp?.manipulationSiteAddress ?? '',
              manipulationSiteCap: existingComp?.manipulationSiteCap ?? '',
              manipulationSiteComune:
                  existingComp?.manipulationSiteComune ?? '',
              manipulationSiteProvincia:
                  existingComp?.manipulationSiteProvincia ?? '',
              peakPeriodFrom: existingComp?.peakPeriodFrom ?? '',
              peakPeriodTo: existingComp?.peakPeriodTo ?? '',
              isJointVisit: existingComp?.isJointVisit ?? false,
              jointVisitDetails: existingComp?.jointVisitDetails ?? '',
              marchioNature: existingComp?.marchioNature ?? '',
              marchioProcesses: existingComp?.marchioProcesses ?? '',
              marchioLabelDraft: existingComp?.marchioLabelDraft ?? false,
              previousOdcName: existingComp?.previousOdcName ?? '',
              previousOdcOutcomes: existingComp?.previousOdcOutcomes ?? '',
            );
          }

          final existingPrevNc = await (_db.select(
            _db.visitPreviousNcManagements,
          )..where((tbl) => tbl.visitId.equals(visitId))).getSingleOrNull();

          final String? extractedCertDate =
              (c != null &&
                  c is Map<String, dynamic> &&
                  c['prev_org_certified_date'] != null)
              ? c['prev_org_certified_date'].toString()
              : data['prev_org_certified_date']?.toString();
          final String? extractedSanctDate =
              (c != null &&
                  c is Map<String, dynamic> &&
                  c['prev_org_sanctioned_date'] != null)
              ? c['prev_org_sanctioned_date'].toString()
              : data['prev_org_sanctioned_date']?.toString();

          final certDateToSave =
              (extractedCertDate != null && extractedCertDate.isNotEmpty)
              ? extractedCertDate
              : (existingPrevNc?.prevOrgCertifiedDate ?? '');
          final sanctDateToSave =
              (extractedSanctDate != null && extractedSanctDate.isNotEmpty)
              ? extractedSanctDate
              : (existingPrevNc?.prevOrgSanctionedDate ?? '');

          List<dynamic>? prevNcItems;
          final rawPrevNc = data['previous_nc_items'] ??
              data['visit_previous_nc_managements'] ??
              data['visit_previous_ncs'];
          if (rawPrevNc != null) {
            if (rawPrevNc is List) {
              prevNcItems = rawPrevNc;
            } else if (rawPrevNc is Map) {
              final items = <dynamic>[];
              final mapData = rawPrevNc as Map<String, dynamic>;
              mapData.forEach((key, value) {
                if (RegExp(r'^\d+$').hasMatch(key) && value is Map) {
                  items.add(value);
                }
              });
              if (items.isNotEmpty) {
                prevNcItems = items;
              } else {
                prevNcItems = [mapData];
              }
            }
          }

          if (prevNcItems != null ||
              certDateToSave.isNotEmpty ||
              sanctDateToSave.isNotEmpty) {
            await _db.upsertPreviousNcManagement(
              visitId: visitId,
              prevNcResults: existingPrevNc?.prevNcResults ?? 0,
              prevNcRequirementsStillKO:
                  existingPrevNc?.prevNcRequirementsStillKO ?? '',
              prevCorrectiveActionsCoherent:
                  existingPrevNc?.prevCorrectiveActionsCoherent ?? 0,
              prevCorrectiveActionsDetails:
                  existingPrevNc?.prevCorrectiveActionsDetails ?? '',
              prevOrgCertifiedDate: certDateToSave,
              prevOrgSanctionedDate: sanctDateToSave,
              biosSanctionDetails: existingPrevNc?.biosSanctionDetails ?? '',
              previousNcListJson: prevNcItems != null
                  ? jsonEncode(prevNcItems)
                  : existingPrevNc?.previousNcListJson,
            );
          }
        }
      }
    } catch (e) {
      debugPrint(
        '   ⚠️ Download assignment da Biosfera per $visitId non riuscito: $e',
      );
    }
  }

  Future<void> deleteVisitFromCloud(String visitId) async {
    try {
      debugPrint('Deleting visit $visitId from cloud...');
      await _supabase.from('visits').delete().eq('id', visitId);
      debugPrint('Visit $visitId deleted from cloud successfully.');
    } catch (e) {
      debugPrint('Error deleting visit from cloud: $e');
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
                  severity: Value(() {
                    final s = json['severity'];
                    if (s is int) return s;
                    if (s == 'warning') return 1;
                    if (s == 'critical') return 2;
                    return 0;
                  }()),
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
  Future<bool> pushVisitToCloud(String visitId) async {
    try {
      final v = await (_db.select(
        _db.visits,
      )..where((t) => t.id.equals(visitId))).getSingleOrNull();
      if (v == null) return false;

      debugPrint('Pushing visit $visitId to cloud...');

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
        'duration_hours': v.durationHours,
        'planned_duration_hours': v.plannedDurationHours,
        'duration_justification': v.durationJustification,
        'last_inspection_date': v.lastInspectionDate?.toIso8601String(),
        'companion_name': v.companionName,
        'representative_name': v.representativeName,
        'other_operators': v.otherOperators,
        'contacted_persons': v.contactedPersons,
        'is_representative_delegate': v.isRepresentativeDelegate,
        'representative_delegate_details': v.representativeDelegateDetails,
        'uses_m202_manual_signature': v.usesM202ManualSignature,
        'updated_at': v.updatedAt.toIso8601String(),
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
          'referente': companyRow.referente,
          'telefono': companyRow.telefono,
          'email': companyRow.email,
          'pec': companyRow.pec,
          'submission_number': companyRow.submissionNumber,
          'sqnpi_protocol': companyRow.sqnpiProtocol,
          'sqnpi_submission_date': companyRow.sqnpiSubmissionDate
              ?.toIso8601String(),
          // Campi Revisione 08
          'is_new_operator': companyRow.isNewOperator,
          'processing_type': companyRow.processingType,
          'third_party_cert_number': companyRow.thirdPartyCertNumber,
          'si_verification': companyRow.siVerification,
          'manipulation_site_address': companyRow.manipulationSiteAddress,
          'manipulation_site_cap': companyRow.manipulationSiteCap,
          'manipulation_site_comune': companyRow.manipulationSiteComune,
          'manipulation_site_provincia': companyRow.manipulationSiteProvincia,
          'peak_period_from': companyRow.peakPeriodFrom,
          'peak_period_to': companyRow.peakPeriodTo,
          'is_joint_visit': companyRow.isJointVisit,
          'joint_visit_details': companyRow.jointVisitDetails,
          'marchio_nature': companyRow.marchioNature,
          'marchio_processes': companyRow.marchioProcesses,
          'marchio_label_draft': companyRow.marchioLabelDraft,
          'previous_odc_name': companyRow.previousOdcName,
          'previous_odc_outcomes': companyRow.previousOdcOutcomes,
        });
      }
      debugPrint('Push visit $visitId OK.');

      // PUSH DETTAGLI PROFONDI
      final detailsSuccess = await _pushVisitDetailsToCloud(visitId);
      return detailsSuccess;
    } catch (e, stack) {
      debugPrint('CRITICAL: Errore durante il push della visita $visitId: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  Future<bool> _pushVisitDetailsToCloud(String visitId) async {
    try {
      debugPrint('--- Inizio Deep Push per visita: $visitId ---');

      // 1. DOCUMENTI DI RIFERIMENTO E VISIONATI
      try {
        final docs = await (_db.select(
          _db.visitDocuments,
        )..where((t) => t.visitId.equals(visitId))).get();
        debugPrint('📄 Documenti locali trovati per $visitId: ${docs.length}');
        if (docs.isNotEmpty) {
          for (final d in docs) {
            try {
              final singlePayload = <String, dynamic>{
                'id': d.id,
                'visit_id': d.visitId,
                'category': d.category,
                'doc_type': d.docType,
                'extra_value': d.extraValue,
                'is_checked': d.isChecked,
              };
              await _supabase.from('visit_documents').upsert(singlePayload);
            } catch (e) {
              debugPrint('Errore push documento: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Errore caricamento documenti: $e');
      }

      // 2. UEC
      try {
        final uecs = await (_db.select(
          _db.visitUecs,
        )..where((t) => t.visitId.equals(visitId))).get();
        final localUecIds = uecs.map((u) => u.id).toList();

        try {
          // Recuperiamo le UEC attualmente sul cloud per questa visita
          final cloudUecsRes = await _supabase
              .from('visit_uecs')
              .select('id')
              .eq('visit_id', visitId);
          final cloudUecIds = (cloudUecsRes as List)
              .map((u) => u['id'] as String)
              .toList();

          // Identifichiamo quali ID esistono sul cloud ma non più localmente
          final idsToDelete = cloudUecIds
              .where((id) => !localUecIds.contains(id))
              .toList();

          if (idsToDelete.isNotEmpty) {
            debugPrint(
              'Rilevate ${idsToDelete.length} UEC orfane sul cloud. Avvio pulizia a cascata...',
            );

            // 1. Eliminiamo le risposte collegate a queste UEC
            await _supabase
                .from('checklist_responses_packed')
                .delete()
                .inFilter('uec_id', idsToDelete);

            // 2. Eliminiamo i lotti collegati a queste UEC
            await _supabase
                .from('visit_lots')
                .delete()
                .inFilter('uec_id', idsToDelete);

            // 3. Finalmente eliminiamo le UEC stesse
            await _supabase
                .from('visit_uecs')
                .delete()
                .inFilter('id', idsToDelete);

            debugPrint('Pulizia orfani completata con successo.');
          }
        } catch (e) {
          debugPrint('ERRORE DURANTE PULIZIA ORFANI CLOUD (UEC/Lots): $e');
        }

        debugPrint('Pushing ${uecs.length} UECs...');

        for (final u in uecs) {
          await _supabase.from('visit_uecs').upsert({
            'id': u.id,
            'visit_id': u.visitId,
            'coltura': u.coltura,
            'descrizione': u.descrizione,
            'n_aggregato': u.nAggregato,
            'note': u.note,
            'latitude': u.latitude,
            'longitude': u.longitude,
            'sqnpi_consistency': u.sqnpiConsistency,
            'sqnpi_compliance': u.sqnpiCompliance,
            'is_traceable': u.isTraceable,
            'has_claims': u.hasClaims,
            'is_field_process_verified': u.isFieldProcessVerified,
            'has_sampling': u.hasSampling,
            'sampling_lot_id': u.samplingLotId,
            'found_product': u.foundProduct,
            'field_process_details': u.fieldProcessDetails,
            'updated_at': u.updatedAt.toIso8601String(),
          });

          // 3. LOTTI per questa UEC
          final lots = await (_db.select(
            _db.visitLots,
          )..where((t) => t.uecId.equals(u.id))).get();
          for (final l in lots) {
            await _supabase.from('visit_lots').upsert({
              'id': l.id,
              'uec_id': l.uecId,
              'codice': l.codice,
              'quantita': l.quantita,
              'note': l.note,
              'updated_at': l.updatedAt.toIso8601String(),
            });
          }
        }
      } catch (e) {
        debugPrint('Errore durante il push di UECs/Lots: $e');
      }

      // 4. RISPOSTE CHECKLIST
      try {
        final allResponses =
            await (_db.select(_db.checklistResponses)..where(
                  (t) => t.uecId.isInQuery(
                    _db.selectOnly(_db.visitUecs)
                      ..addColumns([_db.visitUecs.id])
                      ..where(_db.visitUecs.visitId.equals(visitId)),
                  ),
                ))
                .get();
        final Map<String, List<Map<String, dynamic>>> groupedByUec = {};
        for (final r in allResponses) {
          groupedByUec.putIfAbsent(r.uecId, () => []).add({
            'id': r.id,
            'item_code': r.itemCode,
            'conformita': r.conformita,
            'livello_ko': r.livelloKo,
            'punteggio_uec': r.punteggioUec,
            'punteggio_operatore': r.punteggioOperatore,
            'rilievo_nc': r.rilievoNc,
            'azione_correttiva': r.azioneCorrettiva,
            'note': r.note,
            'updated_at': r.updatedAt.toIso8601String(),
          });
        }
        for (final entry in groupedByUec.entries) {
          await _supabase.from('checklist_responses_packed').upsert({
            'uec_id': entry.key,
            'visit_id': visitId,
            'responses_json': entry.value,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di checklist_responses: $e');
      }

      // 5. CHIUSURA / ESITO
      try {
        final closing = await (_db.select(
          _db.visitClosings,
        )..where((t) => t.visitId.equals(visitId))).getSingleOrNull();
        if (closing != null) {
          await _supabase.from('visit_closings').upsert({
            'visit_id': closing.visitId,
            'corrective_actions': closing.correctiveActions,
            'resolution_deadline': closing.resolutionDeadline
                ?.toIso8601String(),
            'is_closed': closing.isClosed,
            'cap5_adherence': closing.cap5Adherence,
            'cap5_specific_crops': closing.cap5SpecificCrops,
            'commitment_to_rectify': closing.commitmentToRectify,
            'inspection_methods': closing.inspectionMethods,
            'representative_present': closing.representativePresent,
            'is_outcome_formalized': closing.isOutcomeFormalized,
            'verification_notes': closing.verificationNotes,
            'final_recommendation': closing.finalRecommendation,
            'inspector_final_comment': closing.inspectorFinalComment,
            'final_outcome': closing.finalOutcome,
            'provision_detail': closing.provisionDetail,
            'representative_reservations': closing.representativeReservations,
            'updated_at': closing.updatedAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di visit_closings: $e');
      }

      // 6. FIRME
      try {
        final signatures = await (_db.select(
          _db.visitSignatures,
        )..where((t) => t.visitId.equals(visitId))).get();
        for (final s in signatures) {
          await _supabase.from('visit_signatures').upsert({
            'id': s.id,
            'visit_id': s.visitId,
            'signature_type': s.signatureType,
            'signer_name': s.signerName,
            'file_path': s.filePath,
            'identity_doc_path': s.identityDocPath,
            'created_at': s.createdAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di visit_signatures: $e');
      }

      // 7. NC ANNI PRECEDENTI
      try {
        final prevNc = await (_db.select(
          _db.visitPreviousNcManagements,
        )..where((t) => t.visitId.equals(visitId))).getSingleOrNull();
        if (prevNc != null) {
          final payload = {
            'visit_id': prevNc.visitId,
            'prev_nc_results': prevNc.prevNcResults,
            'prev_nc_requirements_still_ko': prevNc.prevNcRequirementsStillKO,
            'prev_corrective_actions_coherent':
                prevNc.prevCorrectiveActionsCoherent,
            'prev_corrective_actions_details':
                prevNc.prevCorrectiveActionsDetails,
            'prev_org_certified_date': prevNc.prevOrgCertifiedDate,
            'prev_org_sanctioned_date': prevNc.prevOrgSanctionedDate,
            'bios_sanction_details': prevNc.biosSanctionDetails,
            'previous_nc_list_json': prevNc.previousNcListJson,
            'updated_at': prevNc.updatedAt.toIso8601String(),
          };
          await _supabase
              .from('visit_previous_nc_managements')
              .upsert(payload, onConflict: 'visit_id');
        }
      } catch (e) {
        debugPrint('❌ ERRORE push Gestione NC: $e');
      }

      // 8. BILANCIO DI MASSA
      try {
        final massBalances = await (_db.select(
          _db.massBalanceRecords,
        )..where((t) => t.visitId.equals(visitId))).get();
        for (final mb in massBalances) {
          await _supabase.from('mass_balance_records').upsert({
            'id': mb.id,
            'visit_id': mb.visitId,
            'substances': mb.substances,
            'purchased': mb.purchased,
            'used': mb.used,
            'stock': mb.stock,
            'discrepancy': mb.discrepancy,
            'reference_documents': mb.referenceDocuments,
            'verified_products': mb.verifiedProducts,
            'ingress_data': mb.ingressData,
            'ingress_docs': mb.ingressDocs,
            'egress_data': mb.egressData,
            'egress_docs': mb.egressDocs,
            'comment': mb.comment,
            'updated_at': mb.updatedAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di mass_balance: $e');
      }

      // 9. ALLEGATI
      try {
        final allAttachments = await (_db.select(
          _db.visitAttachments,
        )..where((t) => t.visitId.equals(visitId))).get();
        final realAttachments = allAttachments
            .where((a) => a.category != 'reference' && a.category != 'viewed')
            .toList();
        for (final a in realAttachments) {
          await _supabase.from('visit_attachments').upsert({
            'id': a.id,
            'visit_id': a.visitId,
            'file_path': a.filePath,
            'caption': a.caption,
            'category': a.category,
            'attachment_type': a.attachmentType,
            'extra_value': a.extraValue,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'uec_id': a.uecId,
            'checklist_code': a.checklistCode,
            'created_at': a.createdAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di visit_attachments: $e');
      }

      // 10. CAMPIONAMENTO
      try {
        final samples = await (_db.select(
          _db.visitSamples,
        )..where((t) => t.visitId.equals(visitId))).get();
        for (final s in samples) {
          await _supabase.from('visit_samples').upsert({
            'id': s.id,
            'visit_id': s.visitId,
            'sample_code': s.sampleCode,
            'matrix_type': s.matrixType,
            'seal_number': s.sealNumber,
            'producer_name': s.producerName,
            'producer_code': s.producerCode,
            'lot_number_georef': s.lotNumberGeoref,
            'inspection_date': s.inspectionDate?.toIso8601String(),
            'inspector_name': s.inspectorName,
            'inspector_code': s.inspectorCode,
            'photo_paths': s.photoPaths,
            'photo_path': s.photoPath,
            'created_at': s.createdAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di visit_samples: $e');
      }

      // 11. DOCUMENTI BILANCIO DI MASSA
      try {
        final mbDocs = await (_db.select(
          _db.massBalanceDocuments,
        )..where((t) => t.visitId.equals(visitId))).get();
        for (final doc in mbDocs) {
          await _supabase.from('mass_balance_documents').upsert({
            'id': doc.id,
            'visit_id': doc.visitId,
            'doc_type': doc.docType,
            'file_path': doc.filePath,
            'file_name': doc.fileName,
            'caption': doc.caption,
            'created_at': doc.createdAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di mass_balance_docs: $e');
      }

      // 12. POST HARVEST
      try {
        final phRecord = await (_db.select(
          _db.postHarvestRecords,
        )..where((t) => t.visitId.equals(visitId))).getSingleOrNull();
        if (phRecord != null) {
          await _supabase.from('post_harvest_records').upsert({
            'id': phRecord.id,
            'visit_id': phRecord.visitId,
            'phases': phRecord.phases,
            'mb_verified_products': phRecord.mbVerifiedProducts,
            'mb_input_data': phRecord.mbInputData,
            'mb_input_docs': phRecord.mbInputDocs,
            'mb_output_data': phRecord.mbOutputData,
            'mb_output_docs': phRecord.mbOutputDocs,
            'mb_comment': phRecord.mbComment,
            'mb_balances': phRecord.mbBalances,
            'traceability_verified_products':
                phRecord.traceabilityVerifiedProducts,
            'updated_at': phRecord.updatedAt.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Errore durante il push di post_harvest: $e');
      }

      debugPrint('--- Deep Push per $visitId COMPLETATO ---');
      return true;
    } catch (e, stack) {
      debugPrint('CRITICAL: Errore durante il push dei dettagli $visitId: $e');
      debugPrint('Stack: $stack');
      return false;
    }
  }

  Future<void> _pullVisitDetailsFromCloud(String visitId) async {
    debugPrint('--- Deep Pull START per visita: $visitId ---');

    // 1. UEC
    try {
      final uecs = await _supabase
          .from('visit_uecs')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ UEC scaricate: ${uecs.length}');

      // Se il cloud non ha UEC, svuotiamo anche il locale per questa visita per evitare "resurrezioni"
      if (uecs.isEmpty) {
        await _db.deleteAllUecsByVisitId(visitId);
        debugPrint('   🧹 Locale svuotato (0 UEC sul cloud)');
      }

      for (final u in uecs) {
        await _db.upsertUec(
          id: u['id'],
          visitId: u['visit_id'],
          coltura: u['coltura'] ?? '',
          descrizione: u['descrizione'] ?? '',
          nAggregato: u['n_aggregato'] ?? '',
          note: u['note'] ?? '',
          latitude: u['latitude']?.toDouble(),
          longitude: u['longitude']?.toDouble(),
          sqnpiConsistency: u['sqnpi_consistency'],
          sqnpiCompliance: u['sqnpi_compliance'],
          isTraceable: u['is_traceable'],
          hasClaims: u['has_claims'],
          isFieldProcessVerified: u['is_field_process_verified'],
          hasSampling: u['has_sampling'],
          samplingLotId: u['sampling_lot_id'],
          foundProduct: u['found_product'],
          fieldProcessDetails: u['field_process_details'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull UEC: $e');
    }

    // 2. LOTTI
    try {
      final lots = await _supabase
          .from('visit_lots')
          .select('*, visit_uecs!inner(visit_id)')
          .eq('visit_uecs.visit_id', visitId);
      debugPrint('   ✅ Lotti scaricati: ${lots.length}');
      for (final l in lots) {
        await _db.upsertLot(
          id: l['id'],
          uecId: l['uec_id'],
          codice: l['codice'] ?? '',
          quantita: l['quantita'] ?? '',
          note: l['note'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Lotti: $e');
    }

    // 3. FIRME
    try {
      final signatures = await _supabase
          .from('visit_signatures')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Firme scaricate: ${signatures.length}');
      for (final s in signatures) {
        await _db.insertSignature(
          visitId: s['visit_id'],
          signatureType: s['signature_type'] ?? '',
          signerName: s['signer_name'],
          filePath: s['file_path'] ?? '',
          identityDocPath: s['identity_doc_path'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Firme: $e');
    }

    // 4. RISPOSTE CHECKLIST (UNPACKING JSONB)
    try {
      final packedResponses = await _supabase
          .from('checklist_responses_packed')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Risposte packed scaricate: ${packedResponses.length}');

      for (final packed in packedResponses) {
        final List<dynamic> responsesList =
            packed['responses_json'] as List<dynamic>;

        for (final r in responsesList) {
          final rawConf = (r['conformita'] as num?)?.toInt() ?? 0;
          final effectiveConf = rawConf < Conformita.values.length
              ? Conformita.values[rawConf]
              : Conformita.ok;

          await _db.upsertResponse(
            uecId: packed['uec_id'],
            itemCode: r['item_code'],
            conformita: effectiveConf,
            livelloKo: (r['livello_ko'] as num?)?.toInt(),
            punteggioUec: (r['punteggio_uec'] as num?)?.toInt(),
            punteggioOperatore: (r['punteggio_operatore'] as num?)?.toInt(),
            rilievoNc: r['rilievo_nc'] ?? '',
            azioneCorrettiva: r['azione_correttiva'] ?? '',
            note: r['note'] ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Risposte Checklist: $e');
    }

    // 5. CHIUSURA / ESITO
    try {
      final closings = await _supabase
          .from('visit_closings')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Chiusura scaricata: ${closings.length}');
      if (closings.isNotEmpty) {
        final cl = closings.first;
        await _db.upsertClosing(
          visitId: cl['visit_id'],
          correctiveActions: cl['corrective_actions'] ?? '',
          resolutionDeadline: cl['resolution_deadline'] != null
              ? DateTime.parse(cl['resolution_deadline'])
              : null,
          isClosed: cl['is_closed'] ?? false,
          cap5Adherence: cl['cap5_adherence'],
          cap5SpecificCrops: cl['cap5_specific_crops'],
          commitmentToRectify: cl['commitment_to_rectify'],
          inspectionMethods: cl['inspection_methods'],
          representativePresent: cl['representative_present'],
          isOutcomeFormalized: cl['is_outcome_formalized'],
          verificationNotes: cl['verification_notes'],
          finalRecommendation: cl['final_recommendation'],
          inspectorFinalComment: cl['inspector_final_comment'],
          finalOutcome: cl['final_outcome'],
          provisionDetail: cl['provision_detail'],
          representativeReservations: cl['representative_reservations'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Chiusura: $e');
    }

    // 6. NC ANNI PRECEDENTI
    try {
      final prevNcs = await _supabase
          .from('visit_previous_nc_managements')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ NC Precedenti scaricate: ${prevNcs.length}');
      if (prevNcs.isNotEmpty) {
        final pn = prevNcs.first;
        String prevNcJson = '[]';
        if (pn['previous_nc_list_json'] != null) {
          prevNcJson = pn['previous_nc_list_json'] is String
              ? pn['previous_nc_list_json']
              : jsonEncode(pn['previous_nc_list_json']);
        } else if (pn['previous_nc_items'] != null) {
          prevNcJson = jsonEncode(pn['previous_nc_items']);
        }

        await _db.upsertPreviousNcManagement(
          visitId: pn['visit_id'],
          prevNcResults: pn['prev_nc_results'] ?? 0,
          prevNcRequirementsStillKO: pn['prev_nc_requirements_still_ko'] ?? '',
          prevCorrectiveActionsCoherent:
              pn['prev_corrective_actions_coherent'] ?? 0,
          prevCorrectiveActionsDetails:
              pn['prev_corrective_actions_details'] ?? '',
          prevOrgCertifiedDate: pn['prev_org_certified_date'] ?? '',
          prevOrgSanctionedDate: pn['prev_org_sanctioned_date'] ?? '',
          biosSanctionDetails: pn['bios_sanction_details'] ?? '',
          previousNcListJson: prevNcJson,
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Gestione NC: $e');
    }

    // 7. BILANCIO DI MASSA
    try {
      final massBalances = await _supabase
          .from('mass_balance_records')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Bilancio Massa scaricati: ${massBalances.length}');
      for (final mb in massBalances) {
        await _db.upsertMassBalance(
          id: mb['id'],
          visitId: mb['visit_id'],
          substances: mb['substances'],
          purchased: mb['purchased']?.toDouble(),
          used: mb['used']?.toDouble(),
          stock: mb['stock']?.toDouble(),
          discrepancy: mb['discrepancy']?.toDouble(),
          referenceDocuments: mb['reference_documents'],
          verifiedProducts: mb['verified_products'],
          ingressData: mb['ingress_data'],
          ingressDocs: mb['ingress_docs'],
          egressData: mb['egress_data'],
          egressDocs: mb['egress_docs'],
          comment: mb['comment'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Bilancio Massa: $e');
    }

    // 8. ALLEGATI
    try {
      final attachments = await _supabase
          .from('visit_attachments')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Allegati scaricati: ${attachments.length}');
      for (final a in attachments) {
        await _db.insertAttachment(
          id: a['id'],
          visitId: a['visit_id'],
          filePath: a['file_path'] ?? '',
          caption: a['caption'] ?? '',
          category: a['category'] ?? 'general',
          attachmentType: a['attachment_type'] ?? '',
          extraValue: a['extra_value'] ?? '',
          latitude: a['latitude']?.toDouble(),
          longitude: a['longitude']?.toDouble(),
          uecId: a['uec_id'],
          checklistCode: a['checklist_code'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Allegati: $e');
    }

    // 8b. DOCUMENTI (Tabella dedicata)
    try {
      final cloudDocs = await _supabase
          .from('visit_documents')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Documenti scaricati: ${cloudDocs.length}');
      if (cloudDocs.isNotEmpty) {
        await _db.deleteSpecialDocumentsByVisitId(visitId);
        for (final d in cloudDocs) {
          await _db.upsertDocument(
            id: d['id'],
            visitId: d['visit_id'],
            category: d['category'] ?? '',
            docType: d['doc_type'] ?? '',
            extraValue: d['extra_value'] ?? '',
            isChecked: d['is_checked'] ?? true,
            filePath: d['file_path'] ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Documenti: $e');
    }

    // 9. CAMPIONAMENTO
    try {
      final samples = await _supabase
          .from('visit_samples')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Campionamenti scaricati: ${samples.length}');
      for (final s in samples) {
        await _db.upsertSample(
          id: s['id'],
          visitId: s['visit_id'],
          sampleCode: s['sample_code'] ?? '',
          matrixType: s['matrix_type'] ?? '',
          sealNumber: s['seal_number'] ?? '',
          producerName: s['producer_name'] ?? '',
          producerCode: s['producer_code'] ?? '',
          lotNumberGeoref: s['lot_number_georef'] ?? '',
          inspectionDate: s['inspection_date'] != null
              ? DateTime.parse(s['inspection_date'])
              : null,
          inspectorName: s['inspector_name'] ?? '',
          inspectorCode: s['inspector_code'] ?? '',
          photoPaths: s['photo_paths'] ?? '',
          photoPath: s['photo_path'],
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Campionamento: $e');
    }

    // 10. DOCUMENTI BILANCIO DI MASSA
    try {
      final mbDocs = await _supabase
          .from('mass_balance_documents')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Documenti BdM scaricati: ${mbDocs.length}');
      for (final doc in mbDocs) {
        await _db.upsertMassBalanceDoc(
          id: doc['id'],
          visitId: doc['visit_id'],
          docType: doc['doc_type'] ?? '',
          filePath: doc['file_path'] ?? '',
          fileName: doc['file_name'] ?? '',
          caption: doc['caption'] ?? '',
          createdAt: doc['created_at'] != null
              ? DateTime.parse(doc['created_at'])
              : null,
        );
      }
    } catch (e) {
      debugPrint('   ❌ ERRORE pull Documenti BdM: $e');
    }

    // 11. POST HARVEST
    try {
      final phRecords = await _supabase
          .from('post_harvest_records')
          .select()
          .eq('visit_id', visitId);
      debugPrint('   ✅ Post-Harvest scaricati: ${phRecords.length}');
      if (phRecords.isNotEmpty) {
        final ph = phRecords.first;
        await _db.upsertPostHarvestRecord(
          id: ph['id'],
          visitId: ph['visit_id'],
          phases: ph['phases'] ?? '[]',
          mbVerifiedProducts: ph['mb_verified_products'] ?? '',
          mbInputData: ph['mb_input_data'] ?? '',
          mbInputDocs: ph['mb_input_docs'] ?? '',
          mbOutputData: ph['mb_output_data'] ?? '',
          mbOutputDocs: ph['mb_output_docs'] ?? '',
          mbComment: ph['mb_comment'] ?? '',
          mbBalances: ph['mb_balances'] ?? '[]',
          traceabilityVerifiedProducts:
              ph['traceability_verified_products'] ?? '',
          updatedAt: ph['updated_at'] != null
              ? DateTime.parse(ph['updated_at'])
              : null,
        );
      }
    } catch (e) {
      debugPrint('!!! ERRORE CRITICO durante il pull dei dettagli: $e');
    }
    debugPrint('--- Deep Pull COMPLETATO per visita: $visitId ---');
  }
}
