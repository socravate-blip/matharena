# 🎮 SYSTÈME MULTIJOUEUR REFACTORISÉ - GUIDE COMPLET

## 📋 Problème Résolu

**Avant:** Joueur 1 commence immédiatement, Joueur 2 arrive en retard → Désynchronisation totale

**Maintenant:** Waiting Room → Compte à rebours synchronisé → Démarrage simultané → Progression temps réel

---

## 🏗️ Architecture

### 1. **Modèle de Données** (`match_model.dart`)

```dart
class MatchModel {
  final String status; // 'waiting' → 'starting' → 'playing' → 'finished'
  final PlayerData player1;
  final PlayerData? player2;
  final List<Map<String, dynamic>> puzzles;
}

class PlayerData {
  final String uid;
  final String nickname;
  final double progress;  // 0.0 à 1.0
  final int score;
  final String status;    // 'active' | 'finished'
}
```

### 2. **Service Firebase** (`firebase_multiplayer_service.dart`)

#### Méthodes principales:

```dart
// Créer un match et attendre un adversaire
Future<String> createMatchAndWait(List<GamePuzzle> puzzles)

// Rejoindre un match existant
Future<String?> findAndJoinMatch()

// Écouter les mises à jour en temps réel
Stream<DocumentSnapshot> streamMatch(String matchId)
Stream<MatchModel> streamMatchModel(String matchId)

// Mettre à jour sa progression
Future<void> updateProgress({
  required String matchId,
  required String uid,
  required double percentage,
  required int score,
})

// Marquer comme terminé
Future<void> finishPlayer({
  required String matchId,
  required String uid,
})

// Démarrer le match (après countdown)
Future<void> startMatch(String matchId)
```

### 3. **Interface Utilisateur** (`ranked_multiplayer_page.dart`)

#### Machine à États:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: _service.streamMatch(matchId),
  builder: (context, snapshot) {
    final match = MatchModel.fromMap(snapshot.data);
    
    switch (match.status) {
      case 'waiting':   return _buildWaitingScreen();
      case 'starting':  return _buildCountdownScreen();
      case 'playing':   return _buildGameScreen();
      case 'finished':  return _buildResultScreen();
    }
  }
)
```

---

## 🚀 Utilisation

### Option A: Utiliser la page de matchmaking

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RankedMatchmakingPage(),
  ),
);
```

### Option B: Intégration manuelle

```dart
// 1. Initialiser le service
final service = FirebaseMultiplayerService();
await service.initialize();

// 2. Créer ou rejoindre un match
String? matchId = await service.findAndJoinMatch();

if (matchId == null) {
  // Pas de match trouvé, créer un nouveau
  final puzzles = PuzzleGenerator.generateMixed(count: 20);
  matchId = await service.createMatchAndWait(puzzles);
}

// 3. Naviguer vers la page du match
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RankedMultiplayerPage(matchId: matchId),
  ),
);
```

---

## 📊 Flux de Données

### Création de Match (Joueur 1)

```
1. createMatchAndWait()
   └─> Firebase: status = 'waiting'
   
2. StreamBuilder écoute le match
   └─> Affiche "RECHERCHE D'UN ADVERSAIRE..."
   
3. Joueur 2 rejoint
   └─> Firebase: status = 'starting'
   
4. StreamBuilder détecte 'starting'
   └─> Lance le countdown local (3s)
   
5. Countdown termine
   └─> startMatch() → status = 'playing'
   
6. Les deux joueurs voient le jeu EN MÊME TEMPS
```

### Rejoindre un Match (Joueur 2)

```
1. findAndJoinMatch()
   └─> Cherche status = 'waiting'
   └─> Trouve le match
   └─> Update: status = 'starting', player2 = {...}
   
2. Navigation vers RankedMultiplayerPage
   
3. StreamBuilder écoute
   └─> Status déjà 'starting'
   └─> Lance countdown (3s)
   
4. Les deux countdowns se synchronisent automatiquement
   └─> Même si P2 arrive 200ms après, le countdown Firebase
       assure qu'ils démarrent ensemble
```

### Progression Temps Réel

```
Joueur 1 résout un puzzle:
  └─> updateProgress(percentage: 0.1, score: 1)
      └─> Firebase update: player1.progress = 0.1
          └─> Joueur 2 voit la barre orange bouger (StreamBuilder)

Joueur 2 résout un puzzle:
  └─> updateProgress(percentage: 0.15, score: 1)
      └─> Firebase update: player2.progress = 0.15
          └─> Joueur 1 voit la barre orange bouger
```

---

## 🔧 Configuration Firebase

### Firestore Rules (À METTRE À JOUR)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Matches
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null 
        && request.auth.uid in [
          resource.data.player1.uid,
          resource.data.player2.uid
        ];
      allow delete: if request.auth != null 
        && request.auth.uid == resource.data.player1.uid
        && resource.data.status == 'waiting';
    }
    
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Structure Firestore

