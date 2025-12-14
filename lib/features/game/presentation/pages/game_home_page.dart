import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class GameHomePage extends ConsumerWidget {
  const GameHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    if (!gameState.isPlaying) {
      return _buildStartScreen(context, ref);
    }

    return _buildGameScreen(context, ref, gameState);
  }

  /// Start Game Screen
  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MathArena'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MATADOR',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: const Color(0xFF00D9FF),
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Combine numbers to reach the target',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                ref.read(gameProvider.notifier).startGame();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
                backgroundColor: const Color(0xFF00D9FF),
              ),
              child: Text(
                'START GAME',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Active Game Screen
  Widget _buildGameScreen(
    BuildContext context,
    WidgetRef ref,
    dynamic gameState,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MathArena - Game'),
        centerTitle: true,
        actions: [
          // Solutions Button
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              _showSolutions(context, gameState.solutions);
            },
            tooltip: 'Show Solutions',
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Score: ${gameState.score}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFFF006E),
                      fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Matador Bonus Badge
            if (gameState.isMatadorSolution)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '🏆 MATADOR BONUS! 🏆',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (gameState.isMatadorSolution) const SizedBox(height: 16),
            // Target Number (Big)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'TARGET',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${gameState.target}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: const Color(0xFF00D9FF),
                          fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Current Expression (Medium)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border:
                    Border.all(color: const Color(0xFFFF006E), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                gameState.expression.isEmpty
                    ? 'Enter expression'
                    : gameState.expression,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: gameState.expression.isEmpty
                          ? Colors.grey
                          : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message Feedback
            if (gameState.message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gameState.message.contains('Correct')
                      ? Colors.green.withOpacity(0.2)
                      : gameState.message.contains('Wrong')
                          ? Colors.red.withOpacity(0.2)
                          : Colors.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gameState.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: gameState.message.contains('Correct')
                            ? Colors.green
                            : gameState.message.contains('Wrong')
                                ? Colors.red
                                : Colors.yellow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),

            // Available Numbers Grid
            Text(
              'Available Numbers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: gameState.availableNumbers.asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final num = entry.value;
                final isUsed = gameState.usedNumberIndices.contains(index);
                return _buildNumberButton(
                  context,
                  ref,
                  num.toString(),
                  isUsed: isUsed,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Operators
            Text(
              'Operators',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['+', '-', '*', '/'].map((op) {
                return _buildOperatorButton(context, ref, op);
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Parentheses
            Text(
              'Parentheses',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['(', ')'].map((paren) {
                return _buildParenthesesButton(context, ref, paren);
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Clear and Submit Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(gameProvider.notifier).clearExpression();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('CLEAR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final notifier = ref.read(gameProvider.notifier);
                      notifier.submitAnswer();
                      
                      // Show feedback dialog after a short delay
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (gameState.message.contains('MATHADOR')) {
                          _showMathadorDialog(context);
                        } else if (gameState.message.contains('Correct')) {
                          _showCorrectDialog(context, gameState);
                        }
                      });
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('SUBMIT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00D9FF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Number Button Widget
  Widget _buildNumberButton(
    BuildContext context,
    WidgetRef ref,
    String number, {
    bool isUsed = false,
  }) {
    return ElevatedButton(
      onPressed: isUsed
          ? null
          : () {
              ref.read(gameProvider.notifier).addToExpression(number);
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: isUsed ? Colors.grey[600] : const Color(0xFF00D9FF),
        disabledBackgroundColor: Colors.grey[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        number,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isUsed ? Colors.grey[400] : Colors.black,
              fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Operator Button Widget
  Widget _buildOperatorButton(
    BuildContext context,
    WidgetRef ref,
    String operator,
  ) {
    return ElevatedButton(
      onPressed: () {
        ref.read(gameProvider.notifier).addToExpression(operator);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFFFF006E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        operator,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Parentheses Button Widget
  Widget _buildParenthesesButton(
    BuildContext context,
    WidgetRef ref,
    String parenthesis,
  ) {
    return ElevatedButton(
      onPressed: () {
        ref.read(gameProvider.notifier).addToExpression(parenthesis);
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: Colors.grey[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        parenthesis,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Shows the Mathador bonus dialog
  void _showMathadorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '🏆 MATHADOR! 🏆',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You used all 5 numbers and all 4 operators!\n\n+13 POINTS',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  /// Shows the correct answer dialog with score breakdown
  void _showCorrectDialog(BuildContext context, dynamic gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          '✅ Correct!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points: +${_extractPoints(gameState.message)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (gameState.lastScoreBreakdown != null) ...[
              const SizedBox(height: 12),
              Text(
                'Breakdown:\n${gameState.lastScoreBreakdown}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Next Round', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  /// Shows all available solutions in a bottom sheet
  void _showSolutions(BuildContext context, List<String> solutions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Solutions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: solutions.length,
                itemBuilder: (context, index) {
                  final solution = solutions[index];
                  final isMathador = _containsAllOperators(solution);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMathador ? Colors.amber.withOpacity(0.2) : const Color(0xFF2E2E2E),
                      border: Border.all(
                        color: isMathador ? Colors.amber : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            solution,
                            style: TextStyle(
                              color: isMathador ? Colors.amber : Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (isMathador)
                          const Text(
                            '🏆 Mathador',
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
