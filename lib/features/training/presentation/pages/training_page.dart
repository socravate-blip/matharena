import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/training_provider.dart';
import '../../domain/logic/training_engine.dart';
import '../../domain/logic/spn_calculator.dart';

class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trainingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: state.isPlaying
            ? _buildActiveSession(context, ref, state)
            : _buildConfigAndHistory(context, ref, state),
      ),
    );
  }

  // CONFIG + GRAPHIQUE (quand pas en jeu)
  Widget _buildConfigAndHistory(BuildContext context, WidgetRef ref, TrainingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITRE
          Text(
            'Training',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (state.sessionHistory.isNotEmpty)
            Text(
              'Mental Rating: ${SPNCalculator.spnToMentalRating(state.sessionHistory.first.spn)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          const SizedBox(height: 32),

          // 1️⃣ CONFIGURATION
          _buildConfigSection(ref, state),
          const SizedBox(height: 40),

          // 2️⃣ GRAPHIQUE DE PROGRESSION
          if (state.sessionHistory.isNotEmpty) ...[
            _buildProgressionGraph(state),
            const SizedBox(height: 40),
          ],

          // BOUTON START
          GestureDetector(
            onTap: () => ref.read(trainingProvider.notifier).startTraining(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'START TRAINING',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(WidgetRef ref, TrainingState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Timer
          Text(
            'Session Duration: ${_formatDuration(state.sessionDurationSeconds)}',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.1),
              trackHeight: 2,
            ),
            child: Slider(
              value: state.sessionDurationSeconds.toDouble(),
              min: 30,
              max: 300,
              divisions: 18,
              onChanged: (value) {
                ref.read(trainingProvider.notifier).updateSessionDuration(value.toInt());
              },
            ),
          ),
          const SizedBox(height: 20),

          // Number Range
          Text(
            'Number Range: 1 - ${state.maxNumber}',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.1),
              trackHeight: 2,
            ),
            child: Slider(
              value: state.maxNumber.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              onChanged: (value) {
                ref.read(trainingProvider.notifier).updateMaxNumber(value.toInt());
              },
            ),
          ),
          const SizedBox(height: 24),

          // Operators
          Text(
            'Operators',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildOperatorToggle(ref, TrainingOperator.add, '+', state),
              _buildOperatorToggle(ref, TrainingOperator.subtract, '-', state),
              _buildOperatorToggle(ref, TrainingOperator.multiply, '×', state),
              _buildOperatorToggle(ref, TrainingOperator.divide, '÷', state),
            ],
          ),
          const SizedBox(height: 20),

          // Allow Negative
          GestureDetector(
            onTap: () => ref.read(trainingProvider.notifier).toggleAllowNegative(),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: state.allowNegative ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: state.allowNegative ? Colors.white : Colors.grey[600]!,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: state.allowNegative
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF0A0A0A))
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Allow Negative Results',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorToggle(WidgetRef ref, TrainingOperator op, String symbol, TrainingState state) {
    final isEnabled = state.enabledOperators.contains(op);
    return GestureDetector(
      onTap: () => ref.read(trainingProvider.notifier).toggleOperator(op),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.transparent,
          border: Border.all(
            color: isEnabled ? Colors.white : Colors.grey[800]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            symbol,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: isEnabled ? const Color(0xFF0A0A0A) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressionGraph(TrainingState state) {
    final sessions = state.sessionHistory.reversed.toList();
    final spnValues = sessions.map((s) => s.spn).toList();
    final smoothed = SPNCalculator.calculateMovingAverage(spnValues, window: 3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[900]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: smoothed
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat('Best', state.sessionHistory.map((s) => s.spn).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)),
              _buildStat('Avg', (state.sessionHistory.map((s) => s.spn).reduce((a, b) => a + b) / state.sessionHistory.length).toStringAsFixed(2)),
              _buildStat('Last', state.sessionHistory.first.spn.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // SESSION ACTIVE (pendant le jeu)
  Widget _buildActiveSession(BuildContext context, WidgetRef ref, TrainingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => ref.read(trainingProvider.notifier).stopTraining(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[800]!, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'STOP',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
              Text(
                '${state.currentScore}/${state.currentTotalQuestions}',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
              ),
              Text(
                _formatDuration(state.remainingSeconds),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: state.remainingSeconds <= 10 ? Colors.red : Colors.white,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Question
          if (state.currentQuestion != null) ...[
            Text(
              '${state.currentQuestion!.operand1} ${state.currentQuestion!.operatorSymbol} ${state.currentQuestion!.operand2}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Input
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 2),
                ),
              ),
              child: Text(
                state.userInput.isEmpty ? '_' : state.userInput,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 56,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Feedback
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: state.showFeedback ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                state.message,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: state.message.startsWith('✓') ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Number Pad
          _buildNumberPad(ref),
        ],
      ),
    );
  }

  Widget _buildNumberPad(WidgetRef ref) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '7'),
            _buildNumButton(ref, '8'),
            _buildNumButton(ref, '9'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '4'),
            _buildNumButton(ref, '5'),
            _buildNumButton(ref, '6'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '1'),
            _buildNumButton(ref, '2'),
            _buildNumButton(ref, '3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumButton(ref, '-'),
            _buildNumButton(ref, '0'),
            _buildBackButton(ref),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(WidgetRef ref, String num) {
    return GestureDetector(
      onTap: () => ref.read(trainingProvider.notifier).addInput(num),
      child: Container(
        width: 100,
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            num,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(trainingProvider.notifier).backspace(),
      child: Container(
        width: 100,
        height: 58,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
