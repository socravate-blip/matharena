# 🎮 EXEMPLE D'INTÉGRATION COMPLÈTE

## 📝 Code Complet - Ajouter le Bouton Ranked

### Option 1: Dans un Menu Existant

```dart
// Exemple: home_page.dart ou menu_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matharena/features/game/presentation/pages/ranked_matchmaking_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 24,
            children: [
              // Logo ou titre
              Text(
                'MATHARENA',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              
              const SizedBox(height: 64),
              
              // NOUVEAU BOUTON RANKED
              _buildMenuButton(
                context,
                label: 'RANKED',
                icon: Icons.emoji_events,
                color: Colors.cyan,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RankedMatchmakingPage(),
                    ),
                  );
                },
              ),
              
              // Autres boutons existants...
              _buildMenuButton(
                context,
                label: 'TRAINING',
                icon: Icons.fitness_center,
                color: Colors.orange,
                onPressed: () {
                  // Votre logique existante
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 280,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Option 2: Via un Router (go_router ou MaterialApp)

```dart
// main.dart ou app_router.dart

import 'package:go_router/go_router.dart';
import 'package:matharena/features/game/presentation/pages/ranked_matchmaking_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    
    // NOUVELLE ROUTE
    GoRoute(
      path: '/ranked',
      builder: (context, state) => const RankedMatchmakingPage(),
    ),
  ],
);

// Utilisation:
// context.go('/ranked');
```

---

### Option 3: Via Navigator Named Routes

```dart
// main.dart

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathArena',
      routes: {
        '/': (context) => HomePage(),
        '/ranked': (context) => RankedMatchmakingPage(), // NOUVEAU
        // ... autres routes
      },
    );
  }
}

// Utilisation:
// Navigator.pushNamed(context, '/ranked');
```

---

## 🔥 Configuration Firebase

### 1. Firestore Rules (Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Matches - Lecture/Écriture pour utilisateurs authentifiés
    match /matches/{matchId} {
      // Tout le monde peut lire (pour spectateurs potentiels)
      allow read: if request.auth != null;
      
      // Création: n'importe qui peut créer
      allow create: if request.auth != null;
      
      // Mise à jour: seulement les joueurs du match
      allow update: if request.auth != null 
        && request.auth.uid in [
          resource.data.player1.uid,
          get(/databases/$(database)/documents/matches/$(matchId)).data.player2.uid
        ];
      
      // Suppression: seulement créateur ET match en waiting
      allow delete: if request.auth != null 
        && request.auth.uid == resource.data.player1.uid
        && resource.data.status == 'waiting';
    }
    
    // Users - Profils utilisateurs
    match /users/{userId} {
      // Tout le monde peut lire les profils
      allow read: if request.auth != null;
      
      // Seulement le propriétaire peut modifier
      allow write: if request.auth != null 
        && request.auth.uid == userId;
    }
  }
}
```

### 2. Authentication Settings

Firebase Console > Authentication:

1. Cliquer "Get Started"
2. Sign-in method > Anonymous > Activer
3. (Optionnel) Ajouter Google, Email/Password, etc.

---

## 📦 pubspec.yaml Complet

```yaml
name: matharena
description: A math game with real-time multiplayer

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Firebase (CRUCIAL)
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0  # Pour le nouveau système
  
  # UI
  google_fonts: ^6.1.0
  
  # State Management (si vous utilisez)
  flutter_riverpod: ^2.4.9  # ou provider, bloc, etc.
  
  # Utilitaires
  shared_preferences: ^2.2.2  # Pour sauver l'état local

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  # Assets (si vous avez des images/sons)
  # assets:
  #   - assets/images/
  #   - assets/sounds/
```

---

## 🚀 main.dart Complet

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'features/game/presentation/pages/home_page.dart';

