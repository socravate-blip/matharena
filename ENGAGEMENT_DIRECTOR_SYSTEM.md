# 🎯 ENGAGEMENT DIRECTOR & SYSTÈME DE CALIBRATION

## Vue d'ensemble

Ce système implémente deux mécanismes clés pour améliorer la rétention et l'expérience utilisateur :

1. **Engagement Director** : Sélection intelligente de bot basée sur l'historique récent
2. **Système de Calibration** : Onboarding obligatoire pour déterminer l'ELO de départ

---

## 🎮 Partie 1 : Engagement Director (Smart Matchmaking)

### Objectif

Maximiser la rétention en adaptant la difficulté du bot selon l'état psychologique du joueur, évitant ainsi la frustration et l'ennui.

### Règles de Sélection

#### 1. Lose Streak Protection (>= 2 défaites)
- **90% chance** de bot **Underdog** (facile)
- **10% chance** de bot **Competitive** (égal)
- **Objectif** : "Pity Win" - Redonner confiance au joueur

#### 2. Win Streak Challenge (>= 3 victoires)
- **80% chance** de bot **Boss** (difficile)
- **20% chance** de bot **Competitive** (égal)
- **Objectif** : Maintenir l'engagement avec un défi

#### 3. Cas Standard (pas de streak)
- **50%** : Competitive (Match serré)
- **25%** : Underdog (Joueur se sent fort)
- **25%** : Boss (Challenge)
- **Objectif** : Roue de la fortune pondérée équilibrée

### Fichiers Créés

#### `lib/features/game/domain/logic/smart_matchmaking_logic.dart`

Classe principale qui implémente l'Engagement Director :

```dart
class SmartMatchmakingLogic {
  /// Sélectionne la difficulté du bot basé sur l'historique
  BotDifficulty selectBotDifficulty({
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  });

  /// Crée un bot avec la difficulté sélectionnée
  BotAI createBotOpponent({
    required int playerElo,
    required PlayerStats stats,
    bool isFirstRankedMatch = false,
  });

  /// Détermine si le joueur devrait jouer contre un bot
  bool shouldMatchWithBot({
    required PlayerStats stats,
    required bool isFirstRankedMatch,
    required int queueTimeSeconds,
    required bool realPlayersAvailable,
  });
}
```

**Différence avec AdaptiveMatchmaking** :
- AdaptiveMatchmaking : Logique originale, plus progressive
- SmartMatchmakingLogic : Nouvelle logique "Engagement Director" avec règles strictes (90%/80%)

### Intégration

Le système fonctionne avec `GhostMatchOrchestrator` qui accepte maintenant les deux types de matchmaking :

```dart
// Option 1 : Avec AdaptiveMatchmaking (existant)
final orchestrator = GhostMatchOrchestrator(
  AdaptiveMatchmaking(),
  PuzzleGenerator(),
);

// Option 2 : Avec SmartMatchmakingLogic (nouveau)
final orchestrator = GhostMatchOrchestrator(
  SmartMatchmakingLogic(),
  PuzzleGenerator(),
);
```

### Logs Console

Le système affiche des logs détaillés pour le debugging :

```
🛡️ Engagement Director: LOSE STREAK DETECTED (2)
   → Forcing Underdog bot (90% chance)

🔥 Engagement Director: WIN STREAK DETECTED (4)
   → Forcing Boss bot (80% chance)

⚖️ Engagement Director: STANDARD CASE
   → Rolled Competitive (50%)
```

---

## 🎓 Partie 2 : Système de Calibration

### Objectif

Déterminer l'ELO de départ du joueur via 3 épreuves obligatoires, plutôt que d'attribuer un ELO par défaut arbitraire.

### Flow Utilisateur

```
1. Premier lancement de l'app
   ↓
2. Vérification: isPlacementComplete ?
   ↓ Non
3. PlacementIntroPage (Explication + Saisie pseudo)
   ↓
4. Match 1: Arithmétique Simple (Basic)
   ↓
5. Match 2: Équations Complexes (Complex)
   ↓
6. Match 3: Jeu de 24 (Game24)
   ↓
7. Calcul de l'ELO Initial
   ↓
8. PlacementCompletePage (Résultats)
   ↓
9. GameHomePage (Mode Ranked débloqué)
```

### Les 3 Épreuves

