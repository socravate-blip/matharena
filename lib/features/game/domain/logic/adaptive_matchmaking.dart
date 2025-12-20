import 'dart:math';
import 'bot_ai.dart';
import '../models/player_stats.dart';
import '../models/puzzle.dart';

/// Matchmaking service that creates fair and engaging matches
/// Adapts bot difficulty based on player performance and psychological state
class AdaptiveMatchmaking {
  final Random _random = Random();

  /// Select appropriate bot difficulty based on player's current state
  /// 
  /// Logic:
  /// - Lose streak (3+): Force Underdog (boost confidence)
  /// - Lose streak (2): 70% Underdog, 30% Competitive
  /// - Win streak (5+): 60% Boss, 40% Competitive (keep challenge)
  /// - Win streak (3-4): 50% Competitive, 50% Boss
  /// - First ranked match after placement: Never Boss
  /// - Normal state: 20% Underdog, 60% Competitive, 20% Boss
  BotDifficulty selectBotDifficulty({
    required PlayerStats stats,
    required bool isFirstRankedMatch,
  }) {
    // First Win Experience: Guarantee positive outcome
    if (isFirstRankedMatch) {
      // 70% Underdog, 30% Competitive for first match
      return _random.nextDouble() < 0.7 
        ? BotDifficulty.underdog 
        : BotDifficulty.competitive;
    }

    // Handle lose streaks (psychological recovery)
    if (stats.currentLoseStreak >= 3) {
      // Strong lose streak: Always Underdog
      return BotDifficulty.underdog;
    } else if (stats.currentLoseStreak == 2) {
      // Medium lose streak: Mostly Underdog
      return _random.nextDouble() < 0.7 
        ? BotDifficulty.underdog 
        : BotDifficulty.competitive;
    }

    // Handle win streaks (maintain engagement)
    if (stats.currentWinStreak >= 5) {
      // Long win streak: Increase challenge
      return _random.nextDouble() < 0.6 
        ? BotDifficulty.boss 
        : BotDifficulty.competitive;
    } else if (stats.currentWinStreak >= 3) {
      // Medium win streak: Mix of challenge
      return _random.nextDouble() < 0.5 
        ? BotDifficulty.competitive 
        : BotDifficulty.boss;
    }

    // Normal distribution for balanced players
    final roll = _random.nextDouble();
    if (roll < 0.20) {
      return BotDifficulty.underdog;
    } else if (roll < 0.80) {
      return BotDifficulty.competitive;
    } else {
      return BotDifficulty.boss;
    }
  }

  /// Create a bot opponent with adaptive difficulty
  /// 
  /// Returns a BotAI configured with appropriate skill level and difficulty
  BotAI createBotOpponent({
    required int playerElo,
    required PlayerStats stats,
    required bool isFirstRankedMatch,
  }) {
    final difficulty = selectBotDifficulty(
      stats: stats,
      isFirstRankedMatch: isFirstRankedMatch,
    );

    // Adjust bot ELO based on difficulty
    int botElo;
    switch (difficulty) {
      case BotDifficulty.underdog:
        // Bot is 50-150 ELO below player
        botElo = playerElo - (50 + _random.nextInt(100));
        break;
      case BotDifficulty.competitive:
        // Bot is within ±75 ELO of player
        botElo = playerElo + (_random.nextInt(150) - 75);
        break;
      case BotDifficulty.boss:
        // Bot is 50-150 ELO above player
        botElo = playerElo + (50 + _random.nextInt(100));
        break;
    }

    // Ensure bot ELO stays within valid range
    botElo = botElo.clamp(800, 2000);

    return BotAI.matchingSkill(botElo, difficulty: difficulty);
  }

  /// Determine if player should be matched with bot or real player
  /// 
  /// Factors:
  /// - First ranked match: Always bot
  /// - Lose streak: Prefer bot (easier to control outcome)
  /// - Win streak: Prefer real players (more engaging)
  /// - Queue time: If no real players available, use bot
  bool shouldMatchWithBot({
    required PlayerStats stats,
    required bool isFirstRankedMatch,
    required int queueTimeSeconds,
    required bool realPlayersAvailable,
  }) {
    // Always bot for first match
    if (isFirstRankedMatch) return true;

    // Always bot if no real players available
    if (!realPlayersAvailable) return true;

    // High lose streak: Prefer bot for confidence boost
    if (stats.currentLoseStreak >= 2) {
      return _random.nextDouble() < 0.7; // 70% bot
    }

    // Long win streak: Prefer real players for engagement
    if (stats.currentWinStreak >= 4) {
      return _random.nextDouble() < 0.3; // 30% bot
    }

    // Long queue time: Use bot to avoid frustration
    if (queueTimeSeconds > 15) {
      return true;
    }

    // Normal case: 50/50 split
    return _random.nextDouble() < 0.5;
  }

  /// Get recommended puzzle types for current match
  /// Based on player performance history
  List<PuzzleType> getRecommendedPuzzleTypes(PlayerStats stats) {
    final List<PuzzleType> types = [];

    // Analyze performance by puzzle type
    if (stats.basicStats.accuracy >= 80) types.add(PuzzleType.basic);
    if (stats.complexStats.accuracy >= 70) types.add(PuzzleType.complex);
    if (stats.game24Stats.accuracy >= 50) types.add(PuzzleType.game24);
    if (stats.mathadoreStats.accuracy >= 40) types.add(PuzzleType.matador);

    // If no strong areas, default to all types
    if (types.isEmpty) {
      return [
        PuzzleType.basic,
        PuzzleType.complex,
        PuzzleType.game24,
        PuzzleType.matador,
      ];
    }

    return types;
  }

  /// Predict match outcome probability for analytics
  /// Returns probability that player will win (0.0 to 1.0)
  double predictWinProbability({
    required int playerElo,
    required int opponentElo,
    required BotDifficulty botDifficulty,
    required PlayerStats stats,
  }) {
    // Base probability from ELO difference
    final eloDiff = playerElo - opponentElo;
    double baseProbability = 1.0 / (1.0 + pow(10, -eloDiff / 400));

    // Adjust for bot difficulty (bots are more predictable)
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

    // Adjust for current form (streaks)
    if (stats.currentWinStreak >= 3) {
      baseProbability += 0.05; // Momentum bonus
    } else if (stats.currentLoseStreak >= 3) {
      baseProbability -= 0.05; // Confidence penalty
    }

    return baseProbability.clamp(0.0, 1.0);
  }

  /// Get match summary for logging/analytics
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
      'matchType': isFirstRankedMatch ? 'First Win Experience' : 'Normal',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Extension on PlayerStats to get puzzle type stats easily
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
