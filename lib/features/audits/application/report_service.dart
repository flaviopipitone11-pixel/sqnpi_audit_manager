import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/domain/visit_outcome.dart';

class ReportService {
  final AppDatabase db;

  ReportService(this.db);

  Future<void> generateAndShareReport(String visitId) async {
    final visit = await db.watchVisitById(visitId).first;
    if (visit == null) return;

    final company = await db.watchCompanyByVisitId(visitId).first;
    final attachments = await db.watchAttachmentsByVisitId(visitId).first;
    final nonConformita = await db.watchNonConformitaByVisit(visitId).first;
    final outcome = await db.watchVisitOutcomeSummary(visitId).first;

    final pdf = pw.Document();

    // Caricamento logo opzionale
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo_bios.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(visit, company, logo),
          pw.SizedBox(height: 20),
          _buildSummary(outcome),
          pw.SizedBox(height: 20),
          _buildDetailSection(nonConformita),
          if (attachments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildAttachmentsSection(attachments),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'verbale_ispezione_${visit.companyName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildHeader(
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
            if (logo != null)
              pw.Image(logo, width: 80)
            else
              pw.Text(
                'BIOS - SQNPI',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'VERBALE DI ISPEZIONE',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  'Data: ${visit.scheduledAt.day}/${visit.scheduledAt.month}/${visit.scheduledAt.year}',
                ),
              ],
            ),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'AZIENDA:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(company?.ragioneSociale ?? visit.companyName),
        pw.Text('CUAA: ${company?.cuaa ?? '-'}'),
        pw.Text(
          'Indirizzo: ${company?.indirizzo ?? '-'}, ${company?.cap ?? ''} ${company?.comune ?? ''}',
        ),
      ],
    );
  }

  pw.Widget _buildSummary(VisitOutcomeSummary outcome) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RIEPILOGO ESITO:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text('Punteggio Operatore: ${outcome.sumOperatoreTotale}'),
              pw.Spacer(),
              pw.Text('MAX Punteggio UEC: ${outcome.maxSommaUec}'),
            ],
          ),
          pw.Text(
            'UEC sopra soglia: ${outcome.uecOverSoglia}',
            style: pw.TextStyle(
              color: outcome.isEsitoFavorevole
                  ? PdfColors.green
                  : PdfColors.red,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailSection(
    List<({ChecklistItem item, ChecklistResponse response, VisitUec uec})> ncs,
  ) {
    if (ncs.isEmpty) {
      return pw.Text('Nessuna Non Conformità rilevata durante l\'ispezione.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'NON CONFORMITÀ RILEVATE:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.TableHelper.fromTextArray(
          headers: ['Code', 'UEC', 'Tipologia', 'Rilievo NC'],
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
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerLeft,
          },
        ),
      ],
    );
  }

  pw.Widget _buildAttachmentsSection(List<VisitAttachment> attachments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ALLEGATI FOTOGRAFICI:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: attachments.take(6).map((att) {
            final file = File(att.filePath);
            if (!file.existsSync()) return pw.SizedBox.shrink();

            try {
              final image = pw.MemoryImage(file.readAsBytesSync());
              return pw.Container(
                width: 150,
                child: pw.Column(
                  children: [
                    pw.Image(image, height: 100),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      att.caption,
                      style: const pw.TextStyle(fontSize: 8),
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
}
