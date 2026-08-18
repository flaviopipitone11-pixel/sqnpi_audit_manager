import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/storage/db_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../auth/presentation/auth_controller.dart';

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
final auditProgressProvider =
    StreamProvider.family<List<PhaseProgress>, String>((ref, uecId) {
      final db = ref.watch(appDatabaseProvider);

      // Watch all responses for this UEC to trigger rebuilds
      final responsesStream = (db.select(
        db.checklistResponses,
      )..where((t) => t.uecId.equals(uecId))).watch();

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
            final isHeader =
                !code.contains('.') ||
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

          progressList.add(
            PhaseProgress(
              phaseName: fase,
              completedCount: completed,
              totalCount: actualItems.length,
            ),
          );
        }

        return progressList;
      });
    });

/// Identifica problemi critici nella compilazione (es. KO senza note)
final validationAlertsProvider =
    StreamProvider.family<List<ValidationAlert>, String>((ref, id) {
      final db = ref.watch(appDatabaseProvider);

      // If id starts with VIS-, we want alerts for the entire visit
      final isVisit = id.startsWith('VIS-');

      Stream<List<ChecklistResponse>> responsesStream;
      if (isVisit) {
        responsesStream = db.watchResponsesByVisitId(id);
      } else {
        responsesStream = (db.select(
          db.checklistResponses,
        )..where((t) => t.uecId.equals(id))).watch();
      }

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
                alerts.add(
                  ValidationAlert(
                    itemCode: item.code,
                    description: item.obbligo,
                    type: AlertType.missingNote,
                  ),
                );
              }
            }
          }
        }
        return alerts;
      });
    });

class GlobalAuditStats {
  final int totalVisits;
  final int pendingVisits;
  final int inProgressVisits;
  final int closedVisits;
  final double averageNcPoints;

  GlobalAuditStats({
    required this.totalVisits,
    required this.pendingVisits,
    required this.inProgressVisits,
    required this.closedVisits,
    required this.averageNcPoints,
  });
}

/// Fornisce statistiche aggregate di tutte le visite dell'ispettore
final globalStatsProvider = StreamProvider<GlobalAuditStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = ref.watch(authControllerProvider);

  if (!auth.isAuthenticated || auth.username == null) {
    return Stream.value(
      GlobalAuditStats(
        totalVisits: 0,
        pendingVisits: 0,
        inProgressVisits: 0,
        closedVisits: 0,
        averageNcPoints: 0,
      ),
    );
  }

  // Usiamo watchVisitsByEmail per mostrare solo le statistiche dell'utente loggato
  return db.watchVisitsByEmail(auth.username!, isAdmin: auth.isAdmin).asyncMap((
    visits,
  ) async {
    int pending = 0;
    int inProgress = 0;
    int closed = 0;
    double totalPoints = 0;
    int visitsWithPoints = 0;

    for (final v in visits) {
      if (v.status == 0) {
        pending++;
      } else if (v.status == 1) {
        inProgress++;
      } else if (v.status >= 2) {
        closed++;
      }

      try {
        final summary = await db.watchVisitOutcomeSummary(v.id).first;
        if (summary.sumOperatoreTotale > 0) {
          totalPoints += summary.sumOperatoreTotale;
          visitsWithPoints++;
        }
      } catch (e) {
        // Ignoriamo errori su singole visite per non bloccare l'intera dashboard
      }
    }

    return GlobalAuditStats(
      totalVisits: visits.length,
      pendingVisits: pending,
      inProgressVisits: inProgress,
      closedVisits: closed,
      averageNcPoints: visitsWithPoints > 0
          ? totalPoints / visitsWithPoints
          : 0.0,
    );
  });
});

/// Fornisce l'ultimo log di sincronizzazione per monitorare lo stato del sistema
final lastSyncStatusProvider = StreamProvider<ActivityLog?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.activityLogs)
        ..where((t) => t.action.like('%SYNC%'))
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ])
        ..limit(1))
      .watchSingleOrNull();
});
