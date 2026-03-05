import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/storage/app_database.dart';
import '../data/audits_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import 'widgets/dashboard_stats.dart';

import 'widgets/visits_map_view.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/services/local_notifications_service.dart';
import '../domain/visit_with_company.dart';

// --- Providers ---
final _dashboardViewModeProvider = StateProvider<bool>(
  (ref) => false,
); // false: lista, true: mappa

final _myVisitsProvider = StreamProvider.autoDispose<List<Visit>>((ref) {
  final repo = ref.watch(auditsRepositoryProvider);
  return repo.watchMyVisits();
});

final _dashboardFilterProvider = StateProvider<int?>((ref) => null);
final _dashboardDateFilterProvider = StateProvider<DateTime?>((ref) => null);

final _visitsWithCompanyProvider =
    StreamProvider.autoDispose<List<VisitWithCompany>>((ref) {
      return ref.watch(auditsRepositoryProvider).watchVisitsWithCompanies();
    });

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(_myVisitsProvider);
    final selectedFilter = ref.watch(_dashboardFilterProvider);
    final selectedDate = ref.watch(_dashboardDateFilterProvider);
    final auth = ref.watch(authControllerProvider);

    return visitsAsync.when(
      data: (visits) {
        final daIniziare = visits.where((v) => v.status == 0).length;
        final inCorso = visits.where((v) => v.status == 1).length;
        final daSincronizzare = visits.where((v) => v.status == 2).length;

        final displayVisits = visits.where((v) {
          final matchesStatus =
              selectedFilter == null || v.status == selectedFilter;
          final matchesDate =
              selectedDate == null ||
              (v.scheduledAt.year == selectedDate.year &&
                  v.scheduledAt.month == selectedDate.month &&
                  v.scheduledAt.day == selectedDate.day);
          return matchesStatus && matchesDate;
        }).toList();

        if (visits.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nessuna visita assegnata',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tocca il pulsante in basso per sincronizzare\nle tue visite dal portale',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _syncWithPortal(context, ref),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizza dal Portale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ciao, ${auth.username ?? 'Ispettore'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Le tue Visite',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${visits.length} visite trovate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _syncWithPortal(context, ref),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sincronizza'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // -- Sync Status Bar --
            Consumer(
              builder: (context, ref, _) {
                final sync = ref.watch(syncStatusProvider);
                if (sync.state == SyncState.online) {
                  return const SizedBox.shrink();
                }
                final (color, text, icon) = switch (sync.state) {
                  SyncState.offline => (
                    Colors.red.shade700,
                    'Sei offline. Le modifiche verranno salvate in locale.',
                    Icons.cloud_off,
                  ),
                  SyncState.needsSync => (
                    Colors.orange.shade700,
                    '${sync.pendingItems} modifiche in attesa di sincronizzazione.',
                    Icons.cloud_upload,
                  ),
                  SyncState.syncing => (
                    Colors.blue.shade700,
                    'Sincronizzazione in corso...',
                    Icons.sync,
                  ),
                  _ => (Colors.grey, '', Icons.help),
                };

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (sync.state == SyncState.needsSync)
                        TextButton(
                          onPressed: () => _syncWithPortal(context, ref),
                          child: const Text('Sincronizza ora'),
                        ),
                    ],
                  ),
                );
              },
            ),
            // -- Summary Cards Section --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Da Iniziare',
                      count: daIniziare,
                      icon: Icons.access_time_filled,
                      color: Colors.orange.shade700,
                      bgColor: Colors.orange.shade50,
                      isSelected: selectedFilter == 0,
                      onTap: () {
                        ref.read(_dashboardFilterProvider.notifier).state =
                            selectedFilter == 0 ? null : 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'In Corso',
                      count: inCorso,
                      icon: Icons.loop,
                      color: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                      isSelected: selectedFilter == 1,
                      onTap: () {
                        ref.read(_dashboardFilterProvider.notifier).state =
                            selectedFilter == 1 ? null : 1;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Chiuse',
                      count: daSincronizzare,
                      icon: Icons.check_circle,
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                      isSelected: selectedFilter == 2,
                      onTap: () {
                        ref.read(_dashboardFilterProvider.notifier).state =
                            selectedFilter == 2 ? null : 2;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DashboardStats(visits: visits),
            const SizedBox(height: 8),
            // -- Titolo Lista e Timeline --
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 0.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Esplora le visite',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.list),
                        label: Text('Lista'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.map),
                        label: Text('Mappa'),
                      ),
                    ],
                    selected: {ref.watch(_dashboardViewModeProvider)},
                    onSelectionChanged: (val) =>
                        ref.read(_dashboardViewModeProvider.notifier).state =
                            val.first,
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (ref.watch(_dashboardViewModeProvider))
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final visitsWithCompanyAsync = ref.watch(
                          _visitsWithCompanyProvider,
                        );
                        return visitsWithCompanyAsync.when(
                          data: (data) => VisitsMapView(visits: data),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) =>
                              Center(child: Text('Errore mappa: $e')),
                        );
                      },
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 70,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: 14, // Mostriamo 14 giorni (2 settimane)
                  itemBuilder: (context, index) {
                    // Partiamo da 3 giorni fa
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
                          v.scheduledAt.year == date.year &&
                          v.scheduledAt.month == date.month &&
                          v.scheduledAt.day == date.day,
                    );

                    return _TimelineDay(
                      date: date,
                      isSelected: isSelected,
                      hasVisits: hasVisits,
                      onTap: () {
                        ref.read(_dashboardDateFilterProvider.notifier).state =
                            isSelected ? null : date;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (displayVisits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(48.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Nessuna visita in questo stato.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      for (int i = 0; i < displayVisits.length; i++) ...[
                        _VisitCard(visit: displayVisits[i]),
                        if (i < displayVisits.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Errore: $e')),
    );
  }

  Future<void> _syncWithPortal(BuildContext context, WidgetRef ref) async {
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
        Navigator.of(context).pop(); // Chiudi loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizzazione completata!')),
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

class _VisitCard extends ConsumerWidget {
  const _VisitCard({required this.visit});

  final Visit visit;

  void _openMaps(BuildContext context) async {
    final query = Uri.encodeComponent('${visit.companyName} ${visit.crop}');
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire le mappe.')),
        );
      }
    }
  }

  void _addToCalendar(BuildContext context) {
    final event = Event(
      title: 'Visita SQNPI - ${visit.companyName}',
      description: 'Ispezione per coltura: ${visit.crop}',
      location: visit.companyName,
      startDate: visit.scheduledAt,
      endDate: visit.scheduledAt.add(const Duration(hours: 2)),
    );
    Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _scheduleReminder(BuildContext context, WidgetRef ref) async {
    final notificationsService = ref.read(localNotificationsProvider);

    // Request permissions first
    await notificationsService.requestPermissions();

    // Schedule 1 hour before
    final reminderTime = visit.scheduledAt.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La visita è troppo vicina per impostare un promemoria (min 1 ora).',
            ),
          ),
        );
      }
      return;
    }

    try {
      await notificationsService.scheduleNotification(
        id: visit.id.hashCode,
        title: 'Promemoria Visita Tra 1 Ora',
        body: 'Visita presso ${visit.companyName} per ${visit.crop}',
        scheduledDate: reminderTime,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promemoria impostato per 1 ora prima della visita.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore impostazione promemoria: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = visit.scheduledAt;
    final formattedDate =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    switch (visit.status) {
      case 0: // daIniziare
        statusColor = Colors.orange;
        break;
      case 1: // inCorso
        statusColor = Colors.blue;
        break;
      case 2: // chiusaDaSincronizzare
        statusColor = Colors.green;
        break;
      case 3: // sincronizzata
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go('/visit/${visit.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        visit.companyName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        visitStatusLabel(visit.status).toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Icon(
                      Icons.grass_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        visit.crop,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openMaps(context),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Naviga'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _addToCalendar(context),
                      icon: const Icon(Icons.event, size: 18),
                      label: const Text('Salva in Calendario'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _scheduleReminder(context, ref),
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text('Ricordamelo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade100,
                        foregroundColor: Colors.amber.shade900,
                      ),
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineDay extends StatelessWidget {
  const _TimelineDay({
    required this.date,
    required this.isSelected,
    required this.hasVisits,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool hasVisits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    final color = isSelected
        ? Theme.of(context).colorScheme.secondary
        : isToday
        ? Theme.of(context).primaryColor
        : Colors.grey.shade400;

    final weekDays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekDays[date.weekday - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (hasVisits) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
