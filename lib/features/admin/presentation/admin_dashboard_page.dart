import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../audits/data/audits_repository.dart';
import '../../../core/widgets/sync_log_dialog.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../application/alerts_provider.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final adminSearchQueryProvider = StateProvider<String>((ref) => '');
final adminStatusFilterProvider = StateProvider<int?>((ref) => null);

final filteredAdminVisitsProvider =
    Provider<AsyncValue<List<VisitWithCompany>>>((ref) {
      final visitsAsync = ref.watch(visitsWithCompanyProvider);
      final query = ref.watch(adminSearchQueryProvider).toLowerCase();
      final statusFilter = ref.watch(adminStatusFilterProvider);

      return visitsAsync.whenData((visits) {
        return visits.where((v) {
          final matchesQuery =
              v.visit.companyName.toLowerCase().contains(query) ||
              v.visit.crop.toLowerCase().contains(query) ||
              v.visit.inspectorName.toLowerCase().contains(query);

          final matchesStatus =
              statusFilter == null || v.visit.status == statusFilter;

          return matchesQuery && matchesStatus;
        }).toList();
      });
    });

final inspectorNcCountsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(auditsRepositoryProvider).watchNcCountsByInspector();
});

class InspectorStats {
  final String name;
  final int completedVisits;
  final int totalNCs;
  final double avgDuration;

  InspectorStats({
    required this.name,
    required this.completedVisits,
    required this.totalNCs,
    required this.avgDuration,
  });

  double get avgNCs => completedVisits == 0 ? 0 : totalNCs / completedVisits;
}

final inspectorStatsProvider = Provider<AsyncValue<List<InspectorStats>>>((
  ref,
) {
  final visitsAsync = ref.watch(visitsWithCompanyProvider);
  final ncCountsAsync = ref.watch(inspectorNcCountsProvider);

  return visitsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (allVisits) {
      return ncCountsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
        data: (ncCounts) {
          final statsMap = <String, List<Visit>>{};
          for (final v in allVisits) {
            final name = v.visit.inspectorName;
            if (name.isEmpty) continue;
            statsMap.putIfAbsent(name, () => []).add(v.visit);
          }

          final statsList = statsMap.entries.map((entry) {
            final name = entry.key;
            final visits = entry.value;
            final completed = visits.where((v) => v.status >= 2).toList();

            double totalHours = 0;
            for (final v in completed) {
              totalHours += v.durationHours.toDouble();
            }

            return InspectorStats(
              name: name,
              completedVisits: completed.length,
              totalNCs: ncCounts[name] ?? 0,
              avgDuration: completed.isEmpty
                  ? 0
                  : totalHours / completed.length,
            );
          }).toList();

          statsList.sort(
            (a, b) => b.completedVisits.compareTo(a.completedVisits),
          );
          return AsyncValue.data(statsList);
        },
      );
    },
  );
});

