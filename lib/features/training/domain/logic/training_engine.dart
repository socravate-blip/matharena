import 'dart:math';

enum TrainingOperator { add, subtract, multiply, divide }

class TrainingQuestion {
  final int operand1;
  final int operand2;
  final TrainingOperator operator;
  final int correctAnswer;
  final double difficultyCoefficient;

  TrainingQuestion({
    required this.operand1,
    required this.operand2,
    required this.operator,
    required this.correctAnswer,
    required this.difficultyCoefficient,
  });

  String get operatorSymbol {
    switch (operator) {
      case TrainingOperator.add:
        return '+';
      case TrainingOperator.subtract:
        return '-';
      case TrainingOperator.multiply:
        return '×';
      case TrainingOperator.divide:
        return '÷';
    }
  }
}

/// Calcule le coefficient de difficulté d'une question
class DifficultyCalculator {
  /// Coefficient basé sur le range des nombres
  static double getRangeCoefficient(int minNumber, int maxNumber) {
    final range = maxNumber - minNumber;
    if (range <= 10) return 1.0;
    if (range <= 20) return 1.3;
    if (range <= 50) return 1.8;
    if (range <= 100) return 2.5;
    return 3.0;
  }

  /// Coefficient basé sur l'opérateur
  static double getOperatorCoefficient(TrainingOperator operator) {
    switch (operator) {
      case TrainingOperator.add:
        return 1.0;
      case TrainingOperator.subtract:
        return 1.0;
      case TrainingOperator.multiply:
        return 1.5;
      case TrainingOperator.divide:
        return 1.8;
    }
  }

  /// Coefficient si nombres négatifs activés
  static double getNegativeCoefficient(bool allowNegative) {
    return allowNegative ? 0.3 : 0.0;
  }

  /// Coefficient basé sur la complexité des nombres (multi-chiffres)
  static double getComplexityCoefficient(int operand1, int operand2) {
    final maxDigits = max(
      operand1.abs().toString().length,
      operand2.abs().toString().length,
    );
    if (maxDigits >= 3) return 0.2;
    if (maxDigits == 2) return 0.1;
    return 0.0;
  }

  /// Calcul du coefficient total
  static double calculateCoefficient({
    required int minNumber,
    required int maxNumber,
    required TrainingOperator operator,
    required bool allowNegative,
    required int operand1,
    required int operand2,
  }) {
    final rangeCoef = getRangeCoefficient(minNumber, maxNumber);
    final operatorCoef = getOperatorCoefficient(operator);
    final negativeBonus = getNegativeCoefficient(allowNegative);
    final complexityBonus = getComplexityCoefficient(operand1, operand2);

    // Formule multiplicative avec bonus additifs
    return (rangeCoef * operatorCoef) + negativeBonus + complexityBonus;
  }
}

class TrainingEngine {
  final Random _random = Random();

  TrainingQuestion generateQuestion({
    required int minNumber,
    required int maxNumber,
    required List<TrainingOperator> enabledOperators,
    required bool allowNegative,
  }) {
    if (enabledOperators.isEmpty) {
      throw ArgumentError('At least one operator must be enabled');
    }

    final operator = enabledOperators[_random.nextInt(enabledOperators.length)];

    int operand1 = _random.nextInt(maxNumber - minNumber + 1) + minNumber;
    int operand2 = _random.nextInt(maxNumber - minNumber + 1) + minNumber;
    int correctAnswer;

    switch (operator) {
      case TrainingOperator.add:
        correctAnswer = operand1 + operand2;
        break;
      case TrainingOperator.subtract:
        if (!allowNegative && operand1 < operand2) {
          final temp = operand1;
          operand1 = operand2;
          operand2 = temp;
        }
        correctAnswer = operand1 - operand2;
        break;
      case TrainingOperator.multiply:
        correctAnswer = operand1 * operand2;
        break;
      case TrainingOperator.divide:
        // Ensure division results in a whole number
        if (operand2 == 0) operand2 = 1;
        operand1 = operand2 * (_random.nextInt(maxNumber - minNumber + 1) + 1);
        correctAnswer = operand1 ~/ operand2;
        break;
    }

    // Calcul du coefficient de difficulté
    final difficultyCoef = DifficultyCalculator.calculateCoefficient(
      minNumber: minNumber,
      maxNumber: maxNumber,
      operator: operator,
      allowNegative: allowNegative,
      operand1: operand1,
      operand2: operand2,
    );

    return TrainingQuestion(
      operand1: operand1,
      operand2: operand2,
      operator: operator,
      correctAnswer: correctAnswer,
      difficultyCoefficient: difficultyCoef,
    );
  }
}
