import 'dart:math';
import '../models/puzzle.dart';
import './matador_engine.dart';

/// Engine for generating ranked match playlists based on player ELO/League
class RankedMatchEngine {
  final Random _random = Random();
  final MatadorEngine _matadorEngine = MatadorEngine();

  /// Generates a complete match playlist based on player's ELO rating
  /// New distribution focuses more on Game24 puzzles at higher levels
  List<GamePuzzle> generateMatchPlaylist(int playerElo) {
    final List<GamePuzzle> playlist = [];
    int puzzleId = 0;

    if (playerElo < 1200) {
      // 🥉 BRONZE: 15 Basic Puzzles
      playlist.addAll(_generateBasicPuzzles(15, puzzleId));
      puzzleId += 15;
    } else if (playerElo < 1500) {
      // 🥈 SILVER: 15 Basic + 5 Complex
      playlist.addAll(_generateBasicPuzzles(15, puzzleId));
      puzzleId += 15;
      playlist.addAll(_generateComplexPuzzles(5, puzzleId));
      puzzleId += 5;
    } else if (playerElo < 1800) {
      // 🥇 GOLD: 10 Basic + 10 Complex + 5 Game24
      playlist.addAll(_generateBasicPuzzles(10, puzzleId));
      puzzleId += 10;
      playlist.addAll(_generateComplexPuzzles(10, puzzleId));
      puzzleId += 10;
      for (int i = 0; i < 5; i++) {
        playlist.add(_generateGame24Puzzle(puzzleId));
        puzzleId++;
      }
    } else {
      // 💎 DIAMOND: 10 Basic + 10 Complex + 10 Game24 + 1 Matador
      playlist.addAll(_generateBasicPuzzles(10, puzzleId));
      puzzleId += 10;
      playlist.addAll(_generateComplexPuzzles(10, puzzleId));
      puzzleId += 10;
      for (int i = 0; i < 10; i++) {
        playlist.add(_generateGame24Puzzle(puzzleId));
        puzzleId++;
      }
      playlist.add(_generateMatadorPuzzle(puzzleId));
      puzzleId++;
    }

    return playlist;
  }

  /// Generates basic arithmetic puzzles: A op B = ?
  List<BasicPuzzle> _generateBasicPuzzles(int count, int startId) {
    final List<BasicPuzzle> puzzles = [];
    final operators = ['+', '-', '*', '/'];

    for (int i = 0; i < count; i++) {
      final operator = operators[_random.nextInt(operators.length)];
      int numberA, numberB, result;

      switch (operator) {
        case '+':
          numberA = _random.nextInt(10) + 1;
          numberB = _random.nextInt(10) + 1;
          result = numberA + numberB;
          break;
        case '-':
          numberA = _random.nextInt(15) + 5;
          numberB = _random.nextInt(numberA) + 1;
          result = numberA - numberB;
          break;
        case '*':
          numberA = _random.nextInt(10) + 1;
          numberB = _random.nextInt(10) + 1;
          result = numberA * numberB;
          break;
        case '/':
          numberB = _random.nextInt(9) + 2;
          final quotient = _random.nextInt(10) + 1;
          numberA = numberB * quotient;
          result = quotient;
          break;
        default:
          numberA = 0;
          numberB = 0;
          result = 0;
      }

      puzzles.add(BasicPuzzle(
        id: 'basic_${startId + i}',
        targetValue: result,
        numberA: numberA,
        numberB: numberB,
        operator: operator,
      ));
    }

    return puzzles;
  }

