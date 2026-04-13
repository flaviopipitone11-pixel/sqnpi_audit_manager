import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed unused import
import '../application/report_provider.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

enum ReportType { full, gallery, checklist }

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Wrap(
          spacing: 32,
          runSpacing: 32,
          alignment: WrapAlignment.center,
          children: [
            // CARD 1: REPORT DI VERIFICA
            _buildExportCard(
              context: context,
              icon: Icons.picture_as_pdf_outlined,
              title: 'Esporta Report di Verifica',
              subtitle: 'REPORT DI VERIFICA ISPETTIVA SQNPI',
              features: [
                (Icons.business_outlined, 'Anagrafica Aziendale'),
                (Icons.warning_amber_rounded, 'Elenco Non Conformità'),
                (Icons.scale_outlined, 'Bilancio di Massa'),
                (Icons.inventory_2_outlined, 'Dati Post-Raccolta'),
                (Icons.draw_outlined, 'Firme Acquisite'),
              ],
              onPreview: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                      visitId: visitId,
                      mode: ReportType.full,
                    ),
                  ),
                );
              },
              onShare: () => ref
                  .read(reportServiceProvider)
                  .generateAndShareReport(visitId),
            ),

            // CARD 2: GALLERIA ALLEGATI
            _buildExportCard(
              context: context,
              icon: Icons.photo_library_outlined,
              title: 'Esporta Galleria Allegati',
              subtitle: 'ALLEGATI FOTOGRAFICI E DOCUMENTALI',
              features: [
                (Icons.camera_alt_outlined, 'Foto scattate in campo'),
                (Icons.location_on_outlined, 'Coordinate GPS e Didascalie'),
                (Icons.style_outlined, 'Tipologia di Allegato'),
                (Icons.calendar_today_outlined, 'Data e Ora di acquisizione'),
              ],
              onPreview: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                      visitId: visitId,
                      mode: ReportType.gallery,
                    ),
                  ),
                );
              },
              onShare: () => ref
                  .read(reportServiceProvider)
                  .generateAndSharePhotoGalleryReport(visitId),
            ),

            // CARD 3: CHECKLIST COMPLETA
            _buildExportCard(
              context: context,
              icon: Icons.checklist_rtl_outlined,
              title: 'Esporta Checklist Completa',
              subtitle: 'LISTA COMPLETA DEI REQUISITI E ESITI',
              features: [
                (Icons.list_alt_outlined, 'Tutti i punti della checklist'),
                (Icons.check_circle_outline, 'Esiti Conforme / KO / N.A.'),
                (Icons.score_outlined, 'Punteggi calcolati'),
                (Icons.notes_outlined, 'Note e Azioni Correttive'),
              ],
              onPreview: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                      visitId: visitId,
                      mode: ReportType.checklist,
                    ),
                  ),
                );
              },
              onShare: () => ref
                  .read(reportServiceProvider)
                  .generateAndShareChecklistReport(visitId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<(IconData, String)> features,
    required VoidCallback onPreview,
    required VoidCallback onShare,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          ...features.map((f) => _buildFeatureItem(f.$1, f.$2)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Anteprima'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Condividi'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class PdfPreviewScreen extends ConsumerWidget {
  const PdfPreviewScreen({
    super.key,
    required this.visitId,
    required this.mode,
  });
  final String visitId;
  final ReportType mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<Uint8List?> pdfAsync;
    String title;

    switch (mode) {
      case ReportType.full:
        pdfAsync = ref.watch(reportPdfProvider(visitId));
        title = 'Anteprima Report';
        break;
      case ReportType.gallery:
        pdfAsync = ref.watch(photoGalleryPdfProvider(visitId));
        title = 'Anteprima Galleria';
        break;
      case ReportType.checklist:
        pdfAsync = ref.watch(checklistPdfProvider(visitId));
        title = 'Anteprima Checklist';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: pdfAsync.when(
        data: (bytes) {
          if (bytes == null) {
            return const Center(child: Text('Nessun file generato.'));
          }
          return PdfPreview(
            build: (format) => bytes,
            allowSharing: false,
            allowPrinting: true,
            dynamicLayout: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Errore durante la generazione: $err')),
      ),
    );
  }
}
