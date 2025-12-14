import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ranked_provider.dart';

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
      body: SafeArea(
        child: Center(
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
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, width: 60, color: Colors.grey[800]),
                const SizedBox(height: 32),
                Text(
                  '2 MINUTE CHALLENGE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 64),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(rankedProvider.notifier).startGame();
                    },
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
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
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context, WidgetRef ref, dynamic state) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${state.secondsRemaining}s',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: state.secondsRemaining <= 30 ? Colors.red[300] : Colors.white,
                        ),
                      ),
                      Text(
                        'Score: ${state.score}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey[900]),
            // Main area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  spacing: 24,
                  children: [
                    // Target
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'MAKE:',
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
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
            // Controls
            _buildControls(context, ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, WidgetRef ref, dynamic state) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 8,
        children: [
          // Numbers
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 1; i <= state.availableNumbers.length; i++)
                _buildBtn(i.toString(), () {
                  ref.read(rankedProvider.notifier).addToExpression(i.toString());
                }),
            ],
          ),
          // Operators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              _buildBtn('+', () => ref.read(rankedProvider.notifier).addToExpression('+')),
              _buildBtn('-', () => ref.read(rankedProvider.notifier).addToExpression('-')),
              _buildBtn('×', () => ref.read(rankedProvider.notifier).addToExpression('*')),
              _buildBtn('÷', () => ref.read(rankedProvider.notifier).addToExpression('/')),
            ],
          ),
          // Parentheses + Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              _buildBtn('(', () => ref.read(rankedProvider.notifier).addToExpression('(')),
              _buildBtn(')', () => ref.read(rankedProvider.notifier).addToExpression(')')),
              _buildBtn('C', () => ref.read(rankedProvider.notifier).clearExpression(), isClear: true),
              _buildBtn('✓', () => ref.read(rankedProvider.notifier).submitAnswer()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap, {bool isClear = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: isClear ? Colors.red[700]! : Colors.grey[800]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isClear ? Colors.red[950] : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClear ? Colors.red[300] : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
