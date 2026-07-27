import 'package:flutter/material.dart';
import '../services/app_controller.dart';

class GlowOrb extends StatefulWidget {
  final double size;
  final bool active;

  const GlowOrb({super.key, this.size = 220, this.active = false});

  @override
  State<GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<GlowOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<Color> _currentPalette = _paletteFor('calm');
  List<Color> _previousPalette = _paletteFor('calm');
  String _lastEmotion = 'calm';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Palette per emotion: [core, light, accent, deep] ──
  static List<Color> _paletteFor(String emotion) {
    switch (emotion) {
      case 'calm':
        return [
          Colors.white,
          const Color(0xFFB8D8FF).withOpacity(0.6),   // light sky
          const Color(0xFF8B7FE8).withOpacity(0.5),   // soft violet
          const Color(0xFF3B4FA8).withOpacity(0.4),   // deep indigo
        ];
      case 'happy':
        return [
          Colors.white,
          const Color(0xFFFFF3B0).withOpacity(0.6),   // light cream yellow
          const Color(0xFFFFAA3B).withOpacity(0.5),   // warm orange
          const Color(0xFFCC6B00).withOpacity(0.4),   // deep amber
        ];
      case 'sad':
        return [
          Colors.white,
          const Color(0xFFD8CCEF).withOpacity(0.6),   // light lavender
          const Color(0xFF9B7FC7).withOpacity(0.5),   // violet
          const Color(0xFF4A3A75).withOpacity(0.4),   // deep purple
        ];
      case 'angry':
        return [
          Colors.white,
          const Color(0xFFFFC9BA).withOpacity(0.6),   // light coral
          const Color(0xFFFF5C3B).withOpacity(0.5),   // fiery red-orange
          const Color(0xFF8B1A00).withOpacity(0.4),   // deep crimson
        ];
      case 'hopeful':
        return [
          Colors.white,
          const Color(0xFFBEE7FF).withOpacity(0.6),   // light cyan
          const Color(0xFF3BAFF5).withOpacity(0.5),   // bright sky
          const Color(0xFF0F5C99).withOpacity(0.4),   // deep ocean
        ];
      case 'anxious':
        return [
          Colors.white,
          const Color(0xFFE8CFFF).withOpacity(0.6),   // light violet
          const Color(0xFFB061E8).withOpacity(0.5),   // vibrant purple
          const Color(0xFF5B1F8C).withOpacity(0.4),   // deep magenta
        ];
      case 'grateful':
        return [
          Colors.white,
          const Color(0xFFCFF0D0).withOpacity(0.6),   // light mint
          const Color(0xFF4FCB6E).withOpacity(0.5),   // vivid green
          const Color(0xFF14683F).withOpacity(0.4),   // deep forest
        ];
      case 'stressed':
        return [
          Colors.white,
          const Color(0xFFFFD9B0).withOpacity(0.6),   // light peach
          const Color(0xFFFF8A2E).withOpacity(0.5),   // vibrant amber
          const Color(0xFF9A4200).withOpacity(0.4),   // deep burnt orange
        ];
      case 'optimistic':
        return [
          Colors.white,
          const Color(0xFFFFF0A8).withOpacity(0.6),   // light sunny
          const Color(0xFFFFD500).withOpacity(0.5),   // pure sunshine
          const Color(0xFFCC9500).withOpacity(0.4),   // deep gold
        ];
      case 'depressed':
        return [
          Colors.white,
          const Color(0xFFC7CDDA).withOpacity(0.6),   // light slate
          const Color(0xFF6B7A93).withOpacity(0.5),   // muted grey-blue
          const Color(0xFF2A3448).withOpacity(0.4),   // deep charcoal
        ];
      case 'crisis':
        return [
          Colors.white,
          const Color(0xFFFFB0B0).withOpacity(0.6),   // alert light red
          const Color(0xFFE83B3B).withOpacity(0.5),   // alarm red
          const Color(0xFF6B0000).withOpacity(0.4),   // deep blood red
        ];
      case 'neutral':
      default:
        return [
          Colors.white,
          const Color(0xFFB8D8FF).withOpacity(0.6),
          const Color(0xFF8B7FE8).withOpacity(0.5),
          const Color(0xFF3B4FA8).withOpacity(0.4),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (context, _) {
        final emotion = AppController().currentEmotion.toLowerCase().trim();

        if (emotion != _lastEmotion) {
          _previousPalette = _currentPalette;
          _currentPalette = _paletteFor(emotion);
          _lastEmotion = emotion;
        }

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, t, __) {
            // Interpolate each color in the palette smoothly
            final blended = List<Color>.generate(4, (i) {
              return Color.lerp(_previousPalette[i], _currentPalette[i], t)!;
            });

            // Extract accent for glow (index 2)
            final glowAccent = blended[2];
            final glowLight = blended[1];

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: blended,
                      radius: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowAccent
                            .withOpacity(widget.active ? 0.6 : 0.35),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: glowLight
                            .withOpacity(widget.active ? 0.5 : 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}