import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/player_stats.dart';
import '../../domain/services/stats_service.dart';
import '../widgets/elo_evolution_chart.dart';

/// Page de statistiques avancées avec tous les graphiques
class AdvancedStatsPage extends StatefulWidget {
  const AdvancedStatsPage({super.key});

  @override
  State<AdvancedStatsPage> createState() => _AdvancedStatsPageState();
}

class _AdvancedStatsPageState extends State<AdvancedStatsPage> {
  final StatsService _statsService = StatsService();
  PlayerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final stats = await _statsService.getPlayerStats(uid);
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'STATISTIQUES DÉTAILLÉES',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _stats == null || _stats!.totalGames == 0
              ? _buildEmptyState()
              : _buildStatsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 24),
          Text(
            'Aucune donnée disponible',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Joue des parties pour débloquer tes stats!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildOverviewCards(),
          const SizedBox(height: 24),

          // ELO Evolution
          if (_stats!.eloHistory.isNotEmpty)
            Column(
              children: [
                EloEvolutionChart(
                  eloHistory: _stats!.eloHistory,
                  currentElo: _stats!.eloHistory.values.isEmpty
                      ? 1200
                      : _stats!.eloHistory.values.last,
                  accentColor: Colors.cyan,
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Win Rate Distribution
          _buildWinRatePieChart(),
          const SizedBox(height: 24),

          // Response Time by Puzzle Type
          _buildResponseTimeChart(),
          const SizedBox(height: 24),

          // Accuracy by Puzzle Type
          _buildAccuracyChart(),
          const SizedBox(height: 24),

          // Games Per Day (last 7 days)
          if (_stats!.gamesPerDay.isNotEmpty) ...[
            _buildGamesPerDayChart(),
            const SizedBox(height: 24),
          ],

          // Personal Records
          _buildPersonalRecords(),
          const SizedBox(height: 24),

          // Detailed Puzzle Stats
          _buildPuzzleTypeDetails(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'PARTIES',
            '${_stats!.totalGames}',
            Icons.sports_esports,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'WIN RATE',
            '${_stats!.winRate.toStringAsFixed(1)}%',
            Icons.emoji_events,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'STREAK',
            _stats!.currentStreak >= 0
                ? '+${_stats!.currentStreak}'
                : '${_stats!.currentStreak}',
            _stats!.currentStreak >= 0 ? Icons.whatshot : Icons.ac_unit,
            _stats!.currentStreak >= 0 ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinRatePieChart() {
    if (_stats!.totalGames == 0) return const SizedBox();

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
          Text(
            'Répartition Victoires/Défaites',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: _stats!.wins.toDouble(),
                          title: '${_stats!.wins}',
                          radius: 60,
                          titleStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: _stats!.losses.toDouble(),
                          title: '${_stats!.losses}',
                          radius: 60,
                          titleStyle: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegend('Victoires', Colors.green, _stats!.wins),
                  const SizedBox(height: 12),
                  _buildLegend('Défaites', Colors.red, _stats!.losses),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildResponseTimeChart() {
    final data = [
      ('Basic', _stats!.basicStats.avgResponseTime, Colors.blue),
      ('Complex', _stats!.complexStats.avgResponseTime, Colors.orange),
      ('Game24', _stats!.game24Stats.avgResponseTime, Colors.purple),
      ('Mathadore', _stats!.mathadoreStats.avgResponseTime, Colors.red),
    ].where((e) => e.$2 > 0).toList();

    if (data.isEmpty) return const SizedBox();

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
          Text(
            'Temps de Réponse Moyen (ms)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    data.map((e) => e.$2).reduce((a, b) => a > b ? a : b) * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index].$1,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                    left: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.$2,
                        color: entry.value.$3,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart() {
    final data = [
      ('Basic', _stats!.basicStats.accuracy, Colors.blue),
      ('Complex', _stats!.complexStats.accuracy, Colors.orange),
      ('Game24', _stats!.game24Stats.accuracy, Colors.purple),
      ('Mathadore', _stats!.mathadoreStats.accuracy, Colors.red),
    ].where((e) => e.$2 > 0).toList();

    if (data.isEmpty) return const SizedBox();

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
          Text(
            'Précision par Type (%)',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...data.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.$1,
                          style: GoogleFonts.inter(
                              fontSize: 14, color: Colors.grey[400])),
                      Text(
                        '${item.$2.toStringAsFixed(1)}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.$3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: item.$2 / 100,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation(item.$3),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGamesPerDayChart() {
    final sortedEntries = _stats!.gamesPerDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last7Days = sortedEntries.length > 7
        ? sortedEntries.sublist(sortedEntries.length - 7)
        : sortedEntries;

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
          Text(
            'Activité (7 derniers jours)',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (last7Days
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() *
                    1.2),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= last7Days.length)
                          return const SizedBox();
                        final date = last7Days[index].key.split('-');
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${date[2]}/${date[1]}',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: Colors.grey[600])),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey[500]));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                    left: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                barGroups: last7Days.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        color: Colors.cyan,
                        width: 30,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecords() {
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
          Text(
            'Records Personnels',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildRecordRow('🏆 Meilleure série',
              '${_stats!.bestWinStreak} victoires', Colors.amber),
          if (_stats!.fastestSolve > 0)
            _buildRecordRow('⚡ Résolution rapide', '${_stats!.fastestSolve} ms',
                Colors.cyan),
          if (_stats!.slowestSolve > 0)
            _buildRecordRow('🐌 Résolution lente', '${_stats!.slowestSolve} ms',
                Colors.grey),
          if (_stats!.shortestMatch > 0)
            _buildRecordRow(
                '⏱️ Match court', '${_stats!.shortestMatch}s', Colors.green),
          if (_stats!.longestMatch > 0)
            _buildRecordRow(
                '⏳ Match long', '${_stats!.longestMatch}s', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleTypeDetails() {
    final types = [
      ('Basic Arithmetic', _stats!.basicStats, Colors.blue),
      ('Complex Operations', _stats!.complexStats, Colors.orange),
      ('Game of 24', _stats!.game24Stats, Colors.purple),
      ('Mathadore', _stats!.mathadoreStats, Colors.red),
    ].where((e) => e.$2.totalAttempts > 0).toList();

    if (types.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails par Type de Puzzle',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...types.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: type.$3.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                            color: type.$3,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.$1,
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Tentatives', '${type.$2.totalAttempts}',
                          Icons.psychology),
                      _buildMiniStat(
                          'Précision',
                          '${type.$2.accuracy.toStringAsFixed(1)}%',
                          Icons.check_circle),
                      _buildMiniStat(
                          'Moy.',
                          '${type.$2.avgResponseTime.toStringAsFixed(0)}ms',
                          Icons.speed),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}
