import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/widgets/radio_group.dart';
import '../../../core/widgets/help_tooltip.dart';
import '../../../core/constants/help_texts.dart';

final closingByVisitIdProvider = StreamProvider.family<VisitClosing?, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchClosingByVisitId(visitId);
});

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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _provisionController = TextEditingController();
    _reservationsController = TextEditingController();
  }

  @override
  void dispose() {
    _provisionController.dispose();
    _reservationsController.dispose();
    super.dispose();
  }

  void _loadData(VisitClosing? closing) {
    if (_loaded || closing == null) return;
    _provisionController.text = closing.provisionDetail;
    _reservationsController.text = closing.representativeReservations;
    _loaded = true;
  }

  void _saveField(String field, dynamic value) {
    if (widget.isReadOnly) return;
    final db = ref.read(appDatabaseProvider);
    final current = ref
        .read(closingByVisitIdProvider(widget.visitId))
        .valueOrNull;

    db.upsertClosing(
      visitId: widget.visitId,
      correctiveActions: current?.correctiveActions ?? '',
      resolutionDeadline: current?.resolutionDeadline,
      isClosed: current?.isClosed ?? false,
      finalOutcome: field == 'finalOutcome' ? value : current?.finalOutcome,
      provisionDetail: field == 'provisionDetail'
          ? value
          : current?.provisionDetail,
      representativeReservations: field == 'representativeReservations'
          ? value
          : current?.representativeReservations,
      // Maintain other fields
      cap5Adherence: current?.cap5Adherence,
      cap5SpecificCrops: current?.cap5SpecificCrops,
      commitmentToRectify: current?.commitmentToRectify,
      inspectionMethods: current?.inspectionMethods,
      representativePresent: current?.representativePresent,
      isOutcomeFormalized: current?.isOutcomeFormalized,
      verificationNotes: current?.verificationNotes,
      finalRecommendation: current?.finalRecommendation,
      inspectorFinalComment: current?.inspectorFinalComment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final closingAsync = ref.watch(closingByVisitIdProvider(widget.visitId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: closingAsync.when(
        data: (closing) {
          _loadData(closing);
          final isMobile = MediaQuery.sizeOf(context).width < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 48,
              vertical: 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Headers
                    Text(
                      'VALUTAZIONE FINALE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                        color: Colors.grey.shade800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'In riferimento al campo di applicazione dell\'attività di verifica ispettiva',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Ritenuto quanto valutato rappresentativo delle attività effettuate dall\'Organizzazione',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Selection Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Si ritiene l\'Organizzazione: *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (HelpTexts.get('Esito') != null) ...[
                                const SizedBox(width: 8),
                                HelpTooltip(text: HelpTexts.get('Esito')!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          CustomRadioGroup<int>(
                            groupValue: closing?.finalOutcome ?? 0,
                            onChanged: (v) => _saveField('finalOutcome', v),
                            child: Column(
                              children: [
                                _buildStyledRadioOption(
                                  label:
                                      'Conforme - per i prodotti indicati (vedi sezione dettaglio prodotti e attività)',
                                  value: 1,
                                  currentValue: closing?.finalOutcome ?? 0,
                                ),
                                _buildStyledRadioOption(
                                  label:
                                      'Proposta provvedimento secondo la procedura di adesione, gestione e controllo nell\'ambito SQNPI applicabile (esclusione lotto, sospensione del processo di certificazione aziendale, esclusione azienda),',
                                  value: 2,
                                  currentValue: closing?.finalOutcome ?? 0,
                                ),
                                if ((closing?.finalOutcome ?? 0) == 2)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 48,
                                      top: 12,
                                      bottom: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'INDICARE:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            if (HelpTexts.get(
                                                  'Proposta provvedimento',
                                                ) !=
                                                null) ...[
                                              const SizedBox(width: 8),
                                              HelpTooltip(
                                                text: HelpTexts.get(
                                                  'Proposta provvedimento',
                                                )!,
                                                size: 14,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: _provisionController,
                                          enabled: !widget.isReadOnly,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                            border: UnderlineInputBorder(),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          onChanged: (v) =>
                                              _saveField('provisionDetail', v),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'allo Standard di certificazione SQNPI',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 56),

                    // Standard Disclaimers Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1.5,
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

                    const SizedBox(height: 56),

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
                            maxLines: 5,
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
                                _saveField('representativeReservations', v),
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
