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
          await pushVisitToCloud(v.id);
        }
      }

      // 2. PULL: Scarichiamo dal Cloud
      debugPrint('--- SYNC START ---');
      debugPrint('User: $email (Admin: $isAdmin)');

      var query = _supabase.from('visits').select('*, visit_companies(*)');

      // Se NON è admin, filtriamo per email
      if (!isAdmin) {
        query = query.eq('inspector_email', dbEmail);
      }

      final cloudVisits = await query;
      debugPrint('Fetched ${cloudVisits.length} visits from cloud');

      for (final v in cloudVisits) {
        final visitId = v['id'] as String;
        final localVisit = localVisits
            .where((lv) => lv.id == visitId)
            .firstOrNull;

        final cloudUpdatedAt = DateTime.parse(v['updated_at']);

        // PROTEZIONE: Se la versione locale è più recente di quella sul cloud,
        // non sovrascriviamo per evitare di perdere modifiche non ancora inviate.
        if (localVisit != null &&
            localVisit.updatedAt.isAfter(cloudUpdatedAt)) {
          debugPrint('Visita $visitId più recente localmente. Salto il pull.');
          continue;
        }

        final cloudStatus = v['status'] ?? 0;
        final effectiveStatus = VisitStatus.values[cloudStatus];

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
          durationHours: v['duration_hours'] ?? 0,
          durationJustification: v['duration_justification'] ?? '',
          companionName: v['companion_name'] ?? '',
          representativeName: v['representative_name'] ?? '',
          otherOperators: v['other_operators'] ?? '',
          contactedPersons: v['contacted_persons'] ?? '',
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
            referente: c['referente'] ?? '',
            telefono: c['telefono'] ?? '',
            email: c['email'] ?? '',
            pec: c['pec'] ?? '',
            submissionNumber: c['submission_number'] ?? '',
            sqnpiProtocol: c['sqnpi_protocol'] ?? '',
            sqnpiSubmissionDate: c['sqnpi_submission_date'] != null
                ? DateTime.parse(c['sqnpi_submission_date'])
                : null,
            // Campi Revisione 08
            isNewOperator: c['is_new_operator'] ?? false,
            processingType: c['processing_type'] ?? 'proprio',
            thirdPartyCertNumber: c['third_party_cert_number'] ?? '',
            siVerification: c['si_verification'] ?? false,
            manipulationSiteAddress: c['manipulation_site_address'] ?? '',
            manipulationSiteCap: c['manipulation_site_cap'] ?? '',
            manipulationSiteComune: c['manipulation_site_comune'] ?? '',
            manipulationSiteProvincia: c['manipulation_site_provincia'] ?? '',
            peakPeriodFrom: c['peak_period_from'] ?? '',
            peakPeriodTo: c['peak_period_to'] ?? '',
            isJointVisit: c['is_joint_visit'] ?? false,
            jointVisitDetails: c['joint_visit_details'] ?? '',
            marchioNature: c['marchio_nature'] ?? '',
            marchioProcesses: c['marchio_processes'] ?? '',
            marchioLabelDraft: c['marchio_label_draft'] ?? false,
            previousOdcName: c['previous_odc_name'] ?? '',
            previousOdcOutcomes: c['previous_odc_outcomes'] ?? '',
          );
        }

        // 2.2 PULL DETTAGLI PROFONDI (Solo se Admin o se l'ispettore ha bisogno di aggiornamenti dal cloud)
        await _pullVisitDetailsFromCloud(visitId);
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
        'planned_duration_hours': v.plannedDurationHours,
        'last_inspection_date': v.lastInspectionDate?.toIso8601String(),
        'duration_hours': v.durationHours,
        'duration_justification': v.durationJustification,
        'companion_name': v.companionName,
        'representative_name': v.representativeName,
        'other_operators': v.otherOperators,
        'contacted_persons': v.contactedPersons,
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
      await _pushVisitDetailsToCloud(visitId);
    } catch (e) {
      debugPrint('Errore durante il push della visita: $e');
    }
  }

  Future<void> _pushVisitDetailsToCloud(String visitId) async {
    try {
      // 1. UEC
      final uecs = await _db.watchUecsByVisitId(visitId).first;
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

        // 2. LOTTI per questa UEC
        final lots = await _db.watchLotsByUecId(u.id).first;
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

      // 3. RISPOSTE CHECKLIST
      final responses = await _db.watchResponsesByVisitId(visitId).first;
      for (final r in responses) {
        await _supabase.from('checklist_responses').upsert({
          'id': r.id,
          'uec_id': r.uecId,
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

      // 4. CHIUSURA / ESITO
      final closing = await _db.watchClosingByVisitId(visitId).first;
      if (closing != null) {
        await _supabase.from('visit_closings').upsert({
          'visit_id': closing.visitId,
          'corrective_actions': closing.correctiveActions,
          'resolution_deadline': closing.resolutionDeadline?.toIso8601String(),
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

      // 5. FIRME (Metadati)
      final signatures = await _db.watchSignaturesByVisitId(visitId).first;
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

      // 6. NC ANNI PRECEDENTI
      final prevNc = await _db
          .watchPreviousNcManagementByVisitId(visitId)
          .first;
      if (prevNc != null) {
        await _supabase.from('visit_previous_nc_managements').upsert({
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
          'updated_at': prevNc.updatedAt.toIso8601String(),
        });
      }

      // 7. BILANCIO DI MASSA
      final massBalances = await _db.watchMassBalancesByVisitId(visitId).first;
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

      // 8. ALLEGATI (Metadati)
      final attachments = await _db.watchAttachmentsByVisitId(visitId).first;
      for (final a in attachments) {
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

      debugPrint('Deep Push for $visitId completed.');
    } catch (e) {
      debugPrint('Errore durante il deep push: $e');
    }
  }

  Future<void> _pullVisitDetailsFromCloud(String visitId) async {
    try {
      // 1. UEC
      final uecs = await _supabase
          .from('visit_uecs')
          .select()
          .eq('visit_id', visitId);
      for (final u in uecs) {
        await _db.upsertUec(
          id: u['id'],
          visitId: u['visit_id'],
          coltura: u['coltura'],
          descrizione: u['descrizione'],
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

      // 2. LOTTI
      final lots = await _supabase
          .from('visit_lots')
          .select('*, visit_uecs!inner(visit_id)')
          .eq('visit_uecs.visit_id', visitId);
      for (final l in lots) {
        await _db.upsertLot(
          id: l['id'],
          uecId: l['uec_id'],
          codice: l['codice'],
          quantita: l['quantita'],
          note: l['note'] ?? '',
        );
      }

      // 3. RISPOSTE CHECKLIST
      final responses = await _supabase
          .from('checklist_responses')
          .select('*, visit_uecs!inner(visit_id)')
          .eq('visit_uecs.visit_id', visitId);
      for (final r in responses) {
        await _db.upsertResponse(
          uecId: r['uec_id'],
          itemCode: r['item_code'],
          conformita: Conformita.values[r['conformita']],
          livelloKo: r['livello_ko'],
          punteggioUec: r['punteggio_uec'],
          punteggioOperatore: r['punteggio_operatore'],
          rilievoNc: r['rilievo_nc'] ?? '',
          azioneCorrettiva: r['azione_correttiva'] ?? '',
          note: r['note'] ?? '',
        );
      }

      // 4. CHIUSURA / ESITO
      final closings = await _supabase
          .from('visit_closings')
          .select()
          .eq('visit_id', visitId);
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

      // 5. FIRME
      final signatures = await _supabase
          .from('visit_signatures')
          .select()
          .eq('visit_id', visitId);
      for (final s in signatures) {
        await _db.insertSignature(
          visitId: s['visit_id'],
          signatureType: s['signature_type'],
          filePath: s['file_path'],
          signerName: s['signer_name'],
          identityDocPath: s['identity_doc_path'],
        );
      }

      // 6. NC ANNI PRECEDENTI
      final prevNcs = await _supabase
          .from('visit_previous_nc_managements')
          .select()
          .eq('visit_id', visitId);
      if (prevNcs.isNotEmpty) {
        final pn = prevNcs.first;
        await _db.upsertPreviousNcManagement(
          visitId: pn['visit_id'],
          prevNcResults: pn['prev_nc_results'],
          prevNcRequirementsStillKO: pn['prev_nc_requirements_still_ko'] ?? '',
          prevCorrectiveActionsCoherent: pn['prev_corrective_actions_coherent'],
          prevCorrectiveActionsDetails:
              pn['prev_corrective_actions_details'] ?? '',
          prevOrgCertifiedDate: pn['prev_org_certified_date'] ?? '',
          prevOrgSanctionedDate: pn['prev_org_sanctioned_date'] ?? '',
          biosSanctionDetails: pn['bios_sanction_details'] ?? '',
        );
      }

      // 7. BILANCIO DI MASSA
      final massBalances = await _supabase
          .from('mass_balance_records')
          .select()
          .eq('visit_id', visitId);
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

      // 8. ALLEGATI
      final attachments = await _supabase
          .from('visit_attachments')
          .select()
          .eq('visit_id', visitId);
      for (final a in attachments) {
        await _db.insertAttachment(
          visitId: a['visit_id'],
          filePath: a['file_path'],
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

      debugPrint('Deep Pull for $visitId completed.');
    } catch (e) {
      debugPrint('Errore durante il deep pull: $e');
    }
  }
}
