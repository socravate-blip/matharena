# ⚡ CONFIGURATION FIREBASE EN 3 MINUTES

## 🎯 Problème: "client is offline"

Votre Firebase n'est **pas configuré**. Suivez ces 3 étapes:

---

## ✅ Étape 1: Créer Firestore Database (1 min)

1. Aller sur: https://console.firebase.google.com
2. Sélectionner votre projet **MathArena**
3. Menu gauche: **Build → Firestore Database**
4. Cliquer sur **"Create database"**
5. Sélectionner **"Start in test mode"**
6. Région: **europe-west1**
7. Cliquer **"Enable"**
8. Attendre 30 secondes ⏳

✅ **Résultat**: Vous voyez une interface avec des onglets "Data", "Rules", "Indexes"

---

## ✅ Étape 2: Activer Anonymous Auth (30 sec)

1. Menu gauche: **Build → Authentication**
2. Si premier usage: cliquer **"Get started"**
3. Onglet **"Sign-in method"**
4. Trouver **"Anonymous"** dans la liste
5. Cliquer sur **Anonymous**
6. Toggle **"Enable"**
7. Cliquer **"Save"**

✅ **Résultat**: Anonymous marqué comme "Enabled" avec coche verte

---

## ✅ Étape 3: Configurer les Règles (1 min)

1. Retourner dans **Firestore Database**
2. Onglet **"Rules"**
3. **Supprimer tout** et copier-coller:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /matches/{matchId} {
      allow read, write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

4. Cliquer **"Publish"**

✅ **Résultat**: "Last updated: just now"

---

## 🧪 TEST IMMÉDIAT

### Rechargez vos 2 fenêtres (F5)

1. **Chrome (localhost:8080)**: Cliquer "COMMENCER"
2. **Edge (localhost:8081)**: Cliquer "COMMENCER"

**✅ Si ça marche**: Vous voyez le countdown 3-2-1 puis le jeu démarre

**❌ Si erreur persiste**:
- Vérifier que les 3 étapes sont bien faites
- Regarder la console Chrome (F12) pour les logs
- Attendre 1 minute que Firebase se propage

---

## 🔍 Vérifications Rapides

### Dans Firebase Console

**Firestore → Data**: Doit être vide au départ (normal)

**Authentication → Users**: Doit se remplir quand vous lancez l'app

### Dans Chrome DevTools (F12)

**Console doit afficher**:
```
🚀 Initialisation Firebase...
🔐 Connexion anonyme...
✅ Connecté: [un code]
📝 Profil créé pour [code]
✅ Firebase initialisé avec succès
```

**Si vous voyez ça**, Firebase fonctionne! 🎉

---

## ⚠️ Erreurs Courantes

| Erreur | Solution |
|--------|----------|
| "client is offline" | Étape 1 pas faite |
| "operation-not-allowed" | Étape 2 pas faite |
| "permission-denied" | Étape 3 pas faite |
| Toujours en erreur | Attendre 1 min + F5 |

---

**C'est tout!** 🚀

Après ces 3 étapes, vos 2 joueurs pourront se trouver instantanément.
