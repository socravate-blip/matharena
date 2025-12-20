import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/placement_manager.dart';
import '../../domain/logic/matchmaking_logic.dart';
import '../../domain/logic/bot_ai.dart';
import '../../domain/models/player_stats.dart';
import '../../domain/models/puzzle.dart';

// ============================================================================
// PLACEMENT SYSTEM PROVIDERS
// ============================================================================

/// Provider for placement state
final placementStateProvider = StateNotifierProvider<PlacementNotifier, PlacementState>((ref) {
  return PlacementNotifier();
});

/// Notifier for managing placement matches
class PlacementNotifier extends StateNotifier<PlacementState> {
  PlacementNotifier() : super(const PlacementState());

  /// Start a new placement match
  PuzzleType startNextPlacementMatch() {
    if (state.isComplete) {
      throw StateError('Placement already complete');
    }

    final nextMatchNumber = state.matchesCompleted + 1;
    if (nextMatchNumber > 3) {
      throw StateError('Cannot start more than 3 placement matches');
    }

    return PlacementManager.getPuzzleTypeForMatch(nextMatchNumber);
  }

  /// Record the result of a placement match
  void recordMatchResult(PlacementMatchResult result) {
    final updatedResults = [...state.results, result];
    final matchesCompleted = state.matchesCompleted + 1;

    // Calculate initial ELO if this was the final match
    int? calculatedElo;
    bool isComplete = false;
    
    if (matchesCompleted == 3) {
      calculatedElo = PlacementManager.calculateInitialElo(updatedResults);
      isComplete = true;
    }

    state = state.copyWith(
      matchesCompleted: matchesCompleted,
      results: updatedResults,
      calculatedElo: calculatedElo,
      isComplete: isComplete,
    );
  }

  /// Reset placement state (for testing or re-calibration)
  void reset() {
    state = const PlacementState();
  }

  /// Get completion message
  String getCompletionMessage() {
    if (!state.isComplete || state.calculatedElo == null) {
      return 'Complete all 3 placement matches first';
    }
    return PlacementManager.getPlacementCompleteMessage(
      state.calculatedElo!,
      state.results,
    );
  }

  /// Check if player needs practice
  bool shouldRecommendPractice() {
    if (!state.isComplete) return false;
    return PlacementManager.shouldRecommendPractice(state.results);
  }

  /// Get practice recommendation
  String getPracticeRecommendation() {
    if (state.calculatedElo == null) return '';
    return PlacementManager.getPracticeDifficultyRecommendation(state.calculatedElo!);
  }
}

// ============================================================================
// MATCHMAKING SYSTEM PROVIDERS
// ============================================================================

/// Provider for matchmaking (Engagement Director)
final adaptiveMatchmakingProvider = Provider<MatchmakingLogic>((ref) {
  return MatchmakingLogic();
});

/// Provider to check if player has completed placement
final hasCompletedPlacementProvider = Provider<bool>((ref) {
  final placementState = ref.watch(placementStateProvider);
  return placementState.isComplete;
});

/// Provider to determine if this is player's first ranked match
/// This should be connected to actual player data in production
final isFirstRankedMatchProvider = Provider.family<bool, String>((ref, playerId) {
  // TODO: Connect to Firebase/storage to check actual player history
  // For now, check if placement is complete and total games == 0
  final placementState = ref.watch(placementStateProvider);
  
  // If placement not complete, not eligible for ranked
  if (!placementState.isComplete) return false;
  
  // Check player stats (you'll need to pass actual stats here)
  // For demonstration: return true if this provider is being called
  // In production, check: stats.totalGames == 0 after placement
  return false; // Replace with actual check
});

/// Provider to create a bot opponent for current match
final botOpponentProvider = Provider.family<BotAI, BotOpponentRequest>((ref, request) {
  final matchmaking = ref.watch(adaptiveMatchmakingProvider);
  
  return matchmaking.createBotOpponent(
    playerElo: request.playerElo,
    stats: request.stats,
    isFirstRankedMatch: request.isFirstRankedMatch,
  );
});

