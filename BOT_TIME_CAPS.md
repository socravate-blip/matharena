# ⏱️ Temps Maximums Absolus des Bots - Système Réaliste

## 📋 Vue d'ensemble

Le système de bot utilise des **caps absolus réalistes** pour chaque type de puzzle et difficulté.
Le bot suit le temps du joueur (multiplicateurs 140-180%, 95-105%, 50-65%) **MAIS** ne dépassera JAMAIS les limites ci-dessous.

---

## 🎯 BASIC MATH (Addition, Soustraction simple)

### 🐢 Underdog (Bot facile)
- **Min:** 2 secondes
- **Max:** 4 secondes
- **Exemple:** 3s ± 1s
- **Logique:** 140-180% du temps joueur, plafonné à 4s

### ⚖️ Competitive (Bot équilibré)
- **Min:** 1.5 secondes
- **Max:** 3 secondes
- **Logique:** 95-105% du temps joueur, plafonné à 3s

### 🔥 Boss (Bot difficile)
- **Min:** 1 seconde
- **Max:** 2 secondes
- **Logique:** 50-65% du temps joueur, plafonné à 2s
- **Spécial:** 10% chance d'hésitation (+20-50%)

---

## 🧮 ADVANCED MATH (Opérations complexes)

### 🐢 Underdog
- **Min:** 4 secondes
- **Max:** 7 secondes
- **Logique:** 140-180% du temps joueur, plafonné à 7s

### ⚖️ Competitive
- **Min:** 3 secondes
- **Max:** 5 secondes
- **Logique:** 95-105% du temps joueur, plafonné à 5s

### 🔥 Boss
- **Min:** 2 secondes
- **Max:** 4 secondes
- **Logique:** 50-65% du temps joueur, plafonné à 4s

---

## 🎲 JEU DE 24 (Game24)

### 🐢 Underdog
- **Min:** 8 secondes
- **Max:** 15 secondes
- **Logique:** 140-180% du temps joueur, plafonné à 15s

### ⚖️ Competitive
- **Min:** 6 secondes
- **Max:** 12 secondes
- **Logique:** 95-105% du temps joueur, plafonné à 12s

### 🔥 Boss
- **Min:** 5 secondes
- **Max:** 10 secondes
- **Logique:** 50-65% du temps joueur, plafonné à 10s

---

## 🎪 MATADOR (5 nombres)

### 🐢 Underdog
- **Min:** 12 secondes
- **Max:** 20 secondes
- **Logique:** 140-180% du temps joueur, plafonné à 20s

### ⚖️ Competitive
- **Min:** 10 secondes
- **Max:** 17 secondes
- **Logique:** 95-105% du temps joueur, plafonné à 17s

### 🔥 Boss
- **Min:** 8 secondes
- **Max:** 15 secondes
- **Logique:** 50-65% du temps joueur, plafonné à 15s

---

## 💡 Exemples Concrets

### Cas 1: Joueur rapide sur Basic Math
- **Temps joueur:** 1.5s
- **Bot Underdog:** 2.1-2.7s → plafonné à **2-4s** ✅
- **Bot Competitive:** 1.4-1.6s → **1.5-3s** ✅
- **Bot Boss:** 0.75-0.98s → **1-2s** (minimum respecté) ✅

### Cas 2: Joueur lent sur Basic Math (AFK)
- **Temps joueur:** 20s (AFK)
- **Bot Underdog:** 28-36s → plafonné à **4s MAX** ✅
- **Bot Competitive:** 19-21s → plafonné à **3s MAX** ✅
- **Bot Boss:** 10-13s → plafonné à **2s MAX** ✅

### Cas 3: Joueur moyen sur Game24
- **Temps joueur:** 10s
- **Bot Underdog:** 14-18s → **8-15s** ✅
- **Bot Competitive:** 9.5-10.5s → **6-12s** ✅
- **Bot Boss:** 5-6.5s → **5-10s** ✅

### Cas 4: Joueur très lent sur Matador
- **Temps joueur:** 45s
- **Bot Underdog:** 63-81s → plafonné à **20s MAX** ✅
- **Bot Competitive:** 42.75-47.25s → plafonné à **17s MAX** ✅
- **Bot Boss:** 22.5-29.25s → plafonné à **15s MAX** ✅

---

## 🎯 Philosophie du Système

1. **Le bot suit le joueur** avec multiplicateurs (140-180%, 95-105%, 50-65%)
2. **MAIS respecte TOUJOURS les caps absolus** (pas de temps infinis)
3. **Les caps sont RÉALISTES et DIFFICILES** 
   - Basic Math Boss = max 2s (très rapide!)
   - Matador Underdog = max 20s (pas 5 minutes)
4. **Le Bot Boss est vraiment challengeant:**
   - Répond en 1-2s sur Basic Math
   - Répond en 5-10s sur Game24
   - A +35% de probabilité de succès

---

## 🔧 Configuration Technique

Fichier: `lib/features/game/domain/logic/bot_ai.dart`

```dart
Duration calculateDynamicDelay(GamePuzzle puzzle, {int? playerHistoricalAvgMs})
```

- Utilise `playerHistoricalAvgMs` (moyenne historique, pas temps actuel)
- Switch sur `puzzle.type` ET `difficulty` pour caps spécifiques
- Distribution Gaussienne pour variation naturelle
- 10% chance d'hésitation pour Bot Boss (réalisme)

---

## ✅ Validation

Tests unitaires dans `test/adaptive_bot_system_test.dart` :
- ✅ Underdog Basic: 2-4s
- ✅ Competitive Basic: 1.5-3s  
- ✅ Boss Basic: 1-2s
- ✅ Complex puzzles: 4-7s (Underdog)
- ✅ Game24: 5-10s (Boss)
- ✅ Matador: 10-17s (Competitive)

---

## 🎮 Impact sur le Gameplay

### Avant (problème)
- Bot attendait indéfiniment si joueur AFK
- Pas de challenge réel
- Boss = 70-85% du temps joueur (trop lent)

### Après (solution)
- Bot Boss répond en 1-2s sur Basic Math (imbattable si joueur lent!)
- Caps réalistes empêchent attentes infinies
- Vraie difficulté progressive: Underdog → Competitive → Boss
- Le Bot Boss peut VRAIMENT gagner maintenant 🔥

---

## 📊 Statistiques Attendues

### Winrate Joueur Moyen (ELO ~1200) contre Bots:
- **Underdog:** 70-80% victoires
- **Competitive:** 45-55% victoires  
- **Boss:** 20-30% victoires

### Temps Moyen de Réponse:
- **Basic Math:** 2-3s (joueur), 1-2s (Boss), 2-4s (Underdog)
- **Game24:** 8-12s (joueur), 5-10s (Boss), 8-15s (Underdog)
- **Matador:** 12-18s (joueur), 8-15s (Boss), 12-20s (Underdog)
