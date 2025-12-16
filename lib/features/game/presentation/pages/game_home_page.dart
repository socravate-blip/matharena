import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matharena/features/game/presentation/pages/ranked_page_fixed.dart';
import 'package:matharena/features/training/presentation/pages/training_page.dart';
import 'package:matharena/features/game/presentation/pages/stats_page.dart';

class GameHomePage extends ConsumerStatefulWidget {
  const GameHomePage({super.key});

  @override
  ConsumerState<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends ConsumerState<GameHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RankedPage(),
    const TrainingPage(),
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[900]!, width: 1),
          ),
          color: const Color(0xFF0A0A0A),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0A0A0A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[700],
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Text(
                '⚔️',
                style: GoogleFonts.spaceGrotesk(fontSize: 20),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚔️',
                  style: GoogleFonts.spaceGrotesk(fontSize: 20),
                ),
              ),
              label: 'RANKED',
            ),
            BottomNavigationBarItem(
              icon: Text(
                '🏋️',
                style: GoogleFonts.spaceGrotesk(fontSize: 20),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🏋️',
                  style: GoogleFonts.spaceGrotesk(fontSize: 20),
                ),
              ),
              label: 'TRAINING',
            ),
            BottomNavigationBarItem(
              icon: Text(
                '📈',
                style: GoogleFonts.spaceGrotesk(fontSize: 20),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📈',
                  style: GoogleFonts.spaceGrotesk(fontSize: 20),
                ),
              ),
              label: 'STATS',
            ),
          ],
        ),
      ),
    );
  }
}
