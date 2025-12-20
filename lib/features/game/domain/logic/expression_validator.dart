import 'package:math_expressions/math_expressions.dart';

class ExpressionValidator {
  static final RegExp _allowedChars = RegExp(r'^[0-9+\-*/()\s]+$');
  static final RegExp _numbersRegex = RegExp(r'\d+');

  static bool isSafeExpression(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return false;
    return _allowedChars.hasMatch(trimmed);
  }

  /// Evaluates a math expression using `math_expressions`.
  /// Returns `null` if invalid.
  static int? evaluateToInt(String expression) {
    try {
      final trimmed = expression.trim();
      if (trimmed.isEmpty) return null;

      final parser = ShuntingYardParser();
      final exp = parser.parse(trimmed);
      final result = exp.evaluate(EvaluationType.REAL, ContextModel());

      if (result is num) {
        // Guard against NaN/Infinity
        if (!result.isFinite) return null;

        final rounded = result.round();
        // Accept only exact integers (within small tolerance)
        if ((result - rounded).abs() > 1e-9) return null;
        return rounded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks that the expression uses exactly the available numbers (multiset).
  /// For example: numbers [3, 6, 8, 8] must appear as 3,6,8,8 (order doesn't matter).
  static bool usesExactNumbers(String expression, List<int> availableNumbers) {
    final matches = _numbersRegex
        .allMatches(expression)
        .map((m) => int.parse(m.group(0)!))
        .toList(growable: false);

    if (matches.length != availableNumbers.length) return false;

    final remaining = <int, int>{};
    for (final n in availableNumbers) {
      remaining[n] = (remaining[n] ?? 0) + 1;
    }

    for (final used in matches) {
      final count = remaining[used] ?? 0;
      if (count <= 0) return false;
      remaining[used] = count - 1;
    }

    return true;
  }

  static bool validatesToTarget({
    required String expression,
    required List<int> availableNumbers,
    required int target,
    bool requireExactNumbers = true,
  }) {
    if (!isSafeExpression(expression)) return false;
    if (requireExactNumbers && !usesExactNumbers(expression, availableNumbers)) {
      return false;
    }

    final value = evaluateToInt(expression);
    if (value == null) return false;
    return value == target;
  }
}
