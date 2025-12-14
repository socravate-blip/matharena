import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class ScoreEntry {
  final int score;
  final String mode; // 'ranked' or 'training'
  final DateTime date;
  final int duration; // en secondes

  ScoreEntry({
    required this.score,
    required this.mode,
    required this.date,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'mode': mode,
      'date': date.toIso8601String(),
      'duration': duration,
    };
  }

  factory ScoreEntry.fromMap(Map<String, dynamic> map) {
    return ScoreEntry(
      score: map['score'],
      mode: map['mode'],
      date: DateTime.parse(map['date']),
      duration: map['duration'],
    );
  }
}

class ScoreStorage {
  static const String _scoreKey = 'matharena_scores';
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  List<ScoreEntry> getScores() {
    if (!_initialized) {
      return [];
    }
    final jsonList = _prefs.getStringList(_scoreKey) ?? [];
    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ScoreEntry.fromMap(map);
    }).toList();
  }

  Future<void> saveScore(ScoreEntry entry) async {
    await init();
    final scores = getScores();
    scores.add(entry);
    
    final jsonList = scores.map((s) => jsonEncode(s.toMap())).toList();
    await _prefs.setStringList(_scoreKey, jsonList);
  }

  Future<void> clearScores() async {
    await init();
    await _prefs.remove(_scoreKey);
  }
}

final scoreStorageProvider = Provider<ScoreStorage>((ref) {
  final storage = ScoreStorage();
  // Initialize in background
  storage.init().ignore();
  return storage;
});
