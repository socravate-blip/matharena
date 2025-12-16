# Firebase Setup Guide for MathArena - Enterprise Security

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Name: "MathArena"
4. Enable Google Analytics (recommended)
5. Create project

## Step 2: Enable Authentication

1. In Firebase Console → **Authentication**
2. Click "Get Started"
3. Enable **Anonymous** authentication
   - This allows instant play without signup
   - Can upgrade to email/Google later
4. (Optional) Enable **Google Sign-In** for web

## Step 3: Create Realtime Database

1. In Firebase Console → **Realtime Database**
2. Click "Create Database"
3. Choose location (Europe for best latency to France)
4. Start in **locked mode** (we'll add rules next)

## Step 4: Set Security Rules

1. Go to **Realtime Database → Rules** tab
2. Copy the rules from `FIREBASE_SECURITY_RULES.md`
3. Click **Publish**

## Step 5: Register Your App

### For Web:
1. In Project Settings → General
2. Click web icon `</>`
3. Register app: "MathArena Web"
4. Copy the config

Create `web/firebase-config.js`:
```javascript
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getDatabase } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-database.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "matharena-xxxxx.firebaseapp.com",
  databaseURL: "https://matharena-xxxxx-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "matharena-xxxxx",
  storageBucket: "matharena-xxxxx.appspot.com",
  messagingSenderId: "XXXXXXXXXXXXX",
  appId: "1:XXXXXXXXXXXXX:web:XXXXXXXXXXXXXXXX"
};

const app = initializeApp(firebaseConfig);
export const database = getDatabase(app);
export const auth = getAuth(app);
```

### For Android:
1. In Project Settings → General
2. Click Android icon
3. Package name: `com.matharena.app`
4. Download `google-services.json`
5. Place in `android/app/`

### For iOS:
1. In Project Settings → General
2. Click iOS icon
3. Bundle ID: `com.matharena.app`
4. Download `GoogleService-Info.plist`
5. Place in `ios/Runner/`

## Step 6: Update Flutter App

### Update `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize multiplayer service
  final container = ProviderContainer();
  await container.read(multiplayerServiceProvider).initialize();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
```

## Step 7: Generate Firebase Options

Run this command to auto-generate Firebase config:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure --project=matharena-xxxxx
```

This creates `lib/firebase_options.dart` automatically!

## Step 8: Enable App Check (Anti-Cheat)

### For Web:
1. In Firebase Console → **App Check**
2. Click "Register" for Web app
3. Choose **reCAPTCHA v3**
4. Get site key from [Google reCAPTCHA](https://www.google.com/recaptcha/admin)
5. Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_app_check: ^0.2.1+8
```

6. In `lib/main.dart`:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

await Firebase.initializeApp(...);

await FirebaseAppCheck.instance.activate(
  webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY',
  androidProvider: AndroidProvider.playIntegrity,
);
```

## Step 9: Database Indexes (Performance)

Go to **Realtime Database → Rules** and add:

```json
{
  "rules": {
    "queue": {
      ".indexOn": ["elo", "joinedAt"]
    },
    "matches": {
      ".indexOn": ["state", "createdAt"]
    },
    "leaderboard": {
      ".indexOn": ["elo", "totalMatches"]
    }
  }
}
```

## Step 10: Test Connection

Run this test in your app:

```dart
// Test Firebase connection
void testFirebase() async {
  try {
    final ref = FirebaseDatabase.instance.ref('test');
    await ref.set({
      'message': 'Hello from MathArena!',
      'timestamp': ServerValue.timestamp,
    });
    print('✅ Firebase connected!');
    
    final snapshot = await ref.get();
    print('Data: ${snapshot.value}');
    
    await ref.remove();
  } catch (e) {
    print('❌ Firebase error: $e');
  }
}
```

## Cost Estimation for Your App

### Firebase Spark Plan (FREE):
- ✅ **50,000 simultaneous connections**
- ✅ **1 GB stored data**
- ✅ **10 GB/month downloaded**
- ✅ **Unlimited authentication**

**This handles ~10,000+ daily active users for FREE!**

### Firebase Blaze Plan (Pay-as-you-go):
If you exceed free tier:
- $1/GB storage (first 1GB free)
- $1/GB download (first 10GB free)
- ~€25-50/month for 50,000 daily users

### Enterprise Scale:
- 100,000+ users: €100-200/month
- 1,000,000+ users: €500-1000/month

**Conclusion**: Start free, only pay when successful!

## Security Checklist

- ✅ Authentication enabled
- ✅ Security rules configured
- ✅ App Check enabled (prevents API abuse)
- ✅ Database indexes created
- ✅ HTTPS enforced
- ✅ Anonymous auth for easy onboarding
- ✅ Server timestamps (can't be faked)
- ✅ Score validation
- ✅ Rate limiting

## Monitoring & Analytics

### Enable Performance Monitoring:
```yaml
dependencies:
  firebase_performance: ^0.9.3+6
```

### Enable Crashlytics:
```yaml
dependencies:
  firebase_crashlytics: ^3.4.8
```

### View Real-Time Users:
Firebase Console → **Realtime Database** → See active connections in real-time!

## Backup Strategy

1. **Automated Backups**: Enable in Firebase Console → Backups
2. **Export Data**: Can export JSON anytime
3. **Version Control**: Rules tracked in Git

## Production Deployment

### Web:
```bash
flutter build web --release
firebase deploy --only hosting
```

### Android:
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

### iOS:
```bash
flutter build ipa --release
# Upload to App Store Connect
```

## Support & Scaling

If you grow large:
- Firebase handles scaling automatically
- No server management needed
- Google Cloud infrastructure
- 99.95% uptime SLA

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Run `flutterfire configure`
3. Test Firebase connection
4. Implement matchmaking UI
5. Test with bot matches
6. Deploy to production!

Need help with any step? Firebase has excellent documentation and support!
