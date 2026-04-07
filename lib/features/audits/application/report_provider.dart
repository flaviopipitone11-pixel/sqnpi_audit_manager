import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import 'report_service.dart';
import 'report_template.dart';

import 'dart:typed_data';

final reportServiceProvider = Provider<ReportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportService(db, template: const StandardSqnpiTemplate());
});

/// Reactively regenerates the PDF whenever the visit or company data changes.
final reportPdfProvider = StreamProvider.family<Uint8List, String>((
  ref,
  visitId,
) {
  final service = ref.watch(reportServiceProvider);
  return service.watchReportBytes(visitId);
});
