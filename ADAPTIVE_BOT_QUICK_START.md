# Guide de Démarrage Rapide - Système de Bots Adaptatifs

## 🚀 Configuration initiale (3 étapes)

### 1. Ajouter les providers à votre app

Dans votre `main.dart` ou widget racine :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/game/presentation/providers/adaptive_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 2. Gérer le flow nouveau joueur

```dart
class NewPlayerFlow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementState = ref.watch(placementStateProvider);
    
    if (!placementState.isComplete) {
      // Afficher les matchs de placement (1/3, 2/3, 3/3)
      return PlacementMatchesScreen();
    } else {
      // Afficher l'écran de résultats
      return PlacementResultsScreen(
        elo: placementState.calculatedElo!,
      );
    }
  }
}
```

### 3. Créer un match avec bot adaptatif

```dart
class RankedMatchScreen extends ConsumerStatefulWidget {
  @override
  _RankedMatchScreenState createState() => _RankedMatchScreenState();
}

class _RankedMatchScreenState extends ConsumerState<RankedMatchScreen> {
  BotAI? bot;
  
  @override
  void initState() {
    super.initState();
    _setupMatch();
  }
  
  void _setupMatch() {
    // Récupérer les stats du joueur (depuis Firebase, par exemple)
    final playerStats = getPlayerStats(); // Votre méthode
    final playerElo = getPlayerElo();      // Votre méthode
    final isFirstRanked = playerStats.totalGames == 0;
    
    // Créer le bot adaptatif
    final botRequest = BotOpponentRequest(
      playerElo: playerElo,
      stats: playerStats,
      isFirstRankedMatch: isFirstRanked,
    );
    
    setState(() {
      bot = ref.read(botOpponentProvider(botRequest));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (bot == null) return CircularProgressIndicator();
    
    return GameScreen(bot: bot!);
  }
}
```

## 📝 Utilisation pendant une partie

### Enregistrer les temps de réponse du joueur

```dart
class GameScreen extends StatefulWidget {
  final BotAI bot;
  const GameScreen({required this.bot});
  
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  
  @override
  void initState() {
    super.initState();
    _startQuestion();
  }
  
  void _startQuestion() {
    _stopwatch.reset();
    _stopwatch.start();
  }
  
  void _onPlayerAnswer() {
    _stopwatch.stop();
    final responseTime = _stopwatch.elapsedMilliseconds;
    
    // Enregistrer pour l'adaptation du bot
    widget.bot.recordPlayerResponseTime(responseTime);
    
    // Le bot répond maintenant
    _botResponds();
  }
  
  Future<void> _botResponds() async {
    final puzzle = getCurrentPuzzle(); // Votre méthode
    
    // Le bot calcule son délai adaptatif
    final delay = widget.bot.calculateDynamicDelay(puzzle);
    
    // Afficher "Bot est en train de réfléchir..."
    showBotThinking();
    
    // Attendre
    await Future.delayed(delay);
    
    // Le bot donne sa réponse
    final answer = widget.bot.solveArithmetic(puzzle);
    showBotAnswer(answer);
  }
}
```

## 🎯 Scénarios d'utilisation courants

### Scénario 1 : Placement complet (nouveau joueur)

```dart
// Dans votre écran de match de placement
void _completePlacementMatch({
  required int matchNumber,
  required int correctAnswers,
  required int totalQuestions,
  required List<int> responseTimes,
  required bool won,
}) {
  final puzzleType = PlacementManager.getPuzzleTypeForMatch(matchNumber);
  
  final result = PlacementMatchResult(
    matchNumber: matchNumber,
    puzzleType: puzzleType,
    correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    responseTimes: responseTimes,
    won: won,
  );
  
  ref.read(placementStateProvider.notifier).recordMatchResult(result);
  
  // Vérifier si c'est le dernier match
  final state = ref.read(placementStateProvider);
  if (state.isComplete) {
    // Afficher l'ELO initial et rediriger vers ranked
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlacementCompleteScreen(
          elo: state.calculatedElo!,
        ),
      ),
    );
  } else {
    // Passer au match suivant
    _startNextPlacementMatch();
  }
}
```

### Scénario 2 : Premier match classé (First Win Experience)

