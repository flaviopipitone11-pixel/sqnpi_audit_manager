import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/db_providers.dart';

/// Rappresenta lo stato delle sanzioni per una visita
class SanctionsStatus {
  final int totalNcPoints;
  final bool isUecExcluded;
  final bool isCompanySuspended;
  final List<String> excludedUecIds;

  SanctionsStatus({
    required this.totalNcPoints,
    required this.isUecExcluded,
    required this.isCompanySuspended,
    required this.excludedUecIds,
  });

  factory SanctionsStatus.empty() => SanctionsStatus(
    totalNcPoints: 0,
    isUecExcluded: false,
    isCompanySuspended: false,
    excludedUecIds: [],
  );
}

final sanctionsProvider = StreamProvider.family<SanctionsStatus, String>((
  ref,
  visitId,
) {
  final db = ref.watch(appDatabaseProvider);

  return db.watchVisitOutcomeSummary(visitId).map((summary) {
    // Sulla base dei criteri SQNPI:
    // 1. Somma punteggi NC: già calcolata in summary.sumOperatoreTotale
    final points = summary.sumOperatoreTotale;

    // 2. Esclusione UEC se punti >= 10
    final isUecExcluded = points >= 10;

    // 3. Sospensione Azienda se punti >= 20
    // Oppure se tutte le UEC aziendali risultano escluse (questo richiede più info)
    final isCompanySuspended = points >= 20;

    return SanctionsStatus(
      totalNcPoints: points,
      isUecExcluded: isUecExcluded,
      isCompanySuspended: isCompanySuspended,
      excludedUecIds: [], // Da popolare se necessario
    );
  });
});
