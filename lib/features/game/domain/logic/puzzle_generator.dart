import 'dart:math';
import '../models/puzzle.dart';

/// Générateur de puzzles pour le mode multijoueur
class PuzzleGenerator {
  static final Random _random = Random();

  /// Génère des puzzles adaptés à l'ELO du joueur
  /// - < 1600 (Diamant): Basic + Complex
  /// - 1600-1799 (Diamant): Basic + Complex + Game24
  /// - >= 1800 (Master+): Basic + Complex + Game24 + Matador
  static List<GamePuzzle> generateByElo(
      {int count = 25, int averageElo = 1200}) {
    final puzzles = <GamePuzzle>[];

    // Déterminer les types de puzzles disponibles selon l'ELO
    final isDiamond = averageElo >= 1600; // Diamant: 1600+
    final isMaster = averageElo >= 1800; // Master: 1800+

    for (int i = 0; i < count; i++) {
      if (isMaster) {
        // Master+: 50% basic, 25% complex, 15% game24, 10% matador
        final rand = _random.nextDouble();
        if (rand < 0.50) {
          puzzles.add(_generateBasicPuzzle(i));
        } else if (rand < 0.75) {
          puzzles.add(_generateComplexPuzzle(i));
        } else if (rand < 0.90) {
          puzzles.add(_generateGame24Puzzle(i));
        } else {
          puzzles.add(_generateMatadorPuzzle(i));
        }
      } else if (isDiamond) {
        // Diamant: 60% basic, 30% complex, 10% game24
        final rand = _random.nextDouble();
        if (rand < 0.60) {
          puzzles.add(_generateBasicPuzzle(i));
        } else if (rand < 0.90) {
          puzzles.add(_generateComplexPuzzle(i));
        } else {
          puzzles.add(_generateGame24Puzzle(i));
        }
      } else {
        // < Diamant: 70% basic, 30% complex
        if (_random.nextDouble() < 0.70) {
          puzzles.add(_generateBasicPuzzle(i));
        } else {
          puzzles.add(_generateComplexPuzzle(i));
        }
      }
    }

    return puzzles;
  }

  /// Génère un mélange de puzzles basiques et complexes (ancienne méthode)
  @Deprecated('Use generateByElo instead')
  static List<GamePuzzle> generateMixed({int count = 20}) {
    return generateByElo(count: count, averageElo: 1200);
  }

  static BasicPuzzle _generateBasicPuzzle(int index) {
    final operators = ['+', '-', '*', '/'];
    final operator = operators[_random.nextInt(operators.length)];

    int a, b, result;

    switch (operator) {
      case '+':
        a = _random.nextInt(50) + 1;
        b = _random.nextInt(50) + 1;
        result = a + b;
        break;
      case '-':
        a = _random.nextInt(50) + 10;
        b = _random.nextInt(a);
        result = a - b;
        break;
      case '*':
        a = _random.nextInt(12) + 1;
        b = _random.nextInt(12) + 1;
        result = a * b;
        break;
      case '/':
        b = _random.nextInt(10) + 1;
        result = _random.nextInt(20) + 1;
        a = b * result;
        break;
      default:
        a = 1;
        b = 1;
        result = 2;
    }

    return BasicPuzzle(
      id: 'puzzle_$index',
      targetValue: result,
      numberA: a,
      numberB: b,
      operator: operator,
    );
  }

  static ComplexPuzzle _generateComplexPuzzle(int index) {
    final operators = ['+', '-', '*'];
    final op1 = operators[_random.nextInt(operators.length)];
    final op2 = operators[_random.nextInt(operators.length)];

    // Réduire la difficulté: nombres plus petits
    final a = _random.nextInt(10) + 1; // 1-10 au lieu de 1-20
    final b = _random.nextInt(8) + 1; // 1-8 au lieu de 1-15
    final c = _random.nextInt(8) + 1; // 1-8 au lieu de 1-15

    // Calculer le résultat avec parenthèses: a op1 (b op2 c)
    int innerResult;
    switch (op2) {
      case '+':
        innerResult = b + c;
        break;
      case '-':
        innerResult = b - c;
        break;
      case '*':
        innerResult = b * c;
        break;
      default:
        innerResult = b + c;
    }

    int finalResult;
    switch (op1) {
      case '+':
        finalResult = a + innerResult;
        break;
      case '-':
        finalResult = a - innerResult;
        break;
      case '*':
        finalResult = a * innerResult;
        break;
      default:
        finalResult = a + innerResult;
    }

    return ComplexPuzzle(
      id: 'puzzle_$index',
      targetValue: finalResult,
      numberA: a,
      numberB: b,
      numberC: c,
      operator1: op1,
      operator2: op2,
      useParentheses: true,
    );
  }

  /// Génère un puzzle Game24 (faire 24 avec 4 nombres)
  static Game24Puzzle _generateGame24Puzzle(int index) {
    // Générer 4 nombres aléatoires entre 1 et 13
    final numbers = <int>[
      _random.nextInt(13) + 1,
      _random.nextInt(13) + 1,
      _random.nextInt(13) + 1,
      _random.nextInt(13) + 1,
    ];

    return Game24Puzzle(
      id: 'game24_$index',
      availableNumbers: numbers,
      targetValue: 24,
    );
  }

  /// Génère un puzzle Matador (atteindre une cible avec 5 nombres)
  static MatadorPuzzle _generateMatadorPuzzle(int index) {
    // Générer 5 nombres aléatoires
    final numbers = <int>[
      _random.nextInt(10) + 1,
      _random.nextInt(10) + 1,
      _random.nextInt(10) + 1,
      _random.nextInt(10) + 1,
      _random.nextInt(10) + 1,
    ];

    // Cible aléatoire entre 10 et 100
    final target = _random.nextInt(91) + 10;

    return MatadorPuzzle(
      id: 'matador_$index',
      targetValue: target,
      availableNumbers: numbers,
      solutionCount: 0,
    );
  }
}
