import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:intl/intl.dart';
import '../application/activity_logger.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_providers.dart';

class AdminImportPage extends ConsumerStatefulWidget {
  const AdminImportPage({super.key});

  @override
  ConsumerState<AdminImportPage> createState() => _AdminImportPageState();
}

class _AdminImportPageState extends ConsumerState<AdminImportPage> {
  bool _isImporting = false;
  String? _statusMessage;
  int _importedCount = 0;

  Future<void> _pickAndImportFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() {
      _isImporting = true;
      _statusMessage = 'Analizzando il file...';
      _importedCount = 0;
    });

    try {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = excel_pkg.Excel.decodeBytes(bytes);
      final db = ref.read(appDatabaseProvider);

      int count = 0;
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table]!;
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final visitId =
              row[0]?.value?.toString() ??
              'V-${DateTime.now().millisecondsSinceEpoch}-$i';
          final dateStr = row[1]?.value?.toString() ?? '';
          final companyName = row[2]?.value?.toString() ?? 'Azienda Ignota';
          final cuaa = row[3]?.value?.toString() ?? '';
          final city = row[4]?.value?.toString() ?? '';
          final prov = row[5]?.value?.toString() ?? '';
          final crop = row[6]?.value?.toString() ?? 'Varie';
          final inspector = row[7]?.value?.toString() ?? 'Da assegnare';
          final duration = int.tryParse(row[8]?.value?.toString() ?? '0') ?? 0;

          final lat = row.length > 9
              ? double.tryParse(
                  row[9]?.value?.toString().replaceAll(',', '.') ?? '',
                )
              : null;
          final lng = row.length > 10
              ? double.tryParse(
                  row[10]?.value?.toString().replaceAll(',', '.') ?? '',
                )
              : null;

          DateTime scheduledAt;
          try {
            scheduledAt = DateFormat('dd/MM/yyyy').parse(dateStr);
          } catch (_) {
            scheduledAt = DateTime.now();
          }

          // 1. Insert Visita
          await db
              .into(db.visits)
              .insertOnConflictUpdate(
                VisitsCompanion.insert(
                  id: visitId,
                  scheduledAt: scheduledAt,
                  companyName: companyName,
                  crop: crop,
                  status: 0,
                  updatedAt: DateTime.now(),
                  inspectorName: Value(inspector),
                  visitType: const Value('ACA'),
                  plannedDurationHours: Value(duration),
                ),
              );

          await db
              .into(db.visitCompanies)
              .insertOnConflictUpdate(
                VisitCompaniesCompanion.insert(
                  visitId: visitId,
                  updatedAt: DateTime.now(),
                  ragioneSociale: Value(companyName),
                  cuaa: Value(cuaa),
                  comune: Value(city),
                  provincia: Value(prov),
                  latitude: Value(lat),
                  longitude: Value(lng),
                ),
              );

          // 3. Upsert Master Anagrafica Azienda (Centralized)
          await db
              .into(db.masterCompanies)
              .insertOnConflictUpdate(
                MasterCompaniesCompanion.insert(
                  cuaa: cuaa.isEmpty
                      ? visitId
                      : cuaa, // Fallback to visitId if CUAA is missing
                  ragioneSociale: Value(companyName),
                  comune: Value(city),
                  provincia: Value(prov),
                  latitude: Value(lat),
                  longitude: Value(lng),
                  updatedAt: DateTime.now(),
                ),
              );

          count++;
        }
      }

      final logger = ref.read(activityLoggerProvider);
      await logger.log(
        action: 'IMPORT_EXCEL',
        description: 'Importate $count visite tramite file Excel',
      );

      setState(() {
        _isImporting = false;
        _importedCount = count;
        _statusMessage = 'Importazione completata con successo!';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importate $count visite con successo!')),
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
        _statusMessage = 'Errore durante l\'importazione: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Importazione Massiva',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pianifica ispezioni da Excel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Carica un file .xlsx per creare automaticamente decine di visite e aziende nel sistema. Il portale mapperà i dati e li renderà disponibili istantaneamente.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade600,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // Box Istruzioni
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFF1A237E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Struttura File Ottimale',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _formatStep('A', 'ID Visita'),
                      _formatStep('B', 'Data'),
                      _formatStep('C', 'Azienda'),
                      _formatStep('D', 'CUAA'),
                      _formatStep('E', 'Comune'),
                      _formatStep('F', 'Provincia'),
                      _formatStep('G', 'Coltura'),
                      _formatStep('H', 'Ispettore'),
                      _formatStep('I', 'Durata (ore)'),
                      _formatStep('J', 'Latitudine'),
                      _formatStep('K', 'Longitudine'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Drop Zone / Button
            Center(
              child: GestureDetector(
                onTap: _isImporting ? null : _pickAndImportFile,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: _isImporting
                        ? Colors.grey.shade50
                        : const Color(0xFF1A237E).withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _isImporting
                          ? Colors.grey.shade300
                          : const Color(0xFF1A237E).withValues(alpha: 0.1),
                      style: BorderStyle.solid,
                      width: 2.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (!_isImporting)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DashPainter(
                              color: const Color(
                                0xFF1A237E,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isImporting)
                              const Column(
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF1A237E),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'ELABORAZIONE IN CORSO...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: Color(0xFF1A237E),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 56,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Seleziona il file Excel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: Color(0xFF1A237E),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trascina qui o clicca per sfogliare',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_importedCount > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Ultimo import: $_importedCount righe',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _statusMessage!.contains('Errore')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusMessage!.contains('Errore')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _statusMessage!.contains('Errore')
                            ? Colors.red
                            : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _statusMessage!.contains('Errore')
                                ? Colors.red.shade900
                                : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _formatStep(String col, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1A237E).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              col,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(32),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
