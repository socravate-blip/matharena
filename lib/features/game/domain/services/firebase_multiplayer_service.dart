import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/match_model.dart';
import '../logic/puzzle_generator.dart';
import '../models/match_constants.dart';

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
      'status': MatchConstants.matchWaiting, // CRUCIAL: En attente d'adversaire
      'createdAt': FieldValue.serverTimestamp(),
      'puzzles': puzzleMaps,
      'averageElo': playerElo, // Stocker l'ELO pour recalcul à la jointure
      'player1': {
        'uid': user.uid,
        'nickname': userProfile['nickname'] ?? 'Joueur 1',
        'elo': userProfile['elo'] ?? 1200,
        'progress': 0.0,
        'score': 0,
        'status': MatchConstants.playerActive,
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

    // Chercher quelques candidats en attente
    final query = await _matchesRef
        .where('status', isEqualTo: MatchConstants.matchWaiting)
        .limit(10)
        .get();

    if (query.docs.isEmpty) {
      print('❌ Aucun match trouvé');
      return null;
    }

    // Tenter de rejoindre en transaction pour éviter la race condition.
    for (final candidate in query.docs) {
      final matchRef = candidate.reference;
      try {
        final joined = await _firestore.runTransaction<String?>((tx) async {
          final snap = await tx.get(matchRef);
          if (!snap.exists) return null;
          final data = snap.data() as Map<String, dynamic>;

          // Recheck: still waiting and not our own match
          if (data['status'] != MatchConstants.matchWaiting) return null;
          final player1 = data['player1'] as Map<String, dynamic>?;
          final player1Uid = player1?['uid'] as String?;
          if (player1Uid == null || player1Uid == user.uid) return null;
          if (data['player2'] != null) return null;

          final player1Elo = (player1?['elo'] as int?) ?? 1200;
          final averageElo = ((player1Elo + myElo) / 2).round();
          final newPuzzles =
              PuzzleGenerator.generateByElo(count: 25, averageElo: averageElo);
          final puzzleMaps = newPuzzles.map((p) => p.toJson()).toList();

          tx.update(matchRef, {
            'status': MatchConstants.matchStarting,
            'startTime': FieldValue.serverTimestamp(),
            'puzzles': puzzleMaps,
            'averageElo': averageElo,
            'player2': {
              'uid': user.uid,
              'nickname': userProfile['nickname'] ?? 'Joueur 2',
              'elo': myElo,
              'progress': 0.0,
              'score': 0,
              'status': MatchConstants.playerActive,
            },
          });

          return snap.id;
        });

        if (joined != null) {
          print('🎯 Match rejoint (transaction)! Démarrage imminent...');
          return joined;
        }
      } catch (e) {
        // Transaction failed (likely race). Try next candidate.
        print('⚠️ Transaction join failed, retrying: $e');
      }
    }

    print('❌ Aucun match compatible trouvé (après transaction)');
    return null;
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
      final matchRef = _matchesRef.doc(matchId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(matchRef);
        if (!snap.exists) return;

        final matchData = snap.data() as Map<String, dynamic>;
        final player1 = matchData['player1'] as Map<String, dynamic>;
        final isPlayer1 = player1['uid'] == uid;
        final field = isPlayer1 ? 'player1' : 'player2';

        final currentPlayer = matchData[field] as Map<String, dynamic>?;
        if (currentPlayer == null) return;

        final oldProgress = (currentPlayer['progress'] as num?)?.toDouble() ?? 0.0;
        final oldScore = currentPlayer['score'] as int? ?? 0;

        // Clamp and enforce monotonic updates to reduce obvious cheating/noise.
        final clampedProgress = percentage.clamp(0.0, 1.0);

        // Cap score to the total possible score in this match.
        final puzzles = (matchData['puzzles'] as List<dynamic>?);
        final totalMaxScore = puzzles == null
            ? 999999
            : puzzles
                .map((p) => (p as Map)['maxPoints'] as int? ?? 0)
                .fold<int>(0, (a, b) => a + b);

        final clampedScore = score.clamp(0, totalMaxScore);

        final newProgress = clampedProgress < oldProgress ? oldProgress : clampedProgress;
        final newScore = clampedScore < oldScore ? oldScore : clampedScore;

        tx.update(matchRef, {
          '$field.progress': newProgress,
          '$field.score': newScore,
        });
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
      '$field.status': MatchConstants.playerFinished,
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
        'status': MatchConstants.matchFinished,
        'finishedAt': FieldValue.serverTimestamp(),
      });

      print('🎉 Match terminé! (Premier joueur a fini)');
    }
  }

  /// Démarrer le match (appelé après le compte à rebours)
  Future<void> startMatch(String matchId) async {
    await _matchesRef.doc(matchId).update({
      'status': MatchConstants.matchPlaying,
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
      if (matchData['status'] == MatchConstants.matchWaiting) {
        await _matchesRef.doc(matchId).delete();
        print('🗑️ Match supprimé: $matchId');
      } else {
        // Marquer comme abandonné
        final player1 = matchData['player1'] as Map<String, dynamic>;
        final field = player1['uid'] == uid ? 'player1' : 'player2';

        await _matchesRef.doc(matchId).update({
          '$field.status': MatchConstants.playerAbandoned,
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
