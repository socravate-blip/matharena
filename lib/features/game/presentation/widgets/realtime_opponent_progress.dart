import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/match_model.dart';

/// Widget affichant la progression de l'adversaire en temps réel
class OpponentProgressWidget extends StatelessWidget {
  final PlayerData? opponentData;
  final String? opponentNickname;

  const OpponentProgressWidget({
    super.key,
    this.opponentData,
    this.opponentNickname,
  });

  @override
  Widget build(BuildContext context) {
    // Si pas encore d'adversaire
    if (opponentData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opponentNickname ?? 'En attente...',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0,
                    backgroundColor: Colors.grey[900],
                    valueColor: AlwaysStoppedAnimation(Colors.grey[800]!),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Adversaire présent
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[900]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opponentData!.nickname.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${opponentData!.score}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: opponentData!.progress,
                  backgroundColor: Colors.grey[900],
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
