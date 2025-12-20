import 'dart:math';
import '../models/puzzle.dart';

/// Bot difficulty levels for adaptive AI
enum BotDifficulty {
  /// Weaker bot - designed to let player win (140-180% of player avg time)
  /// Plus LENT que le joueur - donne confiance au joueur
  underdog,

  /// Equal skill bot - creates tension (95-105% of player avg time)
  /// Égal au joueur - crée de la tension
  competitive,

  /// Stronger bot - challenging but realistic (50-65% of player avg time)
  /// Plus RAPIDE que le joueur - défie le joueur
  boss,
}

/// Realistic bot AI that simulates human-like puzzle solving with adaptive difficulty
class BotAI {
  final String name;
  final int skillLevel; // 800-2000 ELO
  final BotDifficulty difficulty;
  final Random _random = Random();

  // Track player performance for adaptive behavior
  final List<int> _playerResponseTimes = [];

  BotAI({
    required this.name,
    required this.skillLevel,
    this.difficulty = BotDifficulty.competitive,
  });

  /// Factory to create a bot with specific difficulty and skill matching player
  factory BotAI.matchingSkill(
    int playerElo, {
    BotDifficulty difficulty = BotDifficulty.competitive,
  }) {
    // The matchmaking layer already computes the bot's target ELO.
    // Keep it stable here to avoid double-randomizing skill.
    final botElo = playerElo.clamp(800, 2000);

    final botNames = [
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
    ];

    return BotAI(
      name: botNames[Random().nextInt(botNames.length)],
      skillLevel: botElo,
      difficulty: difficulty,
    );
  }

  /// Calculate realistic solve time based on puzzle difficulty and bot skill
  Duration calculateSolveTime(GamePuzzle puzzle) {
    // Base time increases with puzzle complexity
    int baseTimeMs;

    switch (puzzle.type) {
      case PuzzleType.basic:
        baseTimeMs = 2000; // 2 seconds
        break;
      case PuzzleType.complex:
        baseTimeMs = 4000; // 4 seconds
        break;
      case PuzzleType.game24:
        baseTimeMs = 15000; // 15 seconds (increased from 8)
        break;
      case PuzzleType.matador:
        baseTimeMs = 25000; // 25 seconds (increased from 15)
        break;
    }

    // Skill modifier: higher skill = faster (0.6x to 2.5x)
    // ELO 800 = 2.5x slower, ELO 2000 = 0.6x faster
    final skillMultiplier = 3.1 - (skillLevel / 800);

    // Add random variation ±40%
    final randomVariation = 0.6 + (_random.nextDouble() * 0.8);

    final totalMs = (baseTimeMs * skillMultiplier * randomVariation).toInt();

    return Duration(milliseconds: totalMs);
  }

  /// Record player response time for adaptive behavior
  void recordPlayerResponseTime(int milliseconds) {
    _playerResponseTimes.add(milliseconds);
    // Keep only last 10 responses for recent performance
    if (_playerResponseTimes.length > 10) {
      _playerResponseTimes.removeAt(0);
    }
  }

  /// Calculate player's average response time
  int _getPlayerAverageResponseTime() {
    if (_playerResponseTimes.isEmpty) {
      // Default starting value for new matches
      return 5000; // 5 seconds default
    }

    final sum = _playerResponseTimes.reduce((a, b) => a + b);
    return (sum / _playerResponseTimes.length).round();
  }

