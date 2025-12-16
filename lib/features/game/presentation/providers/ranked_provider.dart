import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/logic/matador_engine.dart';
import '../../domain/logic/timer_engine.dart';
import '../../domain/logic/ranked_match_engine.dart';
import '../../domain/logic/bot_ai.dart';
import '../../domain/logic/elo_calculator.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../../domain/services/multiplayer_service.dart';
import 'multiplayer_provider.dart';

class RankedNotifier extends Notifier<RankedGameState> {
  late final MatadorEngine _engine;
  late final RankedMatchEngine _matchEngine;
  CountdownTimer? _timer;
  Timer? _botProgressTimer;
  BotAI? _currentBot;
  FirebaseMultiplayerService? _multiplayerService;
  StreamSubscription? _matchListener;
  String? _currentMatchId;
  String? _currentPlayerId;

  @override
  RankedGameState build() {
    _engine = MatadorEngine();
    _matchEngine = RankedMatchEngine();
    return const RankedGameState(
      target: 0,
      availableNumbers: [],
      expression: '',
      score: 0,
      isPlaying: false,
      message: '',
      secondsRemaining: 360,
      timerActive: false,
    );
  }

  /// Starts a new ranked match - tries to find real player first, then bot
  Future<void> startMatch() async {
    final ratingStorage = ref.read(ratingStorageProvider);
    final profile = await ratingStorage.getProfile();

    _timer?.stop();
    _botProgressTimer?.cancel();

    // Initialize Firebase multiplayer service
    _multiplayerService = ref.read(multiplayerServiceProvider) as FirebaseMultiplayerService;
    await _multiplayerService!.initialize();

    // Get player ID from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(message: 'Authentication error!');
      return;
    }

    final playerId = user.uid;
    final playerElo = profile.currentRating;
    
    // Update profile with Firebase user ID if not set
    if (profile.playerId.isEmpty || profile.playerId != playerId) {
      profile.playerId = playerId;
      await ratingStorage.saveProfile(profile);
    }
    
    final playerName = profile.playerName.isNotEmpty ? profile.playerName : 'Player';

    // Show searching state
    state = state.copyWith(
      isPlaying: false,
      message: '🔍 Searching for opponent...',
    );