```dart
void _startFirstRankedMatch() {
  final stats = getPlayerStats();
  final elo = getPlayerElo();
  
  // Le système garantit un bot facile (Underdog ou Competitive)
  final bot = ref.read(
    botOpponentProvider(
      BotOpponentRequest(
        playerElo: elo,
        stats: stats,
        isFirstRankedMatch: true,  // ⚠️ Important !
      ),
    ),
  );
  
  // Le bot ne sera JAMAIS Boss
  assert(bot.difficulty != BotDifficulty.boss);
  
  // Afficher un message de bienvenue
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Premier match classé ! 🎉'),
      content: Text('Bonne chance ! Le système est conçu pour vous donner une belle première expérience.'),
    ),
  );
  
  startGame(bot);
}
```

### Scénario 3 : Joueur en LoseStreak (Récupération psychologique)

```dart
void _handleLoseStreak() {
  final stats = getPlayerStats();
  
  if (stats.currentLoseStreak >= 3) {
    // Le système force automatiquement un bot Underdog
    final bot = ref.read(
      botOpponentProvider(
        BotOpponentRequest(
          playerElo: getPlayerElo(),
          stats: stats,
          isFirstRankedMatch: false,
        ),
      ),
    );
    
    // bot.difficulty sera Underdog (100% garanti)
    print('LoseStreak détecté ! Bot Underdog assigné pour boost de confiance');
  }
}
```

### Scénario 4 : Joueur en WinStreak (Maintien du challenge)

```dart
void _handleWinStreak() {
  final stats = getPlayerStats();
  
  if (stats.currentWinStreak >= 5) {
    // Le système privilégie les bots Boss ou Competitive
    final bot = ref.read(
      botOpponentProvider(
        BotOpponentRequest(
          playerElo: getPlayerElo(),
          stats: stats,
          isFirstRankedMatch: false,
        ),
      ),
    );
    
    // 60% chance Boss, 40% chance Competitive
    print('WinStreak détecté ! Augmentation du challenge');
  }
}
```

## 🔧 Debug et monitoring

### Logger les décisions du matchmaking

```dart
void _logMatchmaking() {
  final matchmaking = ref.read(adaptiveMatchmakingProvider);
  final stats = getPlayerStats();
  final bot = getCurrentBot();
  
  final summary = matchmaking.getMatchSummary(
    playerElo: getPlayerElo(),
    bot: bot,
    stats: stats,
    isFirstRankedMatch: false,
  );
  
  print('=== Match Summary ===');
  print('Player ELO: ${summary['playerElo']}');
  print('Bot: ${summary['botName']} (${summary['botElo']} ELO)');
  print('Difficulty: ${summary['botDifficulty']}');
  print('Player Streak: ${summary['playerStreak']}');
  print('Win Probability: ${(summary['predictedWinRate'] * 100).toStringAsFixed(1)}%');
  print('=====================');
}
```

### Tester manuellement les difficultés

```dart
// Force un bot Underdog (pour tester)
final botUnderdog = BotAI.matchingSkill(
  1200, 
  difficulty: BotDifficulty.underdog
);

// Force un bot Boss (pour tester)
final botBoss = BotAI.matchingSkill(
  1200, 
  difficulty: BotDifficulty.boss
);

// Simuler des temps de réponse
botBoss.recordPlayerResponseTime(3000);
botBoss.recordPlayerResponseTime(3500);
botBoss.recordPlayerResponseTime(2800);

// Voir l'adaptation
final delay = botBoss.calculateDynamicDelay(puzzle);
print('Bot Boss répondra en ${delay.inMilliseconds}ms');
// Output: ~2100-2500ms (70-85% de 3100ms moyenne)
```

## ⚠️ Points d'attention

### 1. Toujours enregistrer les temps de réponse

```dart
// ❌ MAUVAIS : Le bot ne peut pas s'adapter
void onAnswer() {
  // ... logique sans enregistrer le temps
}

// ✅ BON : Le bot apprend et s'adapte
void onAnswer() {
  final responseTime = stopwatch.elapsedMilliseconds;
  bot.recordPlayerResponseTime(responseTime);
}
```

### 2. Vérifier que le placement est complet avant ranked

```dart
void startRanked() {
  final hasCompleted = ref.read(hasCompletedPlacementProvider);
  
  if (!hasCompleted) {
    // Rediriger vers placement
    Navigator.push(context, PlacementMatchesScreen());
    return;
  }
  
  // OK, continuer vers ranked
}
```

### 3. Sauvegarder l'état de placement dans Firebase