final broadcastMessagesProvider = StreamProvider<List<BroadcastMessage>>((ref) {
  final auth = ref.watch(authControllerProvider);
  final db = ref.watch(appDatabaseProvider);

  return db.watchBroadcastMessages().map((messages) {
    // L'admin vede sempre tutto lo storico inviato
    if (auth.isAdmin) return messages;

    // L'ispettore vede solo i messaggi globali o quelli indirizzati a lui
    final myEmail = auth.username?.toLowerCase();
    return messages.where((m) {
      if (m.targetEmails == null || m.targetEmails!.isEmpty) return true;
      final targets = m.targetEmails!.split(',');
      return targets.contains(myEmail);
    }).toList();
  });
});

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAutoSync();
    });
  }

  Future<void> _performAutoSync() async {
    final auth = ref.read(authControllerProvider);
    if (auth.username == null) return;

    try {
      await ref
          .read(auditsRepositoryProvider)
          .syncWithCloud(
            auth.username!,
            isAdmin: true,
            inspectorCode: auth.inspectorCode,
          );
    } catch (e) {
      debugPrint('Admin Auto-Sync Error: $e');
    }
  }

  Future<void> _handleGlobalSync() async {
    final auth = ref.read(authControllerProvider);
    if (auth.username == null) return;

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
                  'Sincronizzazione Globale...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Recupero dati di tutti gli ispettori.',
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
            auth.username!,
            isAdmin: true,
            inspectorCode: auth.inspectorCode,
          );

      if (!mounted) return;

      // Chiude il loader
      Navigator.of(context).pop();

      // Refresh dati
      ref.invalidate(visitsWithCompanyProvider);

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
          content: Text('Errore sync admin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final visitsAsync = ref.watch(visitsWithCompanyProvider);
    final filteredVisitsAsync = ref.watch(filteredAdminVisitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.dashboard_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PANNELLO ADMIN',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              auth.username ?? 'Amministratore',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    MediaQuery.of(context).size.width < 600
                                    ? 18
                                    : 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _handleGlobalSync,
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        tooltip: 'Sincronizza tutto',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (allVisits) {
          int totalVisits = allVisits.length;
          int completed = allVisits.where((v) => v.visit.status >= 2).length;
          int inProgress = allVisits.where((v) => v.visit.status == 1).length;
          int activeInspectors = allVisits
              .map((v) => v.visit.inspectorName)
              .where((name) => name.isNotEmpty)
              .toSet()
              .length;
          if (activeInspectors == 0 && totalVisits > 0) activeInspectors = 1;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).size.width < 600 ? 190 : 220,
              24,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panoramica Generale',
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Monitoraggio in tempo reale delle attività',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.blueGrey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _handleGlobalSync,
                                  icon: const Icon(
                                    Icons.sync_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Sincronizza Visite da Biosfera',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth < 600 ? 2 : 4;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: constraints.maxWidth < 600
                            ? 1.8
                            : 2.2,
                        children: [
                          _StatCard(
                            title: 'Totale Visite',
                            value: totalVisits.toString(),
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF0284C7),
                          ),
                          _StatCard(
                            title: 'Ispettori',
                            value: activeInspectors.toString(),
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                          _StatCard(
                            title: 'Concluse',
                            value: completed.toString(),
                            icon: Icons.verified_rounded,
                            color: const Color(0xFF047857),
                          ),
                          _StatCard(
                            title: 'In Corso',
                            value: inProgress.toString(),
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFD97706),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const _AlertsSection(),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;
                          return isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1A237E,
                                            ).withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.tune_rounded,
                                            color: Color(0xFF1A237E),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Esplora e Filtra',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF1E293B),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF1A237E,
                                            ).withValues(alpha: 0.08),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _FilterChip(
                                              label: 'Tutte',
                                              status: null,
                                            ),
                                            const SizedBox(width: 4),
                                            _FilterChip(
                                              label: 'In Corso',
                                              status: 1,
                                            ),
                                            const SizedBox(width: 4),
                                            _FilterChip(
                                              label: 'Concluse',
                                              status: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1A237E,
                                        ).withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        color: Color(0xFF1A237E),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Esplora e Filtra',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF1A237E,
                                          ).withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          _FilterChip(
                                            label: 'Tutte',
                                            status: null,
                                          ),
                                          const SizedBox(width: 4),
                                          _FilterChip(
                                            label: 'In Corso',
                                            status: 1,
                                          ),
                                          const SizedBox(width: 4),
                                          _FilterChip(
                                            label: 'Concluse',
                                            status: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              ref
                                      .read(adminSearchQueryProvider.notifier)
                                      .state =
                                  val,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Cerca per azienda, coltura o ispettore...',
                            hintStyle: TextStyle(
                              color: Colors.blueGrey.shade300,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF1A237E),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 24,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: const Color(
                                  0xFF1A237E,
                                ).withValues(alpha: 0.06),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                filteredVisitsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Center(child: Text('Errore: $err')),
                  data: (visits) {
                    if (visits.isEmpty) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 80,
                                  color: Colors.blueGrey.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nessun risultato trovato',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: const Interval(
                        0.6,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visits.length,
                        itemBuilder: (context, index) {
                          return _VisitCard(visit: visits[index].visit);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    final statusColor = visit.status >= 2
        ? const Color(0xFF10B981)
        : visit.status == 1
        ? const Color(0xFF3B82F6)
        : const Color(0xFFF59E0B);

    final statusLabel = visit.status >= 2
        ? 'Conclusa'
        : visit.status == 1
        ? 'In Corso'
        : 'Pianificata';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            visit.status >= 2
                ? Icons.domain_verification_rounded
                : Icons.business_rounded,
            color: statusColor,
          ),
        ),
        title: Text(
          visit.companyName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  Icon(
                    Icons.person_pin_rounded,
                    size: 14,
                    color: Colors.blueGrey.shade400,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    child: Text(
                      visit.inspectorName.isEmpty
                          ? 'Nessun ispettore'
                          : visit.inspectorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: Colors.blueGrey.shade200)),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: Colors.blueGrey.shade400,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.2,
                    ),
                    child: Text(
                      visit.crop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                color: const Color(0xFF1A237E),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisitWorkspacePage(
                        visitId: visit.id,
                        forceReadOnly: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final int? status;

  const _FilterChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(adminStatusFilterProvider) == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) =>
          ref.read(adminStatusFilterProvider.notifier).state = status,
      selectedColor: const Color(0xFF1A237E),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF1A237E),
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends ConsumerWidget {
  const _AlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminAlertsProvider);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Centro Avvisi Critici',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alerts.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final color = alert.severity == AlertSeverity.critical
                  ? Colors.red
                  : alert.severity == AlertSeverity.warning
                  ? Colors.orange
                  : Colors.blue;

              return Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        alert.severity == AlertSeverity.critical
                            ? Icons.priority_high_rounded
                            : alert.severity == AlertSeverity.warning
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            alert.title.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A237E),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
