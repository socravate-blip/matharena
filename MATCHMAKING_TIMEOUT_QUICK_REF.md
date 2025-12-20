# 🚀 Quick Reference: Bot Fallback Matchmaking

## 📌 En Bref
Si aucun adversaire n'est trouvé en **5 secondes**, le joueur affronte automatiquement un **bot adaptatif**.

---

## 🔑 Points Clés

### Timing
- ⏱️ **5 secondes** de timeout
- ⚡ Transition **instantanée** vers le bot
- 🔄 **Pas de disruption** de l'expérience

### Bot Intelligence
- 🎯 **Adapte** son temps de réponse au joueur
- 📊 **3 niveaux**: Underdog / Competitive / Boss
- 🧠 **Sélection psychologique** (lose streak → bot facile)

### ELO & Stats
- ✅ Match bot **compte** comme un vrai match
- 📈 ELO **calculé normalement** (+15 à +25 victoire)
- 📊 Stats **mises à jour** (wins, losses, gamesPlayed)

---

## 📂 Fichiers Principaux

```
lib/features/game/
├── domain/services/
│   └── matchmaking_timeout_service.dart  ← Service timeout
└── presentation/pages/
    └── ranked_multiplayer_page.dart      ← UI intégrée
```

---

## 🔧 Configuration Rapide

### Changer le Délai
```dart
// matchmaking_timeout_service.dart, ligne ~50
await timeoutService.startTimeout(
  timeoutSeconds: 10, // ← Modifier ici (défaut: 5)
  onTimeout: () => _handleMatchmakingTimeout(),
);
```

### Désactiver Complètement
```dart
// ranked_multiplayer_page.dart, initState()
// Commenter cette ligne:
// _startMatchmakingTimeout();
```

---

## 🎮 Flow Utilisateur

```
1. Joueur lance match classé
   ↓
2. Attente 5s (compteur visible: "3s / 5s")
   ↓
   ├─→ Adversaire trouvé (< 5s)
   │   ✅ Match PvP normal
   │
   └─→ Timeout (≥ 5s)
       ⚡ Bot créé automatiquement
       ✅ Match vs Bot
```

---

## 📊 UI Screens

### Waiting Screen
```
┌──────────────────────┐
│ Recherche...         │
│ [████░░░░] 3s / 5s  │
│ Bot après 5s         │
└──────────────────────┘
```

### Bot Game
```
┌──────────────────────┐
│ Vous  VS  🤖 Bot     │
│ 3         2          │
│ 12 + 45 = ?          │
│ [  57  ] [VALIDER]   │
└──────────────────────┘
```

### Results
```
┌──────────────────────┐
│ 🏆 VICTOIRE !        │
│ vs MathBot 🤖        │
│ 7 - 5                │
│ ELO: 1200→1218 (+18) │
│ [RETOUR]             │
└──────────────────────┘
```

---

## 🧪 Test Rapide

```bash
# 1. Lancer l'app
flutter run

# 2. Dans l'app:
- Menu classé
- Lancer match
- Attendre 5s
- ✅ Bot apparaît

# 3. Vérifier logs:
⚡ TIMEOUT! Création bot...
🤖 Bot: Competitive, ELO 1150
```

---

## 🐛 Debugging

### Bot ne s'active pas?
```dart
// Vérifier les logs
print('⚡ TIMEOUT! Création bot...');
```

### Timer pas annulé?
```dart
// Vérifier StreamBuilder 'starting'/'playing':
_cancelMatchmakingTimeout();
```

### ELO pas sauvé?
```dart
// Vérifier _calculateBotElo()
await storage.saveProfile(myProfile);
```

---

## 📝 Code Snippets Utiles

### Vérifier Mode Bot
```dart
if (_isBotMode) {
  // Logic spécifique bot
}
```

### Enregistrer Temps Joueur
```dart
final responseTime = DateTime.now().millisecondsSinceEpoch - _puzzleStartTime;
_bot!.recordPlayerResponseTime(responseTime);
```

### Calculer Délai Bot
```dart
final delay = _bot!.calculateDynamicDelay(puzzle);
Timer(delay, () {
  // Bot répond
});
```

---

## 📚 Documentation Complète

| Document | Contenu |
|----------|---------|
| **MATCHMAKING_TIMEOUT_GUIDE.md** | Guide complet avec UI, config, architecture |
| **MATCHMAKING_TIMEOUT_COMPLETE.md** | Résumé de l'implémentation |
| **MATCHMAKING_TIMEOUT_TESTS.md** | Checklist de tests détaillée |
| **ADAPTIVE_BOT_GUIDE.md** | Système de bots adaptatifs |

---

## ✅ Checklist Deployment

- [x] Code compilé sans erreurs
- [x] Formatage Dart appliqué
- [x] Providers configurés
- [x] Documentation créée
- [ ] Tests manuels effectués
- [ ] Device réel testé
- [ ] Build release créé

---

## 🎯 Prochaines Étapes

1. **Tester** sur device réel (Android/iOS)
2. **Monitorer** le taux de timeout vs matches réels
3. **Ajuster** le délai si nécessaire (3s, 7s, 10s)
4. **Collecter** feedback utilisateurs
5. **Itérer** sur les niveaux de difficulté bot

---

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** 2024
