import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// removed unused import
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/domain/visit_outcome.dart';
import 'report_template.dart';

class ReportService {
  final AppDatabase db;
  final ReportTemplate template;

  ReportService(this.db, {this.template = const StandardSqnpiTemplate()});

  static pw.MemoryImage? _cachedLogoBios;
  static pw.MemoryImage? _cachedLogoSqnpi;

  Future<Uint8List?> generateReport(String visitId) async {
    // Fetch all necessary data in parallel
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
      db.watchAttachmentsByVisitId(visitId).first,
      db.watchNonConformitaByVisit(visitId).first,
      db.watchVisitOutcomeSummary(visitId).first,
      db.watchSignaturesByVisitId(visitId).first,
      db.watchMassBalanceByVisitId(visitId).first,
      db.watchClosingByVisitId(visitId).first,
      db.watchPreviousNcManagementByVisitId(visitId).first,
      db.watchPostHarvestByVisitId(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    final attachments = data[2] as List<VisitAttachment>;
    final nonConformita =
        data[3]
            as List<
              ({ChecklistItem item, ChecklistResponse response, VisitUec uec})
            >;
    final outcome = data[4] as VisitOutcomeSummary;
    final signatures = data[5] as List<VisitSignature>;
    final massBalance = data[6] as MassBalanceRecord?;
    final closing = data[7] as VisitClosing?;
    final prevNc = data[8] as VisitPreviousNcManagement?;
    final postHarvest = data[9] as PostHarvestRecord?;

    // New: Fetch all UECs and Lots for the dedicated section
    final allUecs = await db.watchUecsByVisitId(visitId).first;
    final allLots = await db.watchLotsByVisitId(visitId).first;
    final lotsByUec = <String, List<VisitLot>>{};
    for (final lot in allLots) {
      lotsByUec.putIfAbsent(lot.uecId, () => []).add(lot);
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

    // Pre-load all images for attachments and signatures to avoid disk I/O in building phase
    // This MUST happen here because File operations are async and compute needs the pre-loaded MemoryImage
    final attachmentImages = <String, pw.MemoryImage>{};
    for (final att in attachments) {
      final file = File(att.filePath);
      if (file.existsSync()) {
        try {
          attachmentImages[att.id] = pw.MemoryImage(await file.readAsBytes());
        } catch (_) {}
      }
    }

    final signatureImages = <String, pw.MemoryImage>{};
    for (final sig in signatures) {
      final file = File(sig.filePath);
      if (file.existsSync()) {
        try {
          signatureImages[sig.id] = pw.MemoryImage(await file.readAsBytes());
        } catch (_) {}
      }
    }

    // Build the PDF bytes
    // We offload the heavy PDF layout and saving to a background isolate
    // to keep the UI perfectly responsive.
    return compute(_buildPdfBytes, {
      'template': template,
      'visit': visit,
      'company': company,
      'outcome': outcome,
      'nonConformita': nonConformita,
      'attachments': attachments,
      'attachmentImages': attachmentImages,
      'signatures': signatures,
      'signatureImages': signatureImages,
      'logoBios': logoBios,
      'logoSqnpi': logoSqnpi,
      'massBalance': massBalance,
      'closing': closing,
      'allUecs': allUecs,
      'lotsByUec': lotsByUec,
      'prevNc': prevNc,
      'postHarvest': postHarvest,
    });
  }

  // Top-level or static helper for compute
  static Future<Uint8List> _buildPdfBytes(Map<String, dynamic> args) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final VisitOutcomeSummary outcome = args['outcome'];
    final List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>
    nonConformita = args['nonConformita'];
    final List<VisitAttachment> attachments = args['attachments'];
    final Map<String, pw.MemoryImage> attachmentImages =
        args['attachmentImages'];
    final List<VisitSignature> signatures = args['signatures'];
    final Map<String, pw.MemoryImage> signatureImages = args['signatureImages'];
    final pw.MemoryImage? logoBios = args['logoBios'];
    final pw.MemoryImage? logoSqnpi = args['logoSqnpi'];
    final MassBalanceRecord? massBalance = args['massBalance'];
    final VisitClosing? closing = args['closing'];
    final List<VisitUec> allUecs = args['allUecs'];
    final Map<String, List<VisitLot>> lotsByUec = args['lotsByUec'];
    final VisitPreviousNcManagement? prevNc = args['prevNc'];
    final PostHarvestRecord? postHarvest = args['postHarvest'];

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
          template.buildSummary(outcome, visit),
          pw.SizedBox(height: 20),
          template.buildAziendaCompliance(visit, company),
          pw.SizedBox(height: 20),
          template.buildPreviousNcSection(prevNc),
          pw.SizedBox(height: 20),
          template.buildUecDetailsSection(allUecs, lotsByUec),
          pw.SizedBox(height: 20),
          template.buildPostHarvestSection(postHarvest),
          pw.SizedBox(height: 20),
          template.buildMassBalanceSection(massBalance),
          pw.SizedBox(height: 20),
          // NC Summary and Details grouped
          if (nonConformita.isNotEmpty) ...[
            template.buildM904Summary(nonConformita),
            pw.SizedBox(height: 20),
            template.buildDetailSection(nonConformita),
          ] else
            template.buildDetailSection([]), // Will show "Nessuna NC"
          pw.SizedBox(height: 20),
          template.buildClosingSection(closing),
          pw.SizedBox(height: 20),
          template.buildAttachmentsSection(attachments, attachmentImages),
          pw.SizedBox(height: 20),
          template.buildSignaturesSection(signatures, signatureImages),
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

  Future<Uint8List?> generateChecklistReport(String visitId) async {
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
      db.watchAllChecklistResponsesForVisit(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    final responses =
        data[2]
            as List<
              ({ChecklistItem item, ChecklistResponse response, VisitUec uec})
            >;

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
      'responses': responses,
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
    final List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>
    responses = args['responses'];
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
        build: (context) => [
          pw.SizedBox(height: 10),
          template.buildFullChecklist(responses),
        ],
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
