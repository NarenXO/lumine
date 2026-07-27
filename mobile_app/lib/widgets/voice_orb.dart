import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum VoiceOrbMode { idle, listening, processing, speaking }

class VoiceOrb extends StatefulWidget {
  final VoiceOrbMode mode;
  final double energy;

  const VoiceOrb({
    super.key,
    this.mode = VoiceOrbMode.idle,
    this.energy = 0.0,
  });

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spin, _breathe]),
      builder: (context, _) {
        final breatheValue = Curves.easeInOutSine.transform(_breathe.value);
        final pulse = sin(breatheValue * 2 * pi);

        final modeScale = switch (widget.mode) {
          VoiceOrbMode.listening => 1.08,
          VoiceOrbMode.processing => 1.05,
          VoiceOrbMode.speaking => 1.1,
          VoiceOrbMode.idle => 1.0,
        };

        final amplitude = 0.008 + widget.energy * 0.002;
        final scale = (modeScale + pulse * amplitude).clamp(0.98, 1.12);

        final blurSigma = (18.0 - widget.energy * 4.0).clamp(12.0, 18.0);

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const RadialGradient(
                  center: Alignment.center,
                  radius: 0.5,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.95, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _OrbPainter(
                  rotation: _spin.value * 2 * pi,
                  breathe: breatheValue,
                  mode: widget.mode,
                  energy: widget.energy.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double rotation;
  final double breathe;
  final VoiceOrbMode mode;
  final double energy;

  _OrbPainter({
    required this.rotation,
    required this.breathe,
    required this.mode,
    required this.energy,
  });

  static const Color _softBlue = Color(0xFF7AA8FF);
  static const Color _lavender = Color(0xFFB072FF);
  static const Color _softPink = Color(0xFFFF82C0);
  static const Color _paleYellow = Color(0xFFFFDC84);
  static const Color _glassWhite = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    final energyFactor = energy.clamp(0.0, 1.0);
    final isListening = mode == VoiceOrbMode.listening;
    final isProcessing = mode == VoiceOrbMode.processing;

    final modeSpeed = switch (mode) {
      VoiceOrbMode.listening => 1.18,
      VoiceOrbMode.processing => 1.08,
      VoiceOrbMode.speaking => 1.22,
      VoiceOrbMode.idle => 0.82,
    };
    final speedFactor = 0.78 + energyFactor * 0.26 + (isProcessing ? 0.08 : 0.0);
    final rotationScale = rotation * modeSpeed * speedFactor;

    final blobSpeeds = [0.88, 0.72, 1.14, 0.59, 1.03, 0.66];
    final blobRadiusFactor = [1.12, 1.0, 0.94, 1.04, 1.07, 0.9];
    final blobColor = [
      _softBlue.withOpacity(0.6 + energyFactor * 0.06),
      _lavender.withOpacity(0.52 + energyFactor * 0.04),
      _softPink.withOpacity(0.5 + energyFactor * 0.04),
      _paleYellow.withOpacity(0.38 + energyFactor * 0.04),
      _lavender.withOpacity(0.46 + energyFactor * 0.03),
      _softBlue.withOpacity(0.4 + energyFactor * 0.05),
    ];
    final blobOffsets = [
      0.0,
      pi * 0.72,
      pi * 1.4,
      pi * 0.45,
      pi * 1.1,
      pi * 0.98,
    ];

    final blobDistance = radius * 0.28;
    final baseRadius = radius * 1.05;

    final centerFillPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          _softBlue.withOpacity(0.72),
          _lavender.withOpacity(0.68),
          _softPink.withOpacity(0.56),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5));
    canvas.drawCircle(center, radius * 0.5, centerFillPaint);

    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius * 1.8), Paint());

    for (var i = 0; i < blobColor.length; i++) {
      final angle = blobOffsets[i] + rotationScale * blobSpeeds[i];
      final blobCenter = center + Offset(cos(angle), sin(angle)) * blobDistance * (0.88 + i * 0.02);
      final blobRadius = baseRadius * blobRadiusFactor[i];
      final blobPaint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            blobColor[i],
            blobColor[i].withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: blobCenter, radius: blobRadius));
      canvas.drawCircle(blobCenter, blobRadius, blobPaint);
    }

    final highlightAlpha = (0.22 + energyFactor * 0.28 + (isListening ? 0.08 : 0.0)).clamp(0.18, 0.55);
    final highlightRadius = radius * 0.18;
    final highlightCenter = center + Offset(-radius * 0.2, -radius * 0.18);
    final highlightPaint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          _glassWhite.withOpacity(highlightAlpha),
          _glassWhite.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: highlightCenter, radius: highlightRadius));
    canvas.drawCircle(highlightCenter, highlightRadius, highlightPaint);

    canvas.restore();

    final softCore = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          _glassWhite.withOpacity(0.08 + energyFactor * 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.78],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.02));
    canvas.drawCircle(center, radius * 1.02, softCore);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) {
    return old.rotation != rotation ||
        old.breathe != breathe ||
        old.mode != mode ||
        old.energy != energy;
  }
}