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
import '../../../core/services/local_notifications_service.dart';

final _homeDateFilterProvider = StateProvider<DateTime?>((ref) => DateTime.now());

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final globalStatsAsync = ref.watch(globalStatsProvider);
    final visitsWithCompanyAsync = ref.watch(visitsWithCompanyProvider);
    final selectedDate = ref.watch(_homeDateFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, auth.username ?? 'Ispettore'),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 800 ? 32 : 16,
                vertical: MediaQuery.of(context).size.width > 800 ? 40 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              loading: () => const Center(child: CircularProgressIndicator()),
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
                                  loading: () => const Center(child: CircularProgressIndicator()),
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
                  _buildSectionHeader(
                    '📅 Pianificazione',
                    'Scadenze e prossime visite',
                  ),
                  const SizedBox(height: 24),
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

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF064E3B), // Emerald 900
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF064E3B), // Emerald 900
                    Color(0xFF065F46), // Emerald 800
                  ],
                ),
              ),
            ),
            const Positioned.fill(child: _NatureParticles()),
            // Abstract geometric background elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      _getGreeting().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF34D399),
                        size: 16,
                      ), // Emerald 400
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
    return visitsAsync.when(
      data: (visits) => SizedBox(
        height: 100, // Increased height for better proportions
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: 21, // Show more days for better planning
          itemBuilder: (context, index) {
            final date = DateTime.now()
                .subtract(const Duration(days: 3))
                .add(Duration(days: index));
            final isSelected =
                selectedDate != null &&
                date.year == selectedDate.year &&
                date.month == selectedDate.month &&
                date.day == selectedDate.day;
            final hasVisits = visits.any(
              (v) =>
                  v.visit.scheduledAt.year == date.year &&
                  v.visit.scheduledAt.month == date.month &&
                  v.visit.scheduledAt.day == date.day,
            );

            return _TimelineDay(
              date: date,
              isSelected: isSelected,
              hasVisits: hasVisits,
              onTap: () {
                ref.read(_homeDateFilterProvider.notifier).state = isSelected
                    ? null
                    : date;
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
        : visits
              .where(
                (v) =>
                    v.visit.scheduledAt.year == selectedDate.year &&
                    v.visit.scheduledAt.month == selectedDate.month &&
                    v.visit.scheduledAt.day == selectedDate.day,
              )
              .toList();

    if (filtered.isEmpty) {
      // Se non ci sono visite per il giorno selezionato (es. oggi), 
      // mostriamo le prossime 3 visite in generale.
      final upcoming = visits
          .where((v) => v.visit.scheduledAt.isAfter(DateTime.now().subtract(const Duration(minutes: 30))))
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
                  const Icon(Icons.next_plan_outlined, color: Color(0xFF059669), size: 18),
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
      await ref.read(auditsRepositoryProvider).simulateApiSync();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buongiorno,';
    if (hour < 18) return 'Buon pomeriggio,';
    return 'Buonasera,';
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
                            const SizedBox(height: 2),
                            Text(
                              '${widget.v.visit.crop} • ${widget.v.company.comune}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            color: Theme.of(context).primaryColor,
                            tooltip: 'Imposta Promemoria',
                            onPressed: () async {
                              final scheduledDate = widget.v.visit.scheduledAt;
                              // Schedule for 9 AM of the same day
                              final reminderTime = DateTime(
                                scheduledDate.year,
                                scheduledDate.month,
                                scheduledDate.day,
                                9,
                              );
                              final success = await ref
                                  .read(localNotificationsProvider)
                                  .scheduleNotification(
                                    id: widget.v.visit.id.hashCode,
                                    title: 'Promemoria Visita Ispettiva',
                                    body:
                                        'Oggi visita presso ${widget.v.visit.companyName}',
                                    scheduledDate: reminderTime,
                                  );

                              if (!context.mounted) return;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Promemoria impostato per il ${DateFormat('dd/MM HH:mm').format(reminderTime)}',
                                    ),
                                    backgroundColor: const Color(0xFF059669),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      reminderTime.isBefore(DateTime.now())
                                          ? 'Data nel passato: impossibile impostare il promemoria.'
                                          : 'Errore durante l\'impostazione del promemoria.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
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
        date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;

    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
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
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            else if (isToday)
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
                    : isWeekend ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
  const _NatureParticles();

  @override
  State<_NatureParticles> createState() => _NatureParticlesState();
}

class _NatureParticlesState extends State<_NatureParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = List.generate(35, (_) => _Particle());
  Offset _mousePos = Offset.zero;
  bool _isMouseInside = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  // Increased size for better visibility
  double size = math.Random().nextDouble() * 10 + 8;
  // Use integer speed multipliers to ensure seamless looping at 0.0 -> 1.0 transition
  int speedMultiplier = math.Random().nextInt(2) + 1;
  double opacity = math.Random().nextDouble() * 0.4 + 0.15;
  double noiseOffset = math.Random().nextDouble() * 2 * math.pi;
  double depth = math.Random().nextDouble();

  // Leaf specific
  double rotation = math.Random().nextDouble() * math.pi * 2;
  double rotationSpeed = (math.Random().nextDouble() - 0.5) * 3;
  Color color = [
    const Color(0xFF10B981), // Emerald
    const Color(0xFF059669), // Green 600
    const Color(0xFF34D399), // Emerald 400
    const Color(0xFF6EE7B7), // Emerald 300
    const Color(0xFFA7F3D0), // Mint
  ][math.Random().nextInt(5)];
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
      // (p.y + animationValue * speedMultiplier) % 1.0
      // is PERFECTLY continuous at 0.0 and 1.0 ONLY IF speedMultiplier is an integer.
      final yPos = (p.y + (animationValue * p.speedMultiplier)) % 1.0;

      // Pronounced horizontal swap for organic movement
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

      final path = Path();
      final w = p.size;
      final h = p.size * 1.6;
      path.moveTo(0, -h / 2);
      path.quadraticBezierTo(w / 2, 0, 0, h / 2);
      path.quadraticBezierTo(-w / 2, 0, 0, -h / 2);
      path.close();

      // Optional subtle vein for the leaf
      canvas.drawPath(path, paint);

      final veinPaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, -h / 2), Offset(0, h / 2), veinPaint);

      canvas.restore();
    }
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

class _DataHealthCard extends StatelessWidget {
  const _DataHealthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.05),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const Spacer(),
                const Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Salute Dati',
                  style: TextStyle(
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
