# 🔄 GUIDE DE MIGRATION - ANCIEN → NOUVEAU SYSTÈME MULTIPLAYER

## 📦 Fichiers Créés

### Nouveaux Fichiers Core
✅ `lib/features/game/domain/models/match_model.dart` - Modèle de données
✅ `lib/features/game/domain/logic/puzzle_generator.dart` - Génération puzzles
✅ `lib/features/game/domain/services/firebase_multiplayer_service.dart` - Service refactorisé
✅ `lib/features/game/presentation/pages/ranked_multiplayer_page.dart` - Page principale
✅ `lib/features/game/presentation/pages/ranked_matchmaking_page.dart` - Matchmaking UI
✅ `lib/features/game/presentation/widgets/realtime_opponent_progress.dart` - Widget progression

### Documentation
✅ `MULTIPLAYER_REFACTOR_GUIDE.md` - Guide complet

---

## ⚙️ Étapes de Migration

### 1. Mettre à jour `pubspec.yaml`

Assurez-vous d'avoir:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase (CRUCIAL: Firestore au lieu de Realtime Database)
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0  # ⚠️ NOUVEAU - Remplace firebase_database
  
  # UI
  google_fonts: ^6.1.0
```

### 2. Mettre à jour les Règles Firebase

#### Firestore Rules (À REMPLACER)

Allez dans Firebase Console > Firestore Database > Règles:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Initialiser Firebase dans `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### 4. Option A: Remplacer Ranked Page Actuelle

Si vous voulez remplacer complètement l'ancienne page:

```dart
// Dans votre router ou navigation
case '/ranked':
  return MaterialPageRoute(
    builder: (context) => RankedMatchmakingPage(), // ← NOUVEAU
  );
```

### 5. Option B: Coexistence (Recommandé pour tester)

Gardez l'ancien système et ajoutez le nouveau:

```dart
// Menu principal
Column(
  children: [
    GameButton(
      label: 'RANKED (Ancien)',
      onPressed: () => Navigator.pushNamed(context, '/ranked'),
    ),
    GameButton(
      label: 'RANKED (Nouveau - Multijoueur)',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RankedMatchmakingPage(),
        ),
      ),
    ),
  ],
)
```

---

## 🔄 Changements API

### Ancien Service (à NE PLUS utiliser)

```dart
// ❌ ANCIEN
final service = FirebaseMultiplayerService();
await service.joinQueue(playerId, playerName, elo);
await service.watchMatch(matchId);
await service.updatePlayerProgress(matchId, playerId, score, index);
```

### Nouveau Service

```dart
// ✅ NOUVEAU
final service = FirebaseMultiplayerService();
await service.initialize();

// Créer/Rejoindre
String matchId = await service.createMatchAndWait(puzzles);
String? matchId = await service.findAndJoinMatch();

// Écouter (Stream, pas Future)
Stream<MatchModel> matchStream = service.streamMatchModel(matchId);

// Mettre à jour
await service.updateProgress(
  matchId: matchId,
  uid: myUid,
  percentage: 0.5,
  score: 10,
);

// Terminer
await service.finishPlayer(matchId: matchId, uid: myUid);
```

---

## 📊 Migration des Données Existantes

Si vous avez des matches dans Realtime Database:

### Script de Migration (Optionnel)

```dart
Future<void> migrateMatches() async {
  // 1. Lire Realtime Database
  final rtdb = FirebaseDatabase.instance.ref();
  final snapshot = await rtdb.child('matches').get();
  
  if (!snapshot.exists) return;
  
  // 2. Convertir et sauver dans Firestore
  final firestore = FirebaseFirestore.instance;
  final matches = snapshot.value as Map;
  
  for (final entry in matches.entries) {
    final matchId = entry.key;
    final matchData = entry.value as Map;
    
    // Adapter le format si nécessaire
    await firestore.collection('matches').doc(matchId).set({
      'matchId': matchId,
      'status': matchData['state'] ?? 'finished',
      'createdAt': matchData['createdAt'] ?? FieldValue.serverTimestamp(),
      // ... autres champs
    });
  }
  
  print('✅ Migration terminée');
}
```

**MAIS**: Pas vraiment nécessaire si vous pouvez recommencer à zéro.

---

## 🧹 Nettoyage (Après migration complète)

### Fichiers à SUPPRIMER (une fois que tout marche)

```
❌ lib/features/game/presentation/pages/ranked_page_new.dart
❌ lib/features/game/presentation/pages/ranked_page_fixed.dart
❌ Tout fichier lié à Realtime Database non utilisé
```

### Dépendances à RETIRER de pubspec.yaml

```yaml
dependencies:
  # firebase_database: ^10.0.0  ← RETIRER si plus utilisé ailleurs
```

---

## 🧪 Plan de Test

### Phase 1: Test Solo
1. ✅ Lancer l'app
2. ✅ Cliquer "Ranked (Nouveau)"
3. ✅ Voir "RECHERCHE D'UN ADVERSAIRE..."
4. ✅ Dans Firebase Console > Firestore, voir le match créé avec `status: 'waiting'`

### Phase 2: Test Multijoueur
1. ✅ Ouvrir l'app dans 2 navigateurs (Chrome + Edge)
2. ✅ P1: Créer un match
3. ✅ P2: Rejoindre → Les deux voient "ADVERSAIRE TROUVÉ"
4. ✅ Les deux voient le countdown (3, 2, 1)
5. ✅ Les deux voient le jeu démarrer EN MÊME TEMPS
6. ✅ P1 résout un puzzle → P2 voit la barre orange bouger
7. ✅ P2 résout un puzzle → P1 voit la barre orange bouger
8. ✅ Un des deux termine → Écran "En attente..."
9. ✅ L'autre termine → Les deux voient le résultat

---

## ⚠️ Points d'Attention

### 1. Authentification
Le nouveau système utilise `FirebaseAuth.instance.currentUser.uid` partout.
Assurez-vous que l'authentification anonyme fonctionne:

```dart
// Dans main.dart ou au démarrage
final service = FirebaseMultiplayerService();
await service.initialize(); // ← Gère l'auth automatiquement
```

### 2. Pseudo par Défaut
Le système génère `Joueur{uid_4_chars}` si pas de pseudo. Pour personnaliser:

```dart
await service.updateNickname(myUid, 'MonSuperPseudo');
```

### 3. Puzzles
Le `PuzzleGenerator` crée des puzzles basiques. Adaptez si besoin:

```dart
class PuzzleGenerator {
  static List<GamePuzzle> generateMixed({int count = 20}) {
    // Modifier ici pour ajouter Game24, Matador, etc.
  }
}
```

---

## 🚨 Problèmes Courants

### "Match introuvable"
- Vérifier que Firestore est créé dans Firebase Console
- Vérifier les règles Firestore (read/write autorisés)

### "Les deux ne démarrent pas en même temps"
- Vérifier les logs: `▶️ Match démarré` doit apparaître
- Le countdown est local mais déclenché par Firebase
- Latence réseau peut causer 100-200ms de décalage (normal)

### "La barre adverse ne bouge pas"
- Vérifier que `updateProgress()` est bien appelé
- Vérifier dans Firebase Console que `player1.progress` change
- Vérifier que le `StreamBuilder` écoute bien le bon matchId

### "Erreur de compilation avec GamePuzzle"
Si vos puzzles ont une structure différente, adaptez `PuzzleGenerator`:

```dart
// Si vous utilisez un autre format
static List<MesPuzzles> generateMixed({int count = 20}) {
  return List.generate(count, (i) => MesPuzzles.random());
}
```

---

## 📞 Checklist Finale

Avant de déployer en production:

- [ ] Firebase Firestore créé
- [ ] Règles Firestore configurées
- [ ] Authentication activée (Anonymous)
- [ ] `pubspec.yaml` mis à jour avec `cloud_firestore`
- [ ] Test solo réussi (création match)
- [ ] Test multi-joueurs réussi (2 appareils)
- [ ] Synchronisation confirmée (countdown + progression)
- [ ] Écran de résultat fonctionne
- [ ] Abandon/Quitter fonctionne
- [ ] Aucune erreur dans les logs

---

## 🎉 C'est Bon!

Si tous les tests passent, vous pouvez:

1. **Déployer** le nouveau système
2. **Retirer** l'ancien code (ranked_page_old.dart, etc.)
3. **Communiquer** aux utilisateurs: "Nouveau mode Ranked synchronisé!"

Le système est maintenant **production-ready** avec:
- ✅ Synchronisation parfaite
- ✅ Waiting Room fonctionnelle
- ✅ Progression temps réel
- ✅ Gestion propre des déconnexions
- ✅ Code maintenable et documenté

Bon développement! 🚀
