import 'package:flutter/foundation.dart';
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

  static pw.MemoryImage? _cachedLogoBios;
  static pw.MemoryImage? _cachedLogoSqnpi;

  Future<Uint8List?> generateReport(String visitId) async {
    // Fetch only necessary data for the cover page
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;

    // Find the last inspection date for this company (previous visits by CUAA)
    DateTime? lastVisitDate;
    final cuaa = company?.cuaa ?? '';
    if (cuaa.isNotEmpty) {
      final previousVisits = await db.watchVisitsByCuaa(cuaa).first;
      // Visits are ordered desc by scheduledAt; pick the first one that isn't current
      final previous = previousVisits.where((v) => v.id != visitId).toList();
      if (previous.isNotEmpty) {
        lastVisitDate = previous.first.scheduledAt;
      }
    }

    // Lazy load and cache logos
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      try {
        final logoData = await rootBundle.load('assets/images/logo_bios.webp');
        _cachedLogoBios = pw.MemoryImage(logoData.buffer.asUint8List());

        final logoSqnpiData = await rootBundle.load(
          'assets/images/logo_sqnpi.webp',
        );
        _cachedLogoSqnpi = pw.MemoryImage(logoSqnpiData.buffer.asUint8List());
      } catch (_) {}
    }

    final logoBios = _cachedLogoBios;
    final logoSqnpi = _cachedLogoSqnpi;

    // Build the PDF bytes
    return compute(_buildPdfBytes, {
      'template': template,
      'visit': visit,
      'company': company,
      'logoBios': logoBios,
      'logoSqnpi': logoSqnpi,
      'lastVisitDate': lastVisitDate,
    });
  }

  // Top-level or static helper for compute
  static Future<Uint8List> _buildPdfBytes(Map<String, dynamic> args) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final pw.MemoryImage? logoBios = args['logoBios'];
    final pw.MemoryImage? logoSqnpi = args['logoSqnpi'];
    final DateTime? lastVisitDate = args['lastVisitDate'] as DateTime?;

    final pdf = pw.Document();
    final pageTheme = template.buildPageTheme();

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) =>
            template.buildCoverPage(visit, company, logoBios, logoSqnpi),
      ),
    );

    // Company Info Page
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) => template.buildCompanyInfoPage(
          visit,
          company,
          lastVisitDate: lastVisitDate,
        ),
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

  Future<Uint8List?> generateChecklistReport(String visitId) async {
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
      db.watchAllChecklistResponsesForVisit(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    // Unused responses removed.

    // Lazy load and cache logos
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      try {
        final logoData = await rootBundle.load('assets/images/logo_bios.webp');
        _cachedLogoBios = pw.MemoryImage(logoData.buffer.asUint8List());

        final logoSqnpiData = await rootBundle.load(
          'assets/images/logo_sqnpi.webp',
        );
        _cachedLogoSqnpi = pw.MemoryImage(logoSqnpiData.buffer.asUint8List());
      } catch (_) {}
    }

    final logoBios = _cachedLogoBios;
    final logoSqnpi = _cachedLogoSqnpi;

    return compute(_buildChecklistPdfBytes, {
      'template': template,
      'visit': visit,
      'company': company,
      'logoBios': logoBios,
      'logoSqnpi': logoSqnpi,
    });
  }

  static Future<Uint8List> _buildChecklistPdfBytes(
    Map<String, dynamic> args,
  ) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final pw.MemoryImage? logoBios = args['logoBios'];
    final pw.MemoryImage? logoSqnpi = args['logoSqnpi'];

    final pdf = pw.Document();
    final pageTheme = template.buildPageTheme();

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
        build: (context) => [pw.SizedBox(height: 10)],
      ),
    );

    return pdf.save();
  }

  Future<void> generateAndShareChecklistReport(String visitId) async {
    final bytes = await generateChecklistReport(visitId);
    if (bytes == null) return;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'checklist_completa_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }
}
