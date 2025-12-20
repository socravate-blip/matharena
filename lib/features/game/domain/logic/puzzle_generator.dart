import 'dart:math';
import '../models/puzzle.dart';

/// Générateur de puzzles pour le mode multijoueur
class PuzzleGenerator {
  static final Random _random = Random();

  /// Génère une liste de puzzles d'un type précis.
  /// Utilisé notamment pour la calibration (placement) où chaque match cible un type.
  static List<GamePuzzle> generateByType({
    required PuzzleType type,
    int count = 10,
  }) {
    final puzzles = <GamePuzzle>[];
    for (int i = 0; i < count; i++) {
      switch (type) {
        case PuzzleType.basic:
          puzzles.add(_generateBasicPuzzle(i));
          break;
        case PuzzleType.complex:
          puzzles.add(_generateComplexPuzzle(i));
          break;
        case PuzzleType.game24:
          puzzles.add(_generateGame24Puzzle(i));
          break;
        case PuzzleType.matador:
          puzzles.add(_generateMatadorPuzzle(i));
          break;
      }
    }
    return puzzles;
  }

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
    final numbers = _generateSolvableGame24Numbers();

    return Game24Puzzle(
      id: 'game24_$index',
      availableNumbers: numbers,
      targetValue: 24,
    );
  }

  static List<int> _generateSolvableGame24Numbers() {
    // Fallback curated pool (guaranteed solvable) for worst-case.
    const curated = <List<int>>[
      [3, 3, 8, 8],
      [1, 3, 4, 6],
      [2, 2, 6, 6],
      [2, 3, 4, 12],
      [3, 6, 8, 9],
      [1, 5, 5, 5],
      [4, 4, 10, 10],
      [1, 2, 8, 9],
      [2, 3, 7, 8],
    ];

    // Try random sets first to improve variety.
    for (int attempt = 0; attempt < 250; attempt++) {
      final numbers = List<int>.generate(4, (_) => 1 + _random.nextInt(13));
      if (_canMake24(numbers)) return numbers;
    }

    return curated[_random.nextInt(curated.length)];
  }

  static bool _canMake24(List<int> numbers) {
    final fracs = numbers.map((n) => _Frac(n, 1)).toList();
    return _canReachTarget(fracs, const _Frac(24, 1));
  }

  static bool _canReachTarget(List<_Frac> nums, _Frac target) {
    if (nums.length == 1) {
      return nums[0] == target;
    }

    for (int i = 0; i < nums.length; i++) {
      for (int j = i + 1; j < nums.length; j++) {
        final a = nums[i];
        final b = nums[j];

        final remaining = <_Frac>[];
        for (int k = 0; k < nums.length; k++) {
          if (k != i && k != j) remaining.add(nums[k]);
        }

        // + and * are commutative
        final add = a + b;
        remaining.add(add);
        if (_canReachTarget(remaining, target)) return true;
        remaining.removeLast();

        final mul = a * b;
        remaining.add(mul);
        if (_canReachTarget(remaining, target)) return true;
        remaining.removeLast();

        // - and / are not commutative (try both orders)
        final sub1 = a - b;
        remaining.add(sub1);
        if (_canReachTarget(remaining, target)) return true;
        remaining.removeLast();

        final sub2 = b - a;
        remaining.add(sub2);
        if (_canReachTarget(remaining, target)) return true;
        remaining.removeLast();

        if (!b.isZero) {
          final div1 = a / b;
          remaining.add(div1);
          if (_canReachTarget(remaining, target)) return true;
          remaining.removeLast();
        }

        if (!a.isZero) {
          final div2 = b / a;
          remaining.add(div2);
          if (_canReachTarget(remaining, target)) return true;
          remaining.removeLast();
        }
      }
    }
    return false;
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

class _Frac {
  final int n;
  final int d;

  const _Frac(int numerator, int denominator)
      : n = denominator < 0 ? -numerator : numerator,
        d = denominator < 0 ? -denominator : denominator;

  bool get isZero => n == 0;

  _Frac _reduce() {
    if (n == 0) return const _Frac(0, 1);
    final g = _gcd(n.abs(), d.abs());
    return _Frac(n ~/ g, d ~/ g);
  }

  _Frac operator +(_Frac other) =>
      _Frac(n * other.d + other.n * d, d * other.d)._reduce();

  _Frac operator -(_Frac other) =>
      _Frac(n * other.d - other.n * d, d * other.d)._reduce();

  _Frac operator *(_Frac other) => _Frac(n * other.n, d * other.d)._reduce();

  _Frac operator /(_Frac other) => _Frac(n * other.d, d * other.n)._reduce();

  @override
  bool operator ==(Object other) {
    if (other is! _Frac) return false;
    final a = _reduce();
    final b = other._reduce();
    return a.n == b.n && a.d == b.d;
  }

  @override
  int get hashCode {
    final r = _reduce();
    return Object.hash(r.n, r.d);
  }

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = a % b;
      a = b;
      b = t;
    }
    return a;
  }
}
