import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/storage/app_database.dart';
import '../../../core/domain/visit_outcome.dart';

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
  pw.Widget buildSummary(VisitOutcomeSummary outcome, Visit visit);

  pw.Widget buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  );

  pw.Widget buildM904Summary(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  );

  pw.Widget buildAttachmentsSection(
    List<VisitAttachment> attachments,
    Map<String, pw.MemoryImage> images,
  );

  pw.Widget buildMassBalanceSection(MassBalanceRecord? record);
  pw.Widget buildClosingSection(VisitClosing? closing);
  pw.Widget buildAziendaCompliance(Visit visit, VisitCompany? company);

  pw.Widget buildUecDetailsSection(
    List<VisitUec> uecs,
    Map<String, List<VisitLot>> lotsPerUec,
  );

  pw.Widget buildSignaturesSection(
    List<VisitSignature> signatures,
    Map<String, pw.MemoryImage> images,
  );

  pw.Widget buildFullChecklist(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>
    responses,
  );
  pw.Widget buildPostHarvestSection(PostHarvestRecord? record);
  pw.Widget buildPreviousNcSection(VisitPreviousNcManagement? record);
  pw.Widget buildSamplingSection(
    List<VisitSample> samples,
    Map<String, pw.MemoryImage> images,
  );

  pw.Widget buildM904Page({
    required Visit visit,
    required VisitCompany? company,
    required VisitOutcomeSummary outcome,
    required List<VisitUec> uecs,
    required List<VisitSample> samples,
    required MassBalanceRecord? massBalance,
    required PostHarvestRecord? postHarvest,
    required VisitClosing? closing,
    required List<VisitAttachment> attachments,
    required List<VisitSignature> signatures,
    required Map<String, pw.MemoryImage> signatureImages,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi,
  });

  pw.Widget buildM904SecondPage({
    required Visit visit,
    required VisitCompany? company,
    required VisitPreviousNcManagement? prevNc,
    required List<VisitAttachment> attachments,
    pw.MemoryImage? logoBios,
  });

  pw.Widget buildM904ThirdPage({
    required Visit visit,
    required VisitCompany? company,
    required VisitClosing? closing,
    required List<VisitSignature> signatures,
    required Map<String, pw.MemoryImage> signatureImages,
    pw.MemoryImage? logoBios,
  });

  pw.Widget buildM904CultivationPage({
    required Visit visit,
    required VisitCompany? company,
    required List<VisitUec> uecs,
    pw.MemoryImage? logoBios,
  });

  pw.Widget buildM904PostHarvestPage({
    required Visit visit,
    required VisitCompany? company,
    required PostHarvestRecord? postHarvest,
    pw.MemoryImage? logoBios,
  });

  pw.Widget buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: style.primaryColor, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
      margin: const pw.EdgeInsets.only(bottom: 12, top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              color: style.primaryColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          pw.Container(width: 40, height: 2, color: style.accentColor),
        ],
      ),
    );
  }
}

