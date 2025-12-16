import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/logic/progression_system.dart';

/// Widget pour afficher les informations de l'adversaire
class OpponentCard extends StatelessWidget {
  final String nickname;
  final int elo;
  final int? winStreak;
  final int? loseStreak;
  final int? totalGames;
  final bool isFound;

  const OpponentCard({
    super.key,
    required this.nickname,
    required this.elo,
    this.winStreak,
    this.loseStreak,
    this.totalGames,
    this.isFound = false,
  });

  @override
  Widget build(BuildContext context) {
    final progression =
        ProgressionSystem.getProgressionData(elo, totalGames ?? 0);
    final currentStreak = (winStreak ?? 0) - (loseStreak ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            progression.league.color.withOpacity(0.2),
            progression.league.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progression.league.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Status badge
          if (isFound)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'ADVERSAIRE TROUVÉ',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // League Icon
          Text(
            progression.league.icon,
            style: const TextStyle(fontSize: 64),
          ),

          const SizedBox(height: 12),

          // Nickname
          Text(
            nickname,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // League & Division
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: progression.league.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: progression.league.color),
            ),
            child: Text(
              '${progression.league.name} ${progression.divisionName}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: progression.league.color,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ELO
              _buildStatColumn(
                icon: Icons.stars,
                label: 'ELO',
                value: '$elo',
                color: progression.league.color,
              ),

              // Streak
              if (currentStreak != 0)
                _buildStatColumn(
                  icon: currentStreak > 0 ? Icons.whatshot : Icons.ac_unit,
                  label: 'STREAK',
                  value:
                      currentStreak > 0 ? '+$currentStreak' : '$currentStreak',
                  color: currentStreak > 0 ? Colors.orange : Colors.blue,
                ),

              // Win/Loss
              if (totalGames != null && totalGames! > 0)
                _buildStatColumn(
                  icon: Icons.emoji_events,
                  label: 'PARTIES',
                  value: '$totalGames',
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
