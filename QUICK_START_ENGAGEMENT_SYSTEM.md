# 🚀 GUIDE DE DÉMARRAGE RAPIDE - Engagement Director & Calibration

## Configuration Minimale (5 minutes)

### Étape 1 : Vérifier les Imports

L'app est déjà configurée ! Les modifications ont été apportées à `main.dart` :

```dart
// main.dart utilise maintenant AppStartupPage
home: const AppStartupPage(),
```

### Étape 2 : Tester le Système

#### A. Premier Lancement (Nouveau Joueur)

1. **Lancer l'app** sur un appareil/simulateur propre
2. Vous verrez automatiquement **PlacementIntroPage**
3. **Entrer un pseudo** (minimum 3 caractères)
4. **Compléter les 3 matchs** de calibration
5. Voir votre **ELO initial** calculé

#### B. Tester avec un Utilisateur Existant

Pour forcer un utilisateur existant à refaire la calibration :

**Option 1 : Via Firebase Console**
```
1. Firebase Console → Firestore
2. Collection: users → [votre UID]
3. Champ: stats.isPlacementComplete
4. Changer à: false
5. Relancer l'app
```

**Option 2 : Via Code (Temporaire)**

Dans `app_startup_page.dart`, forcer temporairement :
```dart
setState(() {
  _needsPlacement = true; // Force le placement
  _isLoading = false;
});
```

---

## Activer le Smart Matchmaking (Engagement Director)

### Option 1 : Global (Recommandé)

Créer un provider dans `adaptive_providers.dart` :

```dart
/// Provider pour SmartMatchmakingLogic
final smartMatchmakingProvider = Provider<SmartMatchmakingLogic>((ref) {
  return SmartMatchmakingLogic();
});
```

Utiliser dans `ranked_multiplayer_page.dart` :

```dart
// Ligne ~120
// REMPLACER:
final matchmaking = ref.read(adaptiveMatchmakingProvider);

// PAR:
final matchmaking = SmartMatchmakingLogic();
```

### Option 2 : Local (Test Rapide)

Directement dans `ranked_multiplayer_page.dart` :

```dart
import '../../domain/logic/smart_matchmaking_logic.dart';

// Dans _handleMatchmakingTimeout():
final matchmaking = SmartMatchmakingLogic(); // Au lieu de adaptiveMatchmakingProvider
```

---

## Tester les Différentes Situations

### Scénario 1 : Lose Streak (Pity Win)

1. Perdre volontairement 2 matchs de suite
2. Au 3ème match, le bot sera **Underdog** (90% chance)
3. Vérifier les logs console :
   ```
   🛡️ Engagement Director: LOSE STREAK DETECTED (2)
      → Forcing Underdog bot (90% chance)
   ```

### Scénario 2 : Win Streak (Challenge)

1. Gagner 3 matchs de suite
2. Au 4ème match, le bot sera **Boss** (80% chance)
3. Vérifier les logs console :
   ```
   🔥 Engagement Director: WIN STREAK DETECTED (3)
      → Forcing Boss bot (80% chance)
   ```

### Scénario 3 : Cas Standard

1. Avoir un historique mixte (pas de streak)
2. Le bot sera sélectionné selon la roue de la fortune :
   - 50% Competitive
   - 25% Underdog
   - 25% Boss

---

## Débugger les Problèmes Courants

### Problème 1 : "La calibration ne se lance pas"

**Solution** :
```dart
// Vérifier dans app_startup_page.dart
print('🔍 Checking placement status');
print('   isPlacementComplete: ${stats.isPlacementComplete}');
```

Si `isPlacementComplete` est `true`, le réinitialiser dans Firebase.

### Problème 2 : "Erreur de compilation"

**Imports manquants** :

Dans `placement_match_page.dart`, ajouter :
```dart
import '../../domain/models/puzzle.dart';
import '../../domain/services/placement_service.dart';
```

### Problème 3 : "Le bot ne respecte pas la difficulté"

**Vérifier** :
```dart
// Dans ghost_match_orchestrator.dart
print('🎮 Using FORCED difficulty: ${difficulty.name}');
print('🤖 Creating bot: ELO $botElo, Difficulty: ${difficulty.name}');
```

### Problème 4 : "Game24Puzzle non défini"

Le système utilise `PuzzleType.game24` mais si Game24Puzzle n'existe pas encore, modifier dans `placement_service.dart` :

```dart
// Match 3 : Utiliser complex temporairement
case 3:
  return PuzzleType.complex; // Au lieu de game24
```

---

## Personnalisation Rapide

### Changer les Probabilités de l'Engagement Director

Dans `smart_matchmaking_logic.dart` :

