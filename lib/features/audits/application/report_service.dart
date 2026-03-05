import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/storage/app_database.dart';
import 'report_template.dart';

class ReportService {
  final AppDatabase db;
  final ReportTemplate template;

  ReportService(this.db, {this.template = const StandardSqnpiTemplate()});

  Future<void> generateAndShareReport(String visitId) async {
    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return;

    final company = await db.watchCompanyByVisitId(visitId).first;
    final attachments = await db.watchAttachmentsByVisitId(visitId).first;
    final nonConformita = await db.watchNonConformitaByVisit(visitId).first;
    final outcome = await db.watchVisitOutcomeSummary(visitId).first;

    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo_bios.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(template.style.margin),
        build: (context) => [
          template.buildHeader(visit, company, logo),
          pw.SizedBox(height: 20),
          template.buildSummary(outcome),
          pw.SizedBox(height: 20),
          template.buildDetailSection(nonConformita),
          if (attachments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            template.buildAttachmentsSection(attachments),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'verbale_ispezione_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }
}
