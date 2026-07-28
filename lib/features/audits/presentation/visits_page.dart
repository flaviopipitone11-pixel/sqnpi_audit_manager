import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/audits_repository.dart';
import '../../../core/widgets/sync_log_dialog.dart';
import 'navigation_providers.dart';

final visitsStreamProvider = StreamProvider<List<Visit>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authControllerProvider);

  if (!auth.isAuthenticated || auth.username == null) {
    return Stream.value([]);
  }

  return db.watchVisitsByEmail(auth.username!);
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

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  // int? _selectedStatus; // null = all - RIMOSSO: ora usiamo visitFilterStatusProvider

  Future<void> _handleSync() async {
    final auth = ref.read(authControllerProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Sincronizzazione in corso...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'L\'operazione potrebbe richiedere qualche minuto.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final logs = await ref
          .read(auditsRepositoryProvider)
          .syncWithCloud(
            auth.username ?? '',
            isAdmin: auth.isAdmin,
            inspectorCode: auth.inspectorCode,
          );

      if (!mounted) return;

      // Chiude il loader
      Navigator.of(context).pop();

      // Refresh dati
      ref.invalidate(visitsStreamProvider);

      // Mostra i log
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => SyncLogDialog(logs: logs),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Chiude il loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore critico sync: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final seedAsync = ref.watch(seedDatabaseProvider);
    final searchQuery = ref.watch(visitSearchQueryProvider);
    final visitsAsync = ref.watch(filteredVisitsProvider);

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
      backgroundColor: const Color(0xFFE2E8F0), // Slate 100
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
          Container(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width > 600 ? 32 : 16,
              MediaQuery.of(context).orientation == Orientation.landscape
                  ? 16
                  : 40,
              MediaQuery.of(context).size.width > 600 ? 32 : 16,
              24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visite Ispettive',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -1.2,
                            ),
                          ),
                          Text(
                            'Gestione e pianificazione controlli SQNPI',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        _buildStats(visitsAsync),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _handleSync(),
                          icon: const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF1E293B),
                            size: 22,
                          ),
                          tooltip: 'Sincronizza ora',
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              ref
                                      .read(visitSearchQueryProvider.notifier)
                                      .state =
                                  val,
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
                                                  visitSearchQueryProvider
                                                      .notifier,
                                                )
                                                .state =
                                            '',
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'Tutte'),
                      _filterChip(0, 'Programmate'),
                      _filterChip(1, 'In Corso'),
                      _filterChip(2, 'Completate'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: visitsAsync.when(
              data: (allVisits) {
                final selectedStatus = ref.watch(visitFilterStatusProvider);
                final visits = allVisits.where((v) {
                  if (selectedStatus != null && v.status != selectedStatus) {
                    return false;
                  }
                  return true;
                }).toList();

                if (visits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            searchQuery.isEmpty && selectedStatus == null
                                ? Icons.calendar_today_outlined
                                : Icons.search_off_rounded,
                            size: 80,
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          searchQuery.isEmpty && selectedStatus == null
                              ? 'Nessuna visita in programma'
                              : 'Nessun risultato trovato',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty && selectedStatus == null
                              ? 'Le visite pianificate appariranno qui.'
                              : 'Prova a modificare i filtri o la ricerca.',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width > 600 ? 32 : 16,
                    24,
                    MediaQuery.of(context).size.width > 600 ? 32 : 16,
                    40,
                  ),
                  itemCount: visits.length,
                  itemBuilder: (context, index) =>
                      _VisitCard(visit: visits[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _filterChip(int? status, String label) {
    final selectedStatus = ref.watch(visitFilterStatusProvider);
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          ref.read(visitFilterStatusProvider.notifier).state = status;
        },
        selectedColor: const Color(0xFF059669),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: const Color(0xFFE2E8F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildStats(AsyncValue<List<Visit>> visitsAsync) {
    return visitsAsync.maybeWhen(
      data: (visits) {
        final completed = visits.where((v) => v.status == 2).length;
        final total = visits.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed',
                      style: const TextStyle(
                        color: Color(0xFF064E3B),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: '/$total',
                      style: TextStyle(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _VisitCard extends ConsumerWidget {
  final Visit visit;

  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'it_IT');
    final (statusColor, statusLabel) = _getStatusInfo(visit.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/visit/${visit.id}'),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.of(context).size.width > 600 ? 24 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getStatusIcon(visit.status),
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.companyName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.indigo,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visit.crop,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (visit.visitType.contains('Auto-creato') ||
                        visit.id.startsWith('V-USR-'))
                      IconButton(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        tooltip: 'Elimina visita',
                      ),
                    const SizedBox(width: 8),
                    MediaQuery.of(context).size.width > 500
                        ? _StatusBadge(color: statusColor, label: statusLabel)
                        : const SizedBox.shrink(),
                  ],
                ),
                if (MediaQuery.of(context).size.width <= 500) ...[
                  const SizedBox(height: 12),
                  _StatusBadge(color: statusColor, label: statusLabel),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(visit.scheduledAt),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            MediaQuery.of(context).size.width > 360
                                ? 'Visualizza Dettagli'
                                : 'Dettagli',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.indigo,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Elimina Visita',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sei sicuro di voler procedere? Tutti i dati della visita e i file allegati verranno eliminati definitivamente sia dal dispositivo che dal cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blueGrey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.blueGrey.shade100),
                      ),
                      child: Text(
                        'ANNULLA',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'ELIMINA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final db = ref.read(appDatabaseProvider);
      final repo = ref.read(auditsRepositoryProvider);
      final scaffold = ScaffoldMessenger.of(context);

      try {
        // Elimina localmente
        await db.deleteVisit(visit.id);

        // Elimina dal Cloud (se possibile)
        await repo.deleteVisitFromCloud(visit.id);

        scaffold.showSnackBar(
          const SnackBar(content: Text('Visita eliminata correttamente.')),
        );
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
        );
      }
    }
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

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
