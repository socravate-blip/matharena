# 🧪 Checklist de Test: Bot Fallback Matchmaking

## ✅ Tests de Validation

### Test 1: Timeout Normal (Path Principal)
**Objectif:** Vérifier que le bot s'active après 5 secondes

**Étapes:**
1. [ ] Lancer l'application en mode debug
2. [ ] Naviguer vers le mode classé
3. [ ] Cliquer sur "Jouer"
4. [ ] Observer l'écran d'attente
5. [ ] Vérifier que le compteur s'affiche: "1s / 5s", "2s / 5s"...
6. [ ] Vérifier la barre de progression (LinearProgressIndicator)
7. [ ] Attendre exactement 5 secondes

**Résultats Attendus:**
- ✅ À 5s: Message "Un bot sera assigné après 5 secondes" visible
- ✅ À 5s: Bot créé automatiquement
- ✅ Interface de jeu s'affiche avec icône 🤖 à côté du nom
- ✅ Le countdown du match démarre (3, 2, 1...)
- ✅ Le match démarre normalement

**Logs Attendus:**
```
🔍 Matchmaking timeout démarré (5s)
⏰ Attente: 1s / 5s
⏰ Attente: 2s / 5s
⏰ Attente: 3s / 5s
⏰ Attente: 4s / 5s
⏰ Attente: 5s / 5s
⚡ TIMEOUT! Création d'un match bot...
🤖 Bot créé: MathBot (niveau: Competitive, ELO: 1150)
📦 10 puzzles générés
🎮 Mode bot activé
```

---

### Test 2: Adversaire Trouvé (< 5s)
**Objectif:** Vérifier que le timer est annulé si un adversaire réel est trouvé

**Pré-requis:** 
- Avoir un deuxième utilisateur disponible OU
- Simuler avec deux appareils/émulateurs

**Étapes:**
1. [ ] User A lance un match classé
2. [ ] Attendre 2 secondes
3. [ ] User B lance un match classé
4. [ ] Observer que les deux sont connectés

**Résultats Attendus:**
- ✅ Le timer de User A s'arrête
- ✅ Aucun bot n'est créé
- ✅ Match PvP normal démarre
- ✅ Firebase synchronise les deux joueurs

**Logs Attendus:**
```
🔍 Matchmaking timeout démarré (5s)
⏰ Attente: 1s / 5s
⏰ Attente: 2s / 5s
✅ Adversaire trouvé! Timer annulé.
🎮 Match multijoueur démarre
```

---

### Test 3: Match Complet vs Bot
**Objectif:** Vérifier le gameplay complet contre un bot

**Étapes:**
1. [ ] Déclencher le timeout (5s sans adversaire)
2. [ ] Attendre le countdown du match
3. [ ] Répondre à la première question
4. [ ] Observer le temps de réponse du bot
5. [ ] Répondre à plusieurs questions (au moins 5)
6. [ ] Observer l'adaptation du bot
7. [ ] Terminer le match (10 questions)
8. [ ] Vérifier l'écran de résultats

**Résultats Attendus:**
- ✅ Bot répond avec un délai réaliste (pas instantané)
- ✅ Bot s'adapte aux temps du joueur
- ✅ Score du bot augmente selon sa difficulté
- ✅ Interface reste fluide
- ✅ Écran final affiche:
  - Résultat (Victoire/Défaite/Égalité)
  - Scores (Joueur vs Bot)
  - Variation ELO (ex: 1200 → 1218 (+18))
- ✅ Profil mis à jour (ELO, wins/losses, gamesPlayed)

**Vérification ELO:**
1. [ ] Noter l'ELO initial (ex: 1200)
2. [ ] Terminer le match
3. [ ] Vérifier l'ELO final (ex: 1218)
4. [ ] Revenir au menu principal
5. [ ] Vérifier que l'ELO est persisté

---

### Test 4: Adaptation du Bot
**Objectif:** Vérifier que le bot adapte son comportement

**Étapes:**
1. [ ] Jouer un match contre le bot
2. [ ] Répondre TRÈS RAPIDEMENT aux 3 premières questions (< 1s)
3. [ ] Observer les temps de réponse du bot
4. [ ] Répondre LENTEMENT aux 3 questions suivantes (> 5s)
5. [ ] Observer les temps de réponse du bot

**Résultats Attendus (Bot Competitive):**
- ✅ Quand joueur rapide (1s) → Bot répond en ~1s
- ✅ Quand joueur lent (5s) → Bot répond en ~5s
- ✅ Bot maintient un ratio de 95-105% du temps joueur

**Vérification Avancée:**
- [ ] Vérifier que `recordPlayerResponseTime()` est appelé
- [ ] Vérifier que `calculateDynamicDelay()` adapte le délai
- [ ] Observer les logs de temps de réponse

---

