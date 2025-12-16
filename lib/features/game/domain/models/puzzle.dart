/// Abstract base class for all game puzzles
abstract class GamePuzzle {
  final String id;
  final int targetValue;
  final int maxPoints;
  final int timeLimit; // seconds

  const GamePuzzle({
    required this.id,
    required this.targetValue,
    required this.maxPoints,
    required this.timeLimit,
  });

  /// Validates if the user's answer is correct
  bool validateAnswer(dynamic answer);

  /// Returns the puzzle type for UI rendering
  PuzzleType get type;
  
  /// Convert to JSON for Firebase storage
  Map<String, dynamic> toJson();
  
  /// Create from JSON
  static GamePuzzle fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    switch (typeStr) {
      case 'basic':
        return BasicPuzzle.fromJson(json);
      case 'complex':
        return ComplexPuzzle.fromJson(json);
      case 'game24':
        return Game24Puzzle.fromJson(json);
      case 'matador':
        return MatadorPuzzle.fromJson(json);
      default:
        throw Exception('Unknown puzzle type: $typeStr');
    }
  }
}

enum PuzzleType {
  basic,
  complex,
  game24,
  matador,
}

/// Basic arithmetic puzzle: A op B = ?
/// Example: 5 + 3 = ?
class BasicPuzzle extends GamePuzzle {
  final int numberA;
  final int numberB;
  final String operator;

  const BasicPuzzle({
    required super.id,
    required super.targetValue,
    required this.numberA,
    required this.numberB,
    required this.operator,
    super.maxPoints = 1,
    super.timeLimit = 30,
  });

  @override
  bool validateAnswer(dynamic answer) {
    if (answer is! int) return false;
    return answer == targetValue;
  }

  @override
  PuzzleType get type => PuzzleType.basic;

  String get question => '$numberA $operator $numberB = ?';
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'basic',
    'id': id,
    'targetValue': targetValue,
    'maxPoints': maxPoints,
    'timeLimit': timeLimit,
    'numberA': numberA,
    'numberB': numberB,
    'operator': operator,
  };
  
  factory BasicPuzzle.fromJson(Map<String, dynamic> json) => BasicPuzzle(
    id: json['id'] as String,
    targetValue: json['targetValue'] as int,
    maxPoints: json['maxPoints'] as int? ?? 1,
    timeLimit: json['timeLimit'] as int? ?? 30,
    numberA: json['numberA'] as int,
    numberB: json['numberB'] as int,
    operator: json['operator'] as String,
  );
}

/// Complex puzzle with nested operations: A op (B op C) = ?
/// Example: 10 - (3 + 5) = ?
class ComplexPuzzle extends GamePuzzle {
  final int numberA;
  final int numberB;
  final int numberC;
  final String operator1;
  final String operator2;
  final bool useParentheses;
  final bool allowNegatives;

  const ComplexPuzzle({
    required super.id,
    required super.targetValue,
    required this.numberA,
    required this.numberB,
    required this.numberC,
    required this.operator1,
    required this.operator2,
    this.useParentheses = true,
    this.allowNegatives = true,
    super.maxPoints = 2,
    super.timeLimit = 45,
  });

  @override
  bool validateAnswer(dynamic answer) {
    if (answer is! int) return false;
    return answer == targetValue;
  }

  @override
  PuzzleType get type => PuzzleType.complex;

  String get question {
    if (useParentheses) {
      return '$numberA $operator1 ($numberB $operator2 $numberC) = ?';
    } else {
      return '$numberA $operator1 $numberB $operator2 $numberC = ?';
    }
  }
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'complex',
    'id': id,
    'targetValue': targetValue,
    'maxPoints': maxPoints,
    'timeLimit': timeLimit,
    'numberA': numberA,
    'numberB': numberB,
    'numberC': numberC,
    'operator1': operator1,
    'operator2': operator2,
    'useParentheses': useParentheses,
    'allowNegatives': allowNegatives,
  };
  
  factory ComplexPuzzle.fromJson(Map<String, dynamic> json) => ComplexPuzzle(
    id: json['id'] as String,
    targetValue: json['targetValue'] as int,
    maxPoints: json['maxPoints'] as int? ?? 2,
    timeLimit: json['timeLimit'] as int? ?? 45,
    numberA: json['numberA'] as int,
    numberB: json['numberB'] as int,
    numberC: json['numberC'] as int,
    operator1: json['operator1'] as String,
    operator2: json['operator2'] as String,
    useParentheses: json['useParentheses'] as bool? ?? true,
    allowNegatives: json['allowNegatives'] as bool? ?? true,
  );
}

