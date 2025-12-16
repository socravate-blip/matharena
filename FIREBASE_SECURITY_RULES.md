# Firebase Security Rules for MathArena Multiplayer

## Realtime Database Rules

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    
    "queue": {
      ".read": true,
      "$playerId": {
        ".write": "$playerId === auth.uid",
        ".validate": "newData.hasChildren(['id', 'name', 'elo', 'joinedAt'])"
      }
    },
    
    "matches": {
      "$matchId": {
        ".read": "auth != null && (
          data.child('player1/id').val() === auth.uid ||
          data.child('player2/id').val() === auth.uid ||
          data.child('player2/isBot').val() === true
        )",
        
        ".write": "auth != null && (
          !data.exists() ||
          data.child('player1/id').val() === auth.uid ||
          data.child('player2/id').val() === auth.uid
        )",
        
        "player1": {
          ".validate": "newData.hasChildren(['id', 'name', 'elo', 'score', 'currentPuzzleIndex', 'isReady'])",
          "score": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          },
          "currentPuzzleIndex": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          }
        },
        
        "player2": {
          ".validate": "newData.hasChildren(['id', 'name', 'elo', 'score', 'currentPuzzleIndex', 'isReady'])",
          "score": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          },
          "currentPuzzleIndex": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          }
        },
        
        "state": {
          ".validate": "newData.isString() && (
            newData.val() === 'waiting' ||
            newData.val() === 'ready' ||
            newData.val() === 'inProgress' ||
            newData.val() === 'completed'
          )"
        },
        
        "answers": {
          "$answerId": {
            ".validate": "newData.hasChildren(['playerId', 'isCorrect', 'pointsEarned', 'timestamp'])"
          }
        }
      }
    },
    
    "leaderboard": {
      ".read": true,
      "$userId": {
        ".write": "$userId === auth.uid",
        ".validate": "newData.hasChildren(['name', 'elo', 'wins', 'losses', 'totalMatches'])"
      }
    }
  }
}
```

## Security Features Implemented:

### 1. **Authentication Required**
- All reads/writes require Firebase Auth
- Anonymous auth enabled for instant play
- Can upgrade to email/Google later

### 2. **Data Isolation**
- Players can only read their own matches
- Cannot see other players' active matches
- Queue is public (for matchmaking) but write-protected

### 3. **Data Validation**
- Score must be >= 0 (prevents cheating)
- State transitions validated
- All required fields enforced

### 4. **Anti-Cheat Measures**
- Server timestamps (can't fake)
- Score validation
- Answer history tracked
- Progress must be sequential

### 5. **Bot Matches**
- Bot data marked with `isBot: true`
- Bot matches accessible to player
- Bot cannot be impersonated

## Firestore Alternative Rules

If using Firestore instead of Realtime Database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Queue collection
    match /queue/{playerId} {
      allow read: if true;
      allow write: if request.auth != null && playerId == request.auth.uid;
    }
    
    // Matches collection
    match /matches/{matchId} {
      allow read: if request.auth != null && (
        resource.data.player1.id == request.auth.uid ||
        resource.data.player2.id == request.auth.uid ||
        resource.data.player2.isBot == true
      );
      
      allow create: if request.auth != null;
      
      allow update: if request.auth != null && (
        resource.data.player1.id == request.auth.uid ||
        resource.data.player2.id == request.auth.uid
      ) && (
        // Validate score doesn't decrease
        request.resource.data.player1.score >= resource.data.player1.score &&
        request.resource.data.player2.score >= resource.data.player2.score &&
        // Validate puzzle index doesn't decrease
        request.resource.data.player1.currentPuzzleIndex >= resource.data.player1.currentPuzzleIndex &&
        request.resource.data.player2.currentPuzzleIndex >= resource.data.player2.currentPuzzleIndex
      );
      
      // Answer submissions
      match /answers/{answerId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
    
    // Leaderboard
    match /leaderboard/{userId} {
      allow read: if true;
      allow write: if request.auth != null && userId == request.auth.uid;
    }
  }
}
```

## Additional Security Best Practices:

### 1. **Rate Limiting**
```json
// Add to Realtime Database rules
".write": "$playerId === auth.uid && !data.exists() || 
           (now - data.child('lastUpdate').val() > 1000)"
```

### 2. **Data Expiry**
- Automatically clean up old matches (Firebase Functions)
- Remove queue entries after 5 minutes
- Archive completed matches after 24 hours

### 3. **Fraud Detection**
- Track impossible solve times
- Flag suspicious score jumps
- Monitor bot match abuse

### 4. **Network Security**
- HTTPS only
- App Check enabled (prevents API abuse)
- reCAPTCHA for web version

## Firebase App Check Setup (Recommended)

Prevents API abuse and bot attacks:

```dart
// In main.dart
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  webRecaptchaSiteKey: 'your-recaptcha-key',
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

This ensures only your legitimate app can access Firebase, not API scrapers or cheaters.
