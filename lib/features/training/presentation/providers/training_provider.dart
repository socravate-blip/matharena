import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/logic/training_engine.dart';
import '../../domain/logic/spn_calculator.dart';
import '../../domain/models/training_models.dart';
import '../../domain/repositories/training_session_storage.dart';

class TrainingState {
  // Configuration
  final int sessionDurationSeconds;
  final int minNumber;
  final int maxNumber;
  final Set<TrainingOperator> enabledOperators;
  final bool allowNegative;

  // Session active
  final bool isPlaying;
  final TrainingQuestion? currentQuestion;
  final String userInput;
  final int remainingSeconds;
  final DateTime? questionStartTime;
  final List<QuestionResult> currentSessionResults;

  // Feedback
  final String message;
  final bool showFeedback;

  // Historique
  final List<TrainingSession> sessionHistory;
  final bool isLoadingHistory;

  TrainingState({
    this.sessionDurationSeconds = 60,
    this.minNumber = 1,
    this.maxNumber = 10,
    Set<TrainingOperator>? enabledOperators,
    this.allowNegative = false,
    this.isPlaying = false,
    this.currentQuestion,
    this.userInput = '',
    this.remainingSeconds = 60,
    this.questionStartTime,
    List<QuestionResult>? currentSessionResults,
    this.message = '',
    this.showFeedback = false,
    List<TrainingSession>? sessionHistory,
    this.isLoadingHistory = false,
  })  : enabledOperators = enabledOperators ?? TrainingOperator.values.toSet(),
        currentSessionResults = currentSessionResults ?? [],
        sessionHistory = sessionHistory ?? [];

