import 'dart:math';
import 'package:flutter/material.dart';

/// Professional Elo Rating Calculator
/// Based on arXiv:2502.10985 and arXiv:2406.05869
/// Implements Standard Logistic Elo with Dynamic K-Factor
class EloCalculator {
  /// Initial rating for new players
  static const int initialRating = 1200;

  /// Calculates the expected score (win probability) for player A
  /// Formula: E_A = 1 / (1 + 10^((R_B - R_A) / 400))
  ///
  /// [ratingA] Current rating of player A
  /// [ratingB] Current rating of player B (or virtual opponent)
  /// Returns: Expected score between 0.0 and 1.0
  static double calculateExpectedScore(int ratingA, int ratingB) {
    final exponent = (ratingB - ratingA) / 400.0;
    return 1.0 / (1.0 + _pow10(exponent));
  }

  /// Determines the K-factor based on player experience and rating
  /// Uses dynamic K-factor for optimal convergence and stability
  ///
  /// [gamesPlayed] Total number of games played
  /// [currentRating] Current Elo rating
  /// Returns: K-factor value (10, 20, or 40)
  static int getKFactor(int gamesPlayed, int currentRating) {
    // Placement Phase: Fast convergence for new players
    if (gamesPlayed < 30) {
      return 40;
    }

    // Pro Phase: Stability for top-rated players
    if (currentRating > 2400) {
      return 10;
    }

    // Standard Phase: Regular K-factor
    return 20;
  }

  /// Calculates the new rating after a match
  /// Formula: R_new = R_current + K × (ActualScore - ExpectedScore)
  ///
  /// [currentRating] Player's current rating
  /// [opponentRating] Opponent's rating (or virtual opponent)
  /// [actualScore] Match result (1.0 = win, 0.5 = draw, 0.0 = loss)
  /// [gamesPlayed] Total games played by the player
  /// Returns: New rating (clamped between 100 and 3000)
  static int calculateNewRating({
    required int currentRating,
    required int opponentRating,
    required double actualScore,
    required int gamesPlayed,
  }) {
    // Get dynamic K-factor
    final kFactor = getKFactor(gamesPlayed, currentRating);

    // Calculate expected score
    final expectedScore = calculateExpectedScore(currentRating, opponentRating);

    // Calculate rating change
    final ratingChange = kFactor * (actualScore - expectedScore);

    // Apply change and clamp to valid range
    final newRating = (currentRating + ratingChange).round();
    return newRating.clamp(100, 3000);
  }

  /// Determines virtual opponent rating and actual score based on performance
  ///
  /// [playerScore] Score achieved in the match
  /// [playerRating] Player's current Elo rating
  /// Returns: Map with 'opponentRating' and 'actualScore'
  static Map<String, dynamic> calculateVirtualMatch({
    required int playerScore,
    required int playerRating,
  }) {
    // Target score based on current rating (expected performance)
    // Higher rated players are expected to score more
    final targetScore = (playerRating / 100).round();

    // Calculate performance deviation (percentage difference)
    final deviation = (playerScore - targetScore) / targetScore;

    // Determine match result and opponent rating
    int opponentRating;
    double actualScore;

    if (deviation > 0.1) {
      // Strong performance: Player "wins" against higher-rated opponent
      actualScore = 1.0;
      opponentRating = playerRating + 50;
    } else if (deviation < -0.1) {
      // Weak performance: Player "loses" against lower-rated opponent
      actualScore = 0.0;
      opponentRating = playerRating - 50;
    } else {
      // Average performance: "Draw" against similar opponent
      actualScore = 0.5;
      opponentRating = playerRating;
    }

    return {
      'opponentRating': opponentRating,
      'actualScore': actualScore,
    };
  }

  /// Gets league/rank name based on rating
  static String getLeagueName(int rating) {
    if (rating < 1200) return 'Bronze';
    if (rating < 1500) return 'Silver';
    if (rating < 1800) return 'Gold';
    return 'Diamond';
  }

  /// Gets league icon/emoji based on rating
  static String getLeagueIcon(int rating) {
    if (rating < 1200) return '🥉';
    if (rating < 1500) return '🥈';
    if (rating < 1800) return '🥇';
    return '💎';
  }

  /// Gets league color based on rating
  static Color getLeagueColor(int rating) {
    if (rating < 1200) return const Color(0xFFCD7F32); // Bronze
    if (rating < 1500) return const Color(0xFFC0C0C0); // Silver
    if (rating < 1800) return const Color(0xFFFFD700); // Gold
    return const Color(0xFFB9F2FF); // Diamond
  }

  // Helper method: Calculate 10^x efficiently
  static double _pow10(double exponent) {
    return pow(10, exponent).toDouble();
  }
}

/// Historique d'une partie pour suivre l'évolution du rating
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
      foundMathador: map['foundMathador'] ?? false,
    );
  }
}
