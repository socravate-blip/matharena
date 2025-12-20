import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_stats.dart';

/// Service de gestion des statistiques joueur
class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les stats d'un joueur
  Future<PlayerStats> getPlayerStats(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const PlayerStats();
      }

      final data = doc.data()!;
      final statsData = data['stats'] as Map<String, dynamic>? ?? {};
      return PlayerStats.fromMap(statsData);
    } catch (e) {
      print('Error getting player stats: $e');
      return const PlayerStats();
    }
  }

  /// Stream des stats d'un joueur
  Stream<PlayerStats> streamPlayerStats(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return const PlayerStats();
      final data = doc.data()!;
      final statsData = data['stats'] as Map<String, dynamic>? ?? {};
      return PlayerStats.fromMap(statsData);
    });
  }

  /// Met à jour les stats après un match
  Future<void> updateStatsAfterMatch({
    required String uid,
    required bool isWin,
    required int newElo,
    required int matchDuration, // en secondes
    required List<PuzzleSolveData> solves,
  }) async {
    try {
      final stats = await getPlayerStats(uid);
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timestamp = now.millisecondsSinceEpoch;

      // Update win/loss/streaks
      int newWinStreak = stats.currentWinStreak;
      int newLoseStreak = stats.currentLoseStreak;
      int newWins = stats.wins;
      int newLosses = stats.losses;

      if (isWin) {
        newWins++;
        newWinStreak++;
        newLoseStreak = 0;
      } else {
        newLosses++;
        newLoseStreak++;
        newWinStreak = 0;
      }

      // Update best streaks
      int newBestWinStreak = stats.bestWinStreak;
      int newBestLoseStreak = stats.bestLoseStreak;
      if (newWinStreak > newBestWinStreak) newBestWinStreak = newWinStreak;
      if (newLoseStreak > newBestLoseStreak) newBestLoseStreak = newLoseStreak;

      // Update ELO history
      final newEloHistory = Map<int, int>.from(stats.eloHistory);
      newEloHistory[timestamp] = newElo;

      // Update games per day
      final newGamesPerDay = Map<String, int>.from(stats.gamesPerDay);
      newGamesPerDay[today] = (newGamesPerDay[today] ?? 0) + 1;

      // Update avg response time per day
      final avgResponseTimes =
          solves.map((s) => s.responseTime.toDouble()).toList();
      final todayAvgResponse = avgResponseTimes.isEmpty
          ? 0.0
          : avgResponseTimes.reduce((a, b) => a + b) / avgResponseTimes.length;

      final newAvgResponseTimePerDay =
          Map<String, double>.from(stats.avgResponseTimePerDay);
      newAvgResponseTimePerDay[today] = todayAvgResponse;

      // Update puzzle type stats
      final basicSolves = solves.where((s) => s.puzzleType == 'basic').toList();
      final complexSolves =
          solves.where((s) => s.puzzleType == 'complex').toList();
      final game24Solves =
          solves.where((s) => s.puzzleType == 'game24').toList();
      final mathadoresolves =
          solves.where((s) => s.puzzleType == 'mathadore').toList();

      final newBasicStats =
          _updatePuzzleTypeStats(stats.basicStats, basicSolves);
      final newComplexStats =
          _updatePuzzleTypeStats(stats.complexStats, complexSolves);
      final newGame24Stats =
          _updatePuzzleTypeStats(stats.game24Stats, game24Solves);
      final newMathadoreStats =
          _updatePuzzleTypeStats(stats.mathadoreStats, mathadoresolves);

      // Update records
      final allSolveTimes = solves.map((s) => s.responseTime).toList();
      int newFastestSolve = stats.fastestSolve;
      int newSlowestSolve = stats.slowestSolve;

      if (allSolveTimes.isNotEmpty) {
        final minTime = allSolveTimes.reduce((a, b) => a < b ? a : b);
        final maxTime = allSolveTimes.reduce((a, b) => a > b ? a : b);

        if (newFastestSolve == 0 || minTime < newFastestSolve) {
          newFastestSolve = minTime;
        }
        if (maxTime > newSlowestSolve) {
          newSlowestSolve = maxTime;
        }
      }

      int newShortestMatch = stats.shortestMatch;
      int newLongestMatch = stats.longestMatch;

      if (newShortestMatch == 0 || matchDuration < newShortestMatch) {
        newShortestMatch = matchDuration;
      }
      if (matchDuration > newLongestMatch) {
        newLongestMatch = matchDuration;
      }

      // Create updated stats
      final updatedStats = PlayerStats(
        totalGames: stats.totalGames + 1,
        wins: newWins,
        losses: newLosses,
        draws: stats.draws,
        currentWinStreak: newWinStreak,
        currentLoseStreak: newLoseStreak,
        bestWinStreak: newBestWinStreak,
        bestLoseStreak: newBestLoseStreak,
        eloHistory: newEloHistory,
        basicStats: newBasicStats,
        complexStats: newComplexStats,
        game24Stats: newGame24Stats,
        mathadoreStats: newMathadoreStats,
        gamesPerDay: newGamesPerDay,
        avgResponseTimePerDay: newAvgResponseTimePerDay,
        fastestSolve: newFastestSolve,
        slowestSolve: newSlowestSolve,
        longestMatch: newLongestMatch,
        shortestMatch: newShortestMatch,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(uid).update({
        'stats': updatedStats.toMap(),
        'gamesPlayed': updatedStats.totalGames,
      });
    } catch (e) {
      print('Error updating stats: $e');
    }
  }

  /// Helper pour mettre à jour les stats d'un type de puzzle
  PuzzleTypeStats _updatePuzzleTypeStats(
    PuzzleTypeStats current,
    List<PuzzleSolveData> solves,
  ) {
    if (solves.isEmpty) return current;

    final correct = solves.where((s) => s.isCorrect).length;
    final wrong = solves.where((s) => !s.isCorrect).length;

    final newTotalAttempts = current.totalAttempts + solves.length;
    final newCorrect = current.correctAnswers + correct;
    final newWrong = current.wrongAnswers + wrong;

    // Calculate new average response time
    final solveTimes = solves.map((s) => s.responseTime.toDouble()).toList();
    final currentTotal = current.avgResponseTime * current.totalAttempts;
    final newTotal = currentTotal + solveTimes.reduce((a, b) => a + b);
    final newAvgResponseTime = newTotal / newTotalAttempts;

    // Update fastest/slowest
    final minTime = solveTimes.reduce((a, b) => a < b ? a : b).toInt();
    final maxTime = solveTimes.reduce((a, b) => a > b ? a : b).toInt();

    int newFastest = current.fastestSolve;
    if (newFastest == 0 || minTime < newFastest) {
      newFastest = minTime;
    }

    int newSlowest = current.slowestSolve;
    if (maxTime > newSlowest) {
      newSlowest = maxTime;
    }

    return PuzzleTypeStats(
      totalAttempts: newTotalAttempts,
      correctAnswers: newCorrect,
      wrongAnswers: newWrong,
      avgResponseTime: newAvgResponseTime,
      fastestSolve: newFastest,
      slowestSolve: newSlowest,
    );
  }

  /// Marque le placement/calibration comme terminé et définit l'ELO initial
  Future<void> markPlacementComplete(String uid, int initialElo) async {
    try {
      final stats = await getPlayerStats(uid);
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      final updatedStats = stats.copyWith(
        isPlacementComplete: true,
        eloHistory: {
          ...stats.eloHistory,
          timestamp: initialElo,
        },
      );

      await _firestore.collection('users').doc(uid).set({
        // Champs utilisés par ProfilePage (source de vérité UI)
        'elo': initialElo,
        'stats': updatedStats.toMap(),
      }, SetOptions(merge: true));

      print('✅ Placement complete marked for user $uid with initial ELO $initialElo');
    } catch (e) {
      print('❌ Error marking placement complete: $e');
      rethrow;
    }
  }
}

/// Données d'une résolution de puzzle
class PuzzleSolveData {
  final String puzzleType; // 'basic', 'complex', 'game24', 'mathadore'
  final bool isCorrect;
  final int responseTime; // en ms

  const PuzzleSolveData({
    required this.puzzleType,
    required this.isCorrect,
    required this.responseTime,
  });
}
