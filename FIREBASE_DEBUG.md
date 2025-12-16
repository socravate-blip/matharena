# 🔥 FIREBASE DEBUG - Client Offline Error

## ❌ Problème Actuel

**Erreur**: `[cloud_firestore/unavailable] Failed to get document because the client is offline`

Cette erreur signifie que Firebase n'est **pas correctement configuré**. Les deux joueurs ne peuvent pas se trouver.

---

## ✅ Solution Étape par Étape

### Étape 1: Vérifier Firebase Console

1. **Ouvrir Firebase Console**: https://console.firebase.google.com
2. **Sélectionner votre projet** MathArena
3. **Vérifier ces 3 points critiques** ⬇️

---

### Étape 2: Activer Firestore Database

#### ✅ Checklist Firestore

1. Dans Firebase Console, aller dans **Build → Firestore Database**
2. Si vous voyez "Create database", cliquer dessus
3. **Choisir le mode**:
   - Pour TEST: Sélectionner **"Start in test mode"** 
   - Production: Sélectionner **"Start in production mode"** puis configurer les règles

4. **Sélectionner une région**: `europe-west1` (ou plus proche)

5. **Attendre la création** (30 secondes)

6. **Vérifier que vous voyez**: Une interface avec onglets "Data", "Rules", "Indexes"

---

### Étape 3: Configurer les Règles Firestore

1. Dans Firestore, aller dans l'onglet **"Rules"**

2. **Copier-coller ces règles**:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Collection: matches (matchs multijoueur)
    match /matches/{matchId} {
      // Tout le monde peut lire les matchs
      allow read: if request.auth != null;
      
      // Tout le monde peut créer un match
      allow create: if request.auth != null;
      
      // Seuls les joueurs du match peuvent le modifier
      allow update: if request.auth != null && (
        resource.data.player1.uid == request.auth.uid ||
        resource.data.player2.uid == request.auth.uid
      );
      
      // Seuls les créateurs peuvent supprimer
      allow delete: if request.auth != null && 
        resource.data.player1.uid == request.auth.uid;
    }
    
    // Collection: users (profils utilisateurs)
    match /users/{userId} {
      // Tout le monde peut lire les profils
      allow read: if request.auth != null;
      
      // Chacun peut créer/modifier son propre profil
      allow create, update: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

3. **Cliquer sur "Publish"**

4. **Vérifier**: Vous devez voir "Last updated: just now"

---

### Étape 4: Activer Authentication Anonyme

1. Dans Firebase Console, aller dans **Build → Authentication**

2. Si vous voyez "Get started", cliquer dessus

3. Aller dans l'onglet **"Sign-in method"**

4. **Chercher "Anonymous"** dans la liste

5. **Cliquer sur Anonymous → Enable → Save**

6. **Vérifier**: Anonymous doit être marqué "Enabled" ✅

---

### Étape 5: Tester la Configuration

#### Test dans la Console Web

1. Ouvrir **Chrome DevTools** (F12)

2. Aller dans l'onglet **Console**

3. Vérifier ces logs:

```
✅ Attendu:
🔐 Connexion anonyme...
✅ Connecté: [un UID]
📝 Profil créé pour [UID]

❌ Si erreur:
- "client is offline" → Firestore pas créé
- "auth/operation-not-allowed" → Anonymous pas activé
- "permission-denied" → Règles incorrectes
```

#### Test de Match

1. **Ouvrir 2 fenêtres** (Chrome + Edge)

2. **Fenêtre 1**: Cliquer "COMMENCER"
   - Vous devez voir: "Recherche en cours..."

3. **Fenêtre 2**: Cliquer "COMMENCER"
   - Vous devez voir: "ADVERSAIRE TROUVÉ!" puis countdown 3, 2, 1

4. **Si ça ne fonctionne pas**:
   - Vérifier les logs Console (F12)
   - Vérifier Firebase Console → Firestore → Data → matches
   - Vous devez voir des documents créés

---

## 🔍 Vérifications Supplémentaires

### Vérifier que firebase_options.dart est correct

```bash
# Dans le terminal:
cd C:\Users\Theo\Desktop\mathed\MathArena
flutter pub get
```

Si erreur, régénérer:

```bash
# Installer FlutterFire CLI si pas déjà fait
dart pub global activate flutterfire_cli

# Reconfigurer Firebase
flutterfire configure
```

---

### Vérifier les dépendances dans pubspec.yaml

```yaml
dependencies:
  firebase_core: ^2.32.0
  firebase_auth: ^4.20.0
  cloud_firestore: ^4.17.5
```

Si différent, faire:

```bash
flutter pub get
flutter clean
flutter pub get
```

---

## 📊 Tableau de Diagnostic

| Symptôme | Cause Probable | Solution |
|----------|----------------|----------|
| "client is offline" | Firestore pas créé | Étape 2: Créer Firestore Database |
| "auth/operation-not-allowed" | Anonymous pas activé | Étape 4: Activer Anonymous Auth |
| "permission-denied" | Règles incorrectes | Étape 3: Copier les bonnes règles |
| Pas de match trouvé | Collections vides | Normal, créer 2 instances |
| Timeout / Freeze | Network lent | Vérifier connexion Internet |

---

## 🎯 Checklist Complète

Cocher au fur et à mesure:

- [ ] **Firestore Database créé** (Étape 2)
- [ ] **Règles Firestore configurées** (Étape 3)
- [ ] **Anonymous Authentication activé** (Étape 4)
- [ ] **Test Console: logs de connexion OK** (Étape 5)
- [ ] **Test 2 fenêtres: countdown synchronisé** (Étape 5)

---

## 🚨 Si Rien ne Fonctionne

### Option 1: Vérifier les logs complets

```bash
# Terminal 1
flutter run -d chrome --web-port 8080 --verbose

# Terminal 2
flutter run -d edge --web-port 8081 --verbose
```

Copier les logs d'erreur et vérifier:
- `FirebaseException`
- `AuthException`
- `Network error`

### Option 2: Tester Firebase manuellement

Dans Chrome DevTools Console (F12):

```javascript
// Vérifier Firebase initialisé
firebase.apps.length > 0

// Vérifier Auth
firebase.auth().currentUser

// Vérifier Firestore
firebase.firestore().collection('matches').get()
```

---

## 📝 Résumé Ultra-Court

**3 choses à faire dans Firebase Console**:

1. **Firestore Database** → Create database → Test mode
2. **Rules** → Copier-coller les règles ci-dessus → Publish
3. **Authentication** → Sign-in method → Anonymous → Enable

**Puis tester**: 2 fenêtres → COMMENCER → Doivent se trouver en 3 secondes ✅

---

**Besoin d'aide?** Vérifier les logs Console (F12) et chercher les erreurs Firebase.