  /// Calculate dynamic delay based on player performance and bot difficulty
  /// This is the CORE of the adaptive AI system with REALISTIC TIME CAPS
  ///
  /// NOUVEAU: Temps maximums ABSOLUS réalistes par type et difficulté
  /// Le bot suit le joueur (140-180%, 95-105%, 50-65%) MAIS avec des caps stricts
  Duration calculateDynamicDelay(GamePuzzle puzzle,
      {int? playerHistoricalAvgMs}) {
    // 1. CAPS ABSOLUS RÉALISTES par type de puzzle ET difficulté
    int maxAbsoluteTimeMs;
    int minAbsoluteTimeMs;

    switch (puzzle.type) {
      case PuzzleType.basic:
        // Basic Math: caps très stricts (2-4s pour Underdog, 1-2s pour Boss)
        switch (difficulty) {
          case BotDifficulty.underdog:
            minAbsoluteTimeMs = 2000; // 2s
            maxAbsoluteTimeMs = 4000; // 4s (3s ± 1s)
            break;
          case BotDifficulty.competitive:
            minAbsoluteTimeMs = 1500; // 1.5s
            maxAbsoluteTimeMs = 3000; // 3s
            break;
          case BotDifficulty.boss:
            minAbsoluteTimeMs = 1000; // 1s
            maxAbsoluteTimeMs = 2000; // 2s
            break;
        }
        break;

      case PuzzleType.complex:
        // Advanced Math: plus difficile (4-7s pour Underdog, 2-4s pour Boss)
        switch (difficulty) {
          case BotDifficulty.underdog:
            minAbsoluteTimeMs = 4000; // 4s
            maxAbsoluteTimeMs = 7000; // 7s
            break;
          case BotDifficulty.competitive:
            minAbsoluteTimeMs = 3000; // 3s
            maxAbsoluteTimeMs = 5000; // 5s
            break;
          case BotDifficulty.boss:
            minAbsoluteTimeMs = 2000; // 2s
            maxAbsoluteTimeMs = 4000; // 4s
            break;
        }
        break;

      case PuzzleType.game24:
        // Jeu de 24: plus de temps (8-15s pour Underdog, 5-10s pour Boss)
        switch (difficulty) {
          case BotDifficulty.underdog:
            minAbsoluteTimeMs = 8000; // 8s
            maxAbsoluteTimeMs = 15000; // 15s
            break;
          case BotDifficulty.competitive:
            minAbsoluteTimeMs = 6000; // 6s
            maxAbsoluteTimeMs = 12000; // 12s
            break;
          case BotDifficulty.boss:
            minAbsoluteTimeMs = 5000; // 5s
            maxAbsoluteTimeMs = 10000; // 10s
            break;
        }
        break;

      case PuzzleType.matador:
        // Matador: le plus difficile (12-20s pour Underdog, 8-15s pour Boss)
        switch (difficulty) {
          case BotDifficulty.underdog:
            minAbsoluteTimeMs = 12000; // 12s
            maxAbsoluteTimeMs = 20000; // 20s
            break;
          case BotDifficulty.competitive:
            minAbsoluteTimeMs = 10000; // 10s
            maxAbsoluteTimeMs = 17000; // 17s
            break;
          case BotDifficulty.boss:
            minAbsoluteTimeMs = 8000; // 8s
            maxAbsoluteTimeMs = 15000; // 15s
            break;
        }
        break;
    }

    // 2. Obtenir la moyenne HISTORIQUE du joueur (pas son temps actuel)
    final playerAvg = playerHistoricalAvgMs ?? _getPlayerAverageResponseTime();

    // 3. Base multiplier et variation selon la difficulté
    double baseMultiplier;
    double variationRange;

    switch (difficulty) {
      case BotDifficulty.underdog:
        // Bot est plus lent: 140-180% du temps joueur
        baseMultiplier = 1.6;
        variationRange = 0.2; // ±0.2 for (1.4 to 1.8)
        break;

      case BotDifficulty.competitive:
        // Bot égal au joueur: 95-105% du temps joueur
        baseMultiplier = 1.0;
        variationRange = 0.05; // ±0.05 for (0.95 to 1.05)
        break;

      case BotDifficulty.boss:
        // Bot plus rapide: 50-65% du temps joueur
        baseMultiplier = 0.575;
        variationRange = 0.075; // ±0.075 for (0.5 to 0.65)
        break;
    }

    // 4. Distribution Gaussienne pour variation naturelle
    final randomVariation = _gaussianRandom() * variationRange;
    final finalMultiplier = baseMultiplier + randomVariation;

    // 5. Calcul du délai brut basé sur le temps joueur avec multiplicateur
    int rawDelayMs = (playerAvg * finalMultiplier).round();

    // 6. CAPS ABSOLUS STRICTS : Le bot JAMAIS plus lent/rapide que les limites
    // Exemple: Basic Math Underdog = max 4s, même si le joueur met 10s
    final cappedDelayMs =
        rawDelayMs.clamp(minAbsoluteTimeMs, maxAbsoluteTimeMs);

    // 7. Bonus réalisme: Boss bot "hésite" parfois (10% chance)
    if (difficulty == BotDifficulty.boss && _random.nextDouble() < 0.10) {
      // Hésitation: +20-50% du temps, mais toujours dans les caps
      final hesitationMultiplier = 1.2 + (_random.nextDouble() * 0.3);
      final hesitationDelay = (cappedDelayMs * hesitationMultiplier).toInt();
      return Duration(
          milliseconds:
              hesitationDelay.clamp(minAbsoluteTimeMs, maxAbsoluteTimeMs));
    }

    return Duration(milliseconds: cappedDelayMs);
  }

  /// Returns a per-puzzle accuracy probability (0..1).
  ///
  /// Underdog makes more mistakes; Boss rarely does.
  double accuracy(GamePuzzle puzzle) {
    // Base by difficulty
    final base = switch (difficulty) {
      BotDifficulty.underdog => 0.85,
      BotDifficulty.competitive => 0.93,
      BotDifficulty.boss => 0.99,
    };

    // Penalty by puzzle complexity
    final penalty = switch (puzzle.type) {
      PuzzleType.basic => 0.00,
      PuzzleType.complex => 0.07,
      PuzzleType.game24 => 0.18,
      PuzzleType.matador => 0.25,
    };

    // Slight skill adjustment: higher ELO = slightly more accurate.
    final skillBonus = ((skillLevel - 1200) / 2000).clamp(-0.05, 0.05);

    return (base - penalty + skillBonus).clamp(0.05, 0.995);
  }

  /// Randomly determines whether the bot answers correctly.
  bool rollIsCorrect(GamePuzzle puzzle) {
    return _random.nextDouble() < accuracy(puzzle);
  }

  /// Extra time spent when the bot makes a mistake ("correction").
  int mistakePenaltyMs(GamePuzzle puzzle) {
    final (minMs, maxMs) = switch (puzzle.type) {
      PuzzleType.basic => (400, 900),
      PuzzleType.complex => (700, 1400),
      PuzzleType.game24 => (1200, 3000),
      PuzzleType.matador => (1500, 4000),
    };

    // Underdog tends to panic more, Boss corrects quicker.
    final multiplier = switch (difficulty) {
      BotDifficulty.underdog => 1.3,
      BotDifficulty.competitive => 1.0,
      BotDifficulty.boss => 0.75,
    };

    final raw = minMs + _random.nextInt(maxMs - minMs + 1);
    return (raw * multiplier).round();
  }

  /// Generate random number with Gaussian (normal) distribution
  /// Mean = 0, Standard deviation = 1
  double _gaussianRandom() {
    // Box-Muller transform
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

}
