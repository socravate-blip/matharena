# 🔧 Guide de Debug - Ranked Mode

## Changer rapidement l'ELO pour tester

### Interface visuelle (Recommandé)

Sur l'écran de démarrage du mode Ranked, vous verrez un panneau **"DEBUG - Quick ELO Switch"** avec 4 boutons :

- **🥉 Bronze** → ELO 1000 (15 puzzles Basic)
- **🥈 Silver** → ELO 1350 (15 Basic + 5 Complex)
- **🥇 Gold** → ELO 1650 (10 Basic + 10 Complex + 5 Game24)
- **💎 Diamond** → ELO 1900 (10 Basic + 10 Complex + 10 Game24 + 1 Matador)

Cliquez sur n'importe quel bouton pour changer instantanément votre ELO et tester la league correspondante !

### Par code (Alternative)

Si vous voulez tester un ELO spécifique, vous pouvez appeler directement :

```dart
final storage = ref.read(ratingStorageProvider);
await storage.debugSetElo(1500); // N'importe quel ELO entre 100-3000
ref.invalidate(playerRatingProvider); // Rafraîchir l'UI
```

## Structure des Leagues

| League | ELO Range | Contenu Playlist |
|--------|-----------|------------------|
| 🥉 **Bronze** | < 1200 | 15 Basic |
| 🥈 **Silver** | 1200-1499 | 15 Basic + 5 Complex |
| 🥇 **Gold** | 1500-1799 | 10 Basic + 10 Complex + 5 Game24 |
| 💎 **Diamond** | 1800+ | 10 Basic + 10 Complex + 10 Game24 + 1 Matador |

## Types de Puzzles

### 1. Basic Puzzle (Questions 1-15)
- **Format**: `A op B = ?`
- **Interface**: Question affichée (ex: "5 + 3"), numpad pour entrer la réponse
- **Exemple**: `8 + 7 = ?` → Réponse: `15`
- **Time**: 30 secondes
- **Points**: 1 point

### 2. Complex Puzzle (Questions 16-20, Silver+)
- **Format**: `A op (B op C) = ?`
- **Interface**: Question avec parenthèses (ex: "10 - (3 + 5)"), numpad
- **Exemple**: `20 - (4 * 3) = ?` → Réponse: `8`
- **Time**: 45 secondes
- **Points**: 2 points

### 3. Game24 Puzzle (Question 21, Gold+)
- **Format**: Faire 24 avec 4 nombres
- **Interface**: Expression builder avec opérateurs
- **Exemple**: Nombres [3, 6, 8, 8] → Solution: `8/(3-8/3)` = 24
- **Time**: 120 secondes
- **Points**: 5 points

### 4. Matador Puzzle (Question 22, Diamond+)
- **Format**: Atteindre une cible avec 5 nombres
- **Interface**: Expression builder complet
- **Exemple**: Cible 42 avec [2, 3, 5, 7, 10]
- **Time**: 360 secondes (6 minutes)
- **Points**: 13 points (si Mathador - utilise tous les opérateurs)

## Interface des Puzzles Basic/Complex

L'interface ressemble maintenant au mode **Training** :

```
┌─────────────────────────┐
│      TARGET             │
│                         │
│       5 + 3             │  ← Question affichée
│                         │
└─────────────────────────┘

┌─────────────────────────┐
│         _               │  ← Réponse à entrer
└─────────────────────────┘

┌─────────────────────────┐
│   7   8   9             │
│   4   5   6             │  ← Numpad
│   1   2   3             │
│   -   0   ←             │
└─────────────────────────┘
```

**Différences avec Training**:
- ❌ Pas de bouton "Show Answer"
- ✅ Progression affichée (Question X/Y)
- ✅ Badge du type de puzzle
- ✅ Accumulation de score

## Tips de Test

### Tester Bronze (15 puzzles faciles)
```
Cliquez sur 🥉 Bronze → BEGIN
```

### Tester Silver (20 puzzles avec complexité)
```
Cliquez sur 🥈 Silver → BEGIN
```

### Tester Gold (avec Game24)
```
Cliquez sur 🥇 Gold → BEGIN
Puzzles 1-20 = Basic/Complex
Puzzle 21 = Game24 (Build expression avec 4 nombres)
```

### Tester Diamond (Boss Level)
```
Cliquez sur 💎 Diamond → BEGIN
Puzzles 1-20 = Basic/Complex
Puzzle 21 = Game24
Puzzle 22 = Matador (Boss Level final!)
```

## Résolution Rapide des Problèmes

### "L'interface ne montre pas le bon nombre de puzzles"
→ Vérifiez votre ELO avec les boutons debug et redémarrez le match

### "Les puzzles Basic affichent le résultat"
→ Corrigé ! La question est maintenant affichée sans le résultat (ex: "5 + 3" au lieu de "8")

### "L'ELO ne change pas"
→ Assurez-vous d'appeler `ref.invalidate(playerRatingProvider)` après `debugSetElo()`

### "Je veux revenir à mon vrai ELO"
→ Rechargez complètement l'application ou utilisez le bouton qui correspond à votre vraie league

## Commandes Utiles

### Reset complet du profil
```dart
await ratingStorage.resetProfile();
```

### Voir le profil actuel
```dart
final profile = await ratingStorage.getProfile();
print('Current ELO: ${profile.currentRating}');
print('League: ${profile.league}');
```

---

**Bon test ! 🚀**
