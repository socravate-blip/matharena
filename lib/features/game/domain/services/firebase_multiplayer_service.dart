import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart';
import '../logic/puzzle_generator.dart';

/// Service Firebase Multijoueur avec Waiting Room
/// Synchronisation temps réel des deux joueurs
class FirebaseMultiplayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections Firebase
  CollectionReference get _matchesRef => _firestore.collection('matches');
  CollectionReference get _usersRef => _firestore.collection('users');

  // ============================================================
  // AUTHENTIFICATION & PROFIL UTILISATEUR
  // ============================================================

  /// Initialise l'authentification Firebase
  Future<void> initialize() async {
    try {
      if (_auth.currentUser == null) {
        print('🔐 Connexion anonyme...');
        final userCredential = await _auth.signInAnonymously();
        print('✅ Connecté: ${userCredential.user?.uid}');

        // Créer ou récupérer le profil
        await _ensureUserProfile(userCredential.user!.uid);
      } else {
        print('✅ Déjà connecté: ${_auth.currentUser?.uid}');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur Firebase: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Assure qu'un profil utilisateur existe
  Future<void> _ensureUserProfile(String uid) async {
    final userDoc = await _usersRef.doc(uid).get();
    if (!userDoc.exists) {
      await _usersRef.doc(uid).set({
        'uid': uid,
        'nickname': 'Joueur${uid.substring(0, 4)}',
        'elo': 1000,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('📝 Profil créé pour $uid');
    }
  }

  /// Récupère le profil utilisateur
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) {
      await _ensureUserProfile(uid);
      return getUserProfile(uid);
    }
    return doc.data() as Map<String, dynamic>;
  }

  /// Met à jour le pseudo
  Future<void> updateNickname(String uid, String nickname) async {
    await _usersRef.doc(uid).update({'nickname': nickname});
    print('✅ Pseudo mis à jour: $nickname');
  }

  /// Met à jour le profil utilisateur (plus générique)
  Future<void> updateUserProfile(String uid,
      {String? nickname, int? elo}) async {
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    if (elo != null) updates['elo'] = elo;

    if (updates.isNotEmpty) {
      await _usersRef.doc(uid).update(updates);
      print('✅ Profil mis à jour');
    }
  }

  // ============================================================
  // CRÉATION & RECHERCHE DE MATCH (WAITING ROOM)
  // ============================================================

  /// 1. Créer un match et ATTENDRE un adversaire
  Future<String> createMatchAndWait({required int playerElo}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Non connecté");

    final userProfile = await getUserProfile(user.uid);
    final matchRef = _matchesRef.doc();

    // Générer les puzzles en fonction de l'ELO
    final puzzles =
        PuzzleGenerator.generateByElo(count: 25, averageElo: playerElo);
    final puzzleMaps = puzzles.map((p) => p.toJson()).toList();

    print('🎮 Création du match: ${matchRef.id} (ELO: $playerElo)');

    await matchRef.set({
      'matchId': matchRef.id,
      'status': 'waiting', // CRUCIAL: En attente d'adversaire
      'createdAt': FieldValue.serverTimestamp(),
      'puzzles': puzzleMaps,
      'averageElo': playerElo, // Stocker l'ELO pour recalcul à la jointure
      'player1': {
        'uid': user.uid,
        'nickname': userProfile['nickname'] ?? 'Joueur 1',
        'elo': userProfile['elo'] ?? 1200,
        'progress': 0.0,
        'score': 0,
        'status': 'active',
      },
      'player2': null, // Pas encore d'adversaire
    });

    print('✅ Match créé en attente: ${matchRef.id}');
    return matchRef.id;
  }

  /// 2. Rechercher et rejoindre un match existant
  Future<String?> findAndJoinMatch() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userProfile = await getUserProfile(user.uid);
    final myElo = userProfile['elo'] as int? ?? 1200;

    print('🔍 Recherche d\'un match disponible...');

    // Chercher un match en attente (query simplifiée sans index)
    final query =
        await _matchesRef.where('status', isEqualTo: 'waiting').limit(5).get();

    if (query.docs.isEmpty) {
      print('❌ Aucun match trouvé');
      return null;
    }

    // Filtrer manuellement pour éviter de rejoindre son propre match
    DocumentSnapshot? availableMatch;
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final player1Uid = data['player1']?['uid'];
      if (player1Uid != user.uid) {
        availableMatch = doc;
        break;
      }
    }

    if (availableMatch == null) {
      print('❌ Aucun match compatible trouvé');
      return null;
    }

    final matchId = availableMatch.id;
    final matchData = availableMatch.data() as Map<String, dynamic>;
    final player1Data = matchData['player1'] as Map<String, dynamic>;
    final player1Elo = player1Data['elo'] as int? ?? 1200;

    // Calculer l'ELO moyen des deux joueurs
    final averageElo = ((player1Elo + myElo) / 2).round();

    // Regénérer les puzzles avec l'ELO moyen
    final newPuzzles =
        PuzzleGenerator.generateByElo(count: 25, averageElo: averageElo);
    final puzzleMaps = newPuzzles.map((p) => p.toJson()).toList();

    print(
        '🔄 Recalcul puzzles: ELO moyen = $averageElo (P1: $player1Elo, P2: $myElo)');

    // Rejoindre le match et déclencher le démarrage
    await availableMatch.reference.update({
      'status': 'starting', // Déclencheur pour les 2 joueurs
      'startTime': FieldValue.serverTimestamp(),
      'puzzles': puzzleMaps, // Mettre à jour avec les puzzles adaptés
      'averageElo': averageElo,
      'player2': {
        'uid': user.uid,
        'nickname': userProfile['nickname'] ?? 'Joueur 2',
        'elo': myElo,
        'progress': 0.0,
        'score': 0,
        'status': 'active',
      },
    });

    print('🎯 Match rejoint! Démarrage imminent...');
    return matchId;
  }

  // ============================================================
  // STREAMS TEMPS RÉEL
  // ============================================================

  /// 3. ÉCOUTER le match en temps réel (Met à jour l'UI)
  Stream<DocumentSnapshot> streamMatch(String matchId) {
    print('👂 Écoute du match: $matchId');
    return _matchesRef.doc(matchId).snapshots();
  }

  /// Stream typé pour le modèle MatchModel
  Stream<MatchModel> streamMatchModel(String matchId) {
    return streamMatch(matchId).map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Match introuvable');
      }
      final data = snapshot.data() as Map<String, dynamic>;
      return MatchModel.fromMap(data);
    });
  }

  // ============================================================
  // MISE À JOUR PROGRESSION
  // ============================================================

  /// 4. Mettre à jour sa progression (Barre de progression adversaire)
  Future<void> updateProgress({
    required String matchId,
    required String uid,
    required double percentage,
    required int score,
  }) async {
    try {
      final matchDoc = await _matchesRef.doc(matchId).get();
      if (!matchDoc.exists) return;

      final matchData = matchDoc.data() as Map<String, dynamic>;
      final player1 = matchData['player1'] as Map<String, dynamic>;

      final isPlayer1 = player1['uid'] == uid;
      final field = isPlayer1 ? 'player1' : 'player2';

      await _matchesRef.doc(matchId).update({
        '$field.progress': percentage,
        '$field.score': score,
      });

      print(
          '📊 Progression mise à jour: ${(percentage * 100).toStringAsFixed(1)}%');
    } catch (e) {
      print('⚠️ Erreur mise à jour progression: $e');
      // Ne pas bloquer le jeu
    }
  }

  /// 5. Marquer un joueur comme terminé
  Future<void> finishPlayer({
    required String matchId,
    required String uid,
  }) async {
    final matchDoc = await _matchesRef.doc(matchId).get();
    if (!matchDoc.exists) return;

    final matchData = matchDoc.data() as Map<String, dynamic>;
    final player1 = matchData['player1'] as Map<String, dynamic>;

    final isPlayer1 = player1['uid'] == uid;
    final field = isPlayer1 ? 'player1' : 'player2';

    await _matchesRef.doc(matchId).update({
      '$field.status': 'finished',
      '$field.finishedAt': FieldValue.serverTimestamp(),
    });

    print('🏁 Joueur terminé: $uid');

    // Vérifier si les deux ont fini
    await _checkAndFinishMatch(matchId);
  }

  /// Vérifie et termine le match dès que le premier joueur finit
  Future<void> _checkAndFinishMatch(String matchId) async {
    final matchDoc = await _matchesRef.doc(matchId).get();
    if (!matchDoc.exists) return;

    final matchData = matchDoc.data() as Map<String, dynamic>;
    final player1 = matchData['player1'] as Map<String, dynamic>;
    final player2 = matchData['player2'] as Map<String, dynamic>?;

    if (player2 == null) return;

    final p1Finished = player1['status'] == 'finished';
    final p2Finished = player2['status'] == 'finished';

    // Le match se termine dès que le PREMIER joueur finit (course de vitesse)
    if (p1Finished || p2Finished) {
      await _matchesRef.doc(matchId).update({
        'status': 'finished',
        'finishedAt': FieldValue.serverTimestamp(),
      });

      print('🎉 Match terminé! (Premier joueur a fini)');
    }
  }

  /// Démarrer le match (appelé après le compte à rebours)
  Future<void> startMatch(String matchId) async {
    await _matchesRef.doc(matchId).update({
      'status': 'playing',
      'startedAt': FieldValue.serverTimestamp(),
    });
    print('▶️ Match démarré: $matchId');
  }

  /// Quitter un match
  Future<void> leaveMatch(String matchId, String uid) async {
    try {
      final matchDoc = await _matchesRef.doc(matchId).get();
      if (!matchDoc.exists) return;

      final matchData = matchDoc.data() as Map<String, dynamic>;

      // Si le match n'a pas commencé, le supprimer
      if (matchData['status'] == 'waiting') {
        await _matchesRef.doc(matchId).delete();
        print('🗑️ Match supprimé: $matchId');
      } else {
        // Marquer comme abandonné
        final player1 = matchData['player1'] as Map<String, dynamic>;
        final field = player1['uid'] == uid ? 'player1' : 'player2';

        await _matchesRef.doc(matchId).update({
          '$field.status': 'abandoned',
        });
        print('👋 Match abandonné par $uid');
      }
    } catch (e) {
      print('⚠️ Erreur abandon match: $e');
    }
  }

  void dispose() {
    // Nettoyage si nécessaire
  }
}
