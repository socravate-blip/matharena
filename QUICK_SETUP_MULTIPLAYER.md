# 🚀 Guide Rapide - Activer le Multiplayer

## ⚡ Instructions en 5 Minutes

### Étape 1: Activer l'Authentification Anonyme

1. Ouvrez https://console.firebase.google.com
2. Sélectionnez le projet **matharena-a4da1**
3. Menu de gauche → **Authentication** (🔐)
4. Onglet **Sign-in method**
5. Cliquez sur **Anonymous** (Anonyme)
6. Activez le bouton → **Save** (Enregistrer)

✅ Vous devriez voir "Anonymous" avec un statut "Enabled"

---

### Étape 2: Configurer les Règles de Sécurité

1. Menu de gauche → **Realtime Database** (💾)
2. Onglet **Rules** (Règles)
3. **Supprimez tout** le contenu actuel
4. **Copiez-collez** ces règles:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

5. Cliquez sur **Publish** (Publier)
6. Confirmez

✅ Les règles devraient maintenant être actives

---

### Étape 3: Vérifier la Configuration

Dans la console Firebase, vérifiez:

- [ ] **Realtime Database** existe
- [ ] L'URL est: `https://matharena-a4da1-default-rtdb.europe-west1.firebasedatabase.app`
- [ ] Les règles montrent `"auth != null"`
- [ ] **Authentication** → Anonymous est "Enabled"

---

### Étape 4: Tester le Multiplayer

1. **Ouvrez un terminal** dans VS Code
2. **Lancez l'application**:
   ```powershell
   cd C:\Users\Theo\Desktop\mathed\MathArena
   flutter run -d chrome --web-port 8080
   ```

3. **Ouvrez la console** du navigateur (F12)
4. Cliquez sur **RANKED** → **BEGIN**

---

## ✅ Ce Que Vous Devriez Voir

### Dans la Console Flutter:
```
🔐 Signing in anonymously...
✅ Signed in as: AbC123XyZ...
🔍 Starting matchmaking for player: AbC123XyZ (ELO: 1000)
🔍 joinQueue called - Player: AbC123XyZ, ELO: 1000
📡 Checking queue for opponents...
➕ Adding player to queue...
✅ Player added to queue, waiting for opponent...
⏱️ Timeout reached - creating bot match...
🎮 Creating bot match: match_1234567890_bot
🤖 Bot created: Easy Eddie (ELO: 950)
💾 Saving match to Firebase...
✅ Bot match saved to Firebase
✅ Match created/joined: match_1234567890_bot
```

### Dans le Jeu:
- Message: "⚔️ Match Started! vs [Bot Name]"
- Le puzzle s'affiche
- Le timer démarre
- Vous pouvez jouer normalement

---

## ❌ Si Ça Ne Fonctionne Pas

### Erreur: "auth/operation-not-allowed"
**Solution**: L'authentification anonyme n'est pas activée
→ Retournez à l'Étape 1

### Erreur: "PERMISSION_DENIED"
**Solution**: Les règles de sécurité sont trop strictes
→ Retournez à l'Étape 2 et vérifiez que vous avez bien copié les règles

### Erreur: "Network error" ou "Failed to connect"
**Solution**: Problème de connexion Internet ou Firebase
→ Vérifiez votre connexion
→ Vérifiez que l'URL de la database est correcte dans `lib/firebase_options.dart`

### Le jeu démarre en "offline mode"
**Solution**: Firebase fonctionne en mode fallback
→ Regardez les logs dans la console Flutter pour voir l'erreur exacte
→ Vérifiez les Étapes 1 et 2

---

## 🎮 Mode Hors Ligne (Fallback)

Si Firebase ne fonctionne pas, le jeu **continue de fonctionner** en mode local:
- ✅ Vous jouez contre un bot (IA)
- ✅ Le score est sauvegardé localement
- ✅ Votre ELO est mis à jour
- ❌ Pas de matchmaking avec de vrais joueurs
- ❌ Pas de synchronisation en temps réel

**Pour réactiver le multiplayer**, suivez les étapes ci-dessus.

---

## 🔍 Debugging Avancé

### Voir les Logs Détaillés

Dans la console du navigateur (F12), tapez:
```javascript
// Activer les logs Firebase
firebase.database.enableLogging(true);
```

### Vérifier les Données Firebase

Dans la console du navigateur:
```javascript
// Voir la queue de matchmaking
firebase.database().ref('queue').once('value').then(snap => {
  console.log('Queue:', snap.val());
});

// Voir les matches actifs
firebase.database().ref('matches').once('value').then(snap => {
  console.log('Matches:', snap.val());
});
```

### Réinitialiser Firebase

