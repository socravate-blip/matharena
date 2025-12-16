# 📊 Système ELO - Comment ça fonctionne ?

## 🎯 Principe de base

Le système ELO est un système de classement qui détermine combien de points vous gagnez ou perdez après chaque partie en fonction de:
1. **Votre ELO actuel**
2. **L'ELO de votre adversaire**
3. **Le résultat du match** (victoire, défaite, égalité)

## 📐 Formule mathématique

```
Nouveau_ELO = Ancien_ELO + K × (Score_Réel - Score_Attendu)
```

### Variables:
- **K (Facteur K)**: Détermine l'ampleur des changements
  - K = 40 pour les nouveaux joueurs (< 30 parties)
  - K = 20 pour les joueurs normaux
  - K = 10 pour les joueurs élite (ELO > 2400)

- **Score_Réel**: 
  - 1.0 = Victoire
  - 0.5 = Match nul
  - 0.0 = Défaite

- **Score_Attendu**: Probabilité de victoire calculée par:
  ```
  Score_Attendu = 1 / (1 + 10^((ELO_adversaire - ELO_vous) / 400))
  ```

## 📈 Exemples concrets

### Exemple 1: Match équilibré
**Joueur A (ELO 1200) vs Joueur B (ELO 1200)**

- Score attendu = 1 / (1 + 10^0) = 0.5 (50% de chances de gagner)
- Si A gagne: 1200 + 20 × (1.0 - 0.5) = **1210** (+10)
- Si A perd: 1200 + 20 × (0.0 - 0.5) = **1190** (-10)
- Si égalité: 1200 + 20 × (0.5 - 0.5) = **1200** (0)

### Exemple 2: Victoire contre adversaire plus fort
**Joueur A (ELO 1200) vs Joueur B (ELO 1400)**

- Score attendu = 1 / (1 + 10^(200/400)) = 1 / (1 + 3.16) = **0.24** (24% de chances)
- Si A gagne: 1200 + 20 × (1.0 - 0.24) = **1215** (+15 points) 🎉
- Si A perd: 1200 + 20 × (0.0 - 0.24) = **1195** (-5 points)

**Conclusion**: Battre un adversaire plus fort rapporte beaucoup de points, perdre en coûte peu.

### Exemple 3: Victoire contre adversaire plus faible
**Joueur A (ELO 1400) vs Joueur B (ELO 1200)**

- Score attendu = 1 / (1 + 10^(-200/400)) = **0.76** (76% de chances)
- Si A gagne: 1400 + 20 × (1.0 - 0.76) = **1405** (+5 points)
- Si A perd: 1400 + 20 × (0.0 - 0.76) = **1385** (-15 points) 💀

**Conclusion**: Battre un adversaire plus faible rapporte peu, perdre coûte cher.

### Exemple 4: Nouveau joueur (K=40)
**Nouveau joueur (ELO 1200, 10 parties) vs Joueur expérimenté (ELO 1300)**

- Score attendu = 0.36 (36% de chances)
- Si victoire: 1200 + **40** × (1.0 - 0.36) = **1226** (+26 points)
- Si défaite: 1200 + **40** × (0.0 - 0.36) = **1186** (-14 points)

**Conclusion**: Les nouveaux joueurs gagnent/perdent plus de points pour ajuster rapidement leur classement.

## 🏆 Niveaux de ligue

| ELO | Ligue | Icône |
|-----|-------|-------|
| < 800 | Débutant | 🥉 |
| 800-1000 | Bronze | 🥉 |
| 1000-1200 | Argent | 🥈 |
| 1200-1400 | Or | 🥇 |
| 1400-1600 | Platine | 💎 |
| 1600-1800 | Diamant | 💎 |
| 1800-2000 | Master | 👑 |
| > 2000 | Grand Master | 🌟 |

## 🎮 Règles de victoire dans MathArena

**Le premier joueur qui termine les 25 puzzles GAGNE.**

- Si vous terminez en premier → **VICTOIRE** (même si l'autre a un meilleur score partiel)
- Si l'adversaire termine en premier → **DÉFAITE**
- Si les deux terminent exactement en même temps → **ÉGALITÉ** (très rare)

### Pourquoi ce système ?
C'est une course de vitesse ! Le but est d'être le plus rapide à résoudre correctement les 25 puzzles. Votre ELO évoluera en fonction de votre rapidité ET de la force de votre adversaire.

## 🎯 Difficulté adaptative selon l'ELO

**Le jeu s'adapte automatiquement à votre niveau !**

### 🥈 Débutant à Or (< 1600 ELO)
**Types de puzzles:**
- 70% Basic (ex: `5 + 3 = ?`)
- 30% Complex (ex: `10 - (3 + 5) = ?`)

### 💎 Diamant (1600-1799 ELO)
**Nouveaux défis débloqués:**
- 60% Basic
- 30% Complex
- **10% Jeu de 24** ⭐ (faire 24 avec 4 nombres)

### 👑 Master et plus (1800+ ELO)
**Niveau expert:**
- 50% Basic
- 25% Complex
- 15% Jeu de 24
- **10% Mathadore** 🔥 (atteindre une cible avec 5 nombres en utilisant +, -, ×, ÷)

### 📊 Calcul de l'ELO moyen
Quand deux joueurs se rencontrent, le système calcule l'**ELO moyen** des deux joueurs pour adapter la difficulté:

**Exemple:**
- Joueur A (ELO 1500) vs Joueur B (ELO 1700)
- ELO moyen = (1500 + 1700) / 2 = **1600**
- → Les deux joueurs auront des puzzles de niveau **Diamant** (avec Jeu de 24)

Cela garantit un match équilibré où les deux joueurs ont le même niveau de difficulté !

## 💡 Conseils stratégiques

### Pour gagner de l'ELO rapidement:
1. **Jouez régulièrement** (surtout pour les < 30 parties, K=40)
2. **Battez des adversaires plus forts** (+15 à +20 points)
3. **Évitez les défaites contre des adversaires plus faibles** (-15 à -20 points)

### Pour progresser efficacement:
1. **Qualité > Rapidité** au début (évitez les erreurs)
2. **Apprenez les patterns** de calcul mental
3. **Analysez vos erreurs** dans les stats
4. **Cherchez des adversaires de votre niveau** pour des matchs équilibrés

## 🔢 Tableau de gains/pertes typiques

| Diff. ELO | Victoire | Égalité | Défaite |
|-----------|----------|---------|---------|
| -200 (vous faible) | +15 | +5 | -5 |
| -100 | +13 | +3 | -7 |
| 0 (égal) | +10 | 0 | -10 |
| +100 | +7 | -3 | -13 |
| +200 (vous fort) | +5 | -5 | -15 |

*(Basé sur K=20)*

## 🎯 Objectifs ELO recommandés

- **Débutant**: Atteindre 1000 (Argent)
- **Intermédiaire**: Atteindre 1400 (Platine)
- **Avancé**: Atteindre 1800 (Master)
- **Expert**: Dépasser 2000 (Grand Master)

---

**Bon courage dans votre ascension vers le sommet ! 🚀**
