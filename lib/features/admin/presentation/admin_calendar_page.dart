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

  List<VisitWithCompany> _getEventsForDay(DateTime day, List<VisitWithCompany> visits) {
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
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.today_rounded, color: Color(0xFF1A237E)),
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
                margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
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
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
                    ),
                    todayTextStyle: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                    selectedDecoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red.shade300),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    formatButtonDecoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1A237E)),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A237E)),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  locale: 'it_IT',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_rounded, color: Color(0xFF1A237E), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Attività del ${DateFormat('dd MMMM', 'it_IT').format(_selectedDay ?? _focusedDay)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildEventList(_getEventsForDay(_selectedDay ?? _focusedDay, visits)),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.blueGrey.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              'Nessun impegno programmato',
              style: TextStyle(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final v = events[index];
        final time = DateFormat('HH:mm').format(v.visit.scheduledAt);
        final statusColor = v.visit.status >= 2 ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);
        final statusLabel = v.visit.status >= 2 ? 'Conclusa' : 'In Corso';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.03)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Text(
                                  time,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v.visit.companyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${v.visit.crop} • Insp. ${v.visit.inspectorName.isEmpty ? 'Non assegnato' : v.visit.inspectorName}',
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showAssignInspectorDialog(v),
                              icon: const Icon(Icons.person_add_alt_1, size: 14),
                              label: const Text('Assegna', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 32),
                                side: BorderSide(color: const Color(0xFF1A237E).withOpacity(0.3)),
                                foregroundColor: const Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminCreateVisitPage(initialVisit: v),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Modifica', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 32),
                                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                foregroundColor: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Elimina Visita'),
                                    content: Text('Vuoi davvero eliminare la visita di ${v.visit.companyName}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true), 
                                        child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final db = ref.read(appDatabaseProvider);
                                  await (db.delete(db.visits)..where((t) => t.id.equals(v.visit.id))).go();
                                  
                                  final logger = ref.read(activityLoggerProvider);
                                  await logger.log(
                                    action: 'DELETE_VISIT',
                                    description: 'Eliminata visita ${v.visit.id} per ${v.visit.companyName}',
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 14),
                              label: const Text('Elimina', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 32),
                                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                foregroundColor: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitWorkspacePage(visitId: v.visit.id, forceReadOnly: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF1A237E)),
                  ),
                ),
              ],
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
        const SnackBar(content: Text('Nessun ispettore censito. Aggiungine uno nella gestione ispettori.')),
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
            Text('Seleziona Ispettore', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), fontSize: 22)),
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
                  border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.05)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1A237E),
                    radius: 18,
                    child: Text(isp.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  title: Text(isp.fullName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A237E)),
                  onTap: () async {
                    await (db.update(db.visits)..where((t) => t.id.equals(vwc.visit.id))).write(
                      VisitsCompanion(inspectorName: Value(isp.fullName)),
                    );

                    final logger = ref.read(activityLoggerProvider);
                    await logger.log(
                      action: 'ASSIGN_VISIT',
                      description: 'Assegnata visita ${vwc.visit.id} (Azienda: ${vwc.visit.companyName}) a ${isp.fullName} dal calendario',
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Visita assegnata a ${isp.fullName}'),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: const Text('Annulla', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
