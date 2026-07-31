import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/storage/app_database.dart';
import 'checklist_item_helpers.dart';

class VisitValidationError {
  final String section;
  final String message;
  final String? firstMissingCode;

  VisitValidationError(this.section, this.message, {this.firstMissingCode});
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
      final attachmentsAsync = ref.watch(attachmentsProvider(visitId));

      // If any provider is loading, we wait
      if (visitAsync.isLoading ||
          companyAsync.isLoading ||
          uecsAsync.isLoading ||
          closingAsync.isLoading ||
          fasiAsync.isLoading ||
          responsesAsync.isLoading ||
          attachmentsAsync.isLoading) {
        return;
      }

      final visit = visitAsync.value;
      final company = companyAsync.value;
      final allUecs = uecsAsync.value ?? [];
      final uecs = allUecs
          .where((u) => u.coltura.trim().toUpperCase() != 'OPERATORE')
          .toList();
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

      // 1.1 Validazione Delegato
      if (visit.isRepresentativeDelegate) {
        if (visit.representativeDelegateDetails.trim().isEmpty) {
          errors.add(
            VisitValidationError(
              'Riepilogo',
              'Dettagli delegato mancanti (Nome, Cognome, Note).',
            ),
          );
        }
        final hasDelega = (attachmentsAsync.value ?? []).any(
          (a) => a.attachmentType == 'DELEGA',
        );
        if (!hasDelega) {
          errors.add(
            VisitValidationError(
              'Riepilogo',
              'Documento di delega non caricato.',
            ),
          );
        }
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
            <
              String,
              Map<String, ChecklistResponse>
            >{}; // uecId -> itemCode -> response
        for (final r in allResponses) {
          responseMap.putIfAbsent(r.uecId, () => {})[r.itemCode] = r;
        }

        String? firstMissingCode;
        final incompleteDetails = <String>[];
        final outcomesIncompleteUecNames = <String>[];

        for (final uec in uecs) {
          final uecResponses = responseMap[uec.id] ?? {};

          final itemsMissingData = requirements.where((r) {
            final resp = uecResponses[r.code];
            if (resp == null) return false;

            // NA (1) -> Note mandatory
            if (resp.conformita == 1 && resp.note.trim().isEmpty) {
              return true;
            }

            // KO (2) -> Rilievo mandatory
            if (resp.conformita == 2 && resp.rilievoNc.trim().isEmpty) {
              return true;
            }

            return false;
          }).toList();

          if (itemsMissingData.isNotEmpty) {
            final codes = itemsMissingData.map((r) => r.code).toList();
            firstMissingCode ??= codes.first;

            final display = codes.take(5).join(", ");
            final suffix = codes.length > 5 ? "..." : "";

            incompleteDetails.add(
              "${uec.coltura} (mancano dati su: $display$suffix)",
            );
          } else {
            final isUecIncomplete =
                uec.sqnpiConsistency.isEmpty ||
                uec.sqnpiCompliance.isEmpty ||
                (uec.foundProduct ?? '').trim().isEmpty ||
                (uec.fieldProcessDetails ?? '').trim().isEmpty ||
                (uec.hasSampling && (uec.samplingLotId ?? '').trim().isEmpty);

            if (isUecIncomplete) {
              outcomesIncompleteUecNames.add(uec.coltura);
            }
          }
        }

        if (incompleteDetails.isNotEmpty) {
          errors.add(
            VisitValidationError(
              'Checklist',
              'Compilazione note richiesta: ${incompleteDetails.join(" | ")}',
              firstMissingCode: firstMissingCode,
            ),
          );
        }
        if (outcomesIncompleteUecNames.isNotEmpty) {
          errors.add(
            VisitValidationError(
              'Coltivazione',
              'Dati obbligatori mancanti (Coerenza, Conformità, Prodotto, Processo o Lotto) per: ${outcomesIncompleteUecNames.join(", ")}',
            ),
          );
        }
      }

      // 5. Chiusura & Valutazione Finale
      final missingFields = <String>[];
      if (visit.plannedDurationHours > 0 &&
          visit.durationHours != visit.plannedDurationHours &&
          visit.durationJustification.trim().isEmpty) {
        missingFields.add(
          visit.durationHours < visit.plannedDurationHours
              ? 'Giustificativo Riduzione Ore'
              : 'Giustificativo Sforamento Ore',
        );
      }
      if (closing == null || closing.finalOutcome == 0) {
        missingFields.add('Esito Finale');
      }
      if (closing?.finalOutcome == 2 &&
          (closing?.provisionDetail.trim().isEmpty ?? true)) {
        missingFields.add('Motivi Non Conformità');
      }
      if (closing == null || closing.cap5Adherence == 0) {
        missingFields.add('Rispetto Cap. 5');
      }
      if (closing?.cap5Adherence == 2 &&
          (closing?.cap5SpecificCrops.trim().isEmpty ?? true)) {
        missingFields.add('Specifica colture Cap. 5');
      }
      if (closing == null ||
          closing.inspectionMethods.isEmpty ||
          closing.inspectionMethods == '[]') {
        missingFields.add('Metodi di ispezione');
      }
      if (closing == null || closing.representativePresent == 0) {
        missingFields.add('Presenza Rappresentante');
      }

      if (missingFields.isNotEmpty) {
        errors.add(
          VisitValidationError(
            'Esito/Chiusura',
            'Campi obbligatori mancanti: ${missingFields.join(", ")}.',
          ),
        );
      }

      yield errors;
    });
