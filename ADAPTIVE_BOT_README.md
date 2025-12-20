# 🤖 Système de Bots Adaptatifs - MathArena

> Système d'IA adaptative avec calibration pour optimiser l'engagement et la rétention des joueurs

## 📋 Vue d'ensemble

Ce système implémente une intelligence artificielle qui s'adapte en temps réel à la performance du joueur, garantissant des matchs équilibrés et engageants. Il comprend également un système de calibration en 3 matchs pour évaluer précisément le niveau des nouveaux joueurs.

## ✨ Fonctionnalités principales

### 1. **Bots Adaptatifs** 🎯
- **3 niveaux de difficulté** : Underdog, Competitive, Boss
- **Adaptation en temps réel** : Le bot ajuste son temps de réponse pendant la partie
- **Comportement humain** : Distribution gaussienne pour des variations naturelles
- **Boss intelligent** : Simule des hésitations (15% de chance) pour paraître humain

### 2. **Système de Calibration** 📊
- **3 matchs de placement** pour les nouveaux joueurs
- **Progression graduelle** : Basic → Complex → Game24
- **Calcul d'ELO initial** basé sur :
  - Précision (50%)
  - Vitesse (30%)
  - Victoires (20%)
- **ELO entre 800 et 1600**

### 3. **Matchmaking Psychologique** 🧠
- **First Win Experience** : Garantit un match facile après la calibration
- **Gestion des streaks** :
  - LoseStreak ≥ 3 → Bot Underdog (boost de confiance)
  - WinStreak ≥ 5 → Bot Boss (maintien du challenge)
- **Prédiction de victoire** pour analytics

### 4. **Architecture Clean** 🏗️
- **Domain layer** : Logique métier pure (bot_ai.dart, placement_manager.dart, adaptive_matchmaking.dart)
- **Presentation layer** : Providers Riverpod (adaptive_providers.dart)
- **Testabilité** : Tests unitaires complets

## 🚀 Installation rapide

### 1. Structure des fichiers

```
lib/features/game/
├── domain/
│   ├── logic/
│   │   ├── bot_ai.dart                    ✅ Modifié
│   │   ├── placement_manager.dart         ✅ Nouveau
│   │   ├── adaptive_matchmaking.dart      ✅ Nouveau
│   │   └── elo_rating_system.dart         (Existant)
│   └── models/
│       ├── player_stats.dart              (Existant)
│       └── puzzle.dart                    (Existant)
├── presentation/
│   └── providers/
│       ├── adaptive_providers.dart        ✅ Nouveau
│       └── game_provider.dart             (Existant)
└── examples/
    └── adaptive_bot_integration_example.dart ✅ Nouveau

test/
└── adaptive_bot_system_test.dart          ✅ Nouveau

Documentation:
├── ADAPTIVE_BOT_SYSTEM_GUIDE.md           ✅ Nouveau
├── ADAPTIVE_BOT_QUICK_START.md            ✅ Nouveau
└── ADAPTIVE_BOT_FORMULAS.md               ✅ Nouveau
```

### 2. Code minimal pour démarrer

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/game/presentation/providers/adaptive_providers.dart';

// 1. Créer un bot adaptatif
final bot = ref.read(
  botOpponentProvider(
    BotOpponentRequest(
      playerElo: 1200,
      stats: playerStats,
      isFirstRankedMatch: true,
    ),
  ),
);

// 2. Enregistrer les temps du joueur
bot.recordPlayerResponseTime(responseTimeMs);

// 3. Le bot répond avec un délai adaptatif
final delay = bot.calculateDynamicDelay(puzzle);
await Future.delayed(delay);
```

## 📈 Exemples d'utilisation

### Scénario 1 : Placement d'un nouveau joueur

```dart
// Match 1, 2, 3
for (int i = 1; i <= 3; i++) {
  final puzzleType = ref.read(placementStateProvider.notifier)
    .startNextPlacementMatch();
  
  // Jouer le match...
  
  ref.read(placementStateProvider.notifier).recordMatchResult(result);
}

// Obtenir l'ELO initial
final state = ref.read(placementStateProvider);
print('ELO initial : ${state.calculatedElo}'); // 800-1600
```

### Scénario 2 : Premier match classé

```dart
final bot = ref.read(
  botOpponentProvider(
    BotOpponentRequest(
      playerElo: initialElo,
      stats: playerStats,
      isFirstRankedMatch: true, // ⚠️ Garantit un bot facile
    ),
  ),
);

// bot.difficulty sera Underdog ou Competitive, JAMAIS Boss
```

### Scénario 3 : Joueur en LoseStreak

```dart
// Le système détecte automatiquement le LoseStreak
final stats = PlayerStats(currentLoseStreak: 4);

final bot = ref.read(
  botOpponentProvider(
    BotOpponentRequest(
      playerElo: 1200,
      stats: stats,
      isFirstRankedMatch: false,
    ),
  ),
);

