import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import '../../audits/data/audits_repository.dart';
import 'package:intl/intl.dart';

enum AlertSeverity { critical, warning, info }

class AdminAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime? date;

  AdminAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.date,
  });
}

final adminAlertsProvider = Provider<List<AdminAlert>>((ref) {
  final visitsAsync = ref.watch(visitsWithCompanyProvider);
  final inspectorsAsync = ref.watch(StreamProvider((ref) {
    final db = ref.watch(appDatabaseProvider);
    return db.select(db.inspectors).watch();
  }));

  final visits = visitsAsync.asData?.value ?? [];
  final inspectors = inspectorsAsync.asData?.value ?? [];
  
  final List<AdminAlert> alerts = [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final threeDaysFromNow = today.add(const Duration(days: 3));

  // 1. Overdue Visits (Ritardi)
  final overdue = visits.where((v) => v.visit.status < 2 && v.visit.scheduledAt.isBefore(today)).toList();
  for (var v in overdue) {
    alerts.add(AdminAlert(
      id: 'overdue_${v.visit.id}',
      title: 'Ispezione Scaduta',
      message: '${v.visit.companyName} prevista per il ${DateFormat('dd/MM').format(v.visit.scheduledAt)}',
      severity: AlertSeverity.critical,
      date: v.visit.scheduledAt,
    ));
  }

  // 2. Upcoming Deadlines (Prossime Scadenze)
  final upcoming = visits.where((v) => 
    v.visit.status < 2 && 
    v.visit.scheduledAt.isAfter(today.subtract(const Duration(seconds: 1))) && 
    v.visit.scheduledAt.isBefore(threeDaysFromNow)
  ).toList();
  for (var v in upcoming) {
    alerts.add(AdminAlert(
      id: 'upcoming_${v.visit.id}',
      title: 'Scadenza Imminente',
      message: 'Visita ${v.visit.companyName} tra ${v.visit.scheduledAt.difference(today).inDays} giorni',
      severity: AlertSeverity.warning,
      date: v.visit.scheduledAt,
    ));
  }

  // 3. Workload Check (Carico Lavoro)
  final Map<String, Map<String, int>> inspectorWorkload = {}; // {Date: {Inspector: count}}
  for (var v in visits) {
    if (v.visit.status < 2 && v.visit.inspectorName.isNotEmpty) {
      final dateKey = DateFormat('yyyy-MM-dd').format(v.visit.scheduledAt);
      inspectorWorkload.putIfAbsent(dateKey, () => {});
      inspectorWorkload[dateKey]![v.visit.inspectorName] = (inspectorWorkload[dateKey]![v.visit.inspectorName] ?? 0) + 1;
    }
  }

  inspectorWorkload.forEach((date, workloads) {
    workloads.forEach((name, count) {
      if (count > 2) { // More than 2 visits a day is a warning
        alerts.add(AdminAlert(
          id: 'workload_${date}_$name',
          title: 'Sovraccarico Ispettore',
          message: '$name ha $count visite il $date',
          severity: AlertSeverity.warning,
        ));
      }
    });
  });

  // 4. Inactive Inspectors (Conti da Attivare)
  final inactive = inspectors.where((i) => !i.isActive).toList();
  for (var i in inactive) {
    alerts.add(AdminAlert(
      id: 'inactive_${i.id}',
      title: 'Account da Attivare',
      message: "L'ispettore ${i.fullName} non ha ancora ricevuto le credenziali",
      severity: AlertSeverity.info,
    ));
  }

  // Sort by severity (critical first) then date
  alerts.sort((a, b) {
    final severityComp = a.severity.index.compareTo(b.severity.index);
    if (severityComp != 0) return severityComp;
    if (a.date != null && b.date != null) return a.date!.compareTo(b.date!);
    return 0;
  });

  return alerts;
});
