import 'dart:async';
import 'dart:math';
import '../models/puzzle.dart';
import 'package:math_expressions/math_expressions.dart';

/// Realistic bot AI that simulates human-like puzzle solving
class BotAI {
  final String name;
  final int skillLevel; // 800-2000 ELO
  final Random _random = Random();

  BotAI({
    required this.name,
    required this.skillLevel,
  });

  /// Factory to create a bot with randomized skill near player's ELO
  factory BotAI.matchingSkill(int playerElo) {
    final variation = Random().nextInt(200) - 100; // ±100 ELO
    final botElo = (playerElo + variation).clamp(800, 2000);

    final botNames = [
      'Alex',
      'Jordan',
      'Taylor',
      'Morgan',
      'Casey',
      'Riley',
      'Sam',
      'Charlie',
      'Jamie',
      'Max',
      'Blake',
      'Quinn',
      'Avery',
      'Drew',
      'Kai',
      'Skyler',
      'Phoenix',
      'River',
      'Dakota',
      'Sage',
    ];

    return BotAI(
      name: botNames[Random().nextInt(botNames.length)],
      skillLevel: botElo,
    );
  }

  /// Calculate realistic solve time based on puzzle difficulty and bot skill
  Duration calculateSolveTime(GamePuzzle puzzle) {
    // Base time increases with puzzle complexity
    int baseTimeMs;

    switch (puzzle.type) {
      case PuzzleType.basic:
        baseTimeMs = 2000; // 2 seconds
        break;
      case PuzzleType.complex:
        baseTimeMs = 4000; // 4 seconds
        break;
      case PuzzleType.game24:
        baseTimeMs = 15000; // 15 seconds (increased from 8)
        break;
      case PuzzleType.matador:
        baseTimeMs = 25000; // 25 seconds (increased from 15)
        break;
    }

    // Skill modifier: higher skill = faster (0.6x to 2.5x)
    // ELO 800 = 2.5x slower, ELO 2000 = 0.6x faster
    final skillMultiplier = 3.1 - (skillLevel / 800);

    // Add random variation ±40%
    final randomVariation = 0.6 + (_random.nextDouble() * 0.8);

    final totalMs = (baseTimeMs * skillMultiplier * randomVariation).toInt();

    return Duration(milliseconds: totalMs);
  }

  /// Calculate probability of bot getting answer correct
  double getSuccessProbability(GamePuzzle puzzle) {
    double baseProbability;

    switch (puzzle.type) {
      case PuzzleType.basic:
        baseProbability = 0.95;
        break;
      case PuzzleType.complex:
        baseProbability = 0.85;
        break;
      case PuzzleType.game24:
        baseProbability = 0.55; // Reduced from 0.70
        break;
      case PuzzleType.matador:
        baseProbability = 0.35; // Reduced from 0.50
        break;
    }

    // Adjust for skill level (800 = 0.6x, 1400 = 1.0x, 2000 = 1.3x)
    final skillMultiplier = 0.6 + ((skillLevel - 800) / 1200) * 0.7;

    return (baseProbability * skillMultiplier).clamp(0.2, 0.98);
  }

  /// Generate a solution for arithmetic puzzles
  int? solveArithmetic(GamePuzzle puzzle) {
    final probability = getSuccessProbability(puzzle);

    if (_random.nextDouble() > probability) {
      // Bot fails - return wrong answer
      if (puzzle is BasicPuzzle || puzzle is ComplexPuzzle) {
        final offset = _random.nextInt(20) - 10;
        return puzzle.targetValue + offset;
      }
      return null;
    }

    // Bot succeeds
    return puzzle.targetValue;
  }

