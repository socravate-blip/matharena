import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Animation de célébration pour montée de rang
class RankUpAnimation extends StatefulWidget {
  final String newRankName;
  final String newRankIcon;
  final Color rankColor;
  final VoidCallback onComplete;

  const RankUpAnimation({
    super.key,
    required this.newRankName,
    required this.newRankIcon,
    required this.rankColor,
    required this.onComplete,
  });

  @override
  State<RankUpAnimation> createState() => _RankUpAnimationState();
}

class _RankUpAnimationState extends State<RankUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Texte "RANG SUPÉRIEUR!"
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.rankColor.withOpacity(0.3),
                            widget.rankColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.rankColor, width: 3),
                      ),
                      child: Text(
                        'RANG SUPÉRIEUR!',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Icône de rang qui tourne
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.rankColor.withOpacity(0.4),
                              widget.rankColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.newRankIcon,
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nom du nouveau rang
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          widget.rankColor,
                          widget.rankColor.withOpacity(0.6),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        widget.newRankName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Particules de célébration
                  if (_scaleAnimation.value > 0.8)
                    SizedBox(
                      width: 400,
                      height: 100,
                      child: CustomPaint(
                        painter: ConfettiPainter(
                          progress: _controller.value,
                          color: widget.rankColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Painter pour les confettis de célébration
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  final math.Random random = math.Random(42); // Seed fixe pour cohérence

  ConfettiPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final startY = size.height * 0.5;
      final endY = size.height;
      final y = startY + (endY - startY) * progress;

      final colors = [
        color,
        color.withOpacity(0.7),
        Colors.yellow,
        Colors.white,
      ];
      paint.color = colors[i % colors.length];

      final radius = 3 + random.nextDouble() * 4;
      canvas.drawCircle(Offset(x, y), radius * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Dialogue de milestone atteint
class MilestoneDialog extends StatelessWidget {
  final String milestoneName;
  final String reward;
  final int eloRequired;

  const MilestoneDialog({
    super.key,
    required this.milestoneName,
    required this.reward,
    required this.eloRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de trophée
            const Text('🏆', style: TextStyle(fontSize: 64)),

            const SizedBox(height: 16),

            // Titre
            Text(
              'OBJECTIF ATTEINT!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 24),

            // Nom du milestone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  Text(
                    milestoneName,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$eloRequired ELO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Récompense
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Récompense débloquée:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reward,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CONTINUER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
