import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/widgets/radio_group.dart';
import '../../../core/widgets/help_tooltip.dart';
import '../../../core/constants/help_texts.dart';

class FinalEvaluationPage extends ConsumerStatefulWidget {
  final String visitId;
  final bool isReadOnly;

  const FinalEvaluationPage({
    super.key,
    required this.visitId,
    required this.isReadOnly,
  });

  @override
  ConsumerState<FinalEvaluationPage> createState() =>
      _FinalEvaluationPageState();
}

class _FinalEvaluationPageState extends ConsumerState<FinalEvaluationPage> {
  late TextEditingController _provisionController;
  late TextEditingController _reservationsController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _provisionController = TextEditingController();
    _reservationsController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _provisionController.dispose();
    _reservationsController.dispose();
    super.dispose();
  }

  void _saveField(String field, dynamic value) {
    if (widget.isReadOnly) return;
    final db = ref.read(appDatabaseProvider);
    final closingAsync = ref.read(closingProvider(widget.visitId));

    closingAsync.whenData((current) {
      db.upsertClosing(
        visitId: widget.visitId,
        correctiveActions: current?.correctiveActions ?? '',
        resolutionDeadline: current?.resolutionDeadline,
        finalOutcome: field == 'finalOutcome'
            ? value
            : (current?.finalOutcome ?? 0),
        provisionDetail: field == 'provisionDetail'
            ? value
            : (current?.provisionDetail ?? ''),
        representativeReservations: field == 'representativeReservations'
            ? value
            : (current?.representativeReservations ?? ''),
        // Mantain existing administrative fields
        cap5Adherence: current?.cap5Adherence ?? 0,
        cap5SpecificCrops: current?.cap5SpecificCrops ?? '',
        commitmentToRectify: current?.commitmentToRectify ?? 0,
        inspectionMethods: current?.inspectionMethods ?? '[]',
        representativePresent: current?.representativePresent ?? 0,
        isOutcomeFormalized: current?.isOutcomeFormalized ?? false,
        verificationNotes: current?.verificationNotes ?? '',
      );
    });
  }

  void _debouncedSave(String field, dynamic value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _saveField(field, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final closingAsync = ref.watch(closingProvider(widget.visitId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: closingAsync.when(
        data: (closing) {
          if (_provisionController.text.isEmpty &&
              closing?.provisionDetail != null) {
            _provisionController.text = closing!.provisionDetail;
          }
          if (_reservationsController.text.isEmpty &&
              closing?.representativeReservations != null) {
            _reservationsController.text = closing!.representativeReservations;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Colors.indigo.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valutazione Finale',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Esito complessivo della verifica ispettiva',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Evaluation Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Si ritiene l\'Organizzazione:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomRadioGroup<int>(
                            groupValue: closing?.finalOutcome ?? 0,
                            onChanged: widget.isReadOnly
                                ? null
                                : (v) => _saveField('finalOutcome', v),
                            child: Column(
                              children: [
                                _buildStyledRadioOption(
                                  label: 'CONFORME allo Standard SQNPI',
                                  value: 1,
                                  currentValue: closing?.finalOutcome ?? 0,
                                ),
                                _buildStyledRadioOption(
                                  label:
                                      'NON CONFORME allo Standard SQNPI per i motivi di seguito riportati:',
                                  value: 2,
                                  currentValue: closing?.finalOutcome ?? 0,
                                ),
                              ],
                            ),
                          ),
                          if ((closing?.finalOutcome ?? 0) == 2) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: TextField(
                                controller: _provisionController,
                                maxLines: null,
                                minLines: 4,
                                keyboardType: TextInputType.multiline,
                                enabled: !widget.isReadOnly,
                                decoration: InputDecoration(
                                  hintText:
                                      'Dettagliare i motivi della non conformità...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                onChanged: (v) =>
                                    _debouncedSave('provisionDetail', v),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Viene rilasciata all\'Organizzazione copia del presente report di verifica ispettiva con dettagli relativi ai rilievi effettuati (qualora applicabile)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Il presente rapporto di verifica ispettiva viene sottoscritto per accettazione dal responsabile dell\'Organizzazione – qualora applicabile, in relazione al livello di conformità raggiunto, viene ribadito il livello delle sanzioni stabilite dallo standard SQNPI e le relative tempistiche per la risoluzione. Questo rapporto di verifica ispettiva è soggetto a riesame da parte della direzione della Bios srl.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Reservations Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Eventuali riserve (da parte del responsabile dell\'Organizzazione)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (HelpTexts.get('Riserve') != null) ...[
                                const SizedBox(width: 8),
                                HelpTooltip(
                                  text: HelpTexts.get('Riserve')!,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _reservationsController,
                            maxLines: null,
                            minLines: 5,
                            keyboardType: TextInputType.multiline,
                            enabled: !widget.isReadOnly,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Inserire eventuali riserve...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (v) =>
                                _debouncedSave('representativeReservations', v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Errore: $e')),
      ),
    );
  }

  Widget _buildStyledRadioOption({
    required String label,
    required int value,
    required int currentValue,
  }) {
    final isSelected = value == currentValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomRadioOption<int>(label: label, value: value),
    );
  }
}
