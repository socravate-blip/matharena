import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/rating_storage.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import 'placement_match_page.dart';

/// Page d'introduction au système de calibration
/// Explique le processus et demande le pseudo
class PlacementIntroPage extends StatefulWidget {
  const PlacementIntroPage({super.key});

  @override
  State<PlacementIntroPage> createState() => _PlacementIntroPageState();
}

class _PlacementIntroPageState extends State<PlacementIntroPage> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _startPlacement() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez entrer un pseudo',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    if (nickname.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le pseudo doit contenir au moins 3 caractères',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sauvegarder le pseudo dans le profil
      final storage = RatingStorage();
      await storage.init();
      final profile = await storage.getProfile();
      profile.playerName = nickname;
      await storage.saveProfile(profile);

      // Sauvegarder aussi dans Firebase (ProfilePage lit users/{uid}.nickname)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseMultiplayerService().updateUserProfile(
          uid,
          nickname: nickname,
        );
      }

      if (mounted) {
        // Démarrer le premier match de calibration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PlacementMatchPage(matchNumber: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting placement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du démarrage de la calibration',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Titre
              Text(
                '🎯 CALIBRATION',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Déterminez votre niveau de départ',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Explication
              _buildInfoCard(
                icon: '📋',
                title: '3 Épreuves',
                description:
                    'Vous allez affronter 3 types de défis pour évaluer vos compétences',
              ),

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: '⚡',
                title: 'Vitesse & Précision',
                description:
                    'Votre vitesse de calcul et votre précision seront mesurées',
              ),

              const SizedBox(height: 16),

              _buildInfoCard(
                icon: '🏆',
                title: 'ELO Initial',
                description:
                    'À la fin, vous recevrez votre classement de départ (800-1500 ELO)',
              ),

              const SizedBox(height: 48),

              // Les 3 Épreuves
              Text(
                'Les Épreuves',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              _buildTestCard(
                number: '1',
                title: 'Arithmétique Simple',
                description: 'Addition, soustraction, multiplication',
                icon: '➕',
                color: Colors.blue,
              ),

              const SizedBox(height: 12),

              _buildTestCard(
                number: '2',
                title: 'Équations Complexes',
                description: 'Parenthèses, opérations multiples',
                icon: '🧮',
                color: Colors.orange,
              ),

              const SizedBox(height: 12),

              _buildTestCard(
                number: '3',
                title: 'Jeu de 24',
                description: 'Flexibilité mentale et stratégie',
                icon: '🎯',
                color: Colors.purple,
              ),

              const SizedBox(height: 48),

              // Saisie du pseudo
              Text(
                'Votre Pseudo',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _nicknameController,
                enabled: !_isLoading,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Entrez votre pseudo...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.cyan, width: 2),
                  ),
                ),
                maxLength: 20,
                onSubmitted: (_) => _startPlacement(),
              ),

              const SizedBox(height: 32),

              // Bouton démarrer
              ElevatedButton(
                onPressed: _isLoading ? null : _startPlacement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        'COMMENCER LA CALIBRATION',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
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

  Widget _buildInfoCard({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard({
    required String number,
    required String title,
    required String description,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
