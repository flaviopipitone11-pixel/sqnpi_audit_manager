import 'package:flutter/services.dart';
// removed unused import
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/storage/app_database.dart';
import 'report_template.dart';

class ReportService {
  final AppDatabase db;
  final ReportTemplate template;

  ReportService(this.db, {this.template = const StandardSqnpiTemplate()});

  Future<Uint8List?> generateReport(String visitId) async {
    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return null;

    final company = await db.watchCompanyByVisitId(visitId).first;
    final attachments = await db.watchAttachmentsByVisitId(visitId).first;
    final nonConformita = await db.watchNonConformitaByVisit(visitId).first;
    final outcome = await db.watchVisitOutcomeSummary(visitId).first;
    final signatures = await db.watchSignaturesByVisitId(visitId).first;

    final pdf = pw.Document();

    pw.MemoryImage? logoBios;
    pw.MemoryImage? logoSqnpi;
    try {
      final logoData = await rootBundle.load('assets/images/logo_bios.png');
      logoBios = pw.MemoryImage(logoData.buffer.asUint8List());

      final logoSqnpiData = await rootBundle.load(
        'assets/images/logo_sqnpi.png',
      );
      logoSqnpi = pw.MemoryImage(logoSqnpiData.buffer.asUint8List());
    } catch (_) {}

    final pageTheme = template.buildPageTheme();

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) =>
            template.buildCoverPage(visit, company, logoBios, logoSqnpi),
      ),
    );

    // Main Report Content
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => template.buildPageHeader(
          context,
          visit,
          company,
          logoBios,
          logoSqnpi,
        ),
        footer: (context) => template.buildPageFooter(context, visit, company),
        build: (context) => [
          pw.SizedBox(height: 10),
          template.buildSummary(outcome),
          pw.SizedBox(height: 20),
          template.buildDetailSection(nonConformita),
          if (attachments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            template.buildAttachmentsSection(attachments),
          ],
          if (signatures.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            template.buildSignaturesSection(signatures),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> generateAndShareReport(String visitId) async {
    final bytes = await generateReport(visitId);
    if (bytes == null) return;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'verbale_ispezione_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }
}