Si vous voulez tout nettoyer:
1. Console Firebase → Realtime Database
2. Cliquez sur les "..." à côté de la racine
3. **Delete database** (supprimera toutes les données de test)
4. Ou supprimez manuellement les nœuds `queue` et `matches`

---

## 📚 Documentation Complète

Pour plus de détails, consultez:
- [MULTIPLAYER_DEBUG.md](MULTIPLAYER_DEBUG.md) - Guide de debugging complet
- [FIREBASE_RULES_GUIDE.md](FIREBASE_RULES_GUIDE.md) - Explication des règles de sécurité
- [FIREBASE_COMPLETE_SETUP.md](FIREBASE_COMPLETE_SETUP.md) - Setup original complet

---

## 🆘 Besoin d'Aide?

1. Vérifiez les logs dans la console Flutter
2. Vérifiez les erreurs dans la console du navigateur (F12)
3. Consultez [MULTIPLAYER_DEBUG.md](MULTIPLAYER_DEBUG.md)
4. Si le problème persiste, le mode offline continue de fonctionner

---

**🎯 Temps estimé**: 5-10 minutes pour tout configurer

**✅ Une fois configuré**, le multiplayer fonctionnera automatiquement à chaque lancement!

---

import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/match_model.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../widgets/opponent_progress_widget.dart';
import '../widgets/puzzle_display_widget.dart';
import '../widgets/number_pad_widget.dart';

class RankedPage extends StatefulWidget {
  final String matchId;
  final String userId;

  const RankedPage({
    Key? key,
    required this.matchId,
    required this.userId,
  }) : super(key: key);

  @override
  State<RankedPage> createState() => _RankedPageState();
}

class _RankedPageState extends State<RankedPage> {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();

  StreamSubscription<MatchModel>? _matchSubscription;
  MatchModel? _currentMatch;

  List<Puzzle> _puzzles = [];
  int _currentPuzzleIndex = 0;
  int _myScore = 0;
  String _userAnswer = '';

  // Countdown state
  int? _countdownSeconds;
  Timer? _countdownTimer;

  // Game state
  bool _isWaitingForOpponent = false;
  bool _isCountingDown = false;
  bool _isPlaying = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _initializeMatch();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initializeMatch() async {
    setState(() => _isWaitingForOpponent = true);

    // Listen to match updates
    _matchSubscription = _multiplayerService.getMatchStream(widget.matchId).listen(
      _onMatchUpdate,
      onError: (error) {
        debugPrint('❌ Match stream error: $error');
        _showErrorAndExit('Connection lost');
      },
    );
  }

  void _onMatchUpdate(MatchModel match) {
    setState(() => _currentMatch = match);

    // State machine based on match status
    switch (match.status) {
      case MatchStatus.waitingForPlayers:
        _handleWaitingState();
        break;

      case MatchStatus.readyToStart:
        _handleReadyState();
        break;

      case MatchStatus.playing:
        _handlePlayingState();
        break;

      case MatchStatus.finished:
        _handleFinishedState();
        break;
    }
  }

  // ============================================================
  // STATE HANDLERS
  // ============================================================

  void _handleWaitingState() {
    if (!_isWaitingForOpponent) {
      setState(() => _isWaitingForOpponent = true);
    }
  }

  void _handleReadyState() {
    // Both players are ready - start countdown
    if (!_isCountingDown && _countdownSeconds == null) {
      _startCountdown();
    }
  }

