import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';
import '../application/activity_logger.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'admin_create_visit_page.dart';

class AdminCalendarPage extends ConsumerStatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  ConsumerState<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends ConsumerState<AdminCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<VisitWithCompany> _getEventsForDay(
    DateTime day,
    List<VisitWithCompany> visits,
  ) {
    return visits.where((v) => isSameDay(v.visit.scheduledAt, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(visitsWithCompanyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Calendario Ispezioni',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A237E),
            letterSpacing: -1,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFF1A237E).withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.today_rounded,
                color: Color(0xFF1A237E),
                size: 20,
              ),
              onPressed: () => setState(() => _focusedDay = DateTime.now()),
              tooltip: 'Vai a oggi',
            ),
          ),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (visits) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: TableCalendar<VisitWithCompany>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    eventLoader: (day) => _getEventsForDay(day, visits),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      todayTextStyle: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                      selectedDecoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF312E81)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x401A237E),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                      markerSize: 5,
                      markerMargin: const EdgeInsets.only(top: 4),
                      outsideDaysVisible: false,
                      defaultTextStyle: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A237E),
                        letterSpacing: -0.5,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      leftChevronIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF1A237E),
                          size: 20,
                        ),
                      ),
                      rightChevronIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF1A237E),
                          size: 20,
                        ),
                      ),
                      headerPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      weekendStyle: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    locale: 'it_IT',
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        return Positioned(
                          bottom: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Color(0xFF1A237E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attività Programmata',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE d MMMM',
                            'it_IT',
                          ).format(_selectedDay ?? _focusedDay),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildEventList(
                  _getEventsForDay(_selectedDay ?? _focusedDay, visits),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<VisitWithCompany> events) {
    if (events.isEmpty) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  size: 80,
                  color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nessun impegno pianificato',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Goditi un momento di pausa o pianifica nuove attività.',
                style: TextStyle(
                  color: Colors.blueGrey.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final v = events[index];
        final time = DateFormat('HH:mm').format(v.visit.scheduledAt);
        final statusColor = v.visit.status >= 2
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);
        final statusLabel = v.visit.status >= 2 ? 'Conclusa' : 'In Corso';

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisitWorkspacePage(
                        visitId: v.visit.id,
                        forceReadOnly: false,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        v.visit.companyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 14,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            v.visit.crop,
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: Colors.blueGrey.shade200),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              v.visit.inspectorName.isEmpty
                                  ? 'Ispez. non assegnata'
                                  : 'Insp: ${v.visit.inspectorName}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAssignInspectorDialog(v),
                              icon: const Icon(
                                Icons.person_add_rounded,
                                size: 16,
                              ),
                              label: const Text('Assegna'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ActionIcon(
                            icon: Icons.edit_note_rounded,
                            color: Colors.blue.shade600,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminCreateVisitPage(initialVisit: v),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _ActionIcon(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: const Text(
                                    'Elimina Visita',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  content: Text(
                                    'Vuoi davvero eliminare la visita di ${v.visit.companyName}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annulla'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade400,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Elimina'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final db = ref.read(appDatabaseProvider);
                                await (db.delete(
                                  db.visits,
                                )..where((t) => t.id.equals(v.visit.id))).go();

                                final logger = ref.read(activityLoggerProvider);
                                await logger.log(
                                  action: 'DELETE_VISIT',
                                  description:
                                      'Eliminata visita ${v.visit.id} per ${v.visit.companyName}',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAssignInspectorDialog(VisitWithCompany vwc) async {
    final db = ref.read(appDatabaseProvider);
    final inspectors = await db.select(db.inspectors).get();

    if (!mounted) return;

    if (inspectors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessun ispettore censito. Aggiungine uno nella gestione ispettori.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Column(
          children: [
            Icon(Icons.person_add_rounded, color: Color(0xFF1A237E), size: 32),
            SizedBox(height: 16),
            Text(
              'Seleziona Ispettore',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: inspectors.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final isp = inspectors[index];
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A237E),
                    radius: 18,
                    child: Text(
                      isp.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(
                    isp.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF1A237E),
                  ),
                  onTap: () async {
                    await (db.update(
                      db.visits,
                    )..where((t) => t.id.equals(vwc.visit.id))).write(
                      VisitsCompanion(inspectorName: Value(isp.fullName)),
                    );

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: 'ASSIGN_VISIT',
                      description:
                          'Assegnata visita ${vwc.visit.id} (Azienda: ${vwc.visit.companyName}) a ${isp.fullName} dal calendario',
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Visita assegnata a ${isp.fullName}'),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annulla',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