    try {
      print('🔍 Starting matchmaking for player: $playerId (ELO: $playerElo)');
      
      // Join matchmaking queue (will wait 5 seconds for real player, then create bot match)
      final matchId = await _multiplayerService!.joinQueue(playerId, playerName, playerElo);
      print('✅ Match created/joined: $matchId');

      // Check if it's a bot match or real player match
      final match = await _multiplayerService!.getMatchData(matchId);
      if (match == null) {
        print('❌ Match data not found for: $matchId');
        state = state.copyWith(message: 'Match not found!');
        return;
      }
      
      print('📊 Match data retrieved: ${match.keys}');

      final player2 = Map<String, dynamic>.from(match['player2'] as Map);
      final isBot = player2['isBot'] as bool? ?? false;
      
      // Check if we are player1 or player2
      final player1 = Map<String, dynamic>.from(match['player1'] as Map);
      final isPlayer1 = player1['id'] == playerId;
      
      print('🤖 Is bot match: $isBot');
      print('👤 Opponent: ${player2['name']} (ELO: ${player2['elo']})');
      print('🎮 I am player${isPlayer1 ? '1' : '2'}');

      if (isBot) {
        print('🎮 Starting bot match...');
        // Bot match - generate puzzles and save to Firebase
        _currentBot = BotAI.matchingSkill(playerElo);
        final botElo = _currentBot!.skillLevel;
        final highestElo = playerElo > botElo ? playerElo : botElo;
        final playlist = _matchEngine.generateMatchPlaylist(highestElo);

        if (playlist.isEmpty) {
          state = state.copyWith(message: 'Failed to generate match!');
          return;
        }

        // Save puzzles to Firebase
        final puzzlesJson = playlist.map((p) => p.toJson()).toList();
        await _multiplayerService!.savePuzzles(matchId, puzzlesJson);

        state = RankedGameState(
          matchQueue: playlist,
          currentPuzzleIndex: 0,
          totalScore: 0,
          matchStartTime: DateTime.now(),
          playingAgainstBot: true,
          botName: _currentBot!.name,
          botElo: _currentBot!.skillLevel,
          botScore: 0,
          botCurrentPuzzleIndex: 0,
          botPuzzleProgress: 0.0,
          target: 0,
          availableNumbers: [],
          expression: '',
          score: 0,
          isPlaying: true,
          message: '⚔️ Match Started! vs ${_currentBot!.name} (${_currentBot!.skillLevel} ELO)',
          secondsRemaining: 0,
          timerActive: false,
        );

        _loadCurrentPuzzle();
        _startBotSimulation();
      } else {
        print('🎯 Starting real player match!');
        // Real player match!
        final opponentName = player2['name'] as String;
        final opponentElo = player2['elo'] as int;
        final highestElo = playerElo > opponentElo ? playerElo : opponentElo;
        
        List<GamePuzzle> playlist;
        
        if (isPlayer1) {
          // Player 1 generates puzzles and saves to Firebase
          print('🎲 Generating puzzles (as player1)...');
          playlist = _matchEngine.generateMatchPlaylist(highestElo);
          
          if (playlist.isEmpty) {
            state = state.copyWith(message: 'Failed to generate match!');
            return;
          }
          
          // Save puzzles to Firebase for player2 to load
          final puzzlesJson = playlist.map((p) => p.toJson()).toList();
          await _multiplayerService!.savePuzzles(matchId, puzzlesJson);
          print('✅ Puzzles saved to Firebase for opponent');
        } else {
          // Player 2 loads puzzles from Firebase (with retry for race condition)
          print('📥 Loading puzzles from Firebase (as player2)...');
          List<Map<String, dynamic>> puzzlesJson = [];
          
          // Retry up to 10 times with 500ms delay
          for (int attempt = 1; attempt <= 10; attempt++) {
            puzzlesJson = await _multiplayerService!.loadPuzzles(matchId);
            
            if (puzzlesJson.isNotEmpty) {
              print('✅ Loaded ${puzzlesJson.length} puzzles from Firebase');
              break;
            }
            
            if (attempt < 10) {
              print('⏳ Waiting for player1 to generate puzzles... (attempt $attempt/10)');
              state = state.copyWith(message: '⏳ Waiting for opponent to prepare match...');
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
          
          if (puzzlesJson.isEmpty) {
            print('❌ Timeout: No puzzles after 10 attempts (5 seconds)');
            state = state.copyWith(message: '❌ Match preparation failed!');
            return;
          }
          
          // Convert JSON to GamePuzzle objects
          playlist = puzzlesJson.map((json) => GamePuzzle.fromJson(json)).toList();
        }

        // Store match info for real-time sync
        _currentMatchId = matchId;
        _currentPlayerId = playerId;
        
        // Start listening to match updates for opponent progress
        _startMatchListener(matchId, playerId, isPlayer1);

        state = RankedGameState(
          matchQueue: playlist,
          currentPuzzleIndex: 0,
          totalScore: 0,
          matchStartTime: DateTime.now(),
          playingAgainstBot: false,
          botName: opponentName,
          botElo: opponentElo,
          botScore: 0,
          botCurrentPuzzleIndex: 0,
          botPuzzleProgress: 0.0,
          target: 0,
          availableNumbers: [],
          expression: '',
          score: 0,
          isPlaying: true,
          message: '🎮 Match Started! vs $opponentName ($opponentElo ELO)',
          secondsRemaining: 0,
          timerActive: false,
        );

        _loadCurrentPuzzle();
      }
    } catch (e) {
      print('❌ Firebase matchmaking failed: $e');
      print('📋 Error type: ${e.runtimeType}');
      print('');
      print('🔄 Falling back to local bot match (offline mode)...');
      print('⚠️  To fix Firebase multiplayer, see MULTIPLAYER_DEBUG.md');
      print('');
      
      // Firebase failed (permission denied or network issue)
      // Fall back to local bot match without Firebase
      _startLocalBotMatch(playerElo);
    }
  }

  /// Start a local bot match without Firebase (fallback)
  void _startLocalBotMatch(int playerElo) {
    print('🤖 Creating local bot match (no Firebase)');
    
    // Create bot opponent matching player's skill (±100 ELO)
    _currentBot = BotAI.matchingSkill(playerElo);
    final botElo = _currentBot!.skillLevel;

    // Use HIGHEST ELO to determine game difficulty/playlist
    final highestElo = playerElo > botElo ? playerElo : botElo;
    final playlist = _matchEngine.generateMatchPlaylist(highestElo);

    if (playlist.isEmpty) {
      state = state.copyWith(
        message: 'Failed to generate match!',
        isPlaying: false,
      );
      return;
    }

    // Initialize match state with bot
    state = RankedGameState(
      matchQueue: playlist,
      currentPuzzleIndex: 0,
      totalScore: 0,
      matchStartTime: DateTime.now(),
      playingAgainstBot: true,
      botName: _currentBot!.name,
      botElo: _currentBot!.skillLevel,
      botScore: 0,
      botCurrentPuzzleIndex: 0,
      botPuzzleProgress: 0.0,
      target: 0,
      availableNumbers: [],
      expression: '',
      score: 0,
      isPlaying: true,
      message: '⚔️ Match Started! vs ${_currentBot!.name} (${_currentBot!.skillLevel} ELO)',
      secondsRemaining: 0,
      timerActive: false,
    );

    // Load first puzzle
    _loadCurrentPuzzle();
    
    // Start bot simulation
    _startBotSimulation();
  }

  /// Loads the current puzzle from the queue
  void _loadCurrentPuzzle() {
    final puzzle = state.currentPuzzle;

    if (puzzle == null) {
      // Match complete!
      _finishMatch();
      return;
    }

    // Setup timer for this puzzle
    _timer?.stop();
    _timer = CountdownTimer(
      duration: Duration(seconds: puzzle.timeLimit),
      onTick: (remaining) {
        state = state.copyWith(secondsRemaining: remaining);
      },
      onFinish: () {
        _skipPuzzle(); // Move to next on timeout
      },
    );

    // Configure state based on puzzle type
    switch (puzzle.type) {
      case PuzzleType.basic:
      case PuzzleType.complex:
        _loadArithmeticPuzzle(puzzle);
        break;
      case PuzzleType.game24:
        _loadGame24Puzzle(puzzle as Game24Puzzle);
        break;
      case PuzzleType.matador:
        _loadMatadorPuzzle(puzzle as MatadorPuzzle);
        break;
    }

    _timer!.start();
    state = state.copyWith(timerActive: true);
  }

  /// Loads basic/complex arithmetic puzzle
  void _loadArithmeticPuzzle(GamePuzzle puzzle) {
    String question = '';
    if (puzzle is BasicPuzzle) {
      question = puzzle.question;
    } else if (puzzle is ComplexPuzzle) {
      question = puzzle.question;
    }

    state = state.copyWith(
      target: puzzle.targetValue,
      availableNumbers: [],
      expression: '',
      score: 0,
      message:
          'Puzzle ${state.currentPuzzleIndex + 1}/${state.totalPuzzles}: $question',
      isMatadorSolution: false,
      usedNumberIndices: {},
      solutions: [],
      foundSolutions: {},
      currentResult: null,
      cursorPosition: 0,
      secondsRemaining: puzzle.timeLimit,
    );
  }

  /// Loads Game 24 puzzle
  void _loadGame24Puzzle(Game24Puzzle puzzle) {
    state = state.copyWith(
      target: 24,
      availableNumbers: puzzle.availableNumbers,
      expression: '',
      score: 0,
      message:
          'Puzzle ${state.currentPuzzleIndex + 1}/${state.totalPuzzles}: Make 24!',
      isMatadorSolution: false,
      usedNumberIndices: {},
      solutions: [],
      foundSolutions: {},
      currentResult: null,
      cursorPosition: 0,
      secondsRemaining: puzzle.timeLimit,
    );
  }

  /// Loads Matador puzzle
  void _loadMatadorPuzzle(MatadorPuzzle puzzle) {
    final solutions = puzzle.validSolutions ?? <String>{};

    state = state.copyWith(
      target: puzzle.targetValue,
      availableNumbers: puzzle.availableNumbers,
      expression: '',
      score: 0,
      message:
          'BOSS LEVEL ${state.currentPuzzleIndex + 1}/${state.totalPuzzles}: Make ${puzzle.targetValue}! Points: +1, -2, ×1, ÷3. Mathador (all 4 ops) = 13 pts!',
      isMatadorSolution: false,
      usedNumberIndices: {},
      solutions: solutions.toList(),
      foundSolutions: {},
      currentResult: null,
      cursorPosition: 0,
      secondsRemaining: puzzle.timeLimit,
    );
  }

  /// Submits answer for the current puzzle
  void submitAnswer() {
    final puzzle = state.currentPuzzle;
    if (puzzle == null) return;

    bool isCorrect = false;
    int pointsEarned = 0;

    switch (puzzle.type) {
      case PuzzleType.basic:
      case PuzzleType.complex:
        isCorrect = _validateArithmeticAnswer(puzzle);
        pointsEarned = isCorrect ? puzzle.maxPoints : 0;
        break;

      case PuzzleType.game24:
      case PuzzleType.matador:
        isCorrect = _validateExpressionAnswer(puzzle);
        if (isCorrect) {
          // For Matador: calculate points based on operators used
          if (puzzle is MatadorPuzzle) {
            // Calculate points: + = 1, - = 2, × = 1, ÷ = 3
            final isMathador = puzzle.isMathadorSolution(state.expression);
            
            // Track unique solutions
            final newFoundSolutions = Set<String>.from(state.foundSolutions);
            newFoundSolutions.add(state.expression);
            
            // Award points: 13 if Mathador (all 4 operators), otherwise calculate normally
            pointsEarned = isMathador ? 13 : _calculateMatadorPoints(state.expression);
            state = state.copyWith(
              isMatadorSolution: isMathador,
              foundSolutions: newFoundSolutions,
            );
          } else {
            // Game24: standard points
            pointsEarned = puzzle.maxPoints;
          }
        }
        break;
    }

    if (isCorrect) {
      final newTotalScore = state.totalScore + pointsEarned;
      
      // Custom message for Matador puzzles
      String successMessage = '✅ Correct! +$pointsEarned pts';
      if (puzzle is MatadorPuzzle) {
        if (state.isMatadorSolution) {
          successMessage = '🏆 MATHADOR! +13 pts';
        } else {
          // Calculate total score from all solutions found
          final totalFromSolutions = state.foundSolutions.fold<int>(0, (sum, expr) {
            return sum + _calculateMatadorPoints(expr);
          });
          successMessage = '✅ Solution ${state.foundSolutions.length}! Total: $totalFromSolutions pts';
        }
      }

      state = state.copyWith(
        totalScore: newTotalScore,
        message: successMessage,
      );

      // Move to next puzzle immediately
      _nextPuzzle();
    } else {
      state = state.copyWith(
        message: '❌ Wrong! Try again',
      );
    }
  }

  /// Validates arithmetic puzzle answer (simple number input)
  bool _validateArithmeticAnswer(GamePuzzle puzzle) {
    final input = int.tryParse(state.expression);
    if (input == null) return false;
    return input == puzzle.targetValue;
  }

  /// Validates expression-based answer (Game24/Matador)
  bool _validateExpressionAnswer(GamePuzzle puzzle) {
    if (state.expression.isEmpty) return false;

    final result = _engine.evaluate(state.expression);
    if (result == null) return false;

    return result == puzzle.targetValue;
  }

  /// Calculates Matador points based on operators used
  /// + = 1 point, - = 2 points, × = 1 point, ÷ = 3 points
  int _calculateMatadorPoints(String expression) {
    int points = 0;
    
    // Count each operator
    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      switch (char) {
        case '+':
          points += 1;
          break;
        case '-':
          points += 2;
          break;
        case '*':
          points += 1;
          break;
        case '/':
          points += 3;
          break;
      }
    }
    
    return points;
  }

