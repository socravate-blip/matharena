import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/matador_engine.dart';
import '../../domain/logic/timer_engine.dart';
import '../../domain/repositories/rating_storage.dart';

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
      secondsRemaining: 360,
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
      duration: const Duration(seconds: 360),
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
      secondsRemaining: 360,
      timerActive: false,
      gameStartTime: DateTime.now(),
      foundSolutions: {},
    );

    _timer!.start();
    state = state.copyWith(timerActive: true);
  }

  void addToExpression(String value) {
    final isNumber = int.tryParse(value) != null;
    final isOperator = ['+', '-', '*', '/'].contains(value);
    
    // Insérer à la position du curseur
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

    // Vérifier le caractère avant le curseur
    final charBefore = cursorPos > 0 ? state.expression[cursorPos - 1] : '';
    final charAfter = cursorPos < state.expression.length ? state.expression[cursorPos] : '';
    final beforeIsNumber = int.tryParse(charBefore) != null;
    final beforeIsOperator = ['+', '-', '*', '/'].contains(charBefore);
    final beforeIsOpenParen = charBefore == '(';
    final afterIsNumber = int.tryParse(charAfter) != null;

    // Règles de validation
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

    // Calculer le résultat de la nouvelle expression
    final result = _engine.evaluate(newExpression);
    
    state = state.copyWith(
      expression: newExpression,
      message: '',
      usedNumberIndices: newUsedIndices,
      currentResult: result,
      cursorPosition: cursorPos + value.length,
    );

    // Validation automatique à chaque modification
    _checkAutoValidation();
  }

  /// Calcule les indices des nombres utilisés dans l'expression
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
          // Chercher ce nombre dans availableNumbers et marquer son indice comme utilisé
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
    
    // Traiter le dernier nombre s'il existe
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
    final result = newExpression.isEmpty ? null : _engine.evaluate(newExpression);
    
    state = state.copyWith(
      expression: newExpression,
      message: '',
      usedNumberIndices: newUsedIndices,
      currentResult: result,
      cursorPosition: cursorPos - 1,
    );
  }

  /// Validation automatique - évalue l'expression à chaque modification
  void _checkAutoValidation() {
    if (state.expression.isEmpty) return;

    final result = _engine.evaluate(state.expression);

    // Si l'expression est invalide, ne rien faire
    if (result == null) return;

    // Si le résultat correspond à la cible, valider automatiquement
    if (result == state.target) {
      _validateSolution();
    }
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
      _validateSolution();
    } else {
      state = state.copyWith(
        message: '❌ Wrong! Target: ${state.target}, Got: $result',
      );
    }
  }

  /// Valide une solution correcte (appelée automatiquement ou manuellement)
  void _validateSolution() {
    if (state.expression.isEmpty) return;

    // Normaliser l'expression (enlever espaces)
    final normalizedExpr = state.expression.replaceAll(' ', '');

    // Vérifier si cette solution a déjà été trouvée
    if (state.foundSolutions.contains(normalizedExpr)) {
      state = state.copyWith(
        expression: '',
        message: '✓ (déjà trouvée)',
        usedNumberIndices: {},
        cursorPosition: 0,
        currentResult: null,
      );
      return;
    }

    final (points, breakdown) = _calculateScore(state.expression);
    final isMathador = _isMathador(state.expression);
    final finalPoints = isMathador ? 13 : points;
    final newScore = state.score + finalPoints;

    final solutionCount = state.foundSolutions.length + 1;
    final message = isMathador
        ? '🏆 MATHADOR! +13 pts (Solution $solutionCount)'
        : '✅ +$points pts (Solution $solutionCount)';

    // Ajouter la solution aux solutions trouvées
    final updatedFoundSolutions = {...state.foundSolutions, normalizedExpr};

    // NE PAS générer nouvelle question - garder la même cible
    state = state.copyWith(
      score: newScore,
      expression: '',
      message: message,
      isMatadorSolution: isMathador,
      lastScoreBreakdown: breakdown,
      usedNumberIndices: {},
      foundSolutions: updatedFoundSolutions,
      cursorPosition: 0,
      currentResult: null,
    );
  }

  Future<void> endGame() async {
    _timer?.stop();

    // Mettre à jour le rating Elo avec le nouveau système
    final ratingStorage = ref.read(ratingStorageProvider);
    await ratingStorage.updateRatingAfterGame(
      playerScore: state.score,
      foundMathador: state.isMatadorSolution,
    );

    // Rafraîchir le profil de rating
    ref.invalidate(playerRatingProvider);

    state = state.copyWith(
      isPlaying: false,
      timerActive: false,
      message: 'Time\'s Up! Game Over',
    );
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