  /// Generates complex puzzles with nested operations
  List<ComplexPuzzle> _generateComplexPuzzles(int count, int startId) {
    final List<ComplexPuzzle> puzzles = [];
    final operators = ['+', '-', '*', '/'];

    for (int i = 0; i < count; i++) {
      final op1 = operators[_random.nextInt(operators.length)];
      final op2 = operators[_random.nextInt(operators.length)];

      int numberA, numberB, numberC, result;

      // Generate numbers that work well together
      numberB = _random.nextInt(10) + 1;
      numberC = _random.nextInt(10) + 1;

      // Calculate inner result first (B op2 C)
      int innerResult;
      switch (op2) {
        case '+':
          innerResult = numberB + numberC;
          break;
        case '-':
          // Ensure non-negative
          if (numberB < numberC) {
            final temp = numberB;
            numberB = numberC;
            numberC = temp;
          }
          innerResult = numberB - numberC;
          break;
        case '*':
          innerResult = numberB * numberC;
          break;
        case '/':
          // Make it evenly divisible
          numberC = _random.nextInt(5) + 1;
          numberB = numberC * (_random.nextInt(5) + 1);
          innerResult = numberB ~/ numberC;
          break;
        default:
          innerResult = 0;
      }

      // Now calculate A op1 innerResult
      numberA = _random.nextInt(20) + 1;
      switch (op1) {
        case '+':
          result = numberA + innerResult;
          break;
        case '-':
          numberA = innerResult + _random.nextInt(15) + 1;
          result = numberA - innerResult;
          break;
        case '*':
          numberA = _random.nextInt(5) + 1;
          result = numberA * innerResult;
          break;
        case '/':
          numberA = innerResult * (_random.nextInt(5) + 1);
          result = numberA ~/ innerResult;
          break;
        default:
          result = 0;
      }

      puzzles.add(ComplexPuzzle(
        id: 'complex_${startId + i}',
        targetValue: result,
        numberA: numberA,
        numberB: numberB,
        numberC: numberC,
        operator1: op1,
        operator2: op2,
        useParentheses: true,
        allowNegatives: true,
      ));
    }

    return puzzles;
  }

  /// Generates a Game 24 puzzle with unique numbers and guaranteed solutions
  Game24Puzzle _generateGame24Puzzle(int puzzleId) {
    // Verified solvable Game24 combinations - final clean list
    final game24Sets = [
      [1, 2, 3, 4], // (1+2+3)*4 = 24
      [2, 3, 4, 5], // 2*(3+4+5) = 24
      [1, 3, 4, 6], // 6/(1-3/4) = 24
      [2, 4, 5, 6], // 6*5-4-2 = 24
      [3, 5, 7, 9], // 9*5-7*3 = 24
      [1, 3, 8, 9], // 9*8/3 = 24
      [2, 5, 6, 7], // (7-5)*6*2 = 24
      [3, 4, 6, 8], // (8+4)*6/3 = 24
      [2, 3, 7, 8], // (8-2)*(7-3) = 24
      [1, 4, 5, 6], // 6/(5/4-1) = 24
      [2, 6, 7, 9], // (9-7)*6*2 = 24
      [2, 4, 6, 9], // (9-6)*4*2 = 24
      [1, 4, 8, 9], // 9*8/(4-1) = 24
      [1, 5, 6, 9], // (9-5)*6 = 24
      [3, 4, 7, 9], // (9-7)*4*3 = 24
      [1, 3, 6, 7], // (7-3)*6 = 24
      [1, 6, 8, 9], // (9-6)*8 = 24
      [1, 2, 8, 9], // 9*8/(2+1) = 24
      [3, 6, 8, 9], // 9*8/(6-3) = 24
    ];

    final numbers = game24Sets[_random.nextInt(game24Sets.length)];

    return Game24Puzzle(
      id: 'game24_$puzzleId',
      availableNumbers: numbers,
    );
  }

  /// Generates a Matador puzzle using the existing MatadorEngine
  MatadorPuzzle _generateMatadorPuzzle(int puzzleId) {
    final level = _matadorEngine.generateLevel();
    final target = level['target'] as int;
    final numbers = level['numbers'] as List<int>;

    // Pre-compute solutions for validation
    final solutions = _matadorEngine.solve(numbers, target);

    return MatadorPuzzle(
      id: 'matador_$puzzleId',
      targetValue: target,
      availableNumbers: numbers,
      validSolutions: solutions.toSet(),
      solutionCount: solutions.length,
    );
  }

  /// Gets the total number of puzzles for a given ELO
  int getTotalPuzzleCount(int playerElo) {
    int count = 15; // Bronze baseline
    if (playerElo >= 1200) count += 5; // Silver
    if (playerElo >= 1500) count += 1; // Gold
    if (playerElo >= 1800) count += 1; // Diamond
    return count;
  }

  /// Gets league name from ELO
  String getLeagueName(int playerElo) {
    if (playerElo < 1200) return 'Bronze';
    if (playerElo < 1500) return 'Silver';
    if (playerElo < 1800) return 'Gold';
    return 'Diamond';
  }

  /// Gets league icon from ELO
  String getLeagueIcon(int playerElo) {
    if (playerElo < 1200) return '🥉';
    if (playerElo < 1500) return '🥈';
    if (playerElo < 1800) return '🥇';
    return '💎';
  }
}
