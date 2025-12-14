import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_provider.dart';

class GameHomePage extends ConsumerWidget {
  const GameHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final gameState = ref.watch(gameProvider);

      if (!gameState.isPlaying) {
        return _buildStartScreen(context, ref);
      }

      return _buildGameScreen(context, ref, gameState);
    } catch (e) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// Crypto Wallet Start Screen
  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'MATHARENA',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 48),
                // Subtitle
                Text(
                  'Master the numbers.\nSecure the solution.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.8,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 80),
                // Simple Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(gameProvider.notifier).startGame();
                    },
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crypto Wallet Game Screen
  Widget _buildGameScreen(
    BuildContext context,
    WidgetRef ref,
    dynamic gameState,
  ) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Column(
            children: [
              // Header: Title + Score (Minimalist)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MATHARENA',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '${gameState.score}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 1,
                color: Colors.grey[900],
              ),
              // Main Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      // Target Display (Simple Box)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TARGET',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${gameState.target}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Current Expression
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[950],
                        ),
                        child: Text(
                          gameState.expression.isEmpty
                              ? '0'
                              : gameState.expression,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            color: gameState.expression.isEmpty
                                ? Colors.grey[700]
                                : Colors.white,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Message Feedback
                      if (gameState.message.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[800]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[950],
                          ),
                          child: Text(
                            gameState.message,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Input Area (Bottom)
              _buildInputPanel(context, ref, gameState),
            ],
          ),
        ),
      ),
    );
  }

  /// Input Panel with Button Grid (Minimalist)
  Widget _buildInputPanel(
    BuildContext context,
    WidgetRef ref,
    dynamic gameState,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth < 600 ? 48.0 : 56.0;
    final buttonWidth = screenWidth < 600 ? 48.0 : 56.0;
    
    // Sort numbers in ascending order
    final sortedNumbers = List<int>.from(gameState.availableNumbers)..sort();
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[900]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          spacing: 12,
          children: [
            // Row 1: Numbers
            SizedBox(
              height: buttonHeight,
              child: Center(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedNumbers.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final num = sortedNumbers[index];
                    // Find the original index in availableNumbers for tracking usage
                    final originalIndex = gameState.availableNumbers.indexOf(num);
                    final isUsed = gameState.usedNumberIndices.contains(originalIndex);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: buttonWidth,
                        child: _buildMinimalButton(
                          label: num.toString(),
                          isDisabled: isUsed,
                          onPressed: isUsed
                              ? null
                              : () => ref.read(gameProvider.notifier).addToExpression(num.toString()),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Row 2: Operators
            Row(
              children: [
                Expanded(
                  child: _buildOperatorButton('+', () =>
                      ref.read(gameProvider.notifier).addToExpression('+')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOperatorButton('-', () =>
                      ref.read(gameProvider.notifier).addToExpression('-')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOperatorButton('×', () =>
                      ref.read(gameProvider.notifier).addToExpression('*')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOperatorButton('÷', () =>
                      ref.read(gameProvider.notifier).addToExpression('/')),
                ),
              ],
            ),
            // Row 3: Parentheses + Actions
            Row(
              children: [
                Expanded(
                  child: _buildMinimalButton(
                    label: '(',
                    onPressed: () =>
                        ref.read(gameProvider.notifier).addToExpression('('),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMinimalButton(
                    label: ')',
                    onPressed: () =>
                        ref.read(gameProvider.notifier).addToExpression(')'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    'C',
                    () => ref.read(gameProvider.notifier).clearExpression(),
                    isClear: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton('✓', () {
                    final notifier = ref.read(gameProvider.notifier);
                    final currentContext = context;
                    final currentGameState = gameState;
                    notifier.submitAnswer();

                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (currentContext.mounted) {
                        if (currentGameState.message.contains('MATHADOR')) {
                          _showMathadorDialog(currentContext);
                        } else if (currentGameState.message.contains('Correct')) {
                          _showCorrectDialog(currentContext, currentGameState);
                        }
                      }
                    });
                  }),
                ),
              ],
            ),
            // Solutions Button
            SizedBox(
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSolutions(context, gameState.solutions),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'SOLUTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Minimal Button for Numbers
  Widget _buildMinimalButton({
    required String label,
    required VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled ? Colors.grey[900]! : Colors.grey[800]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isDisabled ? Colors.grey[950] : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDisabled ? Colors.grey[700] : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Operator Button
  Widget _buildOperatorButton(String label, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Action Button (C, ✓)
  Widget _buildActionButton(String label, VoidCallback onPressed, {bool isClear = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isClear ? Colors.red[700]! : Colors.grey[700]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isClear ? Colors.red[950] : Colors.grey[850],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isClear ? Colors.red[300] : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mathador Victory Dialog (Minimalist)
  void _showMathadorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        title: Text(
          'MATHADOR',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All 5 numbers + all 4 operators',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+13 POINTS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CONTINUE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Correct Answer Dialog (Minimalist)
  void _showCorrectDialog(BuildContext context, dynamic gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        title: Text(
          'CORRECT',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${_extractPoints(gameState.message)} POINTS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (gameState.lastScoreBreakdown != null) ...[
              const SizedBox(height: 16),
              Text(
                'Breakdown:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[800]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[950],
                ),
                child: Text(
                  gameState.lastScoreBreakdown,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NEXT',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Solutions Bottom Sheet (Minimalist)
  void _showSolutions(BuildContext context, List<String> solutions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      builder: (context) => Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey[800]!,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOLUTIONS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: solutions.length,
                  itemBuilder: (context, index) {
                    final solution = solutions[index];
                    final isMathador = _containsAllOperators(solution);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isMathador
                                ? Colors.white
                                : Colors.grey[800]!,
                            width: isMathador ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isMathador ? Colors.grey[900] : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                solution,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: isMathador
                                      ? Colors.white
                                      : Colors.grey[500],
                                  fontWeight: isMathador
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            if (isMathador)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  '★',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper: Extract points from message
  int _extractPoints(String message) {
    final regex = RegExp(r'\+(\d+)');
    final match = regex.firstMatch(message);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Helper: Check if solution contains all 4 operators
  bool _containsAllOperators(String expression) {
    final operators = {'+', '-', '*', '/'};
    for (final op in operators) {
      if (!expression.contains(op)) {
        return false;
      }
    }
    return true;
  }
}
