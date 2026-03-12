import 'dart:io';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';
import '../../audits/domain/visit_with_company.dart';

final adminExportServiceProvider = Provider<AdminExportService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AdminExportService(db);
});

class AdminExportService {
  final AppDatabase db;

  AdminExportService(this.db);

  Future<void> exportToExcel(List<VisitWithCompany> visits) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Riepilogo Visite'];
    excel.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue('ID Visita'),
      TextCellValue('Data Programmata'),
      TextCellValue('Azienda'),
      TextCellValue('Coltura'),
      TextCellValue('Stato'),
      TextCellValue('Tipo Visita'),
      TextCellValue('Ispettore'),
      TextCellValue('Indirizzo'),
      TextCellValue('Comune'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (final v in visits) {
      final statusLabel = _getStatusLabel(v.visit.status);
      sheet.appendRow([
        TextCellValue(v.visit.id),
        TextCellValue(dateFormat.format(v.visit.scheduledAt)),
        TextCellValue(v.company.ragioneSociale),
        TextCellValue(v.visit.crop),
        TextCellValue(statusLabel),
        TextCellValue(v.visit.visitType),
        TextCellValue(v.visit.inspectorName),
        TextCellValue(v.company.indirizzo),
        TextCellValue(v.company.comune),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Export_Visite_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: fileName,
      );
    }
  }

  Future<void> exportSummaryPdf(List<VisitWithCompany> visits) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Report Riepilogativo Dashboard Admin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Data', 'Azienda', 'Coltura', 'Stato'],
            data: visits.map((v) => [
              v.visit.id,
              dateFormat.format(v.visit.scheduledAt),
              v.company.ragioneSociale,
              v.visit.crop,
              _getStatusLabel(v.visit.status),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
            },
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text('Documento generato automaticamente dal sistema SQNPI Audit Manager.'),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Riepilogo_Admin_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  String _getStatusLabel(int status) {
    return switch (status) {
      0 => 'Programmata',
      1 => 'In Corso',
      2 => 'Chiusa',
      3 => 'Sincronizzata',
      _ => 'Sconosciuto',
    };
  }
}
