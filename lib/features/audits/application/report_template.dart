import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:collection/collection.dart';
import '../../../core/storage/app_database.dart';

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
    // Sage Green (#7B8C7D)
    this.accentColor = const PdfColor.fromInt(0xFF7B8C7D),
    this.margin = 32.0,
  });

  static const defaultStyle = ReportStyle();
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
    pw.MemoryImage? logoSqnpi,
  );
  pw.Widget buildPageFooter(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
  );

  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi,
  );

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
}

/// Standard implementation of the SQNPI template
class StandardSqnpiTemplate extends ReportTemplate {
  const StandardSqnpiTemplate({super.style});

  pw.TextStyle get labelStyle => pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey700,
  );

  pw.TextStyle get valueStyle =>
      pw.TextStyle(fontSize: 10, color: style.primaryColor);

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
  pw.Widget buildPageHeader(
    pw.Context context,
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 25),
      padding: const pw.EdgeInsets.only(bottom: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (logoBios != null) pw.Image(logoBios, height: 55),
              pw.SizedBox(width: 15),
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 55),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'VERBALE DI ISPEZIONE SQNPI',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: style.accentColor,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                company?.ragioneSociale ?? visit.companyName,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: style.primaryColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
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
          pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: style.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoBios != null)
                pw.Image(logoBios, height: 110)
              else
                pw.Text(
                  'BIOS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 32,
                    color: style.primaryColor,
                  ),
                ),
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 110),
            ],
          ),
          pw.Spacer(flex: 1),
          pw.Container(height: 4, width: 80, color: style.accentColor),
          pw.SizedBox(height: 25),
          pw.Text(
            'RAPPORTO FINALE DI\nVERIFICA ISPETTIVA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 44,
              color: style.primaryColor,
              letterSpacing: 2,
              lineSpacing: 1.1,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'SISTEMA DI QUALITÀ NAZIONALE PRODUZIONE INTEGRATA',
            style: pw.TextStyle(
              fontSize: 10,
              color: style.accentColor,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 60),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'OPERATORE CERTIFICATO',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                company?.ragioneSociale ?? visit.companyName,
                style: pw.TextStyle(
                  fontSize: 26,
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
          pw.Spacer(flex: 2),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildCoverInfoItem(
                  'Data Ispezione',
                  "${visit.scheduledAt.day.toString().padLeft(2, '0')}/${visit.scheduledAt.month.toString().padLeft(2, '0')}/${visit.scheduledAt.year}",
                ),
                _buildCoverInfoItem(
                  'Codice Ispezione',
                  "#${visit.id.split('-').first.toUpperCase()}",
                ),
                _buildCoverInfoItem('Stato', 'DOC. ORIGINALE'),
              ],
            ),
          ),
        ],
      ),
    );
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
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: style.secondaryColor,
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

    final dateStr =
        "${visit.scheduledAt.day.toString().padLeft(2, '0')}/${visit.scheduledAt.month.toString().padLeft(2, '0')}/${visit.scheduledAt.year}";

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
        pw.SizedBox(height: 20),
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
                  "Ispettore (RGVI):",
                  visit.inspectorName,
                  isFullWidth: false,
                  isLast: true,
                ),
                buildValueBlock(
                  "Ultima Verifica:",
                  lastVisitDate != null
                      ? '${lastVisitDate.day.toString().padLeft(2, '0')}/${lastVisitDate.month.toString().padLeft(2, '0')}/${lastVisitDate.year}'
                      : "-",
                  isFullWidth: false,
                  isLast: true,
                ),
              ]),
              buildGridRow([
                _buildToggleBlock("Visita Congiunta:", company.isJointVisit),
                _buildToggleBlock(
                  "Certificato Estero:",
                  company.previousOdcName.isNotEmpty,
                ),
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
              buildValueBlock("Ispettore RGVI:", visit.inspectorName, isLast: false),
              if (visit.companionName.isNotEmpty)
                buildValueBlock(
                  "Affiancatore GVI2:",
                  visit.companionName,
                  isLast: false,
                ),
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
      margin: const pw.EdgeInsets.only(top: 18, bottom: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: scaleOpacity(style.accentColor, 0.08),
        border: pw.Border(
          left: pw.BorderSide(color: style.accentColor, width: 4),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
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
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
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
              value,
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
            shape: pw.BoxShape.circle,
            border: pw.Border.all(
              color: isChecked ? style.accentColor : PdfColors.grey300,
              width: 1.0,
            ),
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Container(
                    width: 5,
                    height: 5,
                    decoration: pw.BoxDecoration(
                      color: style.accentColor,
                      shape: pw.BoxShape.circle,
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
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                      "Disciplinare/i Regionale di Difesa Integrata adottati dall'azienda (rev.08)",
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
                      hasRef('CHECKLIST_BIOS'),
                      "Checklist di Controllo (Digitale in-App) Allegato ad uso interno Bios (rev.08)",
                    ),
                    _buildDocCheck(
                      hasRef('ALTRO_RIF'),
                      "Altro (specificare): ${hasRef('ALTRO_RIF') ? getRefExtra('ALTRO_RIF') : ''}",
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
                      hasViewed('RAPPORTO_PREC'),
                      "Rapporto dell'audit Bios precedente (se applicabile)",
                    ),
                    _buildDocCheck(
                      hasViewed('ESITO_CERT_ALTRO_ODC'),
                      "Esito di certificazione e NC emesse da altro Odc (se applicabile)",
                    ),
                    _buildDocCheck(
                      hasViewed('ALTRO_VIS'),
                      "Altro (obbligatorio specificare): ${hasViewed('ALTRO_VIS') ? getViewedExtra('ALTRO_VIS') : ''}",
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
                color: isChecked ? style.accentColor : PdfColors.grey400,
                width: 0.8,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1.5)),
              color: isChecked ? style.accentColor : null,
            ),
            child: isChecked
                ? pw.Center(
                    child: pw.Container(
                      width: 6,
                      height: 6,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(1),
                        ),
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
            0: pw.FixedColumnWidth(60), // Aggregato
            1: pw.FixedColumnWidth(80), // Prodotto in domanda
            2: pw.FixedColumnWidth(80), // Prodotto riscontrato
            3: pw.FixedColumnWidth(65), // Coerenza
            4: pw.FixedColumnWidth(65), // Conformità
            5: pw.FixedColumnWidth(65), // Campionamento
            6: pw.FixedColumnWidth(60), // Tracciabile
            7: pw.FixedColumnWidth(60), // Reclami
            8: pw.FixedColumnWidth(80), // Processo campo
            9: pw.FlexColumnWidth(1), // Note
          },
          children: [
            // Header Row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableHeader("Aggregato (n.) (rev.08)"),
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
            ...uecs.map(
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
                  ...List.filled(9, pw.Container()),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: labelStyle.copyWith(fontSize: 7, color: PdfColors.black),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: valueStyle.copyWith(fontSize: 8)),
    );
  }

  pw.Widget _buildTableChecks(String value) {
    final v = value.toUpperCase();
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildMiniCheck(v == "SI" || v == "SÌ", "Si"),
          _buildMiniCheck(v == "NO", "No"),
          _buildMiniCheck(v == "N/A" || v == "NA", "N/A"),
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
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
            color: isChecked ? style.accentColor : null,
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Container(
                    width: 3.5,
                    height: 3.5,
                    color: PdfColors.white,
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
                    "$index. BILANCIO DI MASSA (spazio per l'evidenza di un bilancio di massa)",
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
                          mb.verifiedProducts ?? "",
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
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              // Ingress Row
              pw.TableRow(
                children: [
                  _buildMassBalanceTableCell(
                    "Dati in ingresso:",
                    mb.ingressData,
                  ),
                  _buildMassBalanceTableCell(
                    "Documenti di riferimento:",
                    mb.ingressDocs,
                  ),
                ],
              ),
              // Egress Row
              pw.TableRow(
                children: [
                  _buildMassBalanceTableCell("Dati in uscita:", mb.egressData),
                  _buildMassBalanceTableCell(
                    "Documenti di riferimento:",
                    mb.egressDocs,
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
                  mb.comment ?? "",
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
        pw.Text('FASE DI POST RACCOLTA (verifica in loco)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 10),
        _buildPostHarvestPhasesTable(phasesList),
        pw.SizedBox(height: 20),
        pw.Text('BILANCIO DI MASSA (specifico per la fase di post-raccolta)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 10),
        _buildPostHarvestMassBalanceSection(postHarvest, mbBalancesList),
        pw.SizedBox(height: 20),
        pw.Text('PROVA DI RINTRACCIABILITA\' (evidenze riscontrate)(Rif. Check-list punto 16.1)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
            _buildTableHeader("Note / Certificato Terzista"),
          ],
        ),
        if (phases.isEmpty)
          pw.TableRow(
            children: [
              pw.Container(
                height: 30,
                alignment: pw.Alignment.center,
                child: pw.Text("Nessun dato registrato",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ),
              ...List.filled(6, pw.Container()),
            ],
          ),
        ...phases.map((p) => pw.TableRow(
              children: [
                _buildTableCell(p.fase),
                _buildTableYesNo(p.inProprio),
                _buildTableYesNo(p.terzista),
                _buildTableCell(p.prodotto),
                _buildTableChecks(p.conformitaSqnpi == true
                    ? "SI"
                    : p.conformitaSqnpi == false
                        ? "NO"
                        : "N/A"),
                _buildTableChecks(p.tracciabile == true
                    ? "SI"
                    : p.tracciabile == false
                        ? "NO"
                        : "N/A"),
                _buildTableCell(p.terzista ? p.certificatoTerzista : p.note),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPostHarvestMassBalanceSection(
    PostHarvestRecord record,
    List<_PostHarvestMassBalanceData> balances,
  ) {
    final bool hasMainBalance = record.mbVerifiedProducts.isNotEmpty ||
        record.mbInputData.isNotEmpty ||
        record.mbInputDocs.isNotEmpty ||
        record.mbOutputData.isNotEmpty ||
        record.mbOutputDocs.isNotEmpty ||
        record.mbComment.isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (hasMainBalance) ...[
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.6),
            ),
            child: pw.Column(
              children: [
                _buildMassBalanceFullRow(
                    "Prodotti verificati:", record.mbVerifiedProducts),
                pw.Divider(height: 0.6, color: PdfColors.black),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildMassBalanceTableCell(
                        "Dati in ingresso (kg):",
                        record.mbInputData,
                      ),
                    ),
                    pw.VerticalDivider(width: 0.6, color: PdfColors.black),
                    pw.Expanded(
                      child: _buildMassBalanceTableCell(
                        "Documenti di riferimento:",
                        record.mbInputDocs,
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 0.6, color: PdfColors.black),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildMassBalanceTableCell(
                        "Dati in uscita (kg):",
                        record.mbOutputData,
                      ),
                    ),
                    pw.VerticalDivider(width: 0.6, color: PdfColors.black),
                    pw.Expanded(
                      child: _buildMassBalanceTableCell(
                        "Documenti di riferimento:",
                        record.mbOutputDocs,
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 0.6, color: PdfColors.black),
                _buildMassBalanceFullRow("Commento:", record.mbComment),
              ],
            ),
          ),
          if (balances.isNotEmpty) pw.SizedBox(height: 15),
        ],
        if (balances.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text("Dettaglio Bilanci Di Massa Post-Raccolta:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.SizedBox(height: 10),
          ...balances.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final mb = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.6),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.grey100,
                    child: pw.Text("Bilancio n. $idx",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ),
                  pw.Divider(height: 0.6, color: PdfColors.black),
                  _buildMassBalanceFullRow(
                      "Prodotti verificati:", mb.verifiedProducts),
                  pw.Divider(height: 0.6, color: PdfColors.black),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMassBalanceTableCell(
                          "Dati in ingresso (kg):",
                          mb.inputData,
                        ),
                      ),
                      pw.VerticalDivider(width: 0.6, color: PdfColors.black),
                      pw.Expanded(
                        child: _buildMassBalanceTableCell(
                          "Documenti di riferimento:",
                          mb.inputDocs,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(height: 0.6, color: PdfColors.black),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMassBalanceTableCell(
                          "Dati in uscita (kg):",
                          mb.outputData,
                        ),
                      ),
                      pw.VerticalDivider(width: 0.6, color: PdfColors.black),
                      pw.Expanded(
                        child: _buildMassBalanceTableCell(
                          "Documenti di riferimento:",
                          mb.outputDocs,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(height: 0.6, color: PdfColors.black),
                  _buildMassBalanceFullRow("Commento:", mb.comment),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  pw.Widget _buildMassBalanceFullRow(String title, String? value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(value ?? "", style: pw.TextStyle(fontSize: 8.5)),
          ),
        ],
      ),
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
