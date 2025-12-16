import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/match_model.dart';
import '../../domain/models/puzzle.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../../domain/logic/elo_calculator.dart';
import '../../domain/repositories/rating_storage.dart';
import '../widgets/realtime_opponent_progress.dart';

/// Page Ranked avec Waiting Room et synchronisation temps réel
class RankedMultiplayerPage extends StatefulWidget {
  final String matchId;

  const RankedMultiplayerPage({
    super.key,
    required this.matchId,
  });

  @override
  State<RankedMultiplayerPage> createState() => _RankedMultiplayerPageState();
}

class _RankedMultiplayerPageState extends State<RankedMultiplayerPage> {
  final FirebaseMultiplayerService _service = FirebaseMultiplayerService();

  String? _myUid;
  List<GamePuzzle> _puzzles = [];
  int _currentPuzzleIndex = 0;
  int _myScore = 0;
  String _userAnswer = '';

  // Countdown
  int? _countdownSeconds;
  Timer? _countdownTimer;

  // ELO
  int? _oldElo;
  int? _newElo;
  bool _eloCalculated = false;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCountdownIfNeeded();
            });
            return _buildCountdownScreen(opponent?.nickname);

          case 'playing':
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
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () async {
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
            const SizedBox(height: 16),
            Text(
              'vs ${opponentNickname ?? "???"}',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.orange,
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
  }

  Widget _buildGameScreen(MatchModel match, PlayerData? opponent) {
    if (_puzzles.isEmpty || _currentPuzzleIndex >= _puzzles.length) {
      return _buildLoadingScreen();
    }

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final myProgress = (_currentPuzzleIndex) / _puzzles.length;

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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => _showAbandonDialog(),
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

    final currentPuzzle = _puzzles[_currentPuzzleIndex];
    final userAnswerInt = int.tryParse(_userAnswer);
    final isCorrect =
        userAnswerInt != null && currentPuzzle.validateAnswer(userAnswerInt);

    if (isCorrect) {
      setState(() {
        _myScore += currentPuzzle.maxPoints;
        _currentPuzzleIndex++;
        _userAnswer = '';
      });

      // Mise à jour Firebase
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
    } else {
      // Mauvaise réponse: shake ou feedback
      setState(() => _userAnswer = '');
    }
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

      print(
          '📊 ELO: $myElo → $newElo (${newElo - myElo > 0 ? "+" : ""}${newElo - myElo})');
    } catch (e) {
      print('❌ Erreur lors du calcul ELO: $e');
    }
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
}
