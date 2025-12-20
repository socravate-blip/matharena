# Guide: Timeout de Matchmaking avec Bot Fallback

## 🎯 Vue d'ensemble

Lorsqu'un joueur cherche un match classé multijoueur, le système attend **5 secondes** pour trouver un adversaire réel. Si aucun adversaire n'est trouvé dans ce délai, le joueur est automatiquement mis en match contre un **bot adaptatif** pour garantir une expérience de jeu fluide.

## 📋 Fonctionnement

### 1. Démarrage du Matchmaking
```dart
// Dans RankedMultiplayerPage.initState()
_startMatchmakingTimeout();
```

### 2. Timer de 5 Secondes
- Un `Timer` démarre au lancement du matchmaking
- Un compteur visuel s'affiche: "1s / 5s", "2s / 5s"...
- Une barre de progression montre le temps restant

### 3. Deux Issues Possibles

#### A) Adversaire Trouvé (< 5s)
✅ Le match multijoueur normal démarre
✅ Le timer est annulé automatiquement
✅ Firebase gère la synchronisation

#### B) Timeout (≥ 5s)
⚡ Le match Firebase est annulé
⚡ Un bot adaptatif est créé via `AdaptiveMatchmaking`
⚡ Le mode bot s'active automatiquement
⚡ L'interface reste identique (joueur ne voit pas de différence)

## 🤖 Sélection du Bot

Le système utilise **l'analyse psychologique** pour choisir le niveau du bot:

```dart
// matchmaking_timeout_service.dart
final botData = await timeoutService.createBotMatch(
  playerElo: currentElo,
  playerStats: playerStats,
);
```

### Critères de Sélection
- **Lose Streak ≥ 3** → Bot "Underdog" (facile)
- **Premier match classé** → Bot "Competitive" (équilibré)
- **En série de victoires** → Bot "Boss" (difficile)

## 💻 Interface

### Écran d'Attente
```
┌─────────────────────────────┐
│  Recherche d'adversaire...  │
│                             │
│  [████████░░░░░░░░░░]      │
│  3s / 5s                    │
│                             │
│  Un bot sera assigné        │
│  après 5 secondes           │
└─────────────────────────────┘
```

### Écran de Jeu (Mode Bot)
```
┌─────────────────────────────┐
│ Vous        VS    🤖 Bot    │
│ Score: 3          Score: 2  │
├─────────────────────────────┤
│ Question 5/10               │
│                             │
│      12 + 45 = ?            │
│                             │
│      [  57  ]               │
│                             │
│    [VALIDER]                │
└─────────────────────────────┘
```

### Écran de Résultats
```
┌─────────────────────────────┐
│         🏆                  │
│      VICTOIRE !             │
│   vs MathBot 🤖             │
│                             │
│   Vous    -    Bot          │
│    7           5            │
│                             │
│  ELO: 1200 → 1218 (+18)     │
│                             │
│     [RETOUR]                │
└─────────────────────────────┘
```

## 🎮 Comportement du Bot

### Temps de Réponse Adaptatif
```dart
// Le bot enregistre les temps du joueur
bot.recordPlayerResponseTime(responseTime);

// Puis adapte son délai de réponse
final delay = bot.calculateDynamicDelay(puzzle);
```

### Niveaux de Difficulté

| Niveau | Temps de Réponse | Précision | Utilisation |
|--------|-----------------|-----------|-------------|
| **Underdog** | 120-150% du joueur | 50-65% | Lose Streak ≥3 |
| **Competitive** | 95-105% du joueur | 70-85% | Match équilibré |
| **Boss** | 70-85% du joueur | 85-95% | Win Streak ≥3 |

## 📊 Calcul ELO

Le match contre un bot compte pour l'ELO du joueur:

```dart
final newElo = EloCalculator.calculateNewRating(
  currentRating: playerElo,
  opponentRating: botElo,
  actualScore: playerScore > botScore ? 1.0 : 0.0,
  gamesPlayed: gamesPlayed,
);
```

### Gain/Perte Typique
- **Victoire contre bot** : +15 à +25 ELO
- **Défaite contre bot** : -10 à -20 ELO
- **Égalité** : -5 à +5 ELO