```dart
void savePlacementState() {
  final state = ref.read(placementStateProvider);
  
  FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set({
      'placement': {
        'completed': state.isComplete,
        'matchesCompleted': state.matchesCompleted,
        'calculatedElo': state.calculatedElo,
        'results': state.results.map((r) => {
          'matchNumber': r.matchNumber,
          'puzzleType': r.puzzleType.toString(),
          'correctAnswers': r.correctAnswers,
          'totalQuestions': r.totalQuestions,
          'responseTimes': r.responseTimes,
          'won': r.won,
        }).toList(),
      }
    }, SetOptions(merge: true));
}
```

## 📊 Analytics et métriques

### Suivre l'engagement des joueurs

```dart
void trackPlayerEngagement() {
  final stats = getPlayerStats();
  final matchmaking = ref.read(adaptiveMatchmakingProvider);
  
  // Analyser la distribution des difficultés
  final difficultyDistribution = {
    'underdog': 0,
    'competitive': 0,
    'boss': 0,
  };
  
  // Suivre les win rates par difficulté
  final winRateByDifficulty = {
    'underdog': 0.85,  // Exemple : 85% win rate
    'competitive': 0.52,
    'boss': 0.28,
  };
  
  // Envoyer à Firebase Analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'player_performance',
    parameters: {
      'total_games': stats.totalGames,
      'win_rate': stats.winRate,
      'current_streak': stats.currentStreak,
      'avg_response_time': stats.avgResponseTime,
    },
  );
}
```

## 🎨 Personnalisation UI

### Afficher la difficulté du bot

```dart
Widget buildBotDifficultyBadge(BotDifficulty difficulty) {
  final config = {
    BotDifficulty.underdog: {
      'icon': Icons.trending_down,
      'color': Colors.green,
      'label': 'Facile',
    },
    BotDifficulty.competitive: {
      'icon': Icons.trending_flat,
      'color': Colors.orange,
      'label': 'Égal',
    },
    BotDifficulty.boss: {
      'icon': Icons.trending_up,
      'color': Colors.red,
      'label': 'Difficile',
    },
  }[difficulty]!;
  
  return Chip(
    avatar: Icon(config['icon'] as IconData, size: 16),
    label: Text(config['label'] as String),
    backgroundColor: config['color'] as Color,
  );
}
```

### Afficher la progression du placement

```dart
Widget buildPlacementProgress(PlacementState state) {
  return Column(
    children: [
      LinearProgressIndicator(
        value: state.matchesCompleted / 3,
      ),
      SizedBox(height: 8),
      Text('Match ${state.matchesCompleted + 1}/3'),
      if (state.results.isNotEmpty)
        ...state.results.map((r) => 
          ListTile(
            leading: Icon(r.won ? Icons.check : Icons.close),
            title: Text('Match ${r.matchNumber}'),
            subtitle: Text('${r.accuracy.toStringAsFixed(1)}% précision'),
          ),
        ),
    ],
  );
}
```

## ✅ Checklist d'intégration

- [ ] Ajouter les imports nécessaires
- [ ] Configurer ProviderScope dans main.dart
- [ ] Créer l'écran de placement (3 matchs)
- [ ] Implémenter l'enregistrement des temps de réponse
- [ ] Intégrer le système de création de bots adaptatifs
- [ ] Gérer le First Win Experience
- [ ] Sauvegarder l'état dans Firebase
- [ ] Ajouter les analytics
- [ ] Tester les différents scénarios (LoseStreak, WinStreak, etc.)
- [ ] Personnaliser l'UI selon vos besoins

## 📚 Ressources complémentaires

- **Guide complet** : `ADAPTIVE_BOT_SYSTEM_GUIDE.md`
- **Exemples d'intégration** : `lib/features/game/examples/adaptive_bot_integration_example.dart`
- **Code source** :
  - Bot AI : `lib/features/game/domain/logic/bot_ai.dart`
  - Placement : `lib/features/game/domain/logic/placement_manager.dart`
  - Matchmaking : `lib/features/game/domain/logic/adaptive_matchmaking.dart`
  - Providers : `lib/features/game/presentation/providers/adaptive_providers.dart`

## 🆘 Support

Pour toute question ou problème :
1. Consultez le guide complet
2. Vérifiez les exemples d'intégration
3. Activez les logs de debug
4. Testez chaque scénario individuellement

Bon développement ! 🚀
