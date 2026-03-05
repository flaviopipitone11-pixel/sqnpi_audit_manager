import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import 'report_service.dart';
import 'report_template.dart';

import 'dart:typed_data';

final reportServiceProvider = Provider<ReportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportService(db, template: const StandardSqnpiTemplate());
});

final reportPdfProvider = FutureProvider.family<Uint8List, String>((
  ref,
  visitId,
) async {
  final service = ref.watch(reportServiceProvider);
  final bytes = await service.generateReport(visitId);
  return bytes ?? Uint8List(0);
});
