# Formules Mathématiques - Système de Bots Adaptatifs

## 1. Calcul du délai adaptatif du bot

### Formule générale

```
DelaiBot = MoyenneJoueur × Multiplicateur × (1 + VariationGaussienne)
```

### Multiplicateurs par difficulté

| Difficulté | Multiplicateur de base | Variation | Plage finale |
|------------|----------------------|-----------|--------------|
| **Underdog** | 1.35 | ±0.15 | 1.20 - 1.50 |
| **Competitive** | 1.00 | ±0.05 | 0.95 - 1.05 |
| **Boss** | 0.775 | ±0.075 | 0.70 - 0.85 |

### Exemple de calcul

Soit un joueur avec une moyenne de 4000ms (4 secondes) :

**Bot Underdog :**
```
DelaiBot = 4000 × 1.35 × (1 + N(0, 0.15))
        = 4000 × [1.20 à 1.50]
        = 4800ms à 6000ms
```

**Bot Competitive :**
```
DelaiBot = 4000 × 1.00 × (1 + N(0, 0.05))
        = 4000 × [0.95 à 1.05]
        = 3800ms à 4200ms
```

**Bot Boss :**
```
DelaiBot = 4000 × 0.775 × (1 + N(0, 0.075))
        = 4000 × [0.70 à 0.85]
        = 2800ms à 3400ms
```

### Variation gaussienne (Box-Muller Transform)

```dart
// Génération de nombre aléatoire avec distribution normale
double gaussianRandom() {
  final u1 = random.nextDouble();
  final u2 = random.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}
```

Propriétés :
- Moyenne (μ) = 0
- Écart-type (σ) = 1
- ~68% des valeurs entre -1 et +1
- ~95% des valeurs entre -2 et +2

### Hésitation du Bot Boss

Le bot Boss a 15% de chance de "distraire" et prendre plus de temps :

```
if (random() < 0.15) {
  DelaiBot = MoyenneJoueur × [1.3 à 1.8]
}
```

Exemple :
- Moyenne joueur = 4000ms
- Hésitation = 4000 × 1.55 = 6200ms (55% plus lent)

## 2. Calcul de l'ELO initial (Placement)

### Formule complète

```
ELO_initial = 1000 + BonusAccuracy + BonusSpeed + BonusWins + BonusDifficulty
```

Contrainte : `ELO_initial ∈ [800, 1600]`

### Composante 1 : Précision (±300 ELO)

```
BonusAccuracy = ((Précision% - 50) / 50) × 300
```

Exemples :
- 100% précision : `((100-50)/50) × 300 = +300 ELO`
- 75% précision : `((75-50)/50) × 300 = +150 ELO`
- 50% précision : `((50-50)/50) × 300 = 0 ELO`
- 25% précision : `((25-50)/50) × 300 = -150 ELO`
- 0% précision : `((0-50)/50) × 300 = -300 ELO`

### Composante 2 : Vitesse (±200 ELO)

Fonction par morceaux :

```
BonusSpeed = 
  +200          si temps ≤ 3000ms
  +100 à +200   si 3000ms < temps ≤ 5000ms
  0 à +100      si 5000ms < temps ≤ 8000ms
  -100 à 0      si 8000ms < temps ≤ 12000ms
  -200          si temps > 12000ms
```

**Détails :**

Zone 1 (3000-5000ms) :
```
BonusSpeed = 100 + ((5000 - temps) / 2000) × 100
```

Zone 2 (5000-8000ms) :
```
BonusSpeed = ((8000 - temps) / 3000) × 100
```

Zone 3 (8000-12000ms) :
```
BonusSpeed = -((temps - 8000) / 4000) × 100
```

### Composante 3 : Victoires (±100 ELO)

```
TauxVictoire = (Victoires / 3) × 100
BonusWins = ((TauxVictoire - 50) / 50) × 100
```

Exemples :
- 3 victoires (100%) : `((100-50)/50) × 100 = +100 ELO`
- 2 victoires (66.7%) : `((66.7-50)/50) × 100 = +33 ELO`
- 1 victoire (33.3%) : `((33.3-50)/50) × 100 = -33 ELO`
- 0 victoire (0%) : `((0-50)/50) × 100 = -100 ELO`

