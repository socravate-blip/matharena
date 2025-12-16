import 'package:flutter/material.dart';

/// Système de progression basé sur l'ELO avec ligues, divisions et titres
class ProgressionSystem {
  /// Obtenir les détails complets de progression pour un ELO donné
  static ProgressionData getProgressionData(int elo, int gamesPlayed) {
    final league = _getLeague(elo);
    final division = _getDivision(elo, league);
    final title = _getTitle(elo, gamesPlayed);
    final nextMilestone = _getNextMilestone(elo);
    final progressInDivision = _getProgressInDivision(elo, league, division);
    final achievements = _getAchievements(elo, gamesPlayed);

    return ProgressionData(
      elo: elo,
      league: league,
      division: division,
      title: title,
      nextMilestone: nextMilestone,
      progressInDivision: progressInDivision,
      achievements: achievements,
      gamesPlayed: gamesPlayed,
    );
  }

  /// Ligues principales (7 au total)
  static League _getLeague(int elo) {
    if (elo < 800) {
      return League.rookie;
    } else if (elo < 1000) {
      return League.bronze;
    } else if (elo < 1200) {
      return League.silver;
    } else if (elo < 1400) {
      return League.gold;
    } else if (elo < 1600) {
      return League.platinum;
    } else if (elo < 1800) {
      return League.diamond;
    } else if (elo < 2000) {
      return League.master;
    } else {
      return League.grandmaster;
    }
  }

  /// Divisions dans chaque ligue (4 divisions: IV, III, II, I)
  static int _getDivision(int elo, League league) {
    final leagueStart = league.eloRange.start;
    final leagueEnd = league.eloRange.end;
    final leagueSize = leagueEnd - leagueStart;
    final divisionSize = leagueSize / 4;

    final eloInLeague = elo - leagueStart;
    final division = 4 - (eloInLeague / divisionSize).floor();

    return division.clamp(1, 4);
  }

  /// Titre spécial basé sur ELO et expérience
  static String _getTitle(int elo, int gamesPlayed) {
    // Titres spéciaux pour nouveaux joueurs
    if (gamesPlayed < 10) return "Apprenti";
    if (gamesPlayed < 30) return "Débutant";

    // Titres basés sur l'ELO
    if (elo >= 2400) return "Légende Vivante";
    if (elo >= 2200) return "Maître Suprême";
    if (elo >= 2000) return "Grand Maître";
    if (elo >= 1900) return "Maître Élite";
    if (elo >= 1800) return "Maître";
    if (elo >= 1700) return "Expert Diamant";
    if (elo >= 1600) return "As de Diamant";
    if (elo >= 1500) return "Champion Platine";
    if (elo >= 1400) return "Virtuose Platine";
    if (elo >= 1300) return "Prodige Or";
    if (elo >= 1200) return "Étoile Or";
    if (elo >= 1100) return "Talent Argent";
    if (elo >= 1000) return "Éclaireur Argent";
    if (elo >= 900) return "Guerrier Bronze";
    if (elo >= 800) return "Soldat Bronze";

    // Titres encourageants pour bas ELO
    if (gamesPlayed >= 50) return "Vétéran Déterminé";
    return "Challenger";
  }

  /// Récupère tous les jalons de progression
  static List<Milestone> getAllMilestones() {
    return [
      Milestone(
          elo: 800,
          name: "Bronze",
          description: "Entrez en Bronze",
          reward: "🥉 Badge Bronze"),
      Milestone(
          elo: 1000,
          name: "Argent",
          description: "Montez en Argent",
          reward: "🥈 Badge Argent"),
      Milestone(
          elo: 1200,
          name: "Or",
          description: "Atteignez l'Or",
          reward: "🥇 Badge Or"),
      Milestone(
          elo: 1400,
          name: "Platine",
          description: "Devenez Platine",
          reward: "💍 Badge Platine"),
      Milestone(
          elo: 1600,
          name: "Diamant",
          description: "Brillez en Diamant",
          reward: "💎 Badge Diamant + Jeu de 24"),
      Milestone(
          elo: 1800,
          name: "Master",
          description: "Devenez Master",
          reward: "👑 Couronne + Mathadore"),
      Milestone(
          elo: 2000,
          name: "Grand Master",
          description: "Rejoignez l'élite",
          reward: "🌟 Étoile Légendaire"),
      Milestone(
          elo: 2200,
          name: "Légende",
          description: "Statut légendaire",
          reward: "⚡ Aura Légendaire"),
      Milestone(
          elo: 2500,
          name: "Dieu Mathématique",
          description: "Transcendance",
          reward: "✨ Titre Divin"),
    ];
  }

  /// Prochain jalon de progression
  static Milestone _getNextMilestone(int elo) {
    final milestones = getAllMilestones();

    return milestones.firstWhere(
      (m) => m.elo > elo,
      orElse: () => Milestone(
        elo: 3000,
        name: "Perfection",
        description: "Au-delà de l'humain",
        reward: "🏆 Trophée Ultime",
      ),
    );
  }