#### Match 1 : Arithmétique Simple
- **Type** : `PuzzleType.basic`
- **Objectif** : Tester la vitesse de calcul de base
- **Puzzles** : +, -, ×
- **Nombre** : 10 puzzles

#### Match 2 : Équations Complexes
- **Type** : `PuzzleType.complex`
- **Objectif** : Tester la logique avancée
- **Puzzles** : Parenthèses, négatifs, opérations multiples
- **Nombre** : 10 puzzles

#### Match 3 : Jeu de 24
- **Type** : `PuzzleType.game24`
- **Objectif** : Tester la flexibilité mentale
- **Puzzles** : Faire 24 avec 4 nombres
- **Nombre** : 10 puzzles

### Calcul de l'ELO Initial

**Formule** :
```
InitialELO = Base(1000) + (ScoreMoyen × 4) + BonusVitesse
```

**Composants** :
- **Base** : 1000 ELO (Bronze)
- **ScoreMoyen** : Moyenne des précisions (0-100%)
- **Multiplicateur** : 4 points d'ELO par % de précision
- **BonusVitesse** :
  - < 2s : +200 ELO (Très rapide)
  - < 4s : +100 ELO (Rapide)
  - < 6s : +50 ELO (Moyen)
  - > 6s : +0 ELO (Lent)

**Bornes** : 800-1500 ELO (Bronze à Gold max)

**Exemple** :
```
Précision moyenne : 75%
Temps moyen : 3500ms

ELO = 1000 + (75 × 4) + 100
    = 1000 + 300 + 100
    = 1400 (Silver)
```

### Fichiers Créés

#### 1. Service

**`lib/features/game/domain/services/placement_service.dart`**

Service de gestion des 3 matchs de calibration :

```dart
class PlacementService {
  /// Retourne le type de puzzle pour chaque match
  static PuzzleType getPuzzleTypeForMatch(int matchNumber);

  /// Génère les puzzles pour un match spécifique
  static List<GamePuzzle> generateCalibrationPuzzles(int matchNumber);

  /// Calcule l'ELO initial basé sur les 3 performances
  static int calculateInitialElo(List<GamePerformance> performances);

  /// Génère un bot étalon (1200 ELO fixe)
  static Map<String, dynamic> createCalibrationBot();

  /// Retourne un résumé pour le joueur
  static String getCalibrationSummary(...);

  /// Recommandations d'entraînement
  static String getPracticeRecommendations(...);
}
```

#### 2. Modèles

**`GamePerformance`** (dans placement_service.dart) :

```dart
class GamePerformance {
  final int matchNumber;           // 1, 2, ou 3
  final PuzzleType puzzleType;     // basic, complex, game24
  final int correctAnswers;        // Nombre de bonnes réponses
  final int totalPuzzles;          // Total de puzzles
  final int totalTimeMs;           // Temps total du match
  final List<int> responseTimes;   // Temps de chaque puzzle

  double get accuracy;             // Précision (%)
  double get averageResponseTime;  // Temps moyen (ms)
}
```

#### 3. Pages UI

**`lib/features/game/presentation/pages/placement_intro_page.dart`**

Page d'introduction avec :
- Explication du système
- Description des 3 épreuves
- Saisie du pseudo
- Bouton "Commencer la calibration"

**`lib/features/game/presentation/pages/placement_match_page.dart`**

Page de jeu pour chaque match de calibration :
- Affichage du puzzle selon le type
- Clavier numérique
- Feedback immédiat (✓/✗)
- Progression automatique
- Tracking des performances

**`lib/features/game/presentation/pages/placement_complete_page.dart`**

Page de résultats finaux :
- ELO initial calculé
- Ligue assignée (Bronze/Silver/Gold)
- Stats globales (précision, temps moyen)
- Détails des 3 matchs
- Recommandations d'entraînement
- Bouton "Commencer à jouer"

#### 4. Routage

**`lib/features/game/presentation/pages/app_startup_page.dart`**

Wrapper qui vérifie si le placement est nécessaire :

```dart
class AppStartupPage extends StatefulWidget {
  // Vérifie isPlacementComplete dans PlayerStats
  // Si false → PlacementIntroPage
  // Si true → GameHomePage
}
```

### Modifications des Fichiers Existants

#### `lib/features/game/domain/models/player_stats.dart`

