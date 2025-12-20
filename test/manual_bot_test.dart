import 'package:test/test.dart';
import 'package:matharena/features/game/domain/logic/bot_ai.dart';
import 'package:matharena/features/game/domain/models/puzzle.dart';

/// Test manuel pour vérifier que les caps fonctionnent
void main() {
  group('Vérification Caps Absolus', () {
    test('Boss Basic Math: Joueur TRÈS lent (20s) -> Bot max 2s', () {
      final bot = BotAI(
        name: 'BossBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      final puzzle = BasicPuzzle(
        id: 'test-1',
        targetValue: 10,
        numberA: 7,
        numberB: 3,
        operator: '+',
      );

      // Joueur AFK qui met 20 secondes
      final delay = bot.calculateDynamicDelay(
        puzzle,
        playerHistoricalAvgMs: 20000, // 20 secondes
      );

      print('🎮 Scénario: Joueur AFK sur Basic Math');
      print('   Temps joueur: 20s');
      print('   Bot Boss calcul: 50-65% de 20s = 10-13s');
      print('   ✅ Cap appliqué: ${delay.inMilliseconds}ms');
      print('   ✅ Résultat: ${delay.inSeconds}s (devrait être 1-2s)');

      // Boss Basic Math = CAP 1-2s max
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(2000));
    });

    test('Underdog Basic Math: Joueur rapide (1s) -> Bot min 2s', () {
      final bot = BotAI(
        name: 'UnderdogBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.underdog,
      );

      final puzzle = BasicPuzzle(
        id: 'test-2',
        targetValue: 10,
        numberA: 7,
        numberB: 3,
        operator: '+',
      );

      // Joueur très rapide
      final delay = bot.calculateDynamicDelay(
        puzzle,
        playerHistoricalAvgMs: 1000, // 1 seconde
      );

      print('\\n🎮 Scénario: Joueur rapide sur Basic Math');
      print('   Temps joueur: 1s');
      print('   Bot Underdog calcul: 140-180% de 1s = 1.4-1.8s');
      print('   ✅ Cap appliqué: ${delay.inMilliseconds}ms');
      print('   ✅ Résultat: ${delay.inSeconds}s (devrait être 2-4s)');

      // Underdog Basic Math = CAP min 2s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(4000));
    });

    test('Boss Game24: Joueur lent (30s) -> Bot max 10s', () {
      final bot = BotAI(
        name: 'BossBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      final puzzle = Game24Puzzle(
        id: 'test-3',
        targetValue: 24,
        availableNumbers: [3, 8, 3, 8],
      );

      // Joueur qui galère
      final delay = bot.calculateDynamicDelay(
        puzzle,
        playerHistoricalAvgMs: 30000, // 30 secondes
      );

      print('\\n🎮 Scénario: Joueur lent sur Game24');
      print('   Temps joueur: 30s');
      print('   Bot Boss calcul: 50-65% de 30s = 15-19.5s');
      print('   ✅ Cap appliqué: ${delay.inMilliseconds}ms');
      print('   ✅ Résultat: ${delay.inSeconds}s (devrait être 5-10s)');

      // Boss Game24 = CAP 5-10s max
      expect(delay.inMilliseconds, greaterThanOrEqualTo(5000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(10000));
    });

    test('Competitive Complex: Joueur normal (4s) -> Bot ~4s', () {
      final bot = BotAI(
        name: 'CompBot',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      final puzzle = ComplexPuzzle(
        id: 'test-4',
        targetValue: 42,
        numberA: 6,
        numberB: 7,
        operator: '*',
      );

      // Joueur normal
      final delay = bot.calculateDynamicDelay(
        puzzle,
        playerHistoricalAvgMs: 4000, // 4 secondes
      );

      print('\\n🎮 Scénario: Joueur normal sur Advanced Math');
      print('   Temps joueur: 4s');
      print('   Bot Competitive calcul: 95-105% de 4s = 3.8-4.2s');
      print('   ✅ Cap appliqué: ${delay.inMilliseconds}ms');
      print('   ✅ Résultat: ${delay.inSeconds}s (devrait être 3-5s)');

      // Competitive Complex = CAP 3-5s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(3000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(5000));
    });

    test('Test probabilité de succès avec boost de difficulté', () {
      final underdogBot = BotAI(
        name: 'Underdog',
        skillLevel: 1200,
        difficulty: BotDifficulty.underdog,
      );

      final competitiveBot = BotAI(
        name: 'Competitive',
        skillLevel: 1200,
        difficulty: BotDifficulty.competitive,
      );

      final bossBot = BotAI(
        name: 'Boss',
        skillLevel: 1200,
        difficulty: BotDifficulty.boss,
      );

      final puzzle = Game24Puzzle(
        id: 'test-prob',
        targetValue: 24,
        availableNumbers: [3, 8, 3, 8],
      );

      final underdogProb = underdogBot.getSuccessProbability(puzzle);
      final competitiveProb = competitiveBot.getSuccessProbability(puzzle);
      final bossProb = bossBot.getSuccessProbability(puzzle);

      print('\\n📊 Probabilités de succès (Game24):');
      print('   Underdog: ${(underdogProb * 100).toStringAsFixed(1)}%');
      print('   Competitive: ${(competitiveProb * 100).toStringAsFixed(1)}%');
      print('   Boss: ${(bossProb * 100).toStringAsFixed(1)}%');

      // Boss doit avoir la meilleure probabilité
      expect(bossProb, greaterThan(competitiveProb));
      expect(competitiveProb, greaterThan(underdogProb));
      
      // Boss doit avoir ~35% de plus que Competitive
      final boostRatio = bossProb / competitiveProb;
      expect(boostRatio, greaterThan(1.2)); // Au moins 20% de plus
      expect(boostRatio, lessThan(1.5)); // Pas plus de 50%
    });
  });
}
