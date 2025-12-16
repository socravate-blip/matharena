import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Widget de graphique d'évolution de l'ELO
class EloEvolutionChart extends StatelessWidget {
  final Map<int, int> eloHistory; // timestamp -> elo
  final int currentElo;
  final Color accentColor;

  const EloEvolutionChart({
    super.key,
    required this.eloHistory,
    required this.currentElo,
    this.accentColor = Colors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    if (eloHistory.isEmpty) {
      return _buildEmptyState();
    }

    final sortedEntries = eloHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    final minElo =
        sortedEntries.map((e) => e.value).reduce(math.min).toDouble();
    final maxElo =
        sortedEntries.map((e) => e.value).reduce(math.max).toDouble();
    final eloRange = maxElo - minElo;
    final yMin = (minElo - eloRange * 0.1).floorToDouble();
    final yMax = (maxElo + eloRange * 0.1).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution ELO',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${eloHistory.length} parties',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor),
                ),
                child: Text(
                  '$currentElo',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (yMax - yMin) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[800]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (spots.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedEntries.length) {
                          return const SizedBox();
                        }
                        final timestamp = sortedEntries[value.toInt()].key;
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(timestamp);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (yMax - yMin) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                    left: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: yMin,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: accentColor,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF1A1A1A),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= sortedEntries.length) return null;

                        final timestamp = sortedEntries[index].key;
                        final date =
                            DateTime.fromMillisecondsSinceEpoch(timestamp);
                        final elo = spot.y.toInt();

                        return LineTooltipItem(
                          '${date.day}/${date.month}/${date.year}\n$elo ELO',
                          GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Pas encore de données',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Joue des parties pour voir ton évolution',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
