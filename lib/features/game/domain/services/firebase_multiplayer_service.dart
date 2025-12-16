import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/bot_ai.dart';
import '../models/puzzle.dart';
import 'multiplayer_service.dart';

/// Enterprise-grade Firebase multiplayer implementation
/// with real-time opponent tracking and security
class FirebaseMultiplayerService implements MultiplayerService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _botSimulationTimer;
  BotAI? _currentBot;

  @override
  Future<void> initialize() async {
    try {
      // Ensure Firebase is initialized
      // This should be called in main.dart: await Firebase.initializeApp();

      // Sign in anonymously for secure access
      if (_auth.currentUser == null) {
        print('🔐 Signing in anonymously...');
        final userCredential = await _auth.signInAnonymously();
        print('✅ Signed in as: ${userCredential.user?.uid}');
        print('📝 User isAnonymous: ${userCredential.user?.isAnonymous}');
      } else {
        print('✅ Already signed in as: ${_auth.currentUser?.uid}');
      }
    } catch (e, stackTrace) {
      print('❌ Firebase initialization failed!');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('');
      print('🔧 TROUBLESHOOTING:');
      print('1. Vérifiez que Firebase Authentication est activé dans la console');
      print('2. Activez "Anonymous" dans Authentication > Sign-in method');
      print('3. Vérifiez que firebase_options.dart contient les bonnes clés');
      print('');
      rethrow;
    }
  }

  @override
  Future<String> joinQueue(
      String playerId, String playerName, int playerElo) async {
    print('🔍 joinQueue called - Player: $playerId, ELO: $playerElo');
    
    final queueRef = _database.child('queue');
    final matchesRef = _database.child('matches');

    // 🔒 Check if player is already in an active match & clean old matches
    final allMatches = await matchesRef.get();
    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutesAgo = now - (5 * 60 * 1000); // 5 minutes
    
    if (allMatches.exists) {
      final matches = Map<String, dynamic>.from(allMatches.value as Map);
      for (final matchEntry in matches.entries) {
        final match = Map<String, dynamic>.from(matchEntry.value as Map);
        final matchId = matchEntry.key;
        final createdAt = match['createdAt'] as int? ?? 0;
        final state = match['state'] as String?;
        
        // Delete matches older than 5 minutes that are still in "waiting" state
        if (state == 'waiting' && createdAt < fiveMinutesAgo) {
          print('🧹 Cleaning old match: $matchId');
          await matchesRef.child(matchId).remove();
          continue;
        }
        
        // Only check non-finished matches
        if (state != 'finished') {
          final p1 = Map<String, dynamic>.from(match['player1'] as Map);
          final p2 = Map<String, dynamic>.from(match['player2'] as Map);
          
          // If player is already in this match, return it
          if (p1['id'] == playerId || p2['id'] == playerId) {
            print('♻️ Player already in active match: $matchId');
            return matchId;
          }
        }
      }
    }

    // Search for available opponent with similar ELO (±200)
    print('📡 Checking queue for opponents...');
    final queueSnapshot = await queueRef.get();
    print('📊 Queue snapshot exists: ${queueSnapshot.exists}');

    if (queueSnapshot.exists) {
      final queue = Map<String, dynamic>.from(queueSnapshot.value as Map);
      final oneMinuteAgo = now - (60 * 1000); // 1 minute

      for (final entry in queue.entries) {
        final waiting = Map<String, dynamic>.from(entry.value as Map);
        final waitingElo = waiting['elo'] as int;
        final waitingId = waiting['id'] as String;
        final joinedAt = waiting['joinedAt'] as int? ?? 0;

        // Clean up stale queue entries (older than 1 minute)
        if (joinedAt < oneMinuteAgo) {
          print('🧹 Cleaning stale queue entry: $waitingId');
          await queueRef.child(entry.key).remove();
          continue;
        }

        // Skip self
        if (waitingId == playerId) continue;

        // Check ELO range
        if ((waitingElo - playerElo).abs() <= 200) {
          // Found a match!
          final matchId =
              'match_${DateTime.now().millisecondsSinceEpoch}_${playerId.substring(0, 8)}';

          // Create match
          await matchesRef.child(matchId).set({
            'matchId': matchId,
            'player1': {
              'id': waitingId,
              'name': waiting['name'],
              'elo': waitingElo,
              'isBot': false,
              'score': 0,
              'currentPuzzleIndex': 0,
              'isReady': false,
            },
            'player2': {
              'id': playerId,
              'name': playerName,
              'elo': playerElo,
              'isBot': false,
              'score': 0,
              'currentPuzzleIndex': 0,
              'isReady': false,
            },
            'puzzles': [],
            'state': 'waiting',
            'createdAt': ServerValue.timestamp,
          });

          // Remove both from queue
          await queueRef.child(entry.key).remove();
          await queueRef.child(playerId).remove();

          return matchId;
        }
      }
    }

    // No match found - add to queue
    print('➕ Adding player to queue...');
    await queueRef.child(playerId).set({
      'id': playerId,
      'name': playerName,
      'elo': playerElo,
      'joinedAt': ServerValue.timestamp,
    });
    print('✅ Player added to queue, waiting for opponent...');

    // Wait for opponent (5 second timeout)
    final completer = Completer<String>();
    StreamSubscription? subscription;
    Timer? timeoutTimer;

    subscription = queueRef.child(playerId).onValue.listen((event) async {
      if (!event.snapshot.exists) {
        // Removed from queue = matched!
        // Find our match
        final allMatches = await matchesRef.get();
        if (allMatches.exists) {
          final matches = Map<String, dynamic>.from(allMatches.value as Map);
          for (final matchEntry in matches.entries) {
            final match = Map<String, dynamic>.from(matchEntry.value as Map);
            final p1 = Map<String, dynamic>.from(match['player1'] as Map);
            final p2 = Map<String, dynamic>.from(match['player2'] as Map);

            if (p1['id'] == playerId || p2['id'] == playerId) {
              timeoutTimer?.cancel();
              subscription?.cancel();
              if (!completer.isCompleted) {
                completer.complete(match['matchId'] as String);
              }
              return;
            }
          }
        }
      }
    });

    // Timeout: create bot match
    timeoutTimer = Timer(const Duration(seconds: 5), () async {
      print('⏱️ Timeout reached - creating bot match...');
      subscription?.cancel();
      if (!completer.isCompleted) {
        // Remove from queue
        await queueRef.child(playerId).remove();
        print('🗑️ Removed player from queue');

        // Create bot match
        final matchId = await _createBotMatch(playerId, playerName, playerElo);
        print('🤖 Bot match created: $matchId');
        completer.complete(matchId);
      }
    });

    return completer.future;
  }

  Future<String> _createBotMatch(
      String playerId, String playerName, int playerElo) async {
    try {
      final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}_bot';
      print('🎮 Creating bot match: $matchId');

      // Create bot with matching skill
      _currentBot = BotAI.matchingSkill(playerElo);
      print('🤖 Bot created: ${_currentBot!.name} (ELO: ${_currentBot!.skillLevel})');

      print('💾 Saving match to Firebase...');
      await _database.child('matches/$matchId').set({
      'matchId': matchId,
      'player1': {
        'id': playerId,
        'name': playerName,
        'elo': playerElo,
        'isBot': false,
        'score': 0,
        'currentPuzzleIndex': 0,
        'isReady': false,
      },
      'player2': {
        'id': 'bot_$matchId',
        'name': _currentBot!.name,
        'elo': _currentBot!.skillLevel,
        'isBot': true,
        'score': 0,
        'currentPuzzleIndex': 0,
        'isReady': true, // Bot is always ready
      },
      'puzzles': [], // Will be set by the client
      'state': 'waiting',
      'createdAt': ServerValue.timestamp,
    });

      print('✅ Bot match saved to Firebase');
      return matchId;
    } catch (e, stackTrace) {
      print('❌ Failed to create bot match!');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      print('');
      print('🔧 TROUBLESHOOTING:');
      print('1. Ouvrez Firebase Console: https://console.firebase.google.com');
      print('2. Vérifiez Realtime Database > Règles');
      print('3. Pour tester, utilisez: {"rules": {".read": "auth != null", ".write": "auth != null"}}');
      print('4. Vérifiez que l\'URL database est correcte dans firebase_options.dart');
      print('');
      rethrow;
    }
  }

  /// Save puzzles to Firebase (called by player1)
  Future<void> savePuzzles(String matchId, List<Map<String, dynamic>> puzzles) async {
    try {
      print('💾 Saving ${puzzles.length} puzzles to Firebase for match: $matchId');
      await _database.child('matches/$matchId/puzzles').set(puzzles);
      print('✅ Puzzles saved to Firebase');
    } catch (e) {
      print('❌ Failed to save puzzles: $e');
      rethrow;
    }
  }

  /// Load puzzles from Firebase (called by player2)
  Future<List<Map<String, dynamic>>> loadPuzzles(String matchId) async {
    try {
      print('📥 Loading puzzles from Firebase for match: $matchId');
      final snapshot = await _database.child('matches/$matchId/puzzles').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('⚠️ No puzzles found in Firebase');
        return [];
      }
      
      final puzzles = (snapshot.value as List).cast<Map<dynamic, dynamic>>();
      final result = puzzles.map((p) => Map<String, dynamic>.from(p)).toList();
      print('✅ Loaded ${result.length} puzzles from Firebase');
      return result;
    } catch (e) {
      print('❌ Failed to load puzzles: $e');
      rethrow;
    }
  }

  @override
  Future<void> leaveQueue(String playerId) async {
    await _database.child('queue/$playerId').remove();
  }

  @override
  Stream<MultiplayerMatch> watchMatch(String matchId) {
    return _database.child('matches/$matchId').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw Exception('Match not found');
      }

      // Firebase returns LinkedMap - need to properly convert
      final rawData = event.snapshot.value as Map<Object?, Object?>;
      final data = rawData.map((key, value) => MapEntry(key.toString(), value));
      return MultiplayerMatch.fromJson(data);
    });
  }

  @override
  Future<void> updatePlayerProgress(
    String matchId,
    String playerId,
    int score,
    int currentPuzzleIndex,
  ) async {
    final matchRef = _database.child('matches/$matchId');
    final snapshot = await matchRef.get();

    if (!snapshot.exists) return;

    final match = Map<String, dynamic>.from(snapshot.value as Map);
    final player1 = Map<String, dynamic>.from(match['player1'] as Map);

    final isPlayer1 = player1['id'] == playerId;
    final playerPath = isPlayer1 ? 'player1' : 'player2';

    await matchRef.child(playerPath).update({
      'score': score,
      'currentPuzzleIndex': currentPuzzleIndex,
      'lastUpdate': ServerValue.timestamp,
    });
  }

  @override
  Future<void> markReady(String matchId, String playerId) async {
    final matchRef = _database.child('matches/$matchId');
    final snapshot = await matchRef.get();

    if (!snapshot.exists) return;

    final match = Map<String, dynamic>.from(snapshot.value as Map);
    final player1 = Map<String, dynamic>.from(match['player1'] as Map);

    final isPlayer1 = player1['id'] == playerId;
    final playerPath = isPlayer1 ? 'player1' : 'player2';

    await matchRef.child(playerPath).update({'isReady': true});

    // Check if both ready -> start match
    final updatedSnapshot = await matchRef.get();
    final updatedMatch =
        Map<String, dynamic>.from(updatedSnapshot.value as Map);
    final p1 = Map<String, dynamic>.from(updatedMatch['player1'] as Map);
    final p2 = Map<String, dynamic>.from(updatedMatch['player2'] as Map);

    if (p1['isReady'] == true && p2['isReady'] == true) {
      await matchRef.update({
        'state': 'inProgress',
        'startedAt': ServerValue.timestamp,
      });

      // Start bot simulation if applicable
      if (p2['isBot'] == true && _currentBot != null) {
        _startBotSimulation(matchId);
      }
    }
  }

  void _startBotSimulation(String matchId) {
    // Bot will solve puzzles with realistic delays
    _botSimulationTimer?.cancel();

    _botSimulationTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      // This will be called from the ranked provider when puzzles are loaded
      // For now, just a placeholder
    });
  }

  /// Simulate bot solving a puzzle
  Future<void> simulateBotAnswer(
    String matchId,
    dynamic puzzle,
    int puzzleIndex,
  ) async {
    if (_currentBot == null) return;

    // Calculate solve time
    final solveTime = _currentBot!.calculateSolveTime(puzzle);

    await Future.delayed(solveTime);

    // Attempt to solve
    dynamic answer;
    bool isCorrect = false;
    int pointsEarned = 0;

    if (puzzle.type == PuzzleType.basic || puzzle.type == PuzzleType.complex) {
      answer = _currentBot!.solveArithmetic(puzzle);
      isCorrect = answer == puzzle.targetValue;
      pointsEarned = isCorrect ? puzzle.maxPoints : 0;
    } else {
      answer = _currentBot!.solveExpression(puzzle);
      isCorrect = answer != null;
      pointsEarned = isCorrect ? puzzle.maxPoints : 0;
    }

    if (isCorrect) {
      // Update bot progress
      final matchRef = _database.child('matches/$matchId');
      final snapshot = await matchRef.get();

      if (snapshot.exists) {
        final match = Map<String, dynamic>.from(snapshot.value as Map);
        final bot = Map<String, dynamic>.from(match['player2'] as Map);

        await matchRef.child('player2').update({
          'score': (bot['score'] as int) + pointsEarned,
          'currentPuzzleIndex': puzzleIndex + 1,
          'lastUpdate': ServerValue.timestamp,
        });
      }
    }
  }

  @override
  Future<void> submitAnswer(
    String matchId,
    String playerId,
    dynamic answer,
    bool isCorrect,
    int pointsEarned,
  ) async {
    // Track answer in match history
    await _database.child('matches/$matchId/answers').push().set({
      'playerId': playerId,
      'answer': answer?.toString(),
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> completeMatch(String matchId) async {
    await _database.child('matches/$matchId').update({
      'state': 'completed',
      'completedAt': ServerValue.timestamp,
    });

    _botSimulationTimer?.cancel();
    _currentBot = null;
  }

  /// Mark match as finished
  Future<void> finishMatch(String matchId) async {
    await _database.child('matches/$matchId').update({
      'state': 'finished',
      'finishedAt': ServerValue.timestamp,
    });

    _botSimulationTimer?.cancel();
    _currentBot = null;
  }

  @override
  Future<MatchPlayer?> getOpponentState(
      String matchId, String myPlayerId) async {
    final snapshot = await _database.child('matches/$matchId').get();

    if (!snapshot.exists) return null;

    final match = Map<String, dynamic>.from(snapshot.value as Map);
    final player1 = Map<String, dynamic>.from(match['player1'] as Map);
    final player2 = Map<String, dynamic>.from(match['player2'] as Map);

    return player1['id'] == myPlayerId
        ? MatchPlayer.fromJson(player2)
        : MatchPlayer.fromJson(player1);
  }

  /// Get match data from Firebase
  Future<Map<String, dynamic>?> getMatchData(String matchId) async {
    final snapshot = await _database.child('matches/$matchId').get();
    if (!snapshot.exists) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  void dispose() {
    _botSimulationTimer?.cancel();
  }
}
