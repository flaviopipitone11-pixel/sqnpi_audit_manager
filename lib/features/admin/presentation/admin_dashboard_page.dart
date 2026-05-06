import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../application/admin_export_service.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../application/alerts_provider.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'checklist_manager_page.dart';
import '../data/admin_repository.dart';

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
          .syncWithCloud(auth.username!, isAdmin: true);

      await ref.read(adminRepositoryProvider).syncActivityLogsWithCloud();
    } catch (e) {
      debugPrint('Admin Auto-Sync Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final visitsAsync = ref.watch(visitsWithCompanyProvider);
    final filteredVisitsAsync = ref.watch(filteredAdminVisitsProvider);
    final exportService = ref.watch(adminExportServiceProvider);

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
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            await ref
                                .read(auditsRepositoryProvider)
                                .syncWithCloud(
                                  auth.username ?? '',
                                  isAdmin: true,
                                );
                            // Forza il refresh della lista
                            ref.invalidate(visitsWithCompanyProvider);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sincronizzazione globale completata!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Errore sincronizzazione: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1A237E),
                                      Color(0xFF3949AB),
                                    ],
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
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                _ExportButton(
                                  label: 'EXCEL',
                                  icon: Icons.table_chart_rounded,
                                  color: const Color(0xFF10B981),
                                  onPressed: () =>
                                      exportService.exportToExcel(allVisits),
                                ),
                                const SizedBox(width: 12),
                                _ExportButton(
                                  label: 'PDF',
                                  icon: Icons.picture_as_pdf_rounded,
                                  color: const Color(0xFFEF4444),
                                  onPressed: () =>
                                      exportService.exportSummaryPdf(allVisits),
                                ),
                              ],
                            ],
                          ),
                          if (isMobile) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _ExportButton(
                                    label: 'EXCEL',
                                    icon: Icons.table_chart_rounded,
                                    color: const Color(0xFF10B981),
                                    onPressed: () =>
                                        exportService.exportToExcel(allVisits),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ExportButton(
                                    label: 'PDF',
                                    icon: Icons.picture_as_pdf_rounded,
                                    color: const Color(0xFFEF4444),
                                    onPressed: () => exportService
                                        .exportSummaryPdf(allVisits),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
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
                            ? 1.1
                            : 1.2,
                        children: [
                          _StatCard(
                            title: 'Totale Visite',
                            value: totalVisits.toString(),
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF3B82F6),
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
                            color: const Color(0xFF10B981),
                          ),
                          _StatCard(
                            title: 'In Corso',
                            value: inProgress.toString(),
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                const _AlertsSection(),
                const SizedBox(height: 40),
                const _InspectorStatsSection(),
                const SizedBox(height: 40),
                const _CommunicationsSection(),
                const SizedBox(height: 40),
                const _ConfigurationTools(),
                const SizedBox(height: 48),
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

class _InspectorStatsSection extends ConsumerWidget {
  const _InspectorStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(inspectorStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.query_stats_rounded,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Performance Ispettori',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Errore stats: $e')),
          data: (stats) {
            if (stats.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueGrey.shade50),
                ),
                child: Center(
                  child: Text(
                    'Nessun dato disponibile sugli ispettori',
                    style: TextStyle(color: Colors.blueGrey.shade300),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final s = stats[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.1),
                              child: Text(
                                s.name.isNotEmpty ? s.name[0] : '?',
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MiniStat(
                              label: 'VISITE',
                              value: s.completedVisits.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF10B981),
                            ),
                            _MiniStat(
                              label: 'MEDIA NC',
                              value: s.avgNCs.toStringAsFixed(1),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            _MiniStat(
                              label: 'ORE MEDIE',
                              value: s.avgDuration.toStringAsFixed(1),
                              icon: Icons.timer_outlined,
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CommunicationsSection extends ConsumerWidget {
  const _CommunicationsSection();

  Future<void> _confirmDeleteBroadcast(
    BuildContext context,
    WidgetRef ref,
    BroadcastMessage message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Avviso'),
        content: const Text(
          'Sei sicuro di voler eliminare questo avviso? Verrà rimosso permanentemente anche dal Cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(adminRepositoryProvider)
            .deleteBroadcastMessage(message.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avviso eliminato correttamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante l\'eliminazione: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(broadcastMessagesProvider);

    return Column(
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
                                0xFFF43F5E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFFF43F5E),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Comunicazioni e Notifiche',
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showNewBroadcastDialog(context, ref),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Invia Avviso'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF43F5E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFFF43F5E),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Comunicazioni e Notifiche',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showNewBroadcastDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Invia Avviso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Errore messaggi: $e')),
          data: (messages) {
            if (messages.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueGrey.shade50),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 40,
                      color: Colors.blueGrey.shade100,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nessun avviso inviato agli ispettori',
                      style: TextStyle(color: Colors.blueGrey.shade300),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: messages.take(3).map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueGrey.shade50),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSeverityColor(
                        m.severity,
                      ).withValues(alpha: 0.1),
                      child: Icon(
                        _getSeverityIcon(m.severity),
                        color: _getSeverityColor(m.severity),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      m.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      m.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd/MM HH:mm').format(m.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () =>
                              _confirmDeleteBroadcast(context, ref, m),
                          color: Colors.red.shade300,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 2:
        return Colors.red;
      case 1:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(int severity) {
    switch (severity) {
      case 2:
        return Icons.error_outline;
      case 1:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }
}

void _showNewBroadcastDialog(BuildContext context, WidgetRef ref) {
  showDialog(context: context, builder: (context) => _NewBroadcastDialog());
}

class _NewBroadcastDialog extends StatefulWidget {
  @override
  State<_NewBroadcastDialog> createState() => _NewBroadcastDialogState();
}

class _NewBroadcastDialogState extends State<_NewBroadcastDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  int _severity = 0; // 0: Info, 1: Warning, 2: Critical
  bool _isLoading = false;
  bool _sendToAll = true;
  final Set<String> _selectedEmails = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Text(
                    'Nuova Comunicazione',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('TITOLO AVVISO'),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'es: Aggiornamento Disciplinare 2024',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('MESSAGGIO'),
                    _buildTextField(
                      controller: _messageController,
                      hint: 'Scrivi qui il contenuto della notifica...',
                      icon: Icons.message_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('SEVERITÀ'),
                    _buildSeveritySelector(),

                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    _buildRecipientSection(),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Annulla',
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final canSend =
                            _sendToAll || _selectedEmails.isNotEmpty;
                        final label = _sendToAll
                            ? 'Invia a Tutti'
                            : 'Invia a ${_selectedEmails.length} Selezionati';

                        return ElevatedButton(
                          onPressed: (_isLoading || !canSend)
                              ? null
                              : () => _send(ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade300,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey.shade200),
          prefixIcon: Icon(icon, color: Colors.blueGrey.shade300, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          initialValue: _severity,
          items: const [
            DropdownMenuItem(
              value: 0,
              child: _SeverityItem(
                label: 'Informativo',
                color: Colors.blue,
                icon: Icons.info_outline,
              ),
            ),
            DropdownMenuItem(
              value: 1,
              child: _SeverityItem(
                label: 'Attenzione',
                color: Colors.orange,
                icon: Icons.warning_amber_rounded,
              ),
            ),
            DropdownMenuItem(
              value: 2,
              child: _SeverityItem(
                label: 'Urgente',
                color: Colors.red,
                icon: Icons.error_outline,
              ),
            ),
          ],
          onChanged: (v) => setState(() => _severity = v!),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Invia a tutti',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'Tutti gli ispettori riceveranno l\'avviso',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
                value: _sendToAll,
                activeThumbColor: const Color(0xFFF43F5E),
                onChanged: (val) => setState(() {
                  _sendToAll = val;
                  if (val) _selectedEmails.clear();
                }),
              ),
            ],
          ),
        ),
        if (!_sendToAll) ...[
          const SizedBox(height: 20),
          _buildLabel('SELEZIONA ISPETTORI'),
          Consumer(
            builder: (context, ref, _) {
              final db = ref.watch(appDatabaseProvider);
              return StreamBuilder<List<Inspector>>(
                stream: db.select(db.inspectors).watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  final inspectors = snapshot.data!;
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: inspectors.length,
                      itemBuilder: (context, index) {
                        final isp = inspectors[index];
                        final isSelected = _selectedEmails.contains(isp.email);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFFF43F5E,
                                  ).withValues(alpha: 0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(
                                      0xFFF43F5E,
                                    ).withValues(alpha: 0.2)
                                  : Colors.blueGrey.shade50,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              isp.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              isp.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.blueGrey.shade50,
                              child: Text(
                                isp.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            value: isSelected,
                            activeColor: const Color(0xFFF43F5E),
                            onChanged: (val) => setState(() {
                              if (val == true) {
                                _selectedEmails.add(isp.email);
                              } else {
                                _selectedEmails.remove(isp.email);
                              }
                            }),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _send(WidgetRef ref) async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final targetEmailsStr = _sendToAll ? null : _selectedEmails.join(',');
      final msg = await ref
          .read(appDatabaseProvider)
          .createBroadcastMessage(
            title: _titleController.text,
            message: _messageController.text,
            severity: _severity,
            targetEmails: targetEmailsStr,
          );

      // Push al Cloud con un timeout di sicurezza di 10 secondi
      await ref
          .read(adminRepositoryProvider)
          .pushBroadcastMessageToCloud(msg)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Timeout: Il server non risponde.'),
          );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avviso inviato con successo!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'invio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SeverityItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SeverityItem({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

class _ConfigurationTools extends StatelessWidget {
  const _ConfigurationTools();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.settings_suggest_rounded, color: Color(0xFF64748B)),
            SizedBox(width: 12),
            Text(
              'Strumenti di Configurazione',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return isMobile
                ? Column(
                    children: [
                      _ToolCard(
                        title: 'Editor Checklist',
                        subtitle: 'Modifica requisiti e versioni',
                        icon: Icons.checklist_rtl_rounded,
                        color: Colors.indigo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChecklistManagerPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ToolCard(
                        title: 'Dati Master',
                        subtitle: 'Gestione aziende e ispettori',
                        icon: Icons.storage_rounded,
                        color: Colors.teal,
                        onTap: () {}, // Futura implementazione
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _ToolCard(
                          title: 'Editor Checklist',
                          subtitle: 'Modifica requisiti e versioni',
                          icon: Icons.checklist_rtl_rounded,
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChecklistManagerPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ToolCard(
                          title: 'Dati Master',
                          subtitle: 'Gestione aziende e ispettori',
                          icon: Icons.storage_rounded,
                          color: Colors.teal,
                          onTap: () {}, // Futura implementazione
                        ),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade50),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
              ),
            ],
          ),
        ),
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

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade400,
              letterSpacing: 0.5,
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
