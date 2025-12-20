import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/services/placement_service.dart';
import '../../domain/services/stats_service.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/logic/bot_ai.dart';
import 'placement_complete_page.dart';

/// Page de match de calibration (1, 2, ou 3)
class PlacementMatchPage extends StatefulWidget {
  final int matchNumber;
  final List<GamePerformance>? previousPerformances;

  const PlacementMatchPage({
    super.key,
    required this.matchNumber,
    this.previousPerformances,
  });

  @override
  State<PlacementMatchPage> createState() => _PlacementMatchPageState();
}

class _PlacementMatchPageState extends State<PlacementMatchPage> {
  late List<GamePuzzle> _puzzles;
  int _currentPuzzleIndex = 0;
  String _userAnswer = '';
  Set<int> _usedNumberIndices = <int>{}; // Game24: track used numbers
  List<int> _usedNumberHistory = <int>[]; // Game24: indices pressed in order
  int _correctAnswers = 0;
  int _myScore = 0; // Pour coller à l'UI ranked (points)

  // Bot calibration (réutilise la logique de course type ranked)
  late final BotAI _bot;
  final String _botName = 'BOT CALIBRATION';
  int _botPuzzleIndex = 0;
  int _botScore = 0;
  Timer? _botTimer;
  bool _matchFinished = false;

