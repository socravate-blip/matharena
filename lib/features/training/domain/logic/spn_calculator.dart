import '../models/training_models.dart';

/// Calculateur de Score de Performance Normalisé
class SPNCalculator {
  /// Calcule le score d'une question individuelle
  /// Score = Difficulté / Temps
  static double calculateQuestionScore({
    required double difficultyCoefficient,
    required double timeSeconds,
    required bool isCorrect,
  }) {
    if (!isCorrect || timeSeconds == 0) return 0.0;
    return difficultyCoefficient / timeSeconds;
  }

  /// Calcule le SPN d'une session (moyenne des scores valides)
  static double calculateSessionSPN(List<QuestionResult> results) {
    if (results.isEmpty) return 0.0;

    final validScores = results
        .where((r) => r.isCorrect)
        .map((r) => r.questionScore)
        .toList();

    if (validScores.isEmpty) return 0.0;

    final sum = validScores.reduce((a, b) => a + b);
    return sum / validScores.length;
  }

  /// Calcule une moyenne mobile pour lisser la courbe de progression
  /// window: nombre de sessions à considérer (par défaut 3)
  static List<double> calculateMovingAverage(
    List<double> values, {
    int window = 3,
  }) {
    if (values.length < window) return values;

    final result = <double>[];
    for (int i = 0; i < values.length; i++) {
      final start = i < window ? 0 : i - window + 1;
      final windowValues = values.sublist(start, i + 1);
      final avg = windowValues.reduce((a, b) => a + b) / windowValues.length;
      result.add(avg);
    }
    return result;
  }

  /// Convertit un SPN en "Niveau Mental" (rating)
  /// Formule arbitraire mais cohérente
  static int spnToMentalRating(double spn) {
    // SPN typique : 0.5 - 5.0
    // Rating cible : 800 - 2000
    return (800 + (spn * 240)).round().clamp(800, 3000);
  }

  /// Détermine un label de niveau basé sur le rating
  static String getMentalRatingLabel(int rating) {
    if (rating < 1000) return 'Beginner';
    if (rating < 1200) return 'Novice';
    if (rating < 1400) return 'Intermediate';
    if (rating < 1600) return 'Advanced';
    if (rating < 1800) return 'Expert';
    if (rating < 2000) return 'Master';
    return 'Grandmaster';
  }
}
