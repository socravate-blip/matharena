# Système de Bots Adaptatifs et Calibration - MathArena

## Vue d'ensemble

Ce système implémente une IA adaptative pour MathArena qui ajuste dynamiquement la difficulté des bots en fonction de la performance du joueur en temps réel, ainsi qu'un système de calibration pour les nouveaux joueurs.

## Architecture

### 1. BotAI Adaptatif (`bot_ai.dart`)

#### Enum BotDifficulty
```dart
enum BotDifficulty {
  underdog,     // Bot plus faible (120-150% du temps moyen du joueur)
  competitive,  // Bot égal (95-105% du temps moyen du joueur)
  boss,         // Bot plus fort (70-85% du temps moyen du joueur)
}
```

#### Méthodes clés

**`calculateDynamicDelay(GamePuzzle puzzle, {int? userAverageMs})`**
- Calcule le délai de réponse du bot basé sur la performance récente du joueur
- Utilise une distribution gaussienne pour des variations naturelles
- Le bot "Boss" simule des hésitations (15% de chance) pour paraître humain
- Respect d'un temps minimum réaliste (pas de réponse instantanée)

**`recordPlayerResponseTime(int milliseconds)`**
- Enregistre les temps de réponse du joueur
- Garde seulement les 10 dernières réponses pour adaptation en temps réel
- Permet au bot d'ajuster son comportement pendant la partie

**Exemple d'utilisation :**
```dart
final bot = BotAI.matchingSkill(
  1200, 
  difficulty: BotDifficulty.competitive
);

// Enregistrer les temps du joueur
bot.recordPlayerResponseTime(3500);  // 3.5 secondes
bot.recordPlayerResponseTime(4200);  // 4.2 secondes

// Le bot calcule son délai adaptatif
final delay = bot.calculateDynamicDelay(puzzle);
await Future.delayed(delay);
```

### 2. PlacementManager (`placement_manager.dart`)

Gère les 3 matchs de calibration pour les nouveaux joueurs.

#### Flow de calibration

1. **Match 1** : BasicPuzzle (opérations simples)
2. **Match 2** : ComplexPuzzle (équations avec nombres négatifs)
3. **Match 3** : Game24Puzzle (jeu de 24)

#### Calcul de l'ELO initial

**Formule :**
```
ELO_initial = 1000 + BonusAccuracy + BonusVitesse + BonusVictoires + BonusPuzzleDifficile
```

**Pondération :**
- Précision : 50% (±300 ELO)
- Vitesse : 30% (±200 ELO)
- Victoires : 20% (±100 ELO)
- Bonus puzzles difficiles : +50 ELO si > 70% de précision sur Game24

**Exemple :**
```dart
final results = [
  PlacementMatchResult(
    matchNumber: 1,
    puzzleType: PuzzleType.basic,
    correctAnswers: 8,
    totalQuestions: 10,
    responseTimes: [3200, 2800, 3500, ...],
    won: true,
  ),
  // ... 2 autres matchs
];

final initialElo = PlacementManager.calculateInitialElo(results);
// Résultat : 800-1600 ELO selon la performance
```

#### Recommandations post-placement

Le système peut recommander de l'entraînement supplémentaire si :
- Précision < 40%
- 0 victoires sur 3 matchs

### 3. AdaptiveMatchmaking (`adaptive_matchmaking.dart`)

Système intelligent de matchmaking qui adapte la difficulté selon l'état psychologique du joueur.

#### Logique de sélection de difficulté

| Situation | Difficulté Bot | Probabilité |
|-----------|---------------|-------------|
| LoseStreak ≥ 3 | Underdog | 100% |
| LoseStreak = 2 | Underdog / Competitive | 70% / 30% |
| WinStreak ≥ 5 | Boss / Competitive | 60% / 40% |
| WinStreak 3-4 | Competitive / Boss | 50% / 50% |
| First Ranked | Underdog / Competitive | 70% / 30% |
| Normal | Underdog / Competitive / Boss | 20% / 60% / 20% |

#### First Win Experience

Pour la toute première partie classée après placement :
- ❌ **Jamais** de bot "Boss"
- ✅ Priorité aux bots "Underdog" (70%) ou "Competitive" (30%)
- 🎯 Objectif : Expérience positive pour retenir le joueur

