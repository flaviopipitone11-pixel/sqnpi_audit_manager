import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/audit_stats_provider.dart';
import '../application/weather_provider.dart';
import '../data/audits_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/visit_with_company.dart';
import 'navigation_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/widgets/sync_log_dialog.dart';

final _homeDateFilterProvider = StateProvider<DateTime?>(
  (ref) => DateTime.now(),
);

final recentBroadcastMessagesProvider = StreamProvider<List<BroadcastMessage>>((
  ref,
) {
  final messagesStream = ref
      .watch(appDatabaseProvider)
      .watchBroadcastMessages();
  return messagesStream.map((list) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return list.where((m) => m.createdAt.isAfter(weekAgo)).toList();
  });
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _timelineController;
  late final ScrollController _kpiController;
  late final ScrollController _statusControllerMobile;
  late final ScrollController _statusControllerDesktop;
  late DateTime _visibleDate;

  @override
  void initState() {
    super.initState();
    _visibleDate = DateTime.now();
    _timelineController = ScrollController(initialScrollOffset: 30.0 * 81.0);
    _kpiController = ScrollController();
    _statusControllerMobile = ScrollController();
    _statusControllerDesktop = ScrollController();

    _timelineController.addListener(() {
      if (!_timelineController.hasClients) return;

      // Calcola l'indice basato sullo scroll offset
      final index = (_timelineController.offset / 81.0).round();
      final date = DateTime.now()
          .subtract(const Duration(days: 30))
          .add(Duration(days: index));

      // Aggiorna solo se il mese o l'anno cambiano per migliorare la performance
      if (date.month != _visibleDate.month || date.year != _visibleDate.year) {
        setState(() {
          _visibleDate = date;
        });
      }
    });

    // Sincronizzazione automatica all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSync(isInitial: true);
    });
  }

  Future<void> _checkAndSync({bool isInitial = false}) async {
    if (!mounted) return;

    final syncStatus = ref.read(syncStatusProvider);
    final auth = ref.read(authControllerProvider);

    if (syncStatus.state == SyncState.offline) {
      // Se siamo offline, mostriamo il messaggio come richiesto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sei in modalità offline. Ricordati di sincronizzare l\'app appena avrai connettività.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Se siamo online, procediamo con il sync automatico
    try {
      // Mostriamo un feedback non bloccante per il sync automatico
      if (isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Sincronizzazione automatica in corso...'),
              ],
            ),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await ref
          .read(auditsRepositoryProvider)
          .syncWithCloud(
            auth.username ?? '',
            isAdmin: auth.isAdmin,
            inspectorCode: auth.inspectorCode,
          );

      // Refresh delle statistiche e dati
      ref.invalidate(globalStatsProvider);
      ref.invalidate(visitsWithCompanyProvider);
    } catch (e) {
      debugPrint('Errore auto-sync: $e');
    }
  }

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
      ref.invalidate(globalStatsProvider);
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
          content: Text('Errore critico sync: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _kpiController.dispose();
    _statusControllerMobile.dispose();
    _statusControllerDesktop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final globalStatsAsync = ref.watch(globalStatsProvider);
    final visitsWithCompanyAsync = ref.watch(visitsWithCompanyProvider);
    final selectedDate = ref.watch(_homeDateFilterProvider);

    // Ascolta i cambi di navigazione per ri-attivare il sync quando si torna sulla Home
    ref.listen(homeNavigationProvider, (previous, next) {
      if (next == 0 && previous != 0) {
        _checkAndSync();
      }
    });

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isShort = MediaQuery.of(context).size.height < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0), // Slate 100
      body: CustomScrollView(
        slivers: [
          _buildAppBar(
            context,
            ref,
            auth.username ?? 'Ispettore',
            isLandscape,
            isShort,
            selectedDate,
          ),
          if (auth.isFirstLogin)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sicurezza Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const Text(
                              'Stai usando la password predefinita. Per sicurezza, cambiala subito nelle impostazioni.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/settings'),
                        child: const Text('CAMBIA'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 800 ? 32 : 16,
                vertical: isLandscape
                    ? 16
                    : (MediaQuery.of(context).size.width > 800 ? 40 : 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BroadcastAlertsSection(),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final isMobile = MediaQuery.of(context).size.width < 800;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              '📊 Panoramica Attività',
                              'I tuoi indicatori di performance',
                            ),
                            const SizedBox(height: 16),
                            globalStatsAsync.when(
                              data: (stats) => _buildKpiRow(context, stats),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Text('Errore stats: $e'),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/logo_sqnpi.webp',
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              '📡 Stato Operativo',
                              'Contesto e dati',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: Scrollbar(
                                controller: _statusControllerMobile,
                                child: Listener(
                                  onPointerSignal: (event) {
                                    if (event is PointerScrollEvent) {
                                      _statusControllerMobile.jumpTo(
                                        (_statusControllerMobile.offset +
                                                event.scrollDelta.dy)
                                            .clamp(
                                              0,
                                              _statusControllerMobile
                                                  .position
                                                  .maxScrollExtent,
                                            ),
                                      );
                                    }
                                  },
                                  child: SingleChildScrollView(
                                    controller: _statusControllerMobile,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: const Row(
                                      children: [
                                        _WeatherCard(),
                                        SizedBox(width: 12),
                                        _DataHealthCard(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  '📊 Panoramica Attività',
                                  'I tuoi indicatori di performance',
                                ),
                                const SizedBox(height: 16),
                                globalStatsAsync.when(
                                  data: (stats) => _buildKpiRow(context, stats),
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, _) => Text('Errore stats: $e'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Placeholder invisibile per allineamento con i titoli laterali
                                Opacity(
                                  opacity: 0,
                                  child: _buildSectionHeader(
                                    'Placeholder',
                                    'Sub',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo_sqnpi.webp',
                                      height: 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Riquadro laterale per Meteo e Salute Dati
                          SizedBox(
                            width: 320,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  '📡 Stato Operativo',
                                  'Contesto e dati',
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 180,
                                  child: Scrollbar(
                                    controller: _statusControllerDesktop,
                                    child: Listener(
                                      onPointerSignal: (event) {
                                        if (event is PointerScrollEvent) {
                                          _statusControllerDesktop.jumpTo(
                                            (_statusControllerDesktop.offset +
                                                    event.scrollDelta.dy)
                                                .clamp(
                                                  0,
                                                  _statusControllerDesktop
                                                      .position
                                                      .maxScrollExtent,
                                                ),
                                          );
                                        }
                                      },
                                      child: SingleChildScrollView(
                                        controller: _statusControllerDesktop,
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: const Row(
                                          children: [
                                            _WeatherCard(),
                                            SizedBox(width: 16),
                                            _DataHealthCard(),
                                          ],
                                        ),
                                      ),
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
                  const SizedBox(height: 48),
                  _buildTimeline(
                    context,
                    ref,
                    visitsWithCompanyAsync,
                    selectedDate,
                  ),
                  const SizedBox(height: 48),
                  _buildSectionHeader(
                    '⚡ Azioni Rapide',
                    'Strumenti di lavoro veloci',
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, ref),
                  const SizedBox(height: 48),
                  _buildSectionHeader(
                    selectedDate == null
                        ? '🕒 Attività Recenti'
                        : '📍 Visite del Giorno',
                    'Dettaglio delle ispezioni',
                  ),
                  const SizedBox(height: 24),
                  visitsWithCompanyAsync.when(
                    data: (visits) =>
                        _buildFilteredVisits(context, visits, selectedDate),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Errore visite: $e'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.8,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String name,
    bool isLandscape,
    bool isShort,
    DateTime? selectedDate,
  ) {
    final expandedHeight = isLandscape ? (isShort ? 140.0 : 180.0) : 240.0;

    const headerGreenStart = Color(0xFF047857);
    const headerGreenEnd = Color(0xFF059669);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: headerGreenStart,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: 'Impostazioni',
        ),
        IconButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'Logout',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerGreenStart, headerGreenEnd],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isLandscape ? 16 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLandscape || !isShort) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        'BENVENUTO',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isLandscape ? 28 : 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  if (!isLandscape) const SizedBox(height: 16),
                  if (!isLandscape)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'EEEE d MMMM, yyyy',
                            'it_IT',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, GlobalAuditStats stats) {
    return SizedBox(
      height: 180,
      child: Scrollbar(
        controller: _kpiController,
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _kpiController.jumpTo(
                (_kpiController.offset + event.scrollDelta.dy).clamp(
                  0,
                  _kpiController.position.maxScrollExtent,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            controller: _kpiController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _KpiCard(
                  label: 'Programmate',
                  value: stats.pendingVisits.toString(),
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF059669), // Emerald 600
                  onTap: () {
                    ref.read(visitFilterStatusProvider.notifier).state = 0;
                    ref.read(homeNavigationProvider.notifier).state = 1;
                  },
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  label: 'In Corso',
                  value: stats.inProgressVisits.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: Colors.amber.shade700,
                  onTap: () {
                    ref.read(visitFilterStatusProvider.notifier).state = 1;
                    ref.read(homeNavigationProvider.notifier).state = 1;
                  },
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  label: 'Completate',
                  value: stats.closedVisits.toString(),
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF10B981), // Emerald 500
                  onTap: () {
                    ref.read(visitFilterStatusProvider.notifier).state = 2;
                    ref.read(homeNavigationProvider.notifier).state = 1;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VisitWithCompany>> visitsAsync,
    DateTime? selectedDate,
  ) {
    return _ModernInspectionCalendar(
      visitsAsync: visitsAsync,
      selectedDate: selectedDate,
      visibleDate: _visibleDate,
      onMonthChanged: (newDate) {
        setState(() {
          _visibleDate = newDate;
        });
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 800 ? 3 : 1.6,
      children: [
        _ActionCard(
          label: 'Sincronizza',
          icon: Icons.sync,
          color: const Color(0xFF059669),
          onTap: () => _handleSync(),
        ),
        _ActionCard(
          label: 'Cerca Azienda',
          icon: Icons.search,
          color: Colors.orange,
          onTap: () {
            ref.read(homeNavigationProvider.notifier).state = 1;
          },
        ),
      ],
    );
  }

  Widget _buildFilteredVisits(
    BuildContext context,
    List<VisitWithCompany> visits,
    DateTime? selectedDate,
  ) {
    final filtered = selectedDate == null
        ? visits.take(5).toList()
        : visits.where((v) {
            final start = DateTime(
              v.visit.scheduledAt.year,
              v.visit.scheduledAt.month,
              v.visit.scheduledAt.day,
            );
            final end = v.visit.scheduledUntil != null
                ? DateTime(
                    v.visit.scheduledUntil!.year,
                    v.visit.scheduledUntil!.month,
                    v.visit.scheduledUntil!.day,
                  )
                : start;
            final current = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            );
            return (current.isAtSameMomentAs(start) ||
                    current.isAfter(start)) &&
                (current.isAtSameMomentAs(end) || current.isBefore(end));
          }).toList();

    if (filtered.isEmpty) {
      // Se non ci sono visite per il giorno selezionato (es. oggi),
      // mostriamo le prossime 3 visite in generale.
      final upcoming = visits
          .where(
            (v) => v.visit.scheduledAt.isAfter(
              DateTime.now().subtract(const Duration(minutes: 30)),
            ),
          )
          .take(3)
          .toList();

      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            if (upcoming.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.next_plan_outlined,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PROSSIME VISITE IN ARRIVO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...upcoming.map((v) => _RecentVisitTile(v: v)),
            ] else ...[
              Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Nessuna attività programmata',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((v) => _RecentVisitTile(v: v)).toList(),
    );
  }
}

class _BroadcastAlertsSection extends ConsumerWidget {
  const _BroadcastAlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(recentBroadcastMessagesProvider);

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) return const SizedBox.shrink();

        return Column(
          children: messages.map((m) {
            final color = _getSeverityColor(m.severity);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_getSeverityIcon(m.severity), color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM').format(m.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: color.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.message,
                          style: TextStyle(color: color.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 2:
        return const Color(0xFFEF4444); // Red 500
      case 1:
        return const Color(0xFFF59E0B); // Amber 500
      default:
        return const Color(0xFF3B82F6); // Blue 500
    }
  }

  IconData _getSeverityIcon(int severity) {
    switch (severity) {
      case 2:
        return Icons.campaign_rounded;
      case 1:
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: _PerspectiveCard(
        color: widget.color,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 150,
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: _isHovered ? 0.15 : 0.05,
                    ),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: _Sparkline(color: widget.color),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: 24,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              widget.value,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: _PerspectiveCard(
        color: widget.color,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isHovered
                      ? widget.color.withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _isHovered ? 0.08 : 0.02,
                    ),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color,
                          widget.color.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Text(
                          'Azione Rapida',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _isHovered ? widget.color : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentVisitTile extends ConsumerStatefulWidget {
  final VisitWithCompany v;

  const _RecentVisitTile({required this.v});

  @override
  ConsumerState<_RecentVisitTile> createState() => _RecentVisitTileState();
}

class _RecentVisitTileState extends ConsumerState<_RecentVisitTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/visit/${widget.v.visit.id}'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.v.visit.companyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${widget.v.visit.crop} • ${widget.v.company.comune}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(widget.v.visit.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.map_outlined),
                            color: Colors.blue,
                            tooltip: 'Apri Google Maps',
                            onPressed: () async {
                              final lat = widget.v.company.latitude;
                              final lng = widget.v.company.longitude;
                              if (lat == null || lng == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Coordinate non disponibili.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final url = Uri.parse(
                                'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _isHovered
                                ? Theme.of(context).primaryColor
                                : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    final (color, label) = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(int status) {
    switch (status) {
      case 0:
        return (const Color(0xFF64748B), 'Programmata');
      case 1:
        return (Colors.amber.shade700, 'In Corso');
      case 2:
        return (const Color(0xFF10B981), 'Completata');
      case 3:
        return (const Color(0xFF3B82F6), 'Sincronizzata');
      default:
        return (Colors.grey, 'N/D');
    }
  }
}

class _PerspectiveCard extends StatefulWidget {
  final Widget child;
  final Color color;

  const _PerspectiveCard({required this.child, required this.color});

  @override
  State<_PerspectiveCard> createState() => _PerspectiveCardState();
}

class _PerspectiveCardState extends State<_PerspectiveCard> {
  double x = 0;
  double y = 0;

  @override
  Widget build(BuildContext context) {
    // Only apply hover tilt on desktop/wide screens
    final isWide = MediaQuery.of(context).size.width > 800;

    return MouseRegion(
      onEnter: (_) => {},
      onExit: (_) => setState(() {
        x = 0;
        y = 0;
      }),
      onHover: (event) {
        if (!isWide) return;

        final size = context.size;
        if (size == null) return;

        final centerX = size.width / 2;
        final centerY = size.height / 2;

        setState(() {
          // Slightly more subtle tilt (max 7 degrees)
          // Adjust signs so it tilts TOWARDS the mouse
          y = (event.localPosition.dx - centerX) / centerX * 7;
          x = (centerY - event.localPosition.dy) / centerY * 7;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transformAlignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012) // Slightly more pronounced perspective
          ..rotateX(x * (math.pi / 180))
          ..rotateY(y * (math.pi / 180)),
        child: widget.child,
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final Color color;

  const _Sparkline({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(color: color.withValues(alpha: 0.2)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.4,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.9,
      size.width * 0.8,
      size.height * 0.4,
    );
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return Container(
      width: 150,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: weatherAsync.when(
              data: (weather) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      weather.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('☀️', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  const Text(
                    '18.5°C',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Sereno',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DataHealthCard extends ConsumerWidget {
  const _DataHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSyncAsync = ref.watch(lastSyncStatusProvider);

    return lastSyncAsync.when(
      data: (log) {
        final isError = log?.action.contains('ERROR') ?? false;
        final color = isError ? Colors.red : const Color(0xFF10B981);
        final bgColor = isError
            ? Colors.red.withValues(alpha: 0.05)
            : Colors.green.withValues(alpha: 0.05);
        final iconColor = isError ? Colors.red : const Color(0xFF10B981);
        final icon = isError
            ? Icons.cloud_off_rounded
            : Icons.cloud_done_rounded;

        String labelText = 'Salute Dati';
        String valueText = '100%';

        if (log != null) {
          final timeStr = DateFormat('HH:mm').format(log.createdAt);
          valueText = timeStr;
          labelText = isError ? 'Errore Sync' : 'Sincronizzato';
        }

        return Container(
          width: 150,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: bgColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      valueText,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isError ? Colors.red : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        width: 150,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Container(
        width: 150,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      ),
    );
  }
}

class _AnimatedSyncIcon extends StatefulWidget {
  const _AnimatedSyncIcon();

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(Icons.sync, color: Colors.white, size: 14),
    );
  }
}

class _ModernInspectionCalendar extends ConsumerStatefulWidget {
  final AsyncValue<List<VisitWithCompany>> visitsAsync;
  final DateTime? selectedDate;
  final DateTime visibleDate;
  final Function(DateTime) onMonthChanged;

  const _ModernInspectionCalendar({
    required this.visitsAsync,
    required this.selectedDate,
    required this.visibleDate,
    required this.onMonthChanged,
  });

  @override
  ConsumerState<_ModernInspectionCalendar> createState() =>
      _ModernInspectionCalendarState();
}

class _ModernInspectionCalendarState
    extends ConsumerState<_ModernInspectionCalendar> {
  @override
  Widget build(BuildContext context) {
    final visits = widget.visitsAsync.valueOrNull ?? [];
    final monthDate = widget.visibleDate;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    String monthYearLabel;
    try {
      monthYearLabel = DateFormat(
        'MMMM yyyy',
        'it_IT',
      ).format(monthDate).toUpperCase();
    } catch (_) {
      monthYearLabel = DateFormat('MMMM yyyy').format(monthDate).toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Compact Mini-Calendar
                SizedBox(
                  width: 340,
                  child: _buildMiniCalendar(
                    context,
                    monthDate,
                    monthYearLabel,
                    visits,
                  ),
                ),

                // Divider
                Container(
                  width: 1.5,
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: const Color(0xFFF1F5F9),
                ),

                // Right Side: Agenda Visite in Evidenza
                Expanded(child: _buildAgendaView(context, visits)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMiniCalendar(context, monthDate, monthYearLabel, visits),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 20),
                _buildAgendaView(context, visits),
              ],
            ),
    );
  }

  Widget _buildMiniCalendar(
    BuildContext context,
    DateTime monthDate,
    String monthYearLabel,
    List<VisitWithCompany> visits,
  ) {
    final weekdays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final leadingDays = firstDayOfMonth.weekday - 1;
    final startDate = firstDayOfMonth.subtract(Duration(days: leadingDays));

    final nextMonth = monthDate.month == 12 ? 1 : monthDate.month + 1;
    final nextYear = monthDate.month == 12
        ? monthDate.year + 1
        : monthDate.year;
    final daysInMonth = DateTime(nextYear, nextMonth, 0).day;

    final totalDaysCount = (leadingDays + daysInMonth) <= 35 ? 35 : 42;

    final gridDays = List.generate(
      totalDaysCount,
      (index) => startDate.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini Calendar Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthYearLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    widget.onMonthChanged(
                      DateTime(monthDate.year, monthDate.month - 1),
                    );
                  },
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Mese precedente',
                ),
                IconButton(
                  onPressed: () {
                    widget.onMonthChanged(
                      DateTime(monthDate.year, monthDate.month + 1),
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Mese successivo',
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    final now = DateTime.now();
                    widget.onMonthChanged(now);
                    ref.read(_homeDateFilterProvider.notifier).state = now;
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Oggi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Weekday header letters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((w) {
            return SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  w,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 6),

        // Compact Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gridDays.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 38,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final date = gridDays[index];
            final isCurrentMonth = date.month == monthDate.month;
            final isToday =
                date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;

            final isSelected =
                widget.selectedDate != null &&
                date.day == widget.selectedDate!.day &&
                date.month == widget.selectedDate!.month &&
                date.year == widget.selectedDate!.year;

            final dayVisitsCount = _getVisitsForDate(date, visits);

            return InkWell(
              onTap: () {
                ref.read(_homeDateFilterProvider.notifier).state = isSelected
                    ? null
                    : date;
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        )
                      : null,
                  color: !isSelected
                      ? (isToday
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : isCurrentMonth
                            ? Colors.white
                            : Colors.grey.shade50)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF059669)
                        : isToday
                        ? const Color(0xFF10B981)
                        : (isCurrentMonth
                              ? const Color(0xFFF1F5F9)
                              : Colors.transparent),
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isCurrentMonth
                                  ? (isToday
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF1E293B))
                                  : Colors.grey.shade300),
                      ),
                    ),
                    if (dayVisitsCount > 0)
                      Positioned(
                        bottom: 3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgendaView(BuildContext context, List<VisitWithCompany> visits) {
    final selectedDate = widget.selectedDate;

    final activeVisits = selectedDate == null
        ? visits.where((v) {
            return v.visit.scheduledAt.year == widget.visibleDate.year &&
                v.visit.scheduledAt.month == widget.visibleDate.month;
          }).toList()
        : visits.where((v) {
            final start = DateTime(
              v.visit.scheduledAt.year,
              v.visit.scheduledAt.month,
              v.visit.scheduledAt.day,
            );
            final end = v.visit.scheduledUntil != null
                ? DateTime(
                    v.visit.scheduledUntil!.year,
                    v.visit.scheduledUntil!.month,
                    v.visit.scheduledUntil!.day,
                  )
                : start;
            final current = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            );
            return (current.isAtSameMomentAs(start) ||
                    current.isAfter(start)) &&
                (current.isAtSameMomentAs(end) || current.isBefore(end));
          }).toList();

    String titleLabel;
    if (selectedDate != null) {
      try {
        titleLabel =
            'Visite di ${DateFormat('EEEE d MMMM', 'it_IT').format(selectedDate)}';
      } catch (_) {
        titleLabel =
            'Visite del ${DateFormat('d MMMM yyyy').format(selectedDate)}';
      }
    } else {
      titleLabel = 'Agenda Ispezioni in programma';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agenda Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activeVisits.length} ${activeVisits.length == 1 ? "ispezione trovata" : "ispezioni trovate"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDate != null)
              InkWell(
                onTap: () {
                  ref.read(_homeDateFilterProvider.notifier).state = null;
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.filter_alt_off_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Mostra Tutte',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        // List of Inspection Cards
        if (activeVisits.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeVisits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final v = activeVisits[index];
              return _AgendaVisitCard(v: v);
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedDate != null
                      ? 'Nessuna ispezione programmata per questa data.'
                      : 'Nessuna ispezione in programma per questo mese.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleziona un altro giorno nel calendario per visualizzare le visite.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _getVisitsForDate(DateTime date, List<VisitWithCompany> visits) {
    final current = DateTime(date.year, date.month, date.day);
    return visits.where((v) {
      final start = DateTime(
        v.visit.scheduledAt.year,
        v.visit.scheduledAt.month,
        v.visit.scheduledAt.day,
      );
      final end = v.visit.scheduledUntil != null
          ? DateTime(
              v.visit.scheduledUntil!.year,
              v.visit.scheduledUntil!.month,
              v.visit.scheduledUntil!.day,
            )
          : start;
      return (current.isAtSameMomentAs(start) || current.isAfter(start)) &&
          (current.isAtSameMomentAs(end) || current.isBefore(end));
    }).length;
  }
}

class _AgendaVisitCard extends ConsumerWidget {
  final VisitWithCompany v;

  const _AgendaVisitCard({required this.v});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = v.visit.status;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 0:
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'Da Iniziare';
        statusIcon = Icons.play_circle_outline_rounded;
        break;
      case 1:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'In Corso';
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 2:
      case 3:
        statusColor = const Color(0xFF059669);
        statusLabel = 'Completata';
        statusIcon = Icons.verified_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'N/D';
        statusIcon = Icons.info_outline_rounded;
    }

    final companyName = v.visit.companyName;
    final comune = v.company.comune;
    final crop = v.visit.crop;
    final dateFormatted = DateFormat(
      'd MMMM yyyy',
      'it_IT',
    ).format(v.visit.scheduledAt);

    return InkWell(
      onTap: () {
        context.push('/visit/${v.visit.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (crop.isNotEmpty || comune.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          '$crop ${comune.isNotEmpty ? "• $comune" : ""}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
