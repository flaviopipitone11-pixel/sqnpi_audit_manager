import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqnpi_audit_manager/core/storage/app_database.dart';
import 'package:sqnpi_audit_manager/features/audits/application/report_template.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Diagnose Full Document Generation for Visit 65183', () async {
    final origFile = File(
      '/Users/flaviopipitone/Library/Application Support/com.flavio.sqnpiAuditManager/sqnpi_audit_manager/app.sqlite',
    );
    final tmpFile = File('/tmp/test_app.sqlite');
    origFile.copySync(tmpFile.path);

    final db = AppDatabase(NativeDatabase(tmpFile));

    try {
      final visitId = '65183';
      final visit = (await db.watchVisitById(visitId).first)!;
      final company = await db.watchCompanyByVisitId(visitId).first;
      final attachmentsRaw = await db.watchAttachmentsByVisitId(visitId).first;
      final prevNc = await db.watchPreviousNcManagementByVisitId(visitId).first;
      final uecs = await db.watchUecsByVisitId(visitId).first;
      final massBalances = await db.watchMassBalancesByVisitId(visitId).first;
      final postHarvest = await db.watchPostHarvestByVisitId(visitId).first;
      final ncs = await db.watchNonConformitaByVisit(visitId).first;
      final closing = await db.watchClosingByVisitId(visitId).first;
      final signaturesRaw = await db.watchSignaturesByVisitId(visitId).first;

      final logoBiosFile = File(
        '/Users/flaviopipitone/sqnpi_audit_manager/assets/images/logo_bios_new.webp',
      );
      final logoSqnpiFile = File(
        '/Users/flaviopipitone/sqnpi_audit_manager/assets/images/logo_sqnpi.webp',
      );

      final logoBiosBytes = logoBiosFile.existsSync()
          ? logoBiosFile.readAsBytesSync()
          : null;
      final logoSqnpiBytes = logoSqnpiFile.existsSync()
          ? logoSqnpiFile.readAsBytesSync()
          : null;

      final pw.MemoryImage? logoBios = logoBiosBytes != null
          ? pw.MemoryImage(logoBiosBytes)
          : null;
      final pw.MemoryImage? logoSqnpi = logoSqnpiBytes != null
          ? pw.MemoryImage(logoSqnpiBytes)
          : null;

      final List<({VisitSignature signature, Uint8List? bytes})> signatures =
          [];
      for (final s in signaturesRaw) {
        Uint8List? bytes;
        if (s.filePath.isNotEmpty) {
          final f = File(s.filePath);
          if (f.existsSync()) {
            bytes = f.readAsBytesSync();
          }
        }
        signatures.add((signature: s, bytes: bytes));
      }

      final List<VisitAttachment> attachments = [];
      for (final a in attachmentsRaw) {
        attachments.add(a);
      }

      final template = const StandardSqnpiTemplate();
      final pageTheme = template.buildPageTheme();

      print('--- BUILDING ALL PAGES FOR VISIT 65183 ---');
      final pdf = pw.Document();

      // Cover Page
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (context) =>
              template.buildCoverPage(visit, company, logoBios, logoSqnpi),
        ),
      );

      // All Report Content in one continuous MultiPage flow
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          maxPages: 200,
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
          build: (context) => [
            ...template.buildCompanyInfoPage(visit, company),
            pw.NewPage(),
            ...template.buildPreviousAuditPage(
              visit,
              company,
              attachments,
              prevNc,
            ),
            pw.NewPage(),
            ...template.buildCultivationPhasePage(visit, uecs),
            pw.NewPage(),
            ...template.buildMassBalancePage(visit, massBalances),
            if (visit.visitType.contains('MARCHIO')) ...[
              pw.NewPage(),
              ...template.buildPostHarvestPage(postHarvest),
            ],
            pw.NewPage(),
            ...template.buildSummaryActivitiesPage(ncs, closing),
            pw.NewPage(),
            ...template.buildFinalEvaluationPage(
              closing,
              signatures,
              visit.scheduledAt,
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
    } finally {
      await db.close();
      if (tmpFile.existsSync()) tmpFile.deleteSync();
    }
  });

  test('Verify Section 4 items and exclusions', () async {
    final origFile = File(
      '/Users/flaviopipitone/Library/Application Support/com.flavio.sqnpiAuditManager/sqnpi_audit_manager/app.sqlite',
    );
    final tmpFile = File('/tmp/test_app_sec4.sqlite');
    origFile.copySync(tmpFile.path);
    final db = AppDatabase(NativeDatabase(tmpFile));

    try {
      final items = await db
          .watchChecklistItemsByFase(
            '4. Scelta varietale e materiale di moltiplicazione',
          )
          .first;
      final displayCodes = items.map((e) => e.displayCode.trim()).toList();
      final rawCodes = items.map((e) => e.code.trim()).toList();

      expect(displayCodes.contains('4.2'), isTrue);
      expect(displayCodes.contains('4.3'), isTrue);
      expect(displayCodes.contains('4.5.1'), isTrue);
      expect(displayCodes.contains('4.5.2'), isTrue);
      expect(displayCodes.contains('4.6'), isTrue);
      expect(rawCodes.contains('4.4'), isFalse);
      expect(rawCodes.contains('4.6'), isFalse);
    } finally {
      await db.close();
      if (tmpFile.existsSync()) tmpFile.deleteSync();
    }
  });
}
