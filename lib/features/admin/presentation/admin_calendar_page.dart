import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../audits/data/audits_repository.dart';
import '../../audits/domain/visit_with_company.dart';
import '../../audits/presentation/visit_workspace_page.dart';

class AdminCalendarPage extends ConsumerStatefulWidget {
  const AdminCalendarPage({super.key});

  @override
  ConsumerState<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends ConsumerState<AdminCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<VisitWithCompany> _getEventsForDay(
    DateTime day,
    List<VisitWithCompany> visits,
  ) {
    return visits.where((v) {
      final s = v.visit.scheduledAt;
      return s.year == day.year && s.month == day.month && s.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(visitsWithCompanyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
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
                      Icons.calendar_month_rounded,
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
                          'CALENDARIO ISPEZIONE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          'Programmazione Visite',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.today_rounded, size: 16),
                    label: const Text('Oggi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
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
          ),
        ),
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Errore: $err')),
        data: (visits) {
          final filteredVisits = visits.where((v) {
            if (_selectedStatusFilter == null) return true;
            if (_selectedStatusFilter == 2) return v.visit.status >= 2;
            return v.visit.status == _selectedStatusFilter;
          }).toList();

          final dayEvents = _getEventsForDay(
            _selectedDay ?? _focusedDay,
            filteredVisits,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final topPadding = MediaQuery.of(context).size.width < 600
                  ? 120.0
                  : 130.0;

              if (isDesktop) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonna Sinistra: Mini Calendario + Filtri (Larghezza Fissa 360px)
                      SizedBox(
                        width: 360,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCalendarCard(filteredVisits),
                              const SizedBox(height: 16),
                              _buildFilterChipsRow(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Colonna Destra: Lista Visite del giorno selezionato
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildAgendaListSection(dayEvents),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Layout Mobile / Tablet Stretto: Verticale
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarCard(filteredVisits),
                    const SizedBox(height: 16),
                    _buildFilterChipsRow(),
                    const SizedBox(height: 24),
                    _buildAgendaListSection(dayEvents),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(List<VisitWithCompany> filteredVisits) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: TableCalendar<VisitWithCompany>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mese'},
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _getEventsForDay(day, filteredVisits),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            todayTextStyle: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
            selectedDecoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x401A237E),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            weekendTextStyle: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            leftChevronIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1A237E),
                size: 18,
              ),
            ),
            rightChevronIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF1A237E),
                size: 18,
              ),
            ),
            headerPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            weekendStyle: TextStyle(
              color: Color(0xFFFCA5A5),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          locale: 'it_IT',
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              final visitsList = events.cast<VisitWithCompany>();

              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: visitsList.take(3).map((v) {
                    Color dotColor = const Color(0xFFF59E0B);
                    if (v.visit.status >= 2) {
                      dotColor = const Color(0xFF10B981);
                    } else if (v.visit.status == 1) {
                      dotColor = const Color(0xFF3B82F6);
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _filterChip(null, 'Tutte')),
          const SizedBox(width: 4),
          Expanded(
            child: _filterChip(
              2,
              'Concluse',
              activeColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _filterChip(
              1,
              'In Corso',
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _filterChip(
              0,
              'Pianificate',
              activeColor: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(int? status, String label, {Color? activeColor}) {
    final isSelected = _selectedStatusFilter == status;
    final themeColor = activeColor ?? const Color(0xFF1A237E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatusFilter = isSelected ? null : status;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? themeColor : themeColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? themeColor
                  : themeColor.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : themeColor,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaListSection(List<VisitWithCompany> dayEvents) {
    final dateStr = DateFormat(
      'EEEE d MMMM yyyy',
      'it_IT',
    ).format(_selectedDay ?? _focusedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF1A237E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATTIVITÀ DEL GIORNO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Text(
                '${dayEvents.length} ${dayEvents.length == 1 ? 'visita' : 'visite'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (dayEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
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
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 48,
                  color: Colors.blueGrey.shade200,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nessuna ispezione programmata per questa data',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleziona un\'altra data dal calendario per consultare gli impegni.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayEvents.length,
            itemBuilder: (context, index) {
              final v = dayEvents[index];
              return _VisitAgendaCard(visitWithCompany: v);
            },
          ),
      ],
    );
  }
}

class _VisitAgendaCard extends StatelessWidget {
  final VisitWithCompany visitWithCompany;

  const _VisitAgendaCard({required this.visitWithCompany});

  @override
  Widget build(BuildContext context) {
    final v = visitWithCompany;
    final time = DateFormat('HH:mm').format(v.visit.scheduledAt);
    final statusColor = v.visit.status >= 2
        ? const Color(0xFF10B981)
        : (v.visit.status == 1
              ? const Color(0xFF3B82F6)
              : const Color(0xFFF59E0B));
    final statusLabel = v.visit.status >= 2
        ? 'Conclusa'
        : (v.visit.status == 1 ? 'In Corso' : 'Pianificata');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    v.visit.status >= 2
                        ? Icons.domain_verification_rounded
                        : Icons.business_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              time,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        v.visit.companyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 13,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            v.visit.crop,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              v.visit.inspectorName.isEmpty
                                  ? 'Non assegnato'
                                  : v.visit.inspectorName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF1A237E),
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
