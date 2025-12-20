# 🎮 Système de Debug pour Difficulté du Bot

## ✅ Modifications Implémentées

### 1. **Sélecteur de Difficulté Bot (Debug)**

Dans l'écran d'attente du matchmaking, un panneau de debug orange permet de choisir la difficulté du bot :

- **Auto** : Difficulté adaptative basée sur les stats du joueur (comportement par défaut)
- **Easy** : Bot Underdog (120-150% du temps moyen du joueur)
- **Normal** : Bot Competitive (95-105% du temps moyen)
- **Hard** : Bot Boss (70-85% du temps moyen)

#### Configuration
```dart
// Dans ranked_multiplayer_page.dart ligne ~52
static const bool _debugBotDifficulty = true; // Activer/désactiver le debug
```

Pour **désactiver** en production, mettre à `false`.

### 2. **OpponentCard du Bot Affiché**

Créé une méthode `_buildGhostCountdownScreen()` qui affiche l'OpponentCard avec les vraies données du bot :
- Nom réaliste (ex: "Avery", "Jordan", "Quinn")
- ELO crédible (±75 à ±150 du joueur selon difficulté)
- Win/Lose streak du bot
- Total games joués

### 3. **Indicateur de Difficulté (Debug)**

Un badge orange apparaît sous le countdown pour montrer la difficulté du bot :
- **BOT: UNDERDOG**
- **BOT: COMPETITIVE**  
- **BOT: BOSS**

Ce badge n'apparaît que si `_debugBotDifficulty = true`.

---

## 🎯 Comment Utiliser

### Tester différentes difficultés :

1. **Lancer l'app** et aller dans Ranked Match
2. **Attendre** l'écran de matchmaking
3. **Sélectionner** une difficulté dans le panneau orange :
   - Cliquer sur "Easy", "Normal" ou "Hard"
   - Ou laisser "Auto" pour difficulté adaptative
4. **Attendre 5 secondes** pour que le bot soit créé
5. **Observer** l'OpponentCard avec le nom et stats du bot
6. **Vérifier** le badge orange qui indique la difficulté effective

### Exemple de Test :

```
[Écran d'attente]
┌─────────────────────────────────────┐
│  RECHERCHE D'UN ADVERSAIRE...      │
│  Temps d'attente: 3s / 5s          │
│                                    │
│  ⚠️  DEBUG: Difficulté Bot         │
│  [Auto] [Easy] [Normal] [Hard]    │ ← Sélectionner ici
└─────────────────────────────────────┘

[Après 5s - Countdown]
┌─────────────────────────────────────┐
│  ADVERSAIRE TROUVÉ !               │
│                                    │
│  ╔══════════════════════════════╗  │
│  ║  Avery                       ║  │ ← Nom réaliste
│  ║  ELO: 1125                   ║  │ ← ELO crédible
│  ║  Win Streak: 2               ║  │ ← Stats du bot
│  ║  Total: 87 games             ║  │
│  ╚══════════════════════════════╝  │
│                                    │
│           3                        │
│  LA PARTIE COMMENCE...             │
│                                    │
│  🐛 BOT: COMPETITIVE               │ ← Debug indicator
└─────────────────────────────────────┘
```

---

## 🔧 Code Technique

### Fichiers Modifiés

1. **ranked_multiplayer_page.dart**
   - Ajouté `_debugBotDifficulty` flag (ligne ~52)
   - Ajouté `_selectedBotDifficulty` variable (ligne ~53)
   - Ajouté panneau UI de sélection dans `_buildWaitingScreen()`
   - Ajouté `_buildDifficultyButton()` widget
   - Créé `_buildGhostCountdownScreen()` pour afficher OpponentCard
   - Modifié appel à `createGhostMatch()` avec `forcedDifficulty`

2. **ghost_match_orchestrator.dart**
   - Ajouté paramètre `forcedDifficulty` dans `createGhostMatch()`
   - Logique : Si `forcedDifficulty != null`, ignore la difficulté adaptative

### Flux de Données

```
Utilisateur sélectionne "Hard"
    ↓
_selectedBotDifficulty = BotDifficulty.boss
    ↓
Timeout après 5s
    ↓
_handleMatchmakingTimeout()
    ↓
GhostMatchOrchestrator.createGhostMatch(
    forcedDifficulty: BotDifficulty.boss  ← Force Boss
)
    ↓
Bot créé avec difficulté Boss (70-85% temps joueur)
    ↓
OpponentCard affichée avec nom + stats
    ↓
Badge debug "BOT: BOSS"
```

---

## 📊 Comparaison des Difficultés

