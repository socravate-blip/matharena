import 'dart:async';

/// Multiplayer match state
enum MatchState {
  waiting,
  ready,
  inProgress,
  completed,
}

/// Player data in a match
class MatchPlayer {
  final String id;
  final String name;
  final int elo;
  final bool isBot;
  int score;
  int currentPuzzleIndex;
  bool isReady;

  MatchPlayer({
    required this.id,
    required this.name,
    required this.elo,
    this.isBot = false,
    this.score = 0,
    this.currentPuzzleIndex = 0,
    this.isReady = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'elo': elo,
    'isBot': isBot,
    'score': score,
    'currentPuzzleIndex': currentPuzzleIndex,
    'isReady': isReady,
  };

  factory MatchPlayer.fromJson(Map<String, dynamic> json) => MatchPlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    elo: json['elo'] as int,
    isBot: json['isBot'] as bool? ?? false,
    score: json['score'] as int? ?? 0,
    currentPuzzleIndex: json['currentPuzzleIndex'] as int? ?? 0,
    isReady: json['isReady'] as bool? ?? false,
  );
}

/// Match data structure
class MultiplayerMatch {
  final String matchId;
  final MatchPlayer player1;
  final MatchPlayer player2;
  final List<Map<String, dynamic>> puzzles;
  final MatchState state;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  MultiplayerMatch({
    required this.matchId,
    required this.player1,
    required this.player2,
    required this.puzzles,
    this.state = MatchState.waiting,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'player1': player1.toJson(),
    'player2': player2.toJson(),
    'puzzles': puzzles,
    'state': state.name,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory MultiplayerMatch.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert Firebase LinkedMaps to Map<String, dynamic>
    Map<String, dynamic> _convertMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      return {};
    }
    
    // Parse state - handle both enum and string
    MatchState parseState(dynamic stateValue) {
      if (stateValue is MatchState) return stateValue;
      final stateStr = stateValue.toString();
      return MatchState.values.firstWhere(
        (e) => e.name == stateStr,
        orElse: () => MatchState.waiting,
      );
    }
    
    // Parse timestamp - handle both int and String
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    
    return MultiplayerMatch(
      matchId: json['matchId'] as String,
      player1: MatchPlayer.fromJson(_convertMap(json['player1'])),
      player2: MatchPlayer.fromJson(_convertMap(json['player2'])),
      puzzles: (json['puzzles'] as List? ?? [])
          .map((e) => _convertMap(e))
          .toList(),
      state: parseState(json['state']),
      createdAt: parseTimestamp(json['createdAt']),
      startedAt: json['startedAt'] != null ? parseTimestamp(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? parseTimestamp(json['completedAt']) : null,
    );
  }
}

/// Abstract interface for multiplayer backend
/// Implement this with Firebase, Supabase, or custom backend
abstract class MultiplayerService {
  /// Initialize the service
  Future<void> initialize();

  /// Create or join a match queue
  /// Returns match ID when matched
  Future<String> joinQueue(String playerId, String playerName, int playerElo);

  /// Leave the queue
  Future<void> leaveQueue(String playerId);

  /// Listen to match updates
  Stream<MultiplayerMatch> watchMatch(String matchId);

  /// Update player progress
  Future<void> updatePlayerProgress(
    String matchId,
    String playerId,
    int score,
    int currentPuzzleIndex,
  );

  /// Mark player as ready
  Future<void> markReady(String matchId, String playerId);

  /// Submit answer for current puzzle
  Future<void> submitAnswer(
    String matchId,
    String playerId,
    dynamic answer,
    bool isCorrect,
    int pointsEarned,
  );

  /// End the match
  Future<void> completeMatch(String matchId);

  /// Get opponent's current state
  Future<MatchPlayer?> getOpponentState(String matchId, String myPlayerId);
}

/// Mock implementation for testing (single-player with bot)
class MockMultiplayerService implements MultiplayerService {
  final _matchController = StreamController<MultiplayerMatch>.broadcast();
  MultiplayerMatch? _currentMatch;

  @override
  Future<void> initialize() async {
    // No initialization needed for mock
  }

  @override
  Future<String> joinQueue(String playerId, String playerName, int playerElo) async {
    // Simulate queue wait
    await Future.delayed(const Duration(seconds: 2));

    // Create match with bot
    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
    
    _currentMatch = MultiplayerMatch(
      matchId: matchId,
      player1: MatchPlayer(
        id: playerId,
        name: playerName,
        elo: playerElo,
      ),
      player2: MatchPlayer(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        name: 'MathBot',
        elo: playerElo + (playerElo > 1500 ? -100 : 100),
        isBot: true,
      ),
      puzzles: [],
      createdAt: DateTime.now(),
    );

    _matchController.add(_currentMatch!);
    return matchId;
  }

  @override
  Future<void> leaveQueue(String playerId) async {
    // Clean up
  }

  @override
  Stream<MultiplayerMatch> watchMatch(String matchId) {
    return _matchController.stream;
  }

  @override
  Future<void> updatePlayerProgress(
    String matchId,
    String playerId,
    int score,
    int currentPuzzleIndex,
  ) async {
    if (_currentMatch == null) return;

    if (_currentMatch!.player1.id == playerId) {
      _currentMatch!.player1.score = score;
      _currentMatch!.player1.currentPuzzleIndex = currentPuzzleIndex;
    } else {
      _currentMatch!.player2.score = score;
      _currentMatch!.player2.currentPuzzleIndex = currentPuzzleIndex;
    }

    _matchController.add(_currentMatch!);
  }

  @override
  Future<void> markReady(String matchId, String playerId) async {
    if (_currentMatch == null) return;

    if (_currentMatch!.player1.id == playerId) {
      _currentMatch!.player1.isReady = true;
    } else {
      _currentMatch!.player2.isReady = true;
    }

    _matchController.add(_currentMatch!);
  }

  @override
  Future<void> submitAnswer(
    String matchId,
    String playerId,
    dynamic answer,
    bool isCorrect,
    int pointsEarned,
  ) async {
    // Track answer submission
  }

  @override
  Future<void> completeMatch(String matchId) async {
    if (_currentMatch != null) {
      _currentMatch = MultiplayerMatch(
        matchId: _currentMatch!.matchId,
        player1: _currentMatch!.player1,
        player2: _currentMatch!.player2,
        puzzles: _currentMatch!.puzzles,
        state: MatchState.completed,
        createdAt: _currentMatch!.createdAt,
        startedAt: _currentMatch!.startedAt,
        completedAt: DateTime.now(),
      );
      _matchController.add(_currentMatch!);
    }
  }

  @override
  Future<MatchPlayer?> getOpponentState(String matchId, String myPlayerId) async {
    if (_currentMatch == null) return null;
    
    return _currentMatch!.player1.id == myPlayerId
        ? _currentMatch!.player2
        : _currentMatch!.player1;
  }

  void dispose() {
    _matchController.close();
  }
}