```
matches/
  {matchId}/
    matchId: string
    status: 'waiting' | 'starting' | 'playing' | 'finished'
    createdAt: timestamp
    startTime: timestamp (quand P2 rejoint)
    startedAt: timestamp (quand le jeu démarre)
    finishedAt: timestamp
    
    player1/
      uid: string
      nickname: string
      progress: number (0-1)
      score: number
      status: 'active' | 'finished'
    
    player2/
      uid: string
      nickname: string
      progress: number (0-1)
      score: number
      status: 'active' | 'finished'
    
    puzzles: array<Map>

users/
  {uid}/
    uid: string
    nickname: string
    elo: number
    createdAt: timestamp
```

---

## 🎯 Points Clés de la Synchronisation

### 1. **Statut 'starting' = Déclencheur**
Quand Joueur 2 rejoint, le statut passe à `'starting'`. Les DEUX clients reçoivent cette notification via `StreamBuilder` et lancent leur countdown local.

### 2. **Countdown Local mais Déclenché Ensemble**
Même si les countdowns sont locaux (Timer Dart), ils démarrent au même moment car déclenchés par le même événement Firebase.

### 3. **Un Seul Appel startMatch()**
Seul le premier countdown qui finit appelle `startMatch()`. L'autre voit simplement le status changer en `'playing'` via le Stream.

### 4. **updateProgress() Non-Bloquant**
Les mises à jour de progression sont dans un `try-catch` et ne bloquent jamais le jeu si elles échouent.

---

## 🐛 Debug

### Vérifier l'état d'un match dans Firebase Console

```
1. Ouvrir Firebase Console
2. Firestore Database
3. Collection 'matches'
4. Chercher votre matchId
5. Vérifier:
   - status: doit passer de 'waiting' → 'starting' → 'playing'
   - player1.progress: doit augmenter
   - player2.progress: doit augmenter
```

### Logs dans la Console

```
🎮 Création du match: abc123
✅ Match créé en attente: abc123

🔍 Recherche d'un match disponible...
✅ Match trouvé: abc123
🎯 Match rejoint! Démarrage imminent...

👂 Écoute du match: abc123
▶️ Match démarré: abc123

📊 Progression mise à jour: 10.0%
📊 Progression mise à jour: 20.0%

🏁 Joueur terminé: xyz789
🎉 Match terminé!
```

---

## ⚡ Optimisations Futures

1. **Timeout pour Waiting Room**: Si personne ne rejoint en 30s, créer un bot
2. **Matchmaking ELO**: Filtrer par `where('elo', '>=', myElo - 200)`
3. **Reconnexion**: Si un joueur perd la connexion, lui permettre de revenir
4. **Spectateur**: Permettre de regarder un match en cours

---

## 📱 Exemple d'Intégration dans l'App

### Dans votre menu principal:

```dart
GameButton(
  label: 'RANKED',
  icon: Icons.emoji_events,
  color: Colors.cyan,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RankedMatchmakingPage(),
      ),
    );
  },
),
```

---

## ✅ Checklist de Vérification

- [ ] Firebase Authentication activé (Anonymous)
- [ ] Firestore créé et règles mises à jour
- [ ] Import de `cloud_firestore` dans `pubspec.yaml`
- [ ] Test: Créer un match (P1)
- [ ] Test: Rejoindre depuis un autre appareil (P2)
- [ ] Vérifier: Les deux voient le countdown
- [ ] Vérifier: Les deux démarrent en même temps
- [ ] Vérifier: Les barres de progression se mettent à jour
- [ ] Vérifier: L'écran de résultat s'affiche pour les deux

---

## 🎓 Concepts Avancés

### Pourquoi Firestore et pas Realtime Database?

- **Firestore**: Queries complexes, offline support, mieux pour les structures complexes
- **RTDB**: Meilleur pour les updates ultra-rapides (ex: position en temps réel)

Pour ce jeu, Firestore est parfait car:
- Les updates sont toutes les ~2-5 secondes (pas du 60 FPS)
- On a besoin de queries (`where status = waiting`)
- Structure hiérarchique claire

### StreamBuilder vs FutureBuilder

- `FutureBuilder`: 1 requête → 1 résultat
- `StreamBuilder`: 1 requête → ∞ mises à jour

Ici, on DOIT utiliser StreamBuilder car:
```dart
// ❌ MAUVAIS - Ne verra jamais les changements
final match = await firestore.doc(matchId).get();

// ✅ BON - Se met à jour automatiquement
firestore.doc(matchId).snapshots().listen((snapshot) {
  // Se déclenche à CHAQUE modification
});
```

---

## 📞 Support

Si vous rencontrez des problèmes:

1. Vérifier les logs Firebase (🔥 dans la console)
2. Vérifier la console Dart (print statements)
3. Regarder l'onglet Firestore dans Firebase Console
4. Tester avec deux navigateurs en parallèle

Bon jeu! 🎮