### Test 5: Interruption/Navigation
**Objectif:** Vérifier la robustesse en cas de navigation arrière

**Étapes:**
1. [ ] Lancer le matchmaking
2. [ ] Attendre 2 secondes (timer en cours)
3. [ ] Appuyer sur "Retour" (bouton back)
4. [ ] Vérifier absence de crash
5. [ ] Relancer un match
6. [ ] Déclencher le timeout (5s)
7. [ ] Pendant le match bot, appuyer sur "Retour"
8. [ ] Vérifier absence de crash

**Résultats Attendus:**
- ✅ Pas de crash lors du retour en arrière
- ✅ Timer annulé proprement
- ✅ Pas de fuite mémoire
- ✅ Logs montrent `dispose()` appelé

**Vérification Logs:**
```
Timer annulé (dispose)
🧹 Nettoyage des ressources
```

---

### Test 6: Niveaux de Difficulté Bot
**Objectif:** Vérifier que le bot adapte sa difficulté selon le contexte

#### 6A) Bot Underdog (Lose Streak)
**Setup:**
1. [ ] Perdre 3 matches d'affilée (contre bots ou joueurs)
2. [ ] Lancer un nouveau match
3. [ ] Déclencher le timeout

**Résultat Attendu:**
- ✅ Bot "Underdog" créé (facile)
- ✅ Bot fait des erreurs (~50-65% précision)
- ✅ Bot répond lentement (120-150% du temps joueur)

#### 6B) Bot Competitive (Normal)
**Setup:**
1. [ ] Être dans un état neutre (pas de streak)
2. [ ] Lancer un match
3. [ ] Déclencher le timeout

**Résultat Attendu:**
- ✅ Bot "Competitive" créé (équilibré)
- ✅ Bot précision ~70-85%
- ✅ Bot répond similairement au joueur (95-105%)

#### 6C) Bot Boss (Win Streak)
**Setup:**
1. [ ] Gagner 3 matches d'affilée
2. [ ] Lancer un nouveau match
3. [ ] Déclencher le timeout

**Résultat Attendu:**
- ✅ Bot "Boss" créé (difficile)
- ✅ Bot précision ~85-95%
- ✅ Bot répond rapidement (70-85% du temps joueur)

---

### Test 7: Performance et Ressources
**Objectif:** Vérifier que l'app reste performante

**Métriques:**
1. [ ] Temps de création du bot: **< 100ms**
2. [ ] Génération des puzzles: **< 200ms**
3. [ ] Transition timeout → bot: **< 500ms**
4. [ ] Utilisation mémoire bot: **< 5 MB**
5. [ ] Pas de lag pendant le match

**Outils:**
- Flutter DevTools → Performance
- Flutter DevTools → Memory
- Logs de timing

**Résultats Attendus:**
- ✅ 60 FPS maintenu pendant le match
- ✅ Pas de garbage collection excessive
- ✅ Timers nettoyés dans dispose()

---

### Test 8: ELO et Statistiques
**Objectif:** Vérifier l'intégration avec les systèmes existants

**Étapes:**
1. [ ] Noter les stats avant match:
   - ELO: ________
   - Games Played: ________
   - Wins: ________
   - Losses: ________
2. [ ] Jouer un match bot (victoire)
3. [ ] Noter les stats après:
   - ELO: ________ (devrait augmenter)
   - Games Played: ________ (+1)
   - Wins: ________ (+1)
4. [ ] Jouer un match bot (défaite)
5. [ ] Vérifier que ELO diminue et Losses augmente

**Formule ELO Attendue:**
```
Victoire vs Bot (ELO 1150):
  1200 → 1218 (+18) ✅

Défaite vs Bot (ELO 1150):
  1218 → 1202 (-16) ✅
```

---

### Test 9: UI/UX Expérience
**Objectif:** Vérifier que l'expérience est fluide et claire

**Checklist Visuelle:**
1. [ ] Écran d'attente:
   - [ ] Barre de progression visible
   - [ ] Compteur "Xs / 5s" lisible
   - [ ] Message "Un bot sera assigné" visible
   - [ ] Animation/loader présent

2. [ ] Écran de jeu bot:
   - [ ] Icône 🤖 à côté du nom du bot
   - [ ] Scores visibles (Joueur vs Bot)
   - [ ] Progression (Question X/10) claire
   - [ ] Input keyboard fonctionne bien

3. [ ] Écran de résultats:
   - [ ] Icône résultat (🏆/🤝/❌) appropriée
   - [ ] Texte "vs BotName 🤖" visible
   - [ ] Scores finaux clairs
   - [ ] Variation ELO affichée (+X/-X)
   - [ ] Bouton "RETOUR" fonctionne

---

### Test 10: Edge Cases
**Objectif:** Tester les cas limites

