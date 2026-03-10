import 'package:flutter_riverpod/flutter_riverpod.dart';

class MassBalanceData {
  final double purchased;
  final double used;
  final double stock;
  final double discrepancyPercentage;
  final bool isOverThreshold;

  MassBalanceData({
    required this.purchased,
    required this.used,
    required this.stock,
    required this.discrepancyPercentage,
    required this.isOverThreshold,
  });

  factory MassBalanceData.empty() => MassBalanceData(
    purchased: 0,
    used: 0,
    stock: 0,
    discrepancyPercentage: 0,
    isOverThreshold: false,
  );
}

/// Provider per il calcolo del bilancio di massa (es. punti 1.4 e 10.2)
final massBalanceProvider =
    Provider.family<
      MassBalanceData,
      ({double purchased, double used, double threshold})
    >((ref, args) {
      final purchased = args.purchased;
      final used = args.used;
      final threshold = args.threshold;

      final stock = purchased - used;
      final discrepancy = purchased > 0 ? (stock.abs() / purchased) * 100 : 0.0;
      final isOverThreshold = discrepancy > threshold;

      return MassBalanceData(
        purchased: purchased,
        used: used,
        stock: stock,
        discrepancyPercentage: discrepancy,
        isOverThreshold: isOverThreshold,
      );
    });
