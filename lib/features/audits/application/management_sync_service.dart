import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqnpi_audit_manager/core/storage/app_database.dart';
import 'package:sqnpi_audit_manager/core/storage/db_providers.dart';
import 'package:sqnpi_audit_manager/features/admin/application/activity_logger.dart';

final managementSyncServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(activityLoggerProvider);
  return ManagementSyncService(db, logger);
});

class ManagementSyncService {
  final AppDatabase db;
  final ActivityLogger logger;

  ManagementSyncService(this.db, this.logger);

  /// Simulates syncing visit data to the external management system.
  Future<bool> syncVisitToManagement(String visitId) async {
    try {
      // 1. Gather all data as a single JSON object (the "Payload")
      final data = await _prepareSyncPayload(visitId);

      if (kDebugMode) {
        print('--- SYNC PAYLOAD FOR MANAGEMENT SYSTEM ---');
        print(jsonEncode(data));
        print('-----------------------------------------');
      }

      // 2. Simulate API Call to the management system
      await Future.delayed(const Duration(seconds: 2));

      // 3. Log the success
      await logger.log(
        action: 'MANAGEMENT_SYNC_SUCCESS',
        description:
            'Dati della visita $visitId inviati con successo al gestionale aziendale.',
        actor: data['inspector_name'] ?? 'Ispettore',
      );

      return true;
    } catch (e) {
      await logger.log(
        action: 'MANAGEMENT_SYNC_ERROR',
        description: 'Errore durante l\'invio al gestionale: $e',
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> _prepareSyncPayload(String visitId) async {
    final visit = await db.watchVisitById(visitId).first;
    final company = await db.watchCompanyByVisitId(visitId).first;
    final uecs = await db.watchUecsByVisitId(visitId).first;
    final responses = await db
        .watchAllChecklistResponsesForVisit(visitId)
        .first;
    final signatures = await db.watchSignaturesByVisitId(visitId).first;

    return {
      'visit_id': visitId,
      'sync_at': DateTime.now().toIso8601String(),
      'inspector_name': visit?.inspectorName,
      'company': {
        'name': company?.ragioneSociale,
        'cuaa': company?.cuaa,
        'address':
            '${company?.indirizzo}, ${company?.comune} (${company?.provincia})',
        'lat': company?.latitude,
        'lng': company?.longitude,
      },
      'audit_data': {
        'scheduled_at': visit?.scheduledAt.toIso8601String(),
        'crop': visit?.crop,
        'uecs_count': uecs.length,
        'responses': responses
            .map(
              (r) => {
                'code': r.item.code,
                'conformita': r.response.conformita, // 0: OK, 1: NA, 2: KO
                'rilievo': r.response.rilievoNc,
                'note': r.response.note,
              },
            )
            .toList(),
      },
      'signatures': signatures
          .map(
            (s) => {
              'type': s.signatureType,
              'signer': s.signerName,
              'file_present': s.filePath.isNotEmpty,
            },
          )
          .toList(),
      'status': 'CLOSED',
    };
  }
}
