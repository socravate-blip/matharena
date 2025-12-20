import 'package:flutter_test/flutter_test.dart';
import 'package:matharena/features/game/domain/logic/bot_ai.dart';
import 'package:matharena/features/game/domain/logic/placement_manager.dart';
import 'package:matharena/features/game/domain/logic/matchmaking_logic.dart';
import 'package:matharena/features/game/domain/models/player_stats.dart';
import 'package:matharena/features/game/domain/models/puzzle.dart';

void main() {
  group('BotAI Adaptive System', () {
    test('Underdog bot is slower than player average', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.underdog,
      );

      // Simulate player response times (average = 4000ms)
      bot.recordPlayerResponseTime(3800);
      bot.recordPlayerResponseTime(4000);
      bot.recordPlayerResponseTime(4200);

      final puzzle = BasicPuzzle(
        id: 'test-1',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 4000);

      // Underdog Basic Math: cap absolu 2-4s (même si joueur est lent)
      expect(delay.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(4000));
    });

    test('Competitive bot matches player average', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      final puzzle = BasicPuzzle(
        id: 'test-2',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 4000);

      // Competitive Basic Math: cap absolu 1.5-3s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1500));
      expect(delay.inMilliseconds, lessThanOrEqualTo(3000));
    });

    test('Boss bot is faster than player average', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      final puzzle = BasicPuzzle(
        id: 'test-boss',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 4000);

      // Boss Basic Math: cap absolu 1-2s (10% chance hésitation)
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(2000));
    });

    test('Bot records and uses player response times', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      // Record 10 times
      for (int i = 0; i < 10; i++) {
        bot.recordPlayerResponseTime(3000 + (i * 100)); // 3000-3900ms
      }

      // Should only keep last 10
      final puzzle = BasicPuzzle(
        id: 'test-3',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );
      final delay = bot.calculateDynamicDelay(puzzle);

      // Average should be around 3450ms
      expect(delay.inMilliseconds, greaterThanOrEqualTo(3000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(4000));
    });

    test('Bot respects minimum response time', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      // Very fast player (500ms average)
      final puzzle = BasicPuzzle(
        id: 'test-4',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 500);

      // Boss Basic Math: cap minimum absolu = 1s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(2000));
    });

    test('Complex puzzles have higher caps', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.underdog,
      );

      final puzzle = ComplexPuzzle(
        id: 'test-complex',
        targetValue: 42,
        numberA: 7,
        numberB: 6,
        numberC: 0,
        operator1: '*',
        operator2: '+',
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 3000);

      // Underdog Complex Math: cap absolu 4-7s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(4000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(7000));
    });

    test('Game24 puzzles have even higher caps', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      final puzzle = Game24Puzzle(
        id: 'test-game24',
        targetValue: 24,
        availableNumbers: [3, 8, 3, 8],
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 15000);

      // Boss Game24: cap absolu 5-10s (même si joueur met 15s)
      expect(delay.inMilliseconds, greaterThanOrEqualTo(5000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(10000));
    });

    test('Matador puzzles have highest caps', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      final puzzle = MatadorPuzzle(
        id: 'test-matador',
        targetValue: 100,
        availableNumbers: [3, 5, 7, 9, 11],
      );
      final delay =
          bot.calculateDynamicDelay(puzzle, playerHistoricalAvgMs: 25000);

      // Competitive Matador: cap absolu 10-17s (même si joueur met 25s)
      expect(delay.inMilliseconds, greaterThanOrEqualTo(10000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(17000));
    });
  });

  group('PlacementManager', () {
    test('Calculate initial ELO correctly', () {
      final results = [
        PlacementMatchResult(
          matchNumber: 1,
          puzzleType: PuzzleType.basic,
          correctAnswers: 8,
          totalQuestions: 10,
          responseTimes: [
            3000,
            3200,
            3500,
            2800,
            3100,
            3300,
            2900,
            3400,
            3600,
            3000
          ],
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 2,
          puzzleType: PuzzleType.complex,
          correctAnswers: 7,
          totalQuestions: 10,
          responseTimes: [
            4500,
            4800,
            5000,
            4700,
            4900,
            5200,
            4600,
            4800,
            5100,
            4700
          ],
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 3,
          puzzleType: PuzzleType.game24,
          correctAnswers: 6,
          totalQuestions: 10,
          responseTimes: [
            6000,
            6500,
            7000,
            6200,
            6800,
            7200,
            6100,
            6700,
            6900,
            6300
          ],
          won: false,
        ),
      ];

      final elo = PlacementManager.calculateInitialElo(results);

      // 70% accuracy, ~4.5s avg time, 2/3 wins
      // Expected: ~1200-1300 ELO
      expect(elo, greaterThanOrEqualTo(1100));
      expect(elo, lessThanOrEqualTo(1400));
    });

    test('High performance gets high ELO', () {
      final results = [
        PlacementMatchResult(
          matchNumber: 1,
          puzzleType: PuzzleType.basic,
          correctAnswers: 10,
          totalQuestions: 10,
          responseTimes: List.filled(10, 2500),
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 2,
          puzzleType: PuzzleType.complex,
          correctAnswers: 9,
          totalQuestions: 10,
          responseTimes: List.filled(10, 3000),
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 3,
          puzzleType: PuzzleType.game24,
          correctAnswers: 8,
          totalQuestions: 10,
          responseTimes: List.filled(10, 4000),
          won: true,
        ),
      ];

      final elo = PlacementManager.calculateInitialElo(results);

      // 90% accuracy, fast times, 3/3 wins
      // Expected: 1400-1600 ELO (high)
      expect(elo, greaterThanOrEqualTo(1400));
      expect(elo, lessThanOrEqualTo(1600));
    });

    test('Poor performance gets low ELO', () {
      final results = [
        PlacementMatchResult(
          matchNumber: 1,
          puzzleType: PuzzleType.basic,
          correctAnswers: 3,
          totalQuestions: 10,
          responseTimes: List.filled(10, 10000),
          won: false,
        ),
        PlacementMatchResult(
          matchNumber: 2,
          puzzleType: PuzzleType.complex,
          correctAnswers: 2,
          totalQuestions: 10,
          responseTimes: List.filled(10, 12000),
          won: false,
        ),
        PlacementMatchResult(
          matchNumber: 3,
          puzzleType: PuzzleType.game24,
          correctAnswers: 1,
          totalQuestions: 10,
          responseTimes: List.filled(10, 15000),
          won: false,
        ),
      ];

      final elo = PlacementManager.calculateInitialElo(results);

      // 20% accuracy, slow times, 0/3 wins
      // Expected: 800-1000 ELO (low)
      expect(elo, greaterThanOrEqualTo(800));
      expect(elo, lessThanOrEqualTo(1000));
    });

    test('ELO is clamped between 800 and 1600', () {
      // Extreme case: perfect performance
      final perfectResults = [
        PlacementMatchResult(
          matchNumber: 1,
          puzzleType: PuzzleType.basic,
          correctAnswers: 10,
          totalQuestions: 10,
          responseTimes: List.filled(10, 1000), // Super fast
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 2,
          puzzleType: PuzzleType.complex,
          correctAnswers: 10,
          totalQuestions: 10,
          responseTimes: List.filled(10, 1000),
          won: true,
        ),
        PlacementMatchResult(
          matchNumber: 3,
          puzzleType: PuzzleType.game24,
          correctAnswers: 10,
          totalQuestions: 10,
          responseTimes: List.filled(10, 1000),
          won: true,
        ),
      ];

      final elo = PlacementManager.calculateInitialElo(perfectResults);
      expect(elo, lessThanOrEqualTo(1600)); // Clamped
    });

    test('Get correct puzzle type for each match', () {
      expect(PlacementManager.getPuzzleTypeForMatch(1), PuzzleType.basic);
      expect(PlacementManager.getPuzzleTypeForMatch(2), PuzzleType.complex);
      expect(PlacementManager.getPuzzleTypeForMatch(3), PuzzleType.game24);
    });

    test('Recommend practice for poor performers', () {
      final poorResults = [
        PlacementMatchResult(
          matchNumber: 1,
          puzzleType: PuzzleType.basic,
          correctAnswers: 3,
          totalQuestions: 10,
          responseTimes: List.filled(10, 8000),
          won: false,
        ),
        PlacementMatchResult(
          matchNumber: 2,
          puzzleType: PuzzleType.complex,
          correctAnswers: 2,
          totalQuestions: 10,
          responseTimes: List.filled(10, 9000),
          won: false,
        ),
        PlacementMatchResult(
          matchNumber: 3,
          puzzleType: PuzzleType.game24,
          correctAnswers: 1,
          totalQuestions: 10,
          responseTimes: List.filled(10, 10000),
          won: false,
        ),
      ];

      expect(PlacementManager.shouldRecommendPractice(poorResults), true);
    });
  });

  group('MatchmakingLogic', () {
    final matchmaking = MatchmakingLogic();

    test('First ranked match never gets Boss bot', () {
      final stats = PlayerStats(totalGames: 0);

      for (int i = 0; i < 20; i++) {
        final difficulty = matchmaking.selectBotDifficulty(
          stats: stats,
          isFirstRankedMatch: true,
        );
        expect(difficulty, isNot(BotDifficulty.boss));
      }
    });

    test('LoseStreak >= 3 always gets Underdog bot', () {
      final stats = PlayerStats(totalGames: 10, currentLoseStreak: 5);

      for (int i = 0; i < 10; i++) {
        final difficulty = matchmaking.selectBotDifficulty(
          stats: stats,
          isFirstRankedMatch: false,
        );
        expect(difficulty, BotDifficulty.underdog);
      }
    });

    test('WinStreak >= 5 gets Boss or Competitive', () {
      final stats = PlayerStats(totalGames: 10, currentWinStreak: 6);

      for (int i = 0; i < 20; i++) {
        final difficulty = matchmaking.selectBotDifficulty(
          stats: stats,
          isFirstRankedMatch: false,
        );
        expect(
            difficulty, isIn([BotDifficulty.boss, BotDifficulty.competitive]));
      }
    });

    test('Bot opponent has correct ELO range for Underdog', () {
      final stats = PlayerStats(totalGames: 10, currentLoseStreak: 3);
      final bot = matchmaking.createBotOpponent(
        playerElo: 1200,
        stats: stats,
        isFirstRankedMatch: false,
      );

      // Underdog should be 50-150 ELO below player
      expect(bot.skillLevel, greaterThanOrEqualTo(1050));
      expect(bot.skillLevel, lessThanOrEqualTo(1150));
      expect(bot.difficulty, BotDifficulty.underdog);
    });

    test('Bot opponent has correct ELO range for Boss', () {
      final stats = PlayerStats(totalGames: 10, currentWinStreak: 6);

      // Run multiple times to likely get a Boss bot
      bool foundBoss = false;
      for (int i = 0; i < 20 && !foundBoss; i++) {
        final bot = matchmaking.createBotOpponent(
          playerElo: 1200,
          stats: stats,
          isFirstRankedMatch: false,
        );

        if (bot.difficulty == BotDifficulty.boss) {
          foundBoss = true;
          // Boss should be 50-150 ELO above player
          expect(bot.skillLevel, greaterThanOrEqualTo(1250));
          expect(bot.skillLevel, lessThanOrEqualTo(1350));
        }
      }

      expect(foundBoss, true,
          reason: 'Should have found at least one Boss bot');
    });

    test('Win probability is calculated correctly', () {
      final stats = PlayerStats();

      // Equal ELO, Competitive bot should be ~50%
      final prob1 = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: 1200,
        botDifficulty: BotDifficulty.competitive,
        stats: stats,
      );
      expect(prob1, closeTo(0.5, 0.1));

      // Underdog bot should increase win probability
      final prob2 = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: 1100,
        botDifficulty: BotDifficulty.underdog,
        stats: stats,
      );
      expect(prob2, greaterThan(0.6));

      // Boss bot should decrease win probability
      final prob3 = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: 1300,
        botDifficulty: BotDifficulty.boss,
        stats: stats,
      );
      expect(prob3, lessThan(0.4));
    });

    test('Streak affects win probability', () {
      final statsWinStreak = PlayerStats(currentWinStreak: 4);
      final statsLoseStreak = PlayerStats(currentLoseStreak: 4);

      final probWinStreak = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: 1200,
        botDifficulty: BotDifficulty.competitive,
        stats: statsWinStreak,
      );

      final probLoseStreak = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: 1200,
        botDifficulty: BotDifficulty.competitive,
        stats: statsLoseStreak,
      );

      // Win streak should give higher probability
      expect(probWinStreak, greaterThan(probLoseStreak));
    });

    test('Should match with bot on first ranked match', () {
      final stats = PlayerStats(totalGames: 0);

      final shouldUseBot = matchmaking.shouldMatchWithBot(
        stats: stats,
        isFirstRankedMatch: true,
        queueTimeSeconds: 5,
        realPlayersAvailable: true,
      );

      expect(shouldUseBot, true);
    });

    test('Should match with bot when no real players available', () {
      final stats = PlayerStats();

      final shouldUseBot = matchmaking.shouldMatchWithBot(
        stats: stats,
        isFirstRankedMatch: false,
        queueTimeSeconds: 5,
        realPlayersAvailable: false,
      );

      expect(shouldUseBot, true);
    });

    test('Should match with bot after long queue time', () {
      final stats = PlayerStats();

      final shouldUseBot = matchmaking.shouldMatchWithBot(
        stats: stats,
        isFirstRankedMatch: false,
        queueTimeSeconds: 20, // > 15 seconds
        realPlayersAvailable: true,
      );

      expect(shouldUseBot, true);
    });
  });

  group('Integration Tests', () {
    test('Complete placement flow', () {
      final results = <PlacementMatchResult>[];

      // Match 1
      results.add(PlacementMatchResult(
        matchNumber: 1,
        puzzleType: PuzzleType.basic,
        correctAnswers: 8,
        totalQuestions: 10,
        responseTimes: List.filled(10, 3500),
        won: true,
      ));

      // Match 2
      results.add(PlacementMatchResult(
        matchNumber: 2,
        puzzleType: PuzzleType.complex,
        correctAnswers: 7,
        totalQuestions: 10,
        responseTimes: List.filled(10, 4500),
        won: true,
      ));

      // Match 3
      results.add(PlacementMatchResult(
        matchNumber: 3,
        puzzleType: PuzzleType.game24,
        correctAnswers: 6,
        totalQuestions: 10,
        responseTimes: List.filled(10, 6000),
        won: false,
      ));

      final elo = PlacementManager.calculateInitialElo(results);
      expect(elo, inInclusiveRange(800, 1600));

      final message =
          PlacementManager.getPlacementCompleteMessage(elo, results);
      expect(message, isNotEmpty);

      final rankTitle = PlacementManager.getInitialRankTitle(elo);
      expect(rankTitle, isNotEmpty);
    });

    test('Bot adapts to player performance during match', () {
      final bot = BotAI(
        name: 'TestBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      final puzzle = BasicPuzzle(
        id: 'test-adapt',
        targetValue: 8,
        numberA: 5,
        numberB: 3,
        operator: '+',
      );

      // Player starts slow
      bot.recordPlayerResponseTime(6000);
      final delay1 = bot.calculateDynamicDelay(puzzle);

      // Player gets faster
      for (int i = 0; i < 10; i++) {
        bot.recordPlayerResponseTime(3000);
      }
      final delay2 = bot.calculateDynamicDelay(puzzle);

      // Bot should adapt to faster times
      expect(delay2.inMilliseconds, lessThanOrEqualTo(delay1.inMilliseconds));
    });

    test('Complete ranked match flow with adaptive bot', () {
      final matchmaking = MatchmakingLogic();

      // Scenario: Player on LoseStreak
      final stats = PlayerStats(
        totalGames: 10,
        wins: 3,
        losses: 7,
        currentLoseStreak: 3,
      );

      // Create bot (should be Underdog)
      final bot = matchmaking.createBotOpponent(
        playerElo: 1200,
        stats: stats,
        isFirstRankedMatch: false,
      );

      expect(bot.difficulty, BotDifficulty.underdog);
      expect(bot.skillLevel, lessThan(1200));

      // Predict win probability (should be high)
      final winProb = matchmaking.predictWinProbability(
        playerElo: 1200,
        opponentElo: bot.skillLevel,
        botDifficulty: bot.difficulty,
        stats: stats,
      );

      expect(winProb, greaterThan(0.6)); // High chance to win and break streak
    });
  });
}
