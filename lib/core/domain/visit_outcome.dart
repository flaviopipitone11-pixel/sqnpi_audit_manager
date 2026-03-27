enum VisitOutcome { conforme, nonConformeUec, nonConformeOperatore }

class VisitOutcomeSummary {
  const VisitOutcomeSummary({
    required this.sumOperatoreTotale,
    required this.sumUecTotale,
    required this.uecOverSoglia,
    required this.outcome,
  });

  final int sumOperatoreTotale;
  final int sumUecTotale;
  final int uecOverSoglia;
  final VisitOutcome outcome;

  bool get isEsitoFavorevole => outcome == VisitOutcome.conforme;

  static const int sogliaUec = 10;
  static const int sogliaOperatore = 20;

  factory VisitOutcomeSummary.fromRaw({
    required int sumOperatoreTotale,
    required int sumUecTotale,
    required int uecOverSoglia,
  }) {
    final VisitOutcome outcome;
    if (uecOverSoglia > 0) {
      outcome = VisitOutcome.nonConformeUec;
    } else if (sumOperatoreTotale >= sogliaOperatore) {
      outcome = VisitOutcome.nonConformeOperatore;
    } else {
      outcome = VisitOutcome.conforme;
    }

    return VisitOutcomeSummary(
      sumOperatoreTotale: sumOperatoreTotale,
      sumUecTotale: sumUecTotale,
      uecOverSoglia: uecOverSoglia,
      outcome: outcome,
    );
  }
}
