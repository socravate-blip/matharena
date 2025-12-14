import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/matador_engine.dart';

/// Game state class
class GameState {
  final int target;
  final List<int> availableNumbers;
  final String expression;
  final int score;
  final bool isPlaying;
  final String message;
  final bool isMatadorSolution;
  final Set<int> usedNumberIndices; // Track which number buttons are used
  final List<String> solutions; // All valid solutions for this level
  final String? lastScoreBreakdown; // Points breakdown for feedback dialog

  const GameState({
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
  });

  /// Copy with method for immutability
  GameState copyWith({
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
  }) {
    return GameState(
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
    );
  }
}

/// Game notifier class
class GameNotifier extends Notifier<GameState> {
  late final MatadorEngine _engine;

  @override
  GameState build() {
    _engine = MatadorEngine();
    return const GameState(
      target: 0,
      availableNumbers: [],
      expression: '',
      score: 0,
      isPlaying: false,
      message: '',
    );
  }

  /// Starts a new game using the advanced level generator
  void startGame() {
    final level = _engine.generateLevel();
    final target = level['target'] as int;
    final numbers = level['numbers'] as List<int>;
    
    // Pre-calculate all solutions
    final solutions = _engine.solve(numbers, target);

    state = GameState(
      target: target,
      availableNumbers: numbers,
      expression: '',
      score: state.score,
      isPlaying: true,
      message: 'Make $target using these numbers!',
      isMatadorSolution: false,
      usedNumberIndices: {},
      solutions: solutions,
    );
  }

  /// Adds a value to the expression
  /// Prevents "1010" bug by checking last token type
  void addToExpression(String value) {
    final isNumber = int.tryParse(value) != null;
    final isOperator = ['+', '-', '*', '/'].contains(value);
    
    if (state.expression.isEmpty) {
      // First token must be a number or opening parenthesis
      if (isOperator) return;
      if (isNumber) {
        // Mark this number as used
        final idx = int.parse(value);
        final newUsedIndices = {...state.usedNumberIndices};
        if (state.availableNumbers.contains(idx)) {
          newUsedIndices.add(state.availableNumbers.indexOf(idx));
        }
        state = state.copyWith(
          expression: value,
          message: '',
          usedNumberIndices: newUsedIndices,
        );
      } else {
        state = state.copyWith(expression: value, message: '');
      }
      return;
    }

    // Get the last token
    final lastChar = state.expression.isEmpty ? '' : state.expression[state.expression.length - 1];
    final lastIsNumber = int.tryParse(lastChar) != null;
    final lastIsOperator = ['+', '-', '*', '/'].contains(lastChar);
    final lastIsOpenParen = lastChar == '(';

    // Prevent consecutive numbers (no "1010" bug)
    if (isNumber && (lastIsNumber || lastChar == ')')) {
      return; // Ignore - user must use an operator
    }

    // Can't have consecutive operators
    if (isOperator && lastIsOperator) {
      return;
    }

    // Must have operand after opening paren
    if (lastIsOpenParen && isOperator) {
      return;
    }

    final newExpression = state.expression + value;
    
    // Track number usage
    Set<int> newUsedIndices = state.usedNumberIndices;
    if (isNumber) {
      final idx = int.parse(value);
      if (state.availableNumbers.contains(idx)) {
        newUsedIndices = {...state.usedNumberIndices};
        newUsedIndices.add(state.availableNumbers.indexOf(idx));
      }
    }

    state = state.copyWith(
      expression: newExpression,
      message: '',
      usedNumberIndices: newUsedIndices,
    );
  }

  /// Clears the current expression
  void clearExpression() {
    state = state.copyWith(expression: '', message: '', usedNumberIndices: {});
  }

  /// Submits the answer and checks if it matches the target
  /// Scoring: +1 (+), +2 (-), +1 (*), +3 (/), or 13 for MATHADOR
  void submitAnswer() {
    if (state.expression.isEmpty) {
      state = state.copyWith(message: 'Please enter an expression');
      return;
    }

    final result = _engine.evaluate(state.expression);

    if (result == null) {
      state = state.copyWith(message: 'Invalid expression!');
      return;
    }

    if (result == state.target) {
      // Calculate points based on operators used
      final (points, breakdown) = _calculateScore(state.expression);
      
      // Check if Mathador (uses all 5 numbers AND all 4 operators)
      final isMathador = _isMathador(state.expression);
      
      final finalPoints = isMathador ? 13 : points;
      final newScore = state.score + finalPoints;
      
      final message = isMathador
          ? '🏆 MATHADOR! 13 Points!'
          : '✅ Correct! +$points Points';

      state = state.copyWith(
        score: newScore,
        message: message,
        isMatadorSolution: isMathador,
        lastScoreBreakdown: breakdown,
      );

      // Start next round after a short delay
      Future.delayed(const Duration(seconds: 2), startGame);
    } else {
      state = state.copyWith(
        message: '❌ Wrong! Target: ${state.target}, Got: $result',
      );
    }
  }

  /// Calculates score based on operators and returns breakdown string
  (int, String) _calculateScore(String expression) {
    int points = 0;
    final breakdown = StringBuffer();
    
    final operators = {
      '+': 1,
      '-': 2,
      '*': 1,
      '/': 3,
    };

    for (final char in expression.split('')) {
      if (operators.containsKey(char)) {
        final value = operators[char]!;
        points += value;
        breakdown.write('${breakdown.isEmpty ? '' : ' + '}$value($char)');
      }
    }

    return (points, breakdown.toString());
  }

  /// Counts how many numbers are used in the expression
  int _countNumbersInExpression(String expression) {
    // Count digits that represent the available numbers
    int count = 0;
    bool inNumber = false;

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (char.contains(RegExp(r'[0-9]'))) {
        if (!inNumber) {
          count++;
          inNumber = true;
        }
      } else {
        inNumber = false;
      }
    }

    return count;
  }

  /// Checks if solution is Mathador (all 5 numbers + all 4 operators)
  bool _isMathador(String expression) {
    final usesAllNumbers = _countNumbersInExpression(expression) == 5;
    
    final operators = {'+', '-', '*', '/'};
    final usedOps = <String>{};
    
    for (final op in operators) {
      if (expression.contains(op)) {
        usedOps.add(op);
      }
    }

    return usesAllNumbers && usedOps.length == 4;
  }
}

/// Riverpod provider
final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
