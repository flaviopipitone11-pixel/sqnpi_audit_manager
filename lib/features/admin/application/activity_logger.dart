import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqnpi_audit_manager/core/storage/app_database.dart';
import 'package:sqnpi_audit_manager/core/storage/db_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ActivityLogger(db);
});

class ActivityLogger {
  final AppDatabase db;

  ActivityLogger(this.db);

  Future<void> log({
    required String action,
    required String description,
    String actor = 'Admin',
  }) async {
    final id = const Uuid().v4();
    final createdAt = DateTime.now();

    // 1. Salva localmente
    await db
        .into(db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            id: id,
            action: action,
            description: description,
            actor: actor,
            createdAt: createdAt,
          ),
        );

    // 2. Push su Supabase (fire and forget)
    try {
      await Supabase.instance.client.from('activity_logs').insert({
        'id': id,
        'action': action,
        'description': description,
        'actor': actor,
        'created_at': createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Errore durante il sync del log su Supabase: $e');
    }
  }
}
