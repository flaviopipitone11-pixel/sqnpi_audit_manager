import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

final logsExportServiceProvider = Provider<LogsExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LogsExportService(db);
});

class LogsExportService {
  final AppDatabase db;

  LogsExportService(this.db);

  Future<void> exportToExcel(List<ActivityLog> logs) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Log Attività'];
    excel.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue('Data e Ora'),
      TextCellValue('Azione'),
      TextCellValue('Attore'),
      TextCellValue('Descrizione'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (final log in logs) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(log.createdAt)),
        TextCellValue(log.action.replaceAll('_', ' ')),
        TextCellValue(log.actor),
        TextCellValue(log.description),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final fileName =
          'Log_Attivita_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: fileName,
      );
    }
  }
}
