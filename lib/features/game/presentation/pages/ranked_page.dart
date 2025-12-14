import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matharena/features/game/presentation/providers/ranked_provider.dart';
import '../widgets/rating_widgets.dart';

class RankedPage extends ConsumerStatefulWidget {
  const RankedPage({super.key});

  @override
  ConsumerState<RankedPage> createState() => _RankedPageState();
}

class _RankedPageState extends ConsumerState<RankedPage> {
  final TextEditingController _expressionController = TextEditingController();

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankedState = ref.watch(rankedProvider);
    
    // Mettre à jour le controller quand l'expression change
    if (_expressionController.text != rankedState.expression) {
      _expressionController.text = rankedState.expression;
      _expressionController.selection = TextSelection.fromPosition(
        TextPosition(offset: rankedState.cursorPosition),
      );
    }

    if (!rankedState.isPlaying) {
      return _buildStartScreen(context, ref);
    }

    return _buildGameScreen(context, ref, rankedState);
  }

  Widget _buildStartScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Rating profile en haut
              const RatingProfileWidget(),
              
              const Spacer(),
              
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
              
              const Spacer(),
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
    
    final sortedNumbers = List<int>.from(state.availableNumbers)..sort();

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
                  Row(
                    spacing: 12,
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
                      const CompactRatingWidget(),
                    ],
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
                    // Expression avec TextField éditable
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[950],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _expressionController,
                            readOnly: true,
                            showCursor: true,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            onTap: () {
                              final position = _expressionController.selection.baseOffset;
                              ref.read(rankedProvider.notifier).setCursorPosition(position);
                            },
                            onChanged: (value) {
                              final position = _expressionController.selection.baseOffset;
                              ref.read(rankedProvider.notifier).setCursorPosition(position);
                            },
                          ),
                          if (state.currentResult != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: state.currentResult == state.target ? Colors.green[900] : Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '= ${state.currentResult}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  color: state.currentResult == state.target ? Colors.green[300] : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
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
                        itemCount: sortedNumbers.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final num = sortedNumbers[index];
                          final originalIndex = state.availableNumbers.indexOf(num);
                          final isUsed = state.usedNumberIndices.contains(originalIndex);
                          
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
                      Expanded(child: _buildButton('←', () => ref.read(rankedProvider.notifier).deleteLastCharacter(), isDelete: true)),
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

  Widget _buildButton(String label, VoidCallback? onTap, {bool isDisabled = false, bool isClear = false, bool isDelete = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isClear 
                  ? Colors.red[700]! 
                  : (isDelete 
                      ? Colors.orange[700]! 
                      : (isDisabled ? Colors.grey[900]! : Colors.grey[800]!)),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
            color: isClear 
                ? Colors.red[950] 
                : (isDelete 
                    ? Colors.orange[950] 
                    : (isDisabled ? Colors.grey[950] : Colors.transparent)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isClear 
                    ? Colors.red[300] 
                    : (isDelete 
                        ? Colors.orange[300] 
                        : (isDisabled ? Colors.grey[700] : Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
