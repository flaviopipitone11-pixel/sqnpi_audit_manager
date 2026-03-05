import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/storage/app_database.dart';

class DashboardStats extends StatelessWidget {
  final List<Visit> visits;

  const DashboardStats({super.key, required this.visits});

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) return const SizedBox.shrink();

    // Calcolo statistiche in modo efficiente
    final stats = _calculateStats(visits);
    final completed = stats.completed;
    final scheduled = stats.scheduled;
    final topCrops = stats.topCrops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Analisi Visite',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatCard(
                title: 'Stato Completamento',
                child: SizedBox(
                  height: 180,
                  width: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: 'Fatto',
                          color: const Color(0xFF2D6A4F),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: scheduled.toDouble(),
                          title: 'In prog.',
                          color: const Color(0xFFB7E4C7),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
              ),
              _StatCard(
                title: 'Top 5 Colture',
                child: SizedBox(
                  height: 180,
                  width: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (topCrops.isEmpty ? 0 : topCrops.first.value)
                              .toDouble() +
                          1,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < topCrops.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    topCrops[value.toInt()].key
                                        .substring(0, 3)
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: topCrops.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value.toDouble(),
                              color: const Color(0xFF2D6A4F),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  _DashboardStatsData _calculateStats(List<Visit> visits) {
    int completed = 0;
    final cropsMap = <String, int>{};

    for (final v in visits) {
      if (v.status == VisitStatus.chiusaDaSincronizzare.index ||
          v.status == VisitStatus.sincronizzata.index) {
        completed++;
      }
      cropsMap[v.crop] = (cropsMap[v.crop] ?? 0) + 1;
    }

    final topCrops = cropsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _DashboardStatsData(
      completed: completed,
      scheduled: visits.length - completed,
      topCrops: topCrops.take(5).toList(),
    );
  }
}

class _DashboardStatsData {
  final int completed;
  final int scheduled;
  final List<MapEntry<String, int>> topCrops;

  _DashboardStatsData({
    required this.completed,
    required this.scheduled,
    required this.topCrops,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
