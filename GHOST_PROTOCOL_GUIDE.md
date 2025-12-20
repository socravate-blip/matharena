# 👻 Ghost Protocol: Système de Bot Invisible

## 🎯 Objectif

Le joueur **NE DOIT JAMAIS** savoir qu'il joue contre un bot. L'expérience doit être identique à un match multijoueur réel.

## 🏗️ Architecture

### 1. BotPersonaGenerator
**Fichier:** `lib/features/game/domain/logic/bot_persona_generator.dart`

Génère des faux profils de joueurs indiscernables de vrais humains :

```dart
final botPersona = BotPersonaGenerator.generate(
  playerElo: 1200,
  difficulty: 'competitive',
);

// Résultat :
// - displayName: "Alex42" (pool de 40+ noms)
// - currentRating: 1185 (±75 du joueur)
// - peakRating: 1320
// - gamesPlayed: 247
// - wins: 128 (win rate ~52%)
// - avatarId: 12
```

**Caractéristiques:**
- Noms réalistes (Alex, Jordan, Taylor...)
- Suffixes variés ("", "123", "GG", "TTV"...)
- ELO crédible selon difficulté :
  - Underdog: -150 à -50
  - Competitive: -75 à +75
  - Boss: +50 à +150
- Stats cohérentes (win rate basé sur ELO)
- Faux user ID au format Firebase (28 caractères)

### 2. BotAI avec Caps Réalistes
**Fichier:** `lib/features/game/domain/logic/bot_ai.dart`

**NOUVEAU:** Temps de réponse bornés (Anti-AFK)

```dart
// AVANT (Problème):
// Si joueur AFK 1h → Bot attend 1h

// APRÈS (Solution):
// Caps de temps réalistes par type de puzzle
```

#### Caps de Temps par Type

| Type | Min | Max | Raison |
|------|-----|-----|--------|
| BasicPuzzle | 1s | 8s | Simple calcul |
| ComplexPuzzle | 2s | 20s | Multi-opérations |
| Game24 | 5s | 45s | Recherche combinatoire |
| Matador | 8s | 60s | Complexité élevée |

#### Logique de Calcul

```dart
Duration calculateDynamicDelay(GamePuzzle puzzle, {
  int? playerHistoricalAvgMs // <-- HISTORIQUE, pas temps actuel!
}) {
  // 1. Caps réalistes selon type
  final maxCap = puzzle.type == PuzzleType.basic ? 8000 : 20000;
  
  // 2. Moyenne historique du joueur (pas son temps actuel)
  final playerAvg = playerHistoricalAvgMs ?? 5000;
  
  // 3. Plafonner si joueur anormalement lent
  final cappedAvg = playerAvg.clamp(minCap, maxCap * 1.2);
  
  // 4. Distribution Gaussienne (pas uniforme)
  final variation = _gaussianRandom() * variationRange;
  
  // 5. Multiplier selon difficulté
  final delay = cappedAvg * (baseMultiplier + variation);
  
  // 6. CAPS ABSOLU: Jamais au-delà du max
  return Duration(milliseconds: delay.clamp(minCap, maxCap));
}
```

**Avantages:**
- ✅ Si joueur AFK → Bot répond quand même (max 8-60s selon type)
- ✅ Variation naturelle (Gaussienne, pas uniforme)
- ✅ Boss bot "hésite" parfois (15% chance de +30-80% temps)

### 3. GhostMatchOrchestrator
**Fichier:** `lib/features/game/domain/services/ghost_match_orchestrator.dart`

Orchestre la création d'un faux match Firebase-like.

```dart
final ghostData = await orchestrator.createGhostMatch(
  playerElo: 1200,
  playerId: currentUserId,
  playerStats: myStats,
);

// Retourne:
// - bot: BotAI configuré
// - botPersona: Faux profil complet
// - match: MatchModel identique à Firebase
// - puzzles: Liste de GamePuzzle
// - playerHistoricalAvgMs: Temps moyen historique
```

**Méthodes clés:**

