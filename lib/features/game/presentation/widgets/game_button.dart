import 'package:flutter/material.dart';

/// A custom button widget for the math game with gradient backgrounds and neon styling
class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final ButtonType type;
  final double? width;
  final double height;
  final bool isMathadorHighlight;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDisabled = false,
    this.type = ButtonType.number,
    this.width,
    this.height = 60,
    this.isMathadorHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !isDisabled && onPressed != null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive && !isDisabled
            ? [
                BoxShadow(
                  color: _getGlowColor().withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: _getGlowColor().withValues(alpha: 0.3),
          highlightColor: _getGlowColor().withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _buildGradient(),
              border: isMathadorHighlight
                  ? Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDisabled ? Colors.grey[600] : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                      letterSpacing: 1,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _buildGradient() {
    if (isDisabled) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[800]!.withValues(alpha: 0.5),
          Colors.grey[700]!.withValues(alpha: 0.3),
        ],
      );
    }

    switch (type) {
      case ButtonType.number:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0066FF).withValues(alpha: 0.9),
            const Color(0xFF00D9FF).withValues(alpha: 0.8),
          ],
        );
      case ButtonType.operator:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF006E).withValues(alpha: 0.9),
            const Color(0xFFFF4D7B).withValues(alpha: 0.8),
          ],
        );
      case ButtonType.parenthesis:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!.withValues(alpha: 0.8),
            Colors.grey[600]!.withValues(alpha: 0.7),
          ],
        );
      case ButtonType.submit:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.95),
            const Color(0xFFFFA500).withValues(alpha: 0.85),
          ],
        );
      case ButtonType.action:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00FF88).withValues(alpha: 0.9),
            const Color(0xFF00FFCC).withValues(alpha: 0.8),
          ],
        );
    }
  }

  Color _getGlowColor() {
    switch (type) {
      case ButtonType.number:
        return const Color(0xFF00D9FF);
      case ButtonType.operator:
        return const Color(0xFFFF006E);
      case ButtonType.parenthesis:
        return Colors.grey[600]!;
      case ButtonType.submit:
        return const Color(0xFFFFD700);
      case ButtonType.action:
        return const Color(0xFF00FF88);
    }
  }
}

enum ButtonType { number, operator, parenthesis, submit, action }
