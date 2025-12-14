import 'dart:math';

/// Système Elo pour le mode Ranked Mathadore
/// Basé sur le système Elo classique avec adaptations pour jeux mathématiques
class EloRatingSystem {
  // Constantes du système Elo
  static const int initialRating = 1200;
  static const int kFactor = 32; // K-factor pour joueurs réguliers
  static const int kFactorNovice = 40; // K-factor pour nouveaux joueurs
  static const int noviceThreshold = 30; // Nombre de parties pour être considéré régulier

  /// Calcule le rating attendu (Expected Score)
  /// Formula: E_A = 1 / (1 + 10^((R_B - R_A) / 400))
  static double calculateExpectedScore(int playerRating, int opponentRating) {
    final exponent = (opponentRating - playerRating) / 400.0;
    return 1.0 / (1.0 + pow(10, exponent));
  }

  /// Calcule le nouveau rating après une partie
  /// Formula: R_new = R_old + K * (S - E)
  /// où S = score réel (1 = victoire, 0 = défaite, 0.5 = égalité)
  static int calculateNewRating({
    required int currentRating,
    required int opponentRating,
    required double actualScore,
    required int gamesPlayed,
  }) {
    final kFactor = gamesPlayed < noviceThreshold ? kFactorNovice : EloRatingSystem.kFactor;
    final expectedScore = calculateExpectedScore(currentRating, opponentRating);
    final ratingChange = (kFactor * (actualScore - expectedScore)).round();
    return (currentRating + ratingChange).clamp(100, 3000);
  }

  /// Calcule le score basé sur la performance dans Mathadore
  /// Prend en compte:
  /// - Score obtenu vs score maximum possible
  /// - Temps utilisé vs temps disponible
  /// - Mathador trouvé (bonus significatif)
  static double calculatePerformanceScore({
    required int playerScore,
    required int maxPossibleScore,
    required int timeUsedSeconds,
    required int totalTimeSeconds,
    required bool foundMathador,
  }) {
    // Score normalisé (0-1)
    final scoreRatio = playerScore / max(maxPossibleScore, 1);
    
    // Bonus de temps (utiliser moins de temps = mieux)
    final timeEfficiency = 1.0 - (timeUsedSeconds / totalTimeSeconds);
    
    // Bonus Mathador (13 points = score max)
    final mathadorBonus = foundMathador ? 0.3 : 0.0;
    
    // Formule composite avec pondération
    final performanceScore = (scoreRatio * 0.6) + (timeEfficiency * 0.2) + mathadorBonus;
    
    return performanceScore.clamp(0.0, 1.0);
  }

  /// Détermine le rating de l'adversaire virtuel basé sur la difficulté du niveau
  /// Dans Mathadore, l'adversaire est le niveau lui-même
  static int calculateLevelDifficulty({
    required int targetNumber,
    required List<int> availableNumbers,
    required int numberOfSolutions,
  }) {
    // Base: difficulté du target
    int difficultyRating = 1000;
    
    // Target élevé = plus difficile
    if (targetNumber > 50) difficultyRating += 100;
    if (targetNumber > 75) difficultyRating += 100;
    
    // Peu de solutions = plus difficile
    if (numberOfSolutions < 5) difficultyRating += 150;
    if (numberOfSolutions < 3) difficultyRating += 100;
    
    // Nombres disponibles complexes
    final hasLargeNumbers = availableNumbers.any((n) => n > 10);
    if (hasLargeNumbers) difficultyRating += 50;
    
    return difficultyRating.clamp(800, 1800);
  }

  /// Retourne le titre/rang basé sur le rating
  static String getRankTitle(int rating) {
    if (rating < 1000) return 'Bronze';
    if (rating < 1200) return 'Silver';
    if (rating < 1400) return 'Gold';
    if (rating < 1600) return 'Platinum';
    if (rating < 1800) return 'Diamond';
    if (rating < 2000) return 'Master';
    if (rating < 2200) return 'Grandmaster';
    return 'Legend';
  }

  /// Retourne l'icône du rang
  static String getRankIcon(int rating) {
    if (rating < 1000) return '🥉';
    if (rating < 1200) return '🥈';
    if (rating < 1400) return '🥇';
    if (rating < 1600) return '💎';
    if (rating < 1800) return '💠';
    if (rating < 2000) return '👑';
    if (rating < 2200) return '⭐';
    return '🏆';
  }

  /// Calcule les points de rating gagnés/perdus
  static int calculateRatingChange({
    required int currentRating,
    required int levelDifficulty,
    required double performanceScore,
    required int gamesPlayed,
  }) {
    final kFactor = gamesPlayed < noviceThreshold ? kFactorNovice : EloRatingSystem.kFactor;
    final expectedScore = calculateExpectedScore(currentRating, levelDifficulty);
    final ratingChange = (kFactor * (performanceScore - expectedScore)).round();
    return ratingChange;
  }

  /// Retourne la couleur associée au rang
  static String getRankColor(int rating) {
    if (rating < 1000) return '#CD7F32'; // Bronze
    if (rating < 1200) return '#C0C0C0'; // Silver
    if (rating < 1400) return '#FFD700'; // Gold
    if (rating < 1600) return '#E5E4E2'; // Platinum
    if (rating < 1800) return '#B9F2FF'; // Diamond
    if (rating < 2000) return '#9D00FF'; // Master
    if (rating < 2200) return '#FF1493'; // Grandmaster
    return '#FF0000'; // Legend
  }
}

/// Historique de rating pour tracking de progression
class RatingHistory {
  final DateTime date;
  final int rating;
  final int ratingChange;
  final int gameScore;
  final bool foundMathador;

  RatingHistory({
    required this.date,
    required this.rating,
    required this.ratingChange,
    required this.gameScore,
    required this.foundMathador,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'rating': rating,
      'ratingChange': ratingChange,
      'gameScore': gameScore,
      'foundMathador': foundMathador,
    };
  }

  factory RatingHistory.fromMap(Map<String, dynamic> map) {
    return RatingHistory(
      date: DateTime.parse(map['date']),
      rating: map['rating'],
      ratingChange: map['ratingChange'],
      gameScore: map['gameScore'],
      foundMathador: map['foundMathador'],
    );
  }
}
