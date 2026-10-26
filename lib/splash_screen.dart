import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ✅ Drives the continuous rotation of the gradient ring
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // one full rotation every 5s
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Sizes
    const double badgeSize = 160;   // outer badge diameter
    const double ringWidth = 5;     // ring thickness
    const double innerPadding = 8;  // gap between ring and inner disk

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ═══════════════════════════════════════════════════
              // ✅ Spinning Ring + Stationary Logo
              // ═══════════════════════════════════════════════════
              SizedBox(
                width: badgeSize,
                height: badgeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1) Soft glow (static)
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.18),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.green.shade300.withOpacity(0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // 2) Rotating gradient ring (the spinning part)
                    RotationTransition(
                      turns: _spinController,
                      child: CustomPaint(
                        size: const Size(badgeSize, badgeSize),
                        painter: _SplashRingPainter(
                          ringWidth: ringWidth,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white,
                            Colors.lightGreen.shade300,
                            Colors.white,
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                      ),
                    ),

                    // 3) Stationary glassy inner disk with logo
                    Container(
                      width: badgeSize -
                          (ringWidth * 2) -
                          (innerPadding * 2),
                      height: badgeSize -
                          (ringWidth * 2) -
                          (innerPadding * 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                "উকিল",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "আপনার বিশ্বস্ত আইনি সঙ্গী",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 48),

              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Custom painter — draws a smooth gradient ring.
// Rotation is applied externally via RotationTransition.
// ============================================================
class _SplashRingPainter extends CustomPainter {
  final double ringWidth;
  final List<Color> colors;

  _SplashRingPainter({
    required this.ringWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Main rotating ring
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: colors,
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);

    // Extra shine "comet tail" for a premium feel
    final shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 0.55
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.04, 0.09],
        startAngle: 0,
        endAngle: math.pi * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, shinePaint);
  }

  @override
  bool shouldRepaint(covariant _SplashRingPainter old) {
    return old.ringWidth != ringWidth || old.colors != colors;
  }
}