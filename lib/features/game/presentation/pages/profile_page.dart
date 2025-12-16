import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/services/firebase_multiplayer_service.dart';
import '../../domain/logic/progression_system.dart';
import '../widgets/progression_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Page de profil pour changer le pseudo et voir l'ELO
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseMultiplayerService _service = FirebaseMultiplayerService();
  final TextEditingController _nicknameController = TextEditingController();

  String _currentNickname = '';
  int _currentElo = 1000;
  int _gamesPlayed = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  ProgressionData? _progressionData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final profile = await _service.getUserProfile(uid);
      setState(() {
        _currentNickname = profile['nickname'] ?? 'Joueur';
        _currentElo = profile['elo'] ?? 1000;
        _gamesPlayed = profile['gamesPlayed'] ?? 0;
        _nicknameController.text = _currentNickname;
        _progressionData =
            ProgressionSystem.getProgressionData(_currentElo, _gamesPlayed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty || newNickname == _currentNickname) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _service.updateUserProfile(uid, nickname: newNickname);
        setState(() {
          _currentNickname = newNickname;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pseudo modifié avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'PROFIL',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progression Widget
                  if (_progressionData != null)
                    ProgressionWidget(progression: _progressionData!),

                  const SizedBox(height: 32),

                  // Nickname Section
                  Text(
                    'PSEUDO',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nicknameController,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Votre pseudo',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.cyan, width: 2),
                      ),
                    ),
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNickname,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ENREGISTRER',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // All Milestones
                  Text(
                    'OBJECTIFS À DÉBLOQUER',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_progressionData != null)
                    ...ProgressionSystem.getAllMilestones().map((milestone) {
                      final isUnlocked = _progressionData!.elo >= milestone.elo;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isUnlocked ? Colors.green : Colors.grey[800]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isUnlocked
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    isUnlocked ? '✅' : '🔒',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      milestone.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked
                                            ? Colors.green
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      milestone.reward,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${milestone.elo}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isUnlocked ? Colors.green : Colors.cyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}