void main() async {
  // CRUCIAL: Initialiser Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRUCIAL: Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Lancer l'app
  runApp(
    const ProviderScope(  // Si vous utilisez Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MathArena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
```

---

## 🧪 Exemple de Test Complet

```dart
// test/multiplayer_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matharena/features/game/domain/services/firebase_multiplayer_service.dart';
import 'package:matharena/features/game/domain/logic/puzzle_generator.dart';

void main() {
  group('FirebaseMultiplayerService', () {
    late FirebaseMultiplayerService service;
    
    setUp(() {
      service = FirebaseMultiplayerService();
    });
    
    test('Create match should generate valid matchId', () async {
      final puzzles = PuzzleGenerator.generateMixed(count: 20);
      final matchId = await service.createMatchAndWait(puzzles);
      
      expect(matchId, isNotEmpty);
      expect(matchId.length, greaterThan(10));
    });
    
    test('Match should start with status waiting', () async {
      final puzzles = PuzzleGenerator.generateMixed(count: 20);
      final matchId = await service.createMatchAndWait(puzzles);
      
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      
      final status = matchDoc.data()?['status'];
      expect(status, equals('waiting'));
    });
    
    test('Update progress should work', () async {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final puzzles = PuzzleGenerator.generateMixed(count: 20);
      final matchId = await service.createMatchAndWait(puzzles);
      
      await service.updateProgress(
        matchId: matchId,
        uid: uid,
        percentage: 0.5,
        score: 10,
      );
      
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      
      final player1Progress = matchDoc.data()?['player1']['progress'];
      expect(player1Progress, equals(0.5));
    });
  });
}
```

---

## 📊 Monitoring en Production

### Firebase Console - Voir les Matches en Direct

```
1. Ouvrir: https://console.firebase.google.com
2. Sélectionner votre projet
3. Firestore Database
4. Collection "matches"
5. Voir les documents en temps réel
```

### Ajouter des Logs

```dart
// Dans firebase_multiplayer_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

Future<String> createMatchAndWait(List<GamePuzzle> puzzles) async {
  // ... code existant ...
  
  // LOG ANALYTICS
  FirebaseAnalytics.instance.logEvent(
    name: 'match_created',
    parameters: {
      'match_id': matchId,
      'puzzle_count': puzzles.length,
    },
  );
  
  return matchId;
}
```

---

## 🎯 Exemple Complet End-to-End

### Scénario: Joueur lance une partie

```dart
// 1. Utilisateur clique sur "RANKED" dans le menu
void onRankedPressed(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RankedMatchmakingPage(),
    ),
  );
}

// 2. RankedMatchmakingPage s'affiche
// → Bouton "COMMENCER"

// 3. Utilisateur clique "COMMENCER"
// → findAndJoinMatch() appelé
// → Si pas de match: createMatchAndWait()

// 4. Navigation vers RankedMultiplayerPage(matchId: ...)

// 5. StreamBuilder écoute le match
// → Status: 'waiting' → "RECHERCHE D'UN ADVERSAIRE..."

// 6. Joueur 2 rejoint
// → Status passe à 'starting'
// → Les deux voient "ADVERSAIRE TROUVÉ !"
// → Countdown 3, 2, 1

// 7. Countdown termine
// → startMatch() appelé
// → Status: 'playing'
// → Les deux voient le jeu

// 8. Joueurs résolvent puzzles
// → updateProgress() appelé à chaque puzzle
// → Les barres bougent en temps réel

// 9. Premier joueur termine
// → finishPlayer() appelé
// → Voit "En attente..."

// 10. Deuxième joueur termine
// → finishPlayer() appelé
// → Status: 'finished'
// → Les deux voient l'écran de résultat
```

---

## ✅ Checklist Finale

- [ ] Firebase initialisé dans `main.dart`
- [ ] Firestore créé et règles configurées
- [ ] Authentication activée (Anonymous)
- [ ] Bouton "RANKED" ajouté au menu
- [ ] Navigation vers `RankedMatchmakingPage` fonctionne
- [ ] Test avec 2 navigateurs réussi
- [ ] Countdown synchronisé
- [ ] Barres de progression synchronisées
- [ ] Écran de résultat s'affiche correctement

Si tout est ✅, vous avez un système multiplayer production-ready! 🎉
