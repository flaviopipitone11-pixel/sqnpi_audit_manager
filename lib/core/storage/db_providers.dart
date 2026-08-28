import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import '../domain/visit_outcome.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final seedDatabaseProvider = FutureProvider<void>((ref) async {
  final db = ref.read(appDatabaseProvider);

  try {
    await db.ensureChecklistImportedFromAsset();
    await db.seedIfEmpty();
  } catch (e) {
    debugPrint('----- [SEED ERROR] -----');
    debugPrint('$e');
    debugPrint('------------------------');
    rethrow;
  }
});

final visitOutcomeSummaryProvider =
    StreamProvider.family<VisitOutcomeSummary, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchVisitOutcomeSummary(visitId);
    });

final esclusioniLottoProvider =
    StreamProvider.family<
      List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>,
      String
    >((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchEsclusioniLottoByVisit(visitId);
    });

final nonConformitaByVisitProvider =
    StreamProvider.family<
      List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>,
      String
    >((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchNonConformitaByVisit(visitId);
    });

final visitProvider = StreamProvider.family<Visit?, String>((ref, visitId) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchVisitById(visitId);
});

final companyProvider = StreamProvider.family<VisitCompany?, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCompanyByVisitId(visitId);
});

final uecsProvider = StreamProvider.family<List<VisitUec>, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUecsByVisitId(visitId);
});

final closingProvider = StreamProvider.family<VisitClosing?, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchClosingByVisitId(visitId);
});

final fasiProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchFasi();
});

final responsesProvider =
    StreamProvider.family<List<ChecklistResponse>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchResponsesByVisitId(visitId);
    });

final attachmentsProvider =
    StreamProvider.family<List<VisitAttachment>, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchAttachmentsByVisitId(visitId);
    });
