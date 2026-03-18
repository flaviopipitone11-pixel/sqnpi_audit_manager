import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final nonConformitaByVisitProvider =
    StreamProvider.family<
      List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>,
      String
    >((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchNonConformitaByVisit(visitId);
    });

class NcPage extends ConsumerWidget {
  const NcPage({super.key, required this.visitId, this.isReadOnly = false});
  final String visitId;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ncAsync = ref.watch(nonConformitaByVisitProvider(visitId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Non Conformità (NC)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Riepilogo delle non conformità rilevate durante la visita.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ncAsync.when(
                  data: (ncs) {
                    if (ncs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nessuna Non Conformità rilevata!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Compila la checklist per registrare eventuali NC.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: ncs.length,
                      itemBuilder: (context, index) {
                        final nc = ncs[index];
                        final item = nc.item;
                        final resp = nc.response;
                        final uec = nc.uec;

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red.shade200,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Requisito KO',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                          'UEC: ${uec.nAggregato.isNotEmpty ? uec.nAggregato : uec.id} (${uec.coltura})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${item.code} — ${item.obbligo}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Livello KO',
                                  value:
                                      resp.livelloKo?.toString() ??
                                      'Non specificato',
                                ),
                                _DetailRow(
                                  icon: Icons.score,
                                  title: 'Punteggio UEC/Lotto',
                                  value:
                                      resp.punteggioUec?.toString() ??
                                      'Nessuno',
                                ),
                                _DetailRow(
                                  icon: Icons.person_off,
                                  title: 'Punteggio Operatore',
                                  value:
                                      resp.punteggioOperatore?.toString() ??
                                      'Nessuno',
                                ),
                                _DetailRow(
                                  icon: Icons.speaker_notes,
                                  title: 'Descrizione',
                                  value: resp.rilievoNc.isNotEmpty
                                      ? resp.rilievoNc
                                      : 'Nessuna descrizione inserito',
                                ),
                                _DetailRow(
                                  icon: Icons.note_alt_outlined,
                                  title: 'Azione correttiva ( a cura dell\'operatore)',
                                  value: resp.note.isNotEmpty
                                      ? resp.note
                                      : 'Nessuna azione correttiva inserita',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Errore: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