/// Game 24 puzzle: Make 24 using 4 numbers
/// Example: Make 24 with [3, 6, 8, 8]
class Game24Puzzle extends GamePuzzle {
  final List<int> availableNumbers;
  final Set<String>? validSolutions; // Pre-computed solutions (optional)

  const Game24Puzzle({
    required super.id,
    required this.availableNumbers,
    this.validSolutions,
    super.targetValue = 24,
    super.maxPoints = 5,
    super.timeLimit = 120,
  });

  @override
  bool validateAnswer(dynamic answer) {
    // Answer should be a valid expression string
    if (answer is! String) return false;

    // Validate it evaluates to 24
    // This will be implemented in the engine
    return true; // Placeholder
  }

  @override
  PuzzleType get type => PuzzleType.game24;

  String get question =>
      'Make $targetValue with: ${availableNumbers.join(", ")}';
      
  @override
  Map<String, dynamic> toJson() => {
    'type': 'game24',
    'id': id,
    'targetValue': targetValue,
    'maxPoints': maxPoints,
    'timeLimit': timeLimit,
    'availableNumbers': availableNumbers,
    'validSolutions': validSolutions?.toList(),
  };
  
  factory Game24Puzzle.fromJson(Map<String, dynamic> json) => Game24Puzzle(
    id: json['id'] as String,
    targetValue: json['targetValue'] as int? ?? 24,
    maxPoints: json['maxPoints'] as int? ?? 5,
    timeLimit: json['timeLimit'] as int? ?? 120,
    availableNumbers: (json['availableNumbers'] as List).cast<int>(),
    validSolutions: json['validSolutions'] != null 
      ? (json['validSolutions'] as List).cast<String>().toSet()
      : null,
  );
}

/// Matador puzzle: Reach target with 5 numbers using all 4 operations
/// Example: Make 42 with [2, 3, 5, 7, 10]
class MatadorPuzzle extends GamePuzzle {
  final List<int> availableNumbers;
  final Set<String>? validSolutions;
  final int solutionCount;

  const MatadorPuzzle({
    required super.id,
    required super.targetValue,
    required this.availableNumbers,
    this.validSolutions,
    this.solutionCount = 0,
    super.maxPoints = 13,
    super.timeLimit = 360,
  });

  @override
  bool validateAnswer(dynamic answer) {
    // Answer should be a valid expression string
    if (answer is! String) return false;

    // Validate it reaches the target
    // This will be implemented in the engine
    return true; // Placeholder
  }

  @override
  PuzzleType get type => PuzzleType.matador;

  String get question =>
      'Reach $targetValue with: ${availableNumbers.join(", ")}';

  bool isMathadorSolution(String expression) {
    // Check if uses all 4 operations
    return expression.contains('+') &&
        expression.contains('-') &&
        expression.contains('*') &&
        expression.contains('/');
  }
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'matador',
    'id': id,
    'targetValue': targetValue,
    'maxPoints': maxPoints,
    'timeLimit': timeLimit,
    'availableNumbers': availableNumbers,
    'validSolutions': validSolutions?.toList(),
    'solutionCount': solutionCount,
  };
  
  factory MatadorPuzzle.fromJson(Map<String, dynamic> json) => MatadorPuzzle(
    id: json['id'] as String,
    targetValue: json['targetValue'] as int,
    maxPoints: json['maxPoints'] as int? ?? 13,
    timeLimit: json['timeLimit'] as int? ?? 360,
    availableNumbers: (json['availableNumbers'] as List).cast<int>(),
    validSolutions: json['validSolutions'] != null 
      ? (json['validSolutions'] as List).cast<String>().toSet()
      : null,
    solutionCount: json['solutionCount'] as int? ?? 0,
  );
}
