import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// removed unused import
import 'dart:ui' as ui;
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
      db.watchAttachmentsByVisitId(visitId).first,
      db.watchPreviousNcManagementByVisitId(visitId).first,
      db.watchUecsByVisitId(visitId).first,
      db.watchMassBalancesByVisitId(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    final attachments = data[2] as List<VisitAttachment>? ?? [];
    final prevNc = data[3] as VisitPreviousNcManagement?;
    final uecs = data[4] as List<VisitUec>? ?? [];
    final massBalances = data[5] as List<MassBalanceRecord>? ?? [];
    final postHarvest = await db.watchPostHarvestByVisitId(visitId).first;
    final ncs = await db.watchNonConformitaByVisit(visitId).first;
    final closing = await db.watchClosingByVisitId(visitId).first;
    final signatures = await db.watchSignaturesByVisitId(visitId).first;

    final List<({VisitSignature signature, Uint8List? bytes})> signatureData =
        [];
    for (final s in signatures) {
      Uint8List? bytes;
      if (s.filePath.isNotEmpty) {
        final f = File(s.filePath);
        try {
          if (await f.exists()) {
            bytes = await f.readAsBytes();
          }
        } catch (_) {}
      }
      signatureData.add((signature: s, bytes: bytes));
    }

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
      await _loadLogos();
    }

    return compute(_buildPdfBytes, {
      'template': template,
      'visit': visit,
      'company': company,
      'logoBios': _cachedLogoBios,
      'logoSqnpi': _cachedLogoSqnpi,
      'lastVisitDate': lastVisitDate,
      'attachments': attachments,
      'prevNc': prevNc,
      'uecs': uecs,
      'massBalances': massBalances,
      'postHarvest': postHarvest,
      'ncs': ncs,
      'closing': closing,
      'signatures': signatureData,
    });
  }

  /// Stream that re-generates the PDF every time visit OR company data changes.
  Stream<Uint8List> watchReportBytes(String visitId) {
    final controller = StreamController<void>();

    // Listen to both tables; any change in either triggers a regen
    final sub1 = db.watchVisitById(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub2 = db.watchCompanyByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub3 = db.watchAttachmentsByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub4 = db.watchPreviousNcManagementByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub6 = db.watchMassBalancesByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub7 = db.watchPostHarvestByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub8 = db.watchNonConformitaByVisit(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub9 = db.watchClosingByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub10 = db.watchSignaturesByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      sub4.cancel();
      sub6.cancel();
      sub7.cancel();
      sub8.cancel();
      sub9.cancel();
      sub10.cancel();
      controller.close();
    };

    return controller.stream
        .asyncMap((_) => generateReport(visitId))
        .where((b) => b != null)
        .cast<Uint8List>();
  }

  Future<void> _loadLogos() async {
    try {
      final logoData = await rootBundle.load('assets/images/logo_bios.webp');
      _cachedLogoBios = pw.MemoryImage(logoData.buffer.asUint8List());

      final logoSqnpiData = await rootBundle.load(
        'assets/images/logo_sqnpi.webp',
      );
      _cachedLogoSqnpi = pw.MemoryImage(logoSqnpiData.buffer.asUint8List());
    } catch (_) {}
  }

  // Top-level or static helper for compute
  static Future<Uint8List> _buildPdfBytes(Map<String, dynamic> args) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final pw.MemoryImage? logoBios = args['logoBios'];
    final pw.MemoryImage? logoSqnpi = args['logoSqnpi'];
    final DateTime? lastVisitDate = args['lastVisitDate'] as DateTime?;
    final List<VisitAttachment> attachments =
        args['attachments'] as List<VisitAttachment>;
    final VisitPreviousNcManagement? prevNc =
        args['prevNc'] as VisitPreviousNcManagement?;
    final List<VisitUec> uecs = args['uecs'] as List<VisitUec>;
    final List<MassBalanceRecord> massBalances =
        args['massBalances'] as List<MassBalanceRecord>;
    final PostHarvestRecord? postHarvest =
        args['postHarvest'] as PostHarvestRecord?;
    final List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>
    ncs = args['ncs'];
    final VisitClosing? closing = args['closing'];
    final List<({VisitSignature signature, Uint8List? bytes})> signatures =
        args['signatures'] ?? [];

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
          template.buildCompanyInfoPage(
            visit,
            company,
            lastVisitDate: lastVisitDate,
          ),
        ],
      ),
    );

    // Reference Documents and Previous NC Management Page
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
          template.buildPreviousAuditPage(visit, company, attachments, prevNc),
        ],
      ),
    );

    // Page 4: Cultivation Phase
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
        build: (context) => [template.buildCultivationPhasePage(visit, uecs)],
      ),
    );

    // Page 5: Mass Balance
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
          template.buildMassBalancePage(visit, massBalances),
        ],
      ),
    );

    // Page 6: Post-Harvest Phase (Conditional)
    if (visit.visitType.contains('MARCHIO')) {
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
          footer: (context) =>
              template.buildPageFooter(context, visit, company),
          build: (context) => [template.buildPostHarvestPage(postHarvest)],
        ),
      );
    }

    // Page 7: Summary Activities Page (NC Table)
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
        build: (context) => [template.buildSummaryActivitiesPage(ncs, closing)],
      ),
    );

    // Page 8: Final Evaluation and Signatures
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
          template.buildFinalEvaluationPage(
            closing,
            signatures,
            visit.updatedAt,
          ),
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

  Future<Uint8List?> generatePhotoGalleryReport(String visitId) async {
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
      db.watchAttachmentsByVisitId(visitId).first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    final attachments = data[2] as List<VisitAttachment>? ?? [];

    final List<({VisitAttachment attachment, Uint8List? bytes})>
    attachmentData = [];
    for (final a in attachments) {
      Uint8List? bytes;
      if (a.filePath.isNotEmpty) {
        final f = File(a.filePath);
        try {
          if (await f.exists()) {
            final rawBytes = await f.readAsBytes();
            // Convert to PNG natively using flutter's ui codec to ensure compatibility with PDF generator.
            // This safely handles formats like HEIC and avoids native third-party plugin crashes.
            try {
              final codec = await ui.instantiateImageCodec(
                rawBytes,
                targetWidth: 1024, // Optional downscale to save memory
              );
              final frame = await codec.getNextFrame();
              final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
              bytes = byteData?.buffer.asUint8List() ?? rawBytes;
            } catch (codecError) {
              debugPrint('Codec error mapping image: $codecError');
              bytes = rawBytes; // Fallback
            }
          }
        } catch (e) {
          debugPrint('Error loading image ${a.filePath}: $e');
        }
      }
      attachmentData.add((attachment: a, bytes: bytes));
    }

    // Lazy load and cache logos
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      await _loadLogos();
    }

    return compute(_buildPhotoGalleryPdfBytes, {
      'template': template,
      'visit': visit,
      'company': company,
      'logoBios': _cachedLogoBios,
      'logoSqnpi': _cachedLogoSqnpi,
      'attachmentData': attachmentData,
    });
  }

  static Future<Uint8List> _buildPhotoGalleryPdfBytes(
    Map<String, dynamic> args,
  ) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final pw.MemoryImage? logoBios = args['logoBios'];
    final pw.MemoryImage? logoSqnpi = args['logoSqnpi'];
    final List<({VisitAttachment attachment, Uint8List? bytes})>
    attachmentData = args['attachmentData'];

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
          template.buildPhotoGalleryPage(visit, attachmentData),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> generateAndSharePhotoGalleryReport(String visitId) async {
    final bytes = await generatePhotoGalleryReport(visitId);
    if (bytes == null) return;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'galleria_foto_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }
}
