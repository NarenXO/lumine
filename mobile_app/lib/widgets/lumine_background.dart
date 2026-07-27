import 'package:flutter/material.dart';
import 'dart:math';
import '../services/app_theme.dart';
import '../services/theme_service.dart';
import '../services/app_controller.dart';

/// The living cosmic dark canvas used across ALL tabs.
/// Layer 1: deep midnight base
/// Layer 2: drifting clouds + galaxy + star field
/// Layer 3: gold vignette (Lumíne presence)
/// Layer 4: rising gold particles (incense/dust)
/// Layer 5: emotion aura on the sides (prominent, shifts with emotion)
class LumineBackground extends StatefulWidget {
  const LumineBackground({super.key});

  @override
  State<LumineBackground> createState() => _LumineBackgroundState();
}

class _LumineBackgroundState extends State<LumineBackground>
    with TickerProviderStateMixin {
  late AnimationController _driftController;
  late AnimationController _particleController;
  late AnimationController _twinkleController;

  Color _currentEmotionColor = ThemeService.getEmotionColor();
  Color _previousEmotionColor = ThemeService.getEmotionColor();
  DateTime _emotionChangeAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
        _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),  // slower, no reverse
    )..repeat();  // continuous loop, no reverse
  }

  @override
  void dispose() {
    _driftController.dispose();
    _particleController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (context, _) {
        final target = ThemeService.getEmotionColor();
        if (target != _currentEmotionColor) {
          _previousEmotionColor = _currentEmotionColor;
          _currentEmotionColor = target;
          _emotionChangeAt = DateTime.now();
        }

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _driftController,
              _particleController,
              _twinkleController,
            ]),
            builder: (_, __) {
              // 2s smooth emotion color tween
              final sinceChange = DateTime.now()
                      .difference(_emotionChangeAt)
                      .inMilliseconds /
                  2000.0;
              final tweenT = sinceChange.clamp(0.0, 1.0);
              final emotionColor = Color.lerp(
                _previousEmotionColor,
                _currentEmotionColor,
                Curves.easeInOut.transform(tweenT),
              )!;

              return CustomPaint(
                painter: _CosmicPainter(
                  driftT: _driftController.value * 2 * pi,
                  particleT: _particleController.value,
                  twinkleT: _twinkleController.value,
                  emotionColor: emotionColor,
                ),
                size: Size.infinite,
              );
            },
          ),
        );
      },
    );
  }
}

class _CosmicPainter extends CustomPainter {
  final double driftT;
  final double particleT;
  final double twinkleT;
  final Color emotionColor;