#### createGhostMatch()
1. Sélectionne difficulté (AdaptiveMatchmaking)
2. Crée BotAI
3. Génère BotPersona
4. Génère puzzles
5. Crée faux MatchModel
6. Calcule moyenne historique joueur

#### simulateBotResponse()
```dart
Future<BotResponse> simulateBotResponse({
  required BotAI bot,
  required GamePuzzle puzzle,
  required int playerHistoricalAvgMs,
}) async {
  // 1. Calcul délai adaptatif
  final delay = bot.calculateDynamicDelay(
    puzzle,
    playerHistoricalAvgMs: playerHistoricalAvgMs,
  );
  
  // 2. Attente (simule réflexion)
  await Future.delayed(delay);
  
  // 3. Succès/échec basé sur probabilité
  final success = bot._random.nextDouble() < probability;
  
  return BotResponse(
    isCorrect: success,
    responseTimeMs: delay.inMilliseconds,
  );
}
```

## 🔄 Flow d'Intégration

### Scénario: Timeout Matchmaking (5 secondes sans adversaire)

```dart
// Dans RankedMultiplayerPage ou équivalent

void _handleMatchmakingTimeout() async {
  // 1. Annuler la recherche Firebase
  await _firebaseService.leaveMatch(matchId, myUid);
  
  // 2. Créer un Ghost Match
  final ghostData = await _ghostOrchestrator.createGhostMatch(
    playerElo: myProfile.currentRating,
    playerId: myUid,
    playerStats: myProfile,
  );
  
  // 3. AUCUNE UI SPÉCIFIQUE - On utilise le système existant
  // Le MatchModel est identique à Firebase
  setState(() {
    _currentMatch = ghostData.match;
    _isGhostMode = true; // Flag interne uniquement
    _ghostBot = ghostData.bot;
    _playerAvgMs = ghostData.playerHistoricalAvgMs;
  });
  
  // 4. L'UI affiche normalement:
  // - OpponentCard avec botPersona.displayName
  // - Scores temps réel
  // - Progression
  // Le joueur ne voit AUCUNE différence
}
```

### Gestion des Réponses Bot

```dart
// Quand le joueur répond à un puzzle
void _onPlayerAnswer(int puzzleIndex, dynamic answer) {
  // 1. Traiter la réponse joueur
  final isCorrect = _validateAnswer(answer);
  if (isCorrect) {
    _myScore++;
  }
  
  // 2. Si Ghost Mode: Bot répond
  if (_isGhostMode) {
    _ghostOrchestrator.simulateBotResponse(
      bot: _ghostBot!,
      puzzle: _puzzles[puzzleIndex],
      playerHistoricalAvgMs: _playerAvgMs,
    ).then((botResponse) {
      setState(() {
        if (botResponse.isCorrect) {
          _opponentScore++;
        }
        // Mettre à jour match.player2.score
        _currentMatch = _currentMatch.copyWith(
          player2: _currentMatch.player2!.copyWith(
            score: _opponentScore,
            progress: (puzzleIndex + 1) / _puzzles.length,
          ),
        );
      });
    });
  }
  
  // L'UI ne change pas, elle affiche juste _opponentScore
}
```

## 🎨 UI: Transparence Totale

### OpponentCard (Inchangé)

```dart
OpponentCard(
  opponentName: match.player2!.nickname, // "Alex42"
  opponentElo: match.player2!.elo, // 1185
  opponentScore: match.player2!.score, // 3
  progress: match.player2!.progress, // 0.4
)
```

**Le joueur voit:**
- Nom : "Alex42"
- ELO : 1185
- Score : 3
- Progression : 40%

**Identique à un vrai joueur Firebase !**

## 🔒 Sécurité Ghost Protocol

### Règles Strictes

1. **Jamais de mention "Bot" dans l'UI**
   - ❌ Pas de "🤖" icône
   - ❌ Pas de "vs Bot" affiché
   - ❌ Pas d'interface différente