### Composante 4 : Bonus Puzzle Difficile (+50 ELO)

```
BonusDifficulty = 
  +50  si précision_Game24 > 70%
  0    sinon
```

### Exemple complet

**Profil joueur :**
- Match 1 (Basic) : 8/10 correct, temps moyen 3500ms, Victoire
- Match 2 (Complex) : 6/10 correct, temps moyen 5200ms, Défaite
- Match 3 (Game24) : 7/10 correct, temps moyen 6500ms, Victoire

**Calculs :**

1. Précision globale :
```
Total correct = 8 + 6 + 7 = 21
Total questions = 10 + 10 + 10 = 30
Précision = (21/30) × 100 = 70%

BonusAccuracy = ((70-50)/50) × 300 = +120 ELO
```

2. Vitesse moyenne :
```
Temps moyen = (3500 + 5200 + 6500) / 3 = 5066ms
Zone : 5000-8000ms

BonusSpeed = ((8000 - 5066) / 3000) × 100 = +97.8 ≈ +98 ELO
```

3. Victoires :
```
Victoires = 2/3 = 66.7%

BonusWins = ((66.7-50)/50) × 100 = +33 ELO
```

4. Bonus Game24 :
```
Précision Game24 = (7/10) × 100 = 70%
Exactement au seuil !

BonusDifficulty = +50 ELO
```

5. Total :
```
ELO_initial = 1000 + 120 + 98 + 33 + 50 = 1301 ELO
```

Rang : **Skilled** (1200-1300)

## 3. Probabilité de victoire (Formule ELO)

### Formule standard

```
P(Joueur gagne) = 1 / (1 + 10^((ELO_opponent - ELO_player) / 400))
```

### Ajustements pour bots

**Modificateur de difficulté :**

```
P_adjusted = P_base × M_difficulty
```

Où :
```
M_underdog = 1.2, clamped à [0.6, 0.95]
M_competitive = 1.0, clamped à [0.4, 0.6]
M_boss = 0.8, clamped à [0.2, 0.5]
```

**Modificateur de forme (streak) :**

```
P_final = P_adjusted + M_streak
```

Où :
```
M_streak = +0.05  si WinStreak ≥ 3 (momentum)
         = -0.05  si LoseStreak ≥ 3 (confiance basse)
         = 0      sinon
```

### Exemples

**Exemple 1 : Match équilibré**
```
ELO_player = 1200
ELO_bot = 1200
Difficulté = Competitive

P_base = 1 / (1 + 10^((1200-1200)/400))
       = 1 / (1 + 10^0)
       = 1 / 2
       = 0.50 (50%)

P_adjusted = 0.50 × 1.0 = 0.50
P_final = 0.50 (aucun streak)

Probabilité de victoire : 50%
```

**Exemple 2 : Bot Underdog**
```
ELO_player = 1200
ELO_bot = 1100  (100 ELO en dessous)
Difficulté = Underdog

P_base = 1 / (1 + 10^((1100-1200)/400))
       = 1 / (1 + 10^(-0.25))
       = 1 / (1 + 0.562)
       = 0.64 (64%)

P_adjusted = 0.64 × 1.2 = 0.768
Clamped à 0.95 max → 0.768 OK

P_final = 0.768 (76.8%)

Probabilité de victoire : 77%
```

**Exemple 3 : Bot Boss avec LoseStreak**
```
ELO_player = 1200
ELO_bot = 1300  (100 ELO au-dessus)
Difficulté = Boss
LoseStreak = 3

P_base = 1 / (1 + 10^((1300-1200)/400))
       = 1 / (1 + 10^(0.25))
       = 1 / (1 + 1.778)
       = 0.36 (36%)

P_adjusted = 0.36 × 0.8 = 0.288
M_streak = -0.05

P_final = 0.288 - 0.05 = 0.238 (23.8%)

Probabilité de victoire : 24%
```

## 4. Sélection de difficulté (Distribution probabiliste)