| Difficulté | Temps Réponse | Taux Réussite | ELO Relatif |
|-----------|---------------|---------------|-------------|
| **Underdog (Easy)** | 120-150% joueur | Plus bas | -150 à -50 |
| **Competitive (Normal)** | 95-105% joueur | Équivalent | -75 à +75 |
| **Boss (Hard)** | 70-85% joueur | Plus haut | +50 à +150 |

### Exemple Concret

Si le joueur met en moyenne **4 secondes** par puzzle :
- **Easy Bot** : 4.8 - 6.0 secondes
- **Normal Bot** : 3.8 - 4.2 secondes
- **Hard Bot** : 2.8 - 3.4 secondes

Avec **caps absolus** pour éviter l'exploitation :
- BasicPuzzle : max 8s
- ComplexPuzzle : max 20s
- Game24 : max 45s
- Matador : max 60s

---

## ⚠️ Important pour Production

### Désactiver le Debug

Avant de publier en production :

```dart
// Dans ranked_multiplayer_page.dart
static const bool _debugBotDifficulty = false; // ← Mettre à false
```

Cela :
- ✅ Cache le panneau de sélection de difficulté
- ✅ Cache le badge "BOT: XXXX"
- ✅ Garde l'OpponentCard visible (normal)
- ✅ Utilise uniquement la difficulté adaptative

### Pourquoi garder l'OpponentCard en Production ?

L'OpponentCard **doit rester visible** même en production car :
- C'est l'essence du "Ghost Protocol" (bot indiscernable)
- Le joueur voit un adversaire réaliste (nom, ELO, stats)
- Aucune indication que c'est un bot
- UI identique au multiplayer réel

Seuls les **éléments debug** (panneau orange, badge) doivent être cachés.

---

## 🎨 Captures d'Écran Attendues

### Écran d'Attente (Debug ON)
![Waiting](https://via.placeholder.com/300x400/0A0A0A/FFFFFF?text=Waiting+Screen)
- Timer visible (3s / 5s)
- Panneau orange avec 4 boutons
- Bouton sélectionné en orange vif

### Countdown avec OpponentCard
![Countdown](https://via.placeholder.com/300x400/0A0A0A/00FFFF?text=Countdown+Screen)
- "ADVERSAIRE TROUVÉ !"
- OpponentCard complète avec stats
- Countdown géant (3, 2, 1)
- Badge debug "BOT: COMPETITIVE"

### En Jeu
![Game](https://via.placeholder.com/300x400/0A0A0A/FFFFFF?text=Game+Screen)
- Header avec nom adversaire
- Barre de progression adversaire en temps réel
- Puzzles normaux
- Le bot répond avec délais adaptatifs

---

## 🐛 Troubleshooting

### L'OpponentCard ne s'affiche pas
- ✅ Vérifier que `_ghostData` n'est pas null
- ✅ Vérifier que `_ghostData.botPersona` contient les bonnes données
- ✅ Vérifier que `match.player2` est bien créé

### Le panneau de sélection n'apparaît pas
- ✅ Vérifier `_debugBotDifficulty = true`
- ✅ Vérifier que `_waitingSeconds < 5`
- ✅ Relancer l'app si nécessaire

### Le bot ne respecte pas la difficulté choisie
- ✅ Vérifier que `_selectedBotDifficulty` est bien transmis
- ✅ Vérifier les logs : "✅ Ghost Match créé: [nom] (ELO [xxx])"
- ✅ Vérifier le badge debug qui doit afficher la bonne difficulté

---

## 🚀 Tests Recommandés

1. **Test Easy Bot**
   - Sélectionner "Easy"
   - Attendre 5s
   - Vérifier badge "BOT: UNDERDOG"
   - Jouer et observer que le bot est lent

2. **Test Hard Bot**
   - Sélectionner "Hard"
   - Attendre 5s
   - Vérifier badge "BOT: BOSS"
   - Jouer et observer que le bot est rapide

3. **Test Auto (Adaptatif)**
   - Laisser "Auto" sélectionné
   - Le bot s'adapte à votre historique
   - Peut être UNDERDOG, COMPETITIVE ou BOSS

4. **Test OpponentCard**
   - Vérifier que le nom est réaliste (pas "Bot" ou "AI")
   - Vérifier que l'ELO est dans une plage crédible
   - Vérifier que les stats sont cohérentes

---

## ✨ Résultat Final

Le système est maintenant **production-ready** avec :
- ✅ Mode debug pour tester facilement
- ✅ OpponentCard du bot parfaitement affichée
- ✅ Indicateurs visuels clairs en mode debug
- ✅ Facile à désactiver pour production
- ✅ Interface unifiée (bot = joueur réel)

**Le Ghost Protocol est complet !** 👻
