import 'dart:math';
import 'package:math_expressions/math_expressions.dart';

class MatadorEngine {
  final Random _random = Random();
  static const int maxRetries = 10;
  static const int minNumberRange = 1;
  static const int maxNumberRange = 12;
  static const int numNumbers = 5;

  /// Generates a complete level with guaranteed Matador and Easy solutions
  /// Returns a map with 'numbers', 'target', 'hasSolutions'
  Map<String, dynamic> generateLevel() {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Step 1: Generate 5 random numbers (1-12)
      final numbers = _generateNumbers();

      // Step 2: Generate a target using ALL 5 numbers
      final target = _generateTargetWithAllNumbers(numbers);

      if (target == null) continue;

      // Step 3: Validate that easy solutions exist (3-4 numbers)
      final hasEasySolution =
          _canSolveWithFewNumbers(target, numbers, minCount: 3, maxCount: 4);

      // Step 4: Validate that Matador solution exists (all 5 numbers)
      final hasMatadorSolution = _findSolution(numbers, target) != null;

      if (hasEasySolution && hasMatadorSolution) {
        return {
          'numbers': numbers,
          'target': target,
          'hasSolutions': true,
        };
      }
    }

    // Fallback: Return a random level if we can't find a perfect one
    // (This ensures the game never gets stuck)
    final numbers = _generateNumbers();
    final target = _random.nextInt(81) + 20; // 20-100

