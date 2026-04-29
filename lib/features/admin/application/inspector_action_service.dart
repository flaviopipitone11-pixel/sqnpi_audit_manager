import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'activity_logger.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../data/admin_repository.dart';

final inspectorActionServiceProvider = Provider((ref) {
  final logger = ref.watch(activityLoggerProvider);
  final db = ref.watch(appDatabaseProvider);
  final adminRepo = ref.watch(adminRepositoryProvider);
  return InspectorActionService(logger, db, adminRepo);
});

class InspectorActionService {
  final ActivityLogger logger;
  final AppDatabase db;
  final AdminRepository adminRepo;

  InspectorActionService(this.logger, this.db, this.adminRepo);

  Future<void> _pushToCloud(String id) async {
    final updated = await (db.select(
      db.inspectors,
    )..where((t) => t.id.equals(id))).getSingle();
    await adminRepo.pushInspectorToCloud(updated);
  }

  Future<void> createAccount(String inspectorId, String inspectorName) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Update DB status
    await (db.update(db.inspectors)..where((t) => t.id.equals(inspectorId)))
        .write(const InspectorsCompanion(isActive: Value(true)));

    await _pushToCloud(inspectorId);

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

    await _pushToCloud(inspectorId);

    await logger.log(
      action: 'SEND_CREDENTIALS',
      description:
          'Credenziali inviate via Email ($email) e via SMS ($phone) a $inspectorName. Account attivato.',
    );
  }
}
