import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;
import '../application/logs_export_service.dart';
import '../data/admin_repository.dart';

enum LogFilter { all, admin, inspectors }

final logFilterProvider = StateProvider<LogFilter>((ref) => LogFilter.all);
final logSearchQueryProvider = StateProvider<String>((ref) => '');
final logDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

class AdminLogsPage extends ConsumerStatefulWidget {
  const AdminLogsPage({super.key});

  @override
  ConsumerState<AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends ConsumerState<AdminLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminRepositoryProvider).syncActivityLogsWithCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: const Text(
          'Log Attività Sistema',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A237E),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _exportLogs(ref, context),
            icon: const Icon(Icons.download_rounded, color: Color(0xFF1A237E)),
            tooltip: 'Esporta in Excel',
          ),
          IconButton(
            onPressed: () => _showClearLogsDialog(context, ref),
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.redAccent,
            ),
            tooltip: 'Svuota Log',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          onChanged: (v) =>
                              ref.read(logSearchQueryProvider.notifier).state =
                                  v,
                          decoration: const InputDecoration(
                            hintText: 'Cerca per descrizione o attore...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: Colors.blueGrey,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _DateRangeButton(),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(LogFilter.all, 'Tutti', Icons.list_rounded),
                      _FilterChip(
                        LogFilter.admin,
                        'Admin',
                        Icons.shield_outlined,
                      ),
                      _FilterChip(
                        LogFilter.inspectors,
                        'Ispettori',
                        Icons.engineering_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _LogsList()),
        ],
      ),
    );
  }

  Future<void> _exportLogs(WidgetRef ref, BuildContext context) async {
    final db = ref.read(appDatabaseProvider);
    final filter = ref.read(logFilterProvider);
    final search = ref.read(logSearchQueryProvider);
    final range = ref.read(logDateRangeProvider);

    final query = db.select(db.activityLogs);
    if (filter == LogFilter.admin) {
      query.where((t) => t.actor.equals('Admin'));
    } else if (filter == LogFilter.inspectors) {
      query.where((t) => t.actor.equals('Admin').not());
    }
    if (search.isNotEmpty) {
      query.where(
        (t) => t.description.contains(search) | t.actor.contains(search),
      );
    }
    if (range != null) {
      query.where(
        (t) => t.createdAt.isBetweenValues(
          range.start,
          range.end.add(const Duration(days: 1)),
        ),
      );
    }

    final logs = await (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (logs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nessun log da esportare con i filtri attuali.'),
          ),
        );
      }
      return;
    }

    final service = ref.read(logsExportServiceProvider);
    await service.exportToExcel(logs);
  }

  Future<void> _showClearLogsDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Svuota Log'),
        content: const Text(
          'Sei sicuro di voler eliminare tutti i log di attività? Questa azione rimuoverà i dati sia localmente che dal Cloud e non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA TUTTO'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(adminRepositoryProvider).clearAllActivityLogs();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log svuotati correttamente.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante la pulizia: $e')),
          );
        }
      }
    }
  }
}

class _FilterChip extends ConsumerWidget {
  final LogFilter value;
  final String label;
  final IconData icon;

  const _FilterChip(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(logFilterProvider);
    final isSelected = current == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : const Color(0xFF1A237E),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1A237E),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (val) => ref.read(logFilterProvider.notifier).state = value,
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1A237E),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _DateRangeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(logDateRangeProvider);
    final isFiltered = range != null;

    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: range,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1A237E),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF1E293B),
                ),
              ),
              child: child!,
            );
          },
        );
        ref.read(logDateRangeProvider.notifier).state = picked;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered ? const Color(0xFF1A237E) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isFiltered ? Colors.white : Colors.blueGrey,
            ),
            if (isFiltered) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final filter = ref.watch(logFilterProvider);
    final search = ref.watch(logSearchQueryProvider);
    final range = ref.watch(logDateRangeProvider);

    return StreamBuilder<List<ActivityLog>>(
      stream: () {
        final query = db.select(db.activityLogs);
        if (filter == LogFilter.admin) {
          query.where((t) => t.actor.equals('Admin'));
        } else if (filter == LogFilter.inspectors) {
          query.where((t) => t.actor.equals('Admin').not());
        }
        if (search.isNotEmpty) {
          query.where(
            (t) => t.description.contains(search) | t.actor.contains(search),
          );
        }
        if (range != null) {
          query.where(
            (t) => t.createdAt.isBetweenValues(
              range.start,
              range.end.add(const Duration(days: 1)),
            ),
          );
        }
        return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .watch();
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nessun log disponibile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final prevLog = index > 0 ? logs[index - 1] : null;

            final isSameDay =
                prevLog != null &&
                log.createdAt.year == prevLog.createdAt.year &&
                log.createdAt.month == prevLog.createdAt.month &&
                log.createdAt.day == prevLog.createdAt.day;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSameDay) _buildDateSeparator(log.createdAt),
                _buildLogTile(log),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(date.year, date.month, date.day);

    String label;
    if (logDate == today) {
      label = 'OGGI';
    } else if (logDate == yesterday) {
      label = 'IERI';
    } else {
      label = DateFormat('dd MMMM yyyy', 'it_IT').format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLogTile(ActivityLog log) {
    final dateStr = DateFormat('HH:mm').format(log.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildActionIcon(log.action),
        title: Text(
          log.description,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                log.actor,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getActionColor(log.action).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            log.action.replaceAll('_', ' '),
            style: TextStyle(
              color: _getActionColor(log.action),
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(String action) {
    IconData icon;
    Color color;

    switch (action) {
      case 'IMPORT_EXCEL':
        icon = Icons.file_upload_rounded;
        color = Colors.green;
        break;
      case 'CREATE_VISIT_MANUAL':
        icon = Icons.add_task_rounded;
        color = Colors.indigo;
        break;
      case 'UPDATE_VISIT_MANUAL':
        icon = Icons.edit_calendar_rounded;
        color = Colors.blue;
        break;
      case 'DELETE_VISIT':
        icon = Icons.delete_sweep_rounded;
        color = Colors.red;
        break;
      case 'ASSIGN_VISIT':
      case 'ASSIGN_VISIT_MAP':
        icon = Icons.assignment_ind_rounded;
        color = Colors.teal;
        break;
      case 'ADD_INSPECTOR':
      case 'UPDATE_INSPECTOR':
        icon = Icons.person_add_rounded;
        color = Colors.blue;
        break;
      case 'DELETE_INSPECTOR':
        icon = Icons.person_remove_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'IMPORT_EXCEL':
        return Colors.green;
      case 'CREATE_VISIT_MANUAL':
        return Colors.indigo;
      case 'UPDATE_VISIT_MANUAL':
        return Colors.blue;
      case 'DELETE_VISIT':
        return Colors.red;
      case 'ASSIGN_VISIT':
      case 'ASSIGN_VISIT_MAP':
        return Colors.teal;
      case 'ADD_INSPECTOR':
      case 'UPDATE_INSPECTOR':
        return Colors.blue;
      case 'DELETE_INSPECTOR':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
