import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/app_database.dart';
import 'report_service.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  // Supponendo che il DB sia fornito tramite un provider
  // Se non c'è, lo prendiamo direttamente o tramite un altro provider
  final db = AppDatabase(); // Oppure ref.watch(databaseProvider)
  return ReportService(db);
});
