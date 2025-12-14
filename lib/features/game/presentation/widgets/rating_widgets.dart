import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/logic/elo_calculator.dart';

class RatingProfileWidget extends ConsumerWidget {
  const RatingProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerRatingProvider);

    return profileAsync.when(
      data: (profile) => _buildProfile(profile),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildProfile(PlayerRatingProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!.withOpacity(0.5),
            Colors.grey[900]!.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec rating et rang
          Row(
            children: [
              Text(
                profile.leagueIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.currentRating}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    profile.league,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (profile.gamesPlayed < 30)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PLACEMENT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.blue[200],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Games', '${profile.gamesPlayed}'),
              _buildStatItem('W/D/L',
                  '${profile.wins}/${profile.draws}/${profile.losses}'),
              _buildStatItem('Win%', '${profile.winRate.toStringAsFixed(1)}%'),
              _buildStatItem('Peak', '${profile.peakRating}'),
            ],
          ),

          if (profile.mathadorsFound > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[900]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[700]!, width: 1),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.mathadorsFound} Mathador${profile.mathadorsFound > 1 ? 's' : ''} found',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.amber[200],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

/// Widget compact pour afficher le rating en header
class CompactRatingWidget extends ConsumerWidget {
  const CompactRatingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerRatingProvider);

    return profileAsync.when(
      data: (profile) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.leagueIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              '${profile.currentRating}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

/// Dialog de résultats de partie avec changement de rating
class GameResultDialog extends StatelessWidget {
  final int oldRating;
  final int newRating;
  final int score;
  final bool foundMathador;
  final String rank;
  final String rankIcon;

  const GameResultDialog({
    super.key,
    required this.oldRating,
    required this.newRating,
    required this.score,
    required this.foundMathador,
    required this.rank,
    required this.rankIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ratingChange = newRating - oldRating;
    final isGain = ratingChange >= 0;

    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game Over',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Score
            Text(
              'Score: $score',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[300],
              ),
            ),

            if (foundMathador) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[900],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⭐ MATHADOR!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[200],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Rating change
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$oldRating',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  '$newRating',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rating change indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isGain ? Colors.green[900] : Colors.red[900],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isGain ? '+' : ''}$ratingChange',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isGain ? Colors.green[200] : Colors.red[200],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rank
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rankIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  rank,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Close button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
