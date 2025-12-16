import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/multiplayer_provider.dart';
import '../../domain/services/multiplayer_service.dart';

/// Widget showing opponent's real-time progress during a match
class OpponentProgressBar extends ConsumerWidget {
  const OpponentProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(multiplayerMatchProvider);
    final opponent = matchState.opponent;
    
    if (opponent == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: opponent.isBot ? Colors.orange : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Opponent header
          Row(
            children: [
              Icon(
                opponent.isBot ? Icons.smart_toy : Icons.person,
                color: opponent.isBot ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ELO: ${opponent.elo}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${opponent.score} pts',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress indicator
          Row(
            children: [
              Text(
                'Puzzle ${opponent.currentPuzzleIndex + 1}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: matchState.match != null 
                    ? (opponent.currentPuzzleIndex + 1) / matchState.match!.puzzles.length
                    : 0,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    opponent.isBot ? Colors.orange : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          
          // Status indicator
          const SizedBox(height: 8),
          _buildStatusIndicator(opponent),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(MatchPlayer opponent) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: opponent.isBot ? Colors.orange : Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          opponent.isBot ? 'Bot solving...' : 'Solving puzzle',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Head-to-head comparison widget
class HeadToHeadWidget extends ConsumerWidget {
  final int myScore;
  final int myPuzzleIndex;
  final String myName;

  const HeadToHeadWidget({
    super.key,
    required this.myScore,
    required this.myPuzzleIndex,
    required this.myName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(multiplayerMatchProvider);
    final opponent = matchState.opponent;
    
    if (opponent == null) return const SizedBox.shrink();

    final isWinning = myScore > opponent.score;
    final isTied = myScore == opponent.score;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWinning 
            ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
            : isTied
              ? [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0.1)]
              : [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // You
          Expanded(
            child: Column(
              children: [
                Text(
                  'YOU',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  myName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '$myScore',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Puzzle ${myPuzzleIndex + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // VS separator
          Container(
            width: 2,
            height: 80,
            color: Colors.white30,
          ),
          
          // Opponent
          Expanded(
            child: Column(
              children: [
                Text(
                  opponent.isBot ? 'BOT' : 'OPPONENT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: opponent.isBot ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  opponent.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${opponent.score}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: opponent.isBot ? Colors.orange : Colors.blue,
                  ),
                ),
                Text(
                  'Puzzle ${opponent.currentPuzzleIndex + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Matchmaking search screen
class MatchmakingScreen extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final int playerElo;

  const MatchmakingScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerElo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(multiplayerMatchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Finding Match...',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Searching animation
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              matchState.isSearching 
                ? 'Searching for opponent...'
                : matchState.match != null
                  ? 'Match found!'
                  : 'Ready',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'ELO: $playerElo',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            if (matchState.opponent != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: matchState.opponent!.isBot ? Colors.orange : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      matchState.opponent!.isBot ? Icons.smart_toy : Icons.person,
                      size: 48,
                      color: matchState.opponent!.isBot ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      matchState.opponent!.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ELO: ${matchState.opponent!.elo}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () {
                ref.read(multiplayerMatchProvider.notifier).cancelSearch();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