  /// Generate a solution for Game24/Matador puzzles
  String? solveExpression(GamePuzzle puzzle) {
    final probability = getSuccessProbability(puzzle);

    if (_random.nextDouble() > probability) {
      return null; // Bot fails
    }

    if (puzzle is Game24Puzzle) {
      // Try to find a valid solution
      final solutions =
          _findGame24Solutions(puzzle.availableNumbers, puzzle.targetValue);
      if (solutions.isNotEmpty) {
        return solutions[_random.nextInt(solutions.length)];
      }
      return null;
    }

    if (puzzle is MatadorPuzzle) {
      // For Matador, find a solution (may not be the best)
      final solutions =
          _findMatadorSolutions(puzzle.availableNumbers, puzzle.targetValue);

      if (solutions.isEmpty) return null;

      // Higher skill bots try to find Mathador more often
      final tryMathador = skillLevel > 1500 && _random.nextDouble() > 0.7;

      if (tryMathador) {
        final mathadorSolutions = solutions
            .where((s) =>
                s.contains('+') &&
                s.contains('-') &&
                s.contains('*') &&
                s.contains('/'))
            .toList();

        if (mathadorSolutions.isNotEmpty) {
          return mathadorSolutions[_random.nextInt(mathadorSolutions.length)];
        }
      }

      return solutions[_random.nextInt(solutions.length)];
    }

    return null;
  }

  /// Simulate bot typing/input with realistic delays
  Stream<String> simulateInput(String answer) async* {
    // Typing speed based on skill (50-200 ms per character)
    final baseDelayMs = 200 - ((skillLevel - 800) / 1200 * 150).toInt();

    for (int i = 0; i < answer.length; i++) {
      await Future.delayed(Duration(
        milliseconds: baseDelayMs + _random.nextInt(50) - 25,
      ));
      yield answer.substring(0, i + 1);
    }
  }

  /// Find possible Game24 solutions (simplified)
  List<String> _findGame24Solutions(List<int> numbers, int target) {
    final solutions = <String>[];

    // Try common patterns for 4 numbers
    if (numbers.length == 4) {
      final a = numbers[0], b = numbers[1], c = numbers[2], d = numbers[3];

      // Pattern: (a ○ b) ○ (c ○ d)
      final ops = ['+', '-', '*', '/'];
      for (final op1 in ops) {
        for (final op2 in ops) {
          for (final op3 in ops) {
            final expr = '($a$op1$b)$op2($c$op3$d)';
            try {
              final result = _evaluateExpression(expr);
              if (result == target) {
                solutions.add(expr);
              }
            } catch (e) {
              // Invalid expression, skip
            }
          }
        }
      }
    }

    return solutions.take(5).toList();
  }

  /// Find possible Matador solutions
  List<String> _findMatadorSolutions(List<int> numbers, int target) {
    final solutions = <String>[];

    // Try various combinations
    final a = numbers[0],
        b = numbers[1],
        c = numbers[2],
        d = numbers[3],
        e = numbers[4];

    final ops = ['+', '-', '*', '/'];

    // Try simple patterns (limit search for performance)
    for (final op1 in ops) {
      for (final op2 in ops) {
        for (final op3 in ops) {
          for (final op4 in ops) {
            final expressions = [
              '(($a$op1$b)$op2$c)$op3($d$op4$e)',
              '($a$op1$b)$op2(($c$op3$d)$op4$e)',
              '(($a$op1$b)$op2($c$op3$d))$op4$e',
            ];

            for (final expr in expressions) {
              try {
                final result = _evaluateExpression(expr);
                if (result == target) {
                  solutions.add(expr);
                  if (solutions.length >= 10) return solutions;
                }
              } catch (e) {
                // Invalid expression, skip
              }
            }
          }
        }
      }
    }

    return solutions;
  }

  /// Helper to evaluate expressions
  int? _evaluateExpression(String expression) {
    try {
      final Parser p = Parser();
      final Expression exp = p.parse(expression);
      final result = exp.evaluate(EvaluationType.REAL, ContextModel());
      return result.round();
    } catch (e) {
      return null;
    }
  }
}