Ajout du champ :
```dart
final bool isPlacementComplete; // Défaut: false
```

#### `lib/features/game/domain/services/stats_service.dart`

Nouvelle méthode :
```dart
Future<void> markPlacementComplete(String uid, int initialElo) async {
  // Marque le placement comme terminé
  // Sauvegarde l'ELO initial dans l'historique
}
```

#### `lib/main.dart`

Changement de la page d'accueil :
```dart
home: const AppStartupPage(), // Au lieu de GameHomePage
```

---

## 🔧 Utilisation Technique

### Pour Activer le Smart Matchmaking

Remplacer dans `ranked_multiplayer_page.dart` (ligne ~120) :

```dart
// AVANT (AdaptiveMatchmaking)
final matchmaking = ref.read(adaptiveMatchmakingProvider);

// APRÈS (SmartMatchmakingLogic)
final matchmaking = SmartMatchmakingLogic();
```

### Pour Tester la Calibration

1. **Reset le statut de placement** :

Dans Firebase Console → Users → [votre UID] → stats :
```json
{
  "isPlacementComplete": false
}
```

2. **Relancer l'app** → Vous serez redirigé vers PlacementIntroPage

### Pour Débugger

**Logs de l'Engagement Director** :
```dart
print('🛡️ Engagement Director: LOSE STREAK DETECTED (2)');
print('🔥 Engagement Director: WIN STREAK DETECTED (4)');
print('⚖️ Engagement Director: STANDARD CASE');
```

**Logs de la Calibration** :
```dart
print('📝 Generating calibration puzzles for Match 1');
print('📊 Calculating Initial ELO from placement matches:');
print('   Base ELO: 1000');
print('   Average Accuracy: 75.0%');
print('   Accuracy Bonus: +300 ELO');
print('   Speed Bonus: +100 ELO');
print('   → Initial ELO: 1400');
```

---

## 🎯 Points Clés

### Engagement Director

✅ **Transparent** : Le joueur ne voit pas qu'il y a un algorithme derrière  
✅ **Psychologique** : Adapté aux streaks pour éviter frustration/ennui  
✅ **Configurable** : Facile de changer les % (90%, 80%, 50/25/25)  
✅ **Compatible** : Fonctionne avec le système Ghost Protocol existant  

### Calibration

✅ **Obligatoire** : Premier lancement → Placement  
✅ **Rapide** : 3 matchs de 10 puzzles = ~5-10 minutes  
✅ **Précis** : Mesure vitesse ET précision  
✅ **Équitable** : Bot étalon fixe (1200 ELO)  
✅ **Progressif** : Puzzles deviennent plus complexes (Basic → Complex → Game24)  

---

## 📊 Structure des Fichiers Créés

```
lib/features/game/
├── domain/
│   ├── logic/
│   │   └── smart_matchmaking_logic.dart           ✨ NOUVEAU
│   └── services/
│       ├── placement_service.dart                 ✨ NOUVEAU
│       ├── stats_service.dart                     🔧 MODIFIÉ
│       └── ghost_match_orchestrator.dart          🔧 MODIFIÉ
├── domain/models/
│   └── player_stats.dart                          🔧 MODIFIÉ
└── presentation/pages/
    ├── app_startup_page.dart                      ✨ NOUVEAU
    ├── placement_intro_page.dart                  ✨ NOUVEAU
    ├── placement_match_page.dart                  ✨ NOUVEAU
    └── placement_complete_page.dart               ✨ NOUVEAU

lib/
└── main.dart                                      🔧 MODIFIÉ
```

**Légende** :
- ✨ NOUVEAU : Fichier créé
- 🔧 MODIFIÉ : Fichier existant modifié

---

## 🚀 Prochaines Étapes Recommandées

1. **Tester le flow complet de calibration** avec un nouvel utilisateur
2. **Ajuster les formules d'ELO** selon les résultats réels
3. **Analyser les métriques** : Combien de joueurs finissent la calibration ?
4. **A/B Testing** : Comparer Smart vs Adaptive matchmaking
5. **Ajouter des animations** : Transitions entre les matchs de placement
6. **Statistiques de rétention** : Mesurer l'impact sur le taux de rétention J1/J7/J30

---

**Système conçu pour maximiser l'engagement et fournir une expérience de démarrage équitable et mesurée !** 🎮✨
