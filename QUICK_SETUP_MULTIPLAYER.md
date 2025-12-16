# 🚀 Guide Rapide - Activer le Multiplayer

## ⚡ Instructions en 5 Minutes

### Étape 1: Activer l'Authentification Anonyme

1. Ouvrez https://console.firebase.google.com
2. Sélectionnez le projet **matharena-a4da1**
3. Menu de gauche → **Authentication** (🔐)
4. Onglet **Sign-in method**
5. Cliquez sur **Anonymous** (Anonyme)
6. Activez le bouton → **Save** (Enregistrer)

✅ Vous devriez voir "Anonymous" avec un statut "Enabled"

---

### Étape 2: Configurer les Règles de Sécurité

1. Menu de gauche → **Realtime Database** (💾)
2. Onglet **Rules** (Règles)
3. **Supprimez tout** le contenu actuel
4. **Copiez-collez** ces règles:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

5. Cliquez sur **Publish** (Publier)
6. Confirmez

✅ Les règles devraient maintenant être actives

---

### Étape 3: Vérifier la Configuration

Dans la console Firebase, vérifiez:

- [ ] **Realtime Database** existe
- [ ] L'URL est: `https://matharena-a4da1-default-rtdb.europe-west1.firebasedatabase.app`
- [ ] Les règles montrent `"auth != null"`
- [ ] **Authentication** → Anonymous est "Enabled"

---

### Étape 4: Tester le Multiplayer

1. **Ouvrez un terminal** dans VS Code
2. **Lancez l'application**:
   ```powershell
   cd C:\Users\Theo\Desktop\mathed\MathArena
   flutter run -d chrome --web-port 8080
   ```

3. **Ouvrez la console** du navigateur (F12)
4. Cliquez sur **RANKED** → **BEGIN**

---

## ✅ Ce Que Vous Devriez Voir

### Dans la Console Flutter:
```
🔐 Signing in anonymously...
✅ Signed in as: AbC123XyZ...
🔍 Starting matchmaking for player: AbC123XyZ (ELO: 1000)
🔍 joinQueue called - Player: AbC123XyZ, ELO: 1000
📡 Checking queue for opponents...
➕ Adding player to queue...
✅ Player added to queue, waiting for opponent...
⏱️ Timeout reached - creating bot match...
🎮 Creating bot match: match_1234567890_bot
🤖 Bot created: Easy Eddie (ELO: 950)
💾 Saving match to Firebase...
✅ Bot match saved to Firebase
✅ Match created/joined: match_1234567890_bot
```

### Dans le Jeu:
- Message: "⚔️ Match Started! vs [Bot Name]"
- Le puzzle s'affiche
- Le timer démarre
- Vous pouvez jouer normalement

---

## ❌ Si Ça Ne Fonctionne Pas

### Erreur: "auth/operation-not-allowed"
**Solution**: L'authentification anonyme n'est pas activée
→ Retournez à l'Étape 1

### Erreur: "PERMISSION_DENIED"
**Solution**: Les règles de sécurité sont trop strictes
→ Retournez à l'Étape 2 et vérifiez que vous avez bien copié les règles

### Erreur: "Network error" ou "Failed to connect"
**Solution**: Problème de connexion Internet ou Firebase
→ Vérifiez votre connexion
→ Vérifiez que l'URL de la database est correcte dans `lib/firebase_options.dart`

### Le jeu démarre en "offline mode"
**Solution**: Firebase fonctionne en mode fallback
→ Regardez les logs dans la console Flutter pour voir l'erreur exacte
→ Vérifiez les Étapes 1 et 2

---

## 🎮 Mode Hors Ligne (Fallback)

Si Firebase ne fonctionne pas, le jeu **continue de fonctionner** en mode local:
- ✅ Vous jouez contre un bot (IA)
- ✅ Le score est sauvegardé localement
- ✅ Votre ELO est mis à jour
- ❌ Pas de matchmaking avec de vrais joueurs
- ❌ Pas de synchronisation en temps réel

**Pour réactiver le multiplayer**, suivez les étapes ci-dessus.

---

## 🔍 Debugging Avancé

### Voir les Logs Détaillés

Dans la console du navigateur (F12), tapez:
```javascript
// Activer les logs Firebase
firebase.database.enableLogging(true);
```

### Vérifier les Données Firebase

Dans la console du navigateur:
```javascript
// Voir la queue de matchmaking
firebase.database().ref('queue').once('value').then(snap => {
  console.log('Queue:', snap.val());
});

// Voir les matches actifs
firebase.database().ref('matches').once('value').then(snap => {
  console.log('Matches:', snap.val());
});
```

### Réinitialiser Firebase

Si vous voulez tout nettoyer:
1. Console Firebase → Realtime Database
2. Cliquez sur les "..." à côté de la racine
3. **Delete database** (supprimera toutes les données de test)
4. Ou supprimez manuellement les nœuds `queue` et `matches`

---

## 📚 Documentation Complète

Pour plus de détails, consultez:
- [MULTIPLAYER_DEBUG.md](MULTIPLAYER_DEBUG.md) - Guide de debugging complet
- [FIREBASE_RULES_GUIDE.md](FIREBASE_RULES_GUIDE.md) - Explication des règles de sécurité
- [FIREBASE_COMPLETE_SETUP.md](FIREBASE_COMPLETE_SETUP.md) - Setup original complet

---

## 🆘 Besoin d'Aide?

1. Vérifiez les logs dans la console Flutter
2. Vérifiez les erreurs dans la console du navigateur (F12)
3. Consultez [MULTIPLAYER_DEBUG.md](MULTIPLAYER_DEBUG.md)
4. Si le problème persiste, le mode offline continue de fonctionner

---

**🎯 Temps estimé**: 5-10 minutes pour tout configurer

**✅ Une fois configuré**, le multiplayer fonctionnera automatiquement à chaque lancement!
