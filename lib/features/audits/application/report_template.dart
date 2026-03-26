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

  pw.Widget _buildSectionHeader(String title) {
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
          label,
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
  pw.Widget buildSummary(VisitOutcomeSummary outcome, Visit visit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('1. Riepilogo ed Esito Ispezione'),
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
        _buildSectionHeader('5. Non Conformità Rilevate'),
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
          _buildSectionHeader('7. Documentazione Ufficiale (Rev. 08)'),
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
          _buildSectionHeader(
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
        _buildSectionHeader('4. Bilancio di Massa'),
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
        _buildSectionHeader('6. Conclusione Ispezione'),
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
        _buildSectionHeader('2. Dati Aziendali e Compliance (M904)'),
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
        _buildSectionHeader(
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
        _buildSectionHeader('3c. Registrazioni di Campionamento'),
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
        _buildSectionHeader('8. Firme e Dichiarazioni'),
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
        _buildSectionHeader('3b. Fase di Post-Raccolta (MARCHIO)'),
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

    if (phases.isEmpty)
      return _buildEmptyPlaceholder('Nessuna fase dichiarata');

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
        if (map['terzista'] == true) gestione = 'Terzista';

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
        _buildSectionHeader('2b. Gestione NC e Azioni Correttive Precedenti'),
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
        _buildSectionHeader('Dettaglio Checklist Compilata'),
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
