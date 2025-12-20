import '../models/puzzle.dart';
import '../logic/puzzle_generator.dart';

/// Performance d'un match de calibration
class GamePerformance {
  final int matchNumber; // 1, 2, ou 3
  final PuzzleType puzzleType;
  final int correctAnswers;
  final int totalPuzzles;
  final int totalTimeMs;
  final List<int> responseTimes; // Temps de réponse individuels en ms

  GamePerformance({
    required this.matchNumber,
    required this.puzzleType,
    required this.correctAnswers,
    required this.totalPuzzles,
    required this.totalTimeMs,
    required this.responseTimes,
  });

  /// Précision (%)
  double get accuracy => (correctAnswers / totalPuzzles) * 100;

  /// Temps moyen de réponse (ms)
  double get averageResponseTime =>
      responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

  Map<String, dynamic> toMap() {
    return {
      'matchNumber': matchNumber,
      'puzzleType': puzzleType.toString().split('.').last,
      'correctAnswers': correctAnswers,
      'totalPuzzles': totalPuzzles,
      'totalTimeMs': totalTimeMs,
      'accuracy': accuracy,
      'averageResponseTime': averageResponseTime,
    };
  }
}

/// Service de Calibration - Gère les 3 matchs de placement
class PlacementService {
  /// Configuration des 3 épreuves de calibration
  static const int totalPlacementMatches = 3;
  static const int puzzlesPerMatch = 10; // Nombre de puzzles par match

  /// Retourne le type de puzzle pour chaque match de calibration
  static PuzzleType getPuzzleTypeForMatch(int matchNumber) {
    switch (matchNumber) {
      case 1:
        return PuzzleType.basic; // Match 1: Arithmétique simple
      case 2:
        return PuzzleType.complex; // Match 2: Équations complexes
      case 3:
        return PuzzleType.game24; // Match 3: Jeu de 24
      default:
        throw ArgumentError('Match number must be 1, 2, or 3');
    }
  }

  /// Génère les puzzles pour un match de calibration spécifique
  /// Le bot "étalon" est fixé à 1200 ELO (niveau moyen) pour référence
  static List<GamePuzzle> generateCalibrationPuzzles(int matchNumber) {
    final puzzleType = getPuzzleTypeForMatch(matchNumber);

    print('📝 Generating calibration puzzles for Match $matchNumber');
    print('   Type: ${puzzleType.toString().split('.').last}');
    print('   Count: $puzzlesPerMatch');

    return PuzzleGenerator.generateByType(
      type: puzzleType,
      count: puzzlesPerMatch,
    );
  }

  /// Calcule l'ELO initial basé sur les performances des 3 matchs
  /// 
  /// **Formule:**
  /// ```
  /// InitialELO = Base(1000) + (ScoreMoyen * Multiplicateur) + (BonusVitesse)
  /// ```
  /// 
  /// - **Base:** 1000 ELO (Bronze)
  /// - **ScoreMoyen:** Moyenne des précisions (0-100%)
  /// - **Multiplicateur:** 4 (pour convertir % en points ELO)
  /// - **BonusVitesse:** Jusqu'à +200 pour les réponses rapides
  static int calculateInitialElo(List<GamePerformance> performances) {
    if (performances.length != totalPlacementMatches) {
      throw ArgumentError(
          'Expected $totalPlacementMatches performances, got ${performances.length}');
    }

    print('\n📊 Calculating Initial ELO from placement matches:');

    // 1. Base ELO (minimum)
    const minElo = 800;
    const maxElo = 1500;
    const baseElo = minElo;
    print('   Base ELO (min): $baseElo');

    // 2. Calcul du score moyen (précision)
    final averageAccuracy =
        performances.map((p) => p.accuracy).reduce((a, b) => a + b) /
            performances.length;
    print('   Average Accuracy: ${averageAccuracy.toStringAsFixed(1)}%');

    // 3. Bonus de précision (plus fort que la vitesse)
    // 0% -> +0 ; 100% -> +500
    final accuracyBonus = (averageAccuracy * 5).round();
    print('   Accuracy Bonus: +$accuracyBonus ELO');

    // 4. Bonus de vitesse (basé sur temps de réponse moyen)
    final averageResponseTime =
        performances.map((p) => p.averageResponseTime).reduce((a, b) => a + b) /
            performances.length;

    // Bonus de vitesse pondéré par la précision.
    // => si tu réponds très vite mais faux, tu ne prends pas de bonus.
    final accuracyRatio = (averageAccuracy / 100).clamp(0.0, 1.0);

    int rawSpeedBonus = 0;
    if (averageResponseTime < 2000) {
      rawSpeedBonus = 150;
    } else if (averageResponseTime < 4000) {
      rawSpeedBonus = 90;
    } else if (averageResponseTime < 6000) {
      rawSpeedBonus = 40;
    }

    final speedBonus = (rawSpeedBonus * accuracyRatio).round();

    print('   Average Response Time: ${averageResponseTime.toStringAsFixed(0)}ms');
    print('   Speed Bonus: +$speedBonus ELO');

    // 5. Calcul final
    final initialElo = baseElo + accuracyBonus + speedBonus;
    final clampedElo = initialElo.clamp(minElo, maxElo);

    print('   → Initial ELO: $clampedElo');
    print('   → League: ${_getLeagueName(clampedElo)}');

    return clampedElo;
  }

