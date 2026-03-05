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
    this.primaryColor = PdfColors.green700,
    this.secondaryColor = PdfColors.blueGrey700,
    this.accentColor = PdfColors.red700,
    this.margin = 32.0,
  });

  static const defaultStyle = ReportStyle();
}

/// Abstract template for PDF generation
abstract class ReportTemplate {
  final ReportStyle style;
  const ReportTemplate({this.style = ReportStyle.defaultStyle});

  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logo,
  );
  pw.Widget buildHeader(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logo,
  );
  pw.Widget buildSummary(VisitOutcomeSummary outcome);
  pw.Widget buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  );
  pw.Widget buildAttachmentsSection(List<VisitAttachment> attachments);
  pw.Widget buildSignaturesSection(List<VisitSignature> signatures);
}

/// Standard implementation of the SQNPI template
class StandardSqnpiTemplate extends ReportTemplate {
  const StandardSqnpiTemplate({super.style});

  @override
  pw.Widget buildCoverPage(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logo,
  ) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Image(logo, width: 200)
          else
            pw.Text(
              'BIOS - SQNPI',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 32,
                color: style.primaryColor,
              ),
            ),
          pw.SizedBox(height: 50),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 40,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: style.primaryColor, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'VERBALE DI ISPEZIONE',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: style.secondaryColor,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Data Visita: ${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 60),
          pw.Text(
            'AZIENDA ISPEZIONATA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: style.secondaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            company?.ragioneSociale ?? visit.companyName,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: style.primaryColor,
            ),
          ),
          if (company?.cuaa != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'CUAA: ${company!.cuaa}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
          if (company?.indirizzo != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              '${company!.indirizzo}, ${company.cap} ${company.comune}',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  @override
  pw.Widget buildHeader(
    Visit visit,
    VisitCompany? company,
    pw.MemoryImage? logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dettaglio Ispezione',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: style.secondaryColor,
              ),
            ),
            pw.Text(
              'Azienda: ${company != null ? company.ragioneSociale : visit.companyName}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Divider(color: style.primaryColor, thickness: 0.5),
      ],
    );
  }

  @override
  pw.Widget buildSummary(VisitOutcomeSummary outcome) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: style.primaryColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RIEPILOGO ESITO:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: style.primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text('Punteggio Operatore: ${outcome.sumOperatoreTotale}'),
              pw.Spacer(),
              pw.Text('MAX Punteggio UEC: ${outcome.maxSommaUec}'),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            outcome.isEsitoFavorevole
                ? 'ESITO: FAVOREVOLE'
                : 'ESITO: NON FAVOREVOLE',
            style: pw.TextStyle(
              color: outcome.isEsitoFavorevole
                  ? PdfColors.green800
                  : style.accentColor,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  ) {
    if (ncs.isEmpty) {
      return pw.Text(
        'Nessuna Non Conformità rilevata durante l\'ispezione.',
        style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NON CONFORMITÀ RILEVATE:',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
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
          headerDecoration: pw.BoxDecoration(color: style.primaryColor),
          cellHeight: 25,
          cellStyle: const pw.TextStyle(fontSize: 9),
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
        pw.Text(
          'ALLEGATI FOTOGRAFICI:',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: style.primaryColor,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: attachments.map((att) {
            final file = File(att.filePath);
            if (!file.existsSync()) return pw.SizedBox.shrink();

            try {
              final image = pw.MemoryImage(file.readAsBytesSync());
              return pw.Container(
                width: 160,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    pw.Image(image, height: 100, fit: pw.BoxFit.cover),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        att.caption.isNotEmpty
                            ? att.caption
                            : 'Senza didascalia',
                        style: const pw.TextStyle(fontSize: 7),
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
        pw.SizedBox(height: 30),
        pw.Divider(color: style.primaryColor, thickness: 0.5),
        pw.SizedBox(height: 10),
        pw.Text(
          'FIRME E DICHIARAZIONI',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: style.secondaryColor,
            fontSize: 14,
          ),
        ),
        pw.SizedBox(height: 20),
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
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 5),
        pw.Text(name, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 10),
        pw.Container(
          width: 150,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: sigImage != null
              ? pw.Image(sigImage, fit: pw.BoxFit.contain)
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
