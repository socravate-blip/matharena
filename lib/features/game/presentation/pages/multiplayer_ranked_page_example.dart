import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/multiplayer_provider.dart';
import '../widgets/opponent_progress_widget.dart';

/// Example: Multiplayer ranked match screen
/// Shows both players solving puzzles in real-time
class MultiplayerRankedPage extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  final int playerElo;

  const MultiplayerRankedPage({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerElo,
  });

  @override
  ConsumerState<MultiplayerRankedPage> createState() => _MultiplayerRankedPageState();
}

class _MultiplayerRankedPageState extends ConsumerState<MultiplayerRankedPage> {
  bool _hasStartedMatch = false;

  @override
  void initState() {
    super.initState();
    _searchForMatch();
  }

  Future<void> _searchForMatch() async {
    // Initialize multiplayer service
    await ref.read(multiplayerMatchProvider.notifier).initialize();
    
    // Search for opponent
    await ref.read(multiplayerMatchProvider.notifier).searchForMatch(
      widget.playerId,
      widget.playerName,
      widget.playerElo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiplayerState = ref.watch(multiplayerMatchProvider);

    // Show matchmaking screen
    if (multiplayerState.match == null || multiplayerState.isSearching) {
      return MatchmakingScreen(
        playerId: widget.playerId,
        playerName: widget.playerName,
        playerElo: widget.playerElo,
      );
    }

    // Match found - wait for both ready
    final stateStr = multiplayerState.match!.state.name;
    final isReady = stateStr == 'ready' || stateStr == 'inProgress';

    if (!isReady && !_hasStartedMatch) {
      return _buildReadyScreen(multiplayerState);
    }

    // Start match if both ready
    if (isReady && !_hasStartedMatch) {
      _hasStartedMatch = true;
      // TODO: Start your ranked match here
      // You would integrate with your actual ranked provider
    }

    // Show match screen with real-time opponent tracking
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            // Head-to-head comparison at top
            Padding(
              padding: const EdgeInsets.all(16),
              child: HeadToHeadWidget(
                myScore: 0, // TODO: Connect to your actual ranked state
                myPuzzleIndex: 0, // TODO: Connect to your actual ranked state
                myName: widget.playerName,
              ),
            ),

            // Opponent progress bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OpponentProgressBar(),
            ),

            const SizedBox(height: 16),

            // Current puzzle (your existing ranked UI)
            Expanded(
              child: _buildPuzzleContent(),
            ),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyScreen(MultiplayerMatchState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Opponent card
            if (state.opponent != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: state.opponent!.isBot ? Colors.orange : Colors.blue,
                    width: 3,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      state.opponent!.isBot ? Icons.smart_toy : Icons.person,
                      size: 64,
                      color: state.opponent!.isBot ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.opponent!.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ELO: ${state.opponent!.elo}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // VS text
            Text(
              'VS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),

            // Your card
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.person,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.playerName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'ELO: ${widget.playerElo}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Ready button
            ElevatedButton(
              onPressed: () {
                ref.read(multiplayerMatchProvider.notifier).markReady();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'READY!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Waiting text
            if (state.opponent?.isReady == true)
              Text(
                'Waiting for opponent...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleContent() {
    // TODO: Integrate your actual ranked page puzzle rendering here
    // This is just a placeholder for the example
    return Center(
      child: Text(
        'Puzzle Content Here',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Your game controls go here
          Text(
            'Game Controls',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Complete the match when leaving
    ref.read(multiplayerMatchProvider.notifier).completeMatch();
    super.dispose();
  }
}

/// Simple button to start multiplayer from menu
class MultiplayerButton extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final int playerElo;

  const MultiplayerButton({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerElo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiplayerRankedPage(
              playerId: playerId,
              playerName: playerName,
              playerElo: playerElo,
            ),
          ),
        );
      },
      icon: const Icon(Icons.people),
      label: Text(
        'Play Multiplayer',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
