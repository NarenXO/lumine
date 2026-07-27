import 'package:flutter/material.dart';
import 'dart:math';
import '../services/app_theme.dart';

/// A reusable dark bento card with slate glow bleed.
/// Handles: enter animation (container appears empty → contents shimmer in from center),
/// press bounce, glow border.
class AnimatedBentoCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration enterDelay;
  final bool showContent;
  final EdgeInsets padding;
  final double? width;
  final double? height;

  const AnimatedBentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.enterDelay = Duration.zero,
    this.showContent = true,
    this.padding = const EdgeInsets.all(20),
    this.width,
    this.height,
  });

  @override
  State<AnimatedBentoCard> createState() => _AnimatedBentoCardState();
}

class _AnimatedBentoCardState extends State<AnimatedBentoCard>
    with TickerProviderStateMixin {
  late AnimationController _enterCtrl;      // container slides in
  late AnimationController _contentCtrl;    // contents shimmer in
  late AnimationController _glowCtrl;       // slate glow breath
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _startEntry();
  }

  Future<void> _startEntry() async {
    await Future.delayed(widget.enterDelay);
    if (!mounted) return;
    _enterCtrl.forward();
    // 300ms pause after container appears, THEN shimmer in contents
    await Future.delayed(_enterCtrl.duration! + const Duration(milliseconds: 300));
    if (!mounted) return;
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _contentCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_enterCtrl, _contentCtrl, _glowCtrl]),
      builder: (_, __) {
        // Container enter — slide up + fade + scale
        final enterCurve = Curves.easeOutCubic.transform(_enterCtrl.value);
        final translateY = (1 - enterCurve) * 40;
        final enterScale = 0.94 + enterCurve * 0.06;

        // Content shimmer in
        final contentT = Curves.easeOutCubic.transform(_contentCtrl.value);

        // Slate glow breath
        final glow = 0.4 + sin(_glowCtrl.value * pi) * 0.3;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: enterScale * (_pressed ? 0.97 : 1.0),
            child: Opacity(
              opacity: enterCurve,
              child: GestureDetector(
                onTapDown: widget.onTap == null
                    ? null
                    : (_) => setState(() => _pressed = true),
                onTapUp: widget.onTap == null
                    ? null
                    : (_) {
                        setState(() => _pressed = false);
                        widget.onTap!();
                      },
                onTapCancel: widget.onTap == null
                    ? null
                    : () => setState(() => _pressed = false),
                child: Container(
                  width: widget.width ?? double.infinity,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSlate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    border: Border.all(
                      color: AppTheme.bgSlateGlow.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      // slate glow bleed (bigger, outer)
                      BoxShadow(
                        color: AppTheme.bgSlateGlow.withOpacity(glow * 0.7),
                        blurRadius: 30 + glow * 15,
                        spreadRadius: 2,
                      ),
                      // depth shadow beneath
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: Stack(
                      children: [
                        // subtle top highlight (glass)
                        Positioned(
                          top: 0, left: 0, right: 0, height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content — shimmer in from center outward
                        Padding(
                          padding: widget.padding,
                          child: widget.showContent
                              ? Opacity(
                                  opacity: contentT,
                                  child: Transform.scale(
                                    scale: 0.85 + contentT * 0.15,
                                    child: widget.child,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}