/// Request object for bot opponent creation
class BotOpponentRequest {
  final int playerElo;
  final PlayerStats stats;
  final bool isFirstRankedMatch;

  const BotOpponentRequest({
    required this.playerElo,
    required this.stats,
    required this.isFirstRankedMatch,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BotOpponentRequest &&
          runtimeType == other.runtimeType &&
          playerElo == other.playerElo &&
          isFirstRankedMatch == other.isFirstRankedMatch;

  @override
  int get hashCode => playerElo.hashCode ^ isFirstRankedMatch.hashCode;
}

/// Provider for match difficulty recommendation
final matchDifficultyProvider = Provider.family<BotDifficulty, DifficultyRequest>((ref, request) {
  final matchmaking = ref.watch(adaptiveMatchmakingProvider);
  
  return matchmaking.selectBotDifficulty(
    stats: request.stats,
    isFirstRankedMatch: request.isFirstRankedMatch,
  );
});

/// Request object for difficulty selection
class DifficultyRequest {
  final PlayerStats stats;
  final bool isFirstRankedMatch;

  const DifficultyRequest({
    required this.stats,
    required this.isFirstRankedMatch,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DifficultyRequest &&
          runtimeType == other.runtimeType &&
          isFirstRankedMatch == other.isFirstRankedMatch;

  @override
  int get hashCode => isFirstRankedMatch.hashCode;
}

/// Provider to check if should match with bot vs real player
final shouldMatchWithBotProvider = Provider.family<bool, MatchmakingRequest>((ref, request) {
  final matchmaking = ref.watch(adaptiveMatchmakingProvider);
  
  return matchmaking.shouldMatchWithBot(
    stats: request.stats,
    isFirstRankedMatch: request.isFirstRankedMatch,
    queueTimeSeconds: request.queueTimeSeconds,
    realPlayersAvailable: request.realPlayersAvailable,
  );
});

/// Request object for matchmaking decision
class MatchmakingRequest {
  final PlayerStats stats;
  final bool isFirstRankedMatch;
  final int queueTimeSeconds;
  final bool realPlayersAvailable;

  const MatchmakingRequest({
    required this.stats,
    required this.isFirstRankedMatch,
    required this.queueTimeSeconds,
    required this.realPlayersAvailable,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchmakingRequest &&
          runtimeType == other.runtimeType &&
          isFirstRankedMatch == other.isFirstRankedMatch &&
          queueTimeSeconds == other.queueTimeSeconds &&
          realPlayersAvailable == other.realPlayersAvailable;

  @override
  int get hashCode =>
      isFirstRankedMatch.hashCode ^
      queueTimeSeconds.hashCode ^
      realPlayersAvailable.hashCode;
}

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider for win probability prediction
final winProbabilityProvider = Provider.family<double, WinProbabilityRequest>((ref, request) {
  final matchmaking = ref.watch(adaptiveMatchmakingProvider);
  
  return matchmaking.predictWinProbability(
    playerElo: request.playerElo,
    opponentElo: request.opponentElo,
    botDifficulty: request.botDifficulty,
    stats: request.stats,
  );
});

/// Request object for win probability calculation
class WinProbabilityRequest {
  final int playerElo;
  final int opponentElo;
  final BotDifficulty botDifficulty;
  final PlayerStats stats;

  const WinProbabilityRequest({
    required this.playerElo,
    required this.opponentElo,
    required this.botDifficulty,
    required this.stats,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WinProbabilityRequest &&
          runtimeType == other.runtimeType &&
          playerElo == other.playerElo &&
          opponentElo == other.opponentElo &&
          botDifficulty == other.botDifficulty;

  @override
  int get hashCode =>
      playerElo.hashCode ^ opponentElo.hashCode ^ botDifficulty.hashCode;
}
