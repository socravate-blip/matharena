import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/services/stats_service.dart';
import 'placement_intro_page.dart';
import 'game_home_page.dart';

/// Wrapper qui vérifie si l'utilisateur doit faire la calibration
/// Redirige vers PlacementIntroPage si nécessaire, sinon vers GameHomePage
class AppStartupPage extends StatefulWidget {
  const AppStartupPage({super.key});

  @override
  State<AppStartupPage> createState() => _AppStartupPageState();
}

class _AppStartupPageState extends State<AppStartupPage> {
  bool _isLoading = true;
  bool _needsPlacement = false;

  @override
  void initState() {
    super.initState();
    _checkPlacementStatus();
  }

  Future<void> _checkPlacementStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Pas d'utilisateur connecté, considérer comme nouveau
        setState(() {
          _needsPlacement = true;
          _isLoading = false;
        });
        return;
      }

      // Vérifier le statut de placement dans les stats
      final statsService = StatsService();
      final stats = await statsService.getPlayerStats(user.uid);

      print('🔍 Checking placement status for user ${user.uid}');
      print('   isPlacementComplete: ${stats.isPlacementComplete}');
      print('   totalGames: ${stats.totalGames}');

      setState(() {
        _needsPlacement = !stats.isPlacementComplete;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking placement status: $e');
      // En cas d'erreur, ne pas forcer le placement
      setState(() {
        _needsPlacement = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.cyan,
          ),
        ),
      );
    }

    // Rediriger selon le statut
    if (_needsPlacement) {
      return const PlacementIntroPage();
    } else {
      return const GameHomePage();
    }
  }
}
