import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/matador_engine.dart';
import '../../domain/logic/timer_engine.dart';

class RankedNotifier extends Notifier<RankedGameState> {
  late final MatadorEngine _engine;
  CountdownTimer? _timer;

  @override
  RankedGameState build() {
    _engine = MatadorEngine();
    return const RankedGameState(
      target: 0,
      availableNumbers: [],
      expression: '',
      score: 0,
      isPlaying: false,
      message: '',
      secondsRemaining: 120,
      timerActive: false,
    );
  }

  void startGame() {
    final level = _engine.generateLevel();
    final target = level['target'] as int;
    final numbers = level['numbers'] as List<int>;
    
    final solutions = _engine.solve(numbers, target);

    _timer?.stop();
    _timer = CountdownTimer(
      duration: const Duration(seconds: 120),
      onTick: (remaining) {
        state = state.copyWith(secondsRemaining: remaining);
      },
      onFinish: () {
        endGame();
      },
    );

    state = RankedGameState(
      target: target,
      availableNumbers: numbers,
      expression: '',
      score: state.score,
      isPlaying: true,
      message: 'Make $target using these numbers!',
      isMatadorSolution: false,
      usedNumberIndices: {},
      solutions: solutions,
      secondsRemaining: 120,
      timerActive: false,
      gameStartTime: DateTime.now(),
    );

    _timer!.start();
    state = state.copyWith(timerActive: true);
  }

  void addToExpression(String value) {
    final isNumber = int.tryParse(value) != null;
    final isOperator = ['+', '-', '*', '/'].contains(value);
    
    if (state.expression.isEmpty) {
      if (isOperator && value != '-') return;
      if (isNumber) {
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

    final lastChar = state.expression.isEmpty ? '' : state.expression[state.expression.length - 1];
    final lastIsNumber = int.tryParse(lastChar) != null;
    final lastIsOperator = ['+', '-', '*', '/'].contains(lastChar);
    final lastIsOpenParen = lastChar == '(';

    if (isNumber && (lastIsNumber || lastChar == ')')) {
      return;
    }

    if (isOperator && lastIsOperator) {
      return;
    }

    if (lastIsOpenParen && isOperator && value != '-') {
      return;
    }

    final newExpression = state.expression + value;
    
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

  void clearExpression() {
    state = state.copyWith(expression: '', message: '', usedNumberIndices: {});
  }

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
      final (points, breakdown) = _calculateScore(state.expression);
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

      Future.delayed(const Duration(seconds: 2), startGame);
    } else {
      state = state.copyWith(
        message: '❌ Wrong! Target: ${state.target}, Got: $result',
      );
    }
  }

  void endGame() {
    _timer?.stop();
    state = state.copyWith(
      isPlaying: false,
      timerActive: false,
      message: 'Time\'s Up! Game Over',
    );

    // Save score would be handled in the UI layer via ScoreStorage
  }

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

  int _countNumbersInExpression(String expression) {
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

final rankedProvider = NotifierProvider<RankedNotifier, RankedGameState>(() {
  return RankedNotifier();
});
