import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/storage/app_database.dart';
import 'checklist_item_helpers.dart';

class VisitValidationError {
  final String section;
  final String message;

  VisitValidationError(this.section, this.message);
}

/// Fornisce l'elenco dei punti obbligatori non ancora compilati per una visita.
final visitValidationProvider =
    StreamProvider.family<List<VisitValidationError>, String>((
      ref,
      visitId,
    ) async* {
      final db = ref.watch(appDatabaseProvider);

      // Watch data streams using the new providers
      final visitAsync = ref.watch(visitProvider(visitId));
      final companyAsync = ref.watch(companyProvider(visitId));
      final uecsAsync = ref.watch(uecsProvider(visitId));
      final closingAsync = ref.watch(closingProvider(visitId));
      final fasiAsync = ref.watch(fasiProvider);
      final responsesAsync = ref.watch(responsesProvider(visitId));

      // If any provider is loading, we wait
      if (visitAsync.isLoading ||
          companyAsync.isLoading ||
          uecsAsync.isLoading ||
          closingAsync.isLoading ||
          fasiAsync.isLoading ||
          responsesAsync.isLoading) {
        return;
      }

      final visit = visitAsync.value;
      final company = companyAsync.value;
      final uecs = uecsAsync.value ?? [];
      final closing = closingAsync.value;
      final allFasi = fasiAsync.value ?? [];
      final allResponses = responsesAsync.value ?? [];

      if (visit == null) {
        yield [VisitValidationError('Sistema', 'Visita non trovata.')];
        return;
      }

      final errors = <VisitValidationError>[];

      // 1. Dati Generali
      if (visit.inspectorName.trim().isEmpty) {
        errors.add(
          VisitValidationError(
            'Riepilogo',
            'Nome dell\'Ispettore RGVI mancante.',
          ),
        );
      }
      if (visit.representativeName.trim().isEmpty) {
        errors.add(
          VisitValidationError(
            'Anagrafica',
            'Nome del Rappresentante Aziendale mancante.',
          ),
        );
      }
      if (visit.durationHours == 0) {
        errors.add(
          VisitValidationError(
            'Riepilogo',
            'Durata della verifica non inserita.',
          ),
        );
      }

      // 2. Anagrafica Azienda
      if (company == null ||
          company.ragioneSociale.trim().isEmpty ||
          company.cuaa.trim().isEmpty ||
          company.partitaIva.trim().isEmpty ||
          company.indirizzo.trim().isEmpty ||
          company.comune.trim().isEmpty ||
          company.cap.trim().isEmpty ||
          company.provincia.trim().isEmpty ||
          company.sedeOperativaIndirizzo.trim().isEmpty ||
          company.sedeOperativaComune.trim().isEmpty ||
          company.sedeOperativaCap.trim().isEmpty ||
          company.sedeOperativaProvincia.trim().isEmpty ||
          company.peakPeriodFrom.trim().isEmpty ||
          company.referente.trim().isEmpty ||
          company.telefono.trim().isEmpty ||
          company.email.trim().isEmpty ||
          company.pec.trim().isEmpty) {
        errors.add(
          VisitValidationError(
            'Anagrafica',
            'Dati aziendali obbligatori (*) incompleti.',
          ),
        );
      } else {
        if (company.isJointVisit && company.jointVisitDetails.trim().isEmpty) {
          errors.add(
            VisitValidationError(
              'Anagrafica',
              'Dettagli visita congiunta mancanti.',
            ),
          );
        }
        if (company.isNewOperator &&
            (company.previousOdcName.trim().isEmpty ||
                company.previousOdcOutcomes.trim().isEmpty)) {
          errors.add(
            VisitValidationError(
              'Anagrafica',
              'Dati OdC precedente incompleti.',
            ),
          );
        }
      }

      // 3. Marchio (se applicabile)
      if (visit.visitType.contains('MARCHIO')) {
        if (company == null ||
            company.marchioNature.trim().isEmpty ||
            company.marchioProcesses.trim().isEmpty) {
          errors.add(
            VisitValidationError(
              'Scopo Controllo',
              'Dati specifici Marchio incompleti.',
            ),
          );
        }
      }

      // 4. Checklist & UECs
      final visitType = visit.visitType;
      final filteredFasi = allFasi
          .where((f) => ChecklistItemHelpers.isPhaseVisible(f, visitType))
          .toList();

      if (filteredFasi.isNotEmpty) {
        // Fetch all requirements for these phases
        final requirements = <ChecklistItem>[];
        for (final fase in filteredFasi) {
          final items = await db.watchChecklistItemsByFase(fase).first;
          requirements.addAll(
            items.where((it) {
              final code = it.code.trim();
              return !(!code.contains('.') ||
                  RegExp(r'\.0$').hasMatch(code) ||
                  RegExp(r'\.(?!\d)').hasMatch(code));
            }),
          );
        }

        final responseMap =
            <String, Set<String>>{}; // uecId -> Set of itemCodes
        for (final r in allResponses) {
          responseMap.putIfAbsent(r.uecId, () => {}).add(r.itemCode);
        }

        bool checklistIncomplete = false;
        bool sqnpiOutcomesIncomplete = false;

        for (final uec in uecs) {
          final uecResponses = responseMap[uec.id] ?? {};
          final isComplete = requirements.every(
            (r) => uecResponses.contains(r.code),
          );

          if (!isComplete) {
            checklistIncomplete = true;
          } else {
            if (uec.sqnpiConsistency.isEmpty || uec.sqnpiCompliance.isEmpty) {
              sqnpiOutcomesIncomplete = true;
            }
          }
        }

        if (checklistIncomplete) {
          errors.add(
            VisitValidationError(
              'Checklist',
              'Una o più UEC hanno la checklist incompleta.',
            ),
          );
        }
        if (sqnpiOutcomesIncomplete) {
          errors.add(
            VisitValidationError(
              'Colture/UEC',
              'Mancano gli esiti SQNPI per alcune UEC (Coerenza/Conformità).',
            ),
          );
        }
      }

      // 5. Chiusura & Valutazione Finale
      if (closing == null ||
          closing.cap5Adherence == 0 ||
          (closing.cap5Adherence == 2 &&
              closing.cap5SpecificCrops.trim().isEmpty) ||
          closing.inspectionMethods.isEmpty ||
          closing.inspectionMethods == '[]' ||
          closing.representativePresent == 0 ||
          closing.finalOutcome == 0 ||
          (closing.finalOutcome == 2 &&
              closing.provisionDetail.trim().isEmpty) ||
          closing.resolutionDeadline == null) {
        errors.add(
          VisitValidationError(
            'Esito/Chiusura',
            'Dati di chiusura o valutazione finale incompleti.',
          ),
        );
      }

      yield errors;
    });
