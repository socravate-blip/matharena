import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/game/presentation/pages/game_home_page.dart';
import 'config/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MathArenaApp()));
}

class MathArenaApp extends StatelessWidget {
  const MathArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathArena',
      theme: AppTheme.darkTheme,
      home: const GameHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}