import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/bot_ai.dart';
import '../logic/matchmaking_logic.dart';
import '../models/player_stats.dart';
import '../models/puzzle.dart';
import '../logic/puzzle_generator.dart';
import '../../presentation/providers/adaptive_providers.dart';

/// Service qui gère le timeout du matchmaking multijoueur
/// Si aucun adversaire n'est trouvé après 5 secondes, lance un match contre un bot
class MatchmakingTimeoutService {
  final MatchmakingLogic _matchmaking;
  Timer? _timeoutTimer;

  MatchmakingTimeoutService(this._matchmaking);

  /// Démarre le timer de timeout
  /// Callback appelé après [timeoutSeconds] secondes si non annulé
  void startTimeout({
    required int timeoutSeconds,
    required VoidCallback onTimeout,
  }) {
    // Annuler le timer précédent s'il existe
    cancelTimeout();

    print('⏱️ Démarrage du timer matchmaking: ${timeoutSeconds}s');

    _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
      print(
          '⏰ Timeout matchmaking atteint! Création d\'un match contre bot...');
      onTimeout();
    });
  }

  /// Annule le timer de timeout
  void cancelTimeout() {
    if (_timeoutTimer != null && _timeoutTimer!.isActive) {
      print('❌ Annulation du timer matchmaking');
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
    }
  }

  /// Crée un match contre un bot adaptatif
  BotMatchData createBotMatch({
    required int playerElo,
    required PlayerStats playerStats,
    required bool isFirstRankedMatch,
  }) {
    // Créer le bot avec difficulté adaptative
    final bot = _matchmaking.createBotOpponent(
      playerElo: playerElo,
      stats: playerStats,
      isFirstRankedMatch: isFirstRankedMatch,
    );

    // Générer les puzzles selon l'ELO
    final puzzles = PuzzleGenerator.generateByElo(
      count: 25,
      averageElo: playerElo,
    );

    print('🤖 Match contre bot créé:');
    print('  - Bot: ${bot.name} (${bot.skillLevel} ELO)');
    print('  - Difficulté: ${bot.difficulty.name}');
    print('  - Puzzles: ${puzzles.length}');

    return BotMatchData(
      bot: bot,
      puzzles: puzzles,
      playerElo: playerElo,
    );
  }

  /// Dispose le service
  void dispose() {
    cancelTimeout();
  }
}

/// Données d'un match contre un bot
class BotMatchData {
  final BotAI bot;
  final List<GamePuzzle> puzzles;
  final int playerElo;

  const BotMatchData({
    required this.bot,
    required this.puzzles,
    required this.playerElo,
  });
}

/// Provider du service de timeout
final matchmakingTimeoutServiceProvider =
    Provider<MatchmakingTimeoutService>((ref) {
  final matchmaking = ref.watch(adaptiveMatchmakingProvider);
  return MatchmakingTimeoutService(matchmaking);
});

/// Provider pour l'état du matchmaking
class MatchmakingState {
  final bool isSearching;
  final bool hasTimedOut;
  final int elapsedSeconds;
  final BotMatchData? botMatch;

  const MatchmakingState({
    this.isSearching = false,
    this.hasTimedOut = false,
    this.elapsedSeconds = 0,
    this.botMatch,
  });

  MatchmakingState copyWith({
    bool? isSearching,
    bool? hasTimedOut,
    int? elapsedSeconds,
    BotMatchData? botMatch,
  }) {
    return MatchmakingState(
      isSearching: isSearching ?? this.isSearching,
      hasTimedOut: hasTimedOut ?? this.hasTimedOut,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      botMatch: botMatch ?? this.botMatch,
    );
  }
}

/// Notifier pour gérer l'état du matchmaking avec timeout
class MatchmakingNotifier extends StateNotifier<MatchmakingState> {
  final MatchmakingTimeoutService _timeoutService;
  Timer? _elapsedTimer;

  MatchmakingNotifier(this._timeoutService) : super(const MatchmakingState());

  /// Démarre la recherche de match avec timeout
  void startSearching({
    required int timeoutSeconds,
    required int playerElo,
    required PlayerStats playerStats,
    required bool isFirstRankedMatch,
    VoidCallback? onMatchFound,
  }) {
    state = const MatchmakingState(isSearching: true);

    // Timer pour compter les secondes écoulées
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(elapsedSeconds: timer.tick);
      }
    });

    // Timer de timeout
    _timeoutService.startTimeout(
      timeoutSeconds: timeoutSeconds,
      onTimeout: () {
        if (mounted) {
          _handleTimeout(
            playerElo: playerElo,
            playerStats: playerStats,
            isFirstRankedMatch: isFirstRankedMatch,
          );
        }
      },
    );
  }

  /// Gère le timeout (crée un match contre bot)
  void _handleTimeout({
    required int playerElo,
    required PlayerStats playerStats,
    required bool isFirstRankedMatch,
  }) {
    final botMatch = _timeoutService.createBotMatch(
      playerElo: playerElo,
      playerStats: playerStats,
      isFirstRankedMatch: isFirstRankedMatch,
    );

    state = state.copyWith(
      isSearching: false,
      hasTimedOut: true,
      botMatch: botMatch,
    );

    _cleanup();
  }

  /// Appelé quand un adversaire réel est trouvé
  void onRealPlayerFound() {
    _timeoutService.cancelTimeout();
    state = state.copyWith(isSearching: false);
    _cleanup();
  }

  /// Annule la recherche
  void cancelSearch() {
    _timeoutService.cancelTimeout();
    state = const MatchmakingState();
    _cleanup();
  }

  void _cleanup() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  @override
  void dispose() {
    _cleanup();
    _timeoutService.dispose();
    super.dispose();
  }
}

/// Provider du notifier de matchmaking
final matchmakingNotifierProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>((ref) {
  final timeoutService = ref.watch(matchmakingTimeoutServiceProvider);
  return MatchmakingNotifier(timeoutService);
});