**Exemple :**
```dart
final matchmaking = AdaptiveMatchmaking();

final bot = matchmaking.createBotOpponent(
  playerElo: 1200,
  stats: playerStats,
  isFirstRankedMatch: true,  // Force un bot plus facile
);

// bot.difficulty sera Underdog ou Competitive, jamais Boss
```

#### Matchmaking Bot vs Joueur Réel

```dart
final shouldUseBot = matchmaking.shouldMatchWithBot(
  stats: stats,
  isFirstRankedMatch: true,      // Toujours bot
  queueTimeSeconds: 10,
  realPlayersAvailable: true,
);

// Retourne true si :
// - First ranked match
// - LoseStreak ≥ 2 (70% chance)
// - Queue > 15 secondes
// - Pas de joueurs réels disponibles
```

### 4. Providers Riverpod (`adaptive_providers.dart`)

#### PlacementNotifier

Gère l'état des matchs de placement :

```dart
// Démarrer un match de placement
final puzzleType = ref.read(placementStateProvider.notifier)
  .startNextPlacementMatch();

// Enregistrer le résultat
ref.read(placementStateProvider.notifier).recordMatchResult(result);

// Vérifier si terminé
final state = ref.watch(placementStateProvider);
if (state.isComplete) {
  print('ELO initial : ${state.calculatedElo}');
}
```

#### Bot Opponent Provider

```dart
final botRequest = BotOpponentRequest(
  playerElo: 1200,
  stats: playerStats,
  isFirstRankedMatch: false,
);

final bot = ref.watch(botOpponentProvider(botRequest));
```

## Intégration complète

### Étape 1 : Nouveau joueur - Placement

```dart
// 1. Démarrer le placement
final notifier = ref.read(placementStateProvider.notifier);

// 2. Pour chaque match (1, 2, 3)
for (int i = 1; i <= 3; i++) {
  final puzzleType = notifier.startNextPlacementMatch();
  
  // Jouer le match
  final result = await playMatch(puzzleType);
  
  // Enregistrer
  notifier.recordMatchResult(result);
}

// 3. Obtenir l'ELO initial
final state = ref.read(placementStateProvider);
final initialElo = state.calculatedElo!;
```

### Étape 2 : Première partie classée

```dart
final matchmaking = ref.read(adaptiveMatchmakingProvider);

// Créer un bot adaptatif
final bot = matchmaking.createBotOpponent(
  playerElo: initialElo,
  stats: playerStats,
  isFirstRankedMatch: true,  // Garantit une expérience positive
);

// Le bot sera Underdog ou Competitive, jamais Boss
```

### Étape 3 : Pendant la partie

```dart
// Enregistrer chaque réponse du joueur
bot.recordPlayerResponseTime(playerResponseTime);

// Le bot adapte son temps de réponse
final delay = bot.calculateDynamicDelay(puzzle);
await Future.delayed(delay);

// Le bot répond
final answer = bot.solveArithmetic(puzzle);
```

### Étape 4 : Parties suivantes

```dart
// Le système adapte automatiquement selon les streaks
final bot = matchmaking.createBotOpponent(
  playerElo: currentElo,
  stats: updatedStats,
  isFirstRankedMatch: false,
);

// Si LoseStreak ≥ 3 : bot sera Underdog (boost de confiance)
// Si WinStreak ≥ 5 : bot sera Boss (challenge)
```

## Avantages du système

### 1. Expérience psychologique optimisée

- **Lose Streak** : Bot plus facile → Regain de confiance
- **Win Streak** : Bot plus difficile → Maintien de l'engagement
- **First Win** : Expérience positive → Rétention du joueur

### 2. Adaptation en temps réel

Le bot ajuste son temps de réponse **pendant la partie** en fonction :
- De la moyenne courante du joueur
- De la difficulté du puzzle
- De variations gaussiennes (paraît humain)

### 3. Calibration précise

Le système de placement évalue :
- **Précision** : Capacité à résoudre correctement
- **Vitesse** : Rapidité de réflexion
- **Polyvalence** : Performance sur différents types de puzzles

### 4. Prédiction de victoire

```dart
final winProbability = matchmaking.predictWinProbability(
  playerElo: 1200,
  opponentElo: bot.skillLevel,
  botDifficulty: bot.difficulty,
  stats: stats,
);

// Utilise la formule ELO + ajustements pour streaks
// Utile pour analytics et balancing
```

## Configuration et personnalisation

### Ajuster les multiplicateurs de temps

Dans `bot_ai.dart`, modifier :

```dart
case BotDifficulty.underdog:
  baseMultiplier = 1.35;      // 135% du temps joueur
  variationRange = 0.15;      // ±15%
  
case BotDifficulty.competitive:
  baseMultiplier = 1.0;       // 100% du temps joueur
  variationRange = 0.05;      // ±5%
  
case BotDifficulty.boss:
  baseMultiplier = 0.775;     // 77.5% du temps joueur
  variationRange = 0.075;     // ±7.5%
```

### Ajuster la formule d'ELO initial

Dans `placement_manager.dart`, modifier les pondérations :

```dart
// Composante précision (actuellement ±300)
final accuracyBonus = ((overallAccuracy - 50) / 50) * 300;

// Composante vitesse (actuellement ±200)
final speedScore = _calculateSpeedScore(avgResponseTime);

// Composante victoires (actuellement ±100)
final winBonus = ((winRate - 50) / 50) * 100;
```

### Ajuster les probabilités de matchmaking

Dans `adaptive_matchmaking.dart` :

```dart
// First Ranked Match
return _random.nextDouble() < 0.7  // 70% Underdog, 30% Competitive
  ? BotDifficulty.underdog 
  : BotDifficulty.competitive;

// Lose Streak = 2
return _random.nextDouble() < 0.7  // Ajuster à 0.8 pour 80% Underdog
  ? BotDifficulty.underdog 
  : BotDifficulty.competitive;
```

## Tests et débogage

### Logger les décisions du système

```dart
final matchSummary = matchmaking.getMatchSummary(
  playerElo: playerElo,
  bot: bot,
  stats: stats,
  isFirstRankedMatch: isFirstRanked,
);

print('Match Setup: $matchSummary');
// Output: {
//   playerElo: 1200,
//   botName: "Alex",
//   botElo: 1180,
//   botDifficulty: "BotDifficulty.competitive",
//   isFirstRankedMatch: false,
//   playerStreak: 2,
//   predictedWinRate: 0.52,
//   matchType: "Normal",
//   timestamp: "2025-12-20T..."
// }
```

### Tester les différents scénarios

```dart
// Scénario 1 : LoseStreak
final stats1 = PlayerStats(currentLoseStreak: 3);
final bot1 = matchmaking.createBotOpponent(
  playerElo: 1200,
  stats: stats1,
  isFirstRankedMatch: false,
);
assert(bot1.difficulty == BotDifficulty.underdog);

// Scénario 2 : First Ranked
final bot2 = matchmaking.createBotOpponent(
  playerElo: 1200,
  stats: PlayerStats(),
  isFirstRankedMatch: true,
);
assert(bot2.difficulty != BotDifficulty.boss);
```

## Prochaines améliorations possibles

1. **Machine Learning** : Utiliser l'historique pour prédire le niveau optimal
2. **Personnalités de bots** : Différents styles de jeu (agressif, défensif, etc.)
3. **Adaptation multi-parties** : Tenir compte de l'historique long terme
4. **Dynamic difficulty adjustment (DDA)** : Ajuster pendant la partie si le joueur est trop dominant/dominé
5. **A/B Testing** : Tester différentes formules de matchmaking

## Questions fréquentes

**Q: Le bot peut-il devenir trop facile ou trop difficile ?**  
R: Le système utilise des clamps pour éviter les extrêmes. Un bot Underdog ne sera jamais plus de 50% plus lent, et un Boss jamais plus de 30% plus rapide.

**Q: Comment gérer un joueur qui fait exprès de perdre pour avoir des bots faciles ?**  
R: Le système d'ELO continuera à baisser, donc il affrontera des bots de son niveau réel. On peut ajouter une détection de sandbagging si nécessaire.

**Q: Que se passe-t-il si un joueur quitte pendant le placement ?**  
R: Utilisez `placementStateProvider.notifier.reset()` pour réinitialiser. Vous pouvez aussi sauvegarder l'état intermédiaire dans Firebase.

**Q: Le bot peut-il tricher en voyant la réponse du joueur ?**  
R: Non, le bot calcule son délai **avant** que le joueur ne réponde, basé sur les temps précédents seulement.

## Conclusion

Ce système offre une expérience de jeu dynamique et engageante qui s'adapte au niveau et à l'état émotionnel du joueur, maximisant la rétention et la satisfaction.

Pour toute question : Consultez `adaptive_bot_integration_example.dart` pour des exemples complets d'utilisation.
