import 'dart:math' as math;
import 'dart:ui';
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
import '../../../core/utils/seasonal_asset_manager.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/sync/sync_controller.dart';

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
  late DateTime _visibleDate;

  @override
  void initState() {
    super.initState();
    _visibleDate = DateTime.now();
    // Start from index 30 (Today)
    // 81 is width (65) + right margin (16)
    _timelineController = ScrollController(initialScrollOffset: 30.0 * 81.0);

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
          .syncWithCloud(auth.username ?? '');

      // Refresh delle statistiche e dati
      ref.invalidate(globalStatsProvider);
      ref.invalidate(visitsWithCompanyProvider);
    } catch (e) {
      debugPrint('Errore auto-sync: $e');
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
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
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
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
                            _buildSectionHeader(
                              '📡 Stato Operativo',
                              'Contesto e dati',
                            ),
                            const SizedBox(height: 16),
                            const SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _WeatherCard(),
                                  SizedBox(width: 12),
                                  _DataHealthCard(),
                                ],
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
                                const SizedBox(height: 24),
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
                          const SizedBox(width: 40),
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
                                const SizedBox(height: 24),
                                const SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _WeatherCard(),
                                      SizedBox(width: 16),
                                      _DataHealthCard(),
                                    ],
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
    final config = SeasonalAssetManager.getAssetConfig(selectedDate);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: config.startColor,
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [config.startColor, config.endColor],
                ),
              ),
            ),
            // Background image with blend effect
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(config.assetPath, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: _NatureParticles(
                colors: config.particleColors,
                type: config.particleType,
              ),
            ),
            // Abstract geometric background elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: config.particleColors.first.withValues(alpha: 0.1),
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
                        config.label.toUpperCase(),
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
                          color: config.particleColors.first,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _KpiCard(
            label: 'Programmate',
            value: stats.pendingVisits.toString(),
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF059669), // Emerald 600
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'In Corso',
            value: stats.inProgressVisits.toString(),
            icon: Icons.pending_actions_rounded,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 16),
          _KpiCard(
            label: 'Completate',
            value: stats.closedVisits.toString(),
            icon: Icons.verified_rounded,
            color: const Color(0xFF10B981), // Emerald 500
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VisitWithCompany>> visitsAsync,
    DateTime? selectedDate,
  ) {
    String monthYear;
    try {
      monthYear = DateFormat(
        'MMMM yyyy',
        'it_IT',
      ).format(_visibleDate).toUpperCase();
    } catch (e) {
      monthYear = DateFormat('MMMM yyyy').format(_visibleDate).toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'Calendario Ispezioni',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            _OggiButton(
              onTap: () {
                ref.read(_homeDateFilterProvider.notifier).state =
                    DateTime.now();
                _timelineController.animateTo(
                  30.0 * 81.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutQuart,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        visitsAsync.when(
          data: (visits) => SizedBox(
            height: 100, // Ripristinato altezza standard
            child: ListView.builder(
              controller: _timelineController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: 365,
              itemBuilder: (context, index) {
                final date = DateTime.now()
                    .subtract(const Duration(days: 30))
                    .add(Duration(days: index));

                final isSelected =
                    selectedDate != null &&
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                final hasVisits = visits.any((v) {
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
                  final current = DateTime(date.year, date.month, date.day);
                  return (current.isAtSameMomentAs(start) ||
                          current.isAfter(start)) &&
                      (current.isAtSameMomentAs(end) || current.isBefore(end));
                });

                return _TimelineDay(
                  date: date,
                  isSelected: isSelected,
                  hasVisits: hasVisits,
                  onTap: () {
                    ref.read(_homeDateFilterProvider.notifier).state =
                        isSelected ? null : date;
                  },
                );
              },
            ),
          ),
          loading: () => const SizedBox(
            height: 70,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox(height: 70),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: MediaQuery.of(context).size.width > 800 ? 3 : 1.6,
      children: [
        _ActionCard(
          label: 'Sincronizza',
          icon: Icons.sync,
          color: const Color(0xFF059669),
          onTap: () => _handleSync(context, ref),
        ),
        _ActionCard(
          label: 'Cerca Azienda',
          icon: Icons.search,
          color: Colors.orange,
          onTap: () {
            ref.read(homeNavigationProvider.notifier).state = 1;
          },
        ),
        _ActionCard(
          label: 'Pianifica Visita',
          icon: Icons.add_circle_outline_rounded,
          color: Colors.indigo,
          onTap: () => context.push('/create-visit'),
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

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authControllerProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Sincronizzazione in corso...'),
          ],
        ),
      ),
    );

    try {
      await ref
          .read(auditsRepositoryProvider)
          .syncWithCloud(auth.username ?? '');
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronizzazione completata!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
                color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
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

class _TimelineDay extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool hasVisits;
  final VoidCallback onTap;

  const _TimelineDay({
    required this.date,
    required this.isSelected,
    required this.hasVisits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;

    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        width: 65,
        margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                )
              : isToday
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF059669).withValues(alpha: 0.1),
                    const Color(0xFF10B981).withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: !isSelected && !isToday
              ? (isWeekend ? const Color(0xFFF8FAFC) : Colors.white)
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF059669)
                : isToday
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: isSelected || isToday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF059669).withValues(alpha: 0.3)
                  : isToday
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : Colors
                        .transparent, // Ombra invisibile invece di lista vuota
              blurRadius: isSelected ? 12 : (isToday ? 8 : 0),
              offset: isSelected
                  ? const Offset(0, 6)
                  : (isToday ? const Offset(0, 4) : Offset.zero),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              () {
                try {
                  return DateFormat('EEE', 'it_IT').format(date).toUpperCase();
                } catch (e) {
                  // Fallback if it_IT is not available
                  return DateFormat('EEE').format(date).toUpperCase();
                }
              }(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : isWeekend
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? const Color(0xFF064E3B)
                    : const Color(0xFF0F172A),
              ),
            ),
            if (hasVisits) ...[
              const SizedBox(height: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                  ],
                ),
              ),
            ],
            if (isToday && !isSelected) ...[
              const SizedBox(height: 2),
              const Text(
                'OGGI',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OggiButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OggiButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.today_rounded, size: 18, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'OGGI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _NatureParticles extends StatefulWidget {
  final List<Color> colors;
  final ParticleType type;

  const _NatureParticles({required this.colors, required this.type});

  @override
  State<_NatureParticles> createState() => _NatureParticlesState();
}

class _NatureParticlesState extends State<_NatureParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  Offset _mousePos = Offset.zero;
  bool _isMouseInside = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      35,
      (_) => _Particle(colors: widget.colors, type: widget.type),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _NatureParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.colors != widget.colors) {
      _particles = List.generate(
        35,
        (_) => _Particle(colors: widget.colors, type: widget.type),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() => _isMouseInside = true),
      onExit: (e) => setState(() => _isMouseInside = false),
      onHover: (e) => setState(() => _mousePos = e.localPosition),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              _particles,
              _controller.value,
              _mousePos,
              _isMouseInside,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final ParticleType type;

  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 10 + 8;
  int speedMultiplier = math.Random().nextInt(2) + 1;
  double opacity = math.Random().nextDouble() * 0.4 + 0.15;
  double noiseOffset = math.Random().nextDouble() * 2 * math.pi;
  double depth = math.Random().nextDouble();
  double rotation = math.Random().nextDouble() * math.pi * 2;
  double rotationSpeed = (math.Random().nextDouble() - 0.5) * 3;
  late Color color;

  _Particle({required List<Color> colors, required this.type}) {
    color = colors[math.Random().nextInt(colors.length)];
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Offset mousePos;
  final bool isMouseInside;

  _ParticlePainter(
    this.particles,
    this.animationValue,
    this.mousePos,
    this.isMouseInside,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final yPos = (p.y + (animationValue * p.speedMultiplier)) % 1.0;
      final sway =
          math.sin(animationValue * math.pi * 2 + p.noiseOffset) *
          0.12 *
          (0.8 + p.depth);
      final xPos = (p.x + sway) % 1.0;

      double finalX = xPos * size.width;
      double finalY = yPos * size.height;

      if (isMouseInside) {
        final dx = finalX - mousePos.dx;
        final dy = finalY - mousePos.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 130) {
          final force = (130 - dist) / 130;
          final angle = math.atan2(dy, dx);
          final push = force * 35 * (0.6 + p.depth * 0.4);
          finalX += math.cos(angle) * push;
          finalY += math.sin(angle) * push;
        }
      }

      final currentRotation =
          p.rotation + (animationValue * math.pi * 2 * p.rotationSpeed);

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      if (p.depth > 0.8) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      }

      canvas.save();
      canvas.translate(finalX, finalY);
      canvas.rotate(currentRotation);

      switch (p.type) {
        case ParticleType.leaf:
          _drawLeaf(canvas, p, paint);
          break;
        case ParticleType.snowflake:
          _drawSnowflake(canvas, p, paint);
          break;
        case ParticleType.sparkle:
          _drawSparkle(canvas, p, paint);
          break;
        case ParticleType.star:
          _drawStar(canvas, p, paint);
          break;
        case ParticleType.flower:
          _drawFlower(canvas, p, paint);
          break;
        case ParticleType.christmasTree:
          _drawChristmasTree(canvas, p, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, _Particle p, Paint paint) {
    final path = Path();
    final w = p.size;
    final h = p.size * 1.6;
    path.moveTo(0, -h / 2);
    path.quadraticBezierTo(w / 2, 0, 0, h / 2);
    path.quadraticBezierTo(-w / 2, 0, 0, -h / 2);
    path.close();
    canvas.drawPath(path, paint);

    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: p.opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, -h / 2), Offset(0, h / 2), veinPaint);
  }

  void _drawSnowflake(Canvas canvas, _Particle p, Paint paint) {
    final s = p.size * 0.8;
    final strokePaint = Paint()
      ..color = p.color.withValues(alpha: p.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      canvas.drawLine(Offset.zero, Offset(0, s), strokePaint);
      // Small branches
      canvas.drawLine(
        Offset(0, s * 0.6),
        Offset(s * 0.3, s * 0.8),
        strokePaint,
      );
      canvas.drawLine(
        Offset(0, s * 0.6),
        Offset(-s * 0.3, s * 0.8),
        strokePaint,
      );
      canvas.restore();
    }
  }

  void _drawSparkle(Canvas canvas, _Particle p, Paint paint) {
    final s = p.size * 0.5;
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      path.moveTo(math.cos(angle) * s * 2, math.sin(angle) * s * 2);
      path.quadraticBezierTo(
        0,
        0,
        math.cos(angle + math.pi / 2) * s * 2,
        math.sin(angle + math.pi / 2) * s * 2,
      );
    }
    canvas.drawPath(path, paint);
    // Add inner glow
    canvas.drawCircle(
      Offset.zero,
      s * 0.8,
      Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.5),
    );
  }

  void _drawStar(Canvas canvas, _Particle p, Paint paint) {
    final s = p.size * 0.8;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * 4 * math.pi / 5 - math.pi / 2;
      if (i == 0) {
        path.moveTo(math.cos(angle) * s, math.sin(angle) * s);
      } else {
        path.lineTo(math.cos(angle) * s, math.sin(angle) * s);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, _Particle p, Paint paint) {
    final s = p.size * 0.6;
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 2 * math.pi / 5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, s), width: s, height: s * 1.5),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      s * 0.5,
      Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.8),
    );
  }

  void _drawChristmasTree(Canvas canvas, _Particle p, Paint paint) {
    final s = p.size;
    final path = Path();

    // Draw 3 layers of the tree
    for (int i = 0; i < 3; i++) {
      final yTop = -s * 0.8 + (i * s * 0.3);
      final yBottom = yTop + s * 0.5;
      final halfWidth = s * (0.3 + i * 0.2);

      path.moveTo(0, yTop);
      path.lineTo(halfWidth, yBottom);
      path.lineTo(-halfWidth, yBottom);
      path.close();
    }

    // Trunk
    final trunkWidth = s * 0.2;
    final trunkHeight = s * 0.3;
    path.addRect(
      Rect.fromLTWH(-trunkWidth / 2, s * 0.5, trunkWidth, trunkHeight),
    );

    canvas.drawPath(path, paint);

    // Add a tiny star on top
    final starPaint = Paint()
      ..color = Colors.amber.withValues(alpha: p.opacity);
    canvas.drawCircle(Offset(0, -s * 0.8), s * 0.15, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
                    'Sereno (Simulato)',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
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