2. **Flag interne uniquement**
   ```dart
   bool _isGhostMode = false; // Privé, jamais exposé
   BotPersona.isBot = true; // Privé, jamais dans toFirestoreMap()
   ```

3. **Délais réalistes obligatoires**
   - Bot ne répond jamais instantanément (min 1-8s)
   - Bot ne dépasse jamais les caps humains
   - Variation gaussienne pour naturel

4. **Stats et ELO crédibles**
   - Win rate cohérent avec ELO
   - Peak rating > current rating
   - Games played raisonnable (10-500)

## 📊 Avantages du Système

### 1. Immersion Parfaite
- Joueur pense toujours jouer contre un humain
- Pas de "stigma" de jouer contre un bot
- Engagement maximal

### 2. Disponibilité Garantie
- Match disponible en 5 secondes max
- Pas d'attente infinie
- Jouabilité 24/7

### 3. Difficulté Adaptative Invisible
- Bot s'adapte au niveau du joueur
- Underdog pour remonter le moral
- Boss pour challenge après win streak
- Le joueur ne sait pas que c'est adaptatif

### 4. Anti-Exploitation
- Caps de temps empêchent AFK farming
- Bot continue à jouer normalement
- ELO gain/loss authentique

## 🧪 Tests Ghost Protocol

### Checklist Invisibilité

- [ ] Lancez un match bot
- [ ] Vérifiez OpponentCard : Affiche nom réaliste
- [ ] Vérifiez ELO : Proche du vôtre
- [ ] Observez temps de réponse : Variable, naturel
- [ ] Vérifiez score : Bot gagne/perd de façon crédible
- [ ] **Pouvez-vous deviner que c'est un bot ?**
  - Si OUI → ❌ Ghost Protocol échoué
  - Si NON → ✅ Mission accomplie

### Test Anti-AFK

1. Lancez un match bot
2. NE RÉPONDEZ PAS pendant 30 secondes
3. ✅ Le bot doit répondre quand même (max 8-20s selon type)
4. ✅ Le bot ne doit pas attendre 30s

### Test Caps

```dart
test('Bot respects time caps', () {
  final bot = BotAI.matchingSkill(1200, difficulty: BotDifficulty.underdog);
  final puzzle = BasicPuzzle(...);
  
  // Simuler joueur TRÈS lent (1 heure)
  final delay = bot.calculateDynamicDelay(
    puzzle,
    playerHistoricalAvgMs: 3600000, // 1 heure
  );
  
  // Le bot ne doit JAMAIS dépasser 8s pour BasicPuzzle
  expect(delay.inMilliseconds, lessThan(8000));
});
```

## 📝 Migration depuis l'Ancien Système

### À Supprimer

- ❌ `_buildBotGameScreen()` dans ranked_multiplayer_page
- ❌ `_buildBotResultScreen()`
- ❌ Toute logique UI spécifique bot
- ❌ `BotMatchData` dans matchmaking_timeout_service

### À Conserver/Adapter

- ✅ BotAI (avec nouvelles caps)
- ✅ AdaptiveMatchmaking
- ✅ Système de timeout (5s)
- ✅ OpponentCard, RealTimeProgress widgets

### Nouvelle Architecture

```
ranked_multiplayer_page.dart
├─ Firebase Matchmaking (5s)
│   ├─ Adversaire trouvé → Match normal
│   └─ Timeout → createGhostMatch()
│
└─ Ghost Mode (transparent)
    ├─ MatchModel identique
    ├─ OpponentCard avec BotPersona
    ├─ Score temps réel
    └─ ELO calculé normalement
```

## 🚀 Prochaines Étapes

1. **Intégrer** GhostMatchOrchestrator dans le timeout handler
2. **Retirer** toute UI spécifique bot
3. **Tester** invisibilité totale
4. **Monitorer** taux de détection (analytics)
5. **Ajuster** caps si nécessaire

---

**Status:** ✅ Architecture complète  
**Version:** 2.0 (Ghost Protocol)  
**Last Updated:** 2024
