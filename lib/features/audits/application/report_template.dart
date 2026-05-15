import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';
import 'checklist_item_helpers.dart';

/// Configuration for report visual style
class ReportStyle {
  final PdfColor primaryColor;
  final PdfColor secondaryColor;
  final PdfColor accentColor;
  final double margin;

  const ReportStyle({
    // Deep Charcoal (#2D3E4E)
    this.primaryColor = const PdfColor.fromInt(0xFF2D3E4E),
    // Blue Grey (#455A64)
    this.secondaryColor = const PdfColor.fromInt(0xFF455A64),
    // Vibrant Light Green (#C5E1A5)
    this.accentColor = const PdfColor.fromInt(0xFFC5E1A5),
    this.margin = 24.0,
  });

  static const defaultStyle = ReportStyle();
}

extension PdfStringSanitization on String {
  String get sanitizeForPdf {
    if (isEmpty) return this;

    return replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('´', "'")
        .replaceAll('`', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...')
        .replaceAll('•', '-')
        .replaceAll('·', '-')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        .replaceAll('°', ' gradi')
        .replaceAll('€', ' Euro')
        .replaceAll('±', '+/-')
        .replaceAll('×', 'x')
        .replaceAll('➢', '-')
        .replaceAll('➤', '-')
        .replaceAll('➔', '-')
        .replaceAll('✓', '[OK]')
        .replaceAll('✔', '[OK]')
        .replaceAll('☐', '[ ]')
        .replaceAll('☑', '[X]')
        .replaceAll('☒', '[X]')
        .replaceAll('\u00A0', ' ') // Non-breaking space
        .replaceAll('\u200B', '') // Zero width space
        .replaceAll('\u2028', '\n')
        .replaceAll('\u2029', '\n')
        .replaceAll(RegExp(r'[^\x00-\x7FàèéìòùÀÈÉÌÒÙ]'), ' ');
  }
}

/// Abstract template for PDF generation
abstract class ReportTemplate {
  final ReportStyle style;
  const ReportTemplate({this.style = ReportStyle.defaultStyle});

  pw.PageTheme buildPageTheme();
  pw.Widget buildPageHeader(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi, {
    String? docTitle,
    bool isChecklist = false,
  });
  pw.Widget buildPageFooter(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
  );

  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi, {
    String? title,
    String? moduleName,
  });

  pw.Widget buildCompanyInfoPage(
    Visit visit,
    VisitCompany? company, {
    DateTime? lastVisitDate,
  });

  pw.Widget buildPreviousAuditPage(
    Visit visit,
    VisitCompany? company,
    List<VisitAttachment> attachments,
    VisitPreviousNcManagement? prevNc,
  );

  pw.Widget buildCultivationPhasePage(Visit visit, List<VisitUec> uecs);

  pw.Widget buildMassBalancePage(Visit visit, List<MassBalanceRecord> balances);

  pw.Widget buildPostHarvestPage(PostHarvestRecord? postHarvest);

  pw.Widget buildSummaryActivitiesPage(
    List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})> ncs,
    VisitClosing? closing,
  );

  pw.Widget buildFinalEvaluationPage(
    VisitClosing? closing,
    List<({VisitSignature signature, Uint8List? bytes})> signatures,
    DateTime? date,
  );

  List<pw.Widget> buildPhotoGalleryPage(
    Visit visit,
    List<({VisitAttachment attachment, Uint8List? bytes})> attachmentData,
  );

  List<pw.Widget> buildChecklistPage(
    Visit visit,
    List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>
    allResponses,
    List<ChecklistItem> allItems,
    List<String> phases,
  );
}

/// Standard implementation of the SQNPI template
class StandardSqnpiTemplate extends ReportTemplate {
  const StandardSqnpiTemplate({super.style});

