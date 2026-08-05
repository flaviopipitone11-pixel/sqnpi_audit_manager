enum VisitOutcome { conforme, nonConformeUec, nonConformeOperatore }

class VisitOutcomeSummary {
  const VisitOutcomeSummary({
    required this.sumOperatoreTotale,
    required this.sumUecTotale,
    required this.sumTotaleVisita,
    required this.maxUecScore,
    required this.uecOverSoglia,
    required this.totalUecs,
    required this.outcome,
    required this.uecScores,
  });

  final int sumOperatoreTotale;
  final int sumUecTotale;
  final int sumTotaleVisita;
  final int maxUecScore;
  final int uecOverSoglia;
  final int totalUecs;
  final VisitOutcome outcome;
  final Map<String, int> uecScores;

  bool get isEsitoFavorevole => outcome != VisitOutcome.nonConformeOperatore;
  bool get allUecsExcluded => totalUecs > 0 && uecOverSoglia >= totalUecs;

  static const int sogliaUec = 10;
  static const int sogliaOperatore = 10;
  static const int sogliaTotaleVisita = 20;

  factory VisitOutcomeSummary.fromRaw({
    required int sumOperatoreTotale,
    required int sumUecTotale,
    int maxUecScore = 0,
    required int uecOverSoglia,
    int totalUecs = 0,
    Map<String, int> uecScores = const {},
  }) {
    final sumTotaleVisita = sumOperatoreTotale + sumUecTotale;
    final allUecsExcluded = totalUecs > 0 && uecOverSoglia >= totalUecs;

    final VisitOutcome outcome;
    // Sospensione Operatore (Non Conforme Operatore) se:
    // - la somma totale KO della visita >= 20 (sogliaTotaleVisita), oppure
    // - il punteggio KO Operatore >= 10 (sogliaOperatore > 9), oppure
    // - tutte le UEC della visita risultano escluse (allUecsExcluded).
    // Esclusione Lotto (Non Conforme UEC) se:
    // - almeno una UEC supera la soglia KO (10 punti) ma non tutte le UEC sono escluse.
    if (sumTotaleVisita >= sogliaTotaleVisita ||
        sumOperatoreTotale >= sogliaOperatore ||
        allUecsExcluded) {
      outcome = VisitOutcome.nonConformeOperatore;
    } else if (uecOverSoglia > 0 || maxUecScore >= sogliaUec) {
      outcome = VisitOutcome.nonConformeUec;
    } else {
      outcome = VisitOutcome.conforme;
    }

    return VisitOutcomeSummary(
      sumOperatoreTotale: sumOperatoreTotale,
      sumUecTotale: sumUecTotale,
      sumTotaleVisita: sumTotaleVisita,
      maxUecScore: maxUecScore,
      uecOverSoglia: uecOverSoglia,
      totalUecs: totalUecs,
      outcome: outcome,
      uecScores: uecScores,
    );
  }
}
