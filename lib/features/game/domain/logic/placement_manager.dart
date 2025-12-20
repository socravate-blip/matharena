import '../models/puzzle.dart';

/// Represents the state of placement/calibration matches
class PlacementState {
  final int matchesCompleted; // 0 to 3
  final List<PlacementMatchResult> results;
  final int? calculatedElo;
  final bool isComplete;

  const PlacementState({
    this.matchesCompleted = 0,
    this.results = const [],
    this.calculatedElo,
    this.isComplete = false,
  });

  PlacementState copyWith({
    int? matchesCompleted,
    List<PlacementMatchResult>? results,
    int? calculatedElo,
    bool? isComplete,
  }) {
    return PlacementState(
      matchesCompleted: matchesCompleted ?? this.matchesCompleted,
      results: results ?? this.results,
      calculatedElo: calculatedElo ?? this.calculatedElo,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Result of a single placement match
class PlacementMatchResult {
  final int matchNumber; // 1, 2, or 3
  final PuzzleType puzzleType;
  final int correctAnswers;
  final int totalQuestions;
  final List<int> responseTimes; // in milliseconds
  final bool won;

  const PlacementMatchResult({
    required this.matchNumber,
    required this.puzzleType,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.responseTimes,
    required this.won,
  });

  /// Accuracy percentage (0-100)
  double get accuracy => (correctAnswers / totalQuestions) * 100;

  /// Average response time in milliseconds
  double get averageResponseTime {
    if (responseTimes.isEmpty) return 0;
    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }
}

/// Manages the 3-match placement/calibration system for new players
class PlacementManager {
  /// Determines puzzle type for the given placement match
  static PuzzleType getPuzzleTypeForMatch(int matchNumber) {
    switch (matchNumber) {
      case 1:
        return PuzzleType.basic; // Simple operations
      case 2:
        return PuzzleType.complex; // Complex equations with negatives
      case 3:
        return PuzzleType.game24; // Game of 24
      default:
        throw ArgumentError('Match number must be 1, 2, or 3');
    }
  }

  /// Calculate initial ELO based on placement match performance
  /// 
  /// Formula considers:
  /// - Accuracy (weight: 50%)
  /// - Speed (weight: 30%) 
  /// - Win rate (weight: 20%)
  /// 
  /// Returns ELO between 800 and 1600
  static int calculateInitialElo(List<PlacementMatchResult> results) {
    if (results.length != 3) {
      throw ArgumentError('Must have exactly 3 placement match results');
    }

    // Calculate overall accuracy
    final totalCorrect = results.fold<int>(0, (sum, r) => sum + r.correctAnswers);
    final totalQuestions = results.fold<int>(0, (sum, r) => sum + r.totalQuestions);
    final overallAccuracy = (totalCorrect / totalQuestions) * 100;

    // Calculate average response time
    final allResponseTimes = results.expand((r) => r.responseTimes).toList();
    final avgResponseTime = allResponseTimes.reduce((a, b) => a + b) / allResponseTimes.length;

    // Calculate win rate
    final wins = results.where((r) => r.won).length;
    final winRate = (wins / 3) * 100;

    // Base ELO starts at 1000 (below average)
    double calculatedElo = 1000.0;

    // Accuracy component (±300 ELO based on 0-100% accuracy)
    // 0% accuracy = -300, 50% = 0, 100% = +300
    final accuracyBonus = ((overallAccuracy - 50) / 50) * 300;
    calculatedElo += accuracyBonus;

    // Speed component (±200 ELO)
    // Fast response (< 3s avg) = +200, Medium (5s) = 0, Slow (> 8s) = -200
    final speedScore = _calculateSpeedScore(avgResponseTime);
    calculatedElo += speedScore;

    // Win rate component (±100 ELO)
    // 0 wins = -100, 1 win = -33, 2 wins = +33, 3 wins = +100
    final winBonus = ((winRate - 50) / 50) * 100;
    calculatedElo += winBonus;

    // Puzzle type difficulty adjustment
    // Bonus points if player performed well on harder puzzles
    final game24Result = results.firstWhere((r) => r.puzzleType == PuzzleType.game24);
    if (game24Result.accuracy > 70) {
      calculatedElo += 50; // Bonus for handling difficult puzzles
    }

    // Clamp to valid range
    return calculatedElo.round().clamp(800, 1600);
  }

  /// Calculate speed score based on average response time
  /// Returns value between -200 and +200
  static double _calculateSpeedScore(double avgResponseTimeMs) {
    // Ideal response time: 3-5 seconds
    const idealMin = 3000.0;
    const idealMax = 5000.0;

    if (avgResponseTimeMs <= idealMin) {
      // Very fast: +200
      return 200.0;
    } else if (avgResponseTimeMs <= idealMax) {
      // Good speed: +100 to +200
      final ratio = (idealMax - avgResponseTimeMs) / (idealMax - idealMin);
      return 100 + (ratio * 100);
    } else if (avgResponseTimeMs <= 8000) {
      // Moderate: 0 to +100
      final ratio = (8000 - avgResponseTimeMs) / (8000 - idealMax);
      return ratio * 100;
    } else if (avgResponseTimeMs <= 12000) {
      // Slow: -100 to 0
      final ratio = (avgResponseTimeMs - 8000) / 4000;
      return -(ratio * 100);
    } else {
      // Very slow: -200
      return -200.0;
    }
  }

  /// Get a descriptive rank title based on initial ELO
  static String getInitialRankTitle(int elo) {
    if (elo < 900) return 'Beginner';
    if (elo < 1000) return 'Novice';
    if (elo < 1100) return 'Apprentice';
    if (elo < 1200) return 'Intermediate';
    if (elo < 1300) return 'Skilled';
    if (elo < 1400) return 'Advanced';
    if (elo < 1500) return 'Expert';
    return 'Prodigy';
  }

  /// Get motivational message based on placement results
  static String getPlacementCompleteMessage(int elo, List<PlacementMatchResult> results) {
    if (elo >= 1400) {
      return 'Exceptional! You\'ve been placed at ${getInitialRankTitle(elo)} level. You\'re ready for serious competition!';
    } else if (elo >= 1200) {
      return 'Great performance! Starting at ${getInitialRankTitle(elo)} level. Keep improving!';
    } else if (elo >= 1000) {
      return 'Good start! You\'re at ${getInitialRankTitle(elo)} level. Practice makes perfect!';
    } else {
      return 'Welcome to MathArena! Starting at ${getInitialRankTitle(elo)} level. Don\'t worry, everyone improves with practice!';
    }
  }

  /// Determine if player needs more practice before ranked
  static bool shouldRecommendPractice(List<PlacementMatchResult> results) {
    final avgAccuracy = results.fold<double>(0, (sum, r) => sum + r.accuracy) / 3;
    final wins = results.where((r) => r.won).length;
    
    // Recommend practice if accuracy < 40% or 0 wins
    return avgAccuracy < 40 || wins == 0;
  }

  /// Get difficulty recommendation for practice
  static String getPracticeDifficultyRecommendation(int elo) {
    if (elo < 1000) return 'Start with Basic puzzles to build confidence';
    if (elo < 1200) return 'Try a mix of Basic and Complex puzzles';
    if (elo < 1400) return 'Focus on Complex puzzles and Game24';
    return 'Challenge yourself with Matador puzzles';
  }
}