  /// Progression dans la division actuelle (0.0 à 1.0)
  static double _getProgressInDivision(int elo, League league, int division) {
    final leagueStart = league.eloRange.start;
    final leagueEnd = league.eloRange.end;
    final leagueSize = leagueEnd - leagueStart;
    final divisionSize = leagueSize / 4;

    final divisionStart = leagueStart + ((4 - division) * divisionSize);
    final eloInDivision = elo - divisionStart;

    return (eloInDivision / divisionSize).clamp(0.0, 1.0);
  }

  /// Achievements débloqués
  static List<Achievement> _getAchievements(int elo, int gamesPlayed) {
    final achievements = <Achievement>[];

    // Achievements de progression
    if (elo >= 1000)
      achievements.add(Achievement(
          name: "Argenté", icon: "🥈", description: "Atteindre 1000 ELO"));
    if (elo >= 1200)
      achievements.add(Achievement(
          name: "Doré", icon: "🥇", description: "Atteindre 1200 ELO"));
    if (elo >= 1400)
      achievements.add(Achievement(
          name: "Platine", icon: "💍", description: "Atteindre 1400 ELO"));
    if (elo >= 1600)
      achievements.add(Achievement(
          name: "Diamant", icon: "💎", description: "Atteindre 1600 ELO"));
    if (elo >= 1800)
      achievements.add(Achievement(
          name: "Master", icon: "👑", description: "Atteindre 1800 ELO"));

    // Achievements d'expérience
    if (gamesPlayed >= 10)
      achievements.add(Achievement(
          name: "Première Dizaine",
          icon: "🎯",
          description: "Jouer 10 parties"));
    if (gamesPlayed >= 50)
      achievements.add(Achievement(
          name: "Vétéran", icon: "⭐", description: "Jouer 50 parties"));
    if (gamesPlayed >= 100)
      achievements.add(Achievement(
          name: "Centurion", icon: "💯", description: "Jouer 100 parties"));
    if (gamesPlayed >= 500)
      achievements.add(Achievement(
          name: "Légende", icon: "🏆", description: "Jouer 500 parties"));

    return achievements;
  }
}

/// Données de progression complètes
class ProgressionData {
  final int elo;
  final League league;
  final int division; // 1-4 (IV, III, II, I)
  final String title;
  final Milestone nextMilestone;
  final double progressInDivision; // 0.0 à 1.0
  final List<Achievement> achievements;
  final int gamesPlayed;

  ProgressionData({
    required this.elo,
    required this.league,
    required this.division,
    required this.title,
    required this.nextMilestone,
    required this.progressInDivision,
    required this.achievements,
    required this.gamesPlayed,
  });

  /// Nom de la division en chiffres romains
  String get divisionName {
    switch (division) {
      case 1:
        return "I";
      case 2:
        return "II";
      case 3:
        return "III";
      case 4:
        return "IV";
      default:
        return "IV";
    }
  }

  /// ELO nécessaire pour monter de division
  int get eloForNextDivision {
    final divisionSize = (league.eloRange.end - league.eloRange.start) / 4;
    return (league.eloRange.start + ((5 - division) * divisionSize)).round();
  }

  /// Points manquants pour le prochain jalon
  int get pointsToNextMilestone => nextMilestone.elo - elo;
}

/// Ligue (niveau principal)
enum League {
  rookie(
      eloRange: EloRange(0, 800),
      name: "Rookie",
      icon: "🌱",
      color: Color(0xFF8B4513)),
  bronze(
      eloRange: EloRange(800, 1000),
      name: "Bronze",
      icon: "🥉",
      color: Color(0xFFCD7F32)),
  silver(
      eloRange: EloRange(1000, 1200),
      name: "Argent",
      icon: "🥈",
      color: Color(0xFFC0C0C0)),
  gold(
      eloRange: EloRange(1200, 1400),
      name: "Or",
      icon: "🥇",
      color: Color(0xFFFFD700)),
  platinum(
      eloRange: EloRange(1400, 1600),
      name: "Platine",
      icon: "💍",
      color: Color(0xFFE5E4E2)),
  diamond(
      eloRange: EloRange(1600, 1800),
      name: "Diamant",
      icon: "💎",
      color: Color(0xFFB9F2FF)),
  master(
      eloRange: EloRange(1800, 2000),
      name: "Master",
      icon: "👑",
      color: Color(0xFFFF6B6B)),
  grandmaster(
      eloRange: EloRange(2000, 3000),
      name: "Grand Master",
      icon: "🌟",
      color: Color(0xFFFFD700));

  final EloRange eloRange;
  final String name;
  final String icon;
  final Color color;

  const League({
    required this.eloRange,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Plage d'ELO
class EloRange {
  final int start;
  final int end;

  const EloRange(this.start, this.end);
}

/// Jalon de progression
class Milestone {
  final int elo;
  final String name;
  final String description;
  final String reward;

  Milestone({
    required this.elo,
    required this.name,
    required this.description,
    required this.reward,
  });
}

/// Achievement débloquable
class Achievement {
  final String name;
  final String icon;
  final String description;

  Achievement({
    required this.name,
    required this.icon,
    required this.description,
  });
}
