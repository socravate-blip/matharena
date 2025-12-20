# 🏁 Ghost Protocol - Race Condition (Course Parallèle)

## ✅ Implémentation Terminée

Le système Ghost Protocol utilise désormais une **vraie race condition** entre le joueur et le bot.

## 🎯 Principe de Fonctionnement

### Avant (❌ Séquentiel)
```
Joueur répond → Bot réagit après un délai → Prochain puzzle
```
**Problème:** Le bot ne pouvait jamais battre le joueur de vitesse.

### Maintenant (✅ Parallèle)
```
Puzzle affiché
    ↓
    ├─→ Timer Bot démarre (calcul via BotAI)
    └─→ UI débloquée pour le joueur
    
Premier arrivé = Gagnant de la manche
```

## 🔧 Modifications Techniques

### 1. Variable de Tracking
```dart
Timer? _botRaceTimer; // Timer pour la race condition bot vs joueur
```

### 2. Méthode `_startBotRaceTimer()`
- **Quand:** Appelée dès l'affichage d'un puzzle en Ghost Mode
- **Fonction:** Démarre un `Timer` avec le délai calculé par `BotAI.calculateDynamicDelay`
- **Si expire:** Le bot soumet sa réponse automatiquement (le joueur a perdu la manche)

```dart
_botRaceTimer = Timer(
  Duration(milliseconds: botResponse.responseTimeMs),
  () {
    // Bot gagne la race!
    // Mettre à jour score bot
    // Passer au puzzle suivant
  },
);
```

### 3. Modification de `_submitAnswer()`
```dart
// Si le joueur répond en premier → ANNULER le timer du bot
if (_isGhostMode && _botRaceTimer != null && _botRaceTimer!.isActive) {
  print('🎯 JOUEUR GAGNE LA RACE! Timer bot annulé');
  _botRaceTimer?.cancel();
}
```

### 4. Déclenchement Automatique
Dans `_buildGameScreen()`, dès qu'un puzzle est affiché:
```dart
if (_isGhostMode && _botRaceTimer == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startBotRaceTimer();
  });
}
```

## 🎮 Scénarios de Jeu

### Scénario 1: Joueur Rapide ⚡
1. Puzzle s'affiche
2. Timer bot démarre (5 secondes)
3. Joueur répond en 2 secondes ✅
4. **Timer bot annulé** → Joueur gagne la manche

### Scénario 2: Bot Rapide 🤖
1. Puzzle s'affiche
2. Timer bot démarre (3 secondes)
3. Joueur n'a pas encore répondu
4. **Timer expire** → Bot soumet sa réponse → Joueur perd la manche
5. Passage automatique au puzzle suivant

### Scénario 3: Joueur AFK 😴
1. Puzzle s'affiche
2. Timer bot démarre (4 secondes)
3. Joueur ne fait rien
4. **Timer expire** → Bot gagne
5. Nouveau puzzle → Timer bot redémarre
6. Le bot continue à jouer tout seul jusqu'à la fin

## 🔍 Logs Debug

Quand la race démarre:
```
🏁 RACE DÉMARRÉE! Bot va répondre dans 3500ms (3.5s)
```

Si le joueur gagne:
```
🎯 JOUEUR GAGNE LA RACE! Timer bot annulé
```

Si le bot gagne:
```
🤖 BOT GAGNE LA RACE! Réponse: CORRECT
```

## ✨ Avantages

1. **Réalisme Total:** Le bot se comporte comme un vrai adversaire
2. **Pression Temporelle:** Le joueur sent la menace du bot
3. **Gestion AFK:** Si le joueur abandonne, le bot termine le match seul
4. **Architecture Propre:** Les deux flux sont vraiment indépendants

## 🧪 Test Manuel

1. Lancer un match ranked
2. Attendre 5 secondes (timeout → Ghost Mode)
3. **Ne rien faire** sur le premier puzzle
4. Observer: Le bot devrait répondre automatiquement après son délai
5. Réponds sur le 2ème puzzle **très vite**
6. Observer: Le timer du bot est annulé, tu gagnes la manche

## 📁 Fichiers Modifiés

- [`lib/features/game/presentation/pages/ranked_multiplayer_page.dart`](lib/features/game/presentation/pages/ranked_multiplayer_page.dart)
  - Ajout `_botRaceTimer`
  - Méthode `_startBotRaceTimer()`
  - Logique d'annulation dans `_submitAnswer()`
  - Déclenchement automatique dans `_buildGameScreen()`

## ⚙️ Configuration

Le délai du bot est calculé dynamiquement par:
- `BotAI.calculateDynamicDelay()` (dans `bot_ai.dart`)
- Prend en compte:
  - Difficulté du bot (Underdog/Competitive/Boss)
  - Historique du joueur
  - Complexité du puzzle

---

**Status:** ✅ Opérationnel  
**Date:** Décembre 2025  
**Système:** Ghost Protocol v2.0
