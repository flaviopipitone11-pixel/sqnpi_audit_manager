import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart' hide Column;

class AdminLogsPage extends ConsumerWidget {
  const AdminLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Log Attività Sistema', 
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ActivityLog>>(
        stream: (db.select(db.activityLogs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                    child: Icon(Icons.history_rounded, size: 64, color: const Color(0xFF1A237E).withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Nessun log disponibile', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A237E))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateStr = DateFormat('dd MMM yyyy • HH:mm', 'it_IT').format(log.createdAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildActionIcon(log.action),
                  title: Text(log.description, 
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(dateStr, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getActionColor(log.action).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.action.replaceAll('_', ' '),
                          style: TextStyle(color: _getActionColor(log.action), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(log.actor, style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade300, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'IMPORT_EXCEL': return Colors.green;
      case 'CREATE_VISIT_MANUAL': return Colors.indigo;
      case 'UPDATE_VISIT_MANUAL': return Colors.blue;
      case 'DELETE_VISIT': return Colors.red;
      case 'ASSIGN_VISIT':
      case 'ASSIGN_VISIT_MAP': return Colors.teal;
      case 'ADD_INSPECTOR':
      case 'UPDATE_INSPECTOR': return Colors.blue;
      case 'DELETE_INSPECTOR': return Colors.red;
      default: return Colors.grey;
    }
  }
}