  List<int> _responseTimes = [];
  int _puzzleStartTime = 0;
  int _matchStartTime = 0;
  bool _isPlaying = false;
  int? _countdown;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _puzzles = PlacementService.generateCalibrationPuzzles(widget.matchNumber);
    _bot = BotAI(
      name: _botName,
      skillLevel: 1200,
      difficulty: BotDifficulty.competitive,
    );
    _matchStartTime = DateTime.now().millisecondsSinceEpoch;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _botTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 3);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        setState(() {
          _countdown = null;
          _isPlaying = true;
          _puzzleStartTime = DateTime.now().millisecondsSinceEpoch;
        });

        // Démarrer la course du bot au lancement du match.
        _startBotRaceLoop();
      } else {
        setState(() => _countdown = _countdown! - 1);
      }
    });
  }

  int _estimatePlayerHistoricalAvgMs() {
    if (_responseTimes.isEmpty) return 5000;
    final sum = _responseTimes.fold<int>(0, (a, b) => a + b);
    return (sum / _responseTimes.length).round().clamp(1500, 20000);
  }

  void _startBotRaceLoop() {
    if (!mounted || !_isPlaying || _matchFinished) return;
    if (_botPuzzleIndex >= _puzzles.length) {
      _endMatchBecauseBotFinished();
      return;
    }

    final currentBotPuzzle = _puzzles[_botPuzzleIndex];
    final delay = _bot.calculateDynamicDelay(
      currentBotPuzzle,
      playerHistoricalAvgMs: _estimatePlayerHistoricalAvgMs(),
    );

    _botTimer?.cancel();
    _botTimer = Timer(delay, () {
      if (!mounted || !_isPlaying || _matchFinished) return;

      setState(() {
        _botScore += currentBotPuzzle.maxPoints;
        _botPuzzleIndex++;
      });

      if (_botPuzzleIndex >= _puzzles.length) {
        _endMatchBecauseBotFinished();
      } else {
        _startBotRaceLoop();
      }
    });
  }

  void _endMatchBecauseBotFinished() {
    if (_matchFinished) return;
    _matchFinished = true;
    _botTimer?.cancel();
    setState(() => _isPlaying = false);
    _finishMatch();
  }

  void _onNumberPressed(String number) {
    if (!_isPlaying) return;

    final puzzle = _puzzles[_currentPuzzleIndex];

    // Expression puzzles (Game24/Matador) utilisent un builder.
    if (puzzle is Game24Puzzle || puzzle is MatadorPuzzle) {
      _onExpressionTokenPressed(number);
      return;
    }

    // Arithmetic puzzles: input numérique (comme ranked)
    setState(() {
      if (number == '⌫') {
        if (_userAnswer.isNotEmpty) {
          _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        }
      } else if (number == '-') {
        if (_userAnswer.isEmpty) {
          _userAnswer = '-';
        }
      } else {
        _userAnswer += number;
      }
    });
  }

  void _onExpressionNumberPressed(int index, int value) {
    if (!_isPlaying) return;
    if (_usedNumberIndices.contains(index)) return;

    setState(() {
      _userAnswer += value.toString();
      _usedNumberIndices = {..._usedNumberIndices, index};
      _usedNumberHistory = [..._usedNumberHistory, index];
    });
  }

  void _onExpressionBackspace() {
    if (_userAnswer.isEmpty) return;

    // If the expression ends with a number, delete the whole number token.
    final endDigits = RegExp(r'\d+$').firstMatch(_userAnswer)?.group(0);
    if (endDigits != null && endDigits.isNotEmpty) {
      final newExpr =
          _userAnswer.substring(0, _userAnswer.length - endDigits.length);

      // Free the last used number index (matches how we append numbers).
      if (_usedNumberHistory.isNotEmpty) {
        final lastIdx = _usedNumberHistory.last;
        final newHistory = List<int>.from(_usedNumberHistory)..removeLast();
        final newUsed = Set<int>.from(_usedNumberIndices)..remove(lastIdx);
        setState(() {
          _userAnswer = newExpr;
          _usedNumberHistory = newHistory;
          _usedNumberIndices = newUsed;
        });
        return;
      }

      setState(() {
        _userAnswer = newExpr;
      });
      return;
    }

    // Otherwise delete a single char.
    setState(() {
      _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
    });
  }

  void _onExpressionTokenPressed(String token) {
    if (!_isPlaying) return;

    setState(() {
      if (token == '⌫') {
        // handled outside setState for smarter deletion
      } else if (token == 'C') {
        _userAnswer = '';
        _usedNumberIndices = <int>{};
        _usedNumberHistory = <int>[];
      } else {
        _userAnswer += token;
      }
    });

    if (token == '⌫') {
      _onExpressionBackspace();
    }
  }

  Future<void> _submitAnswer() async {
    if (!_isPlaying || _userAnswer.isEmpty) return;
    if (_matchFinished) return;

    final puzzle = _puzzles[_currentPuzzleIndex];
    final responseTime =
        DateTime.now().millisecondsSinceEpoch - _puzzleStartTime;

    // Valider la réponse
    bool isCorrect = false;
    if (puzzle is Game24Puzzle || puzzle is MatadorPuzzle) {
      isCorrect = puzzle.validateAnswer(_userAnswer);
    } else {
      try {
        final answer = int.parse(_userAnswer);
        isCorrect = puzzle.validateAnswer(answer);
      } catch (_) {
        isCorrect = false;
      }
    }

    // Enregistrer les résultats
    _responseTimes.add(responseTime);
    if (isCorrect) {
      _correctAnswers++;
      _myScore += puzzle.maxPoints;
    }

    // Feedback visuel
    _showFeedback(isCorrect);

    // Passer au puzzle suivant ou terminer
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentPuzzleIndex < _puzzles.length - 1) {
      setState(() {
        _currentPuzzleIndex++;
        _userAnswer = '';
        _usedNumberIndices = <int>{};
        _usedNumberHistory = <int>[];
        _puzzleStartTime = DateTime.now().millisecondsSinceEpoch;
      });
    } else {
      _matchFinished = true;
      _botTimer?.cancel();
      _finishMatch();
    }
  }

  void _showFeedback(bool isCorrect) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green[700] : Colors.red[700],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isCorrect ? '✓ Correct!' : '✗ Incorrect',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlayEntry.remove();
    });
  }

  void _finishMatch() async {
    final totalTime = DateTime.now().millisecondsSinceEpoch - _matchStartTime;
    final puzzleType =
        PlacementService.getPuzzleTypeForMatch(widget.matchNumber);

    final performance = GamePerformance(
      matchNumber: widget.matchNumber,
      puzzleType: puzzleType,
      correctAnswers: _correctAnswers,
      totalPuzzles: _puzzles.length,
      totalTimeMs: totalTime,
      responseTimes: _responseTimes,
    );

    print('📊 Match ${widget.matchNumber} terminé:');
    print('   Précision: ${performance.accuracy.toStringAsFixed(1)}%');
    print(
        '   Temps moyen: ${performance.averageResponseTime.toStringAsFixed(0)}ms');

    // Ajouter aux performances précédentes
    final List<GamePerformance> allPerformances = <GamePerformance>[
      ...(widget.previousPerformances ?? const <GamePerformance>[]),
      performance,
    ];

    if (widget.matchNumber < PlacementService.totalPlacementMatches) {
      // Passer au match suivant
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlacementMatchPage(
              matchNumber: widget.matchNumber + 1,
              previousPerformances: allPerformances,
            ),
          ),
        );
      }
    } else {
      // Tous les matchs terminés : calculer l'ELO initial
      final initialElo = PlacementService.calculateInitialElo(allPerformances);

      // Toujours aligner le profil local (RatingStorage) avec l'ELO du placement.
      try {
        final storage = RatingStorage();
        final profile = await storage.getProfile();
        profile.currentRating = initialElo;
        profile.peakRating = initialElo;
        profile.gamesPlayed = 0;
        profile.wins = 0;
        profile.losses = 0;
        profile.draws = 0;
        profile.history = [];
        await storage.saveProfile(profile);
      } catch (e) {
        print('❌ Error saving local placement ELO: $e');
      }

      // Sauvegarder dans Firebase si disponible.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final statsService = StatsService();
          await statsService.markPlacementComplete(uid, initialElo);
        } catch (e) {
          print('❌ Error saving placement to Firebase: $e');
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlacementCompletePage(
              performances: allPerformances,
              initialElo: initialElo,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_countdown != null) {
      return _buildCountdownScreen();
    }

    final progress =
        _puzzles.isEmpty ? 0.0 : (_currentPuzzleIndex / _puzzles.length);
    final botProgress =
      _puzzles.isEmpty ? 0.0 : (_botPuzzleIndex / _puzzles.length);
    final puzzle = _puzzles[_currentPuzzleIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildRankedStyleHeader(),
            _buildBotProgressBar(botProgress),
            _buildMyProgressBar(progress),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPuzzleDisplay(puzzle),
                    const SizedBox(height: 32),
                    _buildAnswerDisplay(),
                  ],
                ),
              ),
            ),
            _buildInputPad(puzzle),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: !_isPlaying ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'VALIDER',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI (style Ranked)
  // ============================================================

  Widget _buildRankedStyleHeader() {
    final type = PlacementService.getPuzzleTypeForMatch(widget.matchNumber);
    final typeName = type.toString().split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CALIBRATION ${widget.matchNumber}/3',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Text(
              typeName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VOUS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_myScore',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[900],
                  valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentPuzzleIndex/${_puzzles.length}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_botName',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_botScore',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[900],
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_botPuzzleIndex/${_puzzles.length}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleDisplay(GamePuzzle puzzle) {
    String question = '';
    if (puzzle is BasicPuzzle) {
      question = puzzle.question;
    } else if (puzzle is ComplexPuzzle) {
      question = puzzle.question;
    } else if (puzzle is Game24Puzzle) {
      question = puzzle.question;
    } else if (puzzle is MatadorPuzzle) {
      question = puzzle.question;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        question,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnswerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
      ),
      child: Text(
        _userAnswer.isEmpty ? '_' : _userAnswer,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInputPad(GamePuzzle puzzle) {
    if (puzzle is Game24Puzzle) {
      return _buildGame24Pad(puzzle);
    }
    // Par défaut: pad numérique (Basic/Complex)
    return _buildNumPad();
  }

  Widget _buildNumPad() {
    final numbers = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '-',
      '0',
      '⌫'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final value = numbers[index];
          return _buildPadButton(value, onTap: () => _onNumberPressed(value));
        },
      ),
    );
  }

  Widget _buildGame24Pad(Game24Puzzle puzzle) {
    final ops = ['+', '-', '*', '/', '(', ')', '⌫', 'C'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombres disponibles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(puzzle.availableNumbers.length, (i) {
              final v = puzzle.availableNumbers[i];
              final used = _usedNumberIndices.contains(i);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == puzzle.availableNumbers.length - 1 ? 0 : 12),
                  child: InkWell(
                    onTap: used ? null : () => _onExpressionNumberPressed(i, v),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: used ? Colors.grey[900]! : Colors.grey[800]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: used ? Colors.grey[900] : null,
                      ),
                      child: Center(
                        child: Text(
                          '$v',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: used ? Colors.grey[700] : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: ops.length,
            itemBuilder: (context, index) {
              final value = ops[index];
              return _buildPadButton(
                value,
                onTap: () => _onExpressionTokenPressed(value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPadButton(String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: !_isPlaying ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Calibration ${widget.matchNumber}/3',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                PlacementService.getPuzzleTypeForMatch(widget.matchNumber)
                    .toString()
                    .split('.')
                    .last
                    .toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                '$_countdown',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calibration ${widget.matchNumber}/3',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                PlacementService.getPuzzleTypeForMatch(widget.matchNumber)
                    .toString()
                    .split('.')
                    .last,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            '${_currentPuzzleIndex + 1}/${_puzzles.length}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}
