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
    // Importa SOLO se checklist_items è vuota.
    await db.ensureChecklistImportedFromAsset();

    // Crea visita demo SOLO se non ci sono visite.
    await db.seedIfEmpty();
  } catch (e, st) {
    // Così vedi in console *la riga esatta* che sta facendo il null-check (!)
    debugPrint('SEED/IMPORT ERROR: $e');
    debugPrintStack(stackTrace: st);

    // Rilancia con stacktrace preservato (così anche Riverpod mostra bene)
    Error.throwWithStackTrace(e, st);
  }
});

final visitOutcomeSummaryProvider =
    StreamProvider.family<VisitOutcomeSummary, String>((ref, visitId) {
      final db = ref.watch(appDatabaseProvider);
      return db.watchVisitOutcomeSummary(visitId);
    });
