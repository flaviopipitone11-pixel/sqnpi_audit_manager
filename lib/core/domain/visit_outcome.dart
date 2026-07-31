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
  });

  final int sumOperatoreTotale;
  final int sumUecTotale;
  final int sumTotaleVisita;
  final int maxUecScore;
  final int uecOverSoglia;
  final int totalUecs;
  final VisitOutcome outcome;

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
  }) {
    final sumTotaleVisita = sumOperatoreTotale + sumUecTotale;
    final allUecsExcluded = totalUecs > 0 && uecOverSoglia >= totalUecs;

    final VisitOutcome outcome;
    // SQNPI 2025 Rev. 15.2 Sec. 8.3.1:
    // Sospensione Operatore: Sommatoria NC >= 20 (a prescindere se per UEC o Operatore) OR Esclusione di tutte le UEC in azienda
    if (sumTotaleVisita >= sogliaTotaleVisita || allUecsExcluded) {
      outcome = VisitOutcome.nonConformeOperatore;
    } else if (uecOverSoglia > 0) {
      // Esclusione UEC/Lotto: punteggio UEC >= 10 oppure 1 NCG su adempimenti sempre obbligatori oppure Esclusione lotto diretta
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
    );
  }
}
