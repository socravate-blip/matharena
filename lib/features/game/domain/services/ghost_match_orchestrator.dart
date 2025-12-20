import 'dart:async';
import 'dart:math';
import '../logic/bot_ai.dart';
import '../logic/bot_persona_generator.dart';
import '../logic/adaptive_matchmaking.dart';
import '../logic/puzzle_generator.dart';
import '../models/player_stats.dart';
import '../models/puzzle.dart';
import '../models/match_model.dart';

/// Service qui orchestre le "Ghost Protocol" - Le bot simule un vrai match Firebase
/// L'UI ne fait AUCUNE différence entre un vrai joueur et un bot
class GhostMatchOrchestrator {
  final AdaptiveMatchmaking _matchmaking;
  final PuzzleGenerator _puzzleGenerator;

  GhostMatchOrchestrator(this._matchmaking, this._puzzleGenerator);

  /// Crée un faux match "Firebase-like" avec un bot
  /// Retourne toutes les données nécessaires pour que l'UI pense que c'est un vrai match
  Future<GhostMatchData> createGhostMatch({
    required int playerElo,
    required String playerId,
    PlayerStats? playerStats,
    BotDifficulty? forcedDifficulty, // Debug: forcer une difficulté spécifique
  }) async {
    // 1. Sélectionner la difficulté du bot (psychologie adaptative OU forcée)
    final difficulty = forcedDifficulty ??
        _matchmaking.selectBotDifficulty(
          stats: playerStats ?? const PlayerStats(),
          isFirstRankedMatch: (playerStats?.totalGames ?? 0) == 0,
        );

    // 2. Créer le bot avec ce niveau
    final bot = _matchmaking.createBotOpponent(
      playerElo: playerElo,
      stats: playerStats ?? const PlayerStats(),
      isFirstRankedMatch: (playerStats?.totalGames ?? 0) == 0,
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
      status: 'starting', // Commence en "starting" comme Firebase
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

  /// Simule la réponse du bot après un délai adaptatif
  /// IMPORTANT: Ne fait PAS d'attente ici, retourne juste le temps et le résultat
  /// L'attente est gérée par le Timer dans ranked_multiplayer_page
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

    // 2. Déterminer si le bot réussit
    final probability = bot.getSuccessProbability(puzzle);
    final success = Random().nextDouble() < probability;

    return BotResponse(
      isCorrect: success,
      responseTimeMs: delay.inMilliseconds,
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
