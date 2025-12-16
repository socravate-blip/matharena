# Multiplayer Setup Guide

## Overview
This guide explains how to set up real-time multiplayer for MathArena ranked matches.

## Free Backend Options (No Server Purchase Needed!)

### Option 1: Firebase Realtime Database (Recommended for Beginners)
**Cost:** Free up to 1GB storage, 10GB/month downloads
**Best for:** Real-time sync, simple setup

#### Setup Steps:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable Realtime Database
4. Add these packages to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_database: ^10.4.0
```

5. Create `lib/features/game/domain/services/firebase_multiplayer_service.dart`:
```dart
import 'package:firebase_database/firebase_database.dart';
import 'multiplayer_service.dart';

class FirebaseMultiplayerService implements MultiplayerService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp();
  }
  
  @override
  Future<String> joinQueue(String playerId, String playerName, int playerElo) async {
    // Check for available matches
    final queueRef = _database.child('queue');
    final snapshot = await queueRef.get();
    
    if (snapshot.exists) {
      final queue = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Find match with similar ELO (±200)
      for (final entry in queue.entries) {
        final waiting = Map<String, dynamic>.from(entry.value as Map);
        final waitingElo = waiting['elo'] as int;
        
        if ((waitingElo - playerElo).abs() <= 200) {
          // Found match! Create game
          final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
          
          await _database.child('matches/$matchId').set({
            'matchId': matchId,
            'player1': waiting,
            'player2': {
              'id': playerId,
              'name': playerName,
              'elo': playerElo,
              'score': 0,
              'currentPuzzleIndex': 0,
              'isReady': false,
            },
            'state': 'waiting',
            'createdAt': ServerValue.timestamp,
          });
          
          // Remove from queue
          await queueRef.child(entry.key).remove();
          
          return matchId;
        }
      }
    }
    
    // No match found, add to queue
    await queueRef.child(playerId).set({
      'id': playerId,
      'name': playerName,
      'elo': playerElo,
      'joinedAt': ServerValue.timestamp,
    });
    
    // Wait for match (timeout after 30 seconds, create bot match)
    await Future.delayed(Duration(seconds: 30));
    
    // Check if still in queue
    final stillInQueue = await queueRef.child(playerId).get();
    if (stillInQueue.exists) {
      // Create bot match
      await queueRef.child(playerId).remove();
      return _createBotMatch(playerId, playerName, playerElo);
    }
    
    throw Exception('Already matched');
  }
  
  Future<String> _createBotMatch(String playerId, String playerName, int playerElo) async {
    final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
    
    await _database.child('matches/$matchId').set({
      'matchId': matchId,
      'player1': {
        'id': playerId,
        'name': playerName,
        'elo': playerElo,
        'score': 0,
        'currentPuzzleIndex': 0,
        'isReady': false,
      },
      'player2': {
        'id': 'bot_$matchId',
        'name': 'MathBot',
        'elo': playerElo + (playerElo > 1500 ? -100 : 100),
        'isBot': true,
        'score': 0,
        'currentPuzzleIndex': 0,
        'isReady': false,
      },
      'state': 'waiting',
      'createdAt': ServerValue.timestamp,
    });
    
    return matchId;
  }
  
  @override
  Stream<MultiplayerMatch> watchMatch(String matchId) {
    return _database.child('matches/$matchId').onValue.map((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return MultiplayerMatch.fromJson(data);
    });
  }
  
  @override
  Future<void> updatePlayerProgress(
    String matchId,
    String playerId,
    int score,
    int currentPuzzleIndex,
  ) async {
    final matchRef = _database.child('matches/$matchId');
    final snapshot = await matchRef.get();
    
    if (!snapshot.exists) return;
    
    final match = Map<String, dynamic>.from(snapshot.value as Map);
    final player1 = Map<String, dynamic>.from(match['player1'] as Map);
    
    if (player1['id'] == playerId) {
      await matchRef.child('player1').update({
        'score': score,
        'currentPuzzleIndex': currentPuzzleIndex,
      });
    } else {
      await matchRef.child('player2').update({
        'score': score,
        'currentPuzzleIndex': currentPuzzleIndex,
      });
    }
  }
  
  // Implement other methods...
}
```

### Option 2: Supabase (Modern, PostgreSQL-based)
**Cost:** Free up to 500MB database, 2GB bandwidth/month
**Best for:** SQL queries, authentication built-in

#### Setup Steps:
1. Go to [Supabase](https://supabase.com/)
2. Create project
3. Add package:
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

4. Create tables in Supabase SQL Editor:
```sql
-- Matches table
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id TEXT UNIQUE NOT NULL,
  player1_id TEXT NOT NULL,
  player1_name TEXT NOT NULL,
  player1_elo INT NOT NULL,
  player1_score INT DEFAULT 0,
  player1_current_puzzle INT DEFAULT 0,
  player2_id TEXT NOT NULL,
  player2_name TEXT NOT NULL,
  player2_elo INT NOT NULL,
  player2_score INT DEFAULT 0,
  player2_current_puzzle INT DEFAULT 0,
  is_player2_bot BOOLEAN DEFAULT false,
  state TEXT DEFAULT 'waiting',
  created_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP,
  completed_at TIMESTAMP
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE matches;
```

### Option 3: Appwrite (Self-hosted or Cloud)
**Cost:** Free cloud tier or self-host for free
**Best for:** Full backend features (auth, storage, functions)

## Bot Implementation

The bot is already implemented in `lib/features/game/domain/logic/bot_ai.dart`:

### Bot Features:
- **Realistic Timing**: Solves based on puzzle difficulty
- **Skill Levels**: ELO 800-2000 with varying success rates
- **Human-like Behavior**: Random variations in solve time
- **Strategic Play**: Higher-skill bots attempt Mathador solutions

### Bot Performance by ELO:
- **800-1000**: Slow, 60-75% success rate
- **1000-1400**: Medium speed, 75-90% success rate
- **1400-1800**: Fast, 85-95% success rate
- **1800-2000**: Very fast, 90-98% success rate

## Architecture

```
┌─────────────────┐         ┌──────────────────┐
│   Player 1      │◄────────►│   Firebase/      │
│   (Real User)   │          │   Supabase       │
└─────────────────┘          │   (Backend)      │
                             └──────────────────┘
                                      ▲
                                      │
                                      ▼
                             ┌──────────────────┐
                             │   Player 2       │
                             │   (Real or Bot)  │
                             └──────────────────┘