## 🔧 Configuration

### Modifier le Délai de Timeout
```dart
// matchmaking_timeout_service.dart
await timeoutService.startTimeout(
  timeoutSeconds: 10, // Changer ici (défaut: 5)
  onTimeout: () => _handleMatchmakingTimeout(),
);
```

### Désactiver le Bot Fallback
```dart
// Dans RankedMultiplayerPage.initState()
// Commenter cette ligne:
// _startMatchmakingTimeout();
```

## 📁 Fichiers Impliqués

| Fichier | Rôle |
|---------|------|
| `matchmaking_timeout_service.dart` | Service gérant le timer et création du bot |
| `ranked_multiplayer_page.dart` | Interface utilisateur avec mode bot |
| `adaptive_matchmaking.dart` | Sélection du niveau de difficulté |
| `bot_ai.dart` | IA du bot avec adaptation en temps réel |

## 🧪 Tests

### Test Manuel
1. Lancer l'app en mode debug
2. Accéder au mode classé
3. Attendre 5 secondes sans trouver d'adversaire
4. Vérifier que le bot apparaît automatiquement
5. Jouer le match complet
6. Vérifier le calcul ELO final

### Logs de Debug
```
🔍 Matchmaking timeout démarré (5s)
⏰ Attente: 1s / 5s
⏰ Attente: 2s / 5s
...
⏰ Attente: 5s / 5s
⚡ TIMEOUT! Création d'un match bot...
🤖 Bot créé: MathBot (niveau: Competitive, ELO: 1150)
🎮 Mode bot activé
📊 ELO vs Bot: 1200 → 1218 (+18)
```

## 🎨 UX Design

### Principe
Le joueur **ne doit pas réaliser** qu'il joue contre un bot. L'expérience doit être fluide:
- ✅ Pas de message "Aucun adversaire trouvé"
- ✅ Transition transparente vers le bot
- ✅ Interface identique au mode multijoueur
- ✅ Bot avec un nom et avatar réalistes

### Indicateurs Subtils
- 🤖 Icône de robot à côté du nom
- 🎮 Temps de réponse légèrement artificiels
- 📊 Mention "vs Bot" seulement sur l'écran final

## 🚀 Avantages

1. **Pas d'attente infinie** : Garantit un match en 5s max
2. **Expérience continue** : Pas de retour au menu
3. **Pratique ELO** : Le joueur peut toujours gagner/perdre des points
4. **Calibration** : Aide les nouveaux joueurs à monter en ELO
5. **Heures creuses** : Assure la jouabilité même sans joueurs en ligne

## ⚙️ Architecture

```
RankedMultiplayerPage
  ├─ Firebase Matchmaking (prioritaire)
  ├─ MatchmakingTimeoutService
  │   ├─ Timer(5s)
  │   └─ createBotMatch()
  │       ├─ AdaptiveMatchmaking.selectBotDifficulty()
  │       ├─ AdaptiveMatchmaking.createBotOpponent()
  │       └─ PuzzleGenerator.generateSet()
  └─ Bot Mode UI
      ├─ _buildBotGameScreen()
      ├─ _buildBotResultScreen()
      └─ _calculateBotElo()
```

## 📝 Notes Techniques

### Thread Safety
- Tous les timers sont annulés dans `dispose()`
- Les callbacks vérifient `if (mounted)` avant `setState()`
- Le timer est annulé si un adversaire réel est trouvé

### Performance
- Le bot est créé **uniquement** après timeout
- Les puzzles sont générés **une seule fois**
- Pas d'overhead si un match réel démarre

### Compatibilité
- ✅ Fonctionne avec le système ELO existant
- ✅ Compatible avec les stats et achievements
- ✅ S'intègre au système de progression

## 🔮 Améliorations Futures

- [ ] Analytics: Taux de timeout vs matches réels
- [ ] Multiple bots avec personnalités différentes
- [ ] Bot qui "chat" pendant le match
- [ ] Mode bot accessible directement (sans timeout)
- [ ] Replay des matches bot pour analyse

---

**Version:** 1.0  
**Dernière mise à jour:** 2024  
**Système:** MathArena Adaptive Bots