  pw.TextStyle get labelStyle => pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey700,
  );

  pw.TextStyle get valueStyle =>
      pw.TextStyle(fontSize: 9.5, color: style.primaryColor);

  @override
  pw.PageTheme buildPageTheme() {
    return pw.PageTheme(
      margin: pw.EdgeInsets.all(style.margin),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );
  }

  @override
  @override
  pw.Widget buildPageHeader(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi, {
    String? docTitle,
    bool isChecklist = false,
  }) {
    if (!isChecklist) {
      const lightGreen = PdfColor.fromInt(0xFF9CCC65); // Verde chiaro/lime
      const darkBlue = PdfColor.fromInt(0xFF1A237E); // Blu scuro/navy

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Sinistra: Loghi
                pw.Row(
                  children: [
                    if (logoBios != null)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(right: 15),
                        child: pw.Image(logoBios, height: 45),
                      ),
                    if (logoSqnpi != null) pw.Image(logoSqnpi, height: 45),
                  ],
                ),
                // Destra: Titoli
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      (docTitle ?? "REPORT DI VERIFICA ISPETTIVA SQNPI")
                          .toUpperCase(),
                      style: pw.TextStyle(
                        color: lightGreen,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      (company?.ragioneSociale ?? "-").sanitizeForPdf,
                      style: pw.TextStyle(
                        color: darkBlue,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 0.5, color: PdfColors.grey400),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Riga Superiore
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo e nome Bios
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBios != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(logoBios, height: 35),
                    ),
                  pw.Text(
                    "Bios Srl",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Logo SQNPI e Titolo
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoSqnpi != null)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(right: 8),
                      child: pw.Image(logoSqnpi, height: 30),
                    ),
                  pw.Text(
                    "Check-list di controllo SQNPI_ 2026",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Dettagli Revisione
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "CL.SQNPI Rev.Min. 12 approvata il 24.11.2025",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Riga Inferiore (Azienda, Auditor, Data)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(
                0xFFE5ECF6,
              ), // Grigio/Azzurro chiaro
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Azienda: ",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                        pw.TextSpan(
                          text: company?.ragioneSociale ?? visit.companyName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Auditor: ",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                        pw.TextSpan(
                          text: visit.inspectorName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: "Data Audit: ",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                        pw.TextSpan(
                          text: _formatVisitDate(visit),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget buildPageFooter(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento generato digitalmente - BIOS/SQNPI',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  String _formatVisitDate(Visit visit) {
    final start = visit.scheduledAt;
    final end = visit.scheduledUntil;

    final startStr = DateFormat('dd/MM/yyyy').format(start);
    if (end == null ||
        (end.year == start.year &&
            end.month == start.month &&
            end.day == start.day)) {
      return startStr;
    }
    final endStr = DateFormat('dd/MM/yyyy').format(end);
    return '$startStr - $endStr';
  }

  @override
  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi, {
    String? title,
    String? moduleName,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoBios != null)
                pw.Image(logoBios, height: 50)
              else
                pw.Text(
                  'BIOS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 28,
                    color: style.primaryColor,
                  ),
                ),
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 60),
            ],
          ),
          pw.SizedBox(height: 60),
          pw.Container(height: 3, width: 80, color: style.accentColor),
          pw.SizedBox(height: 20),
          pw.Text(
            title ?? 'RAPPORTO FINALE DI\nVERIFICA ISPETTIVA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 40,
              color: style.primaryColor,
              letterSpacing: 1.2,
              lineSpacing: 1.1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'SISTEMA DI QUALITÀ NAZIONALE PRODUZIONE INTEGRATA',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 50),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'OPERATORE CERTIFICATO',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                (company?.ragioneSociale ?? visit.companyName).sanitizeForPdf,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: style.primaryColor,
                ),
              ),
              if (company?.cuaa != null) ...[
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text(
                      'CUAA: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      company!.cuaa,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: style.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 40),
          if (company != null &&
              (company.submissionNumber.isNotEmpty ||
                  company.sqnpiProtocol.isNotEmpty ||
                  company.sqnpiSubmissionDate != null))
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (company.submissionNumber.isNotEmpty)
                    _buildCoverInfoItem('N. Domanda', company.submissionNumber),
                  if (company.sqnpiProtocol.isNotEmpty)
                    _buildCoverInfoItem('Protocollo', company.sqnpiProtocol),
                  if (company.sqnpiSubmissionDate != null)
                    _buildCoverInfoItem(
                      'Data Domanda SQNPI',
                      _formatDate(company.sqnpiSubmissionDate),
                    ),
                ],
              ),
            ),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildCoverInfoItem('Data Ispezione', _formatVisitDate(visit)),
                _buildCoverInfoItem('Modulo', moduleName ?? 'M904'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  pw.Widget _buildCoverInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
      ],
    );
  }

  @override
  pw.Widget buildCompanyInfoPage(
    Visit visit,
    VisitCompany? company, {
    DateTime? lastVisitDate,
  }) {
    if (company == null) return pw.SizedBox();
    final indirizzoLegale = [
      company.indirizzo,
      company.cap,
      company.comune,
      company.provincia,
    ].where((e) => e.isNotEmpty).join(', ');
    final indirizzoOperativo = [
      company.sedeOperativaIndirizzo,
      company.sedeOperativaCap,
      company.sedeOperativaComune,
      company.sedeOperativaProvincia,
    ].where((e) => e.isNotEmpty).join(', ');
    final indirizzoManipolazione = [
      company.manipulationSiteAddress,
      company.manipulationSiteCap,
      company.manipulationSiteComune,
      company.manipulationSiteProvincia,
    ].where((e) => e.isNotEmpty).join(', ');

    final rep = visit.representativeName.isNotEmpty
        ? visit.representativeName
        : company.referente;

    final dateStr = _formatVisitDate(visit);

    final sqnpiDateStr = company.sqnpiSubmissionDate != null
        ? "${company.sqnpiSubmissionDate!.day.toString().padLeft(2, '0')}/${company.sqnpiSubmissionDate!.month.toString().padLeft(2, '0')}/${company.sqnpiSubmissionDate!.year}"
        : "-";
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader("ANAGRAFICA DELL'ORGANIZZAZIONE"),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              buildValueBlock(
                "Ragione Sociale:",
                company.ragioneSociale,
                isLast: false,
              ),
              buildGridRow([
                buildValueBlock(
                  "P. IVA / CUAA:",
                  "${company.partitaIva} / ${company.cuaa}",
                  isFullWidth: false,
                  isLast: true,
                ),
                buildValueBlock(
                  "Rappresentante:",
                  rep,
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                buildValueBlock(
                  "E-mail:",
                  company.email,
                  isFullWidth: false,
                  isLast: true,
                ),
                buildValueBlock(
                  "Telefono / PEC:",
                  "${company.telefono} / ${company.pec}",
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                buildValueBlock(
                  "Sede Legale:",
                  indirizzoLegale,
                  isFullWidth: false,
                  isLast: true,
                ),
                buildValueBlock(
                  "Sito Operativo:",
                  indirizzoOperativo,
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                buildValueBlock(
                  "Sito Manipolazione:",
                  indirizzoManipolazione.isNotEmpty
                      ? indirizzoManipolazione
                      : "NON PRESENTE",
                  isFullWidth: false,
                  isLast: true,
                ),
                buildValueBlock(
                  "Geocoordinate:",
                  "${company.latitudeText} | ${company.longitudeText}",
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildValueBlock(
                "Domanda SQNPI:",
                "N.${company.submissionNumber} - Prot.${company.sqnpiProtocol} del $sqnpiDateStr",
                isLast: false,
              ),
              buildValueBlock(
                "Periodo di picco dell'attività:",
                "${company.peakPeriodFrom} - ${company.peakPeriodTo}",
                isLast: true,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        buildSectionHeader("DETTAGLI DELLA VERIFICA ISPETTIVA"),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              buildGridRow([
                buildValueBlock(
                  "Data della verifica ispettiva (1 giornata = 8 ore):",
                  dateStr,
                  isFullWidth: false,
                  isLast: true,
                  textAlign: pw.TextAlign.center,
                ),
                buildValueBlock(
                  "Durata Totale in ore:",
                  "${visit.durationHours} ORE",
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                buildValueBlock(
                  "Ultima Verifica:",
                  lastVisitDate != null
                      ? '${lastVisitDate.day.toString().padLeft(2, '0')}/${lastVisitDate.month.toString().padLeft(2, '0')}/${lastVisitDate.year}'
                      : "-",
                  isFullWidth: true,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                _buildToggleBlock("Visita Congiunta:", company.isJointVisit),
                _buildToggleBlock(
                  "Operatore certificato da altro ODC anni precedenti:",
                  company.previousOdcName.isNotEmpty,
                ),
              ]),
              if ((company.isJointVisit &&
                      company.jointVisitDetails.isNotEmpty) ||
                  company.previousOdcName.isNotEmpty)
                buildGridRow([
                  if (company.isJointVisit &&
                      company.jointVisitDetails.isNotEmpty)
                    buildValueBlock(
                      "Dettaglio schema:",
                      company.jointVisitDetails,
                      isFullWidth: false,
                      isLast: true,
                    )
                  else
                    pw.SizedBox(),
                  if (company.previousOdcName.isNotEmpty)
                    buildValueBlock(
                      "Nome precedente OdC:",
                      company.previousOdcName,
                      isFullWidth: false,
                      isLast: true,
                    )
                  else
                    pw.SizedBox(),
                ]),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 110,
                      child: pw.Text(
                        "Scopo della Verifica:",
                        style: labelStyle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Wrap(
                        spacing: 15,
                        runSpacing: 4,
                        children: [
                          buildCheck(
                            visit.visitType.contains('MARCHIO'),
                            "Marchio",
                          ),
                          buildCheck(visit.visitType.contains('ACA'), "ACA"),
                          buildCheck(
                            visit.visitType.contains('CAMPIONAMENTO'),
                            "Campionamento",
                          ),
                          if (visit.visitType.contains('ALTRO'))
                            buildCheck(true, "Altro"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (visit.visitType.contains('MARCHIO'))
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey100,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "DATI APPLICAZIONE MARCHIO",
                        style: labelStyle.copyWith(
                          color: style.accentColor,
                          fontSize: 8,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _buildColumnValue(
                              "Natura Prodotto",
                              company.marchioNature,
                            ),
                          ),
                          pw.Expanded(
                            child: _buildColumnValue(
                              "Processi Produttivi",
                              company.marchioProcesses,
                            ),
                          ),
                          pw.Expanded(
                            child: _buildColumnValue(
                              "Bozza Etichetta",
                              company.marchioLabelDraft
                                  ? "ACQUISITA"
                                  : "NON ACQUISITA",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              buildValueBlock(
                "Ispettore RGVI:",
                visit.inspectorName,
                isLast: false,
              ),
              if (visit.companionName.isNotEmpty)
                buildValueBlock("GVI2:", visit.companionName, isLast: false),
              if (visit.otherOperators.isNotEmpty)
                buildValueBlock(
                  "Altri Operatori Presenti:",
                  visit.otherOperators,
                  isLast: false,
                ),
              buildValueBlock(
                "Elenco persone contattate:",
                visit.contactedPersons,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: style.accentColor, // Updated Vibrant Green
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9.5,
          color: style.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  pw.Widget buildValueBlock(
    String label,
    String value, {
    bool isFullWidth = true,
    bool isLast = false,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: !isLast
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
              ),
            )
          : null,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: isFullWidth ? 150 : 100,
            child: pw.Text(
              label,
              style: labelStyle.copyWith(color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.sanitizeForPdf,
              textAlign: textAlign,
              style: valueStyle.copyWith(
                color: style.primaryColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget buildGridRow(List<pw.Widget> children, {bool isLast = false}) {
    return pw.Container(
      decoration: !isLast
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
              ),
            )
          : null,
      child: pw.Row(
        children: children.map((child) => pw.Expanded(child: child)).toList(),
      ),
    );
  }

  pw.Widget buildCheck(bool isChecked, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: isChecked ? PdfColors.black : PdfColors.grey300,
              width: 0.8,
            ),
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Text(
                    "x",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                )
              : null,
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          label,
          style: valueStyle.copyWith(
            color: isChecked ? style.primaryColor : PdfColors.grey600,
            fontWeight: isChecked ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildToggleBlock(String label, bool value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 110, child: pw.Text(label, style: labelStyle)),
          buildCheck(value, "Sì"),
          pw.SizedBox(width: 12),
          buildCheck(!value, "No"),
        ],
      ),
    );
  }

  pw.Widget _buildColumnValue(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: labelStyle.copyWith(fontSize: 7, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 2),
        pw.Text(value, style: valueStyle.copyWith(fontSize: 9)),
      ],
    );
  }

  @override
  pw.Widget buildPreviousAuditPage(
    Visit visit,
    VisitCompany? company,
    List<VisitAttachment> attachments,
    VisitPreviousNcManagement? prevNc,
  ) {
    final refDocs = attachments
        .where((a) => a.category == 'reference')
        .toList();
    final viewedDocs = attachments
        .where((a) => a.category == 'viewed')
        .toList();

    bool hasRef(String type) => refDocs.any((a) => a.attachmentType == type);
    String getRefExtra(String type) =>
        refDocs.firstWhereOrNull((a) => a.attachmentType == type)?.extraValue ??
        '';

    bool hasViewed(String type) =>
        viewedDocs.any((a) => a.attachmentType == type);
    String getViewedExtra(String type) =>
        viewedDocs
            .firstWhereOrNull((a) => a.attachmentType == type)
            ?.extraValue ??
        '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader("DOCUMENTI DI RIFERIMENTO E VISIONATI"),

        // Documenti di riferimento
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text(
                  "Documenti di riferimento utilizzati:",
                  style: labelStyle,
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDocCheck(
                      hasRef('DISCIPLINARE'),
                      "Disciplinare/i Regionale di Difesa Integrata adottati dall'azienda (rev.09)",
                    ),
                    if (hasRef('DISCIPLINARE'))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
                        child: pw.Text(
                          "Regione e anno: ${getRefExtra('DISCIPLINARE')}",
                          style: valueStyle.copyWith(fontSize: 8),
                        ),
                      ),
                    _buildDocCheck(
                      hasRef('LINEE_GUIDA'),
                      "Linee Guida Nazionali di Difesa Integrata",
                    ),
                    if (hasRef('LINEE_GUIDA'))
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
                        child: pw.Text(
                          "Anno: ${getRefExtra('LINEE_GUIDA')}",
                          style: valueStyle.copyWith(fontSize: 8),
                        ),
                      ),
                    _buildDocCheck(
                      true,
                      "Checklist di Controllo (Digitale in-App) Allegato ad uso interno Bios (rev.09)",
                    ),
                    _buildDocCheck(
                      hasRef('RIFERIMENTO_ALTRO'),
                      "Altro (specificare): ${hasRef('RIFERIMENTO_ALTRO') ? getRefExtra('RIFERIMENTO_ALTRO') : ''}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Documenti visionati
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 150,
                child: pw.Text("Documenti visionati:", style: labelStyle),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDocCheck(
                      hasViewed('REGISTRO_SQNPI'),
                      "REGISTRO AZIENDALE SQNPI (Quaderni di campagna, Registro operazioni colturali e magazzino)",
                    ),
                    _buildDocCheck(
                      hasViewed('AUTOCONTROLLO'),
                      "Evidenza autocontrollo interno",
                    ),
                    _buildDocCheck(
                      hasViewed('AUDIT_BIOS_PREC'),
                      "Rapporto dell'audit Bios precedente (se applicabile)",
                    ),
                    _buildDocCheck(
                      hasViewed('ESITO_CERT_ALTRO_ODC'),
                      "Esito di certificazione e NC emesse da altro Odc (se applicabile)",
                    ),
                    _buildDocCheck(
                      hasViewed('VISIONATI_ALTRO'),
                      "Altro (obbligatorio specificare): ${hasViewed('VISIONATI_ALTRO') ? getViewedExtra('VISIONATI_ALTRO') : ''}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        buildSectionHeader("GESTIONE NON CONFORMITÀ E AZIONI CORRETTIVE"),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Text(
            "NOTA: Per gli operatori, certificati da altri Odc nei due anni precedenti l'entrata in Bios, è obbligatorio verificare eventuali NC e i provvedimenti emessi (esclusione, sospensione) al fine del calcolo delle recidive.",
            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey200,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Le N/C rilevate nel corso della precedente visita ispettiva risultano:",
                            style: labelStyle.copyWith(fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          buildCheck(prevNc?.prevNcResults == 1, "Risolte"),
                          buildCheck(prevNc?.prevNcResults == 2, "Non risolte"),
                          buildCheck(
                            prevNc?.prevNcResults == 0,
                            "Non applicabile (nel caso non vi siano NC aperte)",
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            "Specificare quali requisiti risultano ancora N/C:",
                            style: labelStyle.copyWith(fontSize: 7),
                          ),
                          pw.Text(
                            prevNc?.prevNcRequirementsStillKO ?? "-",
                            style: valueStyle.copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Le azioni correttive risultano coerenti in relazione alle N/C trattate:",
                            style: labelStyle.copyWith(fontSize: 8),
                          ),
                          pw.SizedBox(height: 4),
                          buildCheck(
                            prevNc?.prevCorrectiveActionsCoherent == 1,
                            "Sì",
                          ),
                          buildCheck(
                            prevNc?.prevCorrectiveActionsCoherent == 2,
                            "No",
                          ),
                          buildCheck(
                            prevNc?.prevCorrectiveActionsCoherent == 0,
                            "N/A (nel caso non vi siano NC aperte)",
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            "Se \"No\" specificare:",
                            style: labelStyle.copyWith(fontSize: 7),
                          ),
                          pw.Text(
                            prevNc?.prevCorrectiveActionsDetails ?? "-",
                            style: valueStyle.copyWith(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  "Dettagli relativi alla precedente attività di sorveglianza e del relativo status di conformità (se applicabile)",
                  style: labelStyle.copyWith(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildDocCheck(
                        prevNc?.prevOrgCertifiedDate.isNotEmpty ?? false,
                        "L'Organizzazione è certificata il: ${prevNc?.prevOrgCertifiedDate ?? ''}",
                      ),
                    ),
                    pw.Expanded(
                      child: _buildDocCheck(
                        prevNc?.prevOrgSanctionedDate.isNotEmpty ?? false,
                        "L'Organizzazione è stata sanzionata il: ${prevNc?.prevOrgSanctionedDate ?? ''}",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDocCheck(bool isChecked, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 11,
            height: 11,
            margin: const pw.EdgeInsets.only(top: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: isChecked ? PdfColors.black : PdfColors.grey400,
                width: 0.8,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1.5)),
            ),
            child: isChecked
                ? pw.Center(
                    child: pw.Text(
                      "x",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              label,
              style: valueStyle.copyWith(
                fontSize: 8.5,
                color: isChecked ? style.primaryColor : PdfColors.grey700,
                fontWeight: isChecked
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget buildCultivationPhasePage(Visit visit, List<VisitUec> uecs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader(
          "FASE DI COLTIVAZIONE: Quadro di verifica per coltura e UEC",
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(45), // Aggregato
            1: pw.FixedColumnWidth(60), // Prodotto in domanda
            2: pw.FixedColumnWidth(60), // Prodotto riscontrato
            3: pw.FixedColumnWidth(45), // Coerenza
            4: pw.FixedColumnWidth(45), // Conformità
            5: pw.FixedColumnWidth(55), // Campionamento
            6: pw.FixedColumnWidth(45), // Tracciabile
            7: pw.FixedColumnWidth(45), // Reclami
            8: pw.FixedColumnWidth(65), // Processo campo
            9: pw.FlexColumnWidth(1), // Note
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeader("Aggregato (n.) (rev.09)"),
                _buildTableHeader("Prodotto in domanda"),
                _buildTableHeader("Prodotto riscontrato in ispezione"),
                _buildTableHeader("Coerenza con domanda SQNPI"),
                _buildTableHeader("Conformità con standard SQNPI"),
                _buildTableHeader("Campionamento"),
                _buildTableHeader(
                  "Il prodotto verificato è identificato e tracciabile",
                ),
                _buildTableHeader(
                  "Sono stati presentati reclami sul prodotto verificato",
                ),
                _buildTableHeader("Processo produttivo verificato in campo"),
                _buildTableHeader("Note"),
              ],
            ),
            // Data Rows
            ...uecs
                .where((u) => u.coltura != 'OPERATORE')
                .map(
                  (uec) => pw.TableRow(
                    children: [
                      _buildTableCell(uec.nAggregato),
                      _buildTableCell(uec.coltura),
                      _buildTableCell(uec.foundProduct ?? '-'),
                      _buildTableChecks(uec.sqnpiConsistency),
                      _buildTableChecks(uec.sqnpiCompliance),
                      _buildTableSampling(uec.hasSampling, uec.samplingLotId),
                      _buildTableYesNo(uec.isTraceable),
                      _buildTableYesNo(uec.hasClaims),
                      _buildTableCell(uec.fieldProcessDetails ?? '-'),
                      _buildTableCell(uec.note),
                    ],
                  ),
                ),
            if (uecs.isEmpty)
              pw.TableRow(
                children: [
                  pw.Container(
                    height: 40,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      "Nessuna unità di controllo (UEC) inserita",
                      style: valueStyle.copyWith(
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  ...List.filled(10, pw.Container()),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: labelStyle.copyWith(fontSize: 6.5, color: PdfColors.black),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text.sanitizeForPdf,
        style: valueStyle.copyWith(fontSize: 7.5),
      ),
    );
  }

  pw.Widget _buildScoreCell(String text, {bool isKo = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text.sanitizeForPdf,
        style: valueStyle.copyWith(
          fontSize: 7.5,
          color: isKo ? PdfColors.red700 : null,
          fontWeight: isKo ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  pw.Widget _buildTableChecks(String value) {
    final v = value.toUpperCase();
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildMiniCheck(v == "SI" || v == "SÌ" || v == "OK", "OK"),
          _buildMiniCheck(v == "N/A" || v == "NA", "NA"),
          _buildMiniCheck(v == "NO" || v == "KO", "KO"),
        ],
      ),
    );
  }

  pw.Widget _buildTableSampling(bool hasSampling, String? lot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildMiniCheck(hasSampling, "Si"),
          _buildMiniCheck(!hasSampling, "No"),
          if (hasSampling && lot != null && lot.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                "Lotto: $lot",
                style: valueStyle.copyWith(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildTableYesNo(bool isYes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [_buildMiniCheck(isYes, "Si"), _buildMiniCheck(!isYes, "No")],
      ),
    );
  }

  pw.Widget _buildMiniCheck(bool isChecked, String label) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.6),
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Text(
                    "x",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 6,
                    ),
                  ),
                )
              : null,
        ),
        pw.SizedBox(width: 3),
        pw.Text(
          label,
          style: labelStyle.copyWith(
            fontSize: 6,
            fontWeight: isChecked ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  PdfColor scaleOpacity(PdfColor color, double opacity) {
    return PdfColor(color.red, color.green, color.blue, opacity);
  }

  @override
  pw.Widget buildMassBalancePage(
    Visit visit,
    List<MassBalanceRecord> balances,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader(
          "DIFESA E CONTROLLO DELLE INFESTANTI: punto 1.4 LGNPC",
        ),
        pw.Text(
          "Bilancio di massa tenuto conto anche delle scorte di magazzino da eseguire su almeno due sostanze attive di particolare rilevanza ai fini del controllo. Verifica dei documenti fiscali.",
          style: pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey800,
            fontStyle: pw.FontStyle.italic,
            lineSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 20),
        if (balances.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              "Nessun bilancio di massa registrato in questa verifica.",
              style: valueStyle.copyWith(color: PdfColors.grey600),
            ),
          )
        else
          ...balances.asMap().entries.map(
            (entry) => _buildMassBalanceBox(entry.value, entry.key + 1),
          ),
      ],
    );
  }

  pw.Widget _buildMassBalanceBox(MassBalanceRecord mb, int index) {
    return _buildStandardMassBalanceBox(
      index: index,
      title:
          "BILANCIO DI MASSA (spazio per l'evidenza di un bilancio di massa)",
      verifiedProducts: mb.verifiedProducts ?? "",
      ingressData: mb.ingressData ?? "",
      ingressDocs: mb.ingressDocs ?? "",
      outputData: mb.egressData ?? "",
      outputDocs: mb.egressDocs ?? "",
      comment: mb.comment ?? "",
    );
  }

  @override
  pw.Widget buildPostHarvestPage(PostHarvestRecord? postHarvest) {
    if (postHarvest == null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text('Nessun dato di post-raccolta inserito.'),
      );
    }

    // Parsing JSON fields from the record
    final phasesJson = postHarvest.phases;
    final List<_PostHarvestPhaseData> phasesList = [];
    try {
      final List decoded = jsonDecode(phasesJson);
      for (var item in decoded) {
        phasesList.add(_PostHarvestPhaseData.fromJson(item));
      }
    } catch (_) {}

    final mbBalancesJson = postHarvest.mbBalances;
    final List<_PostHarvestMassBalanceData> mbBalancesList = [];
    try {
      final List decoded = jsonDecode(mbBalancesJson);
      for (var item in decoded) {
        mbBalancesList.add(_PostHarvestMassBalanceData.fromJson(item));
      }
    } catch (_) {}

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader(
          'FASE DI POST RACCOLTA / CONDIZIONAMENTO / TRASFORMAZIONE',
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'FASE DI POST RACCOLTA (Quadro di verifica)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        _buildPostHarvestPhasesTable(phasesList),
        pw.SizedBox(height: 20),
        pw.Text(
          'BILANCIO DI MASSA (specifico per la fase di post-raccolta)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        _buildPostHarvestMassBalanceSection(postHarvest, mbBalancesList),
        pw.SizedBox(height: 20),
        pw.Text(
          'PROVA DI RINTRACCIABILITA\' (evidenze riscontrate)(Rif. Check-list punto 16.1)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.Text(
          "Verifica registrazioni sul SI del SQNPI al fine di garantire la rintracciabilità dei lotti (rev.08)",
          style: pw.TextStyle(
            fontSize: 8.5,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildPostHarvestTraceabilitySection(postHarvest),
      ],
    );
  }

  pw.Widget _buildPostHarvestPhasesTable(List<_PostHarvestPhaseData> phases) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(100), // Fase
        1: pw.FixedColumnWidth(50), // In proprio
        2: pw.FixedColumnWidth(50), // Terzista
        3: pw.FixedColumnWidth(70), // Prodotto
        4: pw.FixedColumnWidth(60), // Conformità
        5: pw.FixedColumnWidth(60), // Tracciabile
        6: pw.FlexColumnWidth(1), // Note/Certificato
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeader("Fase"),
            _buildTableHeader("In proprio"),
            _buildTableHeader("Terzista"),
            _buildTableHeader("Prodotto"),
            _buildTableHeader("Conformità SQNPI"),
            _buildTableHeader("Tracciabile"),
            _buildTableHeader("Note"),
          ],
        ),
        if (phases.isEmpty)
          pw.TableRow(
            children: [
              pw.Container(
                height: 30,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Nessun dato registrato",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
              ...List.filled(6, pw.Container()),
            ],
          ),
        ...phases.map(
          (p) => pw.TableRow(
            children: [
              _buildTableCell(p.fase),
              _buildTableYesNo(p.inProprio),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildMiniCheck(p.terzista, "Si"),
                    _buildMiniCheck(!p.terzista, "No"),
                    if (p.terzista && p.certificatoTerzista.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          "Cert. SQNPI: ${p.certificatoTerzista}",
                          style: valueStyle.copyWith(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _buildTableCell(p.prodotto),
              _buildTableChecks(
                p.conformitaSqnpi == true
                    ? "SI"
                    : p.conformitaSqnpi == false
                    ? "NO"
                    : "N/A",
              ),
              _buildTableChecks(
                p.tracciabile == true
                    ? "SI"
                    : p.tracciabile == false
                    ? "NO"
                    : "N/A",
              ),
              _buildTableCell(p.note),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPostHarvestMassBalanceSection(
    PostHarvestRecord record,
    List<_PostHarvestMassBalanceData> balances,
  ) {
    final bool hasMainBalance =
        record.mbVerifiedProducts.isNotEmpty ||
        record.mbInputData.isNotEmpty ||
        record.mbInputDocs.isNotEmpty ||
        record.mbOutputData.isNotEmpty ||
        record.mbOutputDocs.isNotEmpty ||
        record.mbComment.isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (hasMainBalance)
          _buildStandardMassBalanceBox(
            index: 1,
            title: "BILANCIO DI MASSA POST-RACCOLTA",
            verifiedProducts: record.mbVerifiedProducts,
            ingressData: record.mbInputData,
            ingressDocs: record.mbInputDocs,
            outputData: record.mbOutputData,
            outputDocs: record.mbOutputDocs,
            comment: record.mbComment,
          ),
        if (balances.isNotEmpty) ...[
          if (hasMainBalance) pw.SizedBox(height: 15),
          pw.Text(
            "Dettaglio Bilanci Di Massa Post-Raccolta:",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          ...balances.asMap().entries.map((entry) {
            final idx = hasMainBalance ? entry.key + 2 : entry.key + 1;
            final mb = entry.value;
            return _buildStandardMassBalanceBox(
              index: idx,
              title: "BILANCIO DI MASSA POST-RACCOLTA",
              verifiedProducts: mb.verifiedProducts,
              ingressData: mb.inputData,
              ingressDocs: mb.inputDocs,
              outputData: mb.outputData,
              outputDocs: mb.outputDocs,
              comment: mb.comment,
            );
          }),
        ],
      ],
    );
  }

  pw.Widget _buildPostHarvestTraceabilitySection(PostHarvestRecord record) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
      ),
      child: _buildMassBalanceTableCell(
        "Prodotti verificati e relative evidenze",
        record.traceabilityVerifiedProducts,
      ),
    );
  }

  @override
  pw.Widget buildSummaryActivitiesPage(
    List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})> ncs,
    VisitClosing? closing,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader("RIEPILOGO DELLE ATTIVITA'"),
        pw.SizedBox(height: 4),
        pw.Text(
          "Il presente rapporto documenta la attività di verifica ispettiva eseguite utilizzando la check-list SQNPI e il/i Disciplinare/i di produzione integrata Regionale nella versione applicabile",
          style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 10),
        _buildNcTable(ncs),
        pw.SizedBox(height: 15),
        _buildActivitiesSummaryCompliance(closing),
      ],
    );
  }

  pw.Widget _buildNcTable(
    List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})> ncs,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(40), // Requisito
        1: pw.FixedColumnWidth(80), // Coltura
        2: pw.FixedColumnWidth(80), // Aggregato
        3: pw.FixedColumnWidth(35), // Gravità
        4: pw.FlexColumnWidth(2), // Descrizione
        5: pw.FlexColumnWidth(2), // Azione
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeader("Requisito"),
            _buildTableHeader("Coltura/ Prodotto"),
            _buildTableHeader("Aggregato / UEP (rev.09)"),
            _buildTableHeader("Gravità"),
            _buildTableHeader("Descrizione (Rilievo NC)"),
            _buildTableHeader("Azione correttiva a cura dell'operatore"),
          ],
        ),
        if (ncs.isEmpty)
          pw.TableRow(
            children: [
              pw.Container(
                height: 40,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  "Nessuna non conformità rilevata",
                  style: valueStyle.copyWith(
                    fontStyle: pw.FontStyle.italic,
                    fontSize: 8,
                  ),
                ),
              ),
              ...List.filled(5, pw.Container()),
            ],
          )
        else
          ...ncs.map((nc) {
            return pw.TableRow(
              children: [
                _buildTableCell(nc.item.code),
                _buildTableCell(nc.uec.coltura),
                _buildTableCell(nc.uec.nAggregato),
                _buildTableCell(
                  ChecklistItemHelpers.getScoreText(
                    nc.item,
                    nc.response.punteggioUec,
                    nc.response.punteggioOperatore,
                  ),
                ),
                _buildTableCell(nc.response.rilievoNc),
                _buildTableCell(nc.response.azioneCorrettiva),
              ],
            );
          }),
      ],
    );
  }

  pw.Widget _buildActivitiesSummaryCompliance(VisitClosing? closing) {
    final c = closing;
    List inspectionMethods = [];
    try {
      if (c != null && c.inspectionMethods.isNotEmpty) {
        inspectionMethods = jsonDecode(c.inspectionMethods) as List;
      }
    } catch (_) {}

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildComplianceField(
            "Rispetto del Cap. 5 Procedura di adesione, gestione e controllo SQNPI:",
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                _buildMiniCheck(
                  c?.cap5Adherence == 1,
                  "Sì per tutte le colture verificate",
                ),
                pw.SizedBox(width: 15),
                _buildMiniCheck(
                  c?.cap5Adherence == 2,
                  "No per le seguenti colture",
                ),
              ],
            ),
            c != null && c.cap5SpecificCrops.isNotEmpty
                ? "Specificare colture: ${c.cap5SpecificCrops}"
                : null,
          ),
          pw.SizedBox(height: 8),
          _buildComplianceField(
            "L'azienda si impegna a rettificare la domanda per correggere eventuali incoerenze tra domanda, fascicolo:",
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                _buildMiniCheck(c?.commitmentToRectify == 0, "N/A"),
                pw.SizedBox(width: 15),
                _buildMiniCheck(
                  c?.commitmentToRectify == 1,
                  "Sì entro il (massimo 7 giorni)",
                ),
                pw.SizedBox(width: 15),
                _buildMiniCheck(c?.commitmentToRectify == 2, "No"),
              ],
            ),
            (c != null &&
                    c.commitmentToRectify == 1 &&
                    c.resolutionDeadline != null)
                ? "Data risoluzione prevista: ${c.resolutionDeadline!.day}/${c.resolutionDeadline!.month}/${c.resolutionDeadline!.year}"
                : null,
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            "La presente verifica ispettiva è stata eseguita mediante:",
            style: labelStyle.copyWith(fontSize: 8),
          ),
          pw.SizedBox(height: 5),
          _buildCheckItem(
            inspectionMethods.contains(
              "Interviste al personale aziendale sul luogo di lavoro durante la produzione",
            ),
            "Interviste al personale aziendale sul luogo di lavoro durante la produzione",
          ),
          _buildCheckItem(
            inspectionMethods.contains(
              "Osservazione dei siti, dei processi e dei siti dell'organizzazione ",
            ),
            "Osservazione dei siti, dei processi e dei siti dell'organizzazione ",
          ),
          _buildCheckItem(
            inspectionMethods.contains(
              "Visione di documentazione, procedure e registrazioni",
            ),
            "Visione di documentazione, procedure e registrazioni",
          ),
          pw.SizedBox(height: 12),
          _buildComplianceField(
            "Presenza del titolare o suo rappresentante:",
            _renderChoice(c?.representativePresent),
          ),
          pw.SizedBox(height: 8),
          _buildComplianceField(
            "L'esito della verifica è stato formalizzato alla presenza del titolare/rappresentante legale dell'Organizzazione (o suo delegato) che sottoscrive il presente report di verifica ispettiva:",
            pw.Row(
              children: [
                _buildMiniCheck(c?.isOutcomeFormalized ?? false, "Sì"),
                pw.SizedBox(width: 10),
                _buildMiniCheck(!(c?.isOutcomeFormalized ?? true), "No"),
              ],
            ),
          ),
          if (c != null && c.verificationNotes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text("Note:", style: labelStyle.copyWith(fontSize: 8)),
            pw.Text(
              c.verificationNotes.sanitizeForPdf,
              style: valueStyle.copyWith(fontSize: 8.5),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildComplianceField(
    String text,
    pw.Widget choice, [
    String? extra,
  ]) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(text, style: labelStyle.copyWith(fontSize: 8)),
            ),
            pw.SizedBox(width: 10),
            choice,
          ],
        ),
        if (extra != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(extra, style: valueStyle.copyWith(fontSize: 8.5)),
        ],
      ],
    );
  }

  pw.Widget _renderChoice(int? value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildMiniCheck(value == 1, "Sì"),
        pw.SizedBox(width: 10),
        _buildMiniCheck(value == 2, "No"),
      ],
    );
  }

  pw.Widget _buildCheckItem(bool isChecked, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            margin: const pw.EdgeInsets.only(top: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: isChecked
                ? pw.Center(
                    child: pw.Text(
                      "x",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(label, style: valueStyle.copyWith(fontSize: 8)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMassBalanceTableCell(String title, String? value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      constraints: const pw.BoxConstraints(minHeight: 40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
          pw.SizedBox(height: 3),
          pw.Text(value ?? "", style: pw.TextStyle(fontSize: 8.5)),
        ],
      ),
    );
  }

  pw.Widget _buildStandardMassBalanceBox({
    required int index,
    required String title,
    required String verifiedProducts,
    required String ingressData,
    required String ingressDocs,
    required String outputData,
    required String outputDocs,
    required String comment,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 25),
      child: pw.Column(
        children: [
          // Header (Grey Area)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.black, width: 0.6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "$index. $title",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Text(
                      "Prodotti verificati: ",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8.5,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.only(bottom: 1),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.black,
                              width: 0.4,
                            ),
                          ),
                        ),
                        child: pw.Text(
                          verifiedProducts,
                          style: pw.TextStyle(fontSize: 8.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Data Table
          pw.Table(
            border: const pw.TableBorder(
              left: pw.BorderSide(color: PdfColors.black, width: 0.6),
              right: pw.BorderSide(color: PdfColors.black, width: 0.6),
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
              horizontalInside: pw.BorderSide(
                color: PdfColors.black,
                width: 0.6,
              ),
              verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.6),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              // Ingress Row
              pw.TableRow(
                children: [
                  _buildMassBalanceTableCell("Dati in ingresso:", ingressData),
                  _buildMassBalanceTableCell(
                    "Documenti di riferimento:",
                    ingressDocs,
                  ),
                ],
              ),
              // Egress Row
              pw.TableRow(
                children: [
                  _buildMassBalanceTableCell("Dati in uscita:", outputData),
                  _buildMassBalanceTableCell(
                    "Documenti di riferimento:",
                    outputDocs,
                  ),
                ],
              ),
            ],
          ),
          // Comment Area
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            constraints: const pw.BoxConstraints(minHeight: 45),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.black, width: 0.6),
                right: pw.BorderSide(color: PdfColors.black, width: 0.6),
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Commento:",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  comment,
                  style: pw.TextStyle(fontSize: 8.5, lineSpacing: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget buildFinalEvaluationPage(
    VisitClosing? closing,
    List<({VisitSignature signature, Uint8List? bytes})> signatures,
    DateTime? date,
  ) {
    final c = closing;
    final inspectorSig = signatures
        .where((s) => s.signature.signatureType == 'inspector')
        .firstOrNull;
    final representativeSig = signatures
        .where((s) => s.signature.signatureType == 'representative')
        .firstOrNull;
    final delegateSig = signatures
        .where((s) => s.signature.signatureType == 'delegate')
        .firstOrNull;

    // We prioritize representative, fallback to delegate
    final orgSig = representativeSig ?? delegateSig;
    final orgLabel = representativeSig != null
        ? "Responsabile dell'Organizzazione"
        : (delegateSig != null
              ? "Delegato (${delegateSig.signature.signerName})"
              : "Responsabile dell'Organizzazione");

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                "VALUTAZIONE FINALE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "In riferimento al campo di applicazione dell'attività di verifica ispettiva",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.Text(
                "Ritenuto quanto valutato rappresentativo delle attività effettuate dall'Organizzazione",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          "Si ritiene l'Organizzazione:",
          style: labelStyle.copyWith(fontSize: 8),
        ),
        pw.SizedBox(height: 8),
        _buildCheckItem(
          c?.finalOutcome == 1,
          "Conforme - per i prodotti indicati (vedi sezione dettaglio prodotti e attività)",
        ),
        _buildCheckItem(
          c?.finalOutcome == 2,
          "Proposta provvedimento secondo la procedura di adesione, gestione e controllo nell'ambito SQNPI applicabile (esclusione lotto, sospensione del processo di certificazione aziendale, esclusione azienda),",
        ),
        if (c != null &&
            c.finalOutcome == 2 &&
            c.provisionDetail.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16),
            child: pw.Text(
              "INDICARE: ${c.provisionDetail}",
              style: valueStyle.copyWith(fontSize: 8.5),
            ),
          ),
        ],
        pw.SizedBox(height: 2),
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            "allo Standard di certificazione SQNPI",
            style: pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          "Viene rilasciata all'Organizzazione copia del presente report di verifica ispettiva con dettagli relativi ai rilievi effettuati (qualora applicabile)",
          style: pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          "Il presente rapporto di verifica ispettiva viene sottoscritto per accettazione dal responsabile dell'Organizzazione - qualora applicabile, in relazione al livello di conformità raggiunto, viene ribadito il livello delle sanzioni stabilite dallo standard SQNPI e le relative tempistiche per la risoluzione. Questo rapporto di verifica ispettiva è soggetto a riesame da parte della direzione della Bios srl.",
          style: pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          "Eventuali riserve (da parte del responsabile dell'Organizzazione)",
          style: labelStyle.copyWith(fontSize: 8),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          constraints: const pw.BoxConstraints(minHeight: 40),
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            (c?.representativeReservations ?? "").sanitizeForPdf,
            style: valueStyle.copyWith(fontSize: 8.5),
          ),
        ),
        pw.SizedBox(height: 20),
        _buildFinalSignatureTable(
          inspectorSig,
          orgSig,
          date,
          orgLabel,
          inspectorSig?.signature.signerName ?? "Tecnico Ispettore incaricato",
        ),
        pw.SizedBox(height: 20),
        _buildFinalDisclaimer(),
      ],
    );
  }

  pw.Widget _buildFinalSignatureTable(
    ({VisitSignature signature, Uint8List? bytes})? inspector,
    ({VisitSignature signature, Uint8List? bytes})? organization,
    DateTime? date,
    String orgLabel,
    String inspectorLabel,
  ) {
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : "      /      /      ";

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(80), // Data
        1: pw.FlexColumnWidth(1), // Ispettore
        2: pw.FlexColumnWidth(1.2), // Organizzazione
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeader("Data"),
            _buildTableHeader("Firma del Tecnico Ispettore"),
            _buildTableHeader(
              "Timbro dell'Organizzazione e firma per esteso del Responsabile dell'Organizzazione",
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(
              height: 60,
              alignment: pw.Alignment.center,
              child: pw.Text(dateStr, style: valueStyle.copyWith(fontSize: 9)),
            ),
            _buildSignatureCell(inspector, inspectorLabel),
            _buildSignatureCell(organization, orgLabel),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSignatureCell(
    ({VisitSignature signature, Uint8List? bytes})? sig, [
    String? subLabel,
  ]) {
    return pw.Container(
      height: 60,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (sig?.bytes != null)
            pw.Image(
              pw.MemoryImage(sig!.bytes!),
              height: 40,
              fit: pw.BoxFit.contain,
            )
          else
            pw.SizedBox(height: 40),
          if (subLabel != null)
            pw.Text(
              subLabel,
              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildFinalDisclaimer() {
    return pw.Column(
      children: [
        _buildBulletItem(
          "La sottoscrizione del presente report da parte del Tecnico Ispettore incaricato implica l'obbligo di inviare a Bios copia del presente report di verifica ispettiva e della checklist di verifica SQNPI ",
          suffix: "entro e non oltre 5 giorni lavorativi",
          suffixColor: PdfColors.red,
          suffixBold: true,
          rest:
              " dall'esecuzione dell'incarico pena applicazione delle sanzioni previste da D035 nella revisione applicabile.",
        ),
        pw.SizedBox(height: 4),
        _buildBulletItem(
          "Con la sottoscrizione del presente report da parte del Responsabile dell'Organizzazione (Titolare/Rappresentante legale o delegati in possesso di delega scritta), lo stesso dichiara di aver ricevuto copia di tutti i rilievi segnalati dal Tecnico Ispettore incaricato, così come elencati e descritti per ciascun prodotto;",
        ),
        pw.SizedBox(height: 4),
        _buildBulletItem(".. (rev.09)"),
      ],
    );
  }

  pw.Widget _buildBulletItem(
    String text, {
    String? suffix,
    PdfColor? suffixColor,
    bool suffixBold = false,
    String? rest,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, right: 8),
          child: pw.Text(
            "v",
            style: pw.TextStyle(
              font: pw.Font.zapfDingbats(),
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(fontSize: 7, color: PdfColors.black),
              children: [
                pw.TextSpan(text: text),
                if (suffix != null)
                  pw.TextSpan(
                    text: suffix,
                    style: pw.TextStyle(
                      color: suffixColor ?? PdfColors.black,
                      fontWeight: suffixBold
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                if (rest != null) pw.TextSpan(text: rest),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  List<pw.Widget> buildPhotoGalleryPage(
    Visit visit,
    List<({VisitAttachment attachment, Uint8List? bytes})> attachmentData,
  ) {
    final List<pw.Widget> widgets = [];

    // 1. Header (only once at the beginning)
    widgets.add(buildSectionHeader("GALLERIA FOTOGRAFICA E ALLEGATI"));
    widgets.add(pw.SizedBox(height: 10));

    if (attachmentData.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 100),
            child: pw.Text(
              "Nessun allegato fotografico presente per questa verifica.",
              style: valueStyle.copyWith(fontStyle: pw.FontStyle.italic),
            ),
          ),
        ),
      );
      return widgets;
    }

    // 2. Photos - One per page
    for (int i = 0; i < attachmentData.length; i++) {
      if (i > 0) {
        widgets.add(pw.NewPage());
      }
      widgets.add(_buildPhotoItem(attachmentData[i]));
    }

    return widgets;
  }

  pw.Widget _buildPhotoItem(
    ({VisitAttachment attachment, Uint8List? bytes}) data,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (data.bytes != null)
            pw.Center(
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(
                  pw.MemoryImage(data.bytes!),
                  height: 500, // Reduced to ensure everything fits on one page
                  fit: pw.BoxFit.contain,
                ),
              ),
            )
          else
            pw.Container(
              height: 200,
              color: PdfColors.grey100,
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      data.attachment.filePath.toLowerCase().endsWith('.pdf')
                          ? "DOCUMENTO PDF"
                          : "FORMATO NON SUPPORTATO",
                      style: labelStyle.copyWith(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "L'allegato è un file esterno e non può essere visualizzato come immagine.",
                      style: valueStyle.copyWith(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          pw.SizedBox(height: 10),
          if (data.attachment.caption.isNotEmpty)
            pw.Text(
              data.attachment.caption,
              style: valueStyle.copyWith(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(data.attachment.createdAt),
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              if (data.attachment.latitude != null)
                pw.Text(
                  "GPS: ${data.attachment.latitude!.toStringAsFixed(5)}, ${data.attachment.longitude!.toStringAsFixed(5)}",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
            ],
          ),
          if (data.attachment.attachmentType.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              "Tipo: ${data.attachment.attachmentType}",
              style: pw.TextStyle(
                fontSize: 8,
                color: style.accentColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRequisitoCell(ChecklistItem item, VisitUec? uec) {
    final indicazioniOdc = ChecklistItemHelpers.getIndicazioniOdc(item);

    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            ((item.code.trim() == '0.10' || item.code.trim() == '0.11')
                    ? item.obbligo.replaceFirst(
                        'superfici catastali',
                        'superfici aziendali',
                      )
                    : (item.code.trim() == '6.1')
                    ? "coinvolgimento intera superficie aziendale o parte di essa: devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)"
                    : (item.code.trim() == '6.2')
                    ? "coinvolgimento superfici aziendali dedicate a specifiche colture :devono essere rispettati i vincoli relativi all'avvicendamento stabiliti nei DPI (ristoppio, all'intervallo min di rientro della stessa coltura e alle eventuali ulteriori restrizioni alle colture inserite nell’intervallo)"
                    : (item.code.trim() == '15.15')
                    ? 'predisporre un piano aziendale all’interno del quale prevedere le modalità e tempi di realizzazione degli impegni aziendali relativi a:\n• formazione a tutto il personale sul tema della sicurezza sul lavoro;\n• formazione sul tema della sostenibilità delle produzioni almeno al personale tecnico assunto a tempo indeterminato'
                    : (item.code.trim() == '17.9')
                    ? 'Pubblicizzare l’indirizzo dell’Osservatorio SQNPI e le modalità di segnalazione. Per gli OA mediante l’utilizzo del proprio sito web; per le aziende singole sito web o almeno un cartello presso il centro aziendale.'
                    : item.obbligo)
                .sanitizeForPdf,
            style: valueStyle.copyWith(fontSize: 7.5),
          ),
          if (indicazioniOdc != null) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              "Indicazioni OdC: ${indicazioniOdc.sanitizeForPdf}",
              style: pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
          if (item.noteNorma.isNotEmpty ||
              item.code.trim() == '0.10' ||
              item.code.trim() == '0.11' ||
              item.code.trim() == '0.13' ||
              item.code.trim() == '15.3') ...[
            pw.SizedBox(height: 3),
            pw.Text(
              "Note: ${(item.code.trim() == '0.10' || item.code.trim() == '0.11'
                  ? "Eventuali incongruenze vanno gestite mediante AC finalizzate ad aggiornare la domanda. Nel caso in cui la formalizzazione dell'A.C possa compromettere la tempistica per il rilascio della certificazione o conformità ACA, l'ODC procede con l'allocazione delle parcelle interessate in uno o più aggregati- UEC aggiuntivi e l'attribuzione della relativa N.C. ** Nel caso di piano colturale difforme si sottolinea l’importanza di accertare la natura avvicendante o intercalare della coltura, da gestire come riportato al punto 5 della Norma.**"
                  : item.code.trim() == '0.13'
                  ? "La relativa non conformità viene attribuita nella seguente maniera:\n- operatore interessato alla fase di campo : si attribuisce il valore correlato alla fase di campo\n- operatore post raccolta: si attribuisce il valore correlato alla fase di raccolta/ post raccolta\n- operatore interessato a tutte le fasi del processo, di campo e di raccolta/post raccolta: si attribuisce il valore correlato alla fase di post raccolta\n(Vedere anche punto 17.9 del PCN)"
                  : item.code.trim() == '15.3'
                  ? "Verifica analisi"
                  : item.noteNorma).sanitizeForPdf}",
              style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
            ),
          ],
          if (item.code.trim() == '0.2') ...[
            pw.SizedBox(height: 3),
            pw.Text(
              "ESCL../SOSP..: 'SI' (esclusione lotto) in caso di assenza completa delle registrazioni",
              style: pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.red700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
          if (item.tipologiaControllo.isNotEmpty ||
              item.frequenzaAssociato.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              [
                if (item.tipologiaControllo.isNotEmpty)
                  "Gravità NC (UEC/Lotto): ${item.code.trim() == '6.2' ? "1 se è nell'intervallo 3% -10% della SAU aziendale dedicata alla specifica coltura sulla quale non vengono rispettate le norme ; 2 se nell'intervallo 10%-30%; 3 se > 30%." : item.tipologiaControllo}",
                if (item.frequenzaAssociato.isNotEmpty)
                  "Gravità NC (Operatore): ${item.frequenzaAssociato}",
              ].join(" | ").sanitizeForPdf,
              style: pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
          if (uec != null) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              uec.id.startsWith('OP-')
                  ? "Target: Operatore"
                  : "Target: Aggregato/UEC ${uec.nAggregato} (${uec.coltura})",
              style: pw.TextStyle(
                fontSize: 6.5,
                color: PdfColors.grey800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  List<pw.Widget> buildChecklistPage(
    Visit visit,
    List<({ChecklistResponse response, ChecklistItem item, VisitUec uec})>
    allResponses,
    List<ChecklistItem> allItems,
    List<String> phases,
  ) {
    final List<pw.Widget> widgets = [];
    widgets.add(buildSectionHeader("CHECKLIST DI VERIFICA COMPLETA"));
    widgets.add(pw.SizedBox(height: 10));

    if (allItems.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            "Nessun dato registrato nella checklist.",
            style: valueStyle.copyWith(fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
      return widgets;
    }

    // Group items by phase
    final itemsByPhase = groupBy(
      allItems,
      (ChecklistItem item) => item.fase.trim(),
    );

    for (final phase in phases) {
      final items = itemsByPhase[phase.trim()] ?? [];
      if (items.isEmpty) continue;

      // Add Phase Header
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          margin: const pw.EdgeInsets.only(top: 15, bottom: 5),
          decoration: pw.BoxDecoration(
            color: style.secondaryColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            phase.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            textAlign: pw.TextAlign.left,
          ),
        ),
      );

      // Group responses by item code for efficient lookup (O(1) instead of O(N))
      final responsesByItemCode =
          <
            String,
            List<
              ({ChecklistResponse response, ChecklistItem item, VisitUec uec})
            >
          >{};
      for (final r in allResponses) {
        responsesByItemCode.putIfAbsent(r.item.code, () => []).add(r);
      }

      // Create table for this phase
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(35), // Codice
            1: pw.FlexColumnWidth(3), // Descrizione
            2: pw.FixedColumnWidth(40), // Esito
            3: pw.FixedColumnWidth(45), // Score
            4: pw.FlexColumnWidth(2), // Note/Rilievo/azione
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeader("Cod."),
                _buildTableHeader("Requisito"),
                _buildTableHeader("Esito"),
                _buildTableHeader("KO Score"),
                _buildTableHeader("Note / Rilievo / Azione"),
              ],
            ),
            ...items
                .where(
                  (item) =>
                      item.code.trim() != '1.2' &&
                      item.code.trim() != '1.5' &&
                      item.code.trim() != '8.2' &&
                      item.code.trim() != '10.4' &&
                      item.code.trim() != '17.10',
                )
                .expand((item) {
                  // Get responses for this specific item using the map
                  final itemResponses = responsesByItemCode[item.code] ?? [];

                  // Check if it's a title item (e.g. "17" or "0.0")
                  final isTitle =
                      !item.code.trim().contains('.') ||
                      item.code.trim() == '0.0';

                  if (isTitle) {
                    return [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey50),
                        children: [
                          _buildTableCell(item.code),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              item.obbligo.sanitizeForPdf,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 8,
                                color: PdfColors.blueGrey800,
                              ),
                            ),
                          ),
                          _buildTableCell(""), // No esito for titles
                          _buildTableCell(""), // No score for titles
                          _buildTableCell(""), // No notes for titles
                        ],
                      ),
                    ];
                  }

                  final visitTypes = visit.visitType
                      .split(',')
                      .map((e) => e.trim().toUpperCase())
                      .where((e) => e.isNotEmpty)
                      .toSet();
                  final isAcaOnly =
                      visitTypes.length == 1 && visitTypes.contains('ACA');

                  if (itemResponses.isEmpty) {
                    // Se ACA-only, i punti non compilati devono essere NA (richiesta specifica utente)
                    final outcome = isAcaOnly ? "NA" : "-";

                    // Per punti <= 12, lo score deve essere vuoto se NA.
                    // Per punti 13-17, lo score può essere NA o vuoto (l'utente dice di non mettere NA se NA)
                    final mainCode = item.code.split('.').first;
                    final codeNum = int.tryParse(mainCode);
                    final isAcaUncompiledPoint =
                        codeNum != null && codeNum >= 13 && codeNum <= 17;

                    final score = (isAcaOnly && isAcaUncompiledPoint)
                        ? "NA"
                        : (isAcaOnly ? "" : "-");

                    String noteText = "";
                    if (isAcaOnly && isAcaUncompiledPoint) {
                      noteText = "NON APPLICABILE AL CONTESTO AZIENDALE";
                    }

                    return [
                      pw.TableRow(
                        children: [
                          _buildTableCell(item.code),
                          _buildRequisitoCell(item, null),
                          _buildTableChecks(outcome),
                          _buildTableCell(score),
                          _buildTableCell(noteText),
                        ],
                      ),
                    ];
                  }

                  // Group identical responses to avoid duplicating rows
                  // when all UECs share the same outcome and notes (NA/OK case)
                  String outcomeStr(int conformita) {
                    if (conformita == 0) return "OK";
                    if (conformita == 1) return "NA";
                    if (conformita == 2) return "KO";
                    return "-";
                  }

                  String notesStr(ChecklistResponse resp) {
                    return [
                      if (resp.rilievoNc.isNotEmpty)
                        "Rilievo: ${resp.rilievoNc}",
                      if (resp.azioneCorrettiva.isNotEmpty)
                        "Azione: ${resp.azioneCorrettiva}",
                      if (resp.note.isNotEmpty) "Note: ${resp.note}",
                    ].join("\n").sanitizeForPdf;
                  }

                  // Build a grouping key from outcome + notes + score
                  final grouped =
                      <
                        String,
                        List<
                          ({
                            ChecklistResponse response,
                            ChecklistItem item,
                            VisitUec uec,
                          })
                        >
                      >{};
                  for (final r in itemResponses) {
                    final key =
                        '${outcomeStr(r.response.conformita)}|${notesStr(r.response)}|${r.response.punteggioUec}|${r.response.punteggioOperatore}';
                    grouped.putIfAbsent(key, () => []).add(r);
                  }

                  return grouped.entries.expand((entry) {
                    final group = entry.value;
                    final first = group.first;
                    final outcome = outcomeStr(first.response.conformita);
                    String notes = notesStr(first.response);

                    final mainCode = first.item.code.split('.').first;
                    final codeNum = int.tryParse(mainCode);
                    final isAcaUncompiledPoint =
                        codeNum != null && codeNum >= 13 && codeNum <= 17;

                    if (isAcaOnly && isAcaUncompiledPoint && notes.isEmpty) {
                      notes = "NON APPLICABILE AL CONTESTO AZIENDALE";
                    }

                    String score = ChecklistItemHelpers.getScoreText(
                      first.item,
                      first.response.punteggioUec,
                      first.response.punteggioOperatore,
                      esclusioneUecText: first.item.esclusioneUecText,
                      esclusioneLottoText: first.item.esclusioneLottoText,
                      esclusioneOperatoreText:
                          first.item.esclusioneOperatoreText,
                    );

                    if (group.length == 1) {
                      // Single response: show with specific UEC target
                      return [
                        pw.TableRow(
                          children: [
                            _buildTableCell(first.item.code),
                            _buildRequisitoCell(first.item, first.uec),
                            _buildTableChecks(outcome),
                            _buildScoreCell(score, isKo: outcome == "KO"),
                            _buildTableCell(notes),
                          ],
                        ),
                      ];
                    } else {
                      // Multiple identical responses: merge into one row
                      // Show all target UECs as a combined label
                      final targetLabels = group
                          .map((r) {
                            if (r.uec.id.startsWith('OP-')) return "Operatore";
                            return r.uec.coltura;
                          })
                          .toSet()
                          .toList();

                      return [
                        pw.TableRow(
                          children: [
                            _buildTableCell(first.item.code),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildRequisitoCell(first.item, null),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                    left: 4,
                                    bottom: 4,
                                  ),
                                  child: pw.Text(
                                    "Target: ${targetLabels.join(', ')}",
                                    style: pw.TextStyle(
                                      fontSize: 6.5,
                                      color: PdfColors.grey800,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildTableChecks(outcome),
                            _buildScoreCell(score, isKo: outcome == "KO"),
                            _buildTableCell(notes),
                          ],
                        ),
                      ];
                    }
                  });
                }),
          ],
        ),
      );
    }

    return widgets;
  }
}

class _PostHarvestPhaseData {
  final String fase;
  final bool inProprio;
  final bool terzista;
  final String prodotto;
  final bool? conformitaSqnpi;
  final bool? tracciabile;
  final String note;
  final String certificatoTerzista;

  _PostHarvestPhaseData({
    required this.fase,
    this.inProprio = false,
    this.terzista = false,
    this.prodotto = '',
    this.conformitaSqnpi,
    this.tracciabile,
    this.note = '',
    this.certificatoTerzista = '',
  });

  factory _PostHarvestPhaseData.fromJson(Map<String, dynamic> json) =>
      _PostHarvestPhaseData(
        fase: json['fase'] ?? '',
        inProprio: json['inProprio'] ?? false,
        terzista: json['terzista'] ?? false,
        prodotto: json['prodotto'] ?? '',
        conformitaSqnpi: json['conformitaSqnpi'],
        tracciabile: json['tracciabile'],
        note: json['note'] ?? '',
        certificatoTerzista:
            json['certificatoTerzista'] ?? json['noteTracciabile'] ?? '',
      );
}

class _PostHarvestMassBalanceData {
  final String verifiedProducts;
  final String inputData;
  final String inputDocs;
  final String outputData;
  final String outputDocs;
  final String comment;

  _PostHarvestMassBalanceData({
    this.verifiedProducts = '',
    this.inputData = '',
    this.inputDocs = '',
    this.outputData = '',
    this.outputDocs = '',
    this.comment = '',
  });

  factory _PostHarvestMassBalanceData.fromJson(Map<String, dynamic> json) =>
      _PostHarvestMassBalanceData(
        verifiedProducts: json['verifiedProducts'] ?? '',
        inputData: json['inputData'] ?? '',
        inputDocs: json['inputDocs'] ?? '',
        outputData: json['outputData'] ?? '',
        outputDocs: json['outputDocs'] ?? '',
        comment: json['comment'] ?? '',
      );
}
