import 'dart:async';
import 'dart:math';
import '../logic/bot_ai.dart';
import '../logic/bot_persona_generator.dart';
import '../logic/matchmaking_logic.dart';
import '../logic/puzzle_generator.dart';
import '../models/player_stats.dart';
import '../models/puzzle.dart';
import '../models/match_model.dart';
import '../models/match_constants.dart';

/// Service qui orchestre le "Ghost Protocol" - Le bot simule un vrai match Firebase
/// L'UI ne fait AUCUNE différence entre un vrai joueur et un bot
class GhostMatchOrchestrator {
  final MatchmakingLogic _matchmaking;

  GhostMatchOrchestrator(this._matchmaking);

  /// Crée un faux match "Firebase-like" avec un bot
  /// Retourne toutes les données nécessaires pour que l'UI pense que c'est un vrai match
  Future<GhostMatchData> createGhostMatch({
    required int playerElo,
    required String playerId,
    PlayerStats? playerStats,
    BotDifficulty? forcedDifficulty, // Debug: forcer une difficulté spécifique
  }) async {
    // 1. Sélectionner la difficulté du bot (forcée OU adaptative)
    // IMPORTANT: Si forcedDifficulty est fournie, elle est PRIORITAIRE
    BotDifficulty difficulty;
    
    if (forcedDifficulty != null) {
      difficulty = forcedDifficulty;
      print('🎮 Using FORCED difficulty: ${difficulty.name}');
    } else {
      difficulty = _matchmaking.selectBotDifficulty(
        stats: playerStats ?? const PlayerStats(),
        isFirstRankedMatch: (playerStats?.totalGames ?? 0) == 0,
      );
    }

    // 2. Créer le bot avec ce niveau
    // IMPORTANT: On force l'utilisation de la difficulté choisie ci-dessus
    // en créant le bot directement au lieu de passer par createBotOpponent
    final bot = _createBotWithDifficulty(
      playerElo: playerElo,
      difficulty: difficulty,
    );

    // 3. Générer le faux profil du bot (Ghost Protocol)
    final botPersona = BotPersonaGenerator.generate(
      playerElo: playerElo,
      difficulty: difficulty.toString().split('.').last,
    );

    // 4. Générer les puzzles pour le match
    final puzzles = PuzzleGenerator.generateByElo(
      averageElo: (playerElo + bot.skillLevel) ~/ 2,
      count: 15,
    );

    // 5. Créer un faux Match Model (comme Firebase le ferait)
    final ghostMatch = _createGhostMatchModel(
      playerId: playerId,
      botPersona: botPersona,
      puzzles: puzzles,
    );

    // 6. Calculer l'average historique du joueur pour le bot
    final playerAvgResponseTime =
        BotPersonaGenerator.calculatePlayerAverageResponseTime(playerStats);

    return GhostMatchData(
      bot: bot,
      botPersona: botPersona,
      match: ghostMatch,
      puzzles: puzzles,
      playerHistoricalAvgMs: (playerAvgResponseTime * 1000).toInt(),
    );
  }

  /// Crée un faux MatchModel qui ressemble à un match Firebase
  MatchModel _createGhostMatchModel({
    required String playerId,
    required BotPersona botPersona,
    required List<GamePuzzle> puzzles,
  }) {
    // Générer un faux match ID (Firebase-like)
    final matchId = _generateFakeMatchId();

    // Convertir puzzles en Map format
    final puzzleMaps = puzzles.map((p) => p.toJson()).toList();

    // Créer PlayerData pour le bot (Ghost)
    final botPlayerData = PlayerData(
      uid: botPersona.userId,
      nickname: botPersona.displayName,
      elo: botPersona.currentRating,
      score: 0,
      progress: 0.0,
      status: 'active',
    );

    // Player1 sera rempli avec les vraies données du joueur par l'appelant
    final playerData = PlayerData(
      uid: playerId,
      nickname: 'Player', // Temporaire, sera override
      elo: 0, // Sera override
      score: 0,
      progress: 0.0,
      status: 'active',
    );

    return MatchModel(
      matchId: matchId,
      status: MatchConstants.matchStarting, // Commence en "starting" comme Firebase
      createdAt: DateTime.now().millisecondsSinceEpoch,
      puzzles: puzzleMaps,
      player1: playerData,
      player2: botPlayerData, // Le bot en player2
    );
  }

  /// Génère un faux Match ID au format Firebase
  String _generateFakeMatchId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'ghost_${timestamp}_$random';
  }

  /// Crée un bot avec une difficulté spécifique (utilisé pour forcer la difficulté)
  /// Contourne l'algorithme d'Engagement Director (MatchmakingLogic)
  BotAI _createBotWithDifficulty({
    required int playerElo,
    required BotDifficulty difficulty,
  }) {
    // Ajuster l'ELO du bot selon la difficulté choisie
    int botElo;
    final random = Random();
    
    switch (difficulty) {
      case BotDifficulty.underdog:
        // Bot est 50-150 ELO en dessous du joueur
        botElo = playerElo - (50 + random.nextInt(100));
        break;
      case BotDifficulty.competitive:
        // Bot est dans ±75 ELO du joueur
        botElo = playerElo + (random.nextInt(150) - 75);
        break;
      case BotDifficulty.boss:
        // Bot est 50-150 ELO au-dessus du joueur
        botElo = playerElo + (50 + random.nextInt(100));
        break;
    }

    // S'assurer que l'ELO reste dans les limites valides
    botElo = botElo.clamp(800, 2000);

    // Créer le bot avec la difficulté spécifique
    return BotAI.matchingSkill(botElo, difficulty: difficulty);
  }

  /// Simule la réponse du bot après un délai adaptatif
  /// IMPORTANT: Ne fait PAS d'attente ici, retourne juste le temps et le résultat
  /// L'attente est gérée par le Timer dans ranked_multiplayer_page
  /// 
  /// Le bot peut échouer avec une probabilité réaliste (accuracy) et perd du temps
  /// en cas d'erreur ("correction"), comme un humain.
  BotResponse simulateBotResponse({
    required BotAI bot,
    required GamePuzzle puzzle,
    required int playerHistoricalAvgMs,
  }) {
    // 1. Calculer le délai adaptatif avec caps réalistes
    final delay = bot.calculateDynamicDelay(
      puzzle,
      playerHistoricalAvgMs: playerHistoricalAvgMs,
    );

    // 2. Probabilité d'erreur réaliste + pénalité de correction
    final isCorrect = bot.rollIsCorrect(puzzle);
    final penaltyMs = isCorrect ? 0 : bot.mistakePenaltyMs(puzzle);

    return BotResponse(
      isCorrect: isCorrect,
      responseTimeMs: delay.inMilliseconds + penaltyMs,
    );
  }
}

/// Données pour un match Ghost (Bot simulant Firebase)
class GhostMatchData {
  final BotAI bot;
  final BotPersona botPersona;
  final MatchModel match;
  final List<GamePuzzle> puzzles;
  final int playerHistoricalAvgMs;

  GhostMatchData({
    required this.bot,
    required this.botPersona,
    required this.match,
    required this.puzzles,
    required this.playerHistoricalAvgMs,
  });
}

/// Réponse du bot à un puzzle
class BotResponse {
  final bool isCorrect;
  final int responseTimeMs;

  BotResponse({
    required this.isCorrect,
    required this.responseTimeMs,
  });
}
