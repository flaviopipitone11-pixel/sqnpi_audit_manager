import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import 'report_service.dart';
import 'report_template.dart';

import 'dart:typed_data';

final reportServiceProvider = Provider<ReportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportService(db, template: const StandardSqnpiTemplate());
});

/// Genera in modo reattivo il PDF quando i dati della visita o dell'azienda cambiano.
final reportPdfProvider = StreamProvider.family<Uint8List, String>((
  ref,
  visitId,
) {
  final service = ref.watch(reportServiceProvider);
  return service.watchReportBytes(visitId);
});

/// Genera in modo reattivo il PDF della galleria fotografica.
final photoGalleryPdfProvider = StreamProvider.family<Uint8List, String>((
  ref,
  visitId,
) {
  final service = ref.watch(reportServiceProvider);
  return service.watchPhotoGalleryReportBytes(visitId);
});

/// Genera in modo reattivo il PDF dell'elenco di controllo completo.
final checklistPdfProvider = StreamProvider.family<Uint8List, String>((
  ref,
  visitId,
) {
  final service = ref.watch(reportServiceProvider);
  return service.watchChecklistReportBytes(visitId);
});
