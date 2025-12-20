import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/match_model.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/models/player_stats.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../../domain/services/stats_service.dart';
import '../../domain/services/ghost_match_orchestrator.dart';
import '../../domain/logic/elo_calculator.dart';
import '../../domain/logic/progression_system.dart';
import '../../domain/logic/puzzle_generator.dart';
import '../../domain/logic/bot_ai.dart'; // Pour BotDifficulty
import '../../domain/repositories/rating_storage.dart';
import '../../presentation/providers/adaptive_providers.dart';
import '../widgets/realtime_opponent_progress.dart';
import '../widgets/rank_up_animation.dart';
import '../widgets/opponent_card.dart';

/// Page Ranked avec Waiting Room, synchronisation temps réel et fallback bot après 5s
class RankedMultiplayerPage extends ConsumerStatefulWidget {
  final String matchId;

  const RankedMultiplayerPage({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<RankedMultiplayerPage> createState() =>
      _RankedMultiplayerPageState();
}

class _RankedMultiplayerPageState extends ConsumerState<RankedMultiplayerPage> {
  final FirebaseMultiplayerService _service = FirebaseMultiplayerService();

  String? _myUid;
  List<GamePuzzle> _puzzles = [];
  int _currentPuzzleIndex = 0;
  int _myScore = 0;
  String _userAnswer = '';

  // Ghost mode (fallback après timeout - Utilise l'interface normale)
  bool _isGhostMode = false;
  GhostMatchData? _ghostData;
  Timer? _ghostResponseTimer;
  Timer? _botRaceTimer; // Timer pour la race condition bot vs joueur

  // Debug: Choisir difficulté du bot
  static const bool _debugBotDifficulty = true; // Activer pour débug
  BotDifficulty?
      _selectedBotDifficulty; // null = adaptative, sinon force difficulté

  // Countdown
  int? _countdownSeconds;
  Timer? _countdownTimer;

  // Matchmaking timeout
  Timer? _matchmakingTimeoutTimer;
  int _waitingSeconds = 0;

  // ELO
  int? _oldElo;
  int? _newElo;
  bool _eloCalculated = false;

  // Stats tracking
  final List<PuzzleSolveData> _solveHistory = [];
  int _matchStartTime = 0;
  int _puzzleStartTime = 0;
  PlayerStats? _playerStats;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
    _matchStartTime = DateTime.now().millisecondsSinceEpoch;
    _puzzleStartTime = DateTime.now().millisecondsSinceEpoch;
    _loadPlayerStats();
    _startMatchmakingTimeout();
  }

  /// Démarre le timer de 5 secondes pour le timeout matchmaking
  void _startMatchmakingTimeout() {
    print('⏱️ Démarrage timer matchmaking: 5 secondes');

    // Timer pour compter les secondes
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGhostMode) {
        setState(() {
          _waitingSeconds = timer.tick;
        });
      } else {
        timer.cancel();
      }
    });

    // Timer de timeout principal
    _matchmakingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isGhostMode) {
        _handleMatchmakingTimeout();
      }
    });
  }

  /// Gère le timeout : crée un Ghost Match (interface identique au multijoueur)
  Future<void> _handleMatchmakingTimeout() async {
    print('👻 Timeout matchmaking! Création d\'un Ghost Match...');

    // Annuler le match Firebase en attente
    try {
      await _service.leaveMatch(widget.matchId, _myUid!);
    } catch (e) {
      print('Erreur lors de l\'annulation du match: $e');
    }

    // Récupérer le profil joueur
    final profile = await RatingStorage().getProfile();
    final playerStats = _playerStats ?? const PlayerStats();

    // Créer l'orchestrateur Ghost
    final matchmaking = ref.read(adaptiveMatchmakingProvider);
    final puzzleGen = PuzzleGenerator();
    final orchestrator = GhostMatchOrchestrator(matchmaking, puzzleGen);

    // Créer le Ghost Match (Bot invisible)
    final ghostData = await orchestrator.createGhostMatch(
      playerElo: profile.currentRating,
      playerId: _myUid!,
      playerStats: playerStats,
      forcedDifficulty: _selectedBotDifficulty, // Debug: difficulté forcée
    );

    print(
        '✅ Ghost Match créé: ${ghostData.botPersona.displayName} (ELO ${ghostData.botPersona.currentRating})');

    if (mounted) {
      setState(() {
        _isGhostMode = true;
        _ghostData = ghostData;
        _puzzles = ghostData.puzzles;
        _countdownSeconds = 3;
      });

      _startCountdown();
    }
  }

  /// Annule le timer de matchmaking si un adversaire réel est trouvé
  void _cancelMatchmakingTimeout() {
    _matchmakingTimeoutTimer?.cancel();
    _matchmakingTimeoutTimer = null;
    print('✅ Adversaire trouvé! Timer matchmaking annulé');
  }

  /// Widget pour bouton de difficulté (debug)
  Widget _buildDifficultyButton(String label, BotDifficulty? difficulty) {
    final isSelected = _selectedBotDifficulty == difficulty;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedBotDifficulty = difficulty;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.grey[800],
            foregroundColor: isSelected ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlayerStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final stats = await StatsService().getPlayerStats(uid);

    setState(() {
      _playerStats = stats;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _matchmakingTimeoutTimer?.cancel();
    _ghostResponseTimer?.cancel();
    _botRaceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mode Ghost : créer un Stream local depuis le GhostMatchData
    if (_isGhostMode && _ghostData != null) {
      return _buildGhostMatchUI();
    }

    // Mode multijoueur normal avec StreamBuilder Firebase
    return StreamBuilder<DocumentSnapshot>(
      stream: _service.streamMatch(widget.matchId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        final matchData = snapshot.data!.data() as Map<String, dynamic>?;
        if (matchData == null) {
          return _buildErrorScreen('Match introuvable');
        }

        final match = MatchModel.fromMap(matchData);
        final status = match.status;
        final opponent = match.getOpponentData(_myUid!);

        // Machine à états selon le status
        switch (status) {
          case 'waiting':
            return _buildWaitingScreen();

          case 'starting':
            _cancelMatchmakingTimeout(); // Adversaire trouvé!
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCountdownIfNeeded();
            });
            return _buildCountdownScreen(opponent?.nickname);

          case 'playing':
            _cancelMatchmakingTimeout(); // Adversaire trouvé!
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPuzzlesIfNeeded(match);
            });
            return _buildGameScreen(match, opponent);

          case 'finished':
            return _buildResultScreen(match, opponent);

          default:
            return _buildErrorScreen('Statut inconnu: $status');
        }
      },
    );
  }

  /// Interface Ghost : utilise la MÊME interface que le multijoueur réel
  /// Le joueur ne peut pas distinguer un bot d'un adversaire humain
  Widget _buildGhostMatchUI() {
    final ghostMatch = _ghostData!.match;
    final opponentData = ghostMatch.player2;

    // Machine à états selon le status (identique au multiplayer)
    if (_countdownSeconds != null && _countdownSeconds! > 0) {
      // Afficher l'OpponentCard du bot pendant le countdown
      return _buildGhostCountdownScreen(opponentData);
    }

    if (_currentPuzzleIndex >= _puzzles.length) {
      return _buildResultScreen(ghostMatch, opponentData);
    }

    return _buildGameScreen(ghostMatch, opponentData);
  }

  /// Écran de countdown pour Ghost Match (affiche OpponentCard du bot)
  Widget _buildGhostCountdownScreen(PlayerData? opponentData) {
    final botPersona = _ghostData!.botPersona;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ADVERSAIRE TROUVÉ !',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            // OpponentCard avec données du bot
            if (opponentData != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: OpponentCard(
                  nickname: opponentData.nickname,
                  elo: opponentData.elo,
                  winStreak: 0,
                  loseStreak: 0,
                  totalGames: botPersona.gamesPlayed,
                  isFound: true,
                ),
              ),
            const SizedBox(height: 64),
            Text(
              _countdownSeconds != null ? '$_countdownSeconds' : '3',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'LA PARTIE COMMENCE...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: 1,
              ),
            ),
            // Debug indicator
            if (_debugBotDifficulty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bug_report,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'BOT: ${_ghostData!.bot.difficulty.toString().split('.').last.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÉCRANS
  // ============================================================

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: CircularProgressIndicator(color: Colors.cyan),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyan),
            const SizedBox(height: 32),
            Text(
              'RECHERCHE D\'UN ADVERSAIRE...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Match ID: ${widget.matchId.substring(0, 8)}...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Affichage du temps d'attente avec indication du bot
            Text(
              _waitingSeconds < 5
                  ? 'Temps d\'attente: ${_waitingSeconds}s / 5s'
                  : 'Création d\'un match contre bot...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _waitingSeconds < 5 ? Colors.cyan : Colors.orange,
              ),
            ),
            if (_waitingSeconds < 5)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                child: LinearProgressIndicator(
                  value: _waitingSeconds / 5,
                  backgroundColor: Colors.grey[800],
                  color: Colors.cyan,
                ),
              ),
            if (_waitingSeconds < 5)
              Text(
                'Un bot sera assigné après 5 secondes',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            // Debug: Sélecteur de difficulté (affiché pendant toute l'attente)
            if (_debugBotDifficulty) ...<Widget>[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.orange,
                    width: _waitingSeconds >= 5 ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bug_report,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _waitingSeconds >= 5
                              ? 'DEBUG: Difficulté Sélectionnée'
                              : 'DEBUG: Choisir Difficulté Bot',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDifficultyButton('Auto', null),
                        _buildDifficultyButton(
                            'Underdog', BotDifficulty.underdog),
                        _buildDifficultyButton(
                            'Competitive', BotDifficulty.competitive),
                        _buildDifficultyButton('Boss', BotDifficulty.boss),
                      ],
                    ),
                    if (_selectedBotDifficulty != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '✓ ${_selectedBotDifficulty == BotDifficulty.underdog ? 'Underdog' : _selectedBotDifficulty == BotDifficulty.competitive ? 'Competitive' : 'Boss'} sélectionné',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_selectedBotDifficulty == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '✓ Mode adaptatif activé',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () async {
                _matchmakingTimeoutTimer?.cancel();
                await _service.leaveMatch(widget.matchId, _myUid!);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.close, color: Colors.red),
              label: Text(
                'Annuler',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownScreen(String? opponentNickname) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _service.streamMatch(widget.matchId),
      builder: (context, snapshot) {
        PlayerData? opponentData;
        if (snapshot.hasData) {
          final matchData = snapshot.data!.data() as Map<String, dynamic>?;
          if (matchData != null) {
            final match = MatchModel.fromMap(matchData);
            opponentData = match.getOpponentData(_myUid!);
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ADVERSAIRE TROUVÉ !',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                // OpponentCard
                if (opponentData != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: FutureBuilder<PlayerStats>(
                      future: StatsService().getPlayerStats(opponentData.uid),
                      builder: (context, statsSnapshot) {
                        final stats = statsSnapshot.data;
                        return OpponentCard(
                          nickname: opponentData!.nickname,
                          elo: opponentData.elo,
                          winStreak: stats?.currentWinStreak,
                          loseStreak: stats?.currentLoseStreak,
                          totalGames: stats?.totalGames,
                          isFound: true,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 64),
                Text(
                  _countdownSeconds != null ? '$_countdownSeconds' : '3',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'LA PARTIE COMMENCE...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameScreen(MatchModel match, PlayerData? opponent) {
    if (_puzzles.isEmpty || _currentPuzzleIndex >= _puzzles.length) {
      return _buildLoadingScreen();
    }

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final myProgress = (_currentPuzzleIndex) / _puzzles.length;

    // 🏁 RACE CONDITION: Démarrer le timer du bot dès l'affichage du puzzle en Ghost Mode
    if (_isGhostMode && _botRaceTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startBotRaceTimer();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(opponent?.nickname),

            // Barre adversaire
            OpponentProgressWidget(
              opponentData: opponent,
              opponentNickname: opponent?.nickname,
            ),

            // Ma barre
            _buildMyProgressBar(myProgress),

            const SizedBox(height: 16),

            // Puzzle
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPuzzleDisplay(currentPuzzle),
                    const SizedBox(height: 48),
                    _buildAnswerDisplay(),
                  ],
                ),
              ),
            ),

            // Clavier
            _buildNumPad(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(MatchModel match, PlayerData? opponent) {
    final myData = match.getPlayerData(_myUid!);

    // Déterminer le gagnant: celui qui a terminé en PREMIER gagne
    bool iWon = false;
    bool isDraw = false;

    if (myData != null && opponent != null) {
      // Si j'ai terminé mais pas l'adversaire, je gagne
      if (myData.status == 'finished' && opponent.status != 'finished') {
        iWon = true;
      }
      // Si l'adversaire a terminé mais pas moi, je perds
      else if (opponent.status == 'finished' && myData.status != 'finished') {
        iWon = false;
      }
      // Si les deux ont terminé, celui avec le finishedAt le plus petit gagne
      else if (myData.finishedAt != null && opponent.finishedAt != null) {
        if (myData.finishedAt! < opponent.finishedAt!) {
          iWon = true;
        } else if (myData.finishedAt! > opponent.finishedAt!) {
          iWon = false;
        } else {
          // Même timestamp (très rare) -> égalité
          isDraw = true;
        }
      } else {
        // Cas par défaut: comparer les scores
        if (myData.score > opponent.score) {
          iWon = true;
        } else if (myData.score == opponent.score) {
          isDraw = true;
        }
      }
    }

    // Calculer l'ELO une seule fois
    if (!_eloCalculated) {
      _calculateEloChange(iWon, isDraw, opponent);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: iWon
                ? Colors.green.withOpacity(0.15)
                : (isDraw
                    ? Colors.orange.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  iWon ? Colors.green : (isDraw ? Colors.orange : Colors.red),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                iWon ? '🏆' : (isDraw ? '🤝' : '💀'),
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                iWon ? 'VICTOIRE !' : (isDraw ? 'ÉGALITÉ' : 'DÉFAITE'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              _buildScoreLine('VOUS', myData?.score ?? 0),
              const SizedBox(height: 8),
              _buildScoreLine(
                  opponent?.nickname ?? 'ADVERSAIRE', opponent?.score ?? 0),

              // Changement ELO
              if (_oldElo != null && _newElo != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CLASSEMENT ELO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.grey[400],
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_oldElo',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _newElo! > _oldElo!
                                ? Icons.arrow_upward
                                : (_newElo! < _oldElo!
                                    ? Icons.arrow_downward
                                    : Icons.remove),
                            color: _newElo! > _oldElo!
                                ? Colors.green
                                : (_newElo! < _oldElo!
                                    ? Colors.red
                                    : Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_newElo',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _newElo! > _oldElo!
                                  ? Colors.green
                                  : (_newElo! < _oldElo!
                                      ? Colors.red
                                      : Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${_newElo! > _oldElo! ? "+" : ""}${_newElo! - _oldElo!})',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _newElo! > _oldElo!
                                  ? Colors.green
                                  : (_newElo! < _oldElo!
                                      ? Colors.red
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text(
                  'CONTINUER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildHeader(String? opponentNickname) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RANKED',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          Text(
            'vs ${opponentNickname ?? "..."}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.orange,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher le streak
              if (_playerStats != null && _playerStats!.currentStreak != 0)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _playerStats!.currentStreak > 0
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _playerStats!.currentStreak > 0
                          ? Colors.orange
                          : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _playerStats!.currentStreak > 0
                            ? Icons.whatshot
                            : Icons.ac_unit,
                        color: _playerStats!.currentStreak > 0
                            ? Colors.orange
                            : Colors.blue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_playerStats!.currentStreak.abs()}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _playerStats!.currentStreak > 0
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _showAbandonDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyProgressBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VOUS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '$_myScore',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[900],
                  valueColor: const AlwaysStoppedAnimation(Colors.cyan),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentPuzzleIndex/${_puzzles.length}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleDisplay(GamePuzzle puzzle) {
    String question = '';
    if (puzzle is BasicPuzzle) {
      question = puzzle.question;
    } else if (puzzle is ComplexPuzzle) {
      question = puzzle.question;
    }

    return Text(
      question,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAnswerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 2)),
      ),
      child: Text(
        _userAnswer.isEmpty ? '_' : _userAnswer,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    final numbers = [
      '7',
      '8',
      '9',
      '4',
      '5',
      '6',
      '1',
      '2',
      '3',
      '-',
      '0',
      '⌫'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final value = numbers[index];
          return _buildNumButton(value);
        },
      ),
    );
  }

  Widget _buildNumButton(String value) {
    return InkWell(
      onTap: () => _onNumberPressed(value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreLine(String name, int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          '$score',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOGIQUE
  // ============================================================

  void _startCountdownIfNeeded() {
    if (_countdownTimer != null || _countdownSeconds != null) return;

    setState(() => _countdownSeconds = 3);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds! > 1) {
        setState(() => _countdownSeconds = _countdownSeconds! - 1);
      } else {
        timer.cancel();
        _service.startMatch(widget.matchId);
      }
    });
  }

  void _loadPuzzlesIfNeeded(MatchModel match) {
    if (_puzzles.isNotEmpty) return;

    setState(() {
      _puzzles = match.puzzles.map((map) => GamePuzzle.fromJson(map)).toList();
    });

    print('📚 ${_puzzles.length} puzzles chargés');
  }

  void _onNumberPressed(String value) {
    setState(() {
      if (value == '⌫') {
        if (_userAnswer.isNotEmpty) {
          _userAnswer = _userAnswer.substring(0, _userAnswer.length - 1);
        }
      } else if (value == '-') {
        if (_userAnswer.isEmpty) {
          _userAnswer = '-';
        }
      } else {
        _userAnswer += value;
      }
    });

    // Vérification automatique après chaque saisie
    _checkAnswerAutomatically();
  }

  // Vérification automatique intelligente
  void _checkAnswerAutomatically() {
    if (_userAnswer.isEmpty || _puzzles.isEmpty) return;

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final userAnswerInt = int.tryParse(_userAnswer);

    // Si la réponse peut être parsée et est correcte → valider automatiquement
    if (userAnswerInt != null && currentPuzzle.validateAnswer(userAnswerInt)) {
      // Validation automatique avec un petit délai pour éviter les validations trop rapides
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_userAnswer.isNotEmpty && mounted) {
          _submitAnswer();
        }
      });
    }
    // Si incorrecte → ne rien faire, laisser l'utilisateur continuer ou effacer
  }

  Future<void> _submitAnswer() async {
    if (_userAnswer.isEmpty || _puzzles.isEmpty) return;

    // 🏁 RACE CONDITION: Le joueur répond en premier -> ANNULER le timer du bot!
    if (_isGhostMode && _botRaceTimer != null && _botRaceTimer!.isActive) {
      print('🎯 JOUEUR GAGNE LA RACE! Timer bot annulé');
      _botRaceTimer?.cancel();
    }

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final userAnswerInt = int.tryParse(_userAnswer);
    final isCorrect =
        userAnswerInt != null && currentPuzzle.validateAnswer(userAnswerInt);

    // Tracker le solve
    final responseTime =
        DateTime.now().millisecondsSinceEpoch - _puzzleStartTime;
    final puzzleType = _getCurrentPuzzleType();

    _solveHistory.add(PuzzleSolveData(
      puzzleType: puzzleType,
      isCorrect: isCorrect,
      responseTime: responseTime,
    ));

    if (isCorrect) {
      setState(() {
        _myScore += currentPuzzle.maxPoints;
        _currentPuzzleIndex++;
        _userAnswer = '';
        _puzzleStartTime =
            DateTime.now().millisecondsSinceEpoch; // Reset pour prochain puzzle
      });

      // Mise à jour selon le mode
      if (_isGhostMode && _ghostData != null) {
        // Ghost Mode: mettre à jour le MatchModel local
        final progress = _currentPuzzleIndex / _puzzles.length;
        final updatedMatch = _ghostData!.match.copyWith(
          player1: _ghostData!.match.player1.copyWith(
            progress: progress,
            score: _myScore,
            status:
                _currentPuzzleIndex >= _puzzles.length ? 'finished' : 'playing',
          ),
        );

        _ghostData = GhostMatchData(
          bot: _ghostData!.bot,
          botPersona: _ghostData!.botPersona,
          match: updatedMatch,
          puzzles: _ghostData!.puzzles,
          playerHistoricalAvgMs: _ghostData!.playerHistoricalAvgMs,
        );

        // 🏁 DÉMARRER LA RACE pour le prochain puzzle
        if (_currentPuzzleIndex < _puzzles.length) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _startBotRaceTimer();
          });
        }

        // Vérifie si terminé
        if (_currentPuzzleIndex >= _puzzles.length) {
          final finishedMatch = _ghostData!.match.copyWith(status: 'finished');
          _ghostData = GhostMatchData(
            bot: _ghostData!.bot,
            botPersona: _ghostData!.botPersona,
            match: finishedMatch,
            puzzles: _ghostData!.puzzles,
            playerHistoricalAvgMs: _ghostData!.playerHistoricalAvgMs,
          );
        }
      } else {
        // Firebase Mode: mise à jour normale
        final progress = _currentPuzzleIndex / _puzzles.length;
        await _service.updateProgress(
          matchId: widget.matchId,
          uid: _myUid!,
          percentage: progress,
          score: _myScore,
        );

        // Vérifie si terminé
        if (_currentPuzzleIndex >= _puzzles.length) {
          await _service.finishPlayer(matchId: widget.matchId, uid: _myUid!);
        }
      }
    } else {
      // Mauvaise réponse: shake ou feedback
      setState(() => _userAnswer = '');
    }
  }

  /// RACE CONDITION: Démarre le timer du bot dès l'affichage du puzzle
  /// Le bot et le joueur jouent EN PARALLÈLE, le premier à répondre gagne
  void _startBotRaceTimer() {
    if (!_isGhostMode || _ghostData == null) return;
    if (_currentPuzzleIndex >= _puzzles.length) return;

    // Annuler tout timer précédent
    _botRaceTimer?.cancel();

    final orchestrator = _ghostData!;
    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final currentBotIndex =
        (orchestrator.match.player2?.progress ?? 0.0) * _puzzles.length;

    // Si le bot a déjà répondu à ce puzzle, ne rien faire
    if (currentBotIndex.toInt() >= _currentPuzzleIndex) {
      return;
    }

    // Calculer la réponse du bot (délai + réponse)
    final botResponse = GhostMatchOrchestrator(
      ref.read(adaptiveMatchmakingProvider),
      PuzzleGenerator(),
    ).simulateBotResponse(
      bot: orchestrator.bot,
      puzzle: currentPuzzle,
      playerHistoricalAvgMs: orchestrator.playerHistoricalAvgMs,
    );

    print(
        '🏁 RACE DÉMARRÉE! Bot va répondre dans ${botResponse.responseTimeMs}ms (${(botResponse.responseTimeMs / 1000).toStringAsFixed(1)}s)');

    // RACE CONDITION: Timer démarre MAINTENANT, en parallèle du joueur
    _botRaceTimer = Timer(
      Duration(milliseconds: botResponse.responseTimeMs),
      () {
        // Si le timer se déclenche, le bot gagne la race!
        if (!mounted || !_isGhostMode) return;

        print(
            '🤖 BOT GAGNE LA RACE! Réponse: ${botResponse.isCorrect ? "CORRECT" : "INCORRECT"}');

        setState(() {
          // Mettre à jour le score et le progrès du bot
          final newBotIndex = currentBotIndex.toInt() + 1;
          final botProgress = newBotIndex / _puzzles.length;
          final botScore = (orchestrator.match.player2?.score ?? 0) +
              (botResponse.isCorrect ? currentPuzzle.maxPoints : 0);

          final updatedMatch = _ghostData!.match.copyWith(
            player2: _ghostData!.match.player2!.copyWith(
              progress: botProgress,
              score: botScore,
              status: newBotIndex >= _puzzles.length ? 'finished' : 'playing',
            ),
          );

          // Si le bot a terminé, marquer le match comme fini
          final finalMatch = (newBotIndex >= _puzzles.length)
              ? updatedMatch.copyWith(status: 'finished')
              : updatedMatch;

          _ghostData = GhostMatchData(
            bot: _ghostData!.bot,
            botPersona: _ghostData!.botPersona,
            match: finalMatch,
            puzzles: _ghostData!.puzzles,
            playerHistoricalAvgMs: _ghostData!.playerHistoricalAvgMs,
          );

          // Passer au puzzle suivant (le joueur a perdu cette manche)
          _currentPuzzleIndex++;
          _userAnswer = '';
          _puzzleStartTime = DateTime.now().millisecondsSinceEpoch;

          // Lancer la race pour le prochain puzzle si le match continue
          if (_currentPuzzleIndex < _puzzles.length) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _startBotRaceTimer();
            });
          }
        });
      },
    );
  }

  /// Gère la réponse du bot en Ghost Mode
  /// Utilise l'orchestrateur pour simuler une réponse naturelle avec délai adaptatif
  void _handleGhostBotResponse(GamePuzzle puzzle, int playerResponseTime) {
    final orchestrator = _ghostData!;
    final currentBotIndex =
        (orchestrator.match.player2?.progress ?? 0.0) * _puzzles.length;

    // Si le bot a déjà répondu à ce puzzle, ne rien faire
    if (currentBotIndex.toInt() >= _currentPuzzleIndex) {
      return;
    }

    // Annuler tout timer précédent
    _ghostResponseTimer?.cancel();

    // Calculer la réponse du bot (sans attendre)
    final botResponse = GhostMatchOrchestrator(
      ref.read(adaptiveMatchmakingProvider),
      PuzzleGenerator(),
    ).simulateBotResponse(
      bot: orchestrator.bot,
      puzzle: puzzle,
      playerHistoricalAvgMs: orchestrator.playerHistoricalAvgMs,
    );

    print(
        '🤖 Bot va répondre dans ${botResponse.responseTimeMs}ms (${(botResponse.responseTimeMs / 1000).toStringAsFixed(1)}s)');

    // Créer un Timer qui se déclenchera après le délai calculé
    _ghostResponseTimer = Timer(
      Duration(milliseconds: botResponse.responseTimeMs),
      () {
        if (!mounted || !_isGhostMode) return;

        print(
            '✅ Bot répond: ${botResponse.isCorrect ? "CORRECT" : "INCORRECT"}');

        setState(() {
          // Mettre à jour le score et le progrès du bot
          final newBotIndex = currentBotIndex.toInt() + 1;
          final botProgress = newBotIndex / _puzzles.length;
          final botScore = (orchestrator.match.player2?.score ?? 0) +
              (botResponse.isCorrect ? puzzle.maxPoints : 0);

          final updatedMatch = _ghostData!.match.copyWith(
            player2: _ghostData!.match.player2!.copyWith(
              progress: botProgress,
              score: botScore,
              status: newBotIndex >= _puzzles.length ? 'finished' : 'playing',
            ),
          );

          // Si le bot a terminé, marquer le match comme fini
          final finalMatch = (newBotIndex >= _puzzles.length &&
                  _currentPuzzleIndex >= _puzzles.length)
              ? updatedMatch.copyWith(status: 'finished')
              : updatedMatch;

          _ghostData = GhostMatchData(
            bot: _ghostData!.bot,
            botPersona: _ghostData!.botPersona,
            match: finalMatch,
            puzzles: _ghostData!.puzzles,
            playerHistoricalAvgMs: _ghostData!.playerHistoricalAvgMs,
          );
        });
      },
    );
  }

  void _calculateEloChange(bool iWon, bool isDraw, PlayerData? opponent) async {
    if (_eloCalculated) return;
    _eloCalculated = true;

    final uid = _myUid;
    if (uid == null) return;

    try {
      // Charger les ELO actuels et calculer le nouveau
      final storage = RatingStorage();
      final myProfile = await storage.getProfile();
      final myElo = myProfile.currentRating;
      final opponentElo =
          opponent?.elo ?? 1000; // ELO de l'adversaire ou défaut

      setState(() => _oldElo = myElo);

      // Calculer le nouveau ELO
      final actualScore = iWon ? 1.0 : (isDraw ? 0.5 : 0.0);
      final newElo = EloCalculator.calculateNewRating(
        currentRating: myElo,
        opponentRating: opponentElo,
        actualScore: actualScore,
        gamesPlayed: myProfile.gamesPlayed,
      );

      setState(() => _newElo = newElo);

      // Mettre à jour le profil localement
      myProfile.currentRating = newElo;
      myProfile.gamesPlayed++;
      if (iWon) {
        myProfile.wins++;
      } else if (!isDraw) {
        myProfile.losses++;
      } else {
        myProfile.draws++;
      }
      if (myProfile.currentRating > myProfile.peakRating) {
        myProfile.peakRating = myProfile.currentRating;
      }
      await storage.saveProfile(myProfile);

      // Mettre à jour dans Firebase
      await _service.updateUserProfile(uid, elo: newElo);

      // Mettre à jour les stats
      await _updateStatsAfterMatch(iWon, isDraw, newElo, myProfile.gamesPlayed);

      // Vérifier montée de rang
      _checkRankUp(myElo, newElo, myProfile.gamesPlayed);

      print(
          '📊 ELO: $myElo → $newElo (${newElo - myElo > 0 ? "+" : ""}${newElo - myElo})');
    } catch (e) {
      print('❌ Erreur lors du calcul ELO: $e');
    }
  }

  Future<void> _updateStatsAfterMatch(
      bool isWin, bool isDraw, int newElo, int oldGamesPlayed) async {
    final uid = _myUid;
    if (uid == null) return;

    try {
      final matchDuration =
          (DateTime.now().millisecondsSinceEpoch - _matchStartTime) ~/ 1000;

      await StatsService().updateStatsAfterMatch(
        uid: uid,
        isWin: isWin,
        newElo: newElo,
        matchDuration: matchDuration,
        solves: _solveHistory,
      );

      print('✅ Stats mises à jour avec succès');
    } catch (e) {
      print('❌ Erreur mise à jour stats: $e');
    }
  }

  void _checkRankUp(int oldElo, int newElo, int oldGamesPlayed) {
    try {
      final oldProgression =
          ProgressionSystem.getProgressionData(oldElo, oldGamesPlayed);
      final newProgression =
          ProgressionSystem.getProgressionData(newElo, oldGamesPlayed + 1);

      // Montée de ligue
      if (newProgression.league != oldProgression.league) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RankUpAnimation(
                newRankName: newProgression.league.name,
                newRankIcon: newProgression.league.icon,
                rankColor: newProgression.league.color,
                onComplete: () => Navigator.of(context).pop(),
              ),
            );
          }
        });
      }

      // Nouveau milestone
      final nextMilestone = newProgression.nextMilestone;
      if (newElo >= nextMilestone.elo && oldElo < nextMilestone.elo) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                title: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Nouveau Palier !',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nextMilestone.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Récompense: ${nextMilestone.reward}',
                      style: GoogleFonts.inter(color: Colors.grey[400]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Super !',
                      style: GoogleFonts.inter(color: Colors.cyan),
                    ),
                  ),
                ],
              ),
            );
          }
        });
      }
    } catch (e) {
      print('⚠️ Erreur vérification rank-up: $e');
    }
  }

  String _getCurrentPuzzleType() {
    if (_puzzles.isEmpty || _currentPuzzleIndex >= _puzzles.length) {
      return 'basic';
    }

    final puzzle = _puzzles[_currentPuzzleIndex];
    if (puzzle is BasicPuzzle) return 'basic';
    if (puzzle is ComplexPuzzle) return 'complex';
    // Game24 et Mathadore peuvent être ajoutés plus tard
    return 'basic';
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Abandonner ?',
          style: GoogleFonts.spaceGrotesk(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous vraiment quitter ce match ?',
          style: GoogleFonts.inter(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Non', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await _service.leaveMatch(widget.matchId, _myUid!);
              if (mounted) {
                Navigator.pop(context); // Dialog
                Navigator.pop(context); // Page
              }
            },
            child: Text('Oui', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODE BOT (Fallback après timeout de matchmaking)
  // ============================================================

  /// Démarre le countdown pour le mode bot
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdownSeconds = (_countdownSeconds ?? 0) - 1;
          if (_countdownSeconds! <= 0) {
            timer.cancel();
            _countdownSeconds = null;
            // Le jeu commence
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Interface de jeu contre le bot
  /// Méthode utilitaire pour obtenir la question d'un puzzle
  String _getPuzzleQuestion(GamePuzzle puzzle) {
    if (puzzle is BasicPuzzle) {
      return '${puzzle.numberA} ${puzzle.operator} ${puzzle.numberB} = ?';
    } else if (puzzle is ComplexPuzzle) {
      return puzzle.question;
    } else if (puzzle is Game24Puzzle) {
      return puzzle.question;
    } else if (puzzle is MatadorPuzzle) {
      return puzzle.question;
    }
    return 'Question';
  }
}
