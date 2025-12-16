import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/logic/progression_system.dart';

/// Widget d'affichage de la progression du joueur
class ProgressionWidget extends StatelessWidget {
  final ProgressionData progression;
  final bool compact;

  const ProgressionWidget({
    super.key,
    required this.progression,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  /// Vue compacte (pour header de match)
  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: progression.league.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: progression.league.color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            progression.league.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            '${progression.league.name} ${progression.divisionName}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${progression.elo}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// Vue complète (pour page de profil)
  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            progression.league.color.withOpacity(0.3),
            progression.league.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progression.league.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et icône de ligue
          Row(
            children: [
              Text(
                progression.league.icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progression.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${progression.league.name} Division ${progression.divisionName}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: progression.league.color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progression.league.color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${progression.elo} ELO',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Barre de progression de division
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression dans la division',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    '${(progression.progressInDivision * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: progression.league.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progression.progressInDivision,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(progression.league.color),
                  minHeight: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Prochain jalon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        progression.nextMilestone.elo <= progression.elo + 200
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prochain objectif: ${progression.nextMilestone.name}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${progression.pointsToNextMilestone} points restants',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progression.nextMilestone.elo}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ),

          // Achievements
          if (progression.achievements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Achievements débloqués (${progression.achievements.length})',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: progression.achievements.take(5).map((achievement) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(achievement.icon,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        achievement.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
