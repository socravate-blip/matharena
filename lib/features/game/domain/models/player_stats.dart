/// Modèle complet des statistiques d'un joueur
class PlayerStats {
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;
  final int currentWinStreak;
  final int currentLoseStreak;
  final int bestWinStreak;
  final int bestLoseStreak;

  // Historique ELO (timestamp -> elo)
  final Map<int, int> eloHistory;

  // Stats par type de puzzle
  final PuzzleTypeStats basicStats;
  final PuzzleTypeStats complexStats;
  final PuzzleTypeStats game24Stats;
  final PuzzleTypeStats mathadoreStats;

  // Stats temporelles
  final Map<String, int> gamesPerDay; // YYYY-MM-DD -> count
  final Map<String, double> avgResponseTimePerDay; // YYYY-MM-DD -> ms

  // Records personnels
  final int fastestSolve; // en ms
  final int slowestSolve; // en ms
  final int longestMatch; // en secondes
  final int shortestMatch; // en secondes

  const PlayerStats({
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentWinStreak = 0,
    this.currentLoseStreak = 0,
    this.bestWinStreak = 0,
    this.bestLoseStreak = 0,
    this.eloHistory = const {},
    this.basicStats = const PuzzleTypeStats(),
    this.complexStats = const PuzzleTypeStats(),
    this.game24Stats = const PuzzleTypeStats(),
    this.mathadoreStats = const PuzzleTypeStats(),
    this.gamesPerDay = const {},
    this.avgResponseTimePerDay = const {},
    this.fastestSolve = 0,
    this.slowestSolve = 0,
    this.longestMatch = 0,
    this.shortestMatch = 0,
  });

  /// Calcul du win rate (%)
  double get winRate {
    if (totalGames == 0) return 0.0;
    return (wins / totalGames) * 100;
  }

  /// Calcul du temps de réponse moyen global (ms)
  double get avgResponseTime {
    if (avgResponseTimePerDay.isEmpty) return 0.0;
    final sum = avgResponseTimePerDay.values.reduce((a, b) => a + b);
    return sum / avgResponseTimePerDay.length;
  }

  /// Streak actuel (positif = win, négatif = lose)
  int get currentStreak {
    if (currentWinStreak > 0) return currentWinStreak;
    if (currentLoseStreak > 0) return -currentLoseStreak;
    return 0;
  }

  /// String formaté du streak
  String get streakDisplay {
    if (currentWinStreak > 0) return '🔥 $currentWinStreak Win Streak';
    if (currentLoseStreak > 0) return '❄️ $currentLoseStreak Lose Streak';
    return '➖ No Streak';
  }

  /// Copie avec modifications
  PlayerStats copyWith({
    int? totalGames,
    int? wins,
    int? losses,
    int? draws,
    int? currentWinStreak,
    int? currentLoseStreak,
    int? bestWinStreak,
    int? bestLoseStreak,
    Map<int, int>? eloHistory,
    PuzzleTypeStats? basicStats,
    PuzzleTypeStats? complexStats,
    PuzzleTypeStats? game24Stats,
    PuzzleTypeStats? mathadoreStats,
    Map<String, int>? gamesPerDay,
    Map<String, double>? avgResponseTimePerDay,
    int? fastestSolve,
    int? slowestSolve,
    int? longestMatch,
    int? shortestMatch,
  }) {
    return PlayerStats(
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      currentLoseStreak: currentLoseStreak ?? this.currentLoseStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      bestLoseStreak: bestLoseStreak ?? this.bestLoseStreak,
      eloHistory: eloHistory ?? this.eloHistory,
      basicStats: basicStats ?? this.basicStats,
      complexStats: complexStats ?? this.complexStats,
      game24Stats: game24Stats ?? this.game24Stats,
      mathadoreStats: mathadoreStats ?? this.mathadoreStats,
      gamesPerDay: gamesPerDay ?? this.gamesPerDay,
      avgResponseTimePerDay:
          avgResponseTimePerDay ?? this.avgResponseTimePerDay,
      fastestSolve: fastestSolve ?? this.fastestSolve,
      slowestSolve: slowestSolve ?? this.slowestSolve,
      longestMatch: longestMatch ?? this.longestMatch,
      shortestMatch: shortestMatch ?? this.shortestMatch,
    );
  }