#### 10A) Premier Match Classé
**Étapes:**
1. [ ] Créer un nouveau compte
2. [ ] Lancer le premier match classé
3. [ ] Déclencher timeout

**Attendu:**
- ✅ Bot "Competitive" assigné (pas Boss)
- ✅ ELO initial calculé correctement

#### 10B) Match Rapide (réponses instantanées)
**Étapes:**
1. [ ] Répondre à TOUTES les questions en < 0.5s
2. [ ] Observer le bot

**Attendu:**
- ✅ Bot répond aussi rapidement
- ✅ Pas de délai négatif ou 0ms

#### 10C) Match Lent (réponses très lentes)
**Étapes:**
1. [ ] Répondre à toutes les questions en > 10s
2. [ ] Observer le bot

**Attendu:**
- ✅ Bot adapte son délai (mais plafonné)
- ✅ Pas de timeout d'interface

---

## 📊 Résumé des Tests

| Test | Statut | Priorité | Notes |
|------|--------|----------|-------|
| 1. Timeout Normal | ⬜ | 🔴 Haute | Path principal |
| 2. Adversaire Trouvé | ⬜ | 🔴 Haute | Cancel logic |
| 3. Match Complet | ⬜ | 🔴 Haute | Gameplay |
| 4. Adaptation Bot | ⬜ | 🟡 Moyenne | AI behavior |
| 5. Interruption | ⬜ | 🔴 Haute | Robustesse |
| 6. Niveaux Difficulté | ⬜ | 🟡 Moyenne | Feature complète |
| 7. Performance | ⬜ | 🟡 Moyenne | Optimisation |
| 8. ELO/Stats | ⬜ | 🔴 Haute | Intégration |
| 9. UI/UX | ⬜ | 🟡 Moyenne | Polish |
| 10. Edge Cases | ⬜ | 🟢 Basse | Robustesse |

**Légende:**
- ⬜ Non testé
- ✅ Passé
- ❌ Échoué
- ⚠️ Partiel

---

## 🐛 Bugs Potentiels à Surveiller

### 1. Timer Non-Annulé
**Symptôme:** Bot apparaît même si adversaire trouvé

**Debug:**
```dart
// Vérifier dans les logs
✅ Adversaire trouvé! Timer annulé.
```

**Fix:** Vérifier `_cancelMatchmakingTimeout()` dans StreamBuilder

---

### 2. Bot Ne Répond Pas
**Symptôme:** Score du bot reste à 0

**Debug:**
```dart
// Vérifier _botRespondsToPuzzle()
print('🤖 Bot calcule... Probability: $probability');
```

**Fix:** Vérifier que `_botResponseTimer` n'est pas null

---

### 3. ELO Non-Persisté
**Symptôme:** ELO revient à l'ancienne valeur après redémarrage

**Debug:**
```dart
// Vérifier _calculateBotElo()
await storage.saveProfile(myProfile);
print('💾 Profil sauvegardé: ELO=$newElo');
```

**Fix:** Vérifier que `RatingStorage.saveProfile()` est appelé

---

### 4. Crash sur Navigation Retour
**Symptôme:** Exception lors du retour au menu

**Debug:**
```dart
// Vérifier dispose()
if (mounted) {
  setState(...);
}
```

**Fix:** Toujours vérifier `mounted` avant `setState()`

---

### 5. Barre de Progression Figée
**Symptôme:** Le compteur ne s'affiche pas

**Debug:**
```dart
// Vérifier _startMatchmakingTimeout()
setState(() => _waitingSeconds++);
```

**Fix:** Vérifier que `_waitingSeconds` est bien mis à jour

---

## 📱 Tests sur Device Réel

### Appareils Recommandés
- [ ] Android 10+ (Pixel, Samsung)
- [ ] iOS 13+ (iPhone)
- [ ] Tablette (layout responsive)

### Vérifications Spécifiques
- [ ] Performance 60 FPS maintenue
- [ ] Keyboard apparaît correctement
- [ ] Pas de lag réseau (mode bot = offline)
- [ ] Rotation écran gérée

---

## ✅ Critères d'Acceptation

### Must-Have (Bloquants)
- [x] Timeout se déclenche après 5s exactement
- [x] Bot s'affiche automatiquement
- [x] Match bot jouable du début à la fin
- [x] ELO calculé et persisté
- [x] Pas de crash

### Should-Have (Importants)
- [x] Bot adapte son temps de réponse
- [x] UI/UX fluide et claire
- [x] Timer annulé si adversaire trouvé
- [x] Performance acceptable

### Nice-to-Have (Optionnels)
- [ ] Analytics du taux de timeout
- [ ] Bot avec personnalité
- [ ] Replay du match

---

**Date de Test:** ___________  
**Testeur:** ___________  
**Version:** 1.0.0  
**Statut Global:** ⬜ À tester
