import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final activityLoggerProvider = Provider((ref) {
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
    await db.into(db.activityLogs).insert(
      ActivityLogsCompanion.insert(
        action: action,
        description: description,
        actor: actor,
        createdAt: DateTime.now(),
      ),
    );
  }
}
