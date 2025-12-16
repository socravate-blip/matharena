import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matharena/features/game/presentation/providers/ranked_provider.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/logic/elo_calculator.dart';
import '../widgets/bot_progress_widget.dart';

class RankedPage extends ConsumerStatefulWidget {
  const RankedPage({super.key});

  @override
  ConsumerState<RankedPage> createState() => _RankedPageState();
}

class _RankedPageState extends ConsumerState<RankedPage> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final rankedState = ref.watch(rankedProvider);

    // Show winner dialog when match ends
    if (rankedState.showEndDialog && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWinnerDialog(context, ref, rankedState);
      });
    }

    // Reset dialog flag when new match starts
    if (rankedState.isPlaying && _dialogShown) {
      _dialogShown = false;
    }

    if (!rankedState.isPlaying) {
      return _buildStartScreen(context, ref);
    }

    return _buildGameScreen(context, ref, rankedState);
  }

  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RANKED',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, width: 60, color: Colors.grey[800]),
              const SizedBox(height: 32),
              Text(
                '2 Minutes · Score Points',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 64),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(rankedProvider.notifier).startGame(),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BEGIN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // DEBUG: Quick ELO switcher
              _buildDebugEloSwitcher(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugEloSwitcher(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'DEBUG - Quick ELO Switch',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.grey[600],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEloButton(ref, '🥉 Bronze', 1000),
              _buildEloButton(ref, '🥈 Silver', 1350),
              _buildEloButton(ref, '🥇 Gold', 1650),
              _buildEloButton(ref, '💎 Diamond', 1900),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEloButton(WidgetRef ref, String label, int elo) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final storage = ref.read(ratingStorageProvider);
          await storage.debugSetElo(elo);
          ref.invalidate(playerRatingProvider);
          // Show confirmation
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text('ELO set to $elo'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green[700],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, WidgetRef ref, dynamic state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth < 600 ? 48.0 : 56.0;
    final buttonWidth = screenWidth < 600 ? 48.0 : 56.0;
    final currentPuzzle = state.currentPuzzle;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RANKED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Row(
                        spacing: 16,
                        children: [
                          // Abandon button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => ref.read(rankedProvider.notifier).abandonMatch(),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red[700]!, width: 1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.flag, size: 14, color: Colors.red[300]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ABANDON',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${(state.secondsRemaining ~/ 60)}:${(state.secondsRemaining % 60).toString().padLeft(2, '0')}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: state.secondsRemaining <= 30
                                  ? Colors.red[300]
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            '${state.totalScore}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey[900]),
            // Player Progress Widget
            _buildPlayerProgress(state),
            // Bot Progress Widget
            const BotProgressWidget(),
            // Main Content - Different layout for Basic/Complex vs Game24/Matador
            Expanded(
              child: currentPuzzle?.type == PuzzleType.basic ||
                      currentPuzzle?.type == PuzzleType.complex
                  ? _buildArithmeticPuzzleContent(context, state, currentPuzzle)
                  : _buildExpressionPuzzleContent(
                      context, state, currentPuzzle),
            ),
            // Controls - Dynamic based on puzzle type
            _buildControls(
                context, ref, state, currentPuzzle, buttonHeight, buttonWidth),
          ],
        ),
      ),
    );
  }

  // Training-style layout for Basic/Complex puzzles - EXACT COPY from Training
  Widget _buildArithmeticPuzzleContent(
      BuildContext context, dynamic state, GamePuzzle? puzzle) {
    if (puzzle == null) return const SizedBox.shrink();

    String question = '';
    if (puzzle is BasicPuzzle) {
      question = '${puzzle.numberA} ${puzzle.operator} ${puzzle.numberB}';
    } else if (puzzle is ComplexPuzzle) {
      question = puzzle.useParentheses
          ? '${puzzle.numberA} ${puzzle.operator1} (${puzzle.numberB} ${puzzle.operator2} ${puzzle.numberC})'
          : '${puzzle.numberA} ${puzzle.operator1} ${puzzle.numberB} ${puzzle.operator2} ${puzzle.numberC}';
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          // Question with equals sign
          Text(
            '$question = ?',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 64,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 2),
              ),
            ),
            child: Text(
              state.expression.isEmpty ? '_' : state.expression,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 56,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Box layout for Game24/Matador puzzles
  Widget _buildExpressionPuzzleContent(
      BuildContext context, dynamic state, GamePuzzle? puzzle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        spacing: 24,
        children: [
          // Target Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  puzzle?.type == PuzzleType.game24 ? 'MAKE 24' : 'TARGET',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  state.target.toString(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Available numbers for Game24/Matador
                if (state.availableNumbers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      children: state.availableNumbers.map<Widget>((num) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey[700]!, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            num.toString(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          // Expression input
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[800]!, width: 1),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[950],
            ),
            child: Column(
              children: [
                Text(
                  state.expression.isEmpty
                      ? 'Build expression...'
                      : state.expression,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: state.expression.isEmpty
                        ? Colors.grey[700]
                        : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.currentResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '= ${state.currentResult}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: state.currentResult == state.target
                          ? Colors.green[400]
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Message
          if (state.message.isNotEmpty)
            Text(
              state.message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: state.message.contains('✅')
                    ? Colors.green[400]
                    : Colors.red[400],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerProgress(dynamic state) {
    final currentPuzzleIndex = state.currentPuzzleIndex;
    final totalPuzzles = state.matchQueue.length;
    
    // Overall match progress (like bot's progress bar)
    final progress = totalPuzzles > 0 
        ? (currentPuzzleIndex / totalPuzzles).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.cyan.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player Header
          Row(
            children: [
              // Player Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'YOU',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Player Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.cyan.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${state.totalScore}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[100],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Overall Match Progress Bar (like bot's)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Match progress (puzzles completed)
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.cyan,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentPuzzleIndex/$totalPuzzles',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.blue[200],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, dynamic state,
      GamePuzzle? puzzle, double buttonHeight, double buttonWidth) {
    if (puzzle?.type == PuzzleType.basic ||
        puzzle?.type == PuzzleType.complex) {
      // Number pad for arithmetic puzzles - EXACT COPY FROM TRAINING
      return _buildNumberPad(ref);
    } else {

      // Expression builder controls for Game24/Matador
      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            // Numbers Row (if available)
            if (state.availableNumbers.isNotEmpty)
              SizedBox(
                height: buttonHeight,
                child: Center(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.availableNumbers.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final num = state.availableNumbers[index];
                      final isUsed = state.usedNumberIndices.contains(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: buttonWidth,
                          child: _buildButton(
                            num.toString(),
                            isUsed
                                ? null
                                : () => ref
                                    .read(rankedProvider.notifier)
                                    .addToExpression(num.toString()),
                            isDisabled: isUsed,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Operators Row
            Row(
              children: [
                Expanded(
                    child: _buildButton(
                        '+',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression('+'))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        '-',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression('-'))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        '×',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression('*'))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        '÷',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression('/'))),
              ],
            ),
            // Actions Row
            Row(
              children: [
                Expanded(
                    child: _buildButton(
                        '(',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression('('))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        ')',
                        () => ref
                            .read(rankedProvider.notifier)
                            .addToExpression(')'))),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        'C',
                        () =>
                            ref.read(rankedProvider.notifier).clearExpression(),
                        isClear: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildButton(
                        '✓',
                        () =>
                            ref.read(rankedProvider.notifier).submitAnswer())),
              ],
            ),
          ],
        ),
      );
    }
  }

  // Number pad for arithmetic puzzles with auto-validation
  Widget _buildNumberPad(WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '7'),
            _buildNumButton(ref, '8'),
            _buildNumButton(ref, '9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '4'),
            _buildNumButton(ref, '5'),
            _buildNumButton(ref, '6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '1'),
            _buildNumButton(ref, '2'),
            _buildNumButton(ref, '3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '-'),
            _buildNumButton(ref, '0'),
            _buildBackButton(ref),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(WidgetRef ref, String num) {
    return GestureDetector(
      onTap: () => ref.read(rankedProvider.notifier).addInput(num),
      child: Container(
        width: 100,
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            num,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(rankedProvider.notifier).backspace(),
      child: Container(
        width: 100,
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback? onTap,
      {bool isDisabled = false, bool isClear = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isClear
                  ? Colors.red[700]!
                  : (isDisabled ? Colors.grey[900]! : Colors.grey[800]!),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isClear
                ? Colors.red[950]
                : (isDisabled ? Colors.grey[950] : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClear
                    ? Colors.red[300]
                    : (isDisabled ? Colors.grey[700] : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showWinnerDialog(BuildContext context, WidgetRef ref, dynamic state) {
    final playerWon = state.totalScore > state.botScore;
    final isDraw = state.totalScore == state.botScore;
    
    // Get player rating info
    final playerRatingAsync = ref.read(playerRatingProvider);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            ref.read(rankedProvider.notifier).resetToStart();
          },
          child: playerRatingAsync.when(
            data: (profile) {
              final oldRating = profile.history.isNotEmpty 
                  ? profile.history[profile.history.length - 1].rating - profile.history[profile.history.length - 1].ratingChange
                  : profile.currentRating;
              final ratingChange = profile.currentRating - oldRating;
              
              // Calculate bot's ELO change (inverse of player's result)
              // If player won (actualScore=1.0), bot lost (actualScore=0.0)
              final botActualScore = playerWon ? 0.0 : (isDraw ? 0.5 : 1.0);
              final botOldElo = state.botElo ?? 1200;
              final botNewElo = EloCalculator.calculateNewRating(
                currentRating: botOldElo,
                opponentRating: oldRating,
                actualScore: botActualScore,
                gamesPlayed: 30, // Assume bot is not a novice
              );
              final botEloChange = botNewElo - botOldElo;
              
              return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  playerWon ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                  playerWon ? Colors.green[800]!.withOpacity(0.9) : Colors.red[800]!.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: playerWon ? Colors.green[300]! : Colors.red[300]!,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (playerWon ? Colors.green : Colors.red).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result Icon
                Text(
                  playerWon ? '🏆' : isDraw ? '🤝' : '💀',
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                // Result Text
                Text(
                  playerWon ? 'VICTORY!' : isDraw ? 'DRAW!' : 'DEFEAT!',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                // Score Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Player Score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'YOU',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${state.totalScore}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.white24),
                      const SizedBox(height: 8),
                      // Bot Score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                state.botName?.toUpperCase() ?? 'BOT',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[200],
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${state.botScore}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[100],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ELO Evolution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ELO CHANGES',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white60,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Player ELO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'YOU',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$oldRating',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.currentRating}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (ratingChange >= 0 ? Colors.green : Colors.red).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${ratingChange >= 0 ? '+' : ''}$ratingChange',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ratingChange >= 0 ? Colors.green[300] : Colors.red[300],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bot ELO (simulated)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: Colors.orange, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                state.botName?.toUpperCase() ?? 'BOT',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.orange[200],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${state.botElo}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$botNewElo',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[100],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (botEloChange >= 0 ? Colors.green : Colors.red).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${botEloChange >= 0 ? '+' : ''}$botEloChange',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: botEloChange >= 0 ? Colors.green[300] : Colors.red[300],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tap to continue
                Text(
                  'Tap anywhere to continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Container(),
          ),
        ),
      ),
    ).then((_) {
      // Reset dialog flag and game state
      setState(() {
        _dialogShown = false;
      });
      ref.read(rankedProvider.notifier).resetToStart();
    });
  }
}