  /// Retourne le nom de la ligue pour un ELO donné
  static String _getLeagueName(int elo) {
    if (elo < 1200) return '🥉 Bronze';
    if (elo < 1500) return '🥈 Silver';
    if (elo < 1800) return '🥇 Gold';
    return '💎 Diamond';
  }

  /// Génère un bot "étalon" pour la calibration
  /// Ce bot a toujours le même niveau (1200 ELO) et sert de référence
  static Map<String, dynamic> createCalibrationBot() {
    const calibrationElo = 1200;

    return {
      'name': 'Calibration Bot',
      'elo': calibrationElo,
      'description': 'Bot de référence pour la calibration',
      'isCalibration': true,
    };
  }

  /// Retourne un message de résumé pour le joueur après calibration
  static String getCalibrationSummary(List<GamePerformance> performances, int finalElo) {
    final averageAccuracy =
        performances.map((p) => p.accuracy).reduce((a, b) => a + b) /
            performances.length;

    final averageResponseTime =
        performances.map((p) => p.averageResponseTime).reduce((a, b) => a + b) /
            performances.length;

    final league = _getLeagueName(finalElo);

    return '''
🎯 Calibration Terminée !

📊 Résultats:
  • Précision moyenne: ${averageAccuracy.toStringAsFixed(1)}%
  • Temps moyen: ${(averageResponseTime / 1000).toStringAsFixed(1)}s
  
🏆 ELO Initial: $finalElo
📈 Ligue: $league

Vous êtes maintenant prêt pour les matchs classés !
''';
  }

  /// Retourne des recommandations d'entraînement basées sur les performances
  static String getPracticeRecommendations(List<GamePerformance> performances) {
    final sortedPerfs = List<GamePerformance>.from(performances)
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final weakestType = sortedPerfs.first.puzzleType;

    final recommendations = <String>[];

    if (sortedPerfs.first.accuracy < 60) {
      recommendations.add(
          '🎯 Entraînez-vous sur les puzzles ${_puzzleTypeName(weakestType)}');
    }

    if (sortedPerfs.any((p) => p.averageResponseTime > 8000)) {
      recommendations.add('⚡ Travaillez votre vitesse de calcul mental');
    }

    if (recommendations.isEmpty) {
      return '✅ Excellente performance ! Continuez comme ça !';
    }

    return '💡 Recommandations:\n${recommendations.join('\n')}';
  }

  static String _puzzleTypeName(PuzzleType type) {
    switch (type) {
      case PuzzleType.basic:
        return 'Arithmétique de base';
      case PuzzleType.complex:
        return 'Équations complexes';
      case PuzzleType.game24:
        return 'Jeu de 24';
      case PuzzleType.matador:
        return 'Matador';
    }
  }
}
