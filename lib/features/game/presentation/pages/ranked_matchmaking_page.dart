import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../../domain/repositories/rating_storage.dart';
import '../pages/ranked_multiplayer_page.dart';
import '../pages/profile_page.dart';

/// Page pour lancer un match Ranked Multijoueur
class RankedMatchmakingPage extends StatefulWidget {
  const RankedMatchmakingPage({super.key});

  @override
  State<RankedMatchmakingPage> createState() => _RankedMatchmakingPageState();
}

class _RankedMatchmakingPageState extends State<RankedMatchmakingPage> {
  final FirebaseMultiplayerService _service = FirebaseMultiplayerService();
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      print('🚀 Initialisation Firebase...');
      await _service.initialize();
      print('✅ Firebase initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation Firebase: $e');
      setState(() {
        _errorMessage = 'Configuration Firebase requise!\n\n'
            'Erreur: $e\n\n'
            'Suivez FIREBASE_DEBUG.md pour configurer:\n'
            '1. Créer Firestore Database\n'
            '2. Activer Anonymous Auth\n'
            '3. Configurer les règles';
      });
    }
  }

  Future<void> _startMatchmaking({required bool createNew}) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      String? matchId;

      // Récupérer l'ELO du joueur
      final storage = RatingStorage();
      final profile = await storage.getProfile();
      final myElo = profile.currentRating;

      if (createNew) {
        // Créer un nouveau match avec l'ELO du joueur
        matchId = await _service.createMatchAndWait(playerElo: myElo);
        print('✅ Match créé: $matchId (ELO: $myElo)');
      } else {
        // Rejoindre un match existant
        matchId = await _service.findAndJoinMatch();

        if (matchId == null) {
          // Aucun match trouvé, créer un nouveau
          matchId = await _service.createMatchAndWait(playerElo: myElo);
          print(
              '✅ Aucun match trouvé, nouveau match créé: $matchId (ELO: $myElo)');
        } else {
          print('✅ Match rejoint: $matchId');
        }
      }

      // Naviguer vers la page du match
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RankedMultiplayerPage(matchId: matchId!),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur matchmaking: $e');
      setState(() {
        String errorMsg = e.toString();

        // Messages d'erreur plus clairs
        if (errorMsg.contains('client is offline') ||
            errorMsg.contains('unavailable')) {
          _errorMessage = '🔥 Firestore non configuré!\n\n'
              'Allez dans Firebase Console:\n'
              '1. Créer Firestore Database (test mode)\n'
              '2. Activer Anonymous Auth\n\n'
              'Voir FIREBASE_DEBUG.md pour détails';
        } else if (errorMsg.contains('permission-denied')) {
          _errorMessage = '🔒 Règles Firestore incorrectes!\n\n'
              'Copiez les règles de FIREBASE_DEBUG.md\n'
              'dans Firebase Console → Firestore → Rules';
        } else if (errorMsg.contains('auth/operation-not-allowed')) {
          _errorMessage = '🔐 Anonymous Auth non activé!\n\n'
              'Firebase Console → Authentication\n'
              '→ Sign-in method → Anonymous → Enable';
        } else {
          _errorMessage = 'Erreur: $errorMsg';
        }

        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'RANKED',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.cyan),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyan, width: 3),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 48),

                // Titre
                Text(
                  'MODE CLASSÉ',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Affrontez un adversaire en temps réel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),

                // Bouton principal
                if (!_isSearching)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _startMatchmaking(createNew: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'COMMENCER',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                if (_isSearching)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        'Recherche en cours...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous serez automatiquement jumelé avec un adversaire',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
