import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/services/placement_service.dart';
import 'package:matharena/features/game/presentation/pages/game_home_page.dart';

/// Page de résultats après les 3 matchs de calibration
class PlacementCompletePage extends StatelessWidget {
  final List<GamePerformance> performances;
  final int initialElo;

  const PlacementCompletePage({
    super.key,
    required this.performances,
    required this.initialElo,
  });

  @override
  Widget build(BuildContext context) {
    final summary = PlacementService.getCalibrationSummary(performances, initialElo);
    final recommendations = PlacementService.getPracticeRecommendations(performances);
    final averageAccuracy = performances.map((p) => p.accuracy).reduce((a, b) => a + b) / performances.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Titre
              Text(
                '🎉',
                style: const TextStyle(fontSize: 64),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Calibration Terminée !',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // ELO Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.withOpacity(0.2),
                      Colors.blue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.cyan, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Votre ELO Initial',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$initialElo',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getLeagueName(initialElo),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stats globales
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: '🎯',
                      label: 'Précision',
                      value: '${averageAccuracy.toStringAsFixed(0)}%',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: '⚡',
                      label: 'Temps Moyen',
                      value: '${_getAverageTime().toStringAsFixed(1)}s',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Détails par match
              Text(
                'Détails des Épreuves',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              ...performances.map((perf) => _buildPerformanceCard(perf)).toList(),

              const SizedBox(height: 32),

              // Recommandations
              if (recommendations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple.withOpacity(0.5), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Text(
                            'Recommandations',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recommendations,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 48),

              // Bouton pour commencer
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const GameHomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'COMMENCER À JOUER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
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
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(GamePerformance perf) {
    final color = _getColorForMatch(perf.matchNumber);
    final icon = _getIconForMatch(perf.matchNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match ${perf.matchNumber} - ${_getPuzzleTypeName(perf.puzzleType)}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${perf.correctAnswers}/${perf.totalPuzzles} correct • ${perf.averageResponseTime.toStringAsFixed(0)}ms avg',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${perf.accuracy.toStringAsFixed(0)}%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _getAverageTime() {
    final avgTime = performances.map((p) => p.averageResponseTime).reduce((a, b) => a + b) / performances.length;
    return avgTime / 1000; // Convert to seconds
  }

  String _getLeagueName(int elo) {
    if (elo < 1200) return '🥉 Bronze';
    if (elo < 1500) return '🥈 Silver';
    if (elo < 1800) return '🥇 Gold';
    return '💎 Diamond';
  }

  String _getPuzzleTypeName(PuzzleType type) {
    switch (type) {
      case PuzzleType.basic:
        return 'Arithmétique';
      case PuzzleType.complex:
        return 'Équations';
      case PuzzleType.game24:
        return 'Jeu de 24';
      case PuzzleType.matador:
        return 'Matador';
    }
  }

  Color _getColorForMatch(int matchNumber) {
    switch (matchNumber) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getIconForMatch(int matchNumber) {
    switch (matchNumber) {
      case 1:
        return '➕';
      case 2:
        return '🧮';
      case 3:
        return '🎯';
      default:
        return '📝';
    }
  }
}
