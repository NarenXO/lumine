import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../services/app_theme.dart';
import '../widgets/lumine_background.dart';
import 'dashboard_screen.dart';

class LumineHome extends StatefulWidget {
  const LumineHome({super.key});

  @override
  State<LumineHome> createState() => _LumineHomeState();
}

class _LumineHomeState extends State<LumineHome>
    with TickerProviderStateMixin {
  late AnimationController _starGlowController;
  late AnimationController _transitionController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _starGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _starGlowController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _handleEnter() async {
    setState(() => _isTransitioning = true);
    _transitionController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, animation, __) => const DashboardScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // Cosmic dark background
          const Positioned.fill(child: LumineBackground()),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Star
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: AnimatedBuilder(
                      animation: Listenable.merge(
                          [_starGlowController, _transitionController]),
                      builder: (context, child) {
                        final glow = _starGlowController.value;
                        final transitionScale = _isTransitioning
                            ? 1.0 + _transitionController.value * 3
                            : 1.0;
                        final transitionOpacity = _isTransitioning
                            ? 1.0 - _transitionController.value
                            : 1.0;

                        return Opacity(
                          opacity: transitionOpacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: transitionScale,
                            child: CustomPaint(
                              size: const Size(260, 260),
                              painter: _GoldStarPainter(glow: glow),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lumíne text — below the star
                  Text(
                    "Lumíne",
                    textAlign: TextAlign.center,
                    style: AppTheme.display(
                      size: 68,
                      color: AppTheme.textPrimary,
                      weight: FontWeight.w600,
                      letterSpacing: -1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 1000.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOutCubic),

                  const SizedBox(height: 12),

                  Text(
                    "Ambient spiritual intelligence.",
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      size: 15,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),

                  const Spacer(flex: 4),

                  // Step In button — gold accent
                  GestureDetector(
                    onTap: _isTransitioning ? null : _handleEnter,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: AppTheme.goldMid,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldMid.withOpacity(0.35),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Step In",
                              style: AppTheme.body(
                                size: 17,
                                color: AppTheme.bgDeep,
                                weight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.bgDeep,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: 24),

                  Text(
                    "v1.0 • Connection Active",
                    style: AppTheme.label(
                      size: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ).animate().fadeIn(delay: 1200.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warm balanced gold 4-point star — middle ground between washed and saturated
class _GoldStarPainter extends CustomPainter {
  final double glow;

  _GoldStarPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.48;
    final waist = size.width * 0.02;

    final path = Path();
    path.moveTo(center.dx, center.dy - outerRadius);
    path.quadraticBezierTo(
      center.dx + waist, center.dy - waist,
      center.dx + outerRadius, center.dy,
    );
    path.quadraticBezierTo(
      center.dx + waist, center.dy + waist,
      center.dx, center.dy + outerRadius,
    );
    path.quadraticBezierTo(
      center.dx - waist, center.dy + waist,
      center.dx - outerRadius, center.dy,
    );
    path.quadraticBezierTo(
      center.dx - waist, center.dy - waist,
      center.dx, center.dy - outerRadius,
    );
    path.close();

    // Layer 1: outer wide halo — soft warm amber
    final outerHalo = Paint()
      ..color = const Color(0xFFE8B647).withOpacity(0.25 + glow * 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 45 + glow * 15);
    canvas.drawPath(path, outerHalo);

    // Layer 2: mid glow — balanced gold
    final midGlow = Paint()
      ..color = const Color(0xFFFFDF7A).withOpacity(0.45 + glow * 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 24 + glow * 8);
    canvas.drawPath(path, midGlow);

    // Layer 3: body — warm balanced radial (middle ground)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF3C8).withOpacity(0.75),   // soft warm center
          const Color(0xFFFFDF7A).withOpacity(0.85),   // balanced gold
          const Color(0xFFE8B647).withOpacity(0.9),    // muted amber edges
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(path, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _GoldStarPainter oldDelegate) =>
      oldDelegate.glow != glow;
}