  void _handlePlayingState() {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
        _isCountingDown = false;
        _isWaitingForOpponent = false;
      });
      _loadPuzzles();
    }
  }

  void _handleFinishedState() {
    if (!_isFinished) {
      setState(() => _isFinished = true);
    }
  }

  // ============================================================
  // COUNTDOWN LOGIC
  // ============================================================

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds! > 1) {
        setState(() => _countdownSeconds = _countdownSeconds! - 1);
      } else {
        timer.cancel();
        _multiplayerService.startMatch(widget.matchId);
        // The playing state will be triggered by the stream update
      }
    });
  }

  // ============================================================
  // GAME LOGIC
  // ============================================================

  void _loadPuzzles() {
    if (_currentMatch == null) return;

    _puzzles = _currentMatch!.puzzles
        .map((map) => Puzzle.fromMap(map))
        .toList();

    debugPrint('📚 Loaded ${_puzzles.length} puzzles');
  }

  Future<void> _submitAnswer() async {
    if (_userAnswer.isEmpty || _currentMatch == null) return;

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final isCorrect = _userAnswer == currentPuzzle.answer.toString();

    if (isCorrect) {
      setState(() {
        _myScore++;
        _currentPuzzleIndex++;
        _userAnswer = '';
      });

      // Update progress in Firebase
      final progress = (_currentPuzzleIndex) / _puzzles.length;
      await _multiplayerService.updatePlayerProgress(
        matchId: widget.matchId,
        userId: widget.userId,
        progress: progress,
        score: _myScore,
      );

      // Check if finished all puzzles
      if (_currentPuzzleIndex >= _puzzles.length) {
        await _finishGame();
      }
    } else {
      // Wrong answer - shake animation or feedback
      setState(() => _userAnswer = '');
    }
  }

  Future<void> _finishGame() async {
    await _multiplayerService.markPlayerFinished(
      matchId: widget.matchId,
      userId: widget.userId,
      finalScore: _myScore,
    );

    setState(() => _isPlaying = false);
  }

  void _onNumberPressed(String number) {
    if (!_isPlaying) return;
    setState(() {
      if (number == '⌫') {
        if (_userAnswer.isNotEmpty) {
          _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        }
      } else if (number == '-') {
        if (_userAnswer.isEmpty) {
          _userAnswer = '-';
        }
      } else {
        _userAnswer += number;
      }
    });
  }

  // ============================================================
  // UI BUILDERS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isWaitingForOpponent) {
      return _buildWaitingScreen();
    }

    if (_isCountingDown) {
      return _buildCountdownScreen();
    }

    if (_isPlaying) {
      return _buildGameScreen();
    }

    if (_isFinished) {
      return _buildResultsScreen();
    }

    return const Center(child: CircularProgressIndicator());
  }

  // ---- Waiting Screen ----
  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyan),
          const SizedBox(height: 24),
          Text(
            'Waiting for opponent...',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'Match ID: ${widget.matchId}',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---- Countdown Screen ----
  Widget _buildCountdownScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'GET READY!',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '$_countdownSeconds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Game Screen ----
  Widget _buildGameScreen() {
    if (_puzzles.isEmpty || _currentPuzzleIndex >= _puzzles.length) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final myProgress = (_currentPuzzleIndex) / _puzzles.length;

    return Column(
      children: [
        // Header with scores and abandon button
        _buildHeader(),

        // Opponent progress bar
        OpponentProgressWidget(
          matchId: widget.matchId,
          currentUserId: widget.userId,
        ),

        // My progress bar
        _buildMyProgress(myProgress),

        const Spacer(),

        // Puzzle display
        PuzzleDisplayWidget(
          puzzle: currentPuzzle,
          userAnswer: _userAnswer,
        ),

        const Spacer(),

        // Number pad
        NumberPadWidget(
          onNumberPressed: _onNumberPressed,
          onSubmit: _submitAnswer,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    final myData = _currentMatch?.getPlayerData(widget.userId);
    final opponentData = _currentMatch?.getOpponentData(widget.userId);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RANKED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'vs ${opponentData?.nickname ?? "???"}',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => _showAbandonDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProgress(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOU',
                style: TextStyle(color: Colors.cyan, fontSize: 14),
              ),
              Text(
                '$_myScore',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '$_currentPuzzleIndex/${_puzzles.length}',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---- Results Screen ----
  Widget _buildResultsScreen() {
    if (_currentMatch == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final myData = _currentMatch!.getPlayerData(widget.userId);
    final opponentData = _currentMatch!.getOpponentData(widget.userId);

    final iWon = myData!.score > (opponentData?.score ?? 0);
    final isDraw = myData.score == (opponentData?.score ?? 0);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: iWon ? Colors.green.shade700 : (isDraw ? Colors.orange.shade700 : Colors.red.shade700),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🏆',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              iWon ? 'VICTORY!' : (isDraw ? 'DRAW!' : 'DEFEAT'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildScoreLine('YOU', myData.score),
            const SizedBox(height: 8),
            _buildScoreLine(opponentData?.nickname ?? 'Opponent', opponentData?.score ?? 0),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreLine(String name, int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: TextStyle(color: Colors.white, fontSize: 18)),
        Text('$score', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Match?'),
        content: const Text('Are you sure you want to leave this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _multiplayerService.leaveMatch(widget.matchId, widget.userId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit match
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showErrorAndExit(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/models/match_model.dart';
import '../../domain/services/firebase_multiplayer_service.dart';

class OpponentProgressWidget extends StatelessWidget {
  final String matchId;
  final String currentUserId;

  const OpponentProgressWidget({
    Key? key,
    required this.matchId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final multiplayerService = FirebaseMultiplayerService();

    return StreamBuilder<PlayerMatchData?>(
      stream: multiplayerService.getOpponentProgressStream(matchId, currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildPlaceholder();
        }

        final opponentData = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        opponentData.nickname.toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${opponentData.score}',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: opponentData.progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPPONENT',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
