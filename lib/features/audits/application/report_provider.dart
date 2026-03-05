import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';
import 'report_service.dart';
import 'report_template.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportService(db, template: const StandardSqnpiTemplate());
});