  /// Moves to next puzzle in queue
  void _nextPuzzle() {
    _timer?.stop();

    final nextIndex = state.currentPuzzleIndex + 1;

    state = state.copyWith(
      currentPuzzleIndex: nextIndex,
    );

    // Update progress to Firebase for real multiplayer
    if (!state.playingAgainstBot && _currentMatchId != null) {
      _updateProgressToFirebase();
    }

    _loadCurrentPuzzle();
  }

  /// Skips current puzzle (timeout or user skip)
  void _skipPuzzle() {
    state = state.copyWith(
      message: '⏱️ Time\'s up!',
    );

    // Move to next puzzle immediately
    _nextPuzzle();
  }

  /// Finishes the match and updates ELO
  Future<void> _finishMatch() async {
    _timer?.stop();
    _botProgressTimer?.cancel();
    _matchListener?.cancel();

    // Mark match as finished in Firebase (for real multiplayer)
    if (!state.playingAgainstBot && _currentMatchId != null && _currentPlayerId != null) {
      try {
        // Final progress update
        await _multiplayerService!.updatePlayerProgress(
          _currentMatchId!,
          _currentPlayerId!,
          state.totalScore,
          state.currentPuzzleIndex,
        );
        
        // Mark match as finished
        await _multiplayerService!.finishMatch(_currentMatchId!);
        print('✅ Match marked as finished in Firebase');
      } catch (e) {
        print('⚠️ Failed to finish match in Firebase: $e');
      }
    }

    final ratingStorage = ref.read(ratingStorageProvider);
    final profile = await ratingStorage.getProfile();

    // Determine actual match result
    final playerWon = state.totalScore > state.botScore;
    final isDraw = state.totalScore == state.botScore;
    final actualScore = playerWon ? 1.0 : (isDraw ? 0.5 : 0.0);

    // Calculate new rating using bot's ELO as opponent
    final botElo = state.botElo ?? profile.currentRating;
    final newRating = EloCalculator.calculateNewRating(
      currentRating: profile.currentRating,
      opponentRating: botElo,
      actualScore: actualScore,
      gamesPlayed: profile.gamesPlayed,
    );

    final ratingChange = newRating - profile.currentRating;

    // Update profile
    profile.currentRating = newRating;
    profile.peakRating = newRating > profile.peakRating ? newRating : profile.peakRating;
    profile.gamesPlayed++;
    
    if (playerWon) {
      profile.wins++;
    } else if (isDraw) {
      profile.draws++;
    } else {
      profile.losses++;
    }

    profile.history.add(RatingHistory(
      date: DateTime.now(),
      rating: newRating,
      ratingChange: ratingChange,
      gameScore: state.totalScore,
      foundMathador: false,
    ));

    if (profile.history.length > 100) {
      profile.history.removeAt(0);
    }

    await ratingStorage.saveProfile(profile);
    ref.invalidate(playerRatingProvider);

    final resultText = playerWon ? '🏆 VICTORY!' : isDraw ? '🤝 DRAW!' : '💀 DEFEAT!';

    state = state.copyWith(
      isPlaying: false,
      timerActive: false,
      showEndDialog: true,
      message: '$resultText You: ${state.totalScore} vs Bot: ${state.botScore}',
    );
  }

