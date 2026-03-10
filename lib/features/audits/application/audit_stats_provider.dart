import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';

class PhaseProgress {
  final String phaseName;
  final int completedCount;
  final int totalCount;

  PhaseProgress({
    required this.phaseName,
    required this.completedCount,
    required this.totalCount,
  });

  double get percent => totalCount > 0 ? completedCount / totalCount : 0.0;
}

enum AlertType { missingNote, missingPhoto }

class ValidationAlert {
  final String itemCode;
  final String description;
  final AlertType type;

  ValidationAlert({
    required this.itemCode,
    required this.description,
    required this.type,
  });

  String get message {
    switch (type) {
      case AlertType.missingNote:
        return 'Manca la nota obbligatoria';
      case AlertType.missingPhoto:
        return 'Manca la foto documentale';
    }
  }
}

/// Fornisce lo stato di avanzamento per ogni fase della checklist per una specifica UEC
final auditProgressProvider = StreamProvider.family<List<PhaseProgress>, String>((ref, uecId) {
  final db = ref.watch(appDatabaseProvider);
  
  // Watch all responses for this UEC to trigger rebuilds
  final responsesStream = (db.select(db.checklistResponses)..where((t) => t.uecId.equals(uecId))).watch();
  
  return responsesStream.asyncMap((responses) async {
    final fasi = await db.watchFasi().first;
    final progressList = <PhaseProgress>[];
    
    // Create a map for quick lookup
    final responseMap = {for (var r in responses) r.itemCode: r};

    for (final fase in fasi) {
      final items = await db.watchChecklistItemsByFase(fase).first;
      
      // Filtriamo i titoli (es. 0.0, 1, 15)
      final actualItems = items.where((it) {
        final code = it.code.trim();
        final isHeader = !code.contains('.') || 
                        RegExp(r'\.0$').hasMatch(code) ||
                        RegExp(r'\.(?!\d)').hasMatch(code);
        return !isHeader;
      }).toList();

      int completed = 0;
      for (final item in actualItems) {
        if (responseMap.containsKey(item.code)) {
          completed++;
        }
      }
      
      progressList.add(PhaseProgress(
        phaseName: fase,
        completedCount: completed,
        totalCount: actualItems.length,
      ));
    }
    
    return progressList;
  });
});

/// Identifica problemi critici nella compilazione (es. KO senza note)
final validationAlertsProvider = StreamProvider.family<List<ValidationAlert>, String>((ref, uecId) {
  final db = ref.watch(appDatabaseProvider);

  // Watch responses AND attachments to be fully reactive
  // (We use a simple watch on tables to catch any change)
  final responsesStream = (db.select(db.checklistResponses)..where((t) => t.uecId.equals(uecId))).watch();

  return responsesStream.asyncMap((responses) async {
    final fasi = await db.watchFasi().first;
    final alerts = <ValidationAlert>[];
    
    final responseMap = {for (var r in responses) r.itemCode: r};

    for (final fase in fasi) {
      final items = await db.watchChecklistItemsByFase(fase).first;
      
      for (final item in items) {
        final resp = responseMap[item.code];
        
        // Se è KO (Non Conforme)
        if (resp != null && resp.conformita != 0) {
          // 1. Controllo nota mancante
          if (resp.note.trim().isEmpty && resp.rilievoNc.trim().isEmpty) {
            alerts.add(ValidationAlert(
              itemCode: item.code,
              description: item.obbligo,
              type: AlertType.missingNote,
            ));
          }
        }
      }
    }
    return alerts;
  });
});
