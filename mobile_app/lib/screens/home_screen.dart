import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:ui';
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
      body: Stack(
        children: [
          const MeshBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Star + Lumíne text stacked centered
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
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
                                  size: const Size(320, 320),
                                  painter: SubtleStarPainter(glow: glow),
                                ),
                              ),
                            );
                          },
                        ),
                        Text(
                          "Lumíne",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 64,
                                letterSpacing: -1,
                                color: const Color(0xFF1A1A1A),
                              ),
                        )
                            .animate()
                            .fadeIn(duration: 1000.ms)
                            .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Ambient spiritual intelligence.",
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              letterSpacing: 0.5,
                              color:
                                  const Color(0xFF1A1A1A).withOpacity(0.6),
                            ),
                  ).animate().fadeIn(delay: 400.ms, duration: 1000.ms),

                  const Spacer(flex: 4),

                  GestureDetector(
                    onTap: _isTransitioning ? null : _handleEnter,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Step In",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
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
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withOpacity(0.3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
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
class MeshBackground extends StatefulWidget {
  const MeshBackground({super.key});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(sin(t) * 0.6, cos(t) * 0.6),
              end: Alignment(-sin(t) * 0.6, -cos(t) * 0.6),
              colors: [
                Color.lerp(const Color(0xFFFEF3E7), const Color(0xFFFDE7F0), (sin(t) + 1) / 2)!,
                Color.lerp(const Color(0xFFE7EFFD), const Color(0xFFF3E7FD), (cos(t) + 1) / 2)!,
                Color.lerp(const Color(0xFFFFF7E0), const Color(0xFFE0F5EC), (sin(t + 1) + 1) / 2)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100 + sin(t) * 60,
                left: -50 + cos(t) * 80,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFB8CD).withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 50 + cos(t + 1) * 80,
                right: -100 + sin(t + 1) * 90,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFDE68A).withOpacity(0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 200 + sin(t + 2) * 50,
                right: -50 + cos(t + 2) * 60,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC8B8F0).withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
        );
      },
    );
  }
}
// SUBTLE 4-POINT STAR - thin & merges with background
class SubtleStarPainter extends CustomPainter {
  final double glow;

  SubtleStarPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.48;
    final waist = size.width * 0.02;

    final path = Path();
    path.moveTo(center.dx, center.dy - outerRadius);
    path.quadraticBezierTo(
      center.dx + waist,
      center.dy - waist,
      center.dx + outerRadius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + waist,
      center.dy + waist,
      center.dx,
      center.dy + outerRadius,
    );
    path.quadraticBezierTo(
      center.dx - waist,
      center.dy + waist,
      center.dx - outerRadius,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx - waist,
      center.dy - waist,
      center.dx,
      center.dy - outerRadius,
    );
    path.close();

    final outerGlow = Paint()
      ..color = Colors.white.withOpacity(0.4 + glow * 0.2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 + glow * 8);

    canvas.drawPath(path, outerGlow);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9 + glow * 0.1),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant SubtleStarPainter oldDelegate) =>
      oldDelegate.glow != glow;
}