import 'dart:math';

import '../models/player_stats.dart';
import '../models/puzzle.dart';
import 'bot_ai.dart';

/// Engagement Director / matchmaking logic.
///
/// This is the single source of truth for bot selection, difficulty,
/// and related helper analytics.
class MatchmakingLogic {
  final Random _random = Random();

  /// Selects bot difficulty based on recent streaks (Engagement Director rules).
  ///
  /// 1) First ranked match (or totalGames==0): 70% underdog, 30% competitive
  /// 2) Lose streak >= 3: always underdog ("Hard Pity Win")
  /// 3) Lose streak == 2: 90% underdog, 10% competitive ("Pity Win")
  /// 3) Win streak >= 3: 80% boss, 20% competitive ("Boss Challenge")
  /// 4) Otherwise: 50% competitive, 25% underdog, 25% boss
  BotDifficulty selectBotDifficulty({
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  }) {
    if (isFirstRankedMatch || stats.totalGames == 0) {
      return _random.nextDouble() < 0.7
          ? BotDifficulty.underdog
          : BotDifficulty.competitive;
    }

    final loseStreak = stats.currentLoseStreak;
    final winStreak = stats.currentWinStreak;

    if (loseStreak >= 3) {
      return BotDifficulty.underdog;
    }

    if (loseStreak == 2) {
      return _random.nextDouble() < 0.90
          ? BotDifficulty.underdog
          : BotDifficulty.competitive;
    }

    if (winStreak >= 3) {
      return _random.nextDouble() < 0.80
          ? BotDifficulty.boss
          : BotDifficulty.competitive;
    }

    final roll = _random.nextDouble();
    if (roll < 0.50) return BotDifficulty.competitive;
    if (roll < 0.75) return BotDifficulty.underdog;
    return BotDifficulty.boss;
  }

  /// Creates a bot opponent with adaptive skill around the player.
  BotAI createBotOpponent({
    required int playerElo,
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  }) {
    final difficulty = selectBotDifficulty(
      stats: stats,
      isFirstRankedMatch: isFirstRankedMatch,
    );

    int botElo;
    switch (difficulty) {
      case BotDifficulty.underdog:
        botElo = playerElo - (50 + _random.nextInt(100));
        break;
      case BotDifficulty.competitive:
        botElo = playerElo + (_random.nextInt(150) - 75);
        break;
      case BotDifficulty.boss:
        botElo = playerElo + (50 + _random.nextInt(100));
        break;
    }

    botElo = botElo.clamp(800, 2000);
    return BotAI.matchingSkill(botElo, difficulty: difficulty);
  }

  /// Determines whether we should fallback to a bot.
  bool shouldMatchWithBot({
    required PlayerStats stats,
    required bool isFirstRankedMatch,
    required int queueTimeSeconds,
    required bool realPlayersAvailable,
  }) {
    if (isFirstRankedMatch) return true;
    if (!realPlayersAvailable) return true;

    if (stats.currentLoseStreak >= 2) {
      return _random.nextDouble() < 0.7;
    }

    if (stats.currentWinStreak >= 4) {
      return _random.nextDouble() < 0.3;
    }

    if (queueTimeSeconds > 15) return true;

    return _random.nextDouble() < 0.5;
  }

  /// Recommended puzzle types based on the player's strengths.
  List<PuzzleType> getRecommendedPuzzleTypes(PlayerStats stats) {
    final List<PuzzleType> types = [];

    if (stats.basicStats.accuracy >= 80) types.add(PuzzleType.basic);
    if (stats.complexStats.accuracy >= 70) types.add(PuzzleType.complex);
    if (stats.game24Stats.accuracy >= 50) types.add(PuzzleType.game24);
    if (stats.mathadoreStats.accuracy >= 40) types.add(PuzzleType.matador);

    if (types.isEmpty) {
      return const [
        PuzzleType.basic,
        PuzzleType.complex,
        PuzzleType.game24,
        PuzzleType.matador,
      ];
    }

    return types;
  }

  /// Predicts win probability for analytics.
  double predictWinProbability({
    required int playerElo,
    required int opponentElo,
    required BotDifficulty botDifficulty,
    required PlayerStats stats,
  }) {
    final eloDiff = playerElo - opponentElo;
    double baseProbability = 1.0 / (1.0 + pow(10, -eloDiff / 400));

    switch (botDifficulty) {
      case BotDifficulty.underdog:
        baseProbability = (baseProbability * 1.2).clamp(0.6, 0.95);
        break;
      case BotDifficulty.competitive:
        baseProbability = (baseProbability * 1.0).clamp(0.4, 0.6);
        break;
      case BotDifficulty.boss:
        baseProbability = (baseProbability * 0.8).clamp(0.2, 0.5);
        break;
    }

    if (stats.currentWinStreak >= 3) {
      baseProbability += 0.05;
    } else if (stats.currentLoseStreak >= 3) {
      baseProbability -= 0.05;
    }

    return baseProbability.clamp(0.0, 1.0);
  }

  /// Builds a match summary for logging/analytics.
  Map<String, dynamic> getMatchSummary({
    required int playerElo,
    required BotAI bot,
    required PlayerStats stats,
    required bool isFirstRankedMatch,
  }) {
    final winProbability = predictWinProbability(
      playerElo: playerElo,
      opponentElo: bot.skillLevel,
      botDifficulty: bot.difficulty,
      stats: stats,
    );

    return {
      'playerElo': playerElo,
      'botName': bot.name,
      'botElo': bot.skillLevel,
      'botDifficulty': bot.difficulty.toString(),
      'isFirstRankedMatch': isFirstRankedMatch,
      'playerStreak': stats.currentStreak,
      'predictedWinRate': winProbability,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

extension PuzzleTypeStatsExtension on PlayerStats {
  PuzzleTypeStats getStatsForType(PuzzleType type) {
    switch (type) {
      case PuzzleType.basic:
        return basicStats;
      case PuzzleType.complex:
        return complexStats;
      case PuzzleType.game24:
        return game24Stats;
      case PuzzleType.matador:
        return mathadoreStats;
    }
  }
}