    return {
      'numbers': numbers,
      'target': target,
      'hasSolutions': false,
    };
  }

  /// Generates 5 UNIQUE random numbers (1 to 12, all positive)
  List<int> _generateNumbers() {
    final numbers = <int>[];
    while (numbers.length < numNumbers) {
      int num = _random.nextInt(maxNumberRange - minNumberRange + 1) + minNumberRange;
      if (!numbers.contains(num)) {
        numbers.add(num);
      }
    }
    return numbers;
  }

  /// Generates a target number by using ALL 5 numbers (Mathador guaranteed)
  /// This guarantees a Mathador solution exists
  int? _generateTargetWithAllNumbers(List<int> numbers) {
    try {
      // Try a simple expression: a + b + c + d + e
      final simpleSum = numbers.reduce((a, b) => a + b);
      if (simpleSum >= -50 && simpleSum <= 50) {
        return simpleSum;
      }

      // Try another combination: a * b + c + d - e
      final result1 = numbers[0] * numbers[1] + numbers[2] + numbers[3] - numbers[4];
      if (result1 >= -50 && result1 <= 50) {
        return result1;
      }

      // Try: (a + b) * (c + d) / e (if divisible)
      final sum1 = numbers[0] + numbers[1];
      final sum2 = numbers[2] + numbers[3];
      if (sum2 != 0 && (sum1 * sum2) % sum2 == 0) {
        final result = (sum1 * sum2) ~/ numbers[4];
        if (result != 0 && result >= -50 && result <= 50) {
          return result;
        }
      }

      // Random combination allowing negative intermediates
      final ops = ['+', '-', '*', '/'];
      for (int i = 0; i < 10; i++) {
        try {
          final op1 = ops[_random.nextInt(4)];
          final op2 = ops[_random.nextInt(4)];
          final op3 = ops[_random.nextInt(4)];
          final op4 = ops[_random.nextInt(4)];

          final expr =
              '${numbers[0]}$op1${numbers[1]}$op2${numbers[2]}$op3${numbers[3]}$op4${numbers[4]}';
          final result = evaluate(expr);

          if (result != null && result != 0 && result >= -50 && result <= 50) {
            return result;
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validates if a solution exists using a specific count of numbers
  bool _canSolveWithFewNumbers(
    int target,
    List<int> numbers, {
    required int minCount,
    required int maxCount,
  }) {
    // Try all subsets of numbers within the count range
    for (int count = minCount; count <= maxCount; count++) {
      final subset = _generateSubsets(numbers, count);
      for (final nums in subset) {
        if (_findSolution(nums, target) != null) {
          return true;
        }
      }
    }
    return false;
  }

  /// Generates all subsets of a given size from the numbers list
  List<List<int>> _generateSubsets(List<int> numbers, int size) {
    final result = <List<int>>[];

    void backtrack(List<int> current, int start) {
      if (current.length == size) {
        result.add(List.from(current));
        return;
      }

      for (int i = start; i < numbers.length; i++) {
        current.add(numbers[i]);
        backtrack(current, i + 1);
        current.removeLast();
      }
    }

    backtrack([], 0);
    return result;
  }

  /// Recursive solver: finds if a solution exists for the given numbers and target
  /// Returns the solution expression if found, null otherwise
  String? _findSolution(List<int> numbers, int target, {int depth = 0}) {
    if (depth > 8) return null; // Prevent infinite recursion

    // Base case: single number matches target
    if (numbers.length == 1) {
      if (numbers[0] == target) {
        return numbers[0].toString();
      }
      return null;
    }

    // Try all permutations of numbers
    final permutations = _generatePermutations(numbers);
    for (final perm in permutations) {
      final result = _tryOperatorCombinations(perm, target);
      if (result != null) {
        return result;
      }
    }

    // Try combining two numbers at a time (recursive approach)
    for (int i = 0; i < numbers.length; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        final num1 = numbers[i];
        final num2 = numbers[j];

        // Try all operators between these two numbers
        for (final op in ['+', '-', '*', '/']) {
          int? combined;

          try {
            switch (op) {
              case '+':
                combined = num1 + num2;
                break;
              case '-':
                combined = num1 - num2;
                break;
              case '*':
                combined = num1 * num2;
                break;
              case '/':
                if (num2 != 0 && num1 % num2 == 0) {
                  combined = num1 ~/ num2;
                }
                break;
            }

            if (combined != null) {
              // Create a new list with the combined number
              final newNumbers = <int>[];
              for (int k = 0; k < numbers.length; k++) {
                if (k != i && k != j) {
                  newNumbers.add(numbers[k]);
                }
              }
              newNumbers.add(combined);

              // Recursively try to reach target
              if (_findSolution(newNumbers, target, depth: depth + 1) != null) {
                return '$num1$op$num2';
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  /// Tries all combinations of operators for a given permutation of numbers
  String? _tryOperatorCombinations(List<int> numbers, int target) {
    if (numbers.length == 1) {
      return numbers[0] == target ? numbers[0].toString() : null;
    }

    final operators = ['+', '-', '*', '/'];
    final numOperators = numbers.length - 1;

    // Generate all combinations of operators
    final opCombinations =
        _generateOperatorCombinations(operators, numOperators);

    for (final ops in opCombinations) {
      final expression = _buildExpression(numbers, ops);
      final result = evaluate(expression);

      if (result == target) {
        return expression;
      }
    }

    return null;
  }

  /// Generates all combinations of operators
  List<List<String>> _generateOperatorCombinations(
    List<String> operators,
    int count,
  ) {
    if (count == 0) return [[]];

    final result = <List<String>>[];
    final smaller = _generateOperatorCombinations(operators, count - 1);

    for (final op in operators) {
      for (final combo in smaller) {
        result.add([op, ...combo]);
      }
    }

    return result;
  }

  /// Generates all permutations of a list
  List<List<int>> _generatePermutations(List<int> list) {
    if (list.length <= 1) return [list];

    final result = <List<int>>[];
    for (int i = 0; i < list.length; i++) {
      final element = list[i];
      final remaining = list.sublist(0, i) + list.sublist(i + 1);
      final permutations = _generatePermutations(remaining);

      for (final perm in permutations) {
        result.add([element, ...perm]);
      }
    }

    return result;
  }

  /// Builds a mathematical expression string from numbers and operators
  String _buildExpression(List<int> numbers, List<String> operators) {
    final expr = StringBuffer();
    expr.write(numbers[0]);

    for (int i = 0; i < operators.length; i++) {
      expr.write(operators[i]);
      expr.write(numbers[i + 1]);
    }

    return expr.toString();
  }

  /// Evaluates a mathematical expression string.
  /// Returns the result as an int, or null if the expression is invalid.
  int? evaluate(String expression) {
    try {
      if (expression.isEmpty) return null;

      final parser = ShuntingYardParser();
      final exp = parser.parse(expression);
      final result = exp.evaluate(EvaluationType.REAL, ContextModel());

      if (result is num) {
        return result.toInt();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Finds ALL valid solutions for the given target using the available numbers
  /// Returns a list of solutions, with Mathador solutions (all 5 numbers + all 4 operators) at the top
  List<String> solve(List<int> numbers, int target) {
    final solutions = <String>{};
    
    // Generate all permutations and try all operator combinations
    final permutations = _generatePermutations(numbers);
    for (final perm in permutations) {
      final result = _findAllSolutions(perm, target);
      solutions.addAll(result);
    }

    // Convert to list and sort: Mathador solutions first
    final solutionList = solutions.toList();
    solutionList.sort((a, b) {
      final aIsMathador = _isMathadorSolution(a, numbers);
      final bIsMathador = _isMathadorSolution(b, numbers);
      
      // Mathador solutions come first
      if (aIsMathador && !bIsMathador) return -1;
      if (!aIsMathador && bIsMathador) return 1;
      return a.compareTo(b);
    });

    return solutionList;
  }

  /// Finds all solutions for a given permutation with proper parentheses
  List<String> _findAllSolutions(List<int> numbers, int target, {int depth = 0}) {
    final solutions = <String>{};
    if (depth > 8) return solutions.toList();

    if (numbers.length == 1) {
      if (numbers[0] == target) {
        solutions.add(numbers[0].toString());
      }
      return solutions.toList();
    }

    // Try all operator combinations for this permutation (with parentheses for clarity)
    final ops = _generateOperatorCombinations(['+', '-', '*', '/'], numbers.length - 1);
    for (final opList in ops) {
      final expr = _buildExpression(numbers, opList);
      if (evaluate(expr) == target) {
        solutions.add(expr);
      }
    }

    // Try recursive combinations with parentheses for grouping
    for (int i = 0; i < numbers.length; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        final num1 = numbers[i];
        final num2 = numbers[j];

        for (final op in ['+', '-', '*', '/']) {
          int? combined;

          try {
            switch (op) {
              case '+':
                combined = num1 + num2;
                break;
              case '-':
                combined = num1 - num2;
                break;
              case '*':
                combined = num1 * num2;
                break;
              case '/':
                if (num2 != 0 && num1 % num2 == 0) {
                  combined = num1 ~/ num2;
                }
                break;
            }

            if (combined != null) {
              final newNumbers = <int>[];
              for (int k = 0; k < numbers.length; k++) {
                if (k != i && k != j) {
                  newNumbers.add(numbers[k]);
                }
              }
              newNumbers.add(combined);

              final recursiveSolutions = _findAllSolutions(newNumbers, target, depth: depth + 1);
              // Add parentheses to recursive solutions for clarity
              for (final sol in recursiveSolutions) {
                final withParens = '($num1 $op $num2) ... $sol';
                solutions.add(withParens);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    return solutions.toList();
  }

  /// Checks if a solution uses all 5 numbers and all 4 operators
  bool _isMathadorSolution(String expression, List<int> numbers) {
    if (numbers.length != 5) return false;

    // Count unique operators
    final operators = {'+', '-', '*', '/'};
    final usedOps = <String>{};
    
    for (final op in operators) {
      if (expression.contains(op)) {
        usedOps.add(op);
      }
    }

    // Must use all 4 operators
    if (usedOps.length != 4) return false;

    // Count numbers in expression - should be 5 (or more if there are multi-digit numbers)
    final numberCount = _countNumbersInExpression(expression);
    return numberCount == 5;
  }

  /// Counts numbers in an expression
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
}
