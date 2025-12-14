import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/elo_calculator.dart';

/// Stockage et gestion du profil de rating du joueur
class PlayerRatingProfile {
  int currentRating;
  int peakRating;
  int gamesPlayed;
  int wins;
  int losses;
  int draws;
  int mathadorsFound;
  List<RatingHistory> history;

  PlayerRatingProfile({
    this.currentRating = 1200,
    this.peakRating = 1200,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.mathadorsFound = 0,
    List<RatingHistory>? history,
  }) : history = history ?? [];

  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0.0;
  String get league => EloCalculator.getLeagueName(currentRating);
  String get leagueIcon => EloCalculator.getLeagueIcon(currentRating);

  Map<String, dynamic> toMap() {
    return {
      'currentRating': currentRating,
      'peakRating': peakRating,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'mathadorsFound': mathadorsFound,
      'history': history.map((h) => h.toMap()).toList(),
    };
  }

  factory PlayerRatingProfile.fromMap(Map<String, dynamic> map) {
    return PlayerRatingProfile(
      currentRating: map['currentRating'] ?? 1200,
      peakRating: map['peakRating'] ?? 1200,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      mathadorsFound: map['mathadorsFound'] ?? 0,
      history: (map['history'] as List?)
              ?.map((h) => RatingHistory.fromMap(h))
              .toList() ??
          [],
    );
  }
}

/// Service de gestion du rating Elo
class RatingStorage {
  static const String _profileKey = 'matharena_rating_profile';
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  /// Récupère le profil du joueur
  Future<PlayerRatingProfile> getProfile() async {
    await init();
    final jsonString = _prefs!.getString(_profileKey);
    if (jsonString == null) {
      return PlayerRatingProfile();
    }
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return PlayerRatingProfile.fromMap(map);
  }

  /// Sauvegarde le profil
  Future<void> saveProfile(PlayerRatingProfile profile) async {
    await init();
    final jsonString = jsonEncode(profile.toMap());
    await _prefs!.setString(_profileKey, jsonString);
  }

  /// Met à jour le rating après une partie avec le système Virtual Opponent
  Future<PlayerRatingProfile> updateRatingAfterGame({
    required int playerScore,
    required bool foundMathador,
  }) async {
    final profile = await getProfile();

    // Étape 1: Calculer le match virtuel basé sur la performance
    final virtualMatch = EloCalculator.calculateVirtualMatch(
      playerScore: playerScore,
      playerRating: profile.currentRating,
    );

    final opponentRating = virtualMatch['opponentRating'] as int;
    final actualScore = virtualMatch['actualScore'] as double;

    // Étape 2: Calculer le nouveau rating avec la formule Elo standard
    final newRating = EloCalculator.calculateNewRating(
      currentRating: profile.currentRating,
      opponentRating: opponentRating,
      actualScore: actualScore,
      gamesPlayed: profile.gamesPlayed,
    );

    final ratingChange = newRating - profile.currentRating;

    // Étape 3: Mise à jour du profil
    profile.currentRating = newRating;
    profile.peakRating = max(profile.peakRating, newRating);
    profile.gamesPlayed++;

    // Victoire, défaite ou match nul basé sur actualScore
    if (actualScore == 1.0) {
      profile.wins++;
    } else if (actualScore == 0.0) {
      profile.losses++;
    } else {
      profile.draws++;
    }

    if (foundMathador) {
      profile.mathadorsFound++;
    }

    // Ajout à l'historique
    profile.history.add(RatingHistory(
      date: DateTime.now(),
      rating: newRating,
      ratingChange: ratingChange,
      gameScore: playerScore,
      foundMathador: foundMathador,
    ));

    // Limite l'historique à 100 entrées
    if (profile.history.length > 100) {
      profile.history.removeAt(0);
    }

    await saveProfile(profile);
    return profile;
  }

  /// Réinitialise le profil
  Future<void> resetProfile() async {
    await init();
    await _prefs!.remove(_profileKey);
  }
}

final ratingStorageProvider = Provider<RatingStorage>((ref) {
  return RatingStorage();
});

final playerRatingProvider = FutureProvider<PlayerRatingProfile>((ref) async {
  final storage = ref.watch(ratingStorageProvider);
  return await storage.getProfile();
});
