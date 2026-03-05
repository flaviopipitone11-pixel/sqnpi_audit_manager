import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final visitsStreamProvider = StreamProvider<List<Visit>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisits();
});

class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seed una sola volta (import checklist + seed visite)
    final seedAsync = ref.watch(seedDatabaseProvider);

    // 1) Se seed fallisce, fermiamo la UI qui e mostriamo l'errore
    if (seedAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Errore durante inizializzazione DB / import checklist:\n${seedAsync.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 2) Finché seed è in corso, spinner (evita race con la stream visite)
    if (seedAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 3) Seed ok -> ora possiamo leggere le visite
    final visitsAsync = ref.watch(visitsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elenco Visite',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
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
              clipBehavior: Clip.antiAlias,
              child: visitsAsync.when(
                data: (visits) {
                  if (visits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessuna visita presente.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 64,
                        horizontalMargin: 24,
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text('Data')),
                          DataColumn(label: Text('Azienda')),
                          DataColumn(label: Text('Coltura')),
                          DataColumn(label: Text('Stato')),
                          DataColumn(label: Text('')), // Azioni
                        ],
                        rows: visits.map((v) {
                          final dateStr =
                              '${v.scheduledAt.day.toString().padLeft(2, '0')}/'
                              '${v.scheduledAt.month.toString().padLeft(2, '0')}/'
                              '${v.scheduledAt.year} '
                              '${v.scheduledAt.hour.toString().padLeft(2, '0')}:'
                              '${v.scheduledAt.minute.toString().padLeft(2, '0')}';

                          Color statusColor;
                          switch (v.status) {
                            case 0:
                              statusColor = Colors.orange;
                              break;
                            case 1:
                              statusColor = Colors.blue;
                              break;
                            case 2:
                              statusColor = Colors.green;
                              break;
                            case 3:
                              statusColor = Colors.grey;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  dateStr,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              DataCell(
                                Text(
                                  v.companyName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  v.crop,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    visitStatusLabel(v.status).toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.tonal(
                                    onPressed: () =>
                                        context.go('/visit/${v.id}'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF2D6A4F,
                                      ).withValues(alpha: 0.1),
                                      foregroundColor: const Color(0xFF1B4332),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Apri'),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Errore caricamento visite: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
