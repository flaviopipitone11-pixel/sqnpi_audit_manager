import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final visitsStreamProvider = StreamProvider<List<Visit>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisits();
});

final visitSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredVisitsProvider = Provider<AsyncValue<List<Visit>>>((ref) {
  final visitsAsync = ref.watch(visitsStreamProvider);
  final query = ref.watch(visitSearchQueryProvider).toLowerCase();

  return visitsAsync.whenData((visits) {
    if (query.isEmpty) return visits;
    return visits.where((v) {
      return v.companyName.toLowerCase().contains(query) ||
          v.crop.toLowerCase().contains(query);
    }).toList();
  });
});

class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seedAsync = ref.watch(seedDatabaseProvider);
    final searchQuery = ref.watch(visitSearchQueryProvider);

    if (seedAsync.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Errore inizializzazione:\n${seedAsync.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (seedAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elenco Visite',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) =>
                        ref.read(visitSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Cerca azienda, coltura o luogo...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () =>
                                  ref
                                          .read(
                                            visitSearchQueryProvider.notifier,
                                          )
                                          .state =
                                      '',
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ref
                .watch(filteredVisitsProvider)
                .when(
                  data: (visits) {
                    if (visits.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                searchQuery.isEmpty
                                    ? Icons.calendar_today_outlined
                                    : Icons.search_off_rounded,
                                size: 64,
                                color: Colors.blue.shade200,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              searchQuery.isEmpty
                                  ? 'Nessuna visita in programma'
                                  : 'Nessun risultato trovato',
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isEmpty
                                  ? 'Le visite pianificate appariranno qui.'
                                  : 'Prova a modificare i criteri di ricerca.',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: visits.length,
                      itemBuilder: (context, index) =>
                          _VisitCard(visit: visits[index]),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Errore: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'it_IT');
    final (statusColor, statusLabel) = _getStatusInfo(visit.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/visit/${visit.id}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getStatusIcon(visit.status),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.companyName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visit.crop,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(visit.scheduledAt),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Apri',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(int status) {
    return switch (status) {
      0 => (const Color(0xFFF59E0B), 'Programmata'),
      1 => (const Color(0xFF3B82F6), 'In Corso'),
      2 => (const Color(0xFF059669), 'Completata'),
      3 => (const Color(0xFF64748B), 'Annullata'),
      _ => (const Color(0xFF64748B), 'Sconosciuto'),
    };
  }

  IconData _getStatusIcon(int status) {
    return switch (status) {
      0 => Icons.event_rounded,
      1 => Icons.pending_actions_rounded,
      2 => Icons.check_circle_rounded,
      3 => Icons.cancel_rounded,
      _ => Icons.help_outline_rounded,
    };
  }
}
