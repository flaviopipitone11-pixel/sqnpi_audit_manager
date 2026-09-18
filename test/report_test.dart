import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqnpi_audit_manager/core/storage/app_database.dart';
import 'package:sqnpi_audit_manager/features/audits/application/checklist_item_helpers.dart';
import 'package:sqnpi_audit_manager/features/audits/application/report_template.dart';
import 'package:pdf/pdf.dart';
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

      printOnFailure('--- BUILDING ALL PAGES FOR VISIT 65183 ---');
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

  test('Verify ChecklistItemHelpers.getEsclSospText accuracy', () {
    ChecklistItem createItem(String code, {String frequenzaSingolo = ''}) {
      return ChecklistItem(
        code: code,
        versionId: 'v1',
        fase: '0.0',
        obbligo: '',
        indicatorType: '',
        deroghe: '',
        noteNorma: '',
        tipologiaControllo: '',
        frequenzaSingolo: frequenzaSingolo,
        frequenzaAssociato: '',
        gravitaUecText: '',
        esclusioneUecText: '',
        gravitaOperatoreText: '',
        esclusioneOperatoreText: '',
        colGText: '',
        disposizioniRegionali: '',
        esclusioneLottoText: '',
        hasEsclusioneLotto: false,
        sortOrder: 1,
      );
    }

    // 0.10, 0.9, 0.13 MUST NOT have exclusions
    expect(ChecklistItemHelpers.getEsclSospText(createItem('0.10')), isNull);
    expect(ChecklistItemHelpers.getEsclSospText(createItem('0.9')), isNull);
    expect(ChecklistItemHelpers.getEsclSospText(createItem('0.13')), isNull);

    // 0.1 and 0.2 MUST have "SI' (esclusione lotto) in caso di assenza completa delle registrazioni"
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('0.1')),
      contains('in caso di assenza completa delle registrazioni'),
    );
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('0.2')),
      contains('in caso di assenza completa delle registrazioni'),
    );

    // 0.8 Sospensione operatore
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('0.8')),
      contains('Sospensione operatore'),
    );

    // 0.11 esclusione UEC in caso di mancata AC
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('0.11')),
      contains('esclusione UEC in caso di mancata AC'),
    );

    // 0.12 Sospensione
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('0.12')),
      equals('Sospensione'),
    );

    // 1.2.2 Esclusione lotto specifica
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('1.2.2')),
      equals(
        "SI' in caso di rilevamento di p.a. non ammessi da etichetta e/o da norme di coltura",
      ),
    );

    // 10.1 Esclusione lotto specifica
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('10.1')),
      equals(
        "SI' (esclusione lotto) in caso di assenza completa del piano di fertilizzazione",
      ),
    );

    // 12.2 Esclusione lotto specifica
    expect(
      ChecklistItemHelpers.getEsclSospText(createItem('12.2')),
      equals(
        "SI' (esclusione lotto) in caso di assenza completa delle registrazioni",
      ),
    );
  });

  test('Verify Chapter 8 Obblighi and Deroghe formatting', () {
    ChecklistItem createItem(
      String code, {
      String obbligo = '',
      String deroghe = '',
    }) {
      return ChecklistItem(
        code: code,
        versionId: 'v1',
        fase: '8. Gestione del suolo',
        obbligo: obbligo,
        indicatorType: '',
        deroghe: deroghe,
        noteNorma: '',
        tipologiaControllo: '',
        frequenzaSingolo: '',
        frequenzaAssociato: '',
        gravitaUecText: '',
        esclusioneUecText: '',
        gravitaOperatoreText: '',
        esclusioneOperatoreText: '',
        colGText: '',
        disposizioniRegionali: '',
        esclusioneLottoText: '',
        hasEsclusioneLotto: false,
        sortOrder: 1,
      );
    }

    // 8.1.1
    final item811 = createItem(
      '8.1.1',
      obbligo:
          'colture erbacee: sono consentite solo tecniche di minima lavorazione, la semina su sodo e la scarificatura/ripuntatura',
    );
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item811),
      equals(
        'Negli appezzamenti con pendenza media superiore al 30%: colture erbacee: sono consentite solo tecniche di minima lavorazione, la semina su sodo e la scarificatura/ripuntatura',
      ),
    );

    // 8.1.2
    final item812 = createItem(
      '8.1.2',
      obbligo:
          "colture arboree: è obbligatorio l'inerbimento nell'interfila anche come vegetazione spontanea gestita con sfalci.",
    );
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item812),
      startsWith('Negli appezzamenti con pendenza media superiore al 30%: '),
    );

    // 8.2.3: should have the main requirement, and deroga in getDeroghe
    final item823 = createItem(
      '8.2.3',
      obbligo:
          'Eccezione per la ripuntatura per la quale è ammessa una profondità massima di 50 cm',
    );
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item823),
      equals(
        'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: consentite lavorazioni ad una profondità max di 30 cm',
      ),
    );
    expect(
      ChecklistItemHelpers.getDeroghe(item823),
      equals(
        'Eccezione per la ripuntatura per la quale è ammessa una profondità massima di 50 cm',
      ),
    );

    // 8.2.4
    final item824 = createItem(
      '8.2.4',
      obbligo:
          'colture erbacee: obbligatoria la realizzazione di solchi acquai temporanei al max ogni 60 m',
    );
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item824),
      startsWith(
        'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ',
      ),
    );

    // 8.2.5
    final item825 = createItem('8.2.5');
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item825),
      startsWith(
        'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ',
      ),
    );

    // 8.2.6
    final item826 = createItem('8.2.6');
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item826),
      startsWith(
        'Negli appezzamenti con pendenza media compresa tra il 10% e il 30%: ',
      ),
    );
    expect(ChecklistItemHelpers.getDeroghe(item826), isNotNull);

    // 8.3
    final item83 = createItem('8.3');
    expect(
      ChecklistItemHelpers.getFormattedObbligo(item83),
      startsWith(
        'Colture arboree negli appezzamenti con pendenza media < 10%: ',
      ),
    );
    expect(ChecklistItemHelpers.getDeroghe(item83), isNotNull);

    // Test that artifact '1' in deroghe is ignored
    final item102 = createItem('10.2', deroghe: '1');
    expect(ChecklistItemHelpers.getDeroghe(item102), isNull);

    final item103 = createItem('10.3', deroghe: '1');
    expect(ChecklistItemHelpers.getDeroghe(item103), isNull);

    final item12 = createItem('1.2', deroghe: '1');
    expect(ChecklistItemHelpers.getDeroghe(item12), isNull);

    final item121 = createItem('1.2.1', deroghe: '1');
    expect(ChecklistItemHelpers.getDeroghe(item121), isNull);

    // Frequencies test for 8.1.1
    expect(ChecklistItemHelpers.getFrequenzaSingolo(item811), equals('100%'));
    expect(ChecklistItemHelpers.getFrequenzaAssociato(item811), equals('√n'));

    // Frequencies test for excluded points (0.12, 10.4, etc.)
    final item012 = createItem('0.12');
    expect(ChecklistItemHelpers.getFrequenzaSingolo(item012), isNull);
    expect(ChecklistItemHelpers.getFrequenzaAssociato(item012), isNull);

    // Frequencies test for special post-raccolta points (0.8, 14.2, 17.1)
    final item08 = createItem('0.8');
    expect(ChecklistItemHelpers.getFrequenzaSingolo(item08), isNull);
    expect(ChecklistItemHelpers.getFrequenzaAssociato(item08), equals('100%'));

    final item171 = createItem('17.1');
    expect(
      ChecklistItemHelpers.getFrequenzaSingolo(item171),
      contains('verifica lotti in stoccaggio'),
    );
    expect(
      ChecklistItemHelpers.getFrequenzaAssociato(item171),
      contains('100% operatori del campione'),
    );

    // Gravità tests
    final item106 = createItem('10.6');
    expect(ChecklistItemHelpers.getGravitaUec(item106), equals('3'));

    final item122 = createItem('12.2');
    expect(ChecklistItemHelpers.getGravitaUec(item122), isNull);

    final item131 = createItem('13.1');
    expect(ChecklistItemHelpers.getGravitaUec(item131), equals('2'));

    final itemNote131 = createItem('13.1');
    expect(
      ChecklistItemHelpers.getFormattedNote(itemNote131),
      contains('Scheda di raccolta con registrazione parametri'),
    );

    // Chapter 15 tests: 15.1 - 15.5 (Lotto, no severity, SI' (esclusione lotto))
    for (final code in ['15.1', '15.2', '15.3', '15.4', '15.5']) {
      final item = createItem(code);
      expect(
        ChecklistItemHelpers.getEsclSospText(item),
        equals("SI' (esclusione lotto)"),
        reason: 'Failed esclSospText for $code',
      );
      expect(
        ChecklistItemHelpers.getGravitaUec(item),
        isNull,
        reason: 'Failed gravitaUec for $code',
      );
      expect(
        ChecklistItemHelpers.getTarget(item),
        equals('Lotto'),
        reason: 'Failed target for $code',
      );
    }

    // Chapter 15 tests: 15.6 - 15.15 (Operatore, specific gravity)
    for (final code in [
      '15.6',
      '15.7',
      '15.8',
      '15.9',
      '15.10',
      '15.11',
      '15.12',
      '15.13',
      '15.14',
      '15.15',
    ]) {
      final item = createItem(code);
      expect(
        ChecklistItemHelpers.getTarget(item),
        equals('Operatore'),
        reason: 'Failed target for $code',
      );
    }

    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.6')),
      equals('NC lieve pari ad 1 per ogni requisito non rispettato'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.7')),
      equals('NC lieve pari ad 1 per ogni requisito non rispettato'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.8')),
      equals('1'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.9')),
      equals('1'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.10')),
      equals('1'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.11')),
      equals('1'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.12')),
      equals('2'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.13')),
      equals('1'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.14')),
      equals('2'),
    );
    expect(
      ChecklistItemHelpers.getGravitaOperatore(createItem('15.15')),
      equals('2'),
    );

    // All checklist targets tests
    // 1. Field crop UEC items
    for (final code in [
      '0.1',
      '0.2',
      '0.3',
      '0.4',
      '0.9',
      '0.10',
      '0.11',
      '1.1',
      '1.2.2',
      '8.1.1',
      '10.1',
      '10.6',
      '12.2',
      '13.1',
    ]) {
      expect(
        ChecklistItemHelpers.getTarget(createItem(code)),
        equals('UEC'),
        reason: 'Failed target UEC for $code',
      );
    }

    // 2. Operator items
    for (final code in [
      '0.5',
      '0.6',
      '0.8',
      '0.12',
      '0.13',
      '1.10',
      '1.11',
      '3.1',
      '3.2',
      '10.5.1',
      '10.5.2',
      '11.3',
      '14.0',
      '14.1',
      '14.2',
      '14.4',
      '15.6',
      '17.6',
      '17.9',
      '17.10',
    ]) {
      expect(
        ChecklistItemHelpers.getTarget(createItem(code)),
        equals('Operatore'),
        reason: 'Failed target Operatore for $code',
      );
    }

    // 3. Post-harvest Lotto items
    for (final code in [
      '15.1',
      '15.2',
      '15.3',
      '15.4',
      '15.5',
      '16.1',
      '16.3',
      '16.4',
      '17.1',
      '17.2',
      '17.3',
      '17.4',
      '17.7',
      '17.8',
    ]) {
      expect(
        ChecklistItemHelpers.getTarget(createItem(code)),
        equals('Lotto'),
        reason: 'Failed target Lotto for $code',
      );
    }

    // 4. Dual attribution item (16.2)
    expect(
      ChecklistItemHelpers.getTarget(createItem('16.2')),
      equals('Lotto / Operatore'),
    );

    // 5. Section headers (should have no target)
    for (final code in [
      '0.0',
      '1',
      '2',
      '3',
      '8',
      '14',
      '15',
      '15_D1',
      '15_D2',
      '16',
      '17',
    ]) {
      expect(
        ChecklistItemHelpers.getTarget(createItem(code)),
        isNull,
        reason: 'Header $code should have null target',
      );
    }
  });

  test('Test rendering square root in PDF', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          final color = PdfColors.grey700;
          final hexColor =
              '#${(color.toInt() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          return pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            children: [
              pw.Text(
                'Frequenza Operatore Singolo: 100% | Frequenza Operatore Associato: ',
              ),
              pw.SvgImage(
                svg:
                    '''<svg viewBox="0 0 10 14" width="5.5" height="7">
                  <path d="M1,7.5 L2.8,6.2 L4.8,12.5 L8.5,1.5 L10,1.5" fill="none" stroke="$hexColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>''',
              ),
              pw.Text('n', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, isTrue);
  });

  test(
    'Test getSingleScoreText and getScoreText for exclusion lotto and suspension',
    () {
      ChecklistItem createItem(String code) {
        return ChecklistItem(
          code: code,
          versionId: '1',
          fase: 'Test',
          obbligo: 'Test obbligo',
          indicatorType: 'mandatory',
          deroghe: '',
          noteNorma: '',
          tipologiaControllo: '',
          frequenzaSingolo: '',
          frequenzaAssociato: '',
          gravitaUecText: '',
          esclusioneUecText: '',
          gravitaOperatoreText: '',
          esclusioneOperatoreText: '',
          esclusioneLottoText: '',
          hasEsclusioneLotto: false,
          colGText: '',
          disposizioniRegionali: '',
          sortOrder: 1,
        );
      }

      // UEC Exclusion Lotto (val = 0 or val = 3)
      final item10_1 = createItem('10.1');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item10_1, 0, false),
        equals('3 (Esclusione lotto)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item10_1, 3, false),
        equals('3 (Esclusione lotto)'),
      );

      final item12_2 = createItem('12.2');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item12_2, 0, false),
        equals('3 (Esclusione lotto)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item12_2, 3, false),
        equals('3 (Esclusione lotto)'),
      );

      final item15_1 = createItem('15.1');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item15_1, 0, false),
        equals('3 (Esclusione lotto)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item15_1, 3, false),
        equals('3 (Esclusione lotto)'),
      );

      // Regular UEC score without exclusion (e.g. 10.6)
      final item10_6 = createItem('10.6');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item10_6, 3, false),
        equals('3'),
      );

      // Operatore Sospensione (val = 0 or val = 3)
      final item0_8 = createItem('0.8');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item0_8, 0, true),
        equals('3 (Sospensione operatore)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item0_8, 3, true),
        equals('3 (Sospensione operatore)'),
      );

      final item0_12 = createItem('0.12');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item0_12, 0, true),
        equals('3 (Sospensione)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item0_12, 3, true),
        equals('3 (Sospensione)'),
      );

      final item17_10 = createItem('17.10');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item17_10, 0, true),
        equals('3 (Sospensione)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item17_10, 3, true),
        equals('3 (Sospensione)'),
      );

      // OA Exclusion
      final item14_0 = createItem('14.0');
      expect(
        ChecklistItemHelpers.getSingleScoreText(item14_0, 0, false),
        equals('3 (Esclusione OA)'),
      );
      expect(
        ChecklistItemHelpers.getSingleScoreText(item14_0, 0, true),
        equals('3 (Esclusione OA)'),
      );

      // getScoreText wrapper
      expect(
        ChecklistItemHelpers.getScoreText(item10_1, 0, null),
        equals('3 (Esclusione lotto)'),
      );
      expect(
        ChecklistItemHelpers.getScoreText(item0_12, null, 0),
        equals('3 (Sospensione)'),
      );

      // 17.7 Typo fix test
      final item17_7 = createItem('17.7');
      expect(
        ChecklistItemHelpers.getGravitaUec(item17_7),
        equals(
          'Nessuna NC qualora si agisca con AC e rafforzamento del campione',
        ),
      );

      // Chapter 13 requirements test
      final item13 = createItem('13');
      expect(
        ChecklistItemHelpers.getFormattedObbligo(item13),
        equals(
          'Raccolta ; Secondo quanto definito dalla Regione nel disciplinare (laddove siano previste prescrizioni obbligatorie)',
        ),
      );

      final item13_1 = createItem('13.1');
      expect(
        ChecklistItemHelpers.getFormattedObbligo(item13_1),
        equals(
          'Se disciplinati dalla Regione o P.A. verificare il rispetto dei parametri per inizio raccolta',
        ),
      );
      expect(
        ChecklistItemHelpers.getFormattedNote(item13_1),
        contains(
          'Scheda di raccolta con registrazione parametri previsti dal DPI',
        ),
      );
      expect(ChecklistItemHelpers.getGravitaUec(item13_1), equals('2'));
      expect(ChecklistItemHelpers.getDeroghe(item13_1), isNull);

      final item13_2 = createItem('13.2');
      expect(
        ChecklistItemHelpers.getFormattedObbligo(item13_2),
        equals(
          'Se disciplinati dalla Regione o P.A. verificare il rispetto delle modalità di raccolta e conferimento ai centri di stoccaggio / lavorazione',
        ),
      );
      expect(
        ChecklistItemHelpers.getFormattedNote(item13_2),
        contains(
          'Descrizione delle modalità di raccolta e conferimento in manuale di autocontrollo',
        ),
      );
      expect(ChecklistItemHelpers.getGravitaUec(item13_2), equals('2'));
      expect(ChecklistItemHelpers.getDeroghe(item13_2), isNull);
    },
  );
}
