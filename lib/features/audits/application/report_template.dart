// removed unused import
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
    // Verde "sostenibilità" tipo oliva/muschio (#8B9A46)
    this.primaryColor = const PdfColor.fromInt(0xFF8B9A46),
    // Blu scuro/Grigio per testi secondari e accenti (#2C3E50)
    this.secondaryColor = const PdfColor.fromInt(0xFF2C3E50),
    this.accentColor = PdfColors.red700,
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
  pw.Widget buildAziendaCompliance(VisitCompany? company);

  pw.Widget buildUecDetailsSection(
    List<VisitUec> uecs,
    Map<String, List<VisitLot>> lotsPerUec,
  );

  pw.Widget buildSignaturesSection(
    List<VisitSignature> signatures,
    Map<String, pw.MemoryImage> images,
  );

  pw.Widget buildFullChecklist(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> responses,
  );

  // Helper generico per i titoli di sezione
  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      color: style.primaryColor,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const pw.EdgeInsets.only(bottom: 16, top: 24),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
        ),
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
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBios != null)
                pw.Image(logoBios, height: 60)
              else
                pw.Text(
                  'BIOS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 32,
                    color: style.primaryColor,
                  ),
                ),
              if (logoSqnpi != null) pw.Image(logoSqnpi, height: 60),
            ],
          ),
          pw.SizedBox(height: 80),
          pw.Text(
            'VERBALE DI\nISPEZIONE',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 48,
              color: style.primaryColor,
              lineSpacing: 1.2,
            ),
          ),
          pw.Divider(color: style.secondaryColor, thickness: 2, height: 40),
          pw.Text(
            'Sistema di Qualità Nazionale Produzione Integrata',
            style: pw.TextStyle(fontSize: 18, color: style.secondaryColor),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              border: pw.Border(
                left: pw.BorderSide(color: style.primaryColor, width: 4),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AZIENDA ISPEZIONATA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: style.secondaryColor,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  company?.ragioneSociale ?? visit.companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: style.primaryColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (company?.cuaa != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CUAA: ${company!.cuaa}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      if (company.submissionNumber.isNotEmpty)
                        pw.Text(
                          'N. DOMANDA: ${company.submissionNumber}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: style.primaryColor,
                          ),
                        ),
                    ],
                  ),
                if (company?.indirizzo != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${company!.indirizzo}, ${company.cap} ${company.comune}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'DATA ISPEZIONE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      '${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: style.secondaryColor,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TIPOLOGIA / DURATA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      '${visit.visitType.replaceAll(',', ' + ')} — ${visit.durationHours} ORE ${visit.durationHours > visit.plannedDurationHours ? '(Prog. ${visit.plannedDurationHours}h)' : ''}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: style.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  pw.Widget buildSummary(VisitOutcomeSummary outcome, Visit visit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('1. Riepilogo ed Esito Ispezione'),
        pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            color: PdfColors.white,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildScoreIndicator('PUNTEGGIO\nOPERATORE', '${outcome.sumOperatoreTotale}', style.secondaryColor),
              pw.Container(width: 1, height: 50, color: PdfColors.grey300),
              _buildScoreIndicator('PUNTEGGIO\nMASSIMO', '${outcome.maxSommaUec}', style.secondaryColor),
              pw.Container(width: 1, height: 50, color: PdfColors.grey300),
              pw.Column(
                children: [
                  pw.Text(
                    'GIUDIZIO FINALE',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: outcome.isEsitoFavorevole ? style.primaryColor : style.accentColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      outcome.isEsitoFavorevole ? 'CONFORME' : 'NON CONFORME',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13),
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

  pw.Widget _buildScoreIndicator(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color),
        ),
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
        pw.Text('Dettaglio Requisiti e Non Conformità', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
            headers: ['Requisito', 'UEC', 'Obbligo', 'Rilievo NC'],
            data: ncs
                .map(
                  (nc) => [
                    nc.item.code,
                    nc.uec.descrizione,
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
            headerDecoration: pw.BoxDecoration(
              color: style.secondaryColor,
            ),
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
        pw.Text('Riepilogo Attività (M904)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.TableHelper.fromTextArray(
          headers: ['Codice', 'Gravità', 'Descrizione N/C / Note'],
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
              nc.item.code,
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('7. Allegati Fotografici'),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: attachments.map((att) {
            final image = images[att.id];

            return pw.Container(
              width: 160,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
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
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
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
                            style: const pw.TextStyle(fontSize: 6, color: PdfColors.blue700),
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
            headers: ['Sostanze Attive', 'Acquistato', 'Utilizzato', 'Giacenza', 'Scostamento', 'Documenti'],
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
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
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
          _buildEmptyPlaceholder('Dati di chiusura ispezione non ancora inseriti.')
        else
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Stato chiusura: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(closing.isClosed ? 'CHIUSA' : 'APERTA',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: closing.isClosed ? PdfColors.green700 : PdfColors.red700)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Azioni Correttive Richieste:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(closing.correctiveActions.isNotEmpty ? closing.correctiveActions : 'Nessuna azione richiesta.',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 8),
                if (closing.resolutionDeadline != null)
                  pw.Text('Scadenza Risoluzione: ${closing.resolutionDeadline!.day}/${closing.resolutionDeadline!.month}/${closing.resolutionDeadline!.year}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red700)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  pw.Widget buildAziendaCompliance(VisitCompany? company) {
    if (company == null) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('2. Dati Aziendali e Compliance (M904)'),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Expanded(child: _buildComplianceRow('Partita IVA', company.partitaIva.isEmpty ? 'N/D' : company.partitaIva)),
                  pw.Expanded(child: _buildComplianceRow('Nuovo Operatore', company.isNewOperator ? 'SÌ' : 'NO')),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildComplianceRow('Coordinate GPS', '${company.latitudeText}, ${company.longitudeText}')),
                  pw.Expanded(child: _buildComplianceRow('Tipo Lavorazione', company.processingType.toUpperCase())),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildComplianceRow('Rappresentante', company.referente.isEmpty ? 'N/D' : company.referente)),
                  pw.Expanded(child: _buildComplianceRow('Telefono', company.telefono.isEmpty ? 'N/D' : company.telefono)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildComplianceRow('Email Contatto', company.email.isEmpty ? 'N/D' : company.email)),
                  pw.Expanded(child: _buildComplianceRow('PEC', company.pec.isEmpty ? 'N/D' : company.pec)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(child: _buildComplianceRow('Verifica SI', company.siVerification ? 'SÌ' : 'NO')),
                  pw.Expanded(child: _buildComplianceRow('Visita Congiunta', company.isJointVisit ? 'SÌ' : 'NO')),
                ],
              ),
              if (company.processingType == 'terzista') ...[
                pw.SizedBox(height: 10),
                _buildComplianceRow('N. Cert. Terzista', company.thirdPartyCertNumber),
              ],
              pw.SizedBox(height: 10),
              _buildComplianceRow('Sito Manipolazione', company.manipulationSiteAddress.isEmpty ? 'N/D' : company.manipulationSiteAddress),
              if (company.isJointVisit) ...[
                pw.SizedBox(height: 10),
                _buildComplianceRow('Dettagli Visita Congiunta', company.jointVisitDetails),
              ],
              pw.SizedBox(height: 10),
              _buildComplianceRow('Periodo Picco', company.peakPeriodFrom.isEmpty ? 'N/D' : '${company.peakPeriodFrom} - ${company.peakPeriodTo}'),
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
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: style.secondaryColor),
            ),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
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
        _buildSectionHeader('3. Esercizio di Controllo (UEC) e Lotti'),
        pw.TableHelper.fromTextArray(
          headers: ['Descrizione / Coltura', 'Lotti Associati'],
          data: uecs.map((uec) {
            final lots = lotsPerUec[uec.id] ?? [];
            final lotsTxt = lots.isEmpty
                ? 'Nessun lotto dichiarato'
                : lots
                    .map((l) => 'Cod: ${l.codice} (${l.quantita} kg/l)')
                    .join('\n');
            return [
              '${uec.descrizione}\nColtura: ${uec.coltura}',
              lotsTxt,
            ];
          }).toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: pw.BoxDecoration(color: style.primaryColor),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.topLeft,
          cellPadding: const pw.EdgeInsets.all(8),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
        ),
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
                representativeSig != null ? images[representativeSig.id] : null,
              ),
              if (delegateSig != null)
                _buildSingleSignatureBox(
                  'Il Delegato Aziendale',
                  delegateSig.signerName ?? 'Persona delegata',
                  images[delegateSig.id],
                ),
            ],
          ),
      ],
    );
  }

  @override
  pw.Widget buildFullChecklist(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> responses,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Dettaglio Checklist Compilata'),
        pw.TableHelper.fromTextArray(
          headers: ['Codice', 'Requisito', 'UEC', 'Esito', 'Note/Rilievi'],
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
              r.item.code,
              r.item.obbligo,
              r.uec.descrizione,
              esitoText,
              r.response.rilievoNc.isNotEmpty ? r.response.rilievoNc : r.response.note,
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
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
