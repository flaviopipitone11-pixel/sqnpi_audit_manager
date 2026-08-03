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

  bool get isEsitoFavorevole => outcome == VisitOutcome.conforme;
  bool get allUecsExcluded => totalUecs > 0 && uecOverSoglia >= totalUecs;

  static const int sogliaUec = 10;
  static const int sogliaOperatore = 20;
  static const int sogliaTotaleVisita = 20;

  factory VisitOutcomeSummary.fromRaw({
    required int sumOperatoreTotale,
    required int sumUecTotale,
    int maxUecScore = 0,
    required int uecOverSoglia,
    int totalUecs = 0,
    Map<String, int> uecScores = const {},
  }) {
    final sumTotaleVisita = sumOperatoreTotale + maxUecScore;
    final allUecsExcluded = totalUecs > 0 && uecOverSoglia >= totalUecs;

    final VisitOutcome outcome;
    // Nuova regola: non conforme l'azienda se e solo se tutte le UEC di quel azienda
    // hanno esclusione lotto (uecOverSoglia >= totalUecs) E la somma tra punteggio operatore
    // e punteggio massimo UEC/lotto è maggiore di 20.
    if (allUecsExcluded && sumTotaleVisita > 20) {
      outcome = VisitOutcome.nonConformeOperatore;
    } else if (uecOverSoglia > 0) {
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
