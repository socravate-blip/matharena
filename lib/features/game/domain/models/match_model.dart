/// Modèle pour un match multijoueur en temps réel
/// Gère la synchronisation des deux joueurs
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String matchId;
  final String status; // 'waiting', 'starting', 'playing', 'finished'
  final int createdAt;
  final int? startTime;
  final List<Map<String, dynamic>> puzzles;
  final PlayerData player1;
  final PlayerData? player2;

  const MatchModel({
    required this.matchId,
    required this.status,
    required this.createdAt,
    this.startTime,
    required this.puzzles,
    required this.player1,
    this.player2,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    // Convertir Timestamp en int (millisecondes)
    int convertTimestamp(dynamic value) {
      if (value == null) return 0;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      return 0;
    }

    return MatchModel(
      matchId: map['matchId'] as String,
      status: map['status'] as String,
      createdAt: convertTimestamp(map['createdAt']),
      startTime:
          map['startTime'] != null ? convertTimestamp(map['startTime']) : null,
      puzzles: (map['puzzles'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      player1: PlayerData.fromMap(map['player1'] as Map<String, dynamic>),
      player2: map['player2'] != null
          ? PlayerData.fromMap(map['player2'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'status': status,
      'createdAt': createdAt,
      'startTime': startTime,
      'puzzles': puzzles,
      'player1': player1.toMap(),
      'player2': player2?.toMap(),
    };
  }

  bool get isFull => player2 != null;
  bool get isWaiting => status == 'waiting';
  bool get isStarting => status == 'starting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';

  /// Retourne les données du joueur adverse
  PlayerData? getOpponentData(String myUid) {
    if (player1.uid == myUid) return player2;
    if (player2?.uid == myUid) return player1;
    return null;
  }

  /// Retourne les données de mon joueur
  PlayerData? getPlayerData(String myUid) {
    if (player1.uid == myUid) return player1;
    if (player2?.uid == myUid) return player2;
    return null;
  }

  /// Vérifie si je suis le joueur 1
  bool isPlayer1(String myUid) => player1.uid == myUid;

  MatchModel copyWith({
    String? matchId,
    String? status,
    int? createdAt,
    int? startTime,
    List<Map<String, dynamic>>? puzzles,
    PlayerData? player1,
    PlayerData? player2,
  }) {
    return MatchModel(
      matchId: matchId ?? this.matchId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      puzzles: puzzles ?? this.puzzles,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
    );
  }
}

/// Données d'un joueur dans le match
class PlayerData {
  final String uid;
  final String nickname;
  final double progress; // 0.0 à 1.0
  final int score;
  final String status; // 'active', 'finished'
  final int elo;
  final int? finishedAt; // Timestamp de fin (millisecondes)

  const PlayerData({
    required this.uid,
    required this.nickname,
    this.progress = 0.0,
    this.score = 0,
    this.status = 'active',
    this.elo = 1200,
    this.finishedAt,
  });

  factory PlayerData.fromMap(Map<String, dynamic> map) {
    // Convertir Timestamp en int pour finishedAt
    int? convertFinishedAt(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      return null;
    }

    return PlayerData(
      uid: map['uid'] as String,
      nickname: map['nickname'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      score: map['score'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
      elo: map['elo'] as int? ?? 1200,
      finishedAt: convertFinishedAt(map['finishedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'progress': progress,
      'score': score,
      'status': status,
      'elo': elo,
      'finishedAt': finishedAt,
    };
  }

  PlayerData copyWith({
    String? uid,
    String? nickname,
    double? progress,
    int? score,
    String? status,
    int? elo,
    int? finishedAt,
  }) {
    return PlayerData(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      progress: progress ?? this.progress,
      score: score ?? this.score,
      status: status ?? this.status,
      elo: elo ?? this.elo,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