// bot.difficulty sera automatiquement Underdog
```

### Scénario 4 : Adaptation en temps réel

```dart
// Pendant la partie, enregistrer chaque réponse
void onPlayerAnswer() {
  final responseTime = stopwatch.elapsedMilliseconds;
  bot.recordPlayerResponseTime(responseTime);
  
  // Le bot adapte son comportement
  final delay = bot.calculateDynamicDelay(puzzle);
  // Si le joueur accélère, le bot accélère aussi
}
```

## 🧪 Tests

Exécuter les tests :

```bash
flutter test test/adaptive_bot_system_test.dart
```

Tests couverts :
- ✅ Délais adaptatifs par difficulté
- ✅ Calcul d'ELO initial
- ✅ Sélection de difficulté selon streaks
- ✅ First Win Experience
- ✅ Adaptation en temps réel

## 📊 Métriques clés

| Métrique | Valeur attendue |
|----------|----------------|
| Win rate First Ranked | 70-80% |
| Win rate après LoseStreak ≥ 3 | 65-75% |
| Win rate vs Boss | 20-35% |
| Win rate vs Competitive | 45-55% |
| Win rate vs Underdog | 65-80% |
| Rétention J+1 | +15% vs système statique |
| Temps de calibration | 10-15 minutes |

## 🎮 Game Design

### Distribution des difficultés

| Situation | Underdog | Competitive | Boss |
|-----------|----------|-------------|------|
| First Ranked | 70% | 30% | 0% |
| LoseStreak ≥ 3 | 100% | 0% | 0% |
| LoseStreak = 2 | 70% | 30% | 0% |
| Normal | 20% | 60% | 20% |
| WinStreak 3-4 | 0% | 50% | 50% |
| WinStreak ≥ 5 | 0% | 40% | 60% |

### Temps de réponse par difficulté

- **Underdog** : 120-150% du temps joueur
- **Competitive** : 95-105% du temps joueur
- **Boss** : 70-85% du temps joueur
- **Boss Hésitation** : 130-180% (15% de chance)

## 🔧 Configuration

Ajuster les paramètres dans `bot_ai.dart` :

```dart
// Multiplicateurs de temps
case BotDifficulty.underdog:
  baseMultiplier = 1.35;     // Changer ici
  variationRange = 0.15;
```

Ajuster la formule d'ELO dans `placement_manager.dart` :

```dart
// Pondérations
final accuracyBonus = ((overallAccuracy - 50) / 50) * 300; // ±300
final speedScore = _calculateSpeedScore(avgResponseTime);  // ±200
final winBonus = ((winRate - 50) / 50) * 100;             // ±100
```

## 📚 Documentation

| Fichier | Description |
|---------|-------------|
| [ADAPTIVE_BOT_SYSTEM_GUIDE.md](ADAPTIVE_BOT_SYSTEM_GUIDE.md) | Guide complet avec architecture détaillée |
| [ADAPTIVE_BOT_QUICK_START.md](ADAPTIVE_BOT_QUICK_START.md) | Guide de démarrage rapide avec exemples |
| [ADAPTIVE_BOT_FORMULAS.md](ADAPTIVE_BOT_FORMULAS.md) | Toutes les formules mathématiques |
| [adaptive_bot_integration_example.dart](lib/features/game/examples/adaptive_bot_integration_example.dart) | Exemples d'intégration complets |

## 🎯 Avantages pour le joueur

### Expérience optimisée

1. **Nouveau joueur** :
   - Calibration rapide (3 matchs)
   - Premier match garanti "gagnant"
   - Progression pédagogique

2. **Joueur en difficulté** :
   - Bot plus facile après 3 défaites
   - Regain de confiance
   - Évite la frustration

3. **Joueur expert** :
   - Challenge progressif
   - Bots plus difficiles en win streak
   - Maintien de l'engagement

### Avantages psychologiques

- **Flow state** : Difficulté optimale selon le niveau
- **Momentum positif** : First Win Experience
- **Récupération** : Bots faciles après streaks négatifs
- **Challenge graduel** : Augmentation du challenge sur les win streaks

## 🚨 Points d'attention

### ⚠️ À faire

- [x] Enregistrer les temps de réponse du joueur
- [x] Vérifier que le placement est complet avant ranked
- [x] Sauvegarder l'état dans Firebase
- [x] Logger les décisions de matchmaking
- [x] Tester tous les scénarios de streaks

### ❌ À éviter

- ❌ Ne pas forcer manuellement la difficulté du bot
- ❌ Ne pas ignorer les temps de réponse
- ❌ Ne pas permettre ranked avant placement
- ❌ Ne pas afficher la difficulté réelle au joueur (sauf debug)

## 🔮 Évolutions futures

1. **Machine Learning** : Prédire le niveau optimal avec historique long terme
2. **Personnalités de bots** : Styles de jeu variés (agressif, défensif)
3. **Dynamic Difficulty Adjustment (DDA)** : Ajuster en plein match
4. **A/B Testing** : Tester différentes formules de matchmaking
5. **Replay system** : Analyser les parties pour améliorer l'IA

## 👥 Contribution

Pour contribuer :

1. Ajouter des tests pour toute nouvelle fonctionnalité
2. Respecter l'architecture Clean
3. Documenter les formules mathématiques
4. Tester avec de vrais joueurs

## 📄 Licence

Intégré au projet MathArena.

## 🆘 Support

Pour toute question :

1. Consultez la documentation complète
2. Vérifiez les exemples d'intégration
3. Exécutez les tests
4. Activez les logs de debug

---

**Développé avec ❤️ pour une expérience joueur optimale**

*"Un bon système d'IA ne se fait pas remarquer - il donne juste l'impression que les matchs sont toujours équilibrés."*
