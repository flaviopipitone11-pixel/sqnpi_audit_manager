import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed unused import
import '../application/report_provider.dart';
import 'package:printing/printing.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
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
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Esporta Verbale Ispezione',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Genera il documento PDF finale contenente l\'anagrafica, le non conformità rilevate e gli allegati fotografici selezionati.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildFeatureItem(
                Icons.business_outlined,
                'Anagrafica Aziendale',
              ),
              _buildFeatureItem(
                Icons.warning_amber_rounded,
                'Elenco Non Conformità',
              ),
              _buildFeatureItem(
                Icons.photo_library_outlined,
                'Allegati Fotografici',
              ),
              _buildFeatureItem(Icons.draw_outlined, 'Firme Acquisite'),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PdfPreviewScreen(visitId: visitId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('Anteprima'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => ref
                          .read(reportServiceProvider)
                          .generateAndShareReport(visitId),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Condividi'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Il file verrà salvato localmente e potrà essere condiviso tramite le app di sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class PdfPreviewScreen extends ConsumerWidget {
  const PdfPreviewScreen({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfAsync = ref.watch(reportPdfProvider(visitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Anteprima Verbale')),
      body: pdfAsync.when(
        data: (bytes) => PdfPreview(
          build: (format) => bytes,
          allowSharing: false,
          allowPrinting: true,
          dynamicLayout: false, // Important for fixed reports
          canChangePageFormat: false,
          canChangeOrientation: false,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Errore durante la generazione: $err')),
      ),
    );
  }
}