### Arbres de décision

**Cas : LoseStreak ≥ 3**
```
P(Underdog) = 1.0
P(Competitive) = 0.0
P(Boss) = 0.0
```

**Cas : LoseStreak = 2**
```
P(Underdog) = 0.7
P(Competitive) = 0.3
P(Boss) = 0.0
```

**Cas : WinStreak ≥ 5**
```
P(Underdog) = 0.0
P(Competitive) = 0.4
P(Boss) = 0.6
```

**Cas : WinStreak 3-4**
```
P(Underdog) = 0.0
P(Competitive) = 0.5
P(Boss) = 0.5
```

**Cas : First Ranked Match**
```
P(Underdog) = 0.7
P(Competitive) = 0.3
P(Boss) = 0.0
```

**Cas : Normal (aucun streak)**
```
P(Underdog) = 0.2
P(Competitive) = 0.6
P(Boss) = 0.2
```

### Algorithme de sélection

```
roll = random(0, 1)

if (roll < P_underdog):
  return Underdog
elif (roll < P_underdog + P_competitive):
  return Competitive
else:
  return Boss
```

## 5. Ajustement ELO du bot selon difficulté

### Formule d'ajustement

**Underdog :**
```
ELO_bot = ELO_player - (50 + random(0, 100))
        = ELO_player - [50, 150]
```

**Competitive :**
```
ELO_bot = ELO_player + (random(0, 150) - 75)
        = ELO_player ± [0, 75]
```

**Boss :**
```
ELO_bot = ELO_player + (50 + random(0, 100))
        = ELO_player + [50, 150]
```

Avec clamp final : `ELO_bot ∈ [800, 2000]`

### Exemples

**Joueur ELO 1200, Underdog :**
```
ELO_bot = 1200 - (50 + random(0, 100))
        ∈ [1050, 1150]
```

**Joueur ELO 1200, Competitive :**
```
ELO_bot = 1200 + (random(0, 150) - 75)
        ∈ [1125, 1275]
```

**Joueur ELO 1200, Boss :**
```
ELO_bot = 1200 + (50 + random(0, 100))
        ∈ [1250, 1350]
```

## 6. Distribution normale (Loi de Gauss)

### Fonction de densité de probabilité

```
f(x) = (1 / (σ√(2π))) × e^(-(x-μ)²/(2σ²))
```

Où :
- μ = moyenne = 0
- σ = écart-type = 1
- x = valeur

### Propriétés utilisées

- 68.27% des valeurs dans [μ-σ, μ+σ] = [-1, 1]
- 95.45% des valeurs dans [μ-2σ, μ+2σ] = [-2, 2]
- 99.73% des valeurs dans [μ-3σ, μ+3σ] = [-3, 3]

### Application au délai du bot

Pour un bot Competitive (variation ±5%) :

```
Variation = gaussianRandom() × 0.05
```

Distribution des variations :
- 68% entre -0.05 et +0.05 (±5%)
- 95% entre -0.10 et +0.10 (±10%)
- 99.7% entre -0.15 et +0.15 (±15%)

Donc le délai sera :
- 68% du temps : 95-105% du temps joueur
- 95% du temps : 90-110% du temps joueur

## Résumé des constantes

| Paramètre | Valeur |
|-----------|--------|
| ELO initial minimum | 800 |
| ELO initial maximum | 1600 |
| ELO initial base | 1000 |
| Bonus précision max | ±300 |
| Bonus vitesse max | ±200 |
| Bonus victoires max | ±100 |
| Bonus puzzle difficile | +50 |
| Multiplicateur Underdog | 1.35 ± 0.15 |
| Multiplicateur Competitive | 1.00 ± 0.05 |
| Multiplicateur Boss | 0.775 ± 0.075 |
| Probabilité hésitation Boss | 15% |
| Délai minimum réaliste | 1000-1500ms |
| Délai maximum | 60000ms |
| Taille fenêtre adaptation | 10 réponses |

---

**Note :** Ces formules sont paramétrables dans le code source. Ajustez les constantes selon vos besoins de game design.
