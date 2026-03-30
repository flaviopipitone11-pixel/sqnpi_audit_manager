import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_logger.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import 'package:drift/drift.dart';

final inspectorActionServiceProvider = Provider((ref) {
  final logger = ref.watch(activityLoggerProvider);
  final db = ref.watch(appDatabaseProvider);
  return InspectorActionService(logger, db);
});

class InspectorActionService {
  final ActivityLogger logger;
  final AppDatabase db;

  InspectorActionService(this.logger, this.db);

  Future<void> createAccount(String inspectorId, String inspectorName) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Update DB status
    await (db.update(db.inspectors)..where((t) => t.id.equals(inspectorId)))
        .write(const InspectorsCompanion(isActive: Value(true)));

    await logger.log(
      action: 'CREATE_ACCOUNT',
      description: 'Account attivato e pronto per l\'uso (Isp. $inspectorName)',
    );
  }

  Future<void> sendCredentials(
    String inspectorId,
    String inspectorName,
    String email,
    String phone,
  ) async {
    // Simulate multi-channel delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Update DB status to active when credentials are sent
    await (db.update(db.inspectors)..where((t) => t.id.equals(inspectorId)))
        .write(const InspectorsCompanion(isActive: Value(true)));

    await logger.log(
      action: 'SEND_CREDENTIALS',
      description:
          'Credenziali inviate via Email ($email) e via SMS ($phone) a $inspectorName. Account attivato.',
    );
  }
}