  _CosmicPainter({
    required this.driftT,
    required this.particleT,
    required this.twinkleT,
    required this.emotionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Layer 1: deep midnight base ──
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.bgDeep);

    // ── Layer 5a: LEFT side emotion aura (prominent) ──
    final leftAura = Paint()
      ..shader = RadialGradient(
        center: Alignment(-1.2 + sin(driftT * 0.3) * 0.1,
            -0.2 + cos(driftT * 0.2) * 0.15),
        radius: 1.4,
        colors: [
          emotionColor.withOpacity(0.28),
          emotionColor.withOpacity(0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, leftAura);

    // ── Layer 5b: RIGHT side emotion aura (paired) ──
    final rightAura = Paint()
      ..shader = RadialGradient(
        center: Alignment(1.2 + cos(driftT * 0.25) * 0.1,
            0.4 + sin(driftT * 0.28) * 0.15),
        radius: 1.3,
        colors: [
          emotionColor.withOpacity(0.22),
          emotionColor.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, rightAura);

    // ── Layer 2a: drifting cloud 1 (soft slate) ──
    final cloud1Center = Offset(
      size.width * (0.3 + sin(driftT * 0.4) * 0.15),
      size.height * (0.25 + cos(driftT * 0.3) * 0.1),
    );
    final cloud1 = Paint()
      ..color = AppTheme.bgSlateGlow.withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    canvas.drawCircle(cloud1Center, size.width * 0.55, cloud1);

    // ── Layer 2b: drifting cloud 2 (deeper slate) ──
    final cloud2Center = Offset(
      size.width * (0.7 + cos(driftT * 0.35) * 0.15),
      size.height * (0.7 + sin(driftT * 0.4) * 0.1),
    );
    final cloud2 = Paint()
      ..color = AppTheme.bgSlateHigh.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(cloud2Center, size.width * 0.5, cloud2);

    // ── Layer 2c: galaxy spiral wisp (center area) ──
    final galaxyCenter = Offset(
      size.width * 0.5,
      size.height * (0.5 + sin(driftT * 0.2) * 0.05),
    );
    for (int i = 0; i < 3; i++) {
      final rotation = driftT * 0.1 + (i * pi / 3);
      final radius = size.width * (0.15 + i * 0.08);
      final wispPaint = Paint()
        ..color = Colors.white.withOpacity(0.03 - i * 0.008)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      final path = Path();
      for (double a = 0; a < 2 * pi; a += 0.15) {
        final r = radius * (1 + sin(a * 3 + rotation) * 0.3);
        final x = galaxyCenter.dx + cos(a + rotation) * r;
        final y = galaxyCenter.dy + sin(a + rotation) * r * 0.4;
        if (a == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wispPaint);
    }

        // ── Layer 2d: STAR FIELD (smoothly twinkling, no glitch) ──
    final starRng = Random(42);
    const starCount = 80;
    for (int i = 0; i < starCount; i++) {
      final x = starRng.nextDouble() * size.width;
      final y = starRng.nextDouble() * size.height;
      final baseSize = 0.5 + starRng.nextDouble() * 1.5;
      // Each star twinkles at unique phase using continuous sine wave
      // Multiply twinkleT by 2pi so full cycle happens over 20s
      final individualPhase = i * 0.4;  // spread phases across all stars
      final twinkleValue = sin(twinkleT * 2 * pi + individualPhase);
      final twinkle = 0.5 + twinkleValue * 0.35;  // smooth 0.15 → 0.85
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.2 + twinkle * 0.25);
      canvas.drawCircle(Offset(x, y), baseSize * (0.7 + twinkle * 0.3), starPaint);
    }

       // A few bigger star sparkles — smooth continuous twinkle
    final sparkleRng = Random(99);
    for (int i = 0; i < 8; i++) {
      final x = sparkleRng.nextDouble() * size.width;
      final y = sparkleRng.nextDouble() * size.height;
      final sparkTwinkle = sin(twinkleT * 2 * pi + i * 0.7) * 0.5 + 0.5;
      final sparkPaint = Paint()
        ..color = AppTheme.goldSoft.withOpacity(0.25 + sparkTwinkle * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), 2, sparkPaint);
    }

    // ── Layer 3: soft gold vignette (top-center Lumíne presence) ──
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, -0.7 + sin(driftT * 0.15) * 0.05),
        radius: 1.0,
        colors: [
          AppTheme.goldMid.withOpacity(0.08),
          AppTheme.goldMid.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    // ── Layer 4: rising particles (visible, gold incense) ──
    final pRng = Random(7);
    const pCount = 35;
    for (int i = 0; i < pCount; i++) {
      final x = pRng.nextDouble() * size.width;
      final startY = size.height + pRng.nextDouble() * 200;
      final rise = (particleT * 900 + i * 60) % (size.height + 300);
      final y = startY - rise;
      if (y < -20 || y > size.height + 20) continue;

      final drift = sin((particleT * 2 * pi) + i * 0.4) * 25;
      final finalX = x + drift;

      // Fade at top and bottom, brighter in middle
      double opacity = 1.0;
      if (y < 100) opacity = y / 100;
      if (y > size.height - 100) opacity = (size.height - y) / 100;
      opacity = opacity.clamp(0.0, 1.0) * 0.55;

      final radius = 1.0 + pRng.nextDouble() * 1.5;
      canvas.drawCircle(
        Offset(finalX, y),
        radius,
        Paint()..color = AppTheme.goldMid.withOpacity(opacity),
      );

      // Occasional larger sparkle particle with blur
      if (i % 7 == 0) {
        canvas.drawCircle(
          Offset(finalX, y),
          radius * 1.8,
          Paint()
            ..color = AppTheme.goldSoft.withOpacity(opacity * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter old) =>
      old.driftT != driftT ||
      old.particleT != particleT ||
      old.twinkleT != twinkleT ||
      old.emotionColor != emotionColor;
}