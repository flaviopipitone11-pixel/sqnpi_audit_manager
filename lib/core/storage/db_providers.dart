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
