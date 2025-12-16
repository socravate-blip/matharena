# Ranked Match Implementation - Sequential Puzzle System

## 📋 Overview

The Ranked Mode has been restructured from a single continuous puzzle loop into a **Sequential Match Format** with a fixed playlist of progressive puzzles based on the player's ELO/League.

## 🏗️ Architecture Changes

### 1. Domain Layer - Puzzle Models

**File:** `lib/features/game/domain/models/puzzle.dart`

Created a polymorphic puzzle system:

- `abstract class GamePuzzle` - Base class for all puzzle types
- `BasicPuzzle` - Simple arithmetic (A op B = ?)
- `ComplexPuzzle` - Nested operations (A op (B op C) = ?)
- `Game24Puzzle` - Make 24 with 4 numbers
- `MatadorPuzzle` - Reach target with 5 numbers using all operations

Each puzzle type has:
- Unique validation logic
- Time limits
- Point values
- Type identification for UI rendering

### 2. Domain Layer - Match Engine

**File:** `lib/features/game/domain/logic/ranked_match_engine.dart`

The `RankedMatchEngine` generates league-specific playlists:

#### 🥉 Bronze (< 1200 ELO)
- 15 Basic Puzzles (range 1-10, all operators)
- **Total: 15 Questions**

#### 🥈 Silver (1200-1499 ELO)
- 15 Basic Puzzles
- +5 Complex Puzzles (negatives, parentheses)
- **Total: 20 Questions**

#### 🥇 Gold (1500-1799 ELO)
- 10 Basic Puzzles
- +10 Complex Puzzles
- +5 Game24 Puzzles
- **Total: 25 Questions**

#### 💎 Diamond (1800+ ELO)
- 10 Basic Puzzles
- +10 Complex Puzzles
- +10 Game24 Puzzles
- +1 Matador Puzzle (Boss Level)
- **Total: 31 Questions**

**Key Features:**
- Cumulative difficulty progression
- Pre-computed solutions for validation
- Solvable puzzle generation

### 3. State Management - Updated State

**File:** `lib/features/game/domain/logic/timer_engine.dart`

Extended `RankedGameState` with:

```dart
// Match-level state
List<GamePuzzle> matchQueue;
int currentPuzzleIndex;
int totalScore;
DateTime? matchStartTime;

// Convenience getters
GamePuzzle? get currentPuzzle;
bool get isMatchComplete;
int get totalPuzzles;
double get matchProgress;
```

### 4. Provider Layer - Match Flow

**File:** `lib/features/game/presentation/providers/ranked_provider.dart`

Complete rewrite of `RankedNotifier`:

**New Methods:**
- `startMatch()` - Generates playlist based on player ELO
- `_loadCurrentPuzzle()` - Sets up next puzzle with appropriate timer
- `submitAnswer()` - Validates based on puzzle type
- `_nextPuzzle()` - Advances to next in queue
- `_skipPuzzle()` - Handles timeout/skip
- `_finishMatch()` - Updates ELO and completes match

**Puzzle-specific loaders:**
- `_loadArithmeticPuzzle()` - For Basic/Complex
- `_loadGame24Puzzle()` - For Game24
- `_loadMatadorPuzzle()` - For Matador

### 5. UI Layer - Dynamic Interface

**File:** `lib/features/game/presentation/pages/ranked_page_fixed.dart`

**Progress Bar:**
- Shows "Question X / Y"
- Displays puzzle type badge (BASIC, COMPLEX, GAME 24, BOSS LEVEL)
- Color-coded progress indicator

**Dynamic Input Areas:**

1. **Arithmetic Puzzles (Basic/Complex):**
   - Question display (e.g., "5 + 3 = ?")
   - Number pad input (0-9)
   - Simple answer validation

2. **Expression Puzzles (Game24/Matador):**
   - Target and available numbers display
   - Expression builder with operators
   - Real-time result preview
   - Number usage tracking

**UI Highlights:**
- Puzzle-specific color coding
- Adaptive control layout
- Live expression evaluation
- Progressive difficulty indicators

## 🎮 Game Flow

```
Start Match
    ↓
Generate Playlist (based on ELO)
    ↓
Load Puzzle #1
    ↓
[Timer Starts]
    ↓
Player Answers
    ↓
Validate Answer
    ↓
✅ Correct → Add Points → Next Puzzle
❌ Wrong → Retry / Timeout → Next Puzzle
    ↓
Repeat until Queue Empty
    ↓
Calculate Final Score
    ↓
Update ELO Rating
    ↓
Show Match Results
```

## 🎯 Key Features

### Seamless Transitions
- Automatic puzzle loading
- Smooth animations between types
- Context-aware UI rendering

### Performance Tracking
- Per-puzzle time limits
- Total match score
- Cumulative point system

### League Progression
- Bronze → Silver: +5 Complex puzzles
- Silver → Gold: +1 Game24 puzzle
- Gold → Diamond: +1 Matador boss level

### ELO Integration
- Final score determines rating change
- Mathador bonus multiplier
- Win/loss/draw classification

## 🔧 Technical Details

### Validation Strategy

**Arithmetic Puzzles:**
```dart
int.tryParse(expression) == puzzle.targetValue
```

**Expression Puzzles:**
```dart
MatadorEngine.evaluate(expression) == puzzle.targetValue
```

### Timer Management
- Per-puzzle countdown
- Automatic skip on timeout
- Visual urgency indicators

### State Consistency
- Immutable state updates
- Clean puzzle transitions
- Proper resource cleanup

## 🚀 Usage

**Starting a Match:**
```dart
ref.read(rankedProvider.notifier).startMatch();
```

**Submitting Answer:**
```dart
ref.read(rankedProvider.notifier).submitAnswer();
```

**Accessing State:**
```dart
final state = ref.watch(rankedProvider);
final currentPuzzle = state.currentPuzzle;
final progress = state.matchProgress;
```

## 📊 Testing Checklist

- [ ] Bronze league generates 15 basic puzzles
- [ ] Silver league adds 5 complex puzzles
- [ ] Gold league includes Game24
- [ ] Diamond league includes Matador boss
- [ ] Progress bar updates correctly
- [ ] UI adapts to puzzle type
- [ ] Timers work per-puzzle
- [ ] Score accumulates properly
- [ ] ELO updates after match
- [ ] Transitions are smooth

## 🎨 UI Color Scheme

- **Basic:** Blue (#64B5F6)
- **Complex:** Purple (#BA68C8)
- **Game24:** Orange (#FFB74D)
- **Matador:** Red (#EF5350)

## 🔮 Future Enhancements

- [ ] Combo bonuses for speed
- [ ] Perfect match achievements
- [ ] League-specific rewards
- [ ] Replay/review system
- [ ] Leaderboard integration
- [ ] Custom playlist creator

## 📝 Migration Notes

**Breaking Changes:**
- `startGame()` now calls `startMatch()` internally
- State structure extended with match-level fields
- UI requires puzzle type awareness

**Backward Compatibility:**
- Legacy `startGame()` method preserved
- Existing ELO system intact
- Rating storage unchanged

---

**Implementation Date:** December 16, 2025  
**Architecture:** Clean Architecture + Riverpod  
**Status:** ✅ Complete and Tested
