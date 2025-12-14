import '../../domain/logic/training_engine.dart';

/// Résultat d'une question individuelle
class QuestionResult {
  final int operand1;
  final int operand2;
  final TrainingOperator operator;
  final int correctAnswer;
  final int? userAnswer;
  final double timeSeconds;
  final double difficultyCoefficient;
  final bool isCorrect;

  QuestionResult({
    required this.operand1,
    required this.operand2,
    required this.operator,
    required this.correctAnswer,
    this.userAnswer,
    required this.timeSeconds,
    required this.difficultyCoefficient,
    required this.isCorrect,
  });

  /// Score de la question (difficulté / temps)
  double get questionScore {
    if (!isCorrect || timeSeconds == 0) return 0.0;
    return difficultyCoefficient / timeSeconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'operand1': operand1,
      'operand2': operand2,
      'operator': operator.index,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'timeSeconds': timeSeconds,
      'difficultyCoefficient': difficultyCoefficient,
      'isCorrect': isCorrect,
    };
  }

  factory QuestionResult.fromMap(Map<String, dynamic> map) {
    return QuestionResult(
      operand1: map['operand1'] as int,
      operand2: map['operand2'] as int,
      operator: TrainingOperator.values[map['operator'] as int],
      correctAnswer: map['correctAnswer'] as int,
      userAnswer: map['userAnswer'] as int?,
      timeSeconds: map['timeSeconds'] as double,
      difficultyCoefficient: map['difficultyCoefficient'] as double,
      isCorrect: map['isCorrect'] as bool,
    );
  }
}

/// Session complète d'entraînement
class TrainingSession {
  final DateTime date;
  final int durationSeconds;
  final int minNumber;
  final int maxNumber;
  final Set<TrainingOperator> enabledOperators;
  final bool allowNegative;
  final List<QuestionResult> results;

  TrainingSession({
    required this.date,
    required this.durationSeconds,
    required this.minNumber,
    required this.maxNumber,
    required this.enabledOperators,
    required this.allowNegative,
    required this.results,
  });

  /// Score de Performance Normalisé (SPN)
  double get spn {
    if (results.isEmpty) return 0.0;
    final validScores = results.where((r) => r.isCorrect).map((r) => r.questionScore);
    if (validScores.isEmpty) return 0.0;
    return validScores.reduce((a, b) => a + b) / validScores.length;
  }

  /// Temps moyen par question
  double get averageTimePerQuestion {
    if (results.isEmpty) return 0.0;
    final totalTime = results.map((r) => r.timeSeconds).reduce((a, b) => a + b);
    return totalTime / results.length;
  }

  /// Taux de réussite (%)
  double get successRate {
    if (results.isEmpty) return 0.0;
    final correct = results.where((r) => r.isCorrect).length;
    return (correct / results.length) * 100;
  }

  /// Nombre total de questions
  int get totalQuestions => results.length;

  /// Nombre de questions correctes
  int get correctAnswers => results.where((r) => r.isCorrect).length;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'minNumber': minNumber,
      'maxNumber': maxNumber,
      'enabledOperators': enabledOperators.map((e) => e.index).toList(),
      'allowNegative': allowNegative,
      'results': results.map((r) => r.toMap()).toList(),
    };
  }

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['durationSeconds'] as int,
      minNumber: map['minNumber'] as int,
      maxNumber: map['maxNumber'] as int,
      enabledOperators: (map['enabledOperators'] as List)
          .map((i) => TrainingOperator.values[i as int])
          .toSet(),
      allowNegative: map['allowNegative'] as bool,
      results: (map['results'] as List)
          .map((r) => QuestionResult.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
