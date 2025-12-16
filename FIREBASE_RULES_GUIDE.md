# 🔐 Firebase Security Rules - Simplified Version

## ⚠️ Version de Debug (À Utiliser Pour Tester)

Cette version est TRÈS permissive et permet de tester rapidement si le multiplayer fonctionne. Une fois que tout fonctionne, passez aux règles de production.

### Étape 1: Allez dans la Console Firebase

1. Ouvrez https://console.firebase.google.com
2. Sélectionnez votre projet **matharena-a4da1**
3. Menu de gauche → **Realtime Database**
4. Onglet **Règles** (Rules)

### Étape 2: Règles de Debug (TEMPORAIRE)

Copiez-collez ces règles et cliquez sur **Publier**:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

**✅ Avantages:**
- Permet de tester rapidement
- Simple à comprendre
- Fonctionne avec l'auth anonyme

**❌ Inconvénients:**
- Tous les utilisateurs authentifiés peuvent tout lire/écrire
- Pas de protection contre le cheating
- À utiliser UNIQUEMENT pour le développement

---

## 🔒 Version de Production (Recommandée Une Fois que ça Marche)

Une fois que le multiplayer fonctionne avec les règles de debug, utilisez ces règles plus sécurisées:

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    
    "queue": {
      ".read": "auth != null",
      "$playerId": {
        ".write": "auth != null && $playerId === auth.uid"
      }
    },
    
    "matches": {
      "$matchId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    
    "leaderboard": {
      ".read": true,
      "$userId": {
        ".write": "auth != null && $userId === auth.uid"
      }
    }
  }
}
```

**✅ Avantages:**
- Protection basique contre le cheating
- Lecture limitée aux utilisateurs authentifiés
- Écriture contrôlée par userId

**⚠️ Limitations:**
- Validation de données minimale
- Pas de vérification de score côté serveur
- Pour une vraie sécurité, utilisez Cloud Functions

---

## 🚀 Version Ultra-Sécurisée (Pour Plus Tard)

Pour une sécurité maximale (recommandée pour la production réelle):

```json
{
  "rules": {
    ".read": false,
    ".write": false,
    
    "queue": {
      ".read": "auth != null",
      ".indexOn": ["elo", "joinedAt"],
      "$playerId": {
        ".write": "auth != null && $playerId === auth.uid",
        ".validate": "newData.hasChildren(['id', 'name', 'elo', 'joinedAt'])",
        "id": {
          ".validate": "newData.val() === auth.uid"
        },
        "name": {
          ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 50"
        },
        "elo": {
          ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 3000"
        },
        "joinedAt": {
          ".validate": "newData.val() === now"
        }
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
          "score": {
            ".validate": "newData.isNumber() && 
                         newData.val() >= data.val() && 
                         newData.val() <= data.val() + 100"
          },
          "currentPuzzleIndex": {
            ".validate": "newData.isNumber() && 
                         newData.val() >= 0 &&
                         newData.val() <= 30"
          }
        },
        
        "player2": {
          "score": {
            ".validate": "newData.isNumber() && 
                         newData.val() >= data.val() && 
                         newData.val() <= data.val() + 100"
          },
          "currentPuzzleIndex": {
            ".validate": "newData.isNumber() && 
                         newData.val() >= 0 &&
                         newData.val() <= 30"
          }
        },
        
        "state": {
          ".validate": "newData.isString() && (
            newData.val() === 'waiting' ||
            newData.val() === 'ready' ||
            newData.val() === 'inProgress' ||
            newData.val() === 'completed'
          )"
        }
      }
    },
    
    "leaderboard": {
      ".read": true,
      "$userId": {
        ".write": "auth != null && $userId === auth.uid",
        ".validate": "newData.hasChildren(['name', 'elo', 'wins', 'losses'])",
        "elo": {
          ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 3000"
        },
        "wins": {
          ".validate": "newData.isNumber() && newData.val() >= 0"
        },
        "losses": {
          ".validate": "newData.isNumber() && newData.val() >= 0"
        }
      }
    }
  }
}
```

**✅ Avantages:**
- Validation stricte des données
- Protection contre les augmentations de score anormales
- Indexation pour performance
- Protection contre les timestamps falsifiés

**❌ Limitations:**
- Plus complexe à maintenir
- Peut bloquer certaines opérations légitimes si mal configurée
- Nécessite des tests approfondis

---

## 📋 Plan d'Action Recommandé

1. **Aujourd'hui**: Utilisez les **règles de debug**
   - Testez que le multiplayer fonctionne
   - Identifiez les bugs
   - Jouez quelques parties

2. **Cette semaine**: Passez aux **règles de production**
   - Une fois que tout fonctionne
   - Testez avec 2 joueurs réels
   - Vérifiez qu'il n'y a pas de blocage

3. **Avant le lancement**: Implémentez les **règles ultra-sécurisées**
   - Ajoutez des Cloud Functions pour validation serveur
   - Testez intensivement
   - Activez le monitoring Firebase

---

## 🛠️ Commandes Utiles

### Tester les Règles Firebase

Dans la console Firebase, onglet "Règles", vous pouvez simuler des lectures/écritures:

```
// Tester lecture queue
Location: /queue/player123
Auth: Authenticated user (player123)
```

### Activer les Logs Firebase (Web)

Dans votre navigateur, console JavaScript:
```javascript
// Activer les logs détaillés
firebase.database.enableLogging(true);
```

### Vérifier l'État de la Database

```javascript
// Dans la console Chrome
firebase.database().ref('matches').once('value').then(snap => {
  console.log('Matches:', snap.val());
});
```

---

**🎯 Prochaine étape**: Utilisez les règles de debug et testez le multiplayer!
