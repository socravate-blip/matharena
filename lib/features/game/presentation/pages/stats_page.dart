import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/score_storage.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/logic/elo_calculator.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(scoreStorageProvider);
    final scores = storage.getScores();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: scores.isEmpty ? _buildEmptyState() : _buildStatsContent(scores),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NO GAMES YET',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Play Ranked or Training to see your stats',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(List<ScoreEntry> scores) {
    final totalGames = scores.length;
    final totalScore = scores.fold<int>(0, (sum, score) => sum + score.score);
    final avgScore = totalScore ~/ totalGames;
    final maxScore = scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final rankedScores = scores.where((s) => s.mode == 'ranked').toList();
    final trainingScores = scores.where((s) => s.mode == 'training').toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            'STATISTICS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        // Divider
        Container(height: 1, color: Colors.grey[900]),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              spacing: 24,
              children: [
                // Elo Rating Card (new)
                _buildEloRatingCard(),
                // Summary Cards
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Games',
                        totalGames.toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Average',
                        avgScore.toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Best',
                        maxScore.toString(),
                      ),
                    ),
                  ],
                ),
                // Elo Progress Chart (new)
                _buildEloProgressChart(),
                // Progress Chart
                if (scores.length > 1) _buildProgressChart(scores),
                // Game Breakdown
                _buildGameBreakdown(rankedScores, trainingScores),
                // Recent Scores
                _buildRecentScores(scores),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: 8,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(List<ScoreEntry> scores) {
    final sortedScores = List<ScoreEntry>.from(scores)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedScores.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedScores[i].score.toDouble()));
    }

    final maxScore =
        sortedScores.map((s) => s.score).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESSION',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxScore > 0 ? (maxScore / 4).toDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[900],
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.grey[400],
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.grey[400]!,
                          strokeColor: Colors.grey[300]!,
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBreakdown(
      List<ScoreEntry> ranked, List<ScoreEntry> training) {
    final rankedTotal = ranked.fold<int>(0, (sum, s) => sum + s.score);
    final trainingTotal = training.fold<int>(0, (sum, s) => sum + s.score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            'GAME MODES',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          _buildModeRow('⚔️ RANKED', ranked.length, rankedTotal),
          _buildModeRow('🏋️ TRAINING', training.length, trainingTotal),
        ],
      ),
    );
  }

  Widget _buildModeRow(String label, int games, int totalScore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$games games • $totalScore pts',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScores(List<ScoreEntry> scores) {
    final sortedScores = List<ScoreEntry>.from(scores)
      ..sort((a, b) => b.date.compareTo(a.date));
    final recent = sortedScores.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'RECENT GAMES',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
        ...recent.map((score) => _buildScoreCard(score)),
      ],
    );
  }

  Widget _buildScoreCard(ScoreEntry score) {
    final dateFormatter = DateFormat('MMM d, HH:mm');
    final dateStr = dateFormatter.format(score.date);
    final modeEmoji = score.mode == 'ranked' ? '⚔️' : '🏋️';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[900]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                '$modeEmoji ${score.mode.toUpperCase()}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.score.toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${score.duration} sec',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEloRatingCard() {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(playerRatingProvider);

        return profileAsync.when(
          data: (profile) {
            final leagueColor =
                EloCalculator.getLeagueColor(profile.currentRating);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border:
                    Border.all(color: leagueColor.withOpacity(0.3), width: 2),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    leagueColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // League Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: leagueColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      profile.leagueIcon,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Rating Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.league,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: leagueColor,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${profile.currentRating}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ELO',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Peak: ${profile.peakRating}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (profile.gamesPlayed < 30)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[900],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PLACEMENT',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.blue[300],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildEloProgressChart() {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(playerRatingProvider);

        return profileAsync.when(
          data: (profile) {
            if (profile.history.isEmpty) {
              return const SizedBox.shrink();
            }

            // Prepare chart data
            final spots = <FlSpot>[];
            for (int i = 0; i < profile.history.length; i++) {
              spots.add(FlSpot(
                i.toDouble(),
                profile.history[i].rating.toDouble(),
              ));
            }

            final minRating = profile.history
                .map((h) => h.rating)
                .reduce((a, b) => a < b ? a : b);
            final maxRating = profile.history
                .map((h) => h.rating)
                .reduce((a, b) => a > b ? a : b);

            final leagueColor =
                EloCalculator.getLeagueColor(profile.currentRating);

            return Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ELO PROGRESSION',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${profile.history.length} games',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 50,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey[900],
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                );
                              },
                              reservedSize: 45,
                              interval: 100,
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: (minRating - 50).toDouble(),
                        maxY: (maxRating + 50).toDouble(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: leagueColor,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: leagueColor,
                                  strokeColor: leagueColor.withOpacity(0.5),
                                  strokeWidth: 2,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: leagueColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}