  TrainingState copyWith({
    int? sessionDurationSeconds,
    int? minNumber,
    int? maxNumber,
    Set<TrainingOperator>? enabledOperators,
    bool? allowNegative,
    bool? isPlaying,
    TrainingQuestion? currentQuestion,
    String? userInput,
    int? remainingSeconds,
    DateTime? questionStartTime,
    List<QuestionResult>? currentSessionResults,
    String? message,
    bool? showFeedback,
    List<TrainingSession>? sessionHistory,
    bool? isLoadingHistory,
  }) {
    return TrainingState(
      sessionDurationSeconds: sessionDurationSeconds ?? this.sessionDurationSeconds,
      minNumber: minNumber ?? this.minNumber,
      maxNumber: maxNumber ?? this.maxNumber,
      enabledOperators: enabledOperators ?? this.enabledOperators,
      allowNegative: allowNegative ?? this.allowNegative,
      isPlaying: isPlaying ?? this.isPlaying,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      userInput: userInput ?? this.userInput,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      currentSessionResults: currentSessionResults ?? this.currentSessionResults,
      message: message ?? this.message,
      showFeedback: showFeedback ?? this.showFeedback,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  // Métriques session courante
  int get currentScore => currentSessionResults.where((r) => r.isCorrect).length;
  int get currentTotalQuestions => currentSessionResults.length;
  double get currentSPN => SPNCalculator.calculateSessionSPN(currentSessionResults);
}

class TrainingNotifier extends Notifier<TrainingState> {
  final TrainingEngine _engine = TrainingEngine();
  Timer? _sessionTimer;
  Timer? _feedbackTimer;

  @override
  TrainingState build() {
    // Load history asynchronously without blocking initialization
    Future.microtask(() => _loadHistory());
    return TrainingState();
  }

  // Configuration
  void updateSessionDuration(int seconds) {
    state = state.copyWith(sessionDurationSeconds: seconds);
  }

  void updateMaxNumber(int maxNumber) {
    state = state.copyWith(maxNumber: maxNumber);
  }

  void toggleOperator(TrainingOperator operator) {
    final newOperators = Set<TrainingOperator>.from(state.enabledOperators);
    if (newOperators.contains(operator)) {
      if (newOperators.length > 1) {
        newOperators.remove(operator);
      }
    } else {
      newOperators.add(operator);
    }
    state = state.copyWith(enabledOperators: newOperators);
  }

  void toggleAllowNegative() {
    state = state.copyWith(allowNegative: !state.allowNegative);
  }

  // Gestion session
  void startTraining() {
    final question = _engine.generateQuestion(
      minNumber: state.minNumber,
      maxNumber: state.maxNumber,
      enabledOperators: state.enabledOperators.toList(),
      allowNegative: state.allowNegative,
    );

    state = state.copyWith(
      isPlaying: true,
      currentQuestion: question,
      userInput: '',
      remainingSeconds: state.sessionDurationSeconds,
      questionStartTime: DateTime.now(),
      currentSessionResults: [],
      message: '',
      showFeedback: false,
    );

    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        _endSession();
        timer.cancel();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  Future<void> _endSession() async {
    _sessionTimer?.cancel();

    final session = TrainingSession(
      date: DateTime.now(),
      durationSeconds: state.sessionDurationSeconds,
      minNumber: state.minNumber,
      maxNumber: state.maxNumber,
      enabledOperators: state.enabledOperators,
      allowNegative: state.allowNegative,
      results: state.currentSessionResults,
    );

    // Sauvegarder la session
    final storage = ref.read(trainingSessionStorageProvider);
    await storage.saveSession(session);

    // Recharger l'historique
    await _loadHistory();

    state = state.copyWith(
      isPlaying: false,
      currentQuestion: null,
      userInput: '',
      message: 'Session terminée! SPN: ${session.spn.toStringAsFixed(2)}',
      showFeedback: true,
    );
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoadingHistory: true);
    final storage = ref.read(trainingSessionStorageProvider);
    final history = await storage.getRecentSessions(20);
    state = state.copyWith(
      sessionHistory: history,
      isLoadingHistory: false,
    );
  }

  void stopTraining() {
    _sessionTimer?.cancel();
    state = state.copyWith(
      isPlaying: false,
      currentQuestion: null,
      userInput: '',
      currentSessionResults: [],
    );
  }

  // Input utilisateur
  void addInput(String digit) {
    if (!state.isPlaying || state.currentQuestion == null) return;

    // Permettre signe négatif au début uniquement
    if (digit == '-' && state.userInput.isEmpty) {
      state = state.copyWith(userInput: digit);
      return;
    }

    if (digit == '-') return;

    final newInput = state.userInput + digit;
    state = state.copyWith(userInput: newInput);

    // VALIDATION AUTOMATIQUE
    _checkAutoValidation();
  }

  void backspace() {
    if (state.userInput.isEmpty) return;
    final newInput = state.userInput.substring(0, state.userInput.length - 1);
    state = state.copyWith(userInput: newInput);
  }

  /// VALIDATION AUTOMATIQUE - cœur du système
  void _checkAutoValidation() {
    if (state.currentQuestion == null || state.userInput.isEmpty) return;

    final userAnswer = int.tryParse(state.userInput);
    if (userAnswer == null) return;

    final correctAnswer = state.currentQuestion!.correctAnswer;

    // Si la réponse est correcte, valider immédiatement
    if (userAnswer == correctAnswer) {
      _validateAnswer(isCorrect: true, userAnswer: userAnswer);
    }
  }

  /// Validation manuelle (si bouton submit utilisé)
  void submitAnswer() {
    if (state.currentQuestion == null || state.userInput.isEmpty) return;

    final userAnswer = int.tryParse(state.userInput);
    if (userAnswer == null) return;

    final isCorrect = userAnswer == state.currentQuestion!.correctAnswer;
    _validateAnswer(isCorrect: isCorrect, userAnswer: userAnswer);
  }

  void _validateAnswer({required bool isCorrect, required int userAnswer}) {
    if (state.currentQuestion == null || state.questionStartTime == null) return;

    final timeSeconds = DateTime.now().difference(state.questionStartTime!).inMilliseconds / 1000;

    final result = QuestionResult(
      operand1: state.currentQuestion!.operand1,
      operand2: state.currentQuestion!.operand2,
      operator: state.currentQuestion!.operator,
      correctAnswer: state.currentQuestion!.correctAnswer,
      userAnswer: userAnswer,
      timeSeconds: timeSeconds,
      difficultyCoefficient: state.currentQuestion!.difficultyCoefficient,
      isCorrect: isCorrect,
    );

    final updatedResults = [...state.currentSessionResults, result];

    // Générer nouvelle question
    final nextQuestion = _engine.generateQuestion(
      minNumber: state.minNumber,
      maxNumber: state.maxNumber,
      enabledOperators: state.enabledOperators.toList(),
      allowNegative: state.allowNegative,
    );

    state = state.copyWith(
      currentSessionResults: updatedResults,
      currentQuestion: nextQuestion,
      questionStartTime: DateTime.now(),
      userInput: '',
      message: isCorrect ? '✓' : '✗ ${state.currentQuestion!.correctAnswer}',
      showFeedback: true,
    );

    // Masquer feedback après 800ms
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      state = state.copyWith(showFeedback: false, message: '');
    });
  }
}

final trainingProvider = NotifierProvider<TrainingNotifier, TrainingState>(() {
  return TrainingNotifier();
});
