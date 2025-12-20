import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/adaptive_providers.dart';
import '../domain/logic/bot_ai.dart';
import '../domain/logic/placement_manager.dart';
import '../domain/models/player_stats.dart';
import '../domain/models/puzzle.dart';

/// Example integration showing how to use the adaptive bot system

// ============================================================================
// EXAMPLE 1: Starting Placement Matches
// ============================================================================

class PlacementMatchExample extends ConsumerWidget {
  const PlacementMatchExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementState = ref.watch(placementStateProvider);
    
    if (placementState.isComplete) {
      return PlacementCompleteScreen(
        elo: placementState.calculatedElo!,
        results: placementState.results,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Placement Match ${placementState.matchesCompleted + 1}/3'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Placement Match ${placementState.matchesCompleted + 1}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final puzzleType = ref.read(placementStateProvider.notifier)
                    .startNextPlacementMatch();
                // Navigate to game with this puzzle type
                Navigator.pushNamed(
                  context,
                  '/game',
                  arguments: {
                    'puzzleType': puzzleType,
                    'isPlacement': true,
                  },
                );
              },
              child: const Text('Start Match'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlacementCompleteScreen extends StatelessWidget {
  final int elo;
  final List<PlacementMatchResult> results;

  const PlacementCompleteScreen({
    super.key,
    required this.elo,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final message = PlacementManager.getPlacementCompleteMessage(elo, results);
    final rankTitle = PlacementManager.getInitialRankTitle(elo);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                'Placement Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                rankTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                'Starting ELO: $elo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/ranked');
                },
                child: const Text('Start Ranked Matches'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Creating Adaptive Bot Match
// ============================================================================

class AdaptiveBotMatchSetup {
  /// Create a bot match with adaptive difficulty
  static Future<BotMatchConfig> setupBotMatch({
    required WidgetRef ref,
    required int playerElo,
    required PlayerStats playerStats,
  }) async {
    // Check if this is first ranked match
    final isFirstRanked = playerStats.totalGames == 0 && 
                         ref.read(hasCompletedPlacementProvider);

    // Create bot opponent with adaptive difficulty
    final botRequest = BotOpponentRequest(
      playerElo: playerElo,
      stats: playerStats,
      isFirstRankedMatch: isFirstRanked,
    );
    
    final bot = ref.read(botOpponentProvider(botRequest));

    // Get recommended puzzle types
    final matchmaking = ref.read(adaptiveMatchmakingProvider);
    final puzzleTypes = matchmaking.getRecommendedPuzzleTypes(playerStats);

    // Get match summary for logging
    final matchSummary = matchmaking.getMatchSummary(
      playerElo: playerElo,
      bot: bot,
      stats: playerStats,
      isFirstRankedMatch: isFirstRanked,
    );

    print('Match Setup: $matchSummary');

    return BotMatchConfig(
      bot: bot,
      puzzleTypes: puzzleTypes,
      isFirstRanked: isFirstRanked,
      expectedWinRate: matchSummary['predictedWinRate'] as double,
    );
  }
}

class BotMatchConfig {
  final BotAI bot;
  final List<PuzzleType> puzzleTypes;
  final bool isFirstRanked;
  final double expectedWinRate;

  const BotMatchConfig({
    required this.bot,
    required this.puzzleTypes,
    required this.isFirstRanked,
    required this.expectedWinRate,
  });
}

// ============================================================================
// EXAMPLE 3: Recording Player Response Time (for bot adaptation)
// ============================================================================

class GameSessionWithAdaptiveBot {
  final BotAI bot;
  final List<int> playerResponseTimes = [];

  GameSessionWithAdaptiveBot({required this.bot});

  /// Called when player answers a question
  void onPlayerAnswer(int responseTimeMs) {
    // Record for bot adaptation
    bot.recordPlayerResponseTime(responseTimeMs);
    playerResponseTimes.add(responseTimeMs);
  }

  /// Get bot's next response time (adaptive)
  Future<void> botResponds(GamePuzzle puzzle) async {
    // Bot calculates delay based on player's recent performance
    final delay = bot.calculateDynamicDelay(puzzle);
    
    print('Bot will respond in ${delay.inMilliseconds}ms');
    print('Bot difficulty: ${bot.difficulty}');
    
    // Wait for the calculated delay
    await Future.delayed(delay);
    
    // Bot would respond here (implementation depends on your game mode).
    // The core game uses timing + correctness, not direct "answer" generation.
    print('Bot attempted the puzzle');
  }

  /// Get average player response time
  double getAveragePlayerTime() {
    if (playerResponseTimes.isEmpty) return 0;
    return playerResponseTimes.reduce((a, b) => a + b) / 
           playerResponseTimes.length;
  }
}

// ============================================================================
// EXAMPLE 4: Complete Match Flow
// ============================================================================

class CompleteMatchExample extends ConsumerStatefulWidget {
  final PlayerStats playerStats;
  final int playerElo;

  const CompleteMatchExample({
    super.key,
    required this.playerStats,
    required this.playerElo,
  });

  @override
  ConsumerState<CompleteMatchExample> createState() => _CompleteMatchExampleState();
}

class _CompleteMatchExampleState extends ConsumerState<CompleteMatchExample> {
  BotAI? bot;
  bool isLoading = true;
  GameSessionWithAdaptiveBot? gameSession;

  @override
  void initState() {
    super.initState();
    _setupMatch();
  }

  Future<void> _setupMatch() async {
    final config = await AdaptiveBotMatchSetup.setupBotMatch(
      ref: ref,
      playerElo: widget.playerElo,
      playerStats: widget.playerStats,
    );

    setState(() {
      bot = config.bot;
      gameSession = GameSessionWithAdaptiveBot(bot: config.bot);
      isLoading = false;
    });

    // Show match info
    if (config.isFirstRanked) {
      _showFirstMatchDialog();
    }
  }

  void _showFirstMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('First Ranked Match!'),
        content: const Text(
          'Welcome to ranked play! This match is designed to give you '
          'a positive first experience. Good luck!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }

  void _onPlayerAnswer(int responseTimeMs) {
    gameSession?.onPlayerAnswer(responseTimeMs);
    
    // Show player's average time
    final avgTime = gameSession?.getAveragePlayerTime() ?? 0;
    print('Player average response time: ${avgTime.toInt()}ms');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('vs ${bot!.name}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Opponent: ${bot!.name}'),
            Text('Difficulty: ${bot!.difficulty.name}'),
            Text('Bot ELO: ${bot!.skillLevel}'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Simulate player answering (3 seconds response time)
                _onPlayerAnswer(3000);
              },
              child: const Text('Simulate Player Answer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Simulate bot responding
                final puzzle = BasicPuzzle(
                  id: 'demo-1',
                  targetValue: 8,
                  numberA: 5,
                  numberB: 3,
                  operator: '+',
                );
                await gameSession?.botResponds(puzzle);
              },
              child: const Text('Simulate Bot Response'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Recording Placement Match Results
// ============================================================================

class PlacementMatchRecorder {
  /// Record a completed placement match
  static void recordPlacementMatch({
    required WidgetRef ref,
    required int matchNumber,
    required PuzzleType puzzleType,
    required int correctAnswers,
    required int totalQuestions,
    required List<int> responseTimes,
    required bool won,
  }) {
    final result = PlacementMatchResult(
      matchNumber: matchNumber,
      puzzleType: puzzleType,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      responseTimes: responseTimes,
      won: won,
    );

    ref.read(placementStateProvider.notifier).recordMatchResult(result);

    // Check if placement is complete
    final state = ref.read(placementStateProvider);
    if (state.isComplete) {
      print('Placement complete! Initial ELO: ${state.calculatedElo}');
      print('Message: ${ref.read(placementStateProvider.notifier).getCompletionMessage()}');
      
      if (ref.read(placementStateProvider.notifier).shouldRecommendPractice()) {
        print('Recommendation: ${ref.read(placementStateProvider.notifier).getPracticeRecommendation()}');
      }
    }
  }
}

// ============================================================================
// EXAMPLE 6: Matchmaking Decision
// ============================================================================

class MatchmakingDecisionExample {
  /// Decide whether to match with bot or real player
  static bool shouldMatchWithBot({
    required WidgetRef ref,
    required PlayerStats stats,
    required bool isFirstRanked,
    required int queueTime,
  }) {
    final request = MatchmakingRequest(
      stats: stats,
      isFirstRankedMatch: isFirstRanked,
      queueTimeSeconds: queueTime,
      realPlayersAvailable: true, // Check actual player pool
    );

    return ref.read(shouldMatchWithBotProvider(request));
  }
}