  /// Conversion depuis Firestore
  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      totalGames: map['totalGames'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      currentWinStreak: map['currentWinStreak'] ?? 0,
      currentLoseStreak: map['currentLoseStreak'] ?? 0,
      bestWinStreak: map['bestWinStreak'] ?? 0,
      bestLoseStreak: map['bestLoseStreak'] ?? 0,
      eloHistory: Map<int, int>.from(map['eloHistory'] ?? {}),
      basicStats: PuzzleTypeStats.fromMap(map['basicStats'] ?? {}),
      complexStats: PuzzleTypeStats.fromMap(map['complexStats'] ?? {}),
      game24Stats: PuzzleTypeStats.fromMap(map['game24Stats'] ?? {}),
      mathadoreStats: PuzzleTypeStats.fromMap(map['mathadoreStats'] ?? {}),
      gamesPerDay: Map<String, int>.from(map['gamesPerDay'] ?? {}),
      avgResponseTimePerDay:
          (map['avgResponseTimePerDay'] as Map<String, dynamic>?)?.map(
                (key, value) => MapEntry(key, (value as num).toDouble()),
              ) ??
              {},
      fastestSolve: map['fastestSolve'] ?? 0,
      slowestSolve: map['slowestSolve'] ?? 0,
      longestMatch: map['longestMatch'] ?? 0,
      shortestMatch: map['shortestMatch'] ?? 0,
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'currentWinStreak': currentWinStreak,
      'currentLoseStreak': currentLoseStreak,
      'bestWinStreak': bestWinStreak,
      'bestLoseStreak': bestLoseStreak,
      'eloHistory': eloHistory,
      'basicStats': basicStats.toMap(),
      'complexStats': complexStats.toMap(),
      'game24Stats': game24Stats.toMap(),
      'mathadoreStats': mathadoreStats.toMap(),
      'gamesPerDay': gamesPerDay,
      'avgResponseTimePerDay': avgResponseTimePerDay,
      'fastestSolve': fastestSolve,
      'slowestSolve': slowestSolve,
      'longestMatch': longestMatch,
      'shortestMatch': shortestMatch,
    };
  }
}

/// Stats par type de puzzle
class PuzzleTypeStats {
  final int totalAttempts;
  final int correctAnswers;
  final int wrongAnswers;
  final double avgResponseTime; // en ms
  final int fastestSolve; // en ms
  final int slowestSolve; // en ms

  const PuzzleTypeStats({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.avgResponseTime = 0.0,
    this.fastestSolve = 0,
    this.slowestSolve = 0,
  });

  /// Taux de réussite (%)
  double get accuracy {
    if (totalAttempts == 0) return 0.0;
    return (correctAnswers / totalAttempts) * 100;
  }

  PuzzleTypeStats copyWith({
    int? totalAttempts,
    int? correctAnswers,
    int? wrongAnswers,
    double? avgResponseTime,
    int? fastestSolve,
    int? slowestSolve,
  }) {
    return PuzzleTypeStats(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      fastestSolve: fastestSolve ?? this.fastestSolve,
      slowestSolve: slowestSolve ?? this.slowestSolve,
    );
  }

  factory PuzzleTypeStats.fromMap(Map<String, dynamic> map) {
    return PuzzleTypeStats(
      totalAttempts: map['totalAttempts'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      avgResponseTime: (map['avgResponseTime'] ?? 0.0).toDouble(),
      fastestSolve: map['fastestSolve'] ?? 0,
      slowestSolve: map['slowestSolve'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAttempts': totalAttempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'avgResponseTime': avgResponseTime,
      'fastestSolve': fastestSolve,
      'slowestSolve': slowestSolve,
    };
  }
}
