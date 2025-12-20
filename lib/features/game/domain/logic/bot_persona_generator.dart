import 'dart:math';
import '../models/player_stats.dart';

/// Génère des faux profils de joueurs pour les bots
/// Ces profils sont indiscernables de vrais joueurs (Ghost Protocol)
class BotPersonaGenerator {
  static final Random _random = Random();

  // Pool de prénoms réalistes (neutres/mixtes)
  static const List<String> _firstNames = [
    'Alex',
    'Jordan',
    'Taylor',
    'Morgan',
    'Casey',
    'Riley',
    'Sam',
    'Charlie',
    'Jamie',
    'Max',
    'Blake',
    'Quinn',
    'Avery',
    'Drew',
    'Kai',
    'Skyler',
    'Phoenix',
    'River',
    'Dakota',
    'Sage',
    'Emerson',
    'Reese',
    'Rowan',
    'Hayden',
    'Parker',
    'Finley',
    'Eden',
    'Bailey',
    'Jules',
    'Remi',
    'Logan',
    'Cameron',
    'Peyton',
    'Kendall',
    'Frankie',
    'Ari',
    'Scout',
    'Micah',
    'Stevie',
    'Devon',
  ];

  // Suffixes optionnels pour plus de variété
  static const List<String> _suffixes = [
    '', '', '', '', '', // Pas de suffixe dans la majorité des cas
    '123', '42', '007', '99', '_pro',
    'GG', 'YT', 'TTV', 'Live', 'Gaming',
  ];

  /// Génère un faux profil complet pour un bot
  ///
  /// [playerElo] : L'ELO du vrai joueur pour générer un ELO crédible
  /// [difficulty] : Influence l'ELO affiché du bot
  static BotPersona generate({
    required int playerElo,
    String difficulty = 'competitive',
  }) {
    // Génération du nom
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final suffix = _suffixes[_random.nextInt(_suffixes.length)];
    final displayName = '$firstName$suffix';

    // Génération de l'ELO crédible (±50 à ±150 points du joueur)
    int eloVariation;
    switch (difficulty) {
      case 'underdog':
        // Bot affiché comme légèrement moins fort
        eloVariation = -150 + _random.nextInt(100); // -150 à -50
        break;
      case 'boss':
        // Bot affiché comme légèrement plus fort
        eloVariation = 50 + _random.nextInt(100); // +50 à +150
        break;
      default: // competitive
        // Bot affiché comme niveau équivalent
        eloVariation = -75 + _random.nextInt(150); // -75 à +75
    }
    final displayedElo = (playerElo + eloVariation).clamp(800, 2000);

    // Génération de stats crédibles basées sur l'ELO
    final gamesPlayed = 10 + _random.nextInt(500); // 10-509 matchs

    // Win rate basé sur l'ELO (plus l'ELO est haut, plus le win rate est bon)
    final expectedWinRate =
        0.35 + ((displayedElo - 800) / 1200) * 0.30; // 35-65%
    final winRateVariation = (_random.nextDouble() - 0.5) * 0.1; // ±5%
    final actualWinRate =
        (expectedWinRate + winRateVariation).clamp(0.25, 0.75);

    final wins = (gamesPlayed * actualWinRate).round();
    final losses =
        gamesPlayed - wins - (gamesPlayed * 0.05).round(); // ~5% draws
    final draws = gamesPlayed - wins - losses;

    // Peak rating légèrement supérieur au current (réaliste)
    final peakRating = displayedElo + 50 + _random.nextInt(150); // +50 à +200

    // Génération d'un faux user ID (Firebase-like)
    final fakeUserId = _generateFakeUserId();

    // Avatar ID (couleur ou index)
    final avatarId = _random.nextInt(20); // 0-19 pour 20 avatars possibles

    return BotPersona(
      userId: fakeUserId,
      displayName: displayName,
      currentRating: displayedElo,
      peakRating: peakRating,
      gamesPlayed: gamesPlayed,
      wins: wins,
      losses: losses,
      draws: draws,
      avatarId: avatarId,
      isBot: true, // Flag interne (jamais exposé à l'UI)
    );
  }

  /// Génère un faux user ID au format Firebase
  static String _generateFakeUserId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(28, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  /// Calcule l'ELO moyen historique du joueur à partir de ses stats
  /// Utilisé pour que le bot prédise un temps de réponse réaliste
  static double calculatePlayerAverageResponseTime(PlayerStats? stats) {
    if (stats == null) return 3.0; // Défaut: 3 secondes

    // On utilise le ratio de précision comme proxy du temps
    // Plus le joueur est précis, plus il prend son temps (généralement)
    final accuracy = stats.totalGames > 0 ? stats.wins / stats.totalGames : 0.5;

    // Modèle simple: Haute précision = temps plus long
    // Précision 30% -> 2s, 50% -> 3s, 70% -> 4s
    return 1.5 + (accuracy * 4.0);
  }
}

/// Représente un faux profil de joueur (Bot)
/// Cette classe est structurellement identique à un vrai profil joueur
class BotPersona {
  final String userId;
  final String displayName;
  final int currentRating;
  final int peakRating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int avatarId;
  final bool isBot; // Flag interne uniquement

  BotPersona({
    required this.userId,
    required this.displayName,
    required this.currentRating,
    required this.peakRating,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.avatarId,
    this.isBot = true,
  });

  /// Convertit le BotPersona en PlayerStats (pour intégration transparente)
  PlayerStats toPlayerStats() {
    return PlayerStats(
      totalGames: gamesPlayed,
      wins: wins,
      losses: losses,
      draws: draws,
      currentWinStreak: 0,
      currentLoseStreak: 0,
    );
  }

  /// Crée un Map pour Firestore-like (simulation)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'currentRating': currentRating,
      'peakRating': peakRating,
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'avatarId': avatarId,
      // isBot est JAMAIS envoyé (Ghost Protocol)
    };
  }

  double get winRate {
    if (gamesPlayed == 0) return 0.0;
    return wins / gamesPlayed;
  }
}
