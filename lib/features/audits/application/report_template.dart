import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
}