  /// Starts bot simulation with realistic progress tracking
  void _startBotSimulation() {
    if (_currentBot == null || state.matchQueue.isEmpty) return;

    // Start bot on first puzzle
    _startBotPuzzle();

    // Update bot progress every 20ms for smoother animation
    _botProgressTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      _updateBotProgress();
    });
  }

  /// Starts bot working on current puzzle
  void _startBotPuzzle() {
    if (state.botCurrentPuzzleIndex >= state.matchQueue.length) {
      // Bot finished all puzzles
      return;
    }

    state = state.copyWith(
      botPuzzleStartTime: DateTime.now(),
      botPuzzleProgress: 0.0,
    );
  }

  /// Updates bot progress and completes puzzles
  void _updateBotProgress() {
    if (!state.isPlaying || 
        state.botCurrentPuzzleIndex >= state.matchQueue.length || 
        state.botPuzzleStartTime == null) {
      return;
    }

    final puzzle = state.matchQueue[state.botCurrentPuzzleIndex];
    final solveTime = _currentBot!.calculateSolveTime(puzzle);
    final elapsed = DateTime.now().difference(state.botPuzzleStartTime!);
    
    // Calculate progress (0.0 to 1.0)
    final progress = (elapsed.inMilliseconds / solveTime.inMilliseconds).clamp(0.0, 1.0);

    state = state.copyWith(
      botPuzzleProgress: progress,
    );

    // Check if bot completed the puzzle
    if (progress >= 1.0) {
      _botCompletePuzzle();
    }
  }

  /// Bot completes current puzzle and moves to next
  void _botCompletePuzzle() {
    if (state.botCurrentPuzzleIndex >= state.matchQueue.length) return;

    final puzzle = state.matchQueue[state.botCurrentPuzzleIndex];
    final successProbability = _currentBot!.getSuccessProbability(puzzle);
    final solves = (successProbability * 100).round() > (DateTime.now().millisecondsSinceEpoch % 100);

    int pointsEarned = 0;

    if (solves) {
      // Bot solves the puzzle
      switch (puzzle.type) {
        case PuzzleType.basic:
        case PuzzleType.complex:
          pointsEarned = puzzle.maxPoints;
          break;
        case PuzzleType.game24:
          pointsEarned = puzzle.maxPoints;
          break;
        case PuzzleType.matador:
          // Bot might find Mathador based on skill
          final tryMathador = _currentBot!.skillLevel > 1500 && 
                             (DateTime.now().millisecondsSinceEpoch % 100) > 70;
          pointsEarned = tryMathador ? 13 : (3 + (DateTime.now().millisecondsSinceEpoch % 5));
          break;
      }
    }

    final newBotScore = state.botScore + pointsEarned;
    final newBotPuzzleIndex = state.botCurrentPuzzleIndex + 1;

    state = state.copyWith(
      botScore: newBotScore,
      botCurrentPuzzleIndex: newBotPuzzleIndex,
      botPuzzleProgress: 0.0,
    );

    // Check if bot finished all puzzles - END THE MATCH
    if (newBotPuzzleIndex >= state.matchQueue.length) {
      _finishMatch();
      return;
    }

    // Start next puzzle if available and match is still playing
    if (state.isPlaying) {
      _startBotPuzzle();
    }
  }

  // Expression building methods for Matador/Game24 puzzles

  void addToExpression(String value) {
    final puzzle = state.currentPuzzle;

    // Only allow expression building for Game24/Matador
    if (puzzle?.type != PuzzleType.game24 &&
        puzzle?.type != PuzzleType.matador) {
      return;
    }

    final isNumber = int.tryParse(value) != null;
    final isOperator = ['+', '-', '*', '/'].contains(value);

    final cursorPos = state.cursorPosition.clamp(0, state.expression.length);
    final before = state.expression.substring(0, cursorPos);
    final after = state.expression.substring(cursorPos);

    if (state.expression.isEmpty) {
      if (isOperator && value != '-') return;
      final newExpression = value;
      final newUsedIndices = _calculateUsedIndices(newExpression);
      final result = _engine.evaluate(newExpression);

      state = state.copyWith(
        expression: newExpression,
        message: '',
        usedNumberIndices: newUsedIndices,
        currentResult: result,
        cursorPosition: newExpression.length,
      );
      return;
    }

    final charBefore = cursorPos > 0 ? state.expression[cursorPos - 1] : '';
    final charAfter =
        cursorPos < state.expression.length ? state.expression[cursorPos] : '';
    final beforeIsNumber = int.tryParse(charBefore) != null;
    final beforeIsOperator = ['+', '-', '*', '/'].contains(charBefore);
    final beforeIsOpenParen = charBefore == '(';
    final afterIsNumber = int.tryParse(charAfter) != null;

    // Validation rules
    if (isNumber && (beforeIsNumber || charBefore == ')' || afterIsNumber)) {
      return;
    }

    if (isOperator && beforeIsOperator) {
      return;
    }

    if (beforeIsOpenParen && isOperator && value != '-') {
      return;
    }

    final newExpression = before + value + after;
    final newUsedIndices = _calculateUsedIndices(newExpression);
    final result = _engine.evaluate(newExpression);

    state = state.copyWith(
      expression: newExpression,
      message: '',
      usedNumberIndices: newUsedIndices,
      currentResult: result,
      cursorPosition: cursorPos + value.length,
    );

    // Auto-validate
    _checkAutoValidation();
  }

  Set<int> _calculateUsedIndices(String expression) {
    final usedIndices = <int>{};
    String currentNumber = '';

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (int.tryParse(char) != null) {
        currentNumber += char;
      } else {
        if (currentNumber.isNotEmpty) {
          final num = int.parse(currentNumber);
          for (int j = 0; j < state.availableNumbers.length; j++) {
            if (state.availableNumbers[j] == num && !usedIndices.contains(j)) {
              usedIndices.add(j);
              break;
            }
          }
          currentNumber = '';
        }
      }
    }

    if (currentNumber.isNotEmpty) {
      final num = int.parse(currentNumber);
      for (int j = 0; j < state.availableNumbers.length; j++) {
        if (state.availableNumbers[j] == num && !usedIndices.contains(j)) {
          usedIndices.add(j);
          break;
        }
      }
    }

    return usedIndices;
  }

  void clearExpression() {
    state = state.copyWith(
      expression: '',
      message: '',
      usedNumberIndices: {},
      currentResult: null,
      cursorPosition: 0,
    );
  }

  void setCursorPosition(int position) {
    state = state.copyWith(
      cursorPosition: position.clamp(0, state.expression.length),
    );
  }

  void deleteLastCharacter() {
    if (state.expression.isEmpty || state.cursorPosition <= 0) return;

    final cursorPos = state.cursorPosition.clamp(0, state.expression.length);
    final before = state.expression.substring(0, cursorPos - 1);
    final after = state.expression.substring(cursorPos);
    final newExpression = before + after;

    final newUsedIndices = _calculateUsedIndices(newExpression);
    final result =
        newExpression.isEmpty ? null : _engine.evaluate(newExpression);

    state = state.copyWith(
      expression: newExpression,
      message: '',
      usedNumberIndices: newUsedIndices,
      currentResult: result,
      cursorPosition: cursorPos - 1,
    );
  }

  void _checkAutoValidation() {
    if (state.expression.isEmpty) return;

    final result = _engine.evaluate(state.expression);
    if (result == null) return;

    if (result == state.target) {
      submitAnswer();
    }
  }

  // Methods for arithmetic puzzles (Basic/Complex) with auto-validation
  void addInput(String value) {
    final puzzle = state.currentPuzzle;
    
    // Only for Basic/Complex arithmetic puzzles
    if (puzzle?.type != PuzzleType.basic && puzzle?.type != PuzzleType.complex) {
      return;
    }

    // Allow numbers and minus sign
    if (value == '-') {
      if (state.expression.isEmpty || state.expression == '-') {
        state = state.copyWith(expression: '-', message: '');
      }
    } else if (int.tryParse(value) != null) {
      // It's a number
      final newExpression = state.expression + value;
      state = state.copyWith(expression: newExpression, message: '');
      
      // Auto-validate after each input
      _checkArithmeticAutoValidation();
    }
  }

  void _checkArithmeticAutoValidation() {
    final puzzle = state.currentPuzzle;
    if (puzzle == null) return;
    
    final input = int.tryParse(state.expression);
    if (input == null) return;
    
    if (input == puzzle.targetValue) {
      // Correct answer - auto-submit
      submitAnswer();
    }
  }

  void backspace() {
    final puzzle = state.currentPuzzle;
    
    // Only for Basic/Complex arithmetic puzzles
    if (puzzle?.type != PuzzleType.basic && puzzle?.type != PuzzleType.complex) {
      return;
    }

    if (state.expression.isNotEmpty) {
      state = state.copyWith(
        expression: state.expression.substring(0, state.expression.length - 1),
        message: '',
      );
    }
  }

  // Legacy compatibility
  void startGame() => startMatch();
  Future<void> endGame() => _finishMatch();
  
  /// Resets to initial state (return to start screen)
  void resetToStart() {
    _timer?.stop();
    _botProgressTimer?.cancel();
    _currentBot = null;
    
    state = const RankedGameState(
      target: 0,
      availableNumbers: [],
      expression: '',
      score: 0,
      isPlaying: false,
      message: '',
      secondsRemaining: 360,
      timerActive: false,
    );
  }
  
  /// Abandon current match (counts as defeat)
  Future<void> abandonMatch() async {
    _timer?.stop();
    _botProgressTimer?.cancel();

    // When abandoning, player always loses
    final ratingStorage = ref.read(ratingStorageProvider);
    final profile = await ratingStorage.getProfile();
    
    // Set opponent rating higher than player to ensure ELO loss
    // Use player's rating + 200 to guarantee a loss
    final virtualOpponentRating = profile.currentRating + 200;
    
    // Actual score is 0.0 (complete loss)
    const actualScore = 0.0;
    
    // Calculate new rating (will always decrease)
    final newRating = EloCalculator.calculateNewRating(
      currentRating: profile.currentRating,
      opponentRating: virtualOpponentRating,
      actualScore: actualScore,
      gamesPlayed: profile.gamesPlayed,
    );
    
    final ratingChange = newRating - profile.currentRating;
    
    // Update profile manually with the loss
    profile.currentRating = newRating;
    profile.peakRating = profile.currentRating > profile.peakRating 
        ? profile.currentRating 
        : profile.peakRating;
    profile.gamesPlayed++;
    profile.losses++;
    
    profile.history.add(RatingHistory(
      date: DateTime.now(),
      rating: newRating,
      ratingChange: ratingChange,
      gameScore: state.totalScore,
      foundMathador: false,
    ));
    
    if (profile.history.length > 100) {
      profile.history.removeAt(0);
    }
    
    await ratingStorage.saveProfile(profile);
    ref.invalidate(playerRatingProvider);

    state = state.copyWith(
      isPlaying: false,
      timerActive: false,
      showEndDialog: true,
      message: '🏳️ ABANDONED! You: ${state.totalScore} vs Bot: ${state.botScore}',
    );
  }

  /// Start listening to real-time match updates
  void _startMatchListener(String matchId, String playerId, bool isPlayer1) {
    print('🎧 Starting match listener for: $matchId');
    
    _matchListener?.cancel();
    _matchListener = _multiplayerService!.watchMatch(matchId).listen((match) {
      // Update opponent's progress
      final opponentData = isPlayer1 ? match.player2 : match.player1;
      
      state = state.copyWith(
        botScore: opponentData.score,
        botCurrentPuzzleIndex: opponentData.currentPuzzleIndex,
      );

      // Check if match is finished
      if (match.state == MatchState.completed || match.state.name == 'finished') {
        print('🏁 Match finished!');
        _matchListener?.cancel();
        _finishMatch();
      }
    }, onError: (error) {
      print('❌ Match listener error: $error');
    });
  }

  /// Update our progress to Firebase
  Future<void> _updateProgressToFirebase() async {
    if (_currentMatchId == null || _currentPlayerId == null || state.playingAgainstBot) {
      return;
    }

    try {
      await _multiplayerService!.updatePlayerProgress(
        _currentMatchId!,
        _currentPlayerId!,
        state.totalScore,
        state.currentPuzzleIndex,
      );
    } catch (e) {
      print('⚠️ Failed to update progress: $e');
    }
  }

  void cleanupMatch() {
    _timer?.stop();
    _botProgressTimer?.cancel();
    _matchListener?.cancel();
  }
}

final rankedProvider = NotifierProvider<RankedNotifier, RankedGameState>(() {
  return RankedNotifier();
});
