import 'dart:io';
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
  pw.Widget buildSummary(VisitOutcomeSummary outcome);
  pw.Widget buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  );
  pw.Widget buildAttachmentsSection(List<VisitAttachment> attachments);
  pw.Widget buildSignaturesSection(List<VisitSignature> signatures);

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
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBios != null)
                pw.Image(logoBios, width: 150)
              else
                pw.Text(
                  'BIOS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 32,
                    color: style.primaryColor,
                  ),
                ),
              if (logoSqnpi != null) pw.Image(logoSqnpi, width: 100),
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
          pw.Spacer(),
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
                  pw.Text(
                    'CUAA: ${company!.cuaa}',
                    style: const pw.TextStyle(fontSize: 14),
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
              ],
            ),
          ),
          pw.SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  pw.Widget buildSummary(VisitOutcomeSummary outcome) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('1. Riepilogo Esito'),
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            color: PdfColors.white,
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Punteggio Operatore',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${outcome.sumOperatoreTotale}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: style.secondaryColor,
                    ),
                  ),
                ],
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Punteggio Massimo',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${outcome.maxSommaUec}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: style.secondaryColor,
                    ),
                  ),
                ],
              ),
              pw.Container(width: 1, height: 40, color: PdfColors.grey300),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: outcome.isEsitoFavorevole
                      ? style.primaryColor
                      : style.accentColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Text(
                  outcome.isEsitoFavorevole
                      ? 'ESITO FAVOREVOLE'
                      : 'ESITO NON FAVOREVOLE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
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
        _buildSectionHeader('2. Non Conformità Rilevate'),
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
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: style.secondaryColor,
            ), // Header più scuro per le NC
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {2: pw.Alignment.center},
            cellPadding: const pw.EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 6,
            ),
            cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            oddRowDecoration: pw.BoxDecoration(
              color: PdfColors.grey50,
            ), // Zebra striping
          ),
      ],
    );
  }

  @override
  pw.Widget buildAttachmentsSection(List<VisitAttachment> attachments) {
    if (attachments.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('3. Allegati Fotografici'),
        pw.Wrap(
          spacing: 16,
          runSpacing: 16,
          children: attachments.map((att) {
            final file = File(att.filePath);
            if (!file.existsSync()) return pw.SizedBox.shrink();

            try {
              final image = pw.MemoryImage(file.readAsBytesSync());
              return pw.Container(
                width: 150,
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
                        child: pw.Image(image, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(6),
                          bottomRight: pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        att.caption.isNotEmpty ? att.caption : 'Allegato',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: style.secondaryColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            } catch (_) {
              return pw.SizedBox.shrink();
            }
          }).toList(),
        ),
      ],
    );
  }

  @override
  pw.Widget buildSignaturesSection(List<VisitSignature> signatures) {
    if (signatures.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final inspectorSig = signatures
        .where((s) => s.signatureType == 'inspector')
        .firstOrNull;
    final representativeSig = signatures
        .where((s) => s.signatureType == 'representative')
        .firstOrNull;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('4. Firme e Dichiarazioni'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSingleSignatureBox(
              'L\'Ispettore SQNPI',
              inspectorSig?.signerName ?? 'Ispettore Incaricato',
              inspectorSig?.filePath,
            ),
            _buildSingleSignatureBox(
              'Il Legale Rappresentante',
              representativeSig?.signerName ?? 'Titolare / Delegato',
              representativeSig?.filePath,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSingleSignatureBox(
    String role,
    String name,
    String? imagePath,
  ) {
    pw.MemoryImage? sigImage;
    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        try {
          sigImage = pw.MemoryImage(file.readAsBytesSync());
        } catch (_) {}
      }
    }

    return pw.Column(
      children: [
        pw.Text(
          role,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: style.secondaryColor,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Container(
          width: 180,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: style.primaryColor, width: 1),
            ),
          ),
          child: sigImage != null
              ? pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(sigImage, fit: pw.BoxFit.contain),
                )
              : pw.Center(
                  child: pw.Text(
                    'Documento privo di firma nativa',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ),
        ),
      ],
    );
  }
}
