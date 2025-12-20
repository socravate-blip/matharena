import 'dart:math';
import 'bot_ai.dart';
import '../models/player_stats.dart';

/// Résultat d'un match pour l'historique
class MatchResult {
  final bool isWin;
  final bool isDraw;
  final int playerScore;
  final int opponentScore;
  final DateTime timestamp;

  MatchResult({
    required this.isWin,
    required this.isDraw,
    required this.playerScore,
    required this.opponentScore,
    required this.timestamp,
  });
}

/// Engagement Director - Sélection intelligente de bot
/// pour maximiser la rétention en fonction de l'historique récent
class SmartMatchmakingLogic {
  final Random _random = Random();

  /// Sélectionne la difficulté du bot basé sur l'historique récent (5 derniers matchs)
  /// 
  /// **Règles de l'Engagement Director:**
  /// 
  /// 1. **Lose Streak >= 2:** 90% chance de bot Underdog ("Pity Win")
  /// 2. **Win Streak >= 3:** 80% chance de bot Boss (Challenge)
  /// 3. **Cas Standard:** Roue de la fortune pondérée:
  ///    - 50% Competitive (Match serré)
  ///    - 25% Underdog (Joueur se sent fort)
  ///    - 25% Boss (Challenge)
  BotDifficulty selectBotDifficulty({
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  }) {
    // Premier match classé : Favorise le succès
    if (isFirstRankedMatch || stats.totalGames == 0) {
      return _random.nextDouble() < 0.7
          ? BotDifficulty.underdog
          : BotDifficulty.competitive;
    }

    // Analyse des streaks actuels
    final loseStreak = stats.currentLoseStreak;
    final winStreak = stats.currentWinStreak;

    // === RÈGLE 1: Lose Streak Protection (Pity Win) ===
    if (loseStreak >= 2) {
      print('🛡️ Engagement Director: LOSE STREAK DETECTED ($loseStreak)');
      print('   → Forcing Underdog bot (90% chance)');
      // 90% Underdog pour redonner confiance
      return _random.nextDouble() < 0.90
          ? BotDifficulty.underdog
          : BotDifficulty.competitive;
    }

    // === RÈGLE 2: Win Streak Challenge ===
    if (winStreak >= 3) {
      print('🔥 Engagement Director: WIN STREAK DETECTED ($winStreak)');
      print('   → Forcing Boss bot (80% chance)');
      // 80% Boss pour maintenir le défi
      return _random.nextDouble() < 0.80
          ? BotDifficulty.boss
          : BotDifficulty.competitive;
    }

    // === RÈGLE 3: Roue de la Fortune Pondérée (Cas Standard) ===
    print('⚖️ Engagement Director: STANDARD CASE');
    final roll = _random.nextDouble();

    if (roll < 0.50) {
      // 50% Competitive
      print('   → Rolled Competitive (50%)');
      return BotDifficulty.competitive;
    } else if (roll < 0.75) {
      // 25% Underdog
      print('   → Rolled Underdog (25%)');
      return BotDifficulty.underdog;
    } else {
      // 25% Boss
      print('   → Rolled Boss (25%)');
      return BotDifficulty.boss;
    }
  }

  /// Crée un bot avec la difficulté sélectionnée
  BotAI createBotOpponent({
    required int playerElo,
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  }) {
    final difficulty = selectBotDifficulty(
      stats: stats,
      isFirstRankedMatch: isFirstRankedMatch,
    );

    // Ajuster l'ELO du bot selon la difficulté
    int botElo;
    switch (difficulty) {
      case BotDifficulty.underdog:
        // Bot 50-150 ELO en dessous du joueur
        botElo = playerElo - (50 + _random.nextInt(100));
        break;
      case BotDifficulty.competitive:
        // Bot dans ±75 ELO du joueur
        botElo = playerElo + (_random.nextInt(150) - 75);
        break;
      case BotDifficulty.boss:
        // Bot 50-150 ELO au-dessus du joueur
        botElo = playerElo + (50 + _random.nextInt(100));
        break;
    }

    // Limiter l'ELO dans les bornes valides
    botElo = botElo.clamp(800, 2000);

    print('🤖 Creating bot: ELO $botElo, Difficulty: ${difficulty.name}');
    return BotAI.matchingSkill(botElo, difficulty: difficulty);
  }

  /// Analyse l'historique des derniers matchs
  /// Retourne les statistiques pour le logging/debug
  Map<String, dynamic> analyzeRecentHistory(PlayerStats stats) {
    return {
      'total_games': stats.totalGames,
      'current_win_streak': stats.currentWinStreak,
      'current_lose_streak': stats.currentLoseStreak,
      'win_rate': stats.winRate.toStringAsFixed(1),
      'best_win_streak': stats.bestWinStreak,
      'best_lose_streak': stats.bestLoseStreak,
    };
  }

  /// Détermine si le joueur devrait jouer contre un bot ou un vrai joueur
  /// (Utile pour la logique de matchmaking timeout)
  bool shouldMatchWithBot({
    required PlayerStats stats,
    required bool isFirstRankedMatch,
    required int queueTimeSeconds,
    required bool realPlayersAvailable,
  }) {
    // Toujours bot pour le premier match
    if (isFirstRankedMatch) return true;

    // Toujours bot si pas de vrais joueurs disponibles
    if (!realPlayersAvailable) return true;

    // Lose streak élevé : Préfère bot (plus contrôlable)
    if (stats.currentLoseStreak >= 2) {
      return _random.nextDouble() < 0.7; // 70% bot
    }

    // Win streak élevé : Préfère vrais joueurs (plus engageant)
    if (stats.currentWinStreak >= 4) {
      return _random.nextDouble() < 0.3; // 30% bot
    }

    // Temps d'attente long : Utilise bot
    if (queueTimeSeconds > 15) {
      return true;
    }

    // Cas normal : 50/50
    return _random.nextDouble() < 0.5;
  }
}