```dart
// Lose Streak Protection
if (loseStreak >= 2) {
  return _random.nextDouble() < 0.90  // Changer 0.90 (90%)
      ? BotDifficulty.underdog
      : BotDifficulty.competitive;
}

// Win Streak Challenge
if (winStreak >= 3) {
  return _random.nextDouble() < 0.80  // Changer 0.80 (80%)
      ? BotDifficulty.boss
      : BotDifficulty.competitive;
}

// Roue de la Fortune
final roll = _random.nextDouble();
if (roll < 0.50) {          // 50% Competitive
  return BotDifficulty.competitive;
} else if (roll < 0.75) {   // 25% Underdog
  return BotDifficulty.underdog;
} else {                    // 25% Boss
  return BotDifficulty.boss;
}
```

### Changer la Formule d'ELO Initial

Dans `placement_service.dart` :

```dart
static int calculateInitialElo(List<GamePerformance> performances) {
  const baseElo = 1000;              // Changer la base
  final accuracyBonus = (averageAccuracy * 4).round(); // Changer le multiplicateur
  
  // Personnaliser les bonus de vitesse
  if (averageResponseTime < 2000) {
    speedBonus = 200;  // Très rapide
  } else if (averageResponseTime < 4000) {
    speedBonus = 100;  // Rapide
  }
  // ...
}
```

### Changer le Nombre de Puzzles par Match

Dans `placement_service.dart` :

```dart
static const int puzzlesPerMatch = 10; // Changer à 5, 15, 20, etc.
```

---

## Vérifier que Tout Fonctionne

### Checklist Complète

- [ ] **App démarre** sans erreur
- [ ] **Nouveau joueur** voit PlacementIntroPage
- [ ] **Saisie du pseudo** fonctionne (3+ caractères)
- [ ] **Match 1** (Basic) se charge et fonctionne
- [ ] **Feedback** (✓/✗) s'affiche après chaque réponse
- [ ] **Transition** automatique vers Match 2
- [ ] **Match 2** (Complex) fonctionne
- [ ] **Transition** automatique vers Match 3
- [ ] **Match 3** (Game24 ou Complex) fonctionne
- [ ] **PlacementCompletePage** s'affiche avec l'ELO calculé
- [ ] **"Commencer à jouer"** redirige vers GameHomePage
- [ ] **isPlacementComplete = true** dans Firebase
- [ ] **Matchs classés** utilisent le smart matchmaking
- [ ] **Lose streak** déclenche bot Underdog
- [ ] **Win streak** déclenche bot Boss
- [ ] **Logs console** affichent les décisions du système

---

## Commandes de Test Rapide

### Reset Placement pour Retester

**Firebase CLI** :
```bash
firebase firestore:update users/[UID] stats.isPlacementComplete=false
```

**Ou via Console Firebase** :
```
Firestore → users → [UID] → stats → isPlacementComplete → false
```

### Tester avec Différents Scénarios

**Script de test** (à créer dans `test/placement_test.dart`) :

```dart
void main() {
  test('Placement calculates correct ELO', () {
    final performances = [
      GamePerformance(
        matchNumber: 1,
        puzzleType: PuzzleType.basic,
        correctAnswers: 8,
        totalPuzzles: 10,
        totalTimeMs: 30000,
        responseTimes: [3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000],
      ),
      // ... match 2 et 3
    ];

    final elo = PlacementService.calculateInitialElo(performances);
    expect(elo, greaterThan(1000));
    expect(elo, lessThan(1500));
  });
}
```

---

## Performance & Optimisation

### Temps de Calibration Estimé

- **Match 1** : ~2-3 minutes (10 puzzles simples)
- **Match 2** : ~3-4 minutes (10 puzzles complexes)
- **Match 3** : ~4-5 minutes (10 Game24)
- **Total** : ~10-12 minutes

### Réduire le Temps

Option 1 : Réduire le nombre de puzzles
```dart
static const int puzzlesPerMatch = 5; // Au lieu de 10
```

Option 2 : Supprimer un match (2 au lieu de 3)
```dart
static const int totalPlacementMatches = 2;
```

---

## Support & Ressources

### Documentation Complète

Voir `ENGAGEMENT_DIRECTOR_SYSTEM.md` pour :
- Architecture détaillée
- Formules mathématiques
- Tous les fichiers créés/modifiés
- Logs de debugging

### Fichiers Clés à Connaître

```
smart_matchmaking_logic.dart    → Logique de sélection de bot
placement_service.dart          → Gestion des 3 matchs
player_stats.dart               → Champ isPlacementComplete
app_startup_page.dart           → Routage initial
placement_intro_page.dart       → UI d'introduction
placement_match_page.dart       → UI de jeu
placement_complete_page.dart    → UI de résultats
```

---

## 🎉 C'est Tout !

Votre système d'Engagement Director et de Calibration est maintenant opérationnel.

**Prochaines étapes recommandées** :
1. Tester avec plusieurs utilisateurs
2. Collecter des métriques (temps moyen, taux de complétion)
3. Ajuster les formules selon les données réelles
4. Ajouter des animations pour rendre l'expérience plus fluide

**Bon développement !** 🚀
