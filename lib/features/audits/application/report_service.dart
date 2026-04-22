import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// removed unused import
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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

    // Get raw logo bytes to pass to the isolate
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      await _loadLogos();
    }
    final logoBiosBytes = _cachedLogoBios?.bytes;
    final logoSqnpiBytes = _cachedLogoSqnpi?.bytes;

    final t = template;
    final v = visit;
    final comp = company;
    final lb = logoBiosBytes;
    final ls = logoSqnpiBytes;
    final lvd = lastVisitDate;
    final att = attachments;
    final pn = prevNc;
    final uc = uecs;
    final mb = massBalances;
    final ph = postHarvest;
    final n = ncs;
    final cl = closing;
    final sig = signatures;

    return Isolate.run(
      () => _buildPdfBytes({
        'template': t,
        'visit': v,
        'company': comp,
        'logoBiosBytes': lb,
        'logoSqnpiBytes': ls,
        'lastVisitDate': lvd,
        'attachments': att,
        'prevNc': pn,
        'uecs': uc,
        'massBalances': mb,
        'postHarvest': ph,
        'ncs': n,
        'closing': cl,
        'signatures': sig,
      }),
    );
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
      final logoData = await rootBundle.load(
        'assets/images/logo_bios_new.webp',
      );
      _cachedLogoBios = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading Bios logo: $e');
    }

    try {
      final logoSqnpiData = await rootBundle.load(
        'assets/images/logo_sqnpi.webp',
      );
      _cachedLogoSqnpi = pw.MemoryImage(logoSqnpiData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading SQNPI logo: $e');
    }
  }

  // Top-level or static helper for compute
  static Future<Uint8List> _buildPdfBytes(Map<String, dynamic> args) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final Uint8List? logoBiosBytes = args['logoBiosBytes'];
    final Uint8List? logoSqnpiBytes = args['logoSqnpiBytes'];

    final pw.MemoryImage? logoBios = logoBiosBytes != null
        ? pw.MemoryImage(logoBiosBytes)
        : null;
    final pw.MemoryImage? logoSqnpi = logoSqnpiBytes != null
        ? pw.MemoryImage(logoSqnpiBytes)
        : null;
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
    final List<VisitSignature> signaturesList = args['signatures'] ?? [];

    final List<({VisitSignature signature, Uint8List? bytes})> signatures = [];
    for (final s in signaturesList) {
      Uint8List? bytes;
      if (s.filePath.isNotEmpty) {
        final f = File(s.filePath);
        try {
          if (f.existsSync()) {
            bytes = f.readAsBytesSync();
            // Optimize signature images
            try {
              final image = img.decodeImage(bytes);
              if (image != null) {
                final resized = img.copyResize(image, width: 400);
                bytes = Uint8List.fromList(img.encodePng(resized));
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      signatures.add((signature: s, bytes: bytes));
    }

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
          docTitle: 'Verbale di Ispezione SQNPI',
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
          docTitle: 'Verbale di Ispezione SQNPI',
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
          docTitle: 'Verbale di Ispezione SQNPI',
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
          docTitle: 'Verbale di Ispezione SQNPI',
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
            docTitle: 'Verbale di Ispezione SQNPI',
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
          docTitle: 'Verbale di Ispezione SQNPI',
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
          docTitle: 'Verbale di Ispezione SQNPI',
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

  Future<bool> generateAndShareReport(String visitId) async {
    final bytes = await generateReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    return await Printing.sharePdf(
      bytes: bytes,
      filename:
          'verbale_ispezione_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<bool> generateAndDownloadReport(String visitId) async {
    final bytes = await generateReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    final filename =
        'verbale_ispezione_${visit.companyName.replaceAll(' ', '_')}.pdf';

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Salva Report di Verifica',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);
        return true;
      }
      return false;
    } else {
      return await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: filename,
      );
    }
  }

  Future<Uint8List?> generateChecklistReport(String visitId) async {
    final data = await Future.wait([
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
      db.watchAllChecklistResponsesForVisit(visitId).first,
      db.watchAllChecklistItems().first,
      db.watchFasi().first,
    ]);

    final visit = data[0] as Visit?;
    if (visit == null) return null;

    final company = data[1] as VisitCompany?;
    final allResponses =
        data[2]
            as List<
              ({ChecklistResponse response, ChecklistItem item, VisitUec uec})
            >;
    final allItems = data[3] as List<ChecklistItem>;
    final phases = data[4] as List<String>;

    // Lazy load and cache logos
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      await _loadLogos();
    }
    final logoBiosBytes = _cachedLogoBios?.bytes;
    final logoSqnpiBytes = _cachedLogoSqnpi?.bytes;

    final t = template;
    final v = visit;
    final comp = company;
    final ar = allResponses;
    final ai = allItems;
    final p = phases;
    final lb = logoBiosBytes;
    final ls = logoSqnpiBytes;

    return Isolate.run(
      () => _buildChecklistPdfBytes({
        'template': t,
        'visit': v,
        'company': comp,
        'allResponses': ar,
        'allItems': ai,
        'phases': p,
        'logoBiosBytes': lb,
        'logoSqnpiBytes': ls,
      }),
    );
  }

  static Future<Uint8List> _buildChecklistPdfBytes(
    Map<String, dynamic> args,
  ) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>
    allResponses = args['allResponses'];
    final List<ChecklistItem> allItems = args['allItems'];
    final List<String> phases = args['phases'];
    final Uint8List? logoBiosBytes = args['logoBiosBytes'];
    final Uint8List? logoSqnpiBytes = args['logoSqnpiBytes'];

    final pw.MemoryImage? logoBios = logoBiosBytes != null
        ? pw.MemoryImage(logoBiosBytes)
        : null;
    final pw.MemoryImage? logoSqnpi = logoSqnpiBytes != null
        ? pw.MemoryImage(logoSqnpiBytes)
        : null;

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
          docTitle: 'Check-list di controllo SQNPI 2026',
        ),
        footer: (context) => template.buildPageFooter(context, visit, company),
        build: (context) => [
          ...template.buildChecklistPage(visit, allResponses, allItems, phases),
        ],
      ),
    );

    return pdf.save();
  }

  Stream<Uint8List> watchChecklistReportBytes(String visitId) {
    final controller = StreamController<void>();

    final sub1 = db.watchVisitById(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub2 = db.watchCompanyByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub3 = db.watchAllChecklistResponsesForVisit(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      controller.close();
    };

    return controller.stream
        .asyncMap((_) => generateChecklistReport(visitId))
        .where((b) => b != null)
        .cast<Uint8List>();
  }

  Future<bool> generateAndShareChecklistReport(String visitId) async {
    final bytes = await generateChecklistReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    return await Printing.sharePdf(
      bytes: bytes,
      filename:
          'checklist_completa_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<bool> generateAndDownloadChecklistReport(String visitId) async {
    final bytes = await generateChecklistReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    final filename =
        'checklist_completa_${visit.companyName.replaceAll(' ', '_')}.pdf';

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Salva Checklist Completa',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);
        return true;
      }
      return false;
    } else {
      return await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: filename,
      );
    }
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
    final attachments = (data[2] as List<VisitAttachment>? ?? [])
        .where((a) => a.filePath.isNotEmpty)
        .toList();

    // Lazy load and cache logos
    if (_cachedLogoBios == null || _cachedLogoSqnpi == null) {
      await _loadLogos();
    }
    final logoBiosBytes = _cachedLogoBios?.bytes;
    final logoSqnpiBytes = _cachedLogoSqnpi?.bytes;

    final t = template;
    final v = visit;
    final comp = company;
    final lb = logoBiosBytes;
    final ls = logoSqnpiBytes;
    final att = attachments;

    return Isolate.run(
      () => _buildPhotoGalleryPdfBytes({
        'template': t,
        'visit': v,
        'company': comp,
        'logoBiosBytes': lb,
        'logoSqnpiBytes': ls,
        'attachments': att,
      }),
    );
  }

  static Future<Uint8List> _buildPhotoGalleryPdfBytes(
    Map<String, dynamic> args,
  ) async {
    final ReportTemplate template = args['template'];
    final Visit visit = args['visit'];
    final VisitCompany? company = args['company'];
    final Uint8List? logoBiosBytes = args['logoBiosBytes'];
    final Uint8List? logoSqnpiBytes = args['logoSqnpiBytes'];

    final pw.MemoryImage? logoBios = logoBiosBytes != null
        ? pw.MemoryImage(logoBiosBytes)
        : null;
    final pw.MemoryImage? logoSqnpi = logoSqnpiBytes != null
        ? pw.MemoryImage(logoSqnpiBytes)
        : null;

    final List<VisitAttachment> attachments = args['attachments'] ?? [];

    final List<({VisitAttachment attachment, Uint8List? bytes})>
    attachmentData = [];

    for (final a in attachments) {
      Uint8List? bytes;
      if (a.filePath.isNotEmpty) {
        final f = File(a.filePath);
        try {
          if (f.existsSync()) {
            final rawBytes = f.readAsBytesSync();
            try {
              final image = img.decodeImage(rawBytes);
              if (image != null) {
                final resized = img.copyResize(
                  image,
                  width: image.width > image.height ? 1024 : null,
                  height: image.height >= image.width ? 1024 : null,
                );
                bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 75));
              } else {
                bytes = rawBytes;
              }
            } catch (_) {
              bytes = rawBytes;
            }
          }
        } catch (e) {
          // In background thread, we can't use ui.instantiateImageCodec easily
          // but we can at least read the raw bytes.
        }
      }
      attachmentData.add((attachment: a, bytes: bytes));
    }

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
          docTitle: 'Galleria Fotografica Ispezione SQNPI',
        ),
        footer: (context) => template.buildPageFooter(context, visit, company),
        build: (context) => [
          ...template.buildPhotoGalleryPage(visit, attachmentData),
        ],
      ),
    );

    return pdf.save();
  }

  Stream<Uint8List> watchPhotoGalleryReportBytes(String visitId) {
    final controller = StreamController<void>();

    final sub1 = db.watchVisitById(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub2 = db.watchCompanyByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);
    final sub3 = db.watchAttachmentsByVisitId(visitId).listen((_) {
      if (!controller.isClosed) controller.add(null);
    }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      controller.close();
    };

    return controller.stream
        .asyncMap((_) => generatePhotoGalleryReport(visitId))
        .where((b) => b != null)
        .cast<Uint8List>();
  }

  Future<bool> generateAndSharePhotoGalleryReport(String visitId) async {
    final bytes = await generatePhotoGalleryReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    return await Printing.sharePdf(
      bytes: bytes,
      filename: 'galleria_foto_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<bool> generateAndDownloadPhotoGalleryReport(String visitId) async {
    final bytes = await generatePhotoGalleryReport(visitId);
    if (bytes == null) return false;

    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return false;

    final filename =
        'galleria_foto_${visit.companyName.replaceAll(' ', '_')}.pdf';

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Salva Galleria Allegati',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsBytes(bytes);
        return true;
      }
      return false;
    } else {
      return await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: filename,
      );
    }
  }

  Future<bool> generateAndEmailAllReports(String visitId) async {
    // 1. Genera tutti e 3 i PDF
    final results = await Future.wait([
      generateReport(visitId),
      generateChecklistReport(visitId),
      generatePhotoGalleryReport(visitId),
      db.watchVisitById(visitId).first,
      db.watchCompanyByVisitId(visitId).first,
    ]);

    final reportBytes = results[0] as Uint8List?;
    final checklistBytes = results[1] as Uint8List?;
    final galleryBytes = results[2] as Uint8List?;
    final visit = results[3] as Visit?;
    // ignore: unused_local_variable
    final company = results[4] as VisitCompany?;

    if (reportBytes == null ||
        checklistBytes == null ||
        galleryBytes == null ||
        visit == null) {
      return false;
    }

    // 2. Salva temporaneamente i file
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final sanitizeName = visit.companyName.replaceAll(' ', '_');

    final reportFile = File(
      p.join(tempDir.path, 'verbale_ispezione_$sanitizeName.pdf'),
    );
    final checklistFile = File(
      p.join(tempDir.path, 'checklist_completa_$sanitizeName.pdf'),
    );
    final galleryFile = File(
      p.join(tempDir.path, 'galleria_foto_$sanitizeName.pdf'),
    );

    await Future.wait([
      reportFile.writeAsBytes(reportBytes),
      checklistFile.writeAsBytes(checklistBytes),
      galleryFile.writeAsBytes(galleryBytes),
    ]);

    // 3. Prepara il messaggio
    final recipient = 'flaviopipitone11@gmail.com';
    final subject = 'Report Ispezione SQNPI - ${visit.companyName}';
    final body =
        'Gentile ${visit.companyName},\n\nin allegato i report relativi all\'ispezione SQNPI effettuata.\n\nCordiali saluti.';

    // 4. Invio (Native macOS via AppleScript o Fallback Share)
    if (!kIsWeb && Platform.isMacOS) {
      try {
        final appleScript =
            '''
tell application "Mail"
    set theMessage to make new outgoing message with properties {subject:"$subject", content:"$body" & return & return}
    tell theMessage
        make new recipient at end of recipients with properties {address:"$recipient"}
        tell content
            make new attachment with properties {file name:POSIX file "${reportFile.path}"} at after last paragraph
            make new attachment with properties {file name:POSIX file "${checklistFile.path}"} at after last paragraph
            make new attachment with properties {file name:POSIX file "${galleryFile.path}"} at after last paragraph
        end tell
        set visible to true
    end tell
    activate
end tell
''';
        await Process.run('osascript', ['-e', appleScript]);
        return true;
      } catch (e) {
        debugPrint('Errore AppleScript: $e');
        // Se AppleScript fallisce, usa il fallback share
      }
    }

    // Fallback per altre piattaforme o se AppleScript fallisce
    // ignore: deprecated_member_use
    final result = await Share.shareXFiles(
      [
        XFile(reportFile.path),
        XFile(checklistFile.path),
        XFile(galleryFile.path),
      ],
      subject: subject,
      text: body,
    );

    return result.status == ShareResultStatus.success;
  }
}
