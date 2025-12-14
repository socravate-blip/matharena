import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matharena/features/game/presentation/providers/ranked_provider.dart';

class RankedPage extends ConsumerWidget {
  const RankedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankedState = ref.watch(rankedProvider);

    if (!rankedState.isPlaying) {
      return _buildStartScreen(context, ref);
    }

    return _buildGameScreen(context, ref, rankedState);
  }

  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RANKED',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, width: 60, color: Colors.grey[800]),
              const SizedBox(height: 32),
              Text(
                '2 Minutes · Score Points',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 64),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(rankedProvider.notifier).startGame(),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BEGIN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, WidgetRef ref, dynamic state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth < 600 ? 48.0 : 56.0;
    final buttonWidth = screenWidth < 600 ? 48.0 : 56.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RANKED',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    spacing: 16,
                    children: [
                      Text(
                        '${(state.secondsRemaining ~/ 60)}:${(state.secondsRemaining % 60).toString().padLeft(2, '0')}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: state.secondsRemaining <= 30 ? Colors.red[300] : Colors.white,
                        ),
                      ),
                      Text(
                        '${state.score}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey[900]),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  spacing: 24,
                  children: [
                    // Target
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TARGET',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${state.target}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expression
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[950],
                      ),
                      child: Text(
                        state.expression.isEmpty ? '0' : state.expression,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          color: state.expression.isEmpty ? Colors.grey[700] : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Message
                    if (state.message.isNotEmpty)
                      Text(
                        state.message,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: state.message.contains('✅') ? Colors.green[400] : Colors.red[400],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            // Controls
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 8,
                children: [
                  // Numbers Row
                  SizedBox(
                    height: buttonHeight,
                    child: Center(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.availableNumbers.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final num = state.availableNumbers[index];
                          final isUsed = state.usedNumberIndices.contains(index);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: buttonWidth,
                              child: _buildButton(
                                num.toString(),
                                isUsed ? null : () => ref.read(rankedProvider.notifier).addToExpression(num.toString()),
                                isDisabled: isUsed,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Operators Row
                  Row(
                    children: [
                      Expanded(child: _buildButton('+', () => ref.read(rankedProvider.notifier).addToExpression('+'))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton('-', () => ref.read(rankedProvider.notifier).addToExpression('-'))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton('×', () => ref.read(rankedProvider.notifier).addToExpression('*'))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton('÷', () => ref.read(rankedProvider.notifier).addToExpression('/'))),
                    ],
                  ),
                  // Actions Row
                  Row(
                    children: [
                      Expanded(child: _buildButton('(', () => ref.read(rankedProvider.notifier).addToExpression('('))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton(')', () => ref.read(rankedProvider.notifier).addToExpression(')'))),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton('C', () => ref.read(rankedProvider.notifier).clearExpression(), isClear: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildButton('✓', () => ref.read(rankedProvider.notifier).submitAnswer())),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback? onTap, {bool isDisabled = false, bool isClear = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isClear ? Colors.red[700]! : (isDisabled ? Colors.grey[900]! : Colors.grey[800]!),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isClear ? Colors.red[950] : (isDisabled ? Colors.grey[950] : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClear ? Colors.red[300] : (isDisabled ? Colors.grey[700] : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
