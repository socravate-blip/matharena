import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/multiplayer_service.dart';
import '../../domain/services/firebase_multiplayer_service.dart';

/// Provider for multiplayer service
final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  return FirebaseMultiplayerService();
});

/// State for multiplayer match
class MultiplayerMatchState {
  final MultiplayerMatch? match;
  final MatchPlayer? opponent;
  final bool isSearching;
  final String? error;
  final bool isMyTurn;
  
  const MultiplayerMatchState({
    this.match,
    this.opponent,
    this.isSearching = false,
    this.error,
    this.isMyTurn = false,
  });

  MultiplayerMatchState copyWith({
    MultiplayerMatch? match,
    MatchPlayer? opponent,
    bool? isSearching,
    String? error,
    bool? isMyTurn,
  }) {
    return MultiplayerMatchState(
      match: match ?? this.match,
      opponent: opponent ?? this.opponent,
      isSearching: isSearching ?? this.isSearching,
      error: error ?? this.error,
      isMyTurn: isMyTurn ?? this.isMyTurn,
    );
  }
}

/// Notifier for multiplayer match state
class MultiplayerMatchNotifier extends StateNotifier<MultiplayerMatchState> {
  final MultiplayerService _service;
  String? _myPlayerId;
  
  MultiplayerMatchNotifier(this._service) : super(const MultiplayerMatchState());

  Future<void> initialize() async {
    await _service.initialize();
  }

  Future<void> searchForMatch(String playerId, String playerName, int playerElo) async {
    _myPlayerId = playerId;
    state = state.copyWith(isSearching: true, error: null);
    
    try {
      final matchId = await _service.joinQueue(playerId, playerName, playerElo);
      
      // Watch match updates
      _service.watchMatch(matchId).listen((match) {
        final opponent = match.player1.id == playerId ? match.player2 : match.player1;
        state = state.copyWith(
          match: match,
          opponent: opponent,
          isSearching: false,
        );
      }, onError: (error) {
        state = state.copyWith(
          isSearching: false,
          error: error.toString(),
        );
      });
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markReady() async {
    if (state.match == null || _myPlayerId == null) return;
    
    await _service.markReady(state.match!.matchId, _myPlayerId!);
  }

  Future<void> updateProgress(int score, int puzzleIndex) async {
    if (state.match == null || _myPlayerId == null) return;
    
    await _service.updatePlayerProgress(
      state.match!.matchId,
      _myPlayerId!,
      score,
      puzzleIndex,
    );
  }

  Future<void> submitAnswer(dynamic answer, bool isCorrect, int points) async {
    if (state.match == null || _myPlayerId == null) return;
    
    await _service.submitAnswer(
      state.match!.matchId,
      _myPlayerId!,
      answer,
      isCorrect,
      points,
    );
  }

  Future<void> completeMatch() async {
    if (state.match == null) return;
    
    await _service.completeMatch(state.match!.matchId);
  }

  void cancelSearch() {
    if (_myPlayerId != null) {
      _service.leaveQueue(_myPlayerId!);
    }
    state = const MultiplayerMatchState();
  }
}

final multiplayerMatchProvider = StateNotifierProvider<MultiplayerMatchNotifier, MultiplayerMatchState>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return MultiplayerMatchNotifier(service);
});
