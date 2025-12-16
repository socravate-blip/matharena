import 'dart:async';
import '../models/puzzle.dart';

class CountdownTimer {
  Timer? _timer;
  int _secondsRemaining = 0;
  final Duration _totalDuration;
  final Function(int) onTick;
  final Function() onFinish;

  bool get isActive => _timer?.isActive ?? false;
  int get secondsRemaining => _secondsRemaining;
  Duration get totalDuration => _totalDuration;

  CountdownTimer({
    required Duration duration,
    required this.onTick,
    required this.onFinish,
  }) : _totalDuration = duration {
    _secondsRemaining = duration.inSeconds;
    _initTimer();
  }

  void _initTimer() {
    // Don't initialize timer, let it be late
  }

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      onTick(_secondsRemaining);

      if (_secondsRemaining <= 0) {
        timer.cancel();
        onFinish();
      }
    });
  }

  void pause() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
  }

  void resume() {
    if (!(_timer?.isActive ?? false)) {
      start();
    }
  }

  void reset() {
    _timer?.cancel();
    _secondsRemaining = _totalDuration.inSeconds;
  }

  void stop() {
    _timer?.cancel();
  }

  double get progress => _secondsRemaining / _totalDuration.inSeconds;

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Ranked game state including timer and match progression
class RankedGameState {
  // Match-level state
  final List<GamePuzzle> matchQueue;
  final int currentPuzzleIndex;
  final int totalScore;
  final DateTime? matchStartTime;

  // Bot opponent state
  final bool playingAgainstBot;
  final String? botName;
  final int? botElo;
  final int botScore;
  final int botCurrentPuzzleIndex;
  final double botPuzzleProgress; // 0.0 to 1.0 for current puzzle
  final DateTime? botPuzzleStartTime;
  final bool showEndDialog; // Flag to show end dialog once

  // Current puzzle state
  final int target;
  final List<int> availableNumbers;
  final String expression;
  final int score;
  final bool isPlaying;
  final String message;
  final bool isMatadorSolution;
  final Set<int> usedNumberIndices;
  final List<String> solutions;
  final String? lastScoreBreakdown;
  final int secondsRemaining;
  final bool timerActive;
  final DateTime? gameStartTime;
  final Set<String> foundSolutions;
  final int? currentResult;
  final int cursorPosition;

  const RankedGameState({
    // Match-level defaults
    this.matchQueue = const [],
    this.currentPuzzleIndex = 0,
    this.totalScore = 0,
    this.matchStartTime,

    // Bot opponent defaults
    this.playingAgainstBot = true,
    this.botName,
    this.botElo,
    this.botScore = 0,
    this.botCurrentPuzzleIndex = 0,
    this.botPuzzleProgress = 0.0,
    this.botPuzzleStartTime,
    this.showEndDialog = false,

    // Current puzzle defaults
    required this.target,
    required this.availableNumbers,
    required this.expression,
    required this.score,
    required this.isPlaying,
    this.message = '',
    this.isMatadorSolution = false,
    this.usedNumberIndices = const {},
    this.solutions = const [],
    this.lastScoreBreakdown,
    this.secondsRemaining = 360,
    this.timerActive = false,
    this.gameStartTime,
    this.foundSolutions = const {},
    this.currentResult,
    this.cursorPosition = 0,
  });

  // Convenience getters
  GamePuzzle? get currentPuzzle => currentPuzzleIndex < matchQueue.length
      ? matchQueue[currentPuzzleIndex]
      : null;

  bool get isMatchComplete => currentPuzzleIndex >= matchQueue.length;

  int get totalPuzzles => matchQueue.length;

  double get matchProgress =>
      totalPuzzles > 0 ? (currentPuzzleIndex / totalPuzzles) : 0.0;

  RankedGameState copyWith({
    // Match-level
    List<GamePuzzle>? matchQueue,
    int? currentPuzzleIndex,
    int? totalScore,
    DateTime? matchStartTime,

    // Bot opponent
    bool? playingAgainstBot,
    String? botName,
    int? botElo,
    int? botScore,
    int? botCurrentPuzzleIndex,
    double? botPuzzleProgress,
    bool? showEndDialog,
    DateTime? botPuzzleStartTime,

    // Current puzzle
    int? target,
    List<int>? availableNumbers,
    String? expression,
    int? score,
    bool? isPlaying,
    String? message,
    bool? isMatadorSolution,
    Set<int>? usedNumberIndices,
    List<String>? solutions,
    String? lastScoreBreakdown,
    int? secondsRemaining,
    bool? timerActive,
    DateTime? gameStartTime,
    Set<String>? foundSolutions,
    int? currentResult,
    int? cursorPosition,
  }) {
    return RankedGameState(
      matchQueue: matchQueue ?? this.matchQueue,
      currentPuzzleIndex: currentPuzzleIndex ?? this.currentPuzzleIndex,
      totalScore: totalScore ?? this.totalScore,
      matchStartTime: matchStartTime ?? this.matchStartTime,
      playingAgainstBot: playingAgainstBot ?? this.playingAgainstBot,
      botName: botName ?? this.botName,
      botElo: botElo ?? this.botElo,
      botScore: botScore ?? this.botScore,
      botCurrentPuzzleIndex: botCurrentPuzzleIndex ?? this.botCurrentPuzzleIndex,
      botPuzzleProgress: botPuzzleProgress ?? this.botPuzzleProgress,
      showEndDialog: showEndDialog ?? this.showEndDialog,
      botPuzzleStartTime: botPuzzleStartTime ?? this.botPuzzleStartTime,
      target: target ?? this.target,
      availableNumbers: availableNumbers ?? this.availableNumbers,
      expression: expression ?? this.expression,
      score: score ?? this.score,
      isPlaying: isPlaying ?? this.isPlaying,
      message: message ?? this.message,
      isMatadorSolution: isMatadorSolution ?? this.isMatadorSolution,
      usedNumberIndices: usedNumberIndices ?? this.usedNumberIndices,
      solutions: solutions ?? this.solutions,
      lastScoreBreakdown: lastScoreBreakdown ?? this.lastScoreBreakdown,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      timerActive: timerActive ?? this.timerActive,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      foundSolutions: foundSolutions ?? this.foundSolutions,
      currentResult: currentResult ?? this.currentResult,
      cursorPosition: cursorPosition ?? this.cursorPosition,
    );
  }
}