/// Standard implementation of the SQNPI template
class StandardSqnpiTemplate extends ReportTemplate {
  const StandardSqnpiTemplate({super.style});

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
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: style.primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VERBALE DI ISPEZIONE SQNPI',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: style.secondaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                company != null ? company.ragioneSociale : visit.companyName,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: style.primaryColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
              if (logoBios != null) pw.Image(logoBios, height: 24),
              pw.SizedBox(width: 8),
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 24),
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
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generato il ${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
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
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 50),
            ],
          ),
          pw.SizedBox(height: 60),
          pw.Container(height: 4, width: 100, color: style.accentColor),
          pw.SizedBox(height: 16),
          pw.Text(
            'RAPPORTO DI\nVERIFICA ISPETTIVA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 36,
              color: style.primaryColor,
              letterSpacing: 1.5,
              lineSpacing: 1.1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Sistema di Qualità Nazionale Produzione Integrata (SQNPI)',
            style: pw.TextStyle(
              fontSize: 14,
              color: style.secondaryColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: style.primaryColor, width: 2),
              ),
            ),
            padding: const pw.EdgeInsets.only(left: 20, top: 10, bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'OPERATORE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  company?.ragioneSociale ?? visit.companyName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: style.primaryColor,
                  ),
                ),
                if (company?.cuaa != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'CUAA: ${company!.cuaa}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: style.secondaryColor,
                    ),
                  ),
                ],
                if (company?.indirizzo != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${company!.indirizzo}, ${company.cap} ${company.comune}',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            children: [
              _buildCoverInfoItem(
                'DATA ISPEZIONE',
                '${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
              ),
              pw.SizedBox(width: 40),
              _buildCoverInfoItem('TIPO VISITÀ', visit.visitType.toUpperCase()),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              _buildCoverInfoItem(
                'DURATA EFFETTIVA',
                '${visit.durationHours} ORE',
              ),
              pw.SizedBox(width: 40),
              _buildCoverInfoItem('ISPETTORE', visit.inspectorName),
            ],
          ),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              children: [
                pw.Container(width: 3, height: 30, color: style.primaryColor),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Text(
                    'Bios S.r.l. - Organismo di Controllo e Certificazione\nVia P.S. Mattarella, 5 - 36063 Marostica (VI)',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ),
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
  pw.Widget buildM904Page({
    required Visit visit,
    required VisitCompany? company,
    required VisitOutcomeSummary outcome,
    required List<VisitUec> uecs,
    required List<VisitSample> samples,
    required MassBalanceRecord? massBalance,
    required PostHarvestRecord? postHarvest,
    required VisitClosing? closing,
    required List<VisitAttachment> attachments,
    required List<VisitSignature> signatures,
    required Map<String, pw.MemoryImage> signatureImages,
    pw.MemoryImage? logoBios,
    pw.MemoryImage? logoSqnpi,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header Section (Reduced version of cover)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MODULO M904',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: style.primaryColor,
                  ),
                ),
                pw.Text(
                  'Rapporto di verifica ispettiva SQNPI',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: style.secondaryColor,
                  ),
                ),
              ],
            ),
            if (logoBios != null) pw.Image(logoBios, height: 30),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(color: style.accentColor, thickness: 1.5),
        pw.SizedBox(height: 15),

        // 1. DATA AZIENDA
        _buildM904SectionTitle('1. DATI DELL\'OPERATORE CONTROLLATO'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _buildM904Row(
                'Ragione Sociale:',
                company?.ragioneSociale ?? visit.companyName,
              ),
              _buildM904Row('CUAA / Cod. Fisc.:', company?.cuaa ?? '-'),
              _buildM904Row(
                'Sede Legale:',
                company != null
                    ? '${company.indirizzo}, ${company.cap} ${company.comune} (${company.provincia})'
                    : '-',
              ),
              _buildM904Row(
                'Referente Aziendale:',
                visit.representativeName.isNotEmpty
                    ? visit.representativeName
                    : '-',
              ),
              _buildM904Row(
                'Sede Operativa:',
                company?.sedeOperativaIndirizzo != null &&
                        company!.sedeOperativaIndirizzo.isNotEmpty
                    ? '${company.sedeOperativaIndirizzo}, ${company.sedeOperativaCap} ${company.sedeOperativaComune} (${company.sedeOperativaProvincia})'
                    : 'Come sede legale',
              ),
              if (company?.latitudeText != null &&
                  company!.latitudeText.isNotEmpty)
                _buildM904Row(
                  'Coordinate Geog.:',
                  'Lat: ${company.latitudeText}, Long: ${company.longitudeText}',
                ),
              _buildM904Row(
                'Sito Manipolazione:',
                company?.manipulationSiteAddress != null &&
                        company!.manipulationSiteAddress.isNotEmpty
                    ? '${company.manipulationSiteAddress}, ${company.manipulationSiteCap} ${company.manipulationSiteComune} (${company.manipulationSiteProvincia})'
                    : 'N.A.',
              ),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildM904Row(
                      'Protocollo SQNPI:',
                      company?.sqnpiProtocol ?? '-',
                    ),
                  ),
                  pw.Expanded(
                    child: _buildM904Row(
                      'Data Domanda:',
                      company?.sqnpiSubmissionDate != null
                          ? '${company!.sqnpiSubmissionDate!.day}/${company.sqnpiSubmissionDate!.month}/${company.sqnpiSubmissionDate!.year}'
                          : '-',
                    ),
                  ),
                ],
              ),
              _buildM904Row(
                'Periodo Picco:',
                company?.peakPeriodFrom != null &&
                        company!.peakPeriodFrom.isNotEmpty
                    ? '${company.peakPeriodFrom} - ${company.peakPeriodTo}'
                    : '-',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // 2. DETTAGLI VERIFICA
        _buildM904SectionTitle('2. DETTAGLI DELLA VERIFICA ISPETTIVA'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _buildM904Row(
                'Data Ispezione:',
                '${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
              ),
              _buildM904Row('Tipo Ispezione:', visit.visitType.toUpperCase()),
              _buildM904Row(
                'Ispettore BIOS:',
                visit.inspectorName.toUpperCase(),
              ),
              _buildM904Row(
                'Ambito Controllo:',
                'SQNPI - Produzione Integrata',
              ),
              _buildM904Row('Durata (ore):', '${visit.durationHours} h'),
              _buildM904Row(
                'Visita Congiunta:',
                company?.isJointVisit == true
                    ? 'SÌ (${company?.jointVisitDetails ?? "-"})'
                    : 'NO',
              ),
              _buildM904Row(
                'Persone Contattate:',
                visit.contactedPersons.isNotEmpty
                    ? visit.contactedPersons
                    : '-',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        _buildM904SectionTitle('3. PRODOTTI E PROCESSI CONTROLLATI'),
        // Testo aggiuntivo per Rev. 08 se presente sanzione
        if (closing != null && closing.finalOutcome == 2)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
            child: pw.Text(
              'Specificare quale sanzione/provvedimento è stato proposto: ${closing.provisionDetail}',
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
              ),
            ),
          ),
        _buildM904DetailedUecTable(uecs),
        if (company?.marchioNature.isNotEmpty == true)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, left: 2),
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DETTAGLI MARCHIO SQNPI:',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Natura: ${company?.marchioNature} | Processi: ${company?.marchioProcesses} | Bozza Etichetta: ${company?.marchioLabelDraft == true ? "SÌ" : "NO"}',
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.amber900),
                  ),
                ],
              ),
            ),
          ),
        if (uecs.length > 15)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, left: 4),
            child: pw.Text(
              '* Ulteriori UEC elencate nelle pagine di dettaglio del rapporto.',
              style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
            ),
          ),
        pw.SizedBox(height: 12),

        // 4. CAMPIONAMENTO E BILANCIO
        _buildM904SectionTitle('4. CAMPIONAMENTO E BILANCI DI MASSA'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: _buildM904InfoBox(
                'CAMPIONAMENTO',
                samples.isNotEmpty
                    ? 'Eseguiti ${samples.length} prelievi\n(${samples.map((s) => s.matrixType).join(", ")})'
                    : 'Nessun campionamento eseguito',
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 2,
              child: _buildM904MassBalanceTable(massBalance),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // 5. ESITO E CONCLUSIONI
        _buildM904SectionTitle('5. ESITO DELLA VERIFICA E CONCLUSIONI'),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: outcome.isEsitoFavorevole
                ? PdfColor.fromInt(0xFFE8F5E9)
                : PdfColor.fromInt(0xFFFFEBEE),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(
              color: outcome.isEsitoFavorevole
                  ? PdfColors.green200
                  : PdfColors.red200,
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ESITO GLOBALE:',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    outcome.isEsitoFavorevole
                        ? 'CONFORME / FAVOREVOLE'
                        : 'NON CONFORME / NON FAVOREVOLE',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: outcome.isEsitoFavorevole
                          ? PdfColors.green800
                          : PdfColors.red800,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Punteggio Op:',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '${outcome.sumOperatoreTotale}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Spacer(),
        _buildM904Footer(),
      ],
    );
  }

  @override
  pw.Widget buildM904SecondPage({
    required Visit visit,
    required VisitCompany? company,
    required VisitPreviousNcManagement? prevNc,
    required List<VisitAttachment> attachments,
    pw.MemoryImage? logoBios,
  }) {
    final referenceDocs = attachments.where((a) => a.category == 'reference');
    final viewedDocs = attachments.where((a) => a.category == 'viewed');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MODULO M904 - Pagina 2',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: style.primaryColor,
              ),
            ),
            if (logoBios != null) pw.Image(logoBios, height: 25),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: style.accentColor, thickness: 1),
        pw.SizedBox(height: 15),

        // 7. DOCUMENTI DI RIFERIMENTO
        _buildM904SectionTitle('7. DOCUMENTI DI RIFERIMENTO UTILIZZATI'),
        _buildM904DocBox([
          _buildM904DocCheckItem(
            'Disciplinare/i Regionale di Difesa Integrata adottati dall\'azienda (rev.08)',
            referenceDocs.any((a) => a.attachmentType == 'DISCIPLINARE'),
            extra: referenceDocs
                .where((a) => a.attachmentType == 'DISCIPLINARE')
                .map((a) => a.extraValue)
                .join(', '),
            extraLabel: 'Regione e anno: ',
          ),
          _buildM904DocCheckItem(
            'Linee Guida Nazionali di Difesa Integrata (anno):',
            referenceDocs.any((a) => a.attachmentType == 'LINEE_GUIDA'),
            extra: referenceDocs
                .where((a) => a.attachmentType == 'LINEE_GUIDA')
                .map((a) => a.extraValue)
                .join(', '),
          ),
          _buildM904DocCheckItem(
            'Checklist di Controllo (revisione applicabile) - Allegato ad uso interno Bios (rev.08)',
            referenceDocs.any((a) => a.attachmentType == 'CHECKLIST'),
          ),
          _buildM904DocCheckItem(
            'Altro (specificare):',
            referenceDocs.any((a) => a.attachmentType == 'ALTRO'),
            extra: referenceDocs
                .where((a) => a.attachmentType == 'ALTRO')
                .map((a) => a.extraValue)
                .join(', '),
          ),
        ]),
        pw.SizedBox(height: 15),

        // 8. DOCUMENTI VISIONATI
        _buildM904SectionTitle('8. DOCUMENTI VISIONATI'),
        _buildM904DocBox([
          _buildM904DocCheckItem(
            'REGISTRO AZIENDALE SQNPI (Quaderni di campagna, Registro operazioni colturali e magazzino)',
            viewedDocs.any((a) => a.attachmentType == 'REGISTRO_SQNPI'),
          ),
          _buildM904DocCheckItem(
            'Evidenza autocontrollo interno',
            viewedDocs.any((a) => a.attachmentType == 'AUTOCONTROLLO'),
          ),
          _buildM904DocCheckItem(
            'Rapporto dell\'audit Bios precedente (se applicabile)',
            viewedDocs.any((a) => a.attachmentType == 'AUDIT_PRECEDENTE'),
          ),
          _buildM904DocCheckItem(
            'Esito di certificazione e NC emesse da altro Odc (se applicabile)',
            viewedDocs.any((a) => a.attachmentType == 'ESITO_ALTRO_ODC'),
          ),
          _buildM904DocCheckItem(
            'Altro (obbligatorio specificare):',
            viewedDocs.any((a) => a.attachmentType == 'ALTRO'),
            extra: viewedDocs
                .where((a) => a.attachmentType == 'ALTRO')
                .map((a) => a.extraValue)
                .join(', '),
          ),
        ]),
        pw.SizedBox(height: 15),

        // 9. GESTIONE NON CONFORMITÀ
        _buildM904SectionTitle(
          '9. GESTIONE NON CONFORMITÀ E AZIONI CORRETTIVE',
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                color: PdfColors.grey100,
                child: pw.Text(
                  'NOTA: Per gli operatori certificati da altri Odc nei due anni precedenti l\'entrata in Bios, è obbligatorio verificare eventuali NC e i provvedimenti emessi.',
                  style: pw.TextStyle(
                    fontSize: 6.5,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey400,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Le N/C rilevate nel corso della precedente visita risultano:',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _buildM904CheckboxItem(
                            'Risolte',
                            prevNc?.prevNcResults == 1,
                          ),
                          _buildM904CheckboxItem(
                            'Non risolte',
                            prevNc?.prevNcResults == 2,
                          ),
                          _buildM904CheckboxItem(
                            'Non applicabile (niente NC aperte)',
                            prevNc?.prevNcResults == 0,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Specificare quali requisiti risultano ancora N/C:',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                          pw.Text(
                            prevNc?.prevNcRequirementsStillKO ?? '-',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
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
                            'Le azioni correttive risultano coerenti:',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _buildM904CheckboxItem(
                            'Sì',
                            prevNc?.prevCorrectiveActionsCoherent == 1,
                          ),
                          _buildM904CheckboxItem(
                            'No',
                            prevNc?.prevCorrectiveActionsCoherent == 2,
                          ),
                          _buildM904CheckboxItem(
                            'N/A',
                            prevNc?.prevCorrectiveActionsCoherent == 0,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Se "No" specificare:',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                          pw.Text(
                            prevNc?.prevCorrectiveActionsDetails ?? '-',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // 10. DETTAGLI PRECEDENTE SORVEGLIANZA
        _buildM904SectionTitle(
          '10. DETTAGLI PRECEDENTE ATTIVITÀ DI SORVEGLIANZA',
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _buildM904DocCheckItem(
                'L\'Organizzazione è certificata il: ',
                prevNc?.prevOrgCertifiedDate != null &&
                    prevNc!.prevOrgCertifiedDate.isNotEmpty,
                extra: prevNc?.prevOrgCertifiedDate ?? '-',
              ),
              _buildM904DocCheckItem(
                'L\'Organizzazione è stata sanzionata il: ',
                prevNc?.prevOrgSanctionedDate != null &&
                    prevNc!.prevOrgSanctionedDate.isNotEmpty,
                extra: prevNc?.prevOrgSanctionedDate ?? '-',
              ),
            ],
          ),
        ),

        pw.Spacer(),
        _buildM904Footer(),
      ],
    );
  }

  @override
  pw.Widget buildM904ThirdPage({
    required Visit visit,
    required VisitCompany? company,
    required VisitClosing? closing,
    required List<VisitSignature> signatures,
    required Map<String, pw.MemoryImage> signatureImages,
    pw.MemoryImage? logoBios,
  }) {
    // Parsing inspection methods (assuming they are stored as comma-separated or similar)
    // For now we'll check common ones in the text
    final methods = closing?.inspectionMethods ?? '';
    final hasVisual = methods.contains('VISIVA');
    final hasDocumental = methods.contains('DOCUMENTALE');
    final hasInterview = methods.contains('COLLOQUI');
    final hasSampling = methods.contains('CAMPIONAMENTO');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MODULO M904 - Pagina 3',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: style.primaryColor,
              ),
            ),
            if (logoBios != null) pw.Image(logoBios, height: 25),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: style.accentColor, thickness: 1),
        pw.SizedBox(height: 15),

        // 11. METODI DI VERIFICA
        _buildM904SectionTitle('11. METODI DI VERIFICA APPLICATI'),
        _buildM904DocBox([
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildM904CheckboxItem('Esame visivo', hasVisual),
              ),
              pw.Expanded(
                child: _buildM904CheckboxItem(
                  'Esame documentale',
                  hasDocumental || methods.isEmpty,
                ),
              ), // Default to true if empty for safety
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildM904CheckboxItem(
                  'Colloqui con personale',
                  hasInterview,
                ),
              ),
              pw.Expanded(
                child: _buildM904CheckboxItem('Campionamento', hasSampling),
              ),
            ],
          ),
        ]),
        pw.SizedBox(height: 15),

        // 12. OSSERVAZIONI DELL'ISPETTORE
        _buildM904SectionTitle(
          '12. OSSERVAZIONI DELL\'ISPETTORE (se applicabile)',
        ),
        pw.Container(
          width: double.infinity,
          constraints: const pw.BoxConstraints(minHeight: 80),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Text(
            closing?.verificationNotes ??
                'Nessuna osservazione particolare rilevata durante la visita.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.SizedBox(height: 15),

        // 13. DICHIARAZIONI DEL RAPPRESENTANTE
        _buildM904SectionTitle(
          '13. OSSERVAZIONI/RISERVE DEL RAPPRESENTANTE AZIENDALE',
        ),
        pw.Container(
          width: double.infinity,
          constraints: const pw.BoxConstraints(minHeight: 60),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Text(
            closing?.representativeReservations ??
                'Il Rappresentante dichiara di non avere riserve in merito alla conduzione della visita ispettiva.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.SizedBox(height: 15),

        // 14. VALUTAZIONE FINALE
        _buildM904SectionTitle('14. VALUTAZIONE FINALE'),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            children: [
              _buildM904CheckboxItem(
                'Favorevole (conforme ai requisiti)',
                closing?.finalOutcome == 1 || closing?.finalOutcome == 0,
              ),
              pw.SizedBox(height: 4),
              _buildM904CheckboxItem(
                'Non Favorevole (proposta di provvedimento)',
                closing?.finalOutcome == 2,
              ),
              if (closing?.finalOutcome == 2) ...[
                pw.SizedBox(height: 4),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20),
                  child: pw.Text(
                    'Motivazione: ${closing?.provisionDetail ?? "-"}',
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.red800),
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // 15. FIRME
        _buildM904SectionTitle('15. SOTTOSCRIZIONE DEL RAPPORTO'),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            // Inspector Signature
            pw.Column(
              children: [
                pw.Text(
                  'L\'ISPETTORE BIOS',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (signatureImages['inspector'] != null)
                  pw.Image(signatureImages['inspector']!, height: 60)
                else
                  pw.Container(
                    height: 60,
                    width: 120,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  visit.inspectorName.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
            // Representative Signature
            pw.Column(
              children: [
                pw.Text(
                  'IL RAPPRESENTANTE AZIENDALE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (signatureImages['representative'] != null)
                  pw.Image(signatureImages['representative']!, height: 60)
                else
                  pw.Container(
                    height: 60,
                    width: 120,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  visit.representativeName.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ],
        ),

        pw.Spacer(),
        _buildM904Footer(),
      ],
    );
  }

  pw.Widget _buildM904Footer() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            _buildFooterCell('M904', 'Documento'),
            _buildFooterCell('08', 'Revisione n.'),
            _buildFooterCell('15/04/2024', 'Data'),
            _buildFooterCell('C. Fabris\nF. Dal Corobbo', 'Redazione'),
            _buildFooterCell('RAQ', 'Verifica'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooterCell(String text, String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            text,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildM904DocBox(List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(children: children),
    );
  }

  pw.Widget _buildM904DocCheckItem(
    String label,
    bool isChecked, {
    String? extra,
    String? extraLabel,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          _buildM904Checkbox(isChecked),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: label,
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  if (extra != null && extra.isNotEmpty)
                    pw.TextSpan(
                      text: ' ${extraLabel ?? ""}$extra',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildM904CheckboxItem(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          _buildM904Checkbox(checked),
          pw.SizedBox(width: 6),
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
        ],
      ),
    );
  }

  pw.Widget _buildM904Checkbox(bool checked) {
    return pw.Container(
      width: 10,
      height: 10,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.7),
      ),
      child: checked
          ? pw.Center(
              child: pw.Text(
                'X',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  pw.Widget _buildM904SectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, left: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: style.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _buildM904Row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildM904InfoBox(String title, String content) {
    return pw.Container(
      height: 60,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: style.secondaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(content, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
    );
  }

  pw.Widget _buildVerticalHeader(String text) {
    return pw.Container(
      height: 60,
      width: 25,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: 1.5708, // 90 degrees in radians
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildM904TableCheckbox(String label, bool isChecked) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 6,
          height: 6,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 0.5),
          ),
          child: isChecked
              ? pw.Center(
                  child: pw.Container(
                    width: 3.5,
                    height: 3.5,
                    color: PdfColors.black,
                  ),
                )
              : null,
        ),
        pw.SizedBox(width: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 5)),
      ],
    );
  }

  pw.Widget _buildM904DetailedUecTable(List<VisitUec> uecs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25), // Aggregato
        1: const pw.FlexColumnWidth(1.2), // Prodotto in domanda
        2: const pw.FlexColumnWidth(1.2), // Prodotto riscontrato
        3: const pw.FixedColumnWidth(22), // Coerenza SQNPI
        4: const pw.FixedColumnWidth(22), // Conformità SQNPI
        5: const pw.FixedColumnWidth(55), // Campionamento / Lotto
        6: const pw.FixedColumnWidth(22), // Tracciabilità
        7: const pw.FixedColumnWidth(22), // Reclami
        8: const pw.FixedColumnWidth(22), // Processo campo
        9: const pw.FlexColumnWidth(1.5), // Note
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: style.secondaryColor),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(
                child: pw.Text(
                  'Aggregato\n(n.)',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(
                child: pw.Text(
                  'Prodotto in\ndomanda',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(
                child: pw.Text(
                  'Prodotto riscontrato\nin ispezione',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            _buildVerticalHeader('Coerenza SQNPI'),
            _buildVerticalHeader('Conformità SQNPI'),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(
                child: pw.Text(
                  'Campionamento\nSe sì, lotto:',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            _buildVerticalHeader('Tracciabilità'),
            _buildVerticalHeader('Reclami'),
            _buildVerticalHeader('Processo Campo'),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Center(
                child: pw.Text(
                  'Note /\nFase Coltivazione',
                  style: pw.TextStyle(
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        // Data rows (limited to 10 for page 1 to avoid overflow)
        ...uecs.take(10).map((uec) {
          final consistency = uec.sqnpiConsistency.toLowerCase();
          final compliance = uec.sqnpiCompliance.toLowerCase();

          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Center(
                  child: pw.Text(
                    uec.nAggregato.isNotEmpty ? uec.nAggregato : uec.id,
                    style: const pw.TextStyle(fontSize: 6),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  uec.coltura,
                  style: const pw.TextStyle(fontSize: 6),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  uec.foundProduct ?? uec.coltura,
                  style: const pw.TextStyle(fontSize: 6),
                ),
              ),
              // Coerenza
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 1,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildM904TableCheckbox('S', consistency == 'si'),
                    pw.SizedBox(height: 1),
                    _buildM904TableCheckbox('N', consistency == 'no'),
                    pw.SizedBox(height: 1),
                    _buildM904TableCheckbox(
                      'A',
                      consistency == 'na' || consistency == 'n/a',
                    ),
                  ],
                ),
              ),
              // Conformità
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 1,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildM904TableCheckbox('S', compliance == 'si'),
                    pw.SizedBox(height: 1),
                    _buildM904TableCheckbox('N', compliance == 'no'),
                    pw.SizedBox(height: 1),
                    _buildM904TableCheckbox(
                      'A',
                      compliance == 'na' || compliance == 'n/a',
                    ),
                  ],
                ),
              ),
              // Campionamento
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        _buildM904TableCheckbox('Sì', uec.hasSampling),
                        pw.SizedBox(width: 4),
                        _buildM904TableCheckbox('No', !uec.hasSampling),
                      ],
                    ),
                    if (uec.hasSampling && uec.samplingLotId != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(
                          'Lt: ${uec.samplingLotId}',
                          style: pw.TextStyle(
                            fontSize: 5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Tracciabilità
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 1,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildM904TableCheckbox('S', uec.isTraceable),
                    pw.SizedBox(height: 3),
                    _buildM904TableCheckbox('N', !uec.isTraceable),
                  ],
                ),
              ),
              // Reclami
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 1,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildM904TableCheckbox('S', uec.hasClaims),
                    pw.SizedBox(height: 3),
                    _buildM904TableCheckbox('N', !uec.hasClaims),
                  ],
                ),
              ),
              // Processo Campo
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 1,
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildM904TableCheckbox('S', uec.isFieldProcessVerified),
                    pw.SizedBox(height: 3),
                    _buildM904TableCheckbox('N', !uec.isFieldProcessVerified),
                  ],
                ),
              ),
              // Note / Fase
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  '${uec.note}${uec.fieldProcessDetails != null ? "\nFase: ${uec.fieldProcessDetails}" : ""}',
                  style: const pw.TextStyle(fontSize: 5),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  pw.Widget buildM904CultivationPage({
    required Visit visit,
    required VisitCompany? company,
    required List<VisitUec> uecs,
    pw.MemoryImage? logoBios,
  }) {
    // Group UECs by aggregate number (nAggregato)
    final Map<String, List<VisitUec>> groupedUecs = {};
    for (final uec in uecs) {
      final key = uec.nAggregato.isEmpty ? 'N/A' : uec.nAggregato;
      if (!groupedUecs.containsKey(key)) {
        groupedUecs[key] = [];
      }
      groupedUecs[key]!.add(uec);
    }

    // Sort keys naturally if possible, or just keep order
    final sortedKeys = groupedUecs.keys.toList()..sort();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MODULO M904',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: style.primaryColor,
                  ),
                ),
                pw.Text(
                  'Fase di Coltivazione per Numero Aggregato',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: style.secondaryColor,
                  ),
                ),
              ],
            ),
            if (logoBios != null) pw.Image(logoBios, height: 30),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: style.accentColor, thickness: 1),
        pw.SizedBox(height: 15),

        _buildM904SectionTitle('CONTROLLO IN CAMPO / FASE DI COLTIVAZIONE'),
        pw.SizedBox(height: 5),

        // Table Header
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              _buildM904TableHeaderCell('N. AGGR.', flex: 1),
              _buildM904TableHeaderCell('COLTURA', flex: 2),
              _buildM904TableHeaderCell(
                'FASE DI COLTIVAZIONE VERIFICATA',
                flex: 3,
              ),
              _buildM904TableHeaderCell('ESITO', flex: 1),
            ],
          ),
        ),

        // Table Body
        ...sortedKeys.map((key) {
          final group = groupedUecs[key]!;
          // Unique crops in this aggregate
          final crops = group.map((e) => e.coltura).toSet().join(', ');
          // Verified phase (assuming it's consistent within aggregate or show all)
          final phases = group
              .map((e) => e.fieldProcessDetails ?? '-')
              .where((p) => p != '-')
              .toSet()
              .join('\n');
          final isVerified = group.any((e) => e.isFieldProcessVerified);

          return pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildM904TableCell(key, flex: 1),
                _buildM904TableCell(crops, flex: 2),
                _buildM904TableCell(phases.isEmpty ? '-' : phases, flex: 3),
                _buildM904TableCell(
                  isVerified ? 'Sì' : 'No',
                  flex: 1,
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        }),

        pw.SizedBox(height: 20),
        pw.Text(
          'Note: Il presente controllo si riferisce alla conformità dei processi produttivi verificati in campo durante la visita ispettiva, in accordo con i Piani di Controllo SQNPI.',
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  pw.Widget buildM904PostHarvestPage({
    required Visit visit,
    required VisitCompany? company,
    required PostHarvestRecord? postHarvest,
    pw.MemoryImage? logoBios,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MODULO M904',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: style.primaryColor,
                  ),
                ),
                pw.Text(
                  'Fase di Post-Raccolta / Trasformazione',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: style.secondaryColor,
                  ),
                ),
              ],
            ),
            if (logoBios != null) pw.Image(logoBios, height: 30),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: style.accentColor, thickness: 1),
        pw.SizedBox(height: 15),

        _buildM904SectionTitle('CONTROLLO POST-RACCOLTA (MARCHIO)'),
        pw.SizedBox(height: 5),

        // 1. Post-Harvest Phases Table
        pw.Text(
          '1. FASI DI POST-RACCOLTA APPLICATE',
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        _buildM904PostHarvestPhasesTable(postHarvest),
        pw.SizedBox(height: 15),

        // 2. Post-Harvest Mass Balance
        pw.Text(
          '2. BILANCIO DI MASSA POST-RACCOLTA (tenuto conto delle giacenze)',
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        _buildM904PostHarvestMassBalanceGrid(postHarvest),
        pw.SizedBox(height: 15),

        // 3. Traceability Proof
        pw.Text(
          '3. PROVA DI RINTRACCIABILITÀ POST-RACCOLTA',
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Prodotti verificati per la rintracciabilità:',
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                postHarvest?.traceabilityVerifiedProducts.isNotEmpty == true
                    ? postHarvest!.traceabilityVerifiedProducts
                    : '-',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        ),

        pw.Spacer(),
        pw.Text(
          'Note: Le verifiche di post-raccolta si applicano esclusivamente alle aziende che richiedono la concessione d\'uso del marchio SQNPI.',
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildM904PostHarvestPhasesTable(PostHarvestRecord? record) {
    List<dynamic> phases = [];
    if (record != null) {
      try {
        phases = jsonDecode(record.phases);
      } catch (_) {}
    }

    if (phases.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        ),
        child: pw.Center(
          child: pw.Text(
            'NESSUNA FASE DICHIARATA',
            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.TableHelper.fromTextArray(
        headers: ['FASE', 'GESTIONE', 'PRODOTTO', 'CONF. SQNPI', 'TRACCIAB.'],
        headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 6),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
        },
        data: phases.map((p) {
          final Map<String, dynamic> map = p as Map<String, dynamic>;
          String gestione = '';
          if (map['inProprio'] == true) gestione = 'In proprio';
          if (map['terzista'] == true) {
            gestione = 'Terzista';
            final cert = map['certificatoTerzista'] ?? '';
            if (cert.isNotEmpty) gestione += ' ($cert)';
          }
          return [
            map['fase'] ?? '-',
            gestione,
            map['prodotto'] ?? '-',
            map['conforme'] == true ? 'SÌ' : 'NO',
            map['rintracciabile'] == true ? 'SÌ' : 'NO',
          ];
        }).toList(),
      ),
    );
  }

  pw.Widget _buildM904PostHarvestMassBalanceGrid(PostHarvestRecord? record) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        children: [
          // Row 1: Products
          _buildM904MassBalanceRow(
            'Prodotti oggetto di verifica:',
            record?.mbVerifiedProducts ?? '',
          ),
          // Row 2: Input/Output Split
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Expanded(
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      _buildM904MassBalanceCell(
                        'Dati in ingresso (Materie prime/Semilavorati):',
                        record?.mbInputData ?? '',
                        hasBottomBorder: true,
                      ),
                      _buildM904MassBalanceCell(
                        'Documenti di riferimento:',
                        record?.mbInputDocs ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      _buildM904MassBalanceCell(
                        'Dati in uscita (Prodotti finiti):',
                        record?.mbOutputData ?? '',
                        hasBottomBorder: true,
                      ),
                      _buildM904MassBalanceCell(
                        'Documenti di riferimento:',
                        record?.mbOutputDocs ?? '',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Comment Row
          if (record?.mbComment.isNotEmpty == true)
            _buildM904MassBalanceRow(
              'Commento / Note sul bilancio:',
              record!.mbComment,
              topBorder: true,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildM904MassBalanceRow(
    String label,
    String value, {
    bool topBorder = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: topBorder
          ? const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            )
          : null,
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: value.isNotEmpty ? value : '-',
              style: const pw.TextStyle(fontSize: 6),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildM904TableHeaderCell(String text, {required int flex}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  pw.Widget _buildM904TableCell(
    String text, {
    required int flex,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 7),
          textAlign: textAlign,
        ),
      ),
    );
  }

  pw.Widget _buildM904MassBalanceTable(MassBalanceRecord? massBalance) {
    if (massBalance == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Center(
          child: pw.Text(
            'BILANCIO DI MASSA NON APPLICABILE',
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DIFESA E CONTROLLO DELLE INFESTANTI: punto 1.4 LGNPC',
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Bilancio di massa tenuto conto anche delle scorte di magazzino sia di prodotti fitosanitari che di diserbanti di libera vendita e regolarmente registrati',
          style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Subsection Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 4,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                child: pw.Text(
                  '1. BILANCIO DI MASSA (spazio per l\'evidenza di un bilancio di massa)',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              // Verified Products Row
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Prodotti verificati: ',
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TextSpan(
                        text: massBalance.verifiedProducts ?? '-',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),
                ),
              ),
              // Ingress / Egress Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // INGRESS COLUMN
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.grey400,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildM904MassBalanceCell(
                            'Dati in ingresso:',
                            massBalance.ingressData,
                            hasBottomBorder: true,
                          ),
                          _buildM904MassBalanceCell(
                            'Documenti di riferimento:',
                            massBalance.ingressDocs,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // EGRESS COLUMN
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildM904MassBalanceCell(
                          'Dati in uscita:',
                          massBalance.egressData,
                          hasBottomBorder: true,
                        ),
                        _buildM904MassBalanceCell(
                          'Documenti di riferimento:',
                          massBalance.egressDocs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Comment Row
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Commento:',
                      style: pw.TextStyle(
                        fontSize: 5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      massBalance.comment ?? '-',
                      style: const pw.TextStyle(fontSize: 6),
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

  pw.Widget _buildM904MassBalanceCell(
    String label,
    String? value, {
    bool hasBottomBorder = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: hasBottomBorder
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            )
          : null,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 1),
          pw.Text(value ?? '-', style: const pw.TextStyle(fontSize: 6)),
        ],
      ),
    );
  }

  @override
  pw.Widget buildSummary(VisitOutcomeSummary outcome, Visit visit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('1. Riepilogo ed Esito Ispezione'),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.grey50,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPremiumScoreIndicator(
                'PUNTEGGIO OP.',
                '${outcome.sumOperatoreTotale}',
                style.primaryColor,
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              _buildPremiumScoreIndicator(
                'UEC OLTRE SOGLIA',
                '${outcome.uecOverSoglia}',
                style.secondaryColor,
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              pw.Column(
                children: [
                  pw.Text(
                    'ESITO GLOBALE',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: outcome.isEsitoFavorevole
                          ? PdfColors.green700
                          : PdfColors.red700,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      outcome.isEsitoFavorevole
                          ? 'FAVOREVOLE'
                          : 'NON FAVOREVOLE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (visit.durationHours > visit.plannedDurationHours &&
            visit.durationJustification.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.orange200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'GIUSTIFICATIVO SFORAMENTO ORE: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.Text(
                      '${visit.durationHours}h vs ${visit.plannedDurationHours}h programmate',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.orange700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  visit.durationJustification,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  pw.Widget buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Dettaglio Requisiti e Non Conformità',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        if (ncs.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Nessuna Non Conformità rilevata durante l\'ispezione.',
              style: pw.TextStyle(
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: [
              'Codice',
              'UEC / Coltura',
              'Descrizione NC',
              'Azione Correttiva Richiesta',
            ],
            data: ncs
                .map(
                  (nc) => [
                    nc.item.displayCode,
                    nc.uec.nAggregato.isNotEmpty
                        ? '${nc.uec.nAggregato} (${nc.uec.coltura})'
                        : nc.uec.id,
                    nc.item.obbligo,
                    nc.response.rilievoNc,
                  ],
                )
                .toList(),
            columnWidths: const {
              0: pw.FixedColumnWidth(60),
              1: pw.FixedColumnWidth(100),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(2),
            },
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: style.secondaryColor),
            cellAlignment: pw.Alignment.topLeft,
            cellPadding: const pw.EdgeInsets.all(8),
            cellStyle: pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
            oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
          ),
      ],
    );
  }

  @override
  pw.Widget buildM904Summary(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('5. Non Conformità Rilevate'),
        pw.Text(
          'Riepilogo Attività (M904)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.TableHelper.fromTextArray(
          headers: ['Codice', 'Gravità', 'Descrizione / Azione corr.'],
          data: ncs.map((nc) {
            String note = nc.response.rilievoNc;
            // Note obbligatorie automatiche
            if (nc.item.code == '0.1' ||
                nc.item.code == '0.11' ||
                nc.item.code == '1.1') {
              if (nc.item.hasEsclusioneLotto) {
                note = '[NC GRAVE - ESCLUSIONE LOTTO/UEC] $note';
              }
            }

            return [
              nc.item.displayCode,
              nc.response.livelloKo?.toString() ?? 'N/D',
              note,
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: style.secondaryColor),
          cellStyle: const pw.TextStyle(fontSize: 9),
          oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey50),
        ),
      ],
    );
  }

  @override
  pw.Widget buildAttachmentsSection(
    List<VisitAttachment> attachments,
    Map<String, pw.MemoryImage> images,
  ) {
    if (attachments.isEmpty) return pw.SizedBox.shrink();

    // Filtra documenti speciali
    final references = attachments
        .where((a) => a.category == 'reference')
        .toList();
    final viewed = attachments.where((a) => a.category == 'viewed').toList();
    final general = attachments
        .where((a) => a.category != 'reference' && a.category != 'viewed')
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (references.isNotEmpty || viewed.isNotEmpty) ...[
          buildSectionHeader('7. Documentazione Ufficiale (Rev. 08)'),
          if (references.isNotEmpty) ...[
            pw.Text(
              'Documenti di riferimento utilizzati:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 5),
            // Se la checklist non è tra gli allegati fisici, la aggiungiamo virtualmente
            if (!references.any(
              (a) => a.attachmentType == 'CHECKLIST_CONTROL_REV',
            ))
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Expanded(
                      child: pw.Text(
                        'Checklist di Controllo (Compilata digitalmente in-App)',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),
            ...references.map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            a.attachmentType == 'CHECKLIST_CONTROL_REV'
                                ? '${a.caption} (Compilata digitalmente in-App)'
                                : a.caption,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          if (a.extraValue.isNotEmpty)
                            pw.Text(
                              'Dettagli: ${a.extraValue}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          if (viewed.isNotEmpty) ...[
            pw.Text(
              'Documenti visionati:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 5),
            ...viewed.map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            a.caption,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          if (a.extraValue.isNotEmpty)
                            pw.Text(
                              'Dettagli: ${a.extraValue}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 15),
          ],
        ],

        if (general.isNotEmpty) ...[
          buildSectionHeader(
            references.isNotEmpty || viewed.isNotEmpty
                ? 'Allegati Fotografici e Documentali Extra'
                : '7. Allegati Fotografici',
          ),
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: general.map((att) {
              final image = images[att.id];

              return pw.Container(
                width: 160,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Container(
                        height: 120,
                        color: PdfColors.grey100,
                        child: image != null
                            ? pw.Image(image, fit: pw.BoxFit.cover)
                            : pw.Center(
                                child: pw.Text(
                                  'Immagine non\ndisponibile',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey400,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(6),
                          bottomRight: pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            att.caption.isNotEmpty ? att.caption : 'Allegato',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: style.secondaryColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                          ),
                          if (att.latitude != null) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'GPS: ${att.latitude!.toStringAsFixed(4)}, ${att.longitude!.toStringAsFixed(4)}',
                              style: const pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.blue700,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  pw.Widget buildMassBalanceSection(MassBalanceRecord? record) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('4. Bilancio di Massa'),
        if (record == null)
          _buildEmptyPlaceholder('Bilancio di massa non compilato.')
        else
          pw.TableHelper.fromTextArray(
            headers: [
              'Sostanze Attive',
              'Acquistato',
              'Utilizzato',
              'Giacenza',
              'Scostamento',
              'Documenti',
            ],
            data: [
              [
                record.substances,
                '${record.purchased} kg/l',
                '${record.used} kg/l',
                '${record.stock} kg/l',
                '${record.discrepancy.toStringAsFixed(2)}%',
                record.referenceDocuments,
              ],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: style.primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
      ],
    );
  }

  @override
  pw.Widget buildClosingSection(VisitClosing? closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('6. Conclusione Ispezione'),
        if (closing == null)
          _buildEmptyPlaceholder(
            'Dati di chiusura ispezione non ancora inseriti.',
          )
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'STATO CHIUSURA: ',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: style.secondaryColor,
                                ),
                              ),
                              pw.TextSpan(
                                text: closing.isClosed ? 'CHIUSA' : 'APERTA',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: closing.isClosed
                                      ? PdfColors.green700
                                      : PdfColors.red700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (closing.resolutionDeadline != null)
                          pw.Text(
                            'Scadenza rettifica: ${closing.resolutionDeadline!.day}/${closing.resolutionDeadline!.month}/${closing.resolutionDeadline!.year}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'INTEGRAZIONE AMMINISTRATIVA (M904 Rev. 08):',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: style.primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildComplianceRow(
                      'Rispetto requisiti Cap. 5',
                      closing.cap5Adherence == 0
                          ? 'N/A'
                          : (closing.cap5Adherence == 1
                                ? 'SÌ per tutte le colture'
                                : 'NO (${closing.cap5SpecificCrops})'),
                    ),
                    _buildComplianceRow(
                      'Impegno a rettificare NC',
                      closing.commitmentToRectify == 0
                          ? 'N/A'
                          : (closing.commitmentToRectify == 1 ? 'SÌ' : 'NO'),
                    ),
                    _buildComplianceRow(
                      'Metodologia ispezione',
                      closing.inspectionMethods
                          .replaceAll('[', '')
                          .replaceAll(']', '')
                          .replaceAll('"', '')
                          .replaceAll(',', ', '),
                    ),
                    _buildComplianceRow(
                      'Presenza titolare/rappresentante',
                      closing.representativePresent == 0
                          ? 'N/A'
                          : (closing.representativePresent == 1 ? 'SÌ' : 'NO'),
                    ),
                    _buildComplianceRow(
                      'Esito formalizzato all\'azienda',
                      closing.isOutcomeFormalized ? 'SÌ' : 'NO',
                    ),
                    if (closing.verificationNotes.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Note di verifica:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                          color: style.secondaryColor,
                        ),
                      ),
                      pw.Text(
                        closing.verificationNotes,
                        style: const pw.TextStyle(fontSize: 9, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Valutazione Finale (Official Layout)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'VALUTAZIONE FINALE',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'In riferimento al campo di applicazione dell\'attività di verifica ispettiva',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                          pw.Text(
                            'Ritenuto quanto valutato rappresentativo delle attività effettuate dall\'Organizzazione',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        'Si ritiene l\'Organizzazione:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // Option 1
                    _buildOutcomeBox(
                      'CONFORME - per i prodotti indicati (vedi sezione dettaglio prodotti e attività)',
                      closing.finalOutcome == 1,
                    ),
                    pw.SizedBox(height: 8),

                    // Option 2
                    _buildOutcomeBox(
                      'PROPOSTA PROVVEDIMENTO secondo la procedura di adesione, gestione e controllo nell\'ambito SQNPI applicabile (esclusione lotto, sospensione del processo di certificazione aziendale, esclusione azienda),',
                      closing.finalOutcome == 2,
                      subtext:
                          (closing.finalOutcome == 2 &&
                              closing.provisionDetail.isNotEmpty)
                          ? 'PROVVEDIMENTO: ${closing.provisionDetail}'
                          : null,
                    ),

                    pw.SizedBox(height: 12),
                    pw.Center(
                      child: pw.Text(
                        'allo Standard di certificazione SQNPI',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              if (closing.representativeReservations.isNotEmpty) ...[
                pw.Text(
                  'Eventuali riserve (da parte del responsabile dell\'Organizzazione)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                    color: PdfColors.white,
                  ),
                  child: pw.Text(
                    closing.representativeReservations,
                    style: const pw.TextStyle(fontSize: 9, height: 1.3),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Text(
                'Azioni Correttive Richieste:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: style.primaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                closing.correctiveActions.isNotEmpty
                    ? closing.correctiveActions
                    : 'Nessuna azione richiesta.',
                style: const pw.TextStyle(fontSize: 9, height: 1.3),
              ),
            ],
          ),
      ],
    );
  }

  @override
  pw.Widget buildAziendaCompliance(Visit visit, VisitCompany? company) {
    if (company == null) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('2. Dati Aziendali e Compliance (M904)'),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Partita IVA',
                  company.partitaIva.isEmpty ? 'N/D' : company.partitaIva,
                ),
                _buildComplianceRow(
                  'Nuovo Operatore?',
                  company.isNewOperator ? 'SÌ' : 'NO',
                ),
              ),
              _buildDivider(),
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Coordinate GPS',
                  '${company.latitudeText}, ${company.longitudeText}',
                ),
                pw.SizedBox(),
              ),
              _buildDivider(),
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Rappresentante',
                  company.referente.isEmpty ? 'N/D' : company.referente,
                ),
                _buildComplianceRow(
                  'Telefono',
                  company.telefono.isEmpty ? 'N/D' : company.telefono,
                ),
              ),
              _buildDivider(),
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Email',
                  company.email.isEmpty ? 'N/D' : company.email,
                ),
                _buildComplianceRow(
                  'PEC',
                  company.pec.isEmpty ? 'N/D' : company.pec,
                ),
              ),
              _buildDivider(),
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Verifica SI',
                  company.siVerification ? 'SÌ' : 'NO',
                ),
                _buildComplianceRow(
                  'Visita Congiunta',
                  company.isJointVisit ? 'SÌ' : 'NO',
                ),
              ),
              if (company.isNewOperator) ...[
                _buildDivider(),
                _buildTwoColumnRow(
                  _buildComplianceRow(
                    'OdC Precedente',
                    company.previousOdcName.isEmpty
                        ? 'N/D'
                        : company.previousOdcName,
                  ),
                  _buildComplianceRow(
                    'Esiti Prec.',
                    company.previousOdcOutcomes.isEmpty
                        ? 'N/D'
                        : company.previousOdcOutcomes,
                  ),
                ),
              ],
              _buildDivider(),
              _buildComplianceRow(
                'Sito Manipolazione',
                company.manipulationSiteAddress.isEmpty
                    ? 'N/D'
                    : company.manipulationSiteAddress,
              ),
              if (company.isJointVisit) ...[
                _buildDivider(),
                _buildComplianceRow(
                  'Dettagli Visita Congiunta',
                  company.jointVisitDetails,
                ),
              ],
              _buildDivider(),
              _buildComplianceRow(
                'Periodo Picco Raccolta',
                company.peakPeriodFrom.isEmpty ? 'N/D' : company.peakPeriodFrom,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        _buildSoggettiPresenti(visit),
      ],
    );
  }

  pw.Widget _buildDivider() => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Divider(color: PdfColors.grey100, thickness: 0.5),
  );

  pw.Widget _buildTwoColumnRow(pw.Widget left, pw.Widget right) {
    return pw.Row(
      children: [
        pw.Expanded(child: left),
        pw.SizedBox(width: 20),
        pw.Expanded(child: right),
      ],
    );
  }

  pw.Widget _buildSoggettiPresenti(Visit visit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Soggetti Presenti all\'Ispezione',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: style.secondaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Ispettore RGVI',
                  visit.inspectorName.isEmpty ? 'N/D' : visit.inspectorName,
                ),
                _buildComplianceRow(
                  'Affiancatore GVI2',
                  visit.companionName.isEmpty ? 'N/D' : visit.companionName,
                ),
              ),
              _buildDivider(),
              _buildTwoColumnRow(
                _buildComplianceRow(
                  'Rappresentante Legale / Delegato',
                  visit.representativeName.isEmpty
                      ? 'N/D'
                      : visit.representativeName,
                ),
                _buildComplianceRow(
                  'Altri Operatori',
                  visit.otherOperators.isEmpty ? 'N/D' : visit.otherOperators,
                ),
              ),
              if (visit.contactedPersons.isNotEmpty) ...[
                _buildDivider(),
                _buildComplianceRow(
                  'Persone Contattate',
                  visit.contactedPersons,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildComplianceRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: style.secondaryColor,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  @override
  pw.Widget buildUecDetailsSection(
    List<VisitUec> uecs,
    Map<String, List<VisitLot>> lotsPerUec,
  ) {
    if (uecs.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader(
          '3. Quadro di Verifica Colture/ Prodotto in domanda e UEC',
        ),
        pw.TableHelper.fromTextArray(
          headers: [
            'Descrizione / Coltura / Lotti',
            'Esiti SQNPI',
            'Verifiche Processo',
            'Campionamento',
            'Note',
          ],
          data: uecs.map((uec) {
            final lots = lotsPerUec[uec.id] ?? [];
            final lotsTxt = lots.isEmpty
                ? 'Nessun lotto dichiarato'
                : 'Lotti: ${lots.map((l) => l.codice).join(', ')}';

            final uecInfo = [
              if (uec.nAggregato.isNotEmpty) 'Agg. ${uec.nAggregato}',
              uec.descrizione,
              'Coltura: ${uec.coltura}',
              lotsTxt,
            ].join('\n');

            final esitiSqnpi = [
              'Coerenza: ${uec.sqnpiConsistency.isEmpty ? "N/D" : uec.sqnpiConsistency}',
              'Conformità: ${uec.sqnpiCompliance.isEmpty ? "N/D" : uec.sqnpiCompliance}',
            ].join('\n');

            final verificheProcesso = [
              'Tracciab.: ${(uec.isTraceable) ? "SÌ" : "NO"}',
              'Reclami: ${(uec.hasClaims) ? "SÌ" : "NO"}',
              'Proc. Campo: ${(uec.isFieldProcessVerified) ? "SÌ" : "NO"}',
            ].join('\n');

            String samplingTxt = (uec.hasSampling) ? 'SÌ' : 'NO';
            if ((uec.hasSampling) && uec.samplingLotId != null) {
              final samplingLot = lots
                  .where((l) => l.id == uec.samplingLotId)
                  .firstOrNull;
              if (samplingLot != null) {
                samplingTxt += '\n(Lotto: ${samplingLot.codice})';
              }
            }

            return [
              uecInfo,
              esitiSqnpi,
              verificheProcesso,
              samplingTxt,
              uec.note.isEmpty ? '-' : uec.note,
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 8,
          ),
          headerDecoration: pw.BoxDecoration(color: style.primaryColor),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.topLeft,
          cellPadding: const pw.EdgeInsets.all(6),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(2),
          },
        ),
      ],
    );
  }

  @override
  pw.Widget buildSamplingSection(
    List<VisitSample> samples,
    Map<String, pw.MemoryImage> images,
  ) {
    if (samples.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('3c. Registrazioni di Campionamento'),
        ...samples.map((s) {
          final photoPaths = s.photoPaths
              .split(',')
              .where((p) => p.isNotEmpty)
              .toList();

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CAMPIONE: ${s.sampleCode.isNotEmpty ? s.sampleCode : s.id.split("-").last}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: style.primaryColor,
                      ),
                    ),
                    if (s.inspectionDate != null)
                      pw.Text(
                        'Data: ${s.inspectionDate!.day}/${s.inspectionDate!.month}/${s.inspectionDate!.year}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
                pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                pw.SizedBox(height: 8),
                _buildTwoColumnRow(
                  _buildComplianceRow(
                    'Matrice',
                    s.matrixType.isNotEmpty ? s.matrixType : 'N/D',
                  ),
                  _buildComplianceRow(
                    'Numero Sigillo',
                    s.sealNumber.isNotEmpty ? s.sealNumber : 'N/D',
                  ),
                ),
                _buildTwoColumnRow(
                  _buildComplianceRow(
                    'Produttore',
                    s.producerName.isNotEmpty ? s.producerName : 'N/D',
                  ),
                  _buildComplianceRow(
                    'Codice Prod.',
                    s.producerCode.isNotEmpty ? s.producerCode : 'N/D',
                  ),
                ),
                _buildTwoColumnRow(
                  _buildComplianceRow(
                    'Lotto Georeferenziato',
                    s.lotNumberGeoref.isNotEmpty ? s.lotNumberGeoref : 'N/D',
                  ),
                  _buildComplianceRow(
                    'Ispettore',
                    s.inspectorName.isNotEmpty ? s.inspectorName : 'N/D',
                  ),
                ),
                if (photoPaths.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Allegati Fotografici Campionamento:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: style.secondaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: photoPaths.map((path) {
                      final image = images[path];
                      return pw.Container(
                        width: 160,
                        height: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 1,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                          color: PdfColors.white,
                        ),
                        child: image != null
                            ? pw.Image(image, fit: pw.BoxFit.cover)
                            : pw.Center(
                                child: pw.Text(
                                  'Immagine non\ndisponibile',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey400,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  pw.Widget buildSignaturesSection(
    List<VisitSignature> signatures,
    Map<String, pw.MemoryImage> images,
  ) {
    final inspectorSig = signatures
        .where((s) => s.signatureType == 'inspector')
        .firstOrNull;
    final representativeSig = signatures
        .where((s) => s.signatureType == 'representative')
        .firstOrNull;
    final delegateSig = signatures
        .where((s) => s.signatureType == 'delegate')
        .firstOrNull;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('8. Firme e Dichiarazioni'),
        if (signatures.isEmpty)
          _buildEmptyPlaceholder('Nessuna firma acquisita per questo verbale.')
        else
          pw.Column(
            children: [
              pw.Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildSingleSignatureBox(
                    'L\'Ispettore SQNPI',
                    inspectorSig?.signerName ?? 'Ispettore Incaricato',
                    inspectorSig != null ? images[inspectorSig.id] : null,
                  ),
                  _buildSingleSignatureBox(
                    'Il Legale Rappresentante',
                    representativeSig?.signerName ?? 'Titolare',
                    representativeSig != null
                        ? images[representativeSig.id]
                        : null,
                  ),
                  if (delegateSig != null)
                    _buildSingleSignatureBox(
                      'Il Delegato Aziendale',
                      delegateSig.signerName ?? 'Persona delegata',
                      images[delegateSig.id],
                    ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ATTENZIONE: DICHIARAZIONI DEL RESPONSABILE DELL\'AZIENDA (M904 Rev. 08)',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColors.red700,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Il sottoscritto dichiara di aver ricevuto copia del presente verbale e dei relativi allegati. Dichiara inoltre la correttezza dei dati identificativi aziendali e degli impegni assunti in merito alla risoluzione delle Non Conformità rilevate (qualora presenti). Si impegna altresì a non utilizzare il marchio SQNPI su lotti oggetto di sospensione o esclusione come indicato nel presente rapporto.',
                      style: const pw.TextStyle(fontSize: 7, height: 1.3),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Tutela dei dati personali: I dati forniti saranno trattati da Bios srl per le finalità legate all\'iter di certificazione in conformità al Reg. UE 2016/679 (GDPR).',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  pw.Widget buildPostHarvestSection(PostHarvestRecord? record) {
    if (record == null) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('3b. Fase di Post-Raccolta (MARCHIO)'),
        pw.Text(
          'Dettaglio Fasi Post-Raccolta Applicate',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: style.secondaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        _buildPostHarvestPhasesTable(record.phases),
        pw.SizedBox(height: 16),
        pw.Text(
          'Bilancio di Massa Post-Raccolta (Vino/Olio/Altro)',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: style.secondaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              _buildSimpleRow('Prodotti verificati', record.mbVerifiedProducts),
              pw.Divider(color: PdfColors.grey100, thickness: 0.5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildSimpleRow('Input', record.mbInputData),
                  ),
                  pw.Expanded(
                    child: _buildSimpleRow('Doc. Rif.', record.mbInputDocs),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey100, thickness: 0.5),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildSimpleRow('Output', record.mbOutputData),
                  ),
                  pw.Expanded(
                    child: _buildSimpleRow('Doc. Rif.', record.mbOutputDocs),
                  ),
                ],
              ),
              if (record.mbComment.isNotEmpty) ...[
                pw.Divider(color: PdfColors.grey100, thickness: 0.5),
                _buildSimpleRow('Commento', record.mbComment),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Prova di Rintracciabilità Post-Raccolta',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: style.secondaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            color: PdfColors.grey50,
          ),
          child: _buildSimpleRow(
            'Prodotti',
            record.traceabilityVerifiedProducts,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPostHarvestPhasesTable(String phasesJson) {
    List<dynamic> phases = [];
    try {
      phases = jsonDecode(phasesJson);
    } catch (_) {}

    if (phases.isEmpty) {
      return _buildEmptyPlaceholder('Nessuna fase dichiarata');
    }

    return pw.TableHelper.fromTextArray(
      headers: [
        'Fase',
        'Gestione',
        'Prodotto',
        'Conf. SQNPI',
        'Tracciab.',
        'Note',
      ],
      data: phases.map((p) {
        final Map<String, dynamic> map = p as Map<String, dynamic>;
        String gestione = '';
        if (map['inProprio'] == true) gestione = 'In proprio';
        if (map['terzista'] == true) {
          gestione = 'Terzista';
          final cert = map['certificatoTerzista'] ?? '';
          if (cert.isNotEmpty) {
            gestione += ' ($cert)';
          }
        }

        return [
          map['fase'] ?? '-',
          gestione,
          map['prodotto'] ?? '-',
          map['conformitaSqnpi'] == true
              ? 'SÌ'
              : (map['conformitaSqnpi'] == false ? 'NO' : 'N/D'),
          map['tracciabile'] == true
              ? 'SÌ'
              : (map['tracciabile'] == false ? 'NO' : 'N/D'),
          map['note'] ?? '-',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 8,
      ),
      headerDecoration: pw.BoxDecoration(color: style.secondaryColor),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellPadding: const pw.EdgeInsets.all(4),
    );
  }

  pw.Widget _buildSimpleRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: style.secondaryColor,
              ),
            ),
            pw.TextSpan(
              text: value.isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  @override
  pw.Widget buildPreviousNcSection(VisitPreviousNcManagement? record) {
    if (record == null) return pw.SizedBox.shrink();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('2b. Gestione NC e Azioni Correttive Precedenti'),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildComplianceRow(
                      'Esito Verifica NC',
                      record.prevNcResults == 1
                          ? 'RISOLTE'
                          : (record.prevNcResults == 2 ? 'NON RISOLTE' : 'N/A'),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildComplianceRow(
                      'Coerenza Azioni Corr.',
                      record.prevCorrectiveActionsCoherent == 1
                          ? 'SÌ'
                          : (record.prevCorrectiveActionsCoherent == 2
                                ? 'NO'
                                : 'N/A'),
                    ),
                  ),
                ],
              ),
              if (record.prevNcRequirementsStillKO.isNotEmpty)
                _buildComplianceRow(
                  'Requisiti ancora KO',
                  record.prevNcRequirementsStillKO,
                ),
              if (record.prevCorrectiveActionsDetails.isNotEmpty)
                _buildComplianceRow(
                  'Dettagli Azioni/Recidive',
                  record.prevCorrectiveActionsDetails,
                ),
              pw.Divider(color: PdfColors.grey200),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildComplianceRow(
                      'Data Cert. Org. Prec.',
                      record.prevOrgCertifiedDate.isEmpty
                          ? '-'
                          : record.prevOrgCertifiedDate,
                    ),
                  ),
                  pw.Expanded(
                    child: _buildComplianceRow(
                      'Data Provv. Org. Prec.',
                      record.prevOrgSanctionedDate.isEmpty
                          ? '-'
                          : record.prevOrgSanctionedDate,
                    ),
                  ),
                ],
              ),
              if (record.biosSanctionDetails.isNotEmpty)
                _buildComplianceRow(
                  'Sanzioni Bios emesse',
                  record.biosSanctionDetails,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  pw.Widget buildFullChecklist(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})>
    responses,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildSectionHeader('Dettaglio Checklist Compilata'),
        pw.TableHelper.fromTextArray(
          headers: [
            'Codice',
            'Requisito',
            'UEC',
            'Esito',
            'Descrizione / Azione corr.',
          ],
          data: responses.map((r) {
            String esitoText = '';
            try {
              final conf = r.response.conformita;
              if (conf == 0) {
                esitoText = 'CONFORME';
              } else if (conf == 1) {
                esitoText = 'NON CONF. (L.${r.response.livelloKo})';
              } else if (conf == 2) {
                esitoText = 'N/A';
              } else if (conf == 3) {
                esitoText = 'NON CONTROLL.';
              }
            } catch (_) {
              esitoText = 'N/D';
            }

            return [
              r.item.displayCode,
              r.item.obbligo,
              r.uec.nAggregato.isNotEmpty
                  ? '${r.uec.nAggregato} (${r.uec.coltura})'
                  : r.uec.id,
              esitoText,
              r.response.rilievoNc.isNotEmpty
                  ? r.response.rilievoNc
                  : r.response.note,
            ];
          }).toList(),
          columnWidths: const {
            0: pw.FixedColumnWidth(40),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(2),
            3: pw.FixedColumnWidth(70),
            4: pw.FlexColumnWidth(2),
          },
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 9,
          ),
          headerDecoration: pw.BoxDecoration(color: style.secondaryColor),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding: const pw.EdgeInsets.all(4),
        ),
      ],
    );
  }

  pw.Widget _buildEmptyPlaceholder(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontStyle: pw.FontStyle.italic,
          fontSize: 9,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildSingleSignatureBox(
    String role,
    String name,
    pw.MemoryImage? sigImage,
  ) {
    return pw.Container(
      width: 190,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        children: [
          pw.Text(
            role.toUpperCase(),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: style.secondaryColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            name,
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: 160,
            height: 70,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: sigImage != null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Image(sigImage, fit: pw.BoxFit.contain),
                  )
                : pw.Center(
                    child: pw.Text(
                      'Documento privo di firma nativa',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildOutcomeBox(String text, bool isChecked, {String? subtext}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: isChecked ? style.primaryColor : PdfColors.grey300,
          width: isChecked ? 2 : 1,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: isChecked ? PdfColors.white : PdfColors.grey100,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              color: isChecked ? style.primaryColor : PdfColors.white,
            ),
            child: isChecked
                ? pw.Center(
                    child: pw.Text(
                      'X',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: isChecked ? pw.FontWeight.bold : null,
                  ),
                ),
                if (subtext != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtext,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      color: style.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPremiumScoreIndicator(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey500,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
