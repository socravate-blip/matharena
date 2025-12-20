import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/logic/bot_persona_generator.dart';
import '../domain/services/ghost_match_orchestrator.dart';
import '../domain/logic/matchmaking_logic.dart';
import '../domain/models/match_model.dart';
import '../domain/repositories/rating_storage.dart';

/// Exemple d'intégration du Ghost Protocol dans une page de matchmaking
/// 
/// Ce snippet montre comment intégrer le système de bot invisible
/// dans le flux de matchmaking existant, sans créer d'UI spécifique.
class GhostProtocolIntegrationExample {
  
  /// Exemple 1: Gestion du Timeout Matchmaking
  /// 
  /// Quand aucun adversaire n'est trouvé en 5 secondes,
  /// on crée un Ghost Match transparent pour le joueur
  static Future<void> handleMatchmakingTimeout({
    required BuildContext context,
    required String currentMatchId,
    required String myUserId,
    required RatingStorage storage,
  }) async {
    print('⚡ TIMEOUT! Pas d\'adversaire trouvé en 5s');
    
    // 1. Récupérer le profil du joueur
    final myProfile = await storage.getProfile();
    
    // 2. Créer l'orchestrateur Ghost
    final matchmaking = MatchmakingLogic();
    final orchestrator = GhostMatchOrchestrator(matchmaking);
    
    // 3. Créer le Ghost Match (Invisible pour le joueur)
    final ghostData = await orchestrator.createGhostMatch(
      playerElo: myProfile.currentRating,
      playerId: myUserId,
      playerStats: myProfile,
    );
    
    print('👻 Ghost Match créé:');
    print('   - Bot: ${ghostData.botPersona.displayName}');
    print('   - Bot ELO: ${ghostData.botPersona.currentRating}');
    print('   - Difficulté: ${ghostData.bot.difficulty}');
    
    // 4. AUCUNE INTERFACE SPÉCIFIQUE
    // On navigue vers la même page que pour un match normal
    // Le MatchModel est structurellement identique à Firebase
    
    // L'UI ne sait pas que c'est un bot !
    // Elle affiche OpponentCard avec ghostData.match.player2 (le bot)
  }
  
  /// Exemple 2: Gestion des Réponses Bot en Temps Réel
  /// 
  /// Quand le joueur répond, le bot répond aussi après un délai adaptatif
  static Future<void> simulateRoundWithBot({
    required GhostMatchOrchestrator orchestrator,
    required GhostMatchData ghostData,
    required int currentPuzzleIndex,
    required Function(bool isCorrect, int score) onBotResponse,
  }) async {
    final puzzle = ghostData.puzzles[currentPuzzleIndex];
    
    print('🎯 Puzzle $currentPuzzleIndex: En attente réponse bot...');
    
    // Le bot calcule et répond
    final botResponse = orchestrator.simulateBotResponse(
      bot: ghostData.bot,
      puzzle: puzzle,
      playerHistoricalAvgMs: ghostData.playerHistoricalAvgMs,
    );
    
    print('🤖 Bot répond en ${botResponse.responseTimeMs}ms');
    print('   - Résultat: ${botResponse.isCorrect ? "✅ Correct" : "❌ Incorrect"}');
    
    // Callback pour mettre à jour l'UI
    onBotResponse(botResponse.isCorrect, botResponse.isCorrect ? 1 : 0);
  }
  
  /// Exemple 3: État du Match (Ghost vs Normal)
  /// 
  /// Structure unifiée: Le code UI ne change pas
  static void demonstrateUnifiedMatchState() {
    print('\n📊 COMPARAISON: Match Normal vs Ghost Match\n');
    
    // Match Normal (Firebase)
    print('🔵 Match Normal (Firebase):');
    print('  MatchModel {');
    print('    matchId: "firebase_abc123",');
    print('    player1: PlayerData(uid: "user_real", nickname: "John"),');
    print('    player2: PlayerData(uid: "user_real2", nickname: "Sarah"),');
    print('    status: "playing",');
    print('  }');
    
    print('\n👻 Ghost Match (Bot):');
    print('  MatchModel {');
    print('    matchId: "ghost_1234567890_999",');
    print('    player1: PlayerData(uid: "user_real", nickname: "John"),');
    print('    player2: PlayerData(uid: "bot_xyz789", nickname: "Alex42"),');
    print('    status: "playing",');
    print('  }');
    
    print('\n✅ IDENTIQUE pour l\'UI! OpponentCard ne voit aucune différence.');
  }
  
  /// Exemple 4: Calcul ELO avec Bot
  /// 
  /// Le match contre un bot compte pour l'ELO réel du joueur
  static Future<void> calculateEloAfterGhostMatch({
    required RatingStorage storage,
    required BotPersona botPersona,
    required int playerScore,
    required int botScore,
  }) async {
    final myProfile = await storage.getProfile();
    final myElo = myProfile.currentRating;
    final botElo = botPersona.currentRating;
    
    // Calcul standard ELO (identique à un match normal)
    final iWon = playerScore > botScore;
    final isDraw = playerScore == botScore;
    final actualScore = iWon ? 1.0 : (isDraw ? 0.5 : 0.0);
    
    // Utiliser EloCalculator existant
    // final newElo = EloCalculator.calculateNewRating(...)
    
    print('📊 Calcul ELO vs Bot:');
    print('   - Avant: $myElo');
    print('   - Bot ELO: $botElo');
    print('   - Résultat: ${iWon ? "Victoire" : isDraw ? "Égalité" : "Défaite"}');
    print('   - Delta ELO estimé: ${iWon ? "+15 à +25" : isDraw ? "±5" : "-10 à -20"}');
    
    // Le joueur ne sait pas que c'était un bot
    // Il voit juste "Victoire vs Alex42 (+18 ELO)"
  }
  
