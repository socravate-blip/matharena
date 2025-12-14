import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_models.dart';

/// Gestion de la persistence des sessions d'entraînement
class TrainingSessionStorage {
  static const String _sessionsKey = 'training_sessions';
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  /// Sauvegarde une nouvelle session
  Future<void> saveSession(TrainingSession session) async {
    await init();
    final sessions = await getSessions();
    sessions.add(session);

    // Limite à 100 sessions max pour éviter surcharge
    if (sessions.length > 100) {
      sessions.removeAt(0);
    }

    final jsonList = sessions.map((s) => jsonEncode(s.toMap())).toList();
    await _prefs!.setStringList(_sessionsKey, jsonList);
  }

  /// Récupère toutes les sessions (triées par date décroissante)
  Future<List<TrainingSession>> getSessions() async {
    await init();
    final jsonList = _prefs!.getStringList(_sessionsKey) ?? [];

    final sessions = jsonList
        .map((json) => TrainingSession.fromMap(jsonDecode(json)))
        .toList();

    // Tri par date décroissante
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  /// Récupère les N dernières sessions
  Future<List<TrainingSession>> getRecentSessions(int count) async {
    final sessions = await getSessions();
    return sessions.take(count).toList();
  }

  /// Récupère les sessions d'une période donnée
  Future<List<TrainingSession>> getSessionsInPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    final sessions = await getSessions();
    return sessions
        .where((s) => s.date.isAfter(start) && s.date.isBefore(end))
        .toList();
  }

  /// Supprime toutes les sessions
  Future<void> clearAllSessions() async {
    await init();
    await _prefs!.remove(_sessionsKey);
  }

  /// Statistiques globales
  Future<Map<String, dynamic>> getGlobalStats() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageSPN': 0.0,
        'bestSPN': 0.0,
        'totalQuestions': 0,
        'totalCorrect': 0,
        'globalSuccessRate': 0.0,
      };
    }

    final spns = sessions.map((s) => s.spn).toList();
    final avgSPN = spns.reduce((a, b) => a + b) / spns.length;
    final bestSPN = spns.reduce((a, b) => a > b ? a : b);
    final totalQuestions = sessions.map((s) => s.totalQuestions).reduce((a, b) => a + b);
    final totalCorrect = sessions.map((s) => s.correctAnswers).reduce((a, b) => a + b);

    return {
      'totalSessions': sessions.length,
      'averageSPN': avgSPN,
      'bestSPN': bestSPN,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'globalSuccessRate': (totalCorrect / totalQuestions) * 100,
    };
  }
}

final trainingSessionStorageProvider = Provider<TrainingSessionStorage>((ref) {
  return TrainingSessionStorage();
});