```

## Matchmaking Logic

1. Player joins queue with ELO rating
2. System searches for opponent within ±200 ELO
3. If found within 30 seconds → real match
4. If timeout → bot match created
5. Bot ELO is slightly above/below player for challenge

## Security Rules (Firebase Example)

```json
{
  "rules": {
    "matches": {
      "$matchId": {
        ".read": true,
        ".write": "auth != null",
        "player1": {
          ".validate": "newData.child('id').val() === auth.uid"
        },
        "player2": {
          ".validate": "newData.child('id').val() === auth.uid || newData.child('isBot').val() === true"
        }
      }
    },
    "queue": {
      ".read": true,
      "$playerId": {
        ".write": "$playerId === auth.uid"
      }
    }
  }
}
```

## Cost Estimation

### Free Tier Limits (Firebase):
- **100 concurrent connections**: ~200 active matches
- **1GB storage**: ~1 million matches
- **10GB downloads/month**: ~50,000 matches/month

**Conclusion**: Free tier easily handles **thousands of players** for free!

### If You Grow:
- Firebase Blaze (pay-as-you-go): ~$25/month for 10,000 active users
- Supabase Pro: $25/month for unlimited
- Self-host on VPS: $5-10/month (DigitalOcean, Hetzner)

## Implementation Steps

1. ✅ Bot AI created (`bot_ai.dart`)
2. ✅ Multiplayer service interface created (`multiplayer_service.dart`)
3. ⏳ Choose backend (Firebase/Supabase)
4. ⏳ Implement service (see examples above)
5. ⏳ Update `ranked_provider.dart` to use multiplayer
6. ⏳ Add matchmaking UI
7. ⏳ Test with bots
8. ⏳ Deploy!

## Next Steps

1. Choose your backend (I recommend **Firebase** for simplicity)
2. Set up project in Firebase Console
3. Add credentials to your Flutter app
4. Implement the `FirebaseMultiplayerService` class
5. Update ranked mode to use multiplayer service
6. Test locally with bot matches
7. Deploy to web/mobile

Need help with any specific step? Let me know!