  /// Exemple 5: Test du Système Anti-AFK
  /// 
  /// Démontre que le bot ne suit pas aveuglément le joueur AFK
  static Future<void> demonstrateAntiAFK() async {
    final bot = BotAI.matchingSkill(
      1200,
      difficulty: BotDifficulty.competitive,
    );
    
    // Simuler un joueur qui part 1 heure (3,600,000 ms)
    print('\n⚠️ TEST ANTI-AFK:');
    print('Joueur AFK pendant 1 heure (3,600,000 ms)');
    
    final basicPuzzle = BasicPuzzle(
      id: 'test',
      numberA: 5,
      numberB: 3,
      operator: '+',
      targetValue: 8,
    );
    
    // Le bot calcule son temps avec le cap réaliste
    final delay = bot.calculateDynamicDelay(
      basicPuzzle,
      playerHistoricalAvgMs: 3600000, // 1 heure !
    );
    
    print('Bot répond en: ${delay.inSeconds}s');
    print('✅ Cap appliqué: Le bot ne dépasse pas 8s pour BasicPuzzle');
    print('   (Sinon il attendrait ~1h * 1.0 = 1h !)');
  }
  
  /// Exemple 6: Snippet d'Intégration dans StatefulWidget
  /// 
  /// Comment gérer l'état Ghost dans une page existante
  static String getStatefulWidgetIntegrationCode() {
    return '''
class RankedMultiplayerPageState extends State<RankedMultiplayerPage> {
  MatchModel? _currentMatch;
  
  // Flags Ghost (privés, jamais exposés)
  bool _isGhostMode = false;
  GhostMatchData? _ghostData;
  
  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }
  
  void _startMatchmaking() async {
    // 1. Lancer recherche Firebase normale
    final matchId = await _firebaseService.createMatch(myUid);
    
    // 2. Timer de 5s
    Timer(Duration(seconds: 5), () async {
      // Si toujours pas d'adversaire après 5s
      if (_currentMatch == null || !_currentMatch!.isFull) {
        await _handleGhostMode();
      }
    });
  }
  
  Future<void> _handleGhostMode() async {
    // Annuler Firebase
    await _firebaseService.leaveMatch(matchId, myUid);
    
    // Créer Ghost Match
    final orchestrator = GhostMatchOrchestrator(...);
    final ghostData = await orchestrator.createGhostMatch(
      playerElo: myProfile.currentRating,
      playerId: myUid,
    );
    
    setState(() {
      _isGhostMode = true;
      _ghostData = ghostData;
      _currentMatch = ghostData.match;
    });
    
    // L'UI affiche _currentMatch normalement
    // OpponentCard ne voit pas la différence !
  }
  
  void _onPlayerAnswer(dynamic answer, int puzzleIndex) {
    // Traiter réponse joueur
    final isCorrect = _validateAnswer(answer);
    
    // Si Ghost Mode: Bot répond aussi
    if (_isGhostMode) {
      _ghostData!.orchestrator.simulateBotResponse(
        bot: _ghostData!.bot,
        puzzle: _ghostData!.puzzles[puzzleIndex],
        playerHistoricalAvgMs: _ghostData!.playerHistoricalAvgMs,
      ).then((botResponse) {
        setState(() {
          // Mettre à jour score opponent
          final newPlayer2 = _currentMatch!.player2!.copyWith(
            score: botResponse.isCorrect 
                ? _currentMatch!.player2!.score + 1 
                : _currentMatch!.player2!.score,
          );
          
          _currentMatch = _currentMatch!.copyWith(player2: newPlayer2);
        });
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // AUCUNE logique conditionnelle UI
    // Que ce soit Ghost ou Firebase, on affiche pareil:
    
    return Scaffold(
      body: Column(
        children: [
          OpponentCard(
            opponentName: _currentMatch!.player2!.nickname,
            opponentElo: _currentMatch!.player2!.elo,
            opponentScore: _currentMatch!.player2!.score,
          ),
          // ... reste de l'UI identique
        ],
      ),
    );
  }
}
''';
  }
}

/// Point d'entrée pour tester les exemples
void main() async {
  print('='.repeat(60));
  print('👻 GHOST PROTOCOL - Exemples d\'Intégration');
  print('='.repeat(60));
  
  // Exemple 3: Comparaison états
  GhostProtocolIntegrationExample.demonstrateUnifiedMatchState();
  
  // Exemple 5: Anti-AFK
  await GhostProtocolIntegrationExample.demonstrateAntiAFK();
  
  print('\n' + '='.repeat(60));
  print('✅ Exemples terminés - Voir GHOST_PROTOCOL_GUIDE.md');
  print('='.repeat(60));
}

extension on String {
  String repeat(int count) => List.filled(count, this).join();
}
