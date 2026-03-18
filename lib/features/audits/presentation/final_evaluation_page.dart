import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/domain/visit_outcome.dart';
import '../../../core/widgets/radio_group.dart';
import 'nc_page.dart' show AdministrativeSection;

final closingByVisitIdProvider = StreamProvider.family<VisitClosing?, String>((ref, visitId) {
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
  ConsumerState<FinalEvaluationPage> createState() => _FinalEvaluationPageState();
}

class _FinalEvaluationPageState extends ConsumerState<FinalEvaluationPage> {
  late TextEditingController _commentController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadData(VisitClosing? closing) {
    if (_loaded || closing == null) return;
    _commentController.text = closing.inspectorFinalComment;
    _loaded = true;
  }

  void _saveField(String field, dynamic value) {
    if (widget.isReadOnly) return;
    final db = ref.read(appDatabaseProvider);
    final current = ref.read(closingByVisitIdProvider(widget.visitId)).valueOrNull;
    
    db.upsertClosing(
      visitId: widget.visitId,
      correctiveActions: current?.correctiveActions ?? '',
      resolutionDeadline: current?.resolutionDeadline,
      isClosed: current?.isClosed ?? false,
      finalRecommendation: field == 'finalRecommendation' ? value : current?.finalRecommendation,
      inspectorFinalComment: field == 'inspectorFinalComment' ? value : current?.inspectorFinalComment,
      // Maintain other fields
      cap5Adherence: current?.cap5Adherence,
      cap5SpecificCrops: current?.cap5SpecificCrops,
      commitmentToRectify: current?.commitmentToRectify,
      inspectionMethods: current?.inspectionMethods,
      representativePresent: current?.representativePresent,
      isOutcomeFormalized: current?.isOutcomeFormalized,
      verificationNotes: current?.verificationNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final closingAsync = ref.watch(closingByVisitIdProvider(widget.visitId));
    final outcomeAsync = ref.watch(visitOutcomeSummaryProvider(widget.visitId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: closingAsync.when(
        data: (closing) {
          _loadData(closing);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VALUTAZIONE FINALE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sintesi dell\'ispezione e raccomandazione finale per l\'OdC (M904 Rev. 08)',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Calculated Outcome Summary Card
                outcomeAsync.when(
                  data: (outcome) => _OutcomeSummaryCard(outcome: outcome),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                AdministrativeSection(
                  title: 'Raccomandazione finale dell\'Ispettore',
                  child: CustomRadioGroup<int>(
                    groupValue: closing?.finalRecommendation ?? 0,
                    onChanged: (v) => _saveField('finalRecommendation', v),
                    child: const Column(
                      children: [
                        CustomRadioOption(label: 'N/A', value: 0),
                        CustomRadioOption(label: 'Certificabile', value: 1),
                        CustomRadioOption(label: 'Certificabile con prescrizioni', value: 2),
                        CustomRadioOption(label: 'Non Certificabile', value: 3),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                AdministrativeSection(
                  title: 'Note e osservazioni finali',
                  child: TextField(
                    controller: _commentController,
                    maxLines: 6,
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(
                      hintText: 'Inserire eventuali osservazioni conclusive...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (v) => _saveField('inspectorFinalComment', v),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}

class _OutcomeSummaryCard extends StatelessWidget {
  final VisitOutcomeSummary outcome;
  const _OutcomeSummaryCard({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final color = outcome.isEsitoFavorevole ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              outcome.isEsitoFavorevole ? Icons.check_circle_outline : Icons.error_outline,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esito Calcolato Automaticamente',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  outcome.isEsitoFavorevole ? 'CONFORME' : 'NON CONFORME',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  'Punteggio Operatore: ${outcome.sumOperatoreTotale}  •  Dettagli NC in Riepilogo Attività',